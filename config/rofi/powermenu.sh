#!/usr/bin/env bash
# Power menu script for Hyprland / Waybar

options=" Lock\n Logout\n Suspend\n Reboot\n Shutdown"

if command -v wofi &>/dev/null; then
    chosen=$(echo -e "$options" | wofi --dmenu -p "Power Menu" --width 240 --height 210 --style "$HOME/.config/wofi/style.css" 2>/dev/null || echo -e "$options" | wofi --dmenu -p "Power Menu")
elif command -v rofi &>/dev/null; then
    chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu:" -theme-str 'window {width: 250px; border-radius: 12px;}')
elif command -v zenity &>/dev/null; then
    chosen=$(zenity --list --title="Power Menu" --column="Action" "Lock" "Logout" "Suspend" "Reboot" "Shutdown")
else
    chosen=$(echo -e "$options" | fzf 2>/dev/null)
fi

case "$chosen" in
    *"Lock"*)
        command -v hyprlock &>/dev/null && hyprlock || loginctl lock-session
        ;;
    *"Logout"*)
        hyprctl dispatch exit || loginctl terminate-user "$USER"
        ;;
    *"Suspend"*)
        systemctl suspend
        ;;
    *"Reboot"*)
        systemctl reboot
        ;;
    *"Shutdown"*)
        systemctl poweroff
        ;;
esac
