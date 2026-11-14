-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Hyprland Main Configuration (Fedora Pywal Rice)       --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

hl.config({})

-- Global Programs Configuration
terminal    = "kitty"
fileManager = "nautilus"
menu        = "wofi --show drun"

-- Require config components
require("environment")
require("monitors")
require("input")
require("appearance")
require("animations")
require("rules")
require("keybinds")
require("autostart")
