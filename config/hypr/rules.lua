-- --------------------------------
-- ---- WINDOWS AND WORKSPACES ----
-- --------------------------------

-- Layout configurations
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
        disable_hyprland_guiutils_check = true,
    },
})

-- Window rules
local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Kitty handles its own transparency via background_opacity in kitty.conf

-- VSCode glass effect
hl.window_rule({
    name = "vscode-glass",
    match = { class = "^(code|Code|code-oss|Code - OSS)$" },
    opacity = 0.80,
})

-- Common utility windows should always float
hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol)$" },
    float = true
})

hl.window_rule({
    name  = "float-nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true
})

hl.window_rule({
    name  = "float-system-dialogs",
    match = { class = "^(polkit-gnome-authentication-agent-1|org.kde.polkit-kde-authentication-agent-1|Pinentry-gtk)$" },
    float = true
})

-- Wireless Screen Casting (Super + K)
hl.window_rule({
    name  = "float-network-displays",
    match = { class = "^(org.gnome.NetworkDisplays|gnome-network-displays)$" },
    float = true,
    center = true,
    size  = "720 540",
})

-- Home Clock Widget (Desktop clock on workspace 1 only)
hl.window_rule({
    name = "float-home-clock",
    match = { class = "^(HomeClockWidget)$" },
    float = true,
    workspace = "1",
    no_focus = true,
    move = "608 30",  -- top center: (1920/1.25 - 320)/2 = 608, with 30px top reserve
})

-- App Launcher overlay (Super+D)
hl.window_rule({
    name = "app-launcher-overlay",
    match = { class = "^(com.hypr.applauncher)$" },
    float = true,
    center = true,
    pin = true,
    dim_around = true,
    size = "780 552",
})
