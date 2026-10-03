-- neovim — minimal: kanagawa.nvim recolored with the default palette + a few basic settings
-- plugins are managed by vim.pack (built into nvim 0.12): :lua vim.pack.update() to update them

vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" })

-- "Default Dark" palette: same names as kanagawa.nvim, colors of the system (petrol surfaces, amber accent)
local palette = {
    sumiInk0 = "#0b1012", sumiInk1 = "#0d1214", sumiInk2 = "#12181a", sumiInk3 = "#0f1416",
    sumiInk4 = "#232c2e", sumiInk5 = "#2e3739", sumiInk6 = "#4f5a5c",
    waveBlue1 = "#1a2a30", waveBlue2 = "#1f3640",
    winterGreen = "#1d2b22", winterYellow = "#2e2a1c", winterRed = "#3a1f22", winterBlue = "#1a2224",
    autumnGreen = "#87b35a", autumnRed = "#d95757", autumnYellow = "#e6b450",
    samuraiRed = "#f07178", roninYellow = "#ff9e64", waveAqua1 = "#7fbbb3", dragonBlue = "#7fbbb3",
    fujiWhite = "#dfe4e5", oldWhite = "#b9c3c5", fujiGray = "#899395", katanaGray = "#899395",
    oniViolet = "#d2a6ff", oniViolet2 = "#c8b8e0", crystalBlue = "#9fd3dc",
    springViolet1 = "#c39ff0", springViolet2 = "#c5ced0", springBlue = "#95e6cb", lightBlue = "#a9d6dc",
    waveAqua2 = "#8fd1bd", springGreen = "#9ece6a", boatYellow1 = "#c9a35a", boatYellow2 = "#d6a443",
    carpYellow = "#e6b450", sakuraPink = "#e08f96", waveRed = "#d95757", peachRed = "#f07178",
    surimiOrange = "#ff9e64",
}

require("kanagawa").setup({
    transparent = false,
    dimInactive = true,
    colors = {
        palette = palette,
        theme = { all = { ui = { bg_gutter = "none" } } },  -- colonna numeri senza fondo
    },
})
vim.cmd.colorscheme("kanagawa-wave")

local o = vim.opt
o.number         = true
o.relativenumber = true
o.cursorline     = true
o.signcolumn     = "yes"
o.termguicolors  = true
o.mouse          = "a"
o.clipboard      = "unnamedplus"   -- copy/paste with the system clipboard (wl-clipboard)
o.expandtab      = true
o.shiftwidth     = 4
o.tabstop        = 4
o.ignorecase     = true
o.smartcase      = true
o.scrolloff      = 6
o.undofile       = true
o.splitright     = true
o.splitbelow     = true
o.laststatus     = 3               -- a single global statusline
