-- -------------------------------
-- ---- ENVIRONMENT VARIABLES ----
-- -------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("PATH", "/home/fuckwindows/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))
hl.env("SHELL", "/home/fuckwindows/.local/bin/zsh")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
