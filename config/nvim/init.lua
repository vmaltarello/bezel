-- neovim — minimal: kanagawa.nvim recolored with the default palette + a few basic settings
-- plugins are managed by vim.pack (built into nvim 0.12): :lua vim.pack.update() to update them

vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" })

-- "Default Dark" palette: same names as kanagawa.nvim, colors of the system (night-blue surfaces, lavender accent)
local palette = {
    sumiInk0 = "#0a0f1c", sumiInk1 = "#0b1120", sumiInk2 = "#0d1424", sumiInk3 = "#0f1628",
    sumiInk4 = "#202c48", sumiInk5 = "#2a3756", sumiInk6 = "#4a5675",
    waveBlue1 = "#1c2b45", waveBlue2 = "#2a3756",
    winterGreen = "#1d2b22", winterYellow = "#29244d", winterRed = "#3a1f22", winterBlue = "#18223a",
    autumnGreen = "#7fbf6e", autumnRed = "#d95757", autumnYellow = "#a99cf0",
    samuraiRed = "#ff5a5f", roninYellow = "#ffb46b", waveAqua1 = "#74b8b0", dragonBlue = "#74b8b0",
    fujiWhite = "#f4f2ec", oldWhite = "#c4c7d1", fujiGray = "#8b91a3", katanaGray = "#8b91a3",
    oniViolet = "#d2a6ff", oniViolet2 = "#c8b8e0", crystalBlue = "#8fd0e0",
    springViolet1 = "#c39ff0", springViolet2 = "#cdd0d9", springBlue = "#7fd3c8", lightBlue = "#a9c9e6",
    waveAqua2 = "#7fc9bd", springGreen = "#9bd48a", boatYellow1 = "#d9824f", boatYellow2 = "#8b7de0",
    carpYellow = "#a99cf0", sakuraPink = "#e08f96", waveRed = "#d95757", peachRed = "#ff5a5f",
    surimiOrange = "#ffb46b",
}

require("kanagawa").setup({
    transparent = false,
    dimInactive = true,
    colors = {
        palette = palette,
        theme = { all = { ui = { bg_gutter = "none" } } },  -- line numbers without a background
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
