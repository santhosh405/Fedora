-- --------------------
-- ---- ANIMATIONS ----
-- --------------------

hl.config({
    animations = {
        enabled = true,
    },
})

-- Dynamic Bézier Curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("md3_decel",      { type = "bezier", points = { {0.05, 0.7},  {0.1, 1}     } })
hl.curve("md3_accel",      { type = "bezier", points = { {0.3, 0},     {0.8, 0.15}  } })
hl.curve("overshoot",      { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}  } })

-- Spring physics curve
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- Fluid, snappy and responsive Hyprland animation rules
hl.animation({ leaf = "global",        enabled = true,  speed = 10,  bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5,   bezier = "md3_decel" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4,   bezier = "md3_decel" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 3.8, bezier = "overshoot", style = "popin 75%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 2.5, bezier = "md3_accel", style = "popin 80%" })
hl.animation({ leaf = "windowsMove",   enabled = true,  speed = 4,   bezier = "overshoot", style = "slide" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 2,   bezier = "md3_accel" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.5, bezier = "md3_decel" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 3.2, bezier = "overshoot", style = "popin 80%" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 2,   bezier = "md3_accel", style = "popin 80%" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 2,   bezier = "md3_accel" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 4.5, bezier = "md3_decel", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 4.5, bezier = "md3_decel", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 4.5, bezier = "md3_decel", style = "slidefade 20%" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,   bezier = "quick" })
