#!/usr/bin/env python3
"""
Interactive Bluetooth menu for Waybar using Wofi.
Supports:
- Toggle Bluetooth On/Off
- Fast device connection / disconnection
- Device scanning & pairing
- Device unpairing / removal
- Direct launch of GUI Settings
"""

import sys
import subprocess
import re
import time

def run_cmd(args, timeout=10):
    try:
        res = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return res.stdout.strip()
    except Exception:
        return ""

def notify(summary, body="", icon="bluetooth"):
    try:
        subprocess.Popen(["notify-send", "-i", icon, summary, body],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def wofi_select(prompt, options):
    if not options:
        return None
    input_str = "\n".join(options)
    try:
        proc = subprocess.Popen(
            ["wofi", "--dmenu", "--prompt", prompt, "--width", "480", "--height", "380", "--insensitive"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True
        )
        stdout, _ = proc.communicate(input=input_str)
        selected = stdout.strip()
        return selected if selected else None
    except Exception:
        return None

def is_powered():
    out = run_cmd(["bluetoothctl", "show"])
    return "Powered: yes" in out

def open_settings():
    # If blueman-manager is installed from system repos, use it
    if subprocess.run(["which", "blueman-manager"], capture_output=True).returncode == 0:
        subprocess.Popen(["blueman-manager"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        env = dict(subprocess.os.environ)
        env["XDG_CURRENT_DESKTOP"] = "GNOME"
        subprocess.Popen(["gnome-control-center", "bluetooth"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def get_devices():
    out = run_cmd(["bluetoothctl", "devices"])
    devices = []
    for line in out.splitlines():
        match = re.match(r"^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$", line.strip())
        if match:
            mac, name = match.group(1), match.group(2).strip()
            devices.append((mac, name))
    return devices

def get_device_info(mac):
    out = run_cmd(["bluetoothctl", "info", mac])
    connected = "Connected: yes" in out
    paired = "Paired: yes" in out
    trusted = "Trusted: yes" in out
    name_match = re.search(r"Alias:\s+(.+)", out) or re.search(r"Name:\s+(.+)", out)
    name = name_match.group(1).strip() if name_match else mac
    return {
        "mac": mac,
        "name": name,
        "connected": connected,
        "paired": paired,
        "trusted": trusted
    }

def scan_and_pair():
    notify("Bluetooth", "Scanning for nearby devices (5s)...")
    run_cmd(["bluetoothctl", "--timeout", "6", "scan", "on"], timeout=8)
    
    devices = get_devices()
    if not devices:
        notify("Bluetooth", "No devices found nearby.")
        return

    options = []
    mac_map = {}
    for mac, name in devices:
        info = get_device_info(mac)
        label = f"󰂯 {name} ({mac})"
        if info["connected"]:
            label += " [Connected]"
        elif info["paired"]:
            label += " [Paired]"
        options.append(label)
        mac_map[label] = (mac, name)

    selected = wofi_select("Select Device to Connect/Pair", options)
    if not selected or selected not in mac_map:
        return

    mac, name = mac_map[selected]
    notify("Bluetooth", f"Pairing & connecting to {name}...")
    run_cmd(["bluetoothctl", "pairable", "on"])
    run_cmd(["bluetoothctl", "pair", mac], timeout=15)
    run_cmd(["bluetoothctl", "trust", mac], timeout=5)
    res = run_cmd(["bluetoothctl", "connect", mac], timeout=15)
    
    if "Connection successful" in res or get_device_info(mac)["connected"]:
        notify("Bluetooth", f"Connected to {name}!", icon="bluetooth-active")
    else:
        notify("Bluetooth", f"Attempted connection to {name}. Check device mode.")

def main_menu():
    powered = is_powered()

    if not powered:
        options = [
            "󰂯  Turn Bluetooth On",
            "󰒓  Open Bluetooth Settings (GUI)"
        ]
        choice = wofi_select("Bluetooth is Off", options)
        if choice == "󰂯  Turn Bluetooth On":
            run_cmd(["rfkill", "unblock", "bluetooth"])
            run_cmd(["bluetoothctl", "power", "on"])
            run_cmd(["bluetoothctl", "pairable", "on"])
            notify("Bluetooth", "Bluetooth powered on")
        elif choice == "󰒓  Open Bluetooth Settings (GUI)":
            open_settings()
        return

    # Bluetooth is ON
    devices = get_devices()
    device_info_list = [get_device_info(mac) for mac, _ in devices]
    
    # Header actions
    options = [
        "󰂲  Turn Bluetooth Off",
        "󰑐  Scan for Nearby Devices",
        "󰒓  Open Bluetooth Settings (GUI)"
    ]

    action_map = {}
    
    paired_items = [d for d in device_info_list if d["paired"] or d["connected"]]
    if paired_items:
        options.append("────────────────────────────")
        for d in paired_items:
            if d["connected"]:
                label = f"󰂱  {d['name']} (Connected)"
            else:
                label = f"󰂯  {d['name']} (Paired)"
            options.append(label)
            action_map[label] = d

    choice = wofi_select("Bluetooth Manager", options)
    if not choice:
        return

    if choice == "󰂲  Turn Bluetooth Off":
        run_cmd(["bluetoothctl", "power", "off"])
        notify("Bluetooth", "Bluetooth powered off")
    elif choice == "󰑐  Scan for Nearby Devices":
        scan_and_pair()
    elif choice == "󰒓  Open Bluetooth Settings (GUI)":
        open_settings()
    elif choice in action_map:
        d = action_map[choice]
        if d["connected"]:
            # Device action menu
            sub_options = [
                f"󰂲  Disconnect {d['name']}",
                f"󰅖  Unpair / Forget {d['name']}",
                "󰅚  Cancel"
            ]
            sub_choice = wofi_select(f"{d['name']} Options", sub_options)
            if sub_choice == f"󰂲  Disconnect {d['name']}":
                run_cmd(["bluetoothctl", "disconnect", d["mac"]])
                notify("Bluetooth", f"Disconnected from {d['name']}")
            elif sub_choice == f"󰅖  Unpair / Forget {d['name']}":
                run_cmd(["bluetoothctl", "remove", d["mac"]])
                notify("Bluetooth", f"Removed {d['name']}")
        else:
            notify("Bluetooth", f"Connecting to {d['name']}...")
            res = run_cmd(["bluetoothctl", "connect", d["mac"]], timeout=15)
            if "Connection successful" in res or get_device_info(d["mac"])["connected"]:
                notify("Bluetooth", f"Connected to {d['name']}!", icon="bluetooth-active")
            else:
                notify("Bluetooth", f"Could not connect to {d['name']}. Is it turned on?")

if __name__ == "__main__":
    main_menu()
