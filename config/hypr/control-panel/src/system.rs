use std::process::Command;

pub fn cmd_stdout(prog: &str, args: &[&str]) -> String {
    Command::new(prog)
        .args(args)
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

pub fn cmd_run(prog: &str, args: &[&str]) -> i32 {
    Command::new(prog)
        .args(args)
        .output()
        .map(|o| o.status.code().unwrap_or(-1))
        .unwrap_or(-1)
}

// ---------------- Display / Refresh rate ----------------

pub fn get_monitors() -> Vec<(String, String, Vec<String>)> {
    // Returns (name, description, available_modes) for each monitor
    let out = cmd_stdout("hyprctl", &["-j", "monitors"]);
    let mut monitors = Vec::new();
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&out) {
        if let Some(arr) = json.as_array() {
            for m in arr {
                let name = m["name"].as_str().unwrap_or("").to_string();
                let desc = m["description"].as_str().unwrap_or("").to_string();
                let mut modes = Vec::new();
                if let Some(mode_list) = m["availableModes"].as_str() {
                    modes = mode_list.split_whitespace().map(|s| s.to_string()).collect();
                }
                monitors.push((name, desc, modes));
            }
        }
    }
    if monitors.is_empty() {
        // Fallback: try to parse without JSON
        let out = cmd_stdout("hyprctl", &["monitors"]);
        for line in out.lines() {
            if line.starts_with("Monitor ") {
                let name = line
                    .trim_start_matches("Monitor ")
                    .split_whitespace()
                    .next()
                    .unwrap_or("")
                    .to_string();
                monitors.push((name.clone(), format!("Monitor {}", name), Vec::new()));
            }
        }
    }
    monitors
}

pub fn set_refresh_rate(monitor: &str, mode: &str) -> i32 {
    // mode is like "144.00Hz"
    let hz = mode.replace("Hz", "").trim().to_string();
    // Get current resolution from monitor
    let current = cmd_stdout("hyprctl", &["-j", "monitors"]);
    let res = if let Ok(json) = serde_json::from_str::<serde_json::Value>(&current) {
        if let Some(arr) = json.as_array() {
            if let Some(m) = arr.iter().find(|m| m["name"].as_str() == Some(monitor)) {
                let w = m["width"].as_u64().unwrap_or(1920);
                let h = m["height"].as_u64().unwrap_or(1080);
                format!("{}x{}", w, h)
            } else {
                "1920x1080".to_string()
            }
        } else {
            "1920x1080".to_string()
        }
    } else {
        "1920x1080".to_string()
    };
    cmd_run(
        "hyprctl",
        &["keyword", "monitor", &format!("{}@{}", res, hz)],
    )
}

// ---------------- Wi-Fi ----------------

pub fn wifi_enabled() -> bool {
    cmd_stdout("nmcli", &["-t", "-f", "WIFI", "radio"]).to_lowercase() == "enabled"
}

pub fn wifi_current() -> String {
    let out = cmd_stdout(
        "nmcli",
        &["-t", "-f", "ACTIVE,SSID", "device", "wifi", "list", "--rescan", "no"],
    );
    for line in out.lines() {
        let mut it = line.splitn(2, ':');
        if it.next() == Some("yes") {
            return it.next().unwrap_or("").to_string();
        }
    }
    String::new()
}

pub fn wifi_toggle(on: bool) -> i32 {
    if on {
        cmd_run("nmcli", &["radio", "wifi", "on"])
    } else {
        cmd_run("nmcli", &["radio", "wifi", "off"])
    }
}

