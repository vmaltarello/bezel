-- bezel — Hyprland part of the theme.
-- Loaded from ~/.config/hypr/hyprland.lua with:
--   require("bezel").setup({ terminal = "kitty -1", ... })
-- Files in this folder belong to the theme and are replaced on update:
-- put your own changes in hyprland.lua (anything set there after setup() wins).

local M = {}

M.defaults = {
    terminal    = "kitty -1",                       -- -1: one kitty process for all windows (less RAM)
    fileManager = "kitty -1 --class yazi -e yazi",  -- terminal file manager
    browser     = nil,                              -- nil = the system default browser (xdg-settings)
    editor      = "nvim",                           -- $EDITOR for apps started by Hyprland
    workspaces  = 5,                                -- persistent workspaces (the bar shows the same number)
}

function M.setup(opts)
    local o = {}
    for k, v in pairs(M.defaults) do o[k] = v end
    for k, v in pairs(opts or {}) do o[k] = v end
    M.opts = o

    require("bezel.env")(o)
    require("bezel.autostart")(o)
    require("bezel.look")(o)
    require("bezel.input")(o)
    require("bezel.binds")(o)
    require("bezel.rules")(o)
end

return M
