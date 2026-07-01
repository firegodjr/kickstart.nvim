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
}
