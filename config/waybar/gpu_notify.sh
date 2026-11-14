#!/usr/bin/env bash
# gpu_notify.sh — Show GPU info notification

GPU_NAME=$(lspci 2>/dev/null | grep -E "VGA|3D" | grep -i "NVIDIA" | sed 's/.*: //')
GPU_NAME=${GPU_NAME:-"NVIDIA Dedicated GPU"}

GPU_TEMP="N/A"
GPU_UTIL="N/A"
GPU_MEM_USED="?"
GPU_MEM_TOTAL="?"

if command -v nvidia-smi &>/dev/null; then
    INFO=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null)
    if [ -n "$INFO" ]; then
        IFS=',' read -r GPU_TEMP GPU_UTIL GPU_MEM_USED GPU_MEM_TOTAL <<< "$INFO"
        GPU_TEMP=$(echo "$GPU_TEMP" | xargs)
        GPU_UTIL=$(echo "$GPU_UTIL" | xargs)
        GPU_MEM_USED=$(echo "$GPU_MEM_USED" | xargs)
        GPU_MEM_TOTAL=$(echo "$GPU_MEM_TOTAL" | xargs)
    fi
elif command -v nvidia-settings &>/dev/null; then
    GPU_TEMP=$(nvidia-settings -q GPUCoreTemp -t 2>/dev/null || echo "N/A")
    GPU_UTIL=$(nvidia-settings -q GPUUtilization -t 2>/dev/null || echo "N/A")
    GPU_MEM_USED=$(nvidia-settings -q UsedDedicatedGPUMemory -t 2>/dev/null || echo "?")
    GPU_MEM_TOTAL=$(nvidia-settings -q TotalDedicatedGPUMemory -t 2>/dev/null || echo "?")
fi

notify-send -t 5000 "${GPU_NAME}" \
    "Temp: ${GPU_TEMP}°C\nUtil: ${GPU_UTIL}%\nMemory: ${GPU_MEM_USED}/${GPU_MEM_TOTAL} MB"
