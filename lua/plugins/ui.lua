vim.o.showtabline = 2
vim.opt.background = 'dark'

-- ui.lua
-- Add functionality for user experience here

return {

  {
    'https://codeberg.org/andyg/leap.nvim.git',
    event = 'VimEnter',
    dependencies = { 'https://github.com/tpope/vim-repeat.git' },
    config = function()
      -- set keybinds for <Plug>(leap)
      vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)')
      vim.keymap.set({ 'n', 'x', 'o' }, 'S', '<Plug>(leap-from-window)')
    end,
  },

  { -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  { -- Marks in the gutter
    'chentoast/marks.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  { -- Git signs in the gutter
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '┃' },
        change = { text = '┃' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- file tree
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    keys = {
      { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    },
    opts = {
      filesystem = {
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
      },
    },
  },

  -- statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'f-person/git-blame.nvim' },
    config = function()
      local git_blame = require 'gitblame'
      git_blame.setup {
        message_template = '<sha>  <author>  <date>',
        message_when_not_committed = 'Noncommitted Changes',
      }
      vim.g.gitblame_display_virtual_text = 0

      local dap_section = {
        function()
          return require('dap').status()
        end,
        icon = { '', color = { fg = '#e7c664' } },
        cond = function()
          if not package.loaded.dap then
            return false
          end
          local session = require('dap').session()
          return session ~= nil
        end,
      }

      require('lualine').setup {
        options = {
          disabled_filetypes = { 'dap-repl', 'dap-view' },
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        tabline = {
          -- show branch and cwd
          -- lualine_a = {{ icon = '', 'mode' }},
          lualine_a = { {
            icon = '',
            function()
              return vim.fn.getcwd()
            end,
          } },
          lualine_b = {
            'tabs',
          },
          lualine_c = { 'overseer', dap_section },
          -- lualine_x = {{ icon='', git_blame.get_current_blame_text, git_blame, cond = git_blame.is_blame_text_available }},
          lualine_y = { { 'diff' } },
          lualine_z = { { 'branch', icon = '', draw_empty = true } },
        },
        -- inactive_winbar = {
        --   lualine_c = { {'branch', icon='', draw_empty=true}},
        --   lualine_x = { {'diff'} },
        -- },
        sections = {
          lualine_a = { { 'mode', icon = '' } },
          lualine_b = { {} },
          lualine_c = { { 'filename' }, 'diagnostics' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
      }
    end,
  },

  -- tab-scoped buffers
  {
    'tiagovla/scope.nvim',
    config = function()
      require('scope').setup {}
    end,
  },

  -- cool colorschemes --
  { 'nyoom-engineering/oxocarbon.nvim' },
  { 'EdenEast/nightfox.nvim' },
  { 'rebelot/kanagawa.nvim' },
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
  { 'morhetz/gruvbox' },
  { 'sainnhe/gruvbox-material' },
  { 'Mofiqul/vscode.nvim' },
  { 'gmr458/vscode_modern_theme.nvim' },
  { 'AlexvZyl/nordic.nvim' },
  { 'rafamadriz/neon' },
  {
    url = 'https://github.com/firegodjr/monokai-pro.nvim.git',
    priority = 1000, -- Make sure to load this before all the other start plugins.
  },
}
