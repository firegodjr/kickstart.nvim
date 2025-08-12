return {
  'epwalsh/obsidian.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  version = '*',
  lazy = true,
  ft = 'markdown',
  opts = {
    workspaces = {
      {
        name = 'kl_onedrive',
        path = '/media/sf_OneDrive_KnowledgeLake/Obsidian/',
      },
    },
  },
}
