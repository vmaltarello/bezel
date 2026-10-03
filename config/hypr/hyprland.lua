-- Hyprland config — bezel theme
-- This file is yours: the installer writes it once and never overwrites it on update.
-- The theme lives in ~/.config/hypr/bezel/ (look, keybindings, rules); settings below win over it.
-- Wiki: https://wiki.hypr.land/Configuring/Start/

require("bezel").setup({
    terminal    = "kitty -1",
    fileManager = "kitty -1 --class yazi -e yazi",
    browser     = nil,      -- nil = system default browser; or e.g. "firefox"
    editor      = "nvim",
})

-- Monitors: https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "@SCALE@",
})

-- Keyboard
hl.config({
    input = {
        kb_layout  = "@KB_LAYOUT@",
        kb_variant = "@KB_VARIANT@",
        kb_options = "",
    },
})

-- Your own binds, rules and settings go below.
