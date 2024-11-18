-- Special Configuration options for Neovide
-- (Runs after all other config in init.lua)

-- Set font manually b/c default size is very large
vim.o.guifont = "CaskaydiaCove Nerd Font:h11"

-- Disable shade b/c it blurs everything
local shade = require('shade')
shade.toggle()
