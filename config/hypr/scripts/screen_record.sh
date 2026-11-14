#!/usr/bin/env bash
# screen_record.sh — Reliable Screen Recorder for Hyprland
# Toggle recording: Press Super + R to start, press Super + R (or Super + Shift + R) to stop

PID_FILE="/tmp/wf-recorder.pid"
RECORDING_INFO="/tmp/wf-recorder.file"

# If already recording, stop cleanly using SIGINT so the MP4/video trailer is properly written
if pgrep -f wf-recorder >/dev/null 2>&1; then
    pkill -INT -f wf-recorder
    SAVED_FILE="$(cat "$RECORDING_INFO" 2>/dev/null)"
    rm -f "$PID_FILE" "$RECORDING_INFO"
    sleep 0.5
    if [ -n "$SAVED_FILE" ] && [ -f "$SAVED_FILE" ]; then
        notify-send -r 9995 -t 4000 -i video-display "Screen Recording Saved" "Saved to $(basename "$SAVED_FILE") in ~/Videos"
    else
        notify-send -r 9995 -t 4000 -i video-display "Screen Recording Saved" "Saved video to ~/Videos"
    fi
    exit 0
fi

# Ensure Videos directory exists
mkdir -p "$HOME/Videos"

# Select region or fullscreen
if [ "$1" = "full" ]; then
    GEOM=""
else
    # Prompt user with crosshair selection
    GEOM=$(slurp 2>/dev/null)
    # If selection was cancelled (e.g. user pressed Esc), exit cleanly
    if [ $? -ne 0 ] || [ -z "$GEOM" ]; then
        exit 0
    fi
fi

# Determine optimal encoder supported by FFmpeg
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
if ffmpeg -encoders 2>/dev/null | grep -qw "libx264"; then
    CODEC_ARGS=("-c" "libx264" "-x" "yuv420p")
    OUT_FILE="$HOME/Videos/recording_${TIMESTAMP}.mp4"
elif [ -s /usr/lib64/libopenh264.so.2.6.0 ] && [ "$(stat -c%s /usr/lib64/libopenh264.so.2.6.0 2>/dev/null || echo 0)" -gt 50000 ]; then
    CODEC_ARGS=("-c" "libopenh264" "-x" "yuv420p")
    OUT_FILE="$HOME/Videos/recording_${TIMESTAMP}.mp4"
elif ffmpeg -encoders 2>/dev/null | grep -qw "mpeg4"; then
    CODEC_ARGS=("-c" "mpeg4" "-x" "yuv420p")
    OUT_FILE="$HOME/Videos/recording_${TIMESTAMP}.mp4"
else
    CODEC_ARGS=("-c" "libvpx-vp9" "-m" "webm")
    OUT_FILE="$HOME/Videos/recording_${TIMESTAMP}.webm"
fi

echo "$OUT_FILE" > "$RECORDING_INFO"

notify-send -r 9995 -t 3000 -i video-display "Screen Recording" "Recording started... (Press Super+R to stop)"

if [ -n "$GEOM" ]; then
    wf-recorder "${CODEC_ARGS[@]}" -g "$GEOM" -f "$OUT_FILE" &
else
    wf-recorder "${CODEC_ARGS[@]}" -f "$OUT_FILE" &
fi

echo $! > "$PID_FILE"
