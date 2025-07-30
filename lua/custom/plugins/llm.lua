local wk = require 'which-key'
wk.add { { '<leader>n', group = 'Ge[n] (Ollama)' } }

function load_llm()
  -- Load constants from ~/.llm.json
  local home_dir = os.getenv 'HOME'
  local llm_config_file = home_dir .. '/.llm.json'
  local llm_config = nil
  if vim.fn.filereadable(llm_config_file) == 1 then
    llm_config = vim.fn.json_decode(vim.fn.readfile(llm_config_file))
  else
    error("Couldn't load " .. llm_config_file)
  end

  local gen = require 'gen'

  gen.setup {
    model = llm_config.model,
    show_prompt = true,
    show_model = true,
    display_mode = 'vertical-split',
    command = function(options)
      if llm_config.service == 'azure' then
        return 'echo $body > ~/test.txt;curl --silent --no-buffer -X POST '
          .. llm_config.url
          .. ' -H "Content-Type: application/json" -H "Authorization: Bearer '
          .. llm_config.api_key
          .. '" -d $body'
      elseif llm_config.service == 'ollama' then
        return 'curl --silent --no-buffer -X POST http://' .. options.host .. ':' .. options.port .. '/api/chat -d $body'
      else
        error 'No known service specified'
      end
    end,
  }
end

return {
  -- ollama code refactoring
  {
    'David-Kunz/gen.nvim',
    -- opts = {
    --     model = "qwen2.5-coder:14b",
    --     show_prompt = true,
    --     show_model = true,
    --     display_mode = "vertical-split",
    --     host = "192.168.56.1",
    -- },
    -- azure deployment
    opts = {
      file = nil,
    },
    config = function()
      load_llm()
    end,
    event = 'BufEnter',
    keys = {
      { '<leader>nl', '<cmd>Gen<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] List' },
      { '<leader>nc', '<cmd>Gen Chat<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] [C]hat' },
      { '<leader>na', '<cmd>Gen Ask<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] [A]sk' },
      { '<leader>ng', '<cmd>Gen Generate<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] [G]enerate' },
    },
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
}
