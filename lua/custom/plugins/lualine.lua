return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', 'f-person/git-blame.nvim' },
  config = function()
    local git_blame = require('gitblame')
    git_blame.setup({
      message_template = "<sha>  <author>  <date>",
      message_when_not_committed = "Noncommitted Changes",
    })
    vim.g.gitblame_display_virtual_text=0

    require('lualine').setup({
      options = {
        component_separators = { left = '', right = '' },
        -- section_separators = { left = '', right = '' },
      },
      -- winbar = {
      --   lualine_x = {{ icon='', git_blame.get_current_blame_text, git_blame, cond = git_blame.is_blame_text_available }},
      --   lualine_y = { {'diff'} },
      --   lualine_z = {'branch'},
      -- },
      -- inactive_winbar = {
      --   lualine_a = {'filename'},
      -- },
      sections = {
        lualine_a = { {'mode', icon=''} },
        lualine_b = { {} },
        lualine_c = { 'filename', 'diagnostics'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
      },
    })
  end,
}
