use std::process::{Command, Stdio};
use std::io::Write;

fn run(args: &[&str]) -> String {
    Command::new("nmcli")
        .args(args)
        .stdin(Stdio::null())
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

fn run_rc(args: &[&str]) -> (String, String, i32) {
    let o = Command::new("nmcli")
        .args(args)
        .stdin(Stdio::null())
        .output()
        .unwrap_or_else(|_| {
            std::process::Command::new("true").output().unwrap()
        });
    let code = o.status.code().unwrap_or(-1);
    (
        String::from_utf8_lossy(&o.stdout).trim().to_string(),
        String::from_utf8_lossy(&o.stderr).trim().to_string(),
        code,
    )
}

fn status() {
    let wifi_on = run(&["-t", "-f", "WIFI", "radio"]).to_lowercase() == "enabled";
    if !wifi_on {
        println!(
            "{{\"text\":\"󰤮 Wi-Fi Off\",\"alt\":\"off\",\"class\":\"wifi-off\",\"tooltip\":\"Wi-Fi disabled\\nClick to see networks\"}}"
        );
        return;
    }

    let out = run(&[
        "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no",
    ]);
    let mut ssid = String::new();
    let mut signal = 0;
    let mut security = String::new();
    for line in out.lines() {
        let parts: Vec<&str> = line.splitn(4, ':').collect();
        if parts.len() >= 4 && parts[0] == "yes" {
            ssid = parts[1].to_string();
            signal = parts[2].parse().unwrap_or(0);
            security = parts[3].to_string();
            break;
        }
    }

    if ssid.is_empty() {
        let dev = run(&["-t", "-f", "TYPE,STATE", "device"]);
        let eth = dev.lines().any(|l| l.contains("ethernet") && l.contains("connected"));
        if eth {
            println!(
                "{{\"text\":\"󰈀 Wired\",\"alt\":\"eth\",\"class\":\"ethernet\",\"tooltip\":\"Connected via Ethernet\\nClick to see networks\"}}"
            );
        } else {
            println!(
                "{{\"text\":\"󰤯 No Connection\",\"alt\":\"none\",\"class\":\"disconnected\",\"tooltip\":\"Not connected\\nClick to see networks\"}}"
            );
        }
        return;
    }

    let icon = ["󰤟", "󰤢", "󰤥", "󰤨"][((signal / 25).min(3)) as usize];
    let lock = if !security.is_empty() && security != "--" { " " } else { "" };
    println!(
        "{{\"text\":\"{} {} {}{}\",\"alt\":\"wifi\",\"class\":\"wifi\",\"tooltip\":\"Connected: {}\\nSignal: {}%\\nSecurity: {}\\nClick to see networks\"}}",
        icon,
        signal,
        ssid,
        lock,
        ssid,
        signal,
        security
    );
}

#[derive(Clone)]
struct Net {
    ssid: String,
    signal: i32,
    security: String,
    in_use: bool,
}

fn scan() -> Vec<Net> {
    Command::new("nmcli")
        .args(["device", "wifi", "rescan"])
        .output()
        .ok();
    let out = run(&[
        "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list", "--rescan", "no",
    ]);
    let mut map: Vec<Net> = Vec::new();
    for line in out.lines() {
        let parts: Vec<&str> = line.splitn(4, ':').collect();
        if parts.len() < 2 {
            continue;
        }
        let ssid = parts[0].trim().to_string();
        if ssid.is_empty() || ssid == "--" {
            continue;
        }
        let signal: i32 = parts[1].parse().unwrap_or(0);
        let security = if parts.len() > 2 { parts[2].to_string() } else { String::new() };
        let in_use = parts.get(3).map(|s| s.contains('*')).unwrap_or(false);
        if let Some(n) = map.iter_mut().find(|n| n.ssid == ssid) {
            if signal > n.signal {
                n.signal = signal;
                n.security = security.clone();
                n.in_use |= in_use;
            }
        } else {
            map.push(Net { ssid, signal, security, in_use });
        }
    }
    map.sort_by(|a, b| b.signal.cmp(&a.signal));
    map
}

fn current_ssid() -> String {
    let out = run(&["-t", "-f", "ACTIVE,SSID", "device", "wifi", "list", "--rescan", "no"]);
    for line in out.lines() {
        let mut it = line.splitn(2, ':');
        if it.next() == Some("yes") {
            return it.next().unwrap_or("").to_string();
        }
    }
    String::new()
}

fn menu() {
    let wifi_on = run(&["-t", "-f", "WIFI", "radio"]).to_lowercase() == "enabled";
    let active = current_ssid();

    let mut lines: Vec<String> = Vec::new();
    let mut actions: Vec<String> = Vec::new();

    if wifi_on {
        lines.push("󰖪  Disable Wi-Fi".into());
    } else {
        lines.push("󰖩  Enable Wi-Fi".into());
    }
    actions.push("toggle".into());

    if !active.is_empty() {
        lines.push(format!("󰌌  Disconnect from '{}'", active));
        actions.push("disconnect".into());
        lines.push(format!("󰄩  Forget '{}'", active));
        actions.push(format!("forget|{}", active));
    }

    lines.push(String::new());
    actions.push("sep".into());
    lines.push("Available Networks:".into());
    actions.push("sep".into());

    if !wifi_on {
        lines.push("  (Wi-Fi is disabled)".into());
        actions.push("noop".into());
    } else {
        let nets = scan();
        if nets.is_empty() {
            lines.push("  No networks found".into());
            actions.push("noop".into());
        } else {
            for n in nets.iter().take(20) {
                let bars = if n.signal >= 75 { "󰤨" } else if n.signal >= 50 { "󰤥" } else if n.signal >= 25 { "󰤢" } else { "󰤟" };
                let lock = if n.security.is_empty() || n.security == "--" { "" } else { " " };
                let cur = if n.in_use { " 󰁍" } else { "" };
                lines.push(format!("  {}  {}{}{}", bars, n.ssid, lock, cur));
                actions.push(format!("connect|{}", n.ssid));
            }
        }
    }

    lines.push(String::new());
    actions.push("sep".into());
    lines.push("󰋼  Connection Details".into());
    actions.push("details".into());

    let input = lines.join("\n");
    let theme = rofi_theme();

    let out = Command::new("rofi")
        .args(["-dmenu", "-i", "-p", "Network", "-theme-str", &theme])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .and_then(|mut c| {
            c.stdin.as_mut().unwrap().write_all(input.as_bytes()).ok();
            c.wait_with_output()
        })
        .unwrap_or_else(|_| {
            // fallback: treat as cancelled
            std::process::Command::new("true").output().unwrap()
        });

    if !out.status.success() {
        return;
    }
    let selected = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if selected.is_empty() {
        return;
    }

    let idx = lines.iter().position(|l| *l == selected);
    let Some(idx) = idx else { return };
    if idx >= actions.len() {
        return;
    }
    let action = actions[idx].clone();
    match action.as_str() {
        "toggle" => toggle(),
        "disconnect" => disconnect(),
        "details" => details(),
        "noop" | "sep" => {}
        _ => {
            if let Some(rest) = action.strip_prefix("forget|") {
                forget(rest);
            } else if let Some(rest) = action.strip_prefix("connect|") {
                connect(rest);
            }
        }
    }
}

fn toggle() {
    let state = run(&["-t", "-f", "WIFI", "radio"]);
    if state.to_lowercase() == "enabled" {
        run(&["radio", "wifi", "off"]);
    } else {
        run(&["radio", "wifi", "on"]);
    }
}

fn disconnect() {
    let out = run(&["-t", "-f", "TYPE,STATE,CONNECTION", "device"]);
    for line in out.lines() {
        let mut it = line.splitn(3, ':');
        let t = it.next().unwrap_or("");
        let s = it.next().unwrap_or("");
        let con = it.next().unwrap_or("");
        if t == "wifi" && s == "connected" && !con.is_empty() {
            run(&["connection", "down", con]);
            break;
        }
    }
}

fn forget(ssid: &str) {
    run(&["connection", "delete", ssid]);
}

fn connect(ssid: &str) {
    let saved = run(&["-t", "-f", "NAME", "connection", "show"]);
    if saved.lines().any(|l| l == ssid) {
        let (_, _, rc) = run_rc(&["connection", "up", ssid]);
        if rc == 0 {
            return;
        }
    }
    let (_, _, rc) = run_rc(&["device", "wifi", "connect", ssid]);
    if rc == 0 {
        return;
    }
    let theme = rofi_theme();
    let pass = Command::new("rofi")
        .args(["-dmenu", "-p", &format!("Password for {}", ssid), "-password", "-theme-str", &theme])
        .output()
        .unwrap_or_else(|_| std::process::Command::new("true").output().unwrap());
    if pass.status.success() {
        let pw = String::from_utf8_lossy(&pass.stdout).trim().to_string();
        if !pw.is_empty() {
            run_rc(&["device", "wifi", "connect", ssid, "password", &pw]);
        }
    }
}

fn details() {
    let out = run(&["-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]);
    let mut dev = String::new();
    for line in out.lines() {
        let parts: Vec<&str> = line.splitn(3, ':').collect();
        if parts.len() >= 3 && parts[2].starts_with("connected") {
            dev = parts[0].to_string();
            break;
        }
    }
    let mut lines: Vec<String> = Vec::new();
    if dev.is_empty() {
        lines.push("No active connection.".into());
    } else {
        let d = run(&["-t", "device", "show", &dev]);
        for line in d.lines() {
            if let Some(v) = line.strip_prefix("GENERAL.DEVICE:") {
                if !v.is_empty() { lines.push(format!("Device: {}", v)); }
            } else if let Some(v) = line.strip_prefix("GENERAL.TYPE:") {
                if !v.is_empty() { lines.push(format!("Type: {}", v)); }
            } else if let Some(v) = line.strip_prefix("GENERAL.CONNECTION:") {
                if !v.is_empty() { lines.push(format!("Connection: {}", v)); }
            } else if let Some(v) = line.strip_prefix("IP4.ADDRESS[1]:").or_else(|| line.strip_prefix("IP4.ADDRESS:")) {
                if !v.is_empty() { lines.push(format!("IP: {}", v)); }
            } else if let Some(v) = line.strip_prefix("IP4.GATEWAY:") {
                if !v.is_empty() { lines.push(format!("Gateway: {}", v)); }
            } else if let Some(v) = line.strip_prefix("IP4.DNS[1]:").or_else(|| line.strip_prefix("IP4.DNS:")) {
                if !v.is_empty() { lines.push(format!("DNS: {}", v)); }
            }
        }
    }
    if lines.is_empty() {
        lines.push("No connection details available.".into());
    }
    let theme = rofi_theme();
    let _ = Command::new("rofi")
        .args(["-e", &lines.join("\n"), "-theme-str", &theme])
        .status();
}

fn rofi_theme() -> String {
    concat!(
        "#window {width: 420px; border-radius: 12px; background-color: #141418; border: 2px; border-color: #7caeff;} ",
        "#mainbox {padding: 10px; background-color: #141418; border-radius: 10px;} ",
        "#inputbar {children: [prompt,entry]; background-color: rgba(255,255,255,5%); border-radius: 8px; padding: 8px; margin: 4px 0px;} ",
        "#prompt {text-color: #7caeff; font: \"JetBrainsMono Nerd Font 11\";} ",
        "#entry {text-color: #e0e0e0; font: \"JetBrainsMono Nerd Font 11\";} ",
        "#listview {spacing: 6px; padding: 4px 0px;} ",
        "#element {padding: 8px 12px; border-radius: 8px; font: \"JetBrainsMono Nerd Font 11\";} ",
        "element selected {background-color: rgba(124, 174, 255, 15%); text-color: #7caeff;} ",
        "#scrollbar {width: 4px; border-radius: 2px; background-color: rgba(255,255,255,5%);} ",
        "#scrollbar handle {background-color: rgba(124, 174, 255, 30%); border-radius: 2px;} "
    )
    .to_string()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(|s| s.as_str()) {
        Some("--menu") => menu(),
        Some("--toggle") => toggle(),
        Some("--disconnect") => disconnect(),
        Some("--details") => details(),
        Some(_) | None => status(),
    }
}
