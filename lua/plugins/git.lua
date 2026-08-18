return {
  {
    'folke/snacks.nvim',
    ---@type snacks.Config
    opts = {
      lazygit = {},
      terminal = {},
    },
    keys = {
      {
        '<leader>lg',
        function()
          Snacks = require 'snacks'
          Snacks.lazygit.open()
        end,
        desc = '[g]it [l]azygit',
      },
    },
  },
  {
    'tpope/vim-fugitive',
    event = 'BufEnter',
    keys = {
      { '<leader>gs', '<cmd>G<cr>', desc = '[g]it [s]tatus' },
      { '<leader>gc', '<cmd>G commit<cr>', desc = '[g]it [c]ommit' },
      { '<leader>gb', '<cmd>G blame -w<cr>', desc = '[g]it [b]lame' },
    },
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
}
