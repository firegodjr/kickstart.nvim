local wk = require 'which-key'
wk.add { { '<leader>n', group = 'Ge[n] (Ollama)' } }
--
-- Helper to get color from highlight group
local function get_hl_color(group, attr, fallback)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
  if ok and hl and hl[attr] then
    return string.format('#%06x', hl[attr])
  end
  return fallback
end

return {
  -- claude code (if available)
  {
    'greggh/claude-code.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      -- don't set up if 'claude' command doesn't exist
      if vim.fn.executable 'claude' == 0 then
        return
      end
      require('claude-code').setup()
    end,
  },
  -- codeium code insertion
  {
    'Exafunction/codeium.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
      'nvim-lualine/lualine.nvim',
    },
    config = function()
      local codeium = require 'codeium'
      codeium.setup {
        enable_cmp_source = false,
        virtual_text = {
          enabled = true,
          manual = true,
          idle_delay = 0,
          key_bindings = {
            accept = '<M-l>',
            accept_word = false,
            accept_line = false,
            clear = false,
            next = '<M-]>',
            prev = '<M-[>',
          },
        },
      }
    end,
    event = 'BufEnter',
    keys = {
      -- Complete in normal mode
      {
        '<M-i>',
        function()
          vim.cmd 'startinsert'
          vim.defer_fn(require('codeium.virtual_text').complete, 100)
        end,
        desc = 'Request AI completion',
      },
      -- Complete in insert mode
      {
        '<M-i>',
        function()
          require('codeium.virtual_text').complete()
        end,
        desc = 'Request AI completion',
        mode = 'i',
      },
    },
  },
  -- {
  --   -- Custom fork fixes issue w/ spaces
  --   url = 'https://github.com/firegodjr/nvim-aider.git',
  --   cmd = 'Aider',
  --   -- Example key mappings for common actions:
  --   keys = {
  --     { '<leader>a/', '<cmd>Aider toggle<cr>', desc = 'Toggle Aider' },
  --     { '<leader>as', '<cmd>Aider send<cr>', desc = 'Send to Aider', mode = { 'n', 'v' } },
  --     { '<leader>ac', '<cmd>Aider command<cr>', desc = 'Aider Commands' },
  --     { '<leader>ab', '<cmd>Aider buffer<cr>', desc = 'Send Buffer' },
  --     { '<leader>a+', '<cmd>Aider add<cr>', desc = 'Add File' },
  --     { '<leader>a-', '<cmd>Aider drop<cr>', desc = 'Drop File' },
  --     { '<leader>ar', '<cmd>Aider add readonly<cr>', desc = 'Add Read-Only' },
  --     { '<leader>aR', '<cmd>Aider reset<cr>', desc = 'Reset Session' },
  --     -- Example nvim-tree.lua integration if needed
  --     { '<leader>a+', '<cmd>AiderTreeAddFile<cr>', desc = 'Add File from Tree to Aider', ft = 'NvimTree' },
  --     { '<leader>a-', '<cmd>AiderTreeDropFile<cr>', desc = 'Drop File from Tree from Aider', ft = 'NvimTree' },
  --   },
  --   dependencies = {
  --     'folke/snacks.nvim',
  --     --- The below dependencies are optional
  --     'catppuccin/nvim',
  --     -- "nvim-tree/nvim-tree.lua",
  --     --- Neo-tree integration
  --     {
  --       'nvim-neo-tree/neo-tree.nvim',
  --       opts = function(_, opts)
  --         -- Example mapping configuration (already set by default)
  --         -- opts.window = {
  --         --   mappings = {
  --         --     ["+"] = { "nvim_aider_add", desc = "add to aider" },
  --         --     ["-"] = { "nvim_aider_drop", desc = "drop from aider" }
  --         --     ["="] = { "nvim_aider_add_read_only", desc = "add read-only to aider" }
  --         --   }
  --         -- }
  --         require('nvim_aider.neo_tree').setup(opts)
  --       end,
  --     },
  --   },
  --   config = function()
  --     require('nvim_aider').setup {
  --       user_input_color = get_hl_color('String', 'fg', '#a6da95'),
  --       tool_output_color = get_hl_color('Function', 'fg', '#8aadf4'),
  --       tool_error_color = get_hl_color('Error', 'fg', '#ed8796'),
  --       tool_warning_color = get_hl_color('WarningMsg', 'fg', '#eed49f'),
  --       assistant_output_color = get_hl_color('Type', 'fg', '#c6a0f6'),
  --       completion_menu_color = get_hl_color('Normal', 'fg', '#cad3f5'),
  --       completion_menu_bg_color = get_hl_color('Normal', 'bg', '#24273a'),
  --       completion_menu_current_color = get_hl_color('CursorLine', 'fg', '#181926'),
  --       completion_menu_current_bg_color = get_hl_color('CursorLine', 'bg', '#f4dbd6'),
  --     }
  --   end,
  -- },
}
