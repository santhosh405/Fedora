#!/usr/bin/env bash
# ==============================================================================
# Fedora 44 Hyprland Rice & Dotfiles Installer
# Repository: https://github.com/santhosh405/Fedora
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config"
LOCAL_BIN="$USER_HOME/.local/bin"
LOCAL_SHARE="$USER_HOME/.local/share"

RED='\033[0;31m'
GREEN='\033[0;32m'
GOLD='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Fedora Hyprland Rice Installer              ║"
echo "║          https://github.com/santhosh405/Fedora       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}Select an installation option:${NC}"
echo "1) Full Installation (Repos + Packages + Configs + Rust Builds + Assets)"
echo "2) Deploy Dotfiles & Scripts Only (No DNF package installations)"
echo "3) Restore DNF & Flatpak Packages Only"
echo "4) Exit"
read -rp "Enter choice [1-4]: " choice

case "$choice" in
    1)
        echo -e "\n${GOLD}---> Starting Full Installation...${NC}"
        ;;
    2)
        echo -e "\n${GOLD}---> Deploying Dotfiles & Scripts only...${NC}"
        ;;
    3)
        echo -e "\n${GOLD}---> Restoring Packages only...${NC}"
        ;;
    *)
        echo "Exiting."
        exit 0
        ;;
esac

# ------------------------------------------------------------------------------
# Package Installation (Options 1 & 3)
# ------------------------------------------------------------------------------
if [ "$choice" -eq 1 ] || [ "$choice" -eq 3 ]; then
    echo -e "\n${BLUE}Verifying sudo permissions...${NC}"
    sudo -v

    echo -e "\n${GOLD}[1/3] Enabling RPM Fusion & Hyprland COPR Repositories...${NC}"
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

    sudo dnf copr enable -y ashbuk/Hyprland-Fedora || true
    sudo dnf copr enable -y erikreider/SwayNotificationCenter 2>/dev/null || true

    echo -e "\n${GOLD}[2/3] Installing Hyprland, Waybar, Kitty, and Rice Tools...${NC}"
    sudo dnf install -y \
        hyprland \
        xdg-desktop-portal-hyprland \
        SwayNotificationCenter \
        waybar \
        kitty \
        cava \
        rofi-wayland \
        wofi \
        pavucontrol \
        brightnessctl \
        wireplumber \
        playerctl \
        grim \
        slurp \
        wl-clipboard \
        network-manager-applet \
        polkit-gnome \
        btop \
        fastfetch \
        mpd \
        ncmpcpp \
        python3-gobject \
        python3-pip \
        gtk3 \
        gtk4 \
        gtk4-devel \
        glib2-devel \
        gcc \
        cargo \
        rust \
        pkg-config \
        zsh || true

    echo -e "\n${GOLD}[3/3] Installing Python dependencies...${NC}"
    pip3 install --user --upgrade PySide6 psutil pywal 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Config & Asset Deployment (Options 1 & 2)
# ------------------------------------------------------------------------------
if [ "$choice" -eq 1 ] || [ "$choice" -eq 2 ]; then
    echo -e "\n${GOLD}[1/5] Deploying Configuration Files to ~/.config...${NC}"
    mkdir -p "$CONFIG_DIR"
    cp -r "$DOTFILES_DIR"/config/* "$CONFIG_DIR"/

    echo -e "\n${GOLD}[2/5] Deploying Shell Configurations...${NC}"
    cp -b "$DOTFILES_DIR"/shell/.zshrc "$USER_HOME"/.zshrc
    cp -b "$DOTFILES_DIR"/shell/.bashrc "$USER_HOME"/.bashrc
    cp -b "$DOTFILES_DIR"/shell/.bash_profile "$USER_HOME"/.bash_profile

    echo -e "\n${GOLD}[3/5] Deploying Custom Scripts to ~/.local/bin...${NC}"
    mkdir -p "$LOCAL_BIN"
    for s in "$DOTFILES_DIR"/scripts/*; do
        if [ -f "$s" ]; then
            install -m 755 "$s" "$LOCAL_BIN"/
        fi
    done

    echo -e "\n${GOLD}[4/5] Deploying Desktop Entries & Wallpapers...${NC}"
    mkdir -p "$LOCAL_SHARE/applications"
    if [ -d "$DOTFILES_DIR/applications" ]; then
        cp -r "$DOTFILES_DIR"/applications/* "$LOCAL_SHARE/applications/"
        update-desktop-database "$LOCAL_SHARE/applications/" 2>/dev/null || true
    fi

    mkdir -p "$USER_HOME/Pictures/wallpapers"
    if [ -d "$DOTFILES_DIR/assets/wallpapers" ]; then
        cp -r "$DOTFILES_DIR"/assets/wallpapers/* "$USER_HOME/Pictures/wallpapers/"
    fi

    if [ -d "$DOTFILES_DIR/assets/themes" ]; then
        mkdir -p "$LOCAL_SHARE/themes"
        cp -r "$DOTFILES_DIR"/assets/themes/* "$LOCAL_SHARE/themes/"
    fi

    if [ -d "$DOTFILES_DIR/assets/icons" ]; then
        mkdir -p "$LOCAL_SHARE/icons"
        cp -r "$DOTFILES_DIR"/assets/icons/* "$LOCAL_SHARE/icons/"
    fi

    echo -e "\n${GOLD}[5/5] Building Custom Rust Components...${NC}"
    if command -v cargo &>/dev/null; then
        if [ -d "$CONFIG_DIR/waybar/wifi-module" ]; then
            echo "  -> Compiling Waybar Wifi Module..."
            (cd "$CONFIG_DIR/waybar/wifi-module" && cargo build --release 2>/dev/null || true)
        fi
        if [ -d "$CONFIG_DIR/hypr/app-launcher" ]; then
            echo "  -> Compiling Hyprland App Launcher..."
            (cd "$CONFIG_DIR/hypr/app-launcher" && cargo build --release 2>/dev/null || true)
        fi
        if [ -d "$CONFIG_DIR/hypr/control-panel" ]; then
            echo "  -> Compiling Hyprland Control Panel..."
            (cd "$CONFIG_DIR/hypr/control-panel" && cargo build --release 2>/dev/null || true)
        fi
    fi

    # Set executable permissions on script directories
    chmod +x "$CONFIG_DIR"/waybar/*.sh 2>/dev/null || true
    chmod +x "$CONFIG_DIR"/hypr/scripts/*.sh 2>/dev/null || true
    chmod +x "$CONFIG_DIR"/hypr/scripts/*.py 2>/dev/null || true
    chmod +x "$CONFIG_DIR"/rofi/*.sh 2>/dev/null || true
fi

echo -e "\n${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Setup operation completed successfully!            ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