pub fn wifi_scan() -> Vec<(String, String, String, bool)> {
    // Returns (ssid, signal, security, in_use)
    let _ = cmd_run("nmcli", &["device", "wifi", "rescan"]);
    let out = cmd_stdout(
        "nmcli",
        &[
            "-t",
            "-f",
            "SSID,SIGNAL,SECURITY,IN-USE",
            "device",
            "wifi",
            "list",
            "--rescan",
            "no",
        ],
    );
    let mut nets: Vec<(String, String, String, bool)> = Vec::new();
    for line in out.lines() {
        let parts: Vec<&str> = line.splitn(4, ':').collect();
        if parts.len() < 2 {
            continue;
        }
        let ssid = parts[0].trim().to_string();
        if ssid.is_empty() || ssid == "--" {
            continue;
        }
        let signal = parts[1].to_string();
        let security = if parts.len() > 2 { parts[2].to_string() } else { String::new() };
        let in_use = parts.get(3).map(|s| s.contains('*')).unwrap_or(false);
        if let Some(n) = nets.iter_mut().find(|n| n.0 == ssid) {
            if signal.parse::<u32>().unwrap_or(0) > n.1.parse::<u32>().unwrap_or(0) {
                n.1 = signal.clone();
                n.2 = security.clone();
                n.3 |= in_use;
            }
        } else {
            nets.push((ssid, signal, security, in_use));
        }
    }
    nets.sort_by(|a, b| b.1.parse::<u32>().unwrap_or(0).cmp(&a.1.parse::<u32>().unwrap_or(0)));
    nets
}

pub fn wifi_connect(ssid: &str, password: Option<&str>) -> i32 {
    let saved = cmd_stdout("nmcli", &["-t", "-f", "NAME", "connection", "show"]);
    if saved.lines().any(|l| l == ssid) {
        return cmd_run("nmcli", &["connection", "up", ssid]);
    }
    if let Some(pw) = password {
        cmd_run("nmcli", &["device", "wifi", "connect", ssid, "password", pw])
    } else {
        cmd_run("nmcli", &["device", "wifi", "connect", ssid])
    }
}

pub fn wifi_disconnect() {
    let out = cmd_stdout("nmcli", &["-t", "-f", "TYPE,STATE,CONNECTION", "device"]);
    for line in out.lines() {
        let parts: Vec<&str> = line.splitn(3, ':').collect();
        if parts.len() >= 3 && parts[0] == "wifi" && parts[1] == "connected" {
            cmd_run("nmcli", &["connection", "down", parts[2]]);
            break;
        }
    }
}

// ---------------- Bluetooth ----------------

pub fn bt_enabled() -> bool {
    cmd_stdout("bluetoothctl", &["show"]).contains("Powered: yes")
}

pub fn bt_toggle(on: bool) -> i32 {
    if on {
        cmd_run("bluetoothctl", &["power", "on"])
    } else {
        cmd_run("bluetoothctl", &["power", "off"])
    }
}

pub fn bt_scan() -> Vec<(String, String)> {
    // Returns (address, name)
    cmd_run("bluetoothctl", &["scan", "on"]);
    std::thread::sleep(std::time::Duration::from_secs(2));
    let out = cmd_stdout("bluetoothctl", &["devices"]);
    let mut devs = Vec::new();
    for line in out.lines() {
        // "Device AA:BB:CC:DD:EE:FF Name"
        if let Some(rest) = line.strip_prefix("Device ") {
            let mut it = rest.splitn(2, ' ');
            if let (Some(addr), Some(name)) = (it.next(), it.next()) {
                if !name.is_empty() {
                    devs.push((addr.to_string(), name.trim().to_string()));
                }
            }
        }
    }
    devs
}

pub fn bt_connect(addr: &str) -> i32 {
    cmd_run("bluetoothctl", &["connect", addr])
}

pub fn bt_disconnect(addr: &str) -> i32 {
    cmd_run("bluetoothctl", &["disconnect", addr])
}

pub fn bt_is_connected(addr: &str) -> bool {
    let out = cmd_stdout("bluetoothctl", &["info", addr]);
    out.contains("Connected: yes")
}

