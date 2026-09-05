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
  {
    dir = vim.fn.stdpath 'config',
    name = 'inline-completion',
    event = 'BufEnter',
    config = function()
      require('inline_completion').setup()
    end,
    keys = {
      {
        '<M-i>',
        function()
          if vim.fn.mode():sub(1, 1) ~= 'i' then
            vim.cmd 'startinsert'
          end
          local bufnr = vim.api.nvim_get_current_buf()
          vim.b[bufnr].inline_completion_manual_triggering = true
          vim.lsp.inline_completion.enable(true, { bufnr = bufnr })
          vim.api.nvim_exec_autocmds('CursorMovedI', { buffer = bufnr, modeline = false })
          vim.b[bufnr].inline_completion_manual_triggering = false
        end,
        mode = { 'n', 'i' },
        desc = 'Request inline completion',
      },
      {
        '<leader>ai',
        function()
          require('inline_completion').menu()
        end,
        mode = { 'n' },
        desc = '[A]I [I]nline completion menu',
      },
    },
    cmd = {
      'InlineCompletion',
      'InlineCompletionProvider',
      'InlineCompletionModel',
      'InlineCompletionStatus',
      'InlineCompletionLog',
      'InlineCompletionApprove',
      'InlineCompletionRevoke',
      'InlineCompletionSetup',
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
