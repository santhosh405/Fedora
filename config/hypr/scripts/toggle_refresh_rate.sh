#!/usr/bin/env bash
# toggle_refresh_rate.sh — Toggle display refresh rate between 60Hz and 144Hz

CURRENT_HZ=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].refreshRate // 144' | cut -d. -f1)

if [ "$CURRENT_HZ" -ge 100 ]; then
    NEW_HZ=60
else
    NEW_HZ=144
fi

# Apply the new refresh rate
hyprctl eval "hl.monitor({ output = 'eDP-1', mode = '1920x1200@${NEW_HZ}', position = '0x0', scale = '1.5' })" >/dev/null 2>&1

notify-send -r 9993 -t 1500 -i video-display "Display Refresh Rate" "Switched to ${NEW_HZ}Hz"
