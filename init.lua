-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.tabstop = 4

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Load per-project config if exists
vim.opt.exrc = true

vim.opt.conceallevel = 0

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 1000

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- keymaps
-- Exit insert mode with jk
vim.keymap.set('i', 'jk', '<Esc><cmd>w<cr>')
vim.keymap.set('i', 'kj', '<Esc><cmd>w<cr>')

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Keybinds to make split navigation easier.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Keybinds for terminal mode
vim.keymap.set('t', '<C-h>', '<C-\\><C-N><C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-N><C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-N><C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-N><C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Buffer navigation
vim.keymap.set('n', ',,', '<cmd>b#<cr>', { desc = 'Go to previous buffer' })
vim.keymap.set('n', ',d', '<cmd>b#|bd#<cr>', { desc = 'Delete current buffer and goto prev' })

-- Fix dos-formatted files
vim.keymap.set(
  'n',
  '<leader>FF',
  '<Cmd>update<CR><Cmd>e ++ff=dos<CR><Cmd>setlocal ff=unix<CR><Cmd>w<CR>',
  { desc = '[F]ix [F]ile (remove excess ^M characters)' }
)
vim.keymap.set(
  'n',
  '<leader>FE',
  '<Cmd>w ++enc=utf-8<CR>',
  { desc = '[F]ix [E]ncoding (convert to utf-8)'}
)

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Enable word wrap for markdown
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
  desc = 'Enable word wrap for markdown files'
})

-- Enable codelens
vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    -- For some reason codelens keeps getting unset, might be theme-specific
    -- So just force the highlight group to a neutral color for now
    vim.api.nvim_set_hl(0, "LspCodeLens", { fg = "#777777", italic = true })
    vim.lsp.codelens.refresh()
  end,
  desc = 'Enable codelens on CursorHold'
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- Install plugins
require('lazy').setup({
  require 'core',
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- Manage colorscheme
-- Loads the current-theme.lua file generated by telescope-themes
require 'current-theme'

-- Set up volar correctly
require 'compat.volar'

-- Make things work on windows system provided clang exists
if vim.loop.os_uname().sysname == 'Windows_NT' then
  require 'compat.windows'
end

-- Make things work in neovide if using neovide
if vim.g.neovide then
  require 'compat.neovide'
end

-- Things that depend on a .nvim.lua file to set a global flag are loaded here
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    -- Load KL plugin if enabled, after exrc is loaded
    if vim.g.use_kl then
      require 'compat.kl'
    end
  end,
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
