# 🌸 Fedora 44 Hyprland Rice & Dotfiles

Personal Fedora configuration, custom Hyprland desktop rice, scripts, and dotfiles.

[![Fedora Linux](https://img.shields.io/badge/Fedora-44-blue?logo=fedora&logoColor=white)](https://getfedora.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-brightgreen?logo=hyprland&logoColor=white)](https://hyprland.org)
[![Shell](https://img.shields.io/badge/Shell-ZSH%20%7C%20Bash-orange)](https://zsh.sourceforge.io)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

---

## 📸 Overview & Features

- **Window Manager**: [Hyprland](https://hyprland.org/) (Wayland compositor) with smooth animations, custom keybindings, and dynamic window rules.
- **Status Bar**: [Waybar](https://github.com/Alexays/Waybar) with dynamic Cava visualizer, Bluetooth switcher, fan controller, GPU stats, and Rust-powered WiFi manager.
- **Theme & Colors**: Dynamic [Pywal](https://github.com/dylanaraps/pywal) color extraction, [Sweet-Dark](https://github.com/EliverLara/Sweet) GTK theme, and [Candy Icons](https://github.com/EliverLara/candy-icons).
- **Terminal & Shell**: Kitty terminal + Zsh with custom prompt, completion, and Pokémon colorscripts.
- **Launchers & Menus**: Wofi & Rofi application launchers, Wlogout lock/logout dashboard, and custom Rust-based App Launcher & Control Panel.
- **Notifications**: SwayNotificationCenter (`SwayNC`).
- **Hardware Integrations**: Custom MSI fan mode scripts, refresh rate toggler, audio via PipeWire/WirePlumber, and brightness control.
- **Gaming & Streaming**: High-performance USB Android mirror with physical UHID controls for Minecraft mobile on PC.

---

## 📂 Repository Structure

```
Fedora/
├── install.sh                  # Interactive one-click installer / deployer
├── config/                     # Configurations matching ~/.config/
│   ├── hypr/                   # Hyprland configs, Lua bindings, and custom scripts
│   │   ├── app-launcher/       # Custom Rust application launcher
│   │   ├── control-panel/      # Custom Rust system control panel
│   │   ├── msi-control-center/ # MSI laptop hardware GUI & fan control
│   │   └── scripts/            # Fan control, screen recording, wallpapers, casting
│   ├── waybar/                 # Waybar configurations, CSS styling, and scripts
│   │   └── wifi-module/        # Custom Rust wifi status widget
│   ├── kitty/                  # Terminal configuration
│   ├── fastfetch/              # System fetch configuration & ASCII art
│   ├── cava/                   # Audio visualizer
│   ├── swaync/                 # Notification center styling & config
│   ├── wlogout/                # Logout / shutdown overlay
│   ├── wofi/ & rofi/           # Application menus
│   ├── wal/                    # Pywal color palettes & templates
│   ├── btop/                   # System monitor themes
│   ├── gtk-3.0/ & gtk-4.0/     # GTK appearance settings
│   ├── systemd/user/           # Custom systemd user service units
│   └── mimeapps.list           # Default application associations
├── shell/                      # Shell dotfiles
│   ├── .zshrc                  # Zsh configuration, prompt, and aliases
│   ├── .bashrc                 # Bash aliases and functions
│   └── .bash_profile          # Profile startup environment
├── scripts/                    # Utilities and standalone scripts
│   ├── install-hyprland.sh     # Hyprland repo & dependency bootstrapper
│   ├── setup-fedora-rice.sh    # Full rice setup and build script
│   ├── setup_second_brain.sh   # Obsidian second brain vault scaffold
│   ├── hyprshot                # Wayland screenshot utility
│   ├── run_mindcraft           # Scrcpy USB mobile gaming stream runner
│   ├── run_obsidian            # Obsidian flatpak runner
│   └── spotify                 # Spotify flatpak runner
├── applications/               # Custom desktop entries (.desktop files)
├── assets/                     # Wallpapers, Sweet-Dark theme, Candy icons
│   ├── wallpapers/             # Curated desktop wallpapers
│   ├── themes/                 # Sweet-Dark GTK theme
│   └── icons/                  # Candy-icons pack
└── system/                     # Fedora system manifests
    ├── dnf.conf                # DNF configuration
    ├── dnf-repositories.txt    # Enabled DNF & COPR repositories
    ├── installed-packages.txt  # Manifest of user-installed RPM packages
    └── flatpak-packages.txt    # Installed Flatpak applications
```

---

## ⌨️ Hyprland Keybindings

| Key Combination | Action |
|---|---|
| `Super + Return` / `Super + Q` | Open Kitty terminal |
| `Super + Space` / `Super + D` | Open Application Launcher (Wofi) |
| `Super + E` | Open File Manager (Nautilus) |
| `Super + B` | Open Brave Browser |
| `Super + Shift + B` | Open Firefox |
| `Super + C` / `Alt + F4` | Close active window |
| `Super + F` | Toggle Fullscreen |
| `Super + V` | Toggle Floating window mode |
| `Super + W` | Cycle Wallpaper & update Pywal theme |
| `Super + K` | Wireless Screen Cast |
| `Super + R` | Toggle Region Screen Recording |
| `Super + Shift + R` | Toggle Fullscreen Screen Recording |
| `Print` | Screenshot active window (Hyprshot) |
| `Shift + Print` | Screenshot selected region |
| `Alt + Print` | Screenshot full monitor |
| `Super + Escape` | Open Power / Logout Menu (Wlogout) |
| `Super + L` | Lock screen (Hyprlock) |
| `Super + Shift + Up / Down` | Adjust hardware fan speed |
| `Super + Shift + T` | Toggle Display Refresh Rate (e.g. 60Hz / 144Hz) |

---

## 🚀 Installation & Deployment

### 1. Clone the repository
```bash
git clone https://github.com/santhosh405/Fedora.git ~/Fedora
cd ~/Fedora
```

### 2. Run the Interactive Installer
```bash
chmod +x install.sh
./install.sh
```

Choose from:
1. **Full Installation**: Enables RPM Fusion and COPR repositories (`ashbuk/Hyprland-Fedora`, `SwayNotificationCenter`), installs all packages, builds Rust modules, links configs, and sets permissions.
2. **Deploy Dotfiles Only**: Quickly copies `config/`, `shell/`, wallpapers, and scripts into `~/.config` and `~/.local/bin` without touching DNF packages.
3. **Restore Packages Only**: Installs required DNF and Flatpak packages.

---

## 📦 Required COPR & Repositories

```bash
# RPM Fusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Hyprland & SwayNC COPR
sudo dnf copr enable -y ashbuk/Hyprland-Fedora
sudo dnf copr enable -y erikreider/SwayNotificationCenter
```

---

## 👤 Author

- GitHub: [@santhosh405](https://github.com/santhosh405)
