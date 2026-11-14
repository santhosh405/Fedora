#!/usr/bin/env bash
# gpu_info.sh — Dedicated GPU monitor (Waybar custom module)

GPU_NAME=$(lspci 2>/dev/null | grep -E "VGA|3D" | grep -i "NVIDIA" | sed 's/.*: //')
GPU_NAME=${GPU_NAME:-"NVIDIA GPU"}

GPU_TEMP="N/A"
GPU_UTIL="N/A"
GPU_MEM_USED="N/A"
GPU_MEM_TOTAL="N/A"
GPU_CLOCK="N/A"

if command -v nvidia-smi &>/dev/null; then
    INFO=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total,clocks.current.graphics --format=csv,noheader,nounits 2>/dev/null)
    if [ -n "$INFO" ]; then
        IFS=',' read -r GPU_TEMP GPU_UTIL GPU_MEM_USED GPU_MEM_TOTAL GPU_CLOCK <<< "$INFO"
        GPU_TEMP=$(echo "$GPU_TEMP" | xargs)
        GPU_UTIL=$(echo "$GPU_UTIL" | xargs)
        GPU_MEM_USED=$(echo "$GPU_MEM_USED" | xargs)
        GPU_MEM_TOTAL=$(echo "$GPU_MEM_TOTAL" | xargs)
        GPU_CLOCK=$(echo "$GPU_CLOCK" | xargs)
    fi
elif command -v nvidia-settings &>/dev/null; then
    GT=$(nvidia-settings -q GPUCoreTemp -t 2>/dev/null)
    [ -n "$GT" ] && GPU_TEMP="$GT"

    GU=$(nvidia-settings -q GPUUtilization -t 2>/dev/null)
    if [ -n "$GU" ]; then
        GPU_UTIL=$(echo "$GU" | grep -oP 'graphics=\K\d+')
        GPU_UTIL=${GPU_UTIL:-0}
    fi

    GMU=$(nvidia-settings -q UsedDedicatedGPUMemory -t 2>/dev/null)
    GMT=$(nvidia-settings -q TotalDedicatedGPUMemory -t 2>/dev/null)
    [ -n "$GMU" ] && GPU_MEM_USED="$GMU"
    [ -n "$GMT" ] && GPU_MEM_TOTAL="$GMT"

    GC=$(nvidia-settings -q GPUCurrentClockFreqs -t 2>/dev/null | head -1)
    [ -n "$GC" ] && GPU_CLOCK="$GC"
fi

# Color by utilization
if [ "$GPU_UTIL" != "N/A" ] && [ "$GPU_UTIL" -ge 0 ] 2>/dev/null; then
    if [ "$GPU_UTIL" -gt 80 ]; then
        CLASS="high"
    elif [ "$GPU_UTIL" -gt 40 ]; then
        CLASS="mid"
    else
        CLASS="low"
    fi
else
    CLASS="low"
fi

if [ "$GPU_TEMP" != "N/A" ]; then
    if [ "$GPU_UTIL" != "N/A" ] && [ "$GPU_UTIL" -gt 0 ] 2>/dev/null; then
        TEXT="󰢮 ${GPU_TEMP}°C ${GPU_UTIL}%"
    else
        TEXT="󰢮 ${GPU_TEMP}°C"
    fi
else
    TEXT="󰢮 Standby"
fi

TOOLTIP="${GPU_NAME}\nTemp: ${GPU_TEMP}°C\nUtil: ${GPU_UTIL}%\nMemory: ${GPU_MEM_USED} / ${GPU_MEM_TOTAL} MB\nClock: ${GPU_CLOCK} MHz"

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
