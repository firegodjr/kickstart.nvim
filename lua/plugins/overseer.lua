local wk = require 'which-key'
wk.add { { '<leader>o', group = '[O]verseer' } }

return {
  'stevearc/overseer.nvim',
  event = 'VimEnter',
  keys = {
    { '<leader>ot', '<cmd>OverseerToggle<cr>', desc = '[O]verseer [T]oggle' },
    { '<leader>or', '<cmd>OverseerRun<cr>', desc = '[O]verseer [R]un' },
  },
  config = function()
    require('overseer').setup()
  end,
}
