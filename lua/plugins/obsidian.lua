-- Check first if workspace exists
local workspaces = {}

if vim.fn.isdirectory('/media/sf_OneDrive_KnowledgeLake/Obsidian/') == 1 then
  table.insert(workspaces, {
    name = 'kl_onedrive_vm',
    path = '/media/sf_OneDrive_KnowledgeLake/Obsidian/',
  })
end
if vim.fn.isdirectory(vim.fn.expand('~/OneDrive - KnowledgeLake/Obsidian/')) == 1 then
  table.insert(workspaces, {
    name = 'kl_onedrive',
    path = vim.fn.expand('~/OneDrive - KnowledgeLake/Obsidian/'),
  })
end

return {
  'epwalsh/obsidian.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  version = '*',
  lazy = true,
  ft = 'markdown',
  opts = {
    workspaces = workspaces,
  },
}


