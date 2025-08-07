return {
  {
    "ray-x/go.nvim",
    dependencies = {  -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      -- lsp_keymaps = false,
      -- other options
    },
    config = function(lp, opts)
      require("go").setup(opts)
      local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
        require('go.format').goimports()
        end,
        group = format_sync_grp,
      })
    end,
    event = {"CmdlineEnter"},
    ft = {"go", 'gomod'},
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
  -- Compile Less on save
  {
    "askfiy/neovim-easy-less",
    ft = { "less" },
    config = function()
      require("easy-less").setup()
    end
  },
  -- Refactoring
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {},
    keys = {
      { "<leader>re", ":Refactor extract ", desc="[R]efactor [E]xtract"},
      { "<leader>rf", ":Refactor extract_to_file ", desc="[R]efactor Extract to [F]ile"},
      { "<leader>rv", ":Refactor extract_var ", desc="[R]efactor Extract [V]ariable"},
      { "<leader>rI", "<cmd>Refactor inline_func<cr>", desc="[R]efactor [I]nline"},
      { "<leader>ri", "<cmd>Refactor inline_var<cr>", desc="[R]efactor [I]nline Variable"},
      { "<leader>rb", "<cmd>Refactor extract_block<cr>", desc="[R]efactor Extract [B]lock"},
      { "<leader>rbf", "<cmd>Refactor extract_block_to_file<cr>", desc="[R]efactor Extract [B]lock to [F]ile"},
    },
    config = function ()
      require('refactoring').setup();
    end
  },
}
