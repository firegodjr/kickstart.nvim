-- Special Configuration options for Neovide
-- (Runs after all other config in init.lua)

-- Set font manually b/c default size is very large
vim.o.guifont = 'CaskaydiaCove Nerd Font:h11'

-- Disable shade b/c it blurs everything (if it's loaded)
local ok, shade = pcall(require, 'shade')
if ok then
  shade.toggle()
end

-- Animate when changing mode
vim.g.neovide_cursor_vfx_mode = 'wireframe'

-- Specific things for work VM
if vim.fn.hostname() == '2017EXCLUSIONZO' then
  vim.cmd [[
    augroup cdpwd
      autocmd!
      autocmd VimEnter * cd C:/dev
    augroup END
  ]]
  vim.o.guifont = 'CaskaydiaCove Nerd Font:h10'
  vim.g.neovide_refresh_rate = 30
  vim.g.neovide_floating_blur_amount_x = 0
  vim.g.neovide_floating_blur_amount_y = 0
end
