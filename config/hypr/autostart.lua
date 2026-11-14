-- -------------------
-- ---- AUTOSTART ----
-- -------------------

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("systemctl --user start swww.service")
    hl.exec_cmd("systemctl --user start waybar.service")
    hl.exec_cmd("systemctl --user start home-clock.service")
    hl.exec_cmd("swaync")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("sleep 0.5 && /home/fuckwindows/.config/hypr/scripts/setwall.sh /home/fuckwindows/Pictures/wallpapers/main.jpg")
    hl.exec_cmd("hypridle")
end)
