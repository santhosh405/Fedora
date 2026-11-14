#!/usr/bin/env bash
# wireless_cast.sh — Toggle Wireless Screen Casting (Miracast / Wi-Fi Display / Chromecast)
# Triggered by Super + K

# Ensure systemd graphical session & desktop portals are active
systemctl --user start hyprland-session.target 2>/dev/null
systemctl --user start xdg-desktop-portal-hyprland 2>/dev/null
systemctl --user start xdg-desktop-portal 2>/dev/null

if pgrep -f gnome-network-displays >/dev/null 2>&1; then
    pkill -f gnome-network-displays || killall gnome-network-displays
    notify-send -r 9994 -t 2000 -i video-display "Wireless Display" "Closed screen casting"
else
    notify-send -r 9994 -t 3000 -i video-display "Wireless Display" "Scanning for wireless displays (Miracast / Chromecast)..."
    GDK_BACKEND=wayland gnome-network-displays &
fi
