-- Minimal config for the vscode-neovim extension: text editing and keybinds only.
-- VS Code owns windows, panes, the file tree, language servers and completion.
-- LSP keymaps forward to VS Code commands.

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
-- VS Code handles insert mode, so insert-mode keymaps never reach Neovim.
-- jk/kj live in the VS Code setting `vscode-neovim.compositeKeys`. See CLAUDE.md.

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)', { desc = 'Leap' })

-- Keymaps that forward to VS Code commands. They exist only inside VS Code.
if vim.g.vscode then
  local vscode = require 'vscode'

  local function map_vscode_action(mode, lhs, action, desc)
    vim.keymap.set(mode, lhs, function()
      vscode.action(action)
    end, { desc = desc })
  end

  map_vscode_action('n', ',,', 'workbench.action.openPreviousRecentlyUsedEditor', 'Go to previous buffer')
  map_vscode_action('n', ',d', 'workbench.action.closeActiveEditor', 'Close current buffer')

  -- Language features, served by the VS Code language extensions.
  map_vscode_action('n', 'gd', 'editor.action.revealDefinition', 'LSP: [G]oto [D]efinition')
  map_vscode_action('n', 'gr', 'editor.action.goToReferences', 'LSP: [G]oto [R]eferences')
  map_vscode_action('n', 'gI', 'editor.action.goToImplementation', 'LSP: [G]oto [I]mplementation')
  map_vscode_action('n', 'gD', 'editor.action.revealDeclaration', 'LSP: [G]oto [D]eclaration')
  map_vscode_action('n', '<leader>ds', 'workbench.action.gotoSymbol', 'LSP: [D]ocument [S]ymbols')
  map_vscode_action('n', '<leader>ws', 'workbench.action.showAllSymbols', 'LSP: [W]orkspace [S]ymbols')
  map_vscode_action('n', '<leader>rn', 'editor.action.rename', 'LSP: [R]e[n]ame')
  map_vscode_action({ 'n', 'x' }, '<leader>ca', 'editor.action.quickFix', 'LSP: [C]ode [A]ction')
  map_vscode_action('n', '<leader>f', 'editor.action.formatDocument', '[F]ormat buffer')
  map_vscode_action('x', '<leader>f', 'editor.action.formatSelection', '[F]ormat selection')

  local INLAY_HINTS_SETTING = 'editor.inlayHints.enabled'
  vim.keymap.set('n', '<leader>th', function()
    local next_state = vscode.get_config(INLAY_HINTS_SETTING) == 'off' and 'on' or 'off'
    vscode.update_config(INLAY_HINTS_SETTING, next_state, 'global')
  end, { desc = 'LSP: [T]oggle Inlay [H]ints' })
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