pub fn bt_paired() -> Vec<(String, String)> {
    let out = cmd_stdout("bluetoothctl", &["paired-devices"]);
    let mut devs = Vec::new();
    for line in out.lines() {
        if let Some(rest) = line.strip_prefix("Device ") {
            let mut it = rest.splitn(2, ' ');
            if let (Some(addr), Some(name)) = (it.next(), it.next()) {
                devs.push((addr.to_string(), name.trim().to_string()));
            }
        }
    }
    devs
}

// ---------------- Brightness ----------------

pub fn brightness_get() -> (u32, u32) {
    let max = cmd_stdout("brightnessctl", &["max"])
        .parse::<u32>()
        .unwrap_or(100);
    let cur = cmd_stdout("brightnessctl", &["get"])
        .parse::<u32>()
        .unwrap_or(0);
    (cur, max)
}

pub fn brightness_set(pct: u32) -> i32 {
    cmd_run("brightnessctl", &["set", &format!("{}%", pct)])
}

// ---------------- Audio ----------------

pub fn volume_get() -> u32 {
    let out = cmd_stdout("wpctl", &["get-volume", "@DEFAULT_AUDIO_SINK@"]);
    out.split_whitespace()
        .nth(1)
        .and_then(|v| v.parse::<f32>().ok())
        .map(|v| (v * 100.0) as u32)
        .unwrap_or(0)
}

pub fn volume_set(pct: u32) -> i32 {
    cmd_run("wpctl", &["set-volume", "@DEFAULT_AUDIO_SINK@", &format!("{:.1}", pct as f32 / 100.0)])
}

pub fn volume_mute(mute: bool) -> i32 {
    if mute {
        cmd_run("wpctl", &["set-mute", "@DEFAULT_AUDIO_SINK@", "1"])
    } else {
        cmd_run("wpctl", &["set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
    }
}

pub fn audio_sink_mute() -> bool {
    cmd_stdout("wpctl", &["get-volume", "@DEFAULT_AUDIO_SINK@"]).contains("MUTED")
}

// ---------------- System ----------------

pub fn battery_info() -> (u32, bool) {
    let out = cmd_stdout("upower", &["-i", &format!("/org/freedesktop/UPower/devices/battery_{}", default_bat())]);
    let mut pct = 0;
    let mut charging = false;
    for line in out.lines() {
        let l = line.trim();
        if let Some(v) = l.strip_prefix("percentage:") {
            pct = v.trim().trim_end_matches('%').parse().unwrap_or(0);
        }
        if l.contains("state:") && l.contains("charging") {
            charging = true;
        }
    }
    (pct, charging)
}

fn default_bat() -> String {
    let out = cmd_stdout("upower", &["-e"]);
    out.lines()
        .find(|l| l.contains("battery"))
        .and_then(|l| l.rsplit('/').next())
        .unwrap_or("BAT0")
        .to_string()
}

pub fn cpu_usage() -> u32 {
    let out = cmd_stdout("top", &["-bn1"]);
    if let Some(line) = out.lines().find(|l| l.contains("%Cpu")) {
        if let Some(p) = line.split('%').next() {
            if let Some(v) = p.split_whitespace().last() {
                if let Ok(f) = v.replace(',', ".").parse::<f32>() {
                    return (100.0 - f) as u32;
                }
            }
        }
    }
    0
}

pub fn memory_usage() -> u32 {
    let out = cmd_stdout("free", &["-m"]);
    for line in out.lines().skip(1).take(1) {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 3 {
            let total = parts[1].parse::<u64>().unwrap_or(1);
            let used = parts[2].parse::<u64>().unwrap_or(0);
            return (used * 100 / total) as u32;
        }
    }
    0
}

pub fn shutdown() {
    cmd_spawn("systemctl", &["poweroff"]);
}

pub fn reboot() {
    cmd_spawn("systemctl", &["reboot"]);
}

pub fn suspend() {
    cmd_spawn("systemctl", &["suspend"]);
}

pub fn lock() {
    cmd_spawn("hyprlock", &[]);
}

fn cmd_spawn(prog: &str, args: &[&str]) {
    let _ = Command::new(prog).args(args).spawn();
}
