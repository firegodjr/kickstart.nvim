local wk = require 'which-key'

-- Helper to get color from highlight group
local function get_hl_color(group, attr, fallback)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
  if ok and hl and hl[attr] then
    return string.format('#%06x', hl[attr])
  end
  return fallback
end

return {
  -- codeium code insertion
  {
    'alex35mil/pi.nvim',

    -- Optional: required only for `:PiPasteImage` (clipboard image paste).
    -- dependencies = { "HakonHarnes/img-clip.nvim" },

    -- if you're fine with defaults:
    config = function()
      local pi = require 'pi'
      pi.setup()

      -- Global mappings — open / toggle / resume from anywhere.
      vim.keymap.set({ 'n', 'v' }, '<Leader>pp', function()
        vim.cmd 'Pi layout=side'
      end, { desc = 'Pi side' })
      vim.keymap.set({ 'n', 'v' }, '<Leader>pf', function()
        vim.cmd 'Pi layout=float'
      end, { desc = 'Pi float' })
      vim.keymap.set({ 'n', 'v' }, '<Leader>pl', '<Cmd>PiToggleLayout<CR>', { desc = 'Pi toggle layout' })
      vim.keymap.set({ 'n', 'v' }, '<Leader>pc', '<Cmd>PiContinue<CR>', { desc = 'Pi continue last session' })
      vim.keymap.set({ 'n', 'v' }, '<Leader>pr', '<Cmd>PiResume<CR>', { desc = 'Pi resume past session' })
      vim.keymap.set({ 'n', 'v' }, '<Leader>pm', '<Cmd>PiSendMention<CR>', { desc = 'Pi mention file/selection' })
      vim.keymap.set({ 'n', 'v' }, '<Leader>pa', '<Cmd>PiAttention<CR>', { desc = 'Pi open next attention request' })
    end,
  },
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
  {
    'carlos-algms/agentic.nvim',
    opts = {
      provider = 'maki',
      acp_providers = {
        maki = {
          name = 'Maki',
          command = 'maki',
          args = { 'acp' },
        },
      },
      windows = {
        position = 'right',
      },
    },
    keys = {
      {
        '<C-\\>',
        function()
          require('agentic').toggle()
        end,
        mode = { 'n', 'v', 'i' },
        desc = 'Toggle Agentic Chat (Maki)',
      },
      {
        "<C-'>",
        function()
          require('agentic').add_selection_or_file_to_context()
        end,
        mode = { 'n', 'v' },
        desc = 'Add Selection/File to Agentic Context',
      },
      {
        '<C-,>',
        function()
          require('agentic').new_session()
        end,
        mode = { 'n', 'v', 'i' },
        desc = 'New Agentic Session',
      },
      {
        '<leader>ar',
        function()
          require('agentic').restore_session()
        end,
        mode = { 'n', 'v' },
        desc = 'Agentic Restore Session',
      },
      {
        '<leader>ad',
        function()
          require('agentic').add_current_line_diagnostics()
        end,
        mode = { 'n' },
        desc = 'Add Current Line Diagnostic to Agentic',
      },
      {
        '<leader>aD',
        function()
          require('agentic').add_buffer_diagnostics()
        end,
        mode = { 'n' },
        desc = 'Add Buffer Diagnostics to Agentic',
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
