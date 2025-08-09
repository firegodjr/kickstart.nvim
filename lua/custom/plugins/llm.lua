local wk = require 'which-key'
wk.add { { '<leader>n', group = 'Ge[n] (Ollama)' } }
--
-- Helper to get color from highlight group
local function get_hl_color(group, attr, fallback)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
  if ok and hl and hl[attr] then
    return string.format("#%06x", hl[attr])
  end
  return fallback
end

-- function load_llm()
--   -- Load constants from ~/.llm.json
--   local home_dir = os.getenv 'HOME'
--   local llm_config_file = home_dir .. '/.llm.json'
--   local llm_config = nil
--   if vim.fn.filereadable(llm_config_file) == 1 then
--     llm_config = vim.fn.json_decode(vim.fn.readfile(llm_config_file))
--   else
--     error("Couldn't load " .. llm_config_file)
--   end
--
--   local gen = require 'gen'
--
--   gen.setup {
--     model = llm_config.model,
--     show_prompt = true,
--     show_model = true,
--     display_mode = 'vertical-split',
--     command = function(options)
--       if llm_config.service == 'azure' then
--         return 'echo $body > ~/test.txt;curl --silent --no-buffer -X POST '
--           .. llm_config.url
--           .. ' -H "Content-Type: application/json" -H "Authorization: Bearer '
--           .. llm_config.api_key
--           .. '" -d $body'
--       elseif llm_config.service == 'ollama' then
--         return 'curl --silent --no-buffer -X POST http://' .. options.host .. ':' .. options.port .. '/api/chat -d $body'
--       else
--         error 'No known service specified'
--       end
--     end,
--   }
-- end

return {
  -- ollama code refactoring
  -- {
  --   'David-Kunz/gen.nvim',
  --   -- opts = {
  --   --     model = "qwen2.5-coder:14b",
  --   --     show_prompt = true,
  --   --     show_model = true,
  --   --     display_mode = "vertical-split",
  --   --     host = "192.168.56.1",
  --   -- },
  --   -- azure deployment
  --   opts = {
  --     file = nil,
  --   },
  --   config = function()
  --     load_llm()
  --   end,
  --   event = 'BufEnter',
  --   keys = {
  --     { '<leader>nl', '<cmd>Gen<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] List' },
  --     { '<leader>nc', '<cmd>Gen Chat<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] [C]hat' },
  --     { '<leader>na', '<cmd>Gen Ask<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] [A]sk' },
  --     { '<leader>ng', '<cmd>Gen Generate<cr>', mode = { 'n', 'v' }, desc = 'Ge[n] [G]enerate' },
  --   },
  -- },
  -- codeium code insertion
  {
    -- Custom fork fixes issue w/ spaces
    url = 'https://github.com/firegodjr/nvim-aider.git',
    cmd = "Aider",
    -- Example key mappings for common actions:
    keys = {
      { "<leader>a/", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
      { "<leader>as", "<cmd>Aider send<cr>", desc = "Send to Aider", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>Aider command<cr>", desc = "Aider Commands" },
      { "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Send Buffer" },
      { "<leader>a+", "<cmd>Aider add<cr>", desc = "Add File" },
      { "<leader>a-", "<cmd>Aider drop<cr>", desc = "Drop File" },
      { "<leader>ar", "<cmd>Aider add readonly<cr>", desc = "Add Read-Only" },
      { "<leader>aR", "<cmd>Aider reset<cr>", desc = "Reset Session" },
      -- Example nvim-tree.lua integration if needed
      { "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
      { "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
    },
    dependencies = {
      "folke/snacks.nvim",
      --- The below dependencies are optional
      "catppuccin/nvim",
      -- "nvim-tree/nvim-tree.lua",
      --- Neo-tree integration
      {
        "nvim-neo-tree/neo-tree.nvim",
        opts = function(_, opts)
          -- Example mapping configuration (already set by default)
          -- opts.window = {
          --   mappings = {
          --     ["+"] = { "nvim_aider_add", desc = "add to aider" },
          --     ["-"] = { "nvim_aider_drop", desc = "drop from aider" }
          --     ["="] = { "nvim_aider_add_read_only", desc = "add read-only to aider" }
          --   }
          -- }
          require("nvim_aider.neo_tree").setup(opts)
        end,
      },
    },
    config = function ()
      require('nvim_aider').setup({
          user_input_color = get_hl_color("String", "fg", "#a6da95"),
          tool_output_color = get_hl_color("Function", "fg", "#8aadf4"),
          tool_error_color = get_hl_color("Error", "fg", "#ed8796"),
          tool_warning_color = get_hl_color("WarningMsg", "fg", "#eed49f"),
          assistant_output_color = get_hl_color("Type", "fg", "#c6a0f6"),
          completion_menu_color = get_hl_color("Normal", "fg", "#cad3f5"),
          completion_menu_bg_color = get_hl_color("Normal", "bg", "#24273a"),
          completion_menu_current_color = get_hl_color("CursorLine", "fg", "#181926"),
          completion_menu_current_bg_color = get_hl_color("CursorLine", "bg", "#f4dbd6"),
      })
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
}
