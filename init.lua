-- Minimal config for the vscode-neovim extension: text editing and keybinds only.
-- VS Code owns windows, panes, the file tree, LSP, formatting and completion.

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Options ]]
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.timeoutlen = 300

-- Scheduled because the clipboard provider can slow startup.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- [[ Plugins ]]
vim.pack.add({
  'https://github.com/tpope/vim-repeat',
  'https://codeberg.org/andyg/leap.nvim',
  'https://github.com/echasnovski/mini.nvim',
}, { confirm = false })

local MINI_AI_SEARCH_LINES = 500
require('mini.ai').setup { n_lines = MINI_AI_SEARCH_LINES }

-- [[ Keymaps ]]
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('i', 'kj', '<Esc>')

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)', { desc = 'Leap' })

-- Keymaps that forward to VS Code commands. They exist only inside VS Code.
if vim.g.vscode then
  local vscode = require 'vscode'

  vim.keymap.set('n', ',,', function()
    vscode.action 'workbench.action.openPreviousRecentlyUsedEditor'
  end, { desc = 'Go to previous buffer' })

  vim.keymap.set('n', ',d', function()
    vscode.action 'workbench.action.closeActiveEditor'
  end, { desc = 'Close current buffer' })
end

-- [[ Autocommands ]]
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- vim: ts=2 sts=2 sw=2 et
