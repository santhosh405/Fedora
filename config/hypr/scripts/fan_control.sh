#!/usr/bin/env bash
# fan_control.sh — Adjusts fan speed / thermal profile and sends a notification.
# Supports ASUS TUF/ROG (asus-nb-wmi), HP (hp-wmi), and standard hwmon PWM.
# Uses flock to prevent async race conditions when keys are held down.

LOCK_FILE="/tmp/fan_control.lock"

(
    flock -x 200

    # ========================================================
    # 1. ASUS TUF / ROG Support (asus-nb-wmi)
    # ========================================================
    ASUS_POLICY="/sys/devices/platform/asus-nb-wmi/throttle_thermal_policy"

    if [ -f "$ASUS_POLICY" ]; then
        CURR_POLICY=$(cat "$ASUS_POLICY" 2>/dev/null)
        CURR_POLICY=${CURR_POLICY:-0}

        # ASUS Thermal Policies:
        # 2 = Silent / Quiet
        # 0 = Balanced / Standard
        # 1 = Turbo / Performance
        case "$1" in
            up)
                case "$CURR_POLICY" in
                    2) NEW_POLICY=0; MODE_NAME="Balanced" ;;
                    0) NEW_POLICY=1; MODE_NAME="Turbo / Performance" ;;
                    1) NEW_POLICY=1; MODE_NAME="Turbo / Performance (Max)" ;;
                    *) NEW_POLICY=0; MODE_NAME="Balanced" ;;
                esac
                ;;
            down)
                case "$CURR_POLICY" in
                    1) NEW_POLICY=0; MODE_NAME="Balanced" ;;
                    0) NEW_POLICY=2; MODE_NAME="Silent / Quiet" ;;
                    2) NEW_POLICY=2; MODE_NAME="Silent / Quiet (Min)" ;;
                    *) NEW_POLICY=2; MODE_NAME="Silent / Quiet" ;;
                esac
                ;;
            max|turbo|performance)
                NEW_POLICY=1
                MODE_NAME="Turbo / Performance"
                ;;
            balanced|normal)
                NEW_POLICY=0
                MODE_NAME="Balanced"
                ;;
            silent|quiet|off|min)
                NEW_POLICY=2
                MODE_NAME="Silent / Quiet"
                ;;
            *)
                echo "Usage: $0 {up|down|max|balanced|silent}"
                exit 1
                ;;
        esac

        SUCCESS=0
        if echo "$NEW_POLICY" > "$ASUS_POLICY" 2>/dev/null; then
            SUCCESS=1
        elif sudo -n sh -c "echo $NEW_POLICY > $ASUS_POLICY" 2>/dev/null; then
            SUCCESS=1
        fi

        # Read live fan RPMs
        CPU_RPM=$(cat /sys/devices/platform/asus-nb-wmi/hwmon/hwmon*/fan1_input 2>/dev/null | head -n 1)
        GPU_RPM=$(cat /sys/devices/platform/asus-nb-wmi/hwmon/hwmon*/fan2_input 2>/dev/null | head -n 1)
        RPM_INFO=""
        [ -n "$CPU_RPM" ] && RPM_INFO="CPU: ${CPU_RPM} RPM"
        [ -n "$GPU_RPM" ] && RPM_INFO="${RPM_INFO:+$RPM_INFO | }GPU: ${GPU_RPM} RPM"

        if [ "$SUCCESS" -eq 1 ]; then
            MSG="Profile: ${MODE_NAME}"
            if [ "$NEW_POLICY" -eq 1 ]; then
                MSG="${MSG} [Full Speed / Max Boost]"
            fi
            [ -n "$RPM_INFO" ] && MSG="${MSG}\nCurrent: ${RPM_INFO}"
            notify-send -r 9991 -t 2000 -i kcmthermal "ASUS Fan Control" "$MSG" &
        else
            notify-send -r 9991 -t 4000 -i dialog-warning "Fan Control Permission Required" "Run once in terminal:\nsudo chmod 666 $ASUS_POLICY" &
        fi
        exit 0
    fi

    # ========================================================
    # 2. HP / Generic PWM Fallback
    # ========================================================
    PWM_PATH=$(glob() { echo "$1"; }; glob /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1)
    ENABLE_PATH=$(glob() { echo "$1"; }; glob /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1_enable)

    if [ ! -f "$PWM_PATH" ]; then
        notify-send -t 2000 -i dialog-error "Fan Control" "Error: Fan control device not found!"
        exit 1
    fi

    CURRENT_VAL=$(cat "$PWM_PATH" 2>/dev/null)
    CURRENT_VAL=${CURRENT_VAL:-0}
    STEP=26

    case "$1" in
        up)
            NEW_VAL=$((CURRENT_VAL + STEP))
            [ $NEW_VAL -gt 255 ] && NEW_VAL=255
            ;;
        down)
            NEW_VAL=$((CURRENT_VAL - STEP))
            [ $NEW_VAL -lt 0 ] && NEW_VAL=0
            ;;
        max)
            NEW_VAL=255
            ;;
        off)
            NEW_VAL=0
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 0 ] && [ "$1" -le 255 ]; then
                NEW_VAL="$1"
            else
                echo "Usage: $0 {up|down|max|off|value}"
                exit 1
            fi
            ;;
    esac

    if [ -f "$ENABLE_PATH" ]; then
        echo "1" > "$ENABLE_PATH" 2>/dev/null
    fi

    PCT=$(( NEW_VAL * 100 / 255 ))
    if echo "$NEW_VAL" > "$PWM_PATH" 2>/dev/null; then
        notify-send -r 9991 -t 1500 -i kcmthermal "Fan Control" "Speed: ${PCT}% (${NEW_VAL}/255)" &
    else
        sudo sh -c "echo $NEW_VAL > $PWM_PATH" 2>/dev/null && \
        notify-send -r 9991 -t 1500 -i kcmthermal "Fan Control" "Speed: ${PCT}% (${NEW_VAL}/255) [sudo]" &
    fi

) 200>"$LOCK_FILE"
