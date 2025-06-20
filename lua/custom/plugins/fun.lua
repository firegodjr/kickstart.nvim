local wk = require('which-key');
wk.add({{ '<leader>f', hidden=true }});

return {
  { 'eandrju/cellular-automaton.nvim',
    keys = {
      { "<leader>fml", "<cmd>CellularAutomaton make_it_rain<cr>", { silent = true } } 
    }
  }
}
