local wk = require('which-key');
wk.add({{ '<leader>o', group='[O]verseer' }});

return {
  'stevearc/overseer.nvim',
  keys = {
    { '<leader>ol', '<cmd>OverseerToggle<cr>', desc = '[O]verseer [T]oggle' },
    { '<leader>ot', '<cmd>OverseerRun<cr>', desc = '[O]verseer [R]un' }
  },
  config = function ()
    require('overseer').setup();
  end
}

