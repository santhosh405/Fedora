#!/usr/bin/env bash
# ==============================================================================
# Fedora 44 - Hyprland Installation & GDM Login Setup
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
GOLD='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Fedora 44 - Hyprland Login Setup            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config"

echo -e "${BLUE}Requesting root permissions to install Hyprland...${NC}"
sudo -v

# 1. Enable active Fedora 44 Hyprland and SwayNC COPR repositories
echo -e "\n${GOLD}[1/4] Enabling COPR repositories for Fedora 44...${NC}"
sudo dnf copr enable -y ashbuk/Hyprland-Fedora
sudo dnf copr enable -y erikreider/SwayNotificationCenter 2>/dev/null || true

# 2. Install Hyprland and core rice packages
echo -e "\n${GOLD}[2/4] Installing Hyprland, Waybar, Kitty, and desktop portals...${NC}"
sudo dnf install -y \
    hyprland \
    xdg-desktop-portal-hyprland \
    SwayNotificationCenter \
    waybar \
    kitty \
    cava \
    rofi-wayland \
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
    gtk3 \
    gtk4 \
    gtk4-devel \
    glib2-devel \
    gcc \
    cargo \
    rust \
    pkg-config \
    python3-pip \
    python3-gobject

# 3. Ensure the Wayland session file exists for GDM login screen
echo -e "\n${GOLD}[3/4] Ensuring /usr/share/wayland-sessions/hyprland.desktop exists...${NC}"
sudo mkdir -p /usr/share/wayland-sessions
if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
fi

# 4. Build custom Rust binaries (wifi-module, app-launcher, control-panel)
echo -e "\n${GOLD}[4/4] Building custom rice binaries (Launcher, Control Panel, Wifi Module)...${NC}"
if command -v cargo &>/dev/null; then
    if [ -d "$CONFIG_DIR/waybar/wifi-module" ]; then
        (cd "$CONFIG_DIR/waybar/wifi-module" && cargo build --release 2>/dev/null || true)
    fi
    if [ -d "$CONFIG_DIR/hypr/app-launcher" ]; then
        (cd "$CONFIG_DIR/hypr/app-launcher" && cargo build --release 2>/dev/null || true)
    fi
    if [ -d "$CONFIG_DIR/hypr/control-panel" ]; then
        (cd "$CONFIG_DIR/hypr/control-panel" && cargo build --release 2>/dev/null || true)
    fi
fi

# Install Python requirements
pip3 install --user --upgrade PySide6 psutil 2>/dev/null || true

echo -e "\n${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Hyprland has been installed successfully!         ${NC}"
echo -e "${GREEN}  ✓ Hyprland entry created in GDM login screen!        ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "To log into Hyprland now:"
echo "1. Log out or run: gnome-session-quit --logout --no-prompt"
echo "2. On the login screen, click your name, then click the gear ⚙️ icon in the bottom right."
echo "3. Select 'Hyprland' and log in."
