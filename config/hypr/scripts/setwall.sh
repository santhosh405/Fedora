#!/usr/bin/env bash
# =========================================================
# Dynamic Wallpaper & Pywal Color Changer
# =========================================================

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

# If wofi is already running, toggle it off
if pgrep -x wofi > /dev/null; then
    pkill -x wofi
    exit 0
fi

WALL_DIR="$HOME/Pictures/wallpapers"
KITTY_COLORS="$HOME/.cache/wal/colors-kitty.conf"

# Ensure swww-daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    systemctl --user start swww.service 2>/dev/null || (swww-daemon &)
    sleep 0.5
fi

# Pick wallpaper
if [ -n "$1" ] && [ -f "$1" ]; then
    WALL="$1"
else
    CHOICE=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.gif" \) -exec basename {} \; | sort | wofi --dmenu --prompt "Select Wallpaper:" --conf "$HOME/.config/wofi/config" --style "$HOME/.config/wofi/style.css")
    [ -z "$CHOICE" ] && exit 0
    WALL="$WALL_DIR/$CHOICE"
fi

[ ! -f "$WALL" ] && exit 1

# Apply wallpaper with smooth transition
swww img "$WALL" --transition-type outer --transition-duration 1 --transition-fps 60

# Generate color scheme with Pywal
wal -i "$WALL" -n -q

# Restart Waybar with updated pywal CSS palette
systemctl --user restart waybar.service 2>/dev/null || (pkill waybar && nohup waybar >/dev/null 2>&1 &)

# Reload desktop clock widget with new colors
systemctl --user reload-or-restart home-clock.service 2>/dev/null || true

# Reload Hyprland borders
hyprctl reload 2>/dev/null || true

# Reload Kitty terminal colors across running instances
kitty @ set-colors --all "$KITTY_COLORS" 2>/dev/null || true

# Send notification if notify-send exists
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Theme" "Wallpaper Updated" "$(basename "$WALL")" -i "$WALL"
fi
