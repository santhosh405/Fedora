-- -----------------------
-- ---- LOOK AND FEEL ----
-- -----------------------

-- Read dynamic Pywal colors if available
local c4, c5, c0 = "rgba(c4a7e7ee)", "rgba(9ccfd8ee)", "rgba(6e6a86aa)"
local wal_path = (os.getenv("HOME") or "/home/fuckwindows") .. "/.cache/wal/colors"
local wal_file = io.open(wal_path, "r")
if wal_file then
    local colors = {}
    for line in wal_file:lines() do
        table.insert(colors, line)
    end
    wal_file:close()
    if #colors >= 6 then
        c4 = colors[5] -- color4
        c5 = colors[6] -- color5
        c0 = colors[1] -- color0
    end
end

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 14,

        border_size = 2,

        col = {
            active_border   = { colors = {c4, c5}, angle = 45 },
            inactive_border = c0,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.92,
        inactive_opacity = 0.88,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(00000066)",
        },

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            vibrancy          = 0.17,
            ignore_opacity    = true,
            new_optimizations = true,
        },
    },

    cursor = {
        no_hardware_cursors = false,
    },
})
