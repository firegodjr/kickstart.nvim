require('nvim-treesitter.install').compilers = { 'clang' }
vim.cmd [[set shell=powershell]]
vim.cmd [[set shellcmdflag=-command]]
vim.cmd [[set shellxquote=]]
vim.keymap.set(
  'n',
  '<leader>FF',
  '<Cmd>update<CR><Cmd>e ++ff=dos<CR><Cmd>setlocal ff=unix<CR><Cmd>w<CR>',
  { desc = '[F]ix [F]ile (remove excess ^M characters)' }
)
