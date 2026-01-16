local wk = require 'which-key'
wk.add { { '<leader>t', group = '[T]est' } }

-- ide.lua --
-- Add functionality for various programming languages here

return {
  { -- Lua LSP for Neovim config
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },

  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      -- lsp_keymaps = false,
      -- other options
    },
    config = function(lp, opts)
      require('go').setup(opts)
      local format_sync_grp = vim.api.nvim_create_augroup('GoFormat', {})
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*.go',
        callback = function()
          require('go.format').goimports()
        end,
        group = format_sync_grp,
      })
    end,
    -- event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
  {
    'GustavEikaas/easy-dotnet.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('easy-dotnet').setup {
        test_runner = {
          noBuild = false,
          -- Add mappings consistent with existing plugins and built to invoke which-key
          mappings = {
            run_test_from_buffer = { lhs = '<leader>tr', desc = '[T]est [R]un' },
            debug_test = { lhs = '<leader>td', desc = '[T]est [D]ebug' },
            run = { lhs = '<leader>tr', desc = '[T]est [R]un' },
            run_all = { lhs = '<leader>tR', desc = '[T]est [R]un All' },
            expand = { lhs = '<CR>', desc = 'expand' },
          },
        },
      }
    end,
    keys = {
      { '<leader>tt', '<cmd>Dotnet testrunner<cr>', desc = '[T]ests [T]oggle' },
      { '<leader>DD', '<cmd>Dotnet<cr>', desc = '[D]otnet List' },
      { '<leader>Db', '<cmd>Dotnet build<cr>', desc = '[D]otnet [B]uild' },
      { '<leader>Dw', '<cmd>Dotnet watch<cr>', desc = '[D]otnet [W]atch' },
    },
  },
  -- Compile Less on save
  {
    'askfiy/neovim-easy-less',
    ft = { 'less' },
    config = function()
      require('easy-less').setup {
        generate_suffix = 'min.css',
      }
    end,
  },
  -- Refactoring
  -- TODO: Need to read into how this actually works
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    lazy = false,
    opts = {},
    keys = {
      { '<leader>re', ':Refactor extract ', desc = '[R]efactor [E]xtract' },
      { '<leader>rf', ':Refactor extract_to_file ', desc = '[R]efactor Extract to [F]ile' },
      { '<leader>rv', ':Refactor extract_var ', desc = '[R]efactor Extract [V]ariable' },
      { '<leader>rI', '<cmd>Refactor inline_func<cr>', desc = '[R]efactor [I]nline' },
      { '<leader>ri', '<cmd>Refactor inline_var<cr>', desc = '[R]efactor [I]nline Variable' },
      { '<leader>rb', '<cmd>Refactor extract_block<cr>', desc = '[R]efactor Extract [B]lock' },
      { '<leader>rbf', '<cmd>Refactor extract_block_to_file<cr>', desc = '[R]efactor Extract [B]lock to [F]ile' },
    },
    config = function()
      require('refactoring').setup()
    end,
  },
}
