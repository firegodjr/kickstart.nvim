--[[
Plugins in this file:
- kdheepak/lazygit.nvim
- nvim-lua/plenary.nvim
- rhysd/conflict-marker.vim
- tpope/vim-fugitive
]]

return {
  {
    'kdheepak/lazygit.nvim',
    lazy = true,
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },
  {
    'rhysd/conflict-marker.vim',
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
}
