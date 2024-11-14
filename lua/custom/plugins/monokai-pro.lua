return {
  url = 'https://github.com/firegodjr/monokai-pro.nvim.git',
  priority = 1000, -- Make sure to load this before all the other start plugins.
  init = function()
    vim.cmd.hi 'Comment gui=none'
  end
}
