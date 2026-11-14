#!/usr/bin/env bash
# fan_notify.sh — Show fan speed notification

FAN1=0
FAN2=0
for name_file in /sys/class/hwmon/hwmon*/name; do
    if [ -f "$name_file" ]; then
        n=$(cat "$name_file" 2>/dev/null)
        if [ "$n" = "asus" ] || [ "$n" = "msi_wmi_platform" ] || [ "$n" = "hp" ]; then
            DIR=$(dirname "$name_file")
            FAN1=$(cat "$DIR/fan1_input" 2>/dev/null || echo 0)
            FAN2=$(cat "$DIR/fan2_input" 2>/dev/null || echo 0)
            break
        fi
    fi
done

notify-send -t 3000 "Fan Speeds" "CPU Fan: ${FAN1} RPM\nGPU Fan: ${FAN2} RPM"
