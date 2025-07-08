return {
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
