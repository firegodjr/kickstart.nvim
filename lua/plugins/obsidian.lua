local function getWorkspaces()
  local workspaces = {}
  -- Only add OneDrive workspace if path exists
  -- Check for both Linux and Windows VMs
  if (vim.fn.isdirectory('/media/sf_OneDrive_KnowledgeLake/Obsidian/') == 1) then
    table.insert(workspaces, {
      name = 'kl_onedrive',
      path = '/media/sf_OneDrive_KnowledgeLake/Obsidian/',
    })
  elseif (vim.fn.isdirectory(vim.fn.expand('~/OneDrive - KnowledgeLake/Obsidian/') == 1)) then
    table.insert(workspaces, {
      name = 'kl_onedrive',
      path = '~/OneDrive - KnowledgeLake/Obsidian/',
    })
  end
  return workspaces;
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
    workspaces = getWorkspaces()
  },
}


