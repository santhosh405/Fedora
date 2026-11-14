-- ============================================
-- App Launcher configuration
-- Each entry: name, icon, exec, comment
--   icon: themed icon name OR absolute path to a file
--   exec: full shell command to launch the app
-- ============================================

apps = {
    {
        name    = "Firefox",
        icon    = "firefox",
        exec    = "firefox",
        comment = "Web Browser",
    },
    {
        name    = "Brave",
        icon    = "brave-browser",
        exec    = "brave-browser",
        comment = "Privacy Browser",
    },
    {
        name    = "Kitty",
        icon    = "kitty",
        exec    = "kitty",
        comment = "Terminal",
    },
    {
        name    = "Files",
        icon    = "org.gnome.Nautilus",
        exec    = "nautilus",
        comment = "File Manager",
    },
    {
        name    = "Control Panel",
        icon    = "org.gnome.Settings",
        exec    = "/home/fuckwindows/.config/hypr/control-panel/target/release/hypr-control-panel",
        comment = "System Settings",
    },
    {
        name    = "Waypaper",
        icon    = "/usr/share/icons/AdwaitaLegacy/48x48/legacy/preferences-desktop-wallpaper.png",
        exec    = "/home/fuckwindows/.local/bin/waypaper",
        comment = "Wallpaper Chooser",
    },
    {
        name    = "Text Editor",
        icon    = "org.gnome.TextEditor",
        exec    = "gnome-text-editor",
        comment = "Notes & Code",
    },
    {
        name    = "Calculator",
        icon    = "org.gnome.Calculator",
        exec    = "gnome-calculator",
        comment = "Math Calculator",
    },
    {
        name    = "System Monitor",
        icon    = "org.gnome.SystemMonitor",
        exec    = "gnome-system-monitor",
        comment = "Processes & Resources",
    },
    {
        name    = "btop",
        icon    = "kitty",
        exec    = "kitty -e btop",
        comment = "Terminal Monitor",
    },
    {
        name    = "Disks",
        icon    = "org.gnome.DiskUtility",
        exec    = "gnome-disks",
        comment = "Disk Management",
    },
    {
        name    = "Settings",
        icon    = "org.gnome.Settings",
        exec    = "gnome-control-center",
        comment = "GNOME Settings",
    },
    {
        name    = "Volume Control",
        icon    = "org.pulseaudio.pavucontrol",
        exec    = "pavucontrol",
        comment = "Audio Settings",
    },
    {
        name    = "Camera",
        icon    = "org.gnome.Snapshot",
        exec    = "snapshot",
        comment = "Webcam / Snapshot",
    },
    {
        name    = "Calendar",
        icon    = "org.gnome.Calendar",
        exec    = "gnome-calendar",
        comment = "Calendar & Events",
    },
    {
        name    = "Video Player",
        icon    = "org.gnome.Showtime",
        exec    = "showtime",
        comment = "Media Player",
    },
    {
        name    = "Image Viewer",
        icon    = "org.gnome.Loupe",
        exec    = "loupe",
        comment = "Photo Viewer",
    },
}
