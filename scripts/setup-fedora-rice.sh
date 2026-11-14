#!/usr/bin/env bash
# ==============================================================================
# Fedora Ricing - Complete Setup & Dependencies Installer
# Configured for: gurunesh30/fedora-ricing
# System: Fedora Linux 44
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
GOLD='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Fedora Hyprland Ricing Installer            ║"
echo "║          Ghost of Tsushima & Rose Pine Setup         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config"

# Check sudo
if ! sudo -v &>/dev/null; then
    echo -e "${BLUE}Please enter your sudo password to proceed with package installation:${NC}"
    sudo -v
fi

# ------------------------------------------------------------------------------
# 1. Enable Required Repositories
# ------------------------------------------------------------------------------
echo -e "\n${GOLD}[1/5] Enabling Repositories (RPM Fusion & Hyprland COPR)...${NC}"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

sudo dnf copr enable -y ashbuk/Hyprland-Fedora
sudo dnf copr enable -y erikreider/SwayNotificationCenter 2>/dev/null || true

# ------------------------------------------------------------------------------
# 2. Install Packages
# ------------------------------------------------------------------------------
echo -e "\n${GOLD}[2/5] Installing Hyprland, Waybar, Kitty, and utilities...${NC}"
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
    dracut \
    plymouth 2>/dev/null || true

# ------------------------------------------------------------------------------
# 3. Create GDM Wayland session entry if missing
# ------------------------------------------------------------------------------
echo -e "\n${GOLD}[3/5] Verifying GDM Wayland session entry...${NC}"
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

# ------------------------------------------------------------------------------
# 4. Build Rust Components
# ------------------------------------------------------------------------------
echo -e "\n${GOLD}[4/5] Building custom Rust binaries (App Launcher, Control Panel, Wifi Module)...${NC}"

if command -v cargo &>/dev/null; then
    # Waybar Wifi Module
    if [ -d "$CONFIG_DIR/waybar/wifi-module" ]; then
        echo "  Compiling Waybar Wifi Module..."
        (cd "$CONFIG_DIR/waybar/wifi-module" && cargo build --release 2>/dev/null || true)
    fi

    # App Launcher
    if [ -d "$CONFIG_DIR/hypr/app-launcher" ]; then
        echo "  Compiling App Launcher..."
        (cd "$CONFIG_DIR/hypr/app-launcher" && cargo build --release 2>/dev/null || true)
    fi

    # Control Panel
    if [ -d "$CONFIG_DIR/hypr/control-panel" ]; then
        echo "  Compiling Control Panel..."
        (cd "$CONFIG_DIR/hypr/control-panel" && cargo build --release 2>/dev/null || true)
    fi
fi

# ------------------------------------------------------------------------------
# 5. Install Python Dependencies & Fix Permissions
# ------------------------------------------------------------------------------
echo -e "\n${GOLD}[5/5] Finalizing permissions and desktop entries...${NC}"
pip3 install --user --upgrade PySide6 psutil 2>/dev/null || pip install --user --upgrade PySide6 psutil 2>/dev/null || true

chmod +x "$CONFIG_DIR"/waybar/*.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR"/hypr/scripts/*.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR"/hypr/scripts/*.py 2>/dev/null || true
chmod +x "$CONFIG_DIR"/rofi/*.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR"/hypr/msi-control-center/install.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR"/hypr/msi-control-center/main.py 2>/dev/null || true

mkdir -p "$USER_HOME/.local/share/applications"
cp "$CONFIG_DIR/hypr/msi-control-center/msi-control-center.desktop" "$USER_HOME/.local/share/applications/" 2>/dev/null || true
update-desktop-database "$USER_HOME/.local/share/applications/" 2>/dev/null || true

echo -e "\n${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Base setup completed successfully!                ${NC}"
echo -e "${GREEN}  ✓ Hyprland entry is ready in your login screen!     ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "To start Hyprland:"
echo -e "  Log out of GNOME, click your user name on the GDM login screen,"
echo -e "  click the gear (⚙️) icon in the bottom right corner, and select 'Hyprland'."
