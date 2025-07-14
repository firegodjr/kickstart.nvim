vim.o.showtabline = 2;

return {
  -- -- shade inactive splits
  -- {
  --   -- Fork fixes issues with Mason install window
  --   url="https://github.com/valentino-sm/shade.nvim.git",
  --   opts = {
  --     overlay_opacity = 75,
  --     opacity_step = 1
  --   }
  -- },

  -- display marks next to line number
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- file tree
  {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
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
      local git_blame = require('gitblame')
      git_blame.setup({
        message_template = "<sha>  <author>  <date>",
        message_when_not_committed = "Noncommitted Changes",
      })
      vim.g.gitblame_display_virtual_text=0
  
      local dap_section = {
        function()
          local tasks = require("overseer").list_tasks();
          local tasks_string = concat(tasks, " | ");
          return require("dap").status()
        end,
        icon = { "", color = { fg = "#e7c664" } }, -- nerd icon.
        cond = function()
          if not package.loaded.dap then
            return false
          end
          local session = require("dap").session()
          return session ~= nil
        end,
      }

      require('lualine').setup({
        options = {
          disabled_filetypes = {'dap-repl', 'dap-view'},
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        tabline = {
          -- show branch and cwd
          lualine_a = {{ icon = '', 'mode' }},
          lualine_b = { { function() return vim.fn.getcwd() end }, dap_section },
          lualine_c = { "overseer" },
          -- lualine_x = {{ icon='', git_blame.get_current_blame_text, git_blame, cond = git_blame.is_blame_text_available }},
          lualine_y = { {'diff'} },
          lualine_z = { {'branch', icon='', draw_empty=true} }
        },
        -- inactive_winbar = {
        --   lualine_c = { {'branch', icon='', draw_empty=true}},
        --   lualine_x = { {'diff'} },
        -- },
        sections = {
          lualine_a = { {'mode', icon=''} },
          lualine_b = { {} },
          lualine_c = { { 'filename', path=1 }, 'diagnostics'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
      })
    end,
  },

  -- tabline (now owned by lualine)
  -- {
  --   'nanozuki/tabby.nvim',
  --   event = 'VimEnter',
  --   dependencies = { 'nvim-tree/nvim-web-devicons', 'uga-rosa/utf8.nvim' },
  --   keys = {
  --     { "<A-,>", "<cmd>bprev<cr>", { silent = true } },
  --     { "<A-.>", "<cmd>bnext<cr>", { silent = true } },
  --     { "<A-c>", "<cmd>bp|bd#<cr>", { silent = true } },
  --     { "<A-x>", "<cmd>bp|bd!#<cr>", { silent = true } },
  --     { "<A-<>", "<cmd>tabp<cr>", { silent = true } },
  --     { "<A->>", "<cmd>tabn<cr>", { silent = true } },
  --     { "<A-S-c>", "<cmd>tabclose<cr>", { silent = true } },
  --   },
  --   config = function()
  --     local theme = {
  --       lualine_normal = 'lualine_a_normal',
  --       fill = 'TabLineFill',
  --       head = 'TabLine',
  --       current_tab = 'TabLineSel',
  --       tab = 'TabLine',
  --       win = 'TabLine',
  --       tail = 'TabLine',
  --     }
  --     require('tabby').setup({
  --       line = function(line)
  --         local utf8 = require("utf8");
  --         local function sub(s,i,j)
  --               i=utf8.offset(s,i)
  --               j=utf8.offset(s,j+1)-1
  --               return string.sub(s,i,j)
  --         end
  --         local tabIcons = '󰋜󰅩󰯉';
  --         return {
  --           {
  --             { '  ', hl = theme.lualine_normal },
  --             line.sep('', theme.lualine_normal, theme.fill),
  --           },
  --           line.bufs().foreach(function(buf)
  --             local hl = buf.is_current() and theme.current_tab or theme.tab
  --             return {
  --               line.sep('', hl, theme.fill),
  --               buf.file_icon(),
  --               buf.name(),
  --               -- buf.id,
  --               buf.is_changed() and '' or '',
  --               line.sep('', hl, theme.fill),
  --               hl = hl,
  --               margin = ' ',
  --           }
  --           end),
  --           line.spacer(),
  --           line.tabs().foreach(function(tab)
  --             local hl = tab.is_current() and theme.current_tab or theme.tab
  --             return {
  --               line.sep('', hl, theme.fill),
  --               utf8.len(tabIcons) > tab.id and sub(tabIcons, tab.id, tab.id) or tab.id,
  --               -- tab.name(),
  --               #tab.wins().wins >= 1 and (#tab.wins().wins) or '',
  --               -- tab.close_btn(''),
  --               line.sep('', hl, theme.fill),
  --               hl = hl,
  --               margin = ' ',
  --           }
  --           end),
  --         }
  --       end,
  --       option = {
  --         buf_name = {
  --           mode = 'tail'
  --         }
  --       }
  --     });
  --   end,
  -- },

  -- tab-scoped buffers
  {
    'tiagovla/scope.nvim',
    config = function()
      require('scope').setup({
        
      });
    end,
  },

  -- cool colorschemes --
  {'rebelot/kanagawa.nvim'},
  {"catppuccin/nvim", name = "catppuccin", priority = 1000},
  {'morhetz/gruvbox'},
  {'sainnhe/gruvbox-material'},
  {'loganswartz/sunburn.nvim', dependencies={'loganswartz/polychrome.nvim'}},
  {'zenbones-theme/zenbones.nvim', dependencies={'rktjmp/lush.nvim'}},
  {'Mofiqul/vscode.nvim'},
  {'gmr458/vscode_modern_theme.nvim'},
  {'slugbyte/lackluster.nvim'},
  {'olivercederborg/poimandres.nvim'},
  {'wnkz/monoglow.nvim'},
  {'aliqyan-21/darkvoid.nvim'},
  {'scottmckendry/cyberdream.nvim'},
  {'AlexvZyl/nordic.nvim'},
  {'rafamadriz/neon'},
  {
    url = 'https://github.com/firegodjr/monokai-pro.nvim.git',
    priority = 1000, -- Make sure to load this before all the other start plugins.
  }
}
-- return {
--     'romgrk/barbar.nvim',
--     dependencies = {
--       'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
--       'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
--     },
--     init = function() vim.g.barbar_auto_setup = false end,
--     opts = {
--
--       exclude_name = {'powershell.EXE'},
--       maximum_length = 30,
--       sidebar_filetypes = {
--         ['neo-tree'] = true,
--       }
--     },
--     version = '^1.0.0', -- optional: only update when a new 1.x version is released
-- }
