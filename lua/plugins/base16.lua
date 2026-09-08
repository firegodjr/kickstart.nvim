-- Makes automatic theming based on noctalia work
-- Only relevant on BlackICE
return {
  'RRethy/base16-nvim',
  config = function()
    local function apply_lualine_theme()
      local colors = require('base16-colorscheme').colors
      local theme = {
        normal = {
          a = { fg = colors.base00, bg = colors.base0B, gui = 'bold' },
          b = { fg = colors.base05, bg = colors.base02 },
          c = { fg = colors.base05, bg = colors.base00 },
        },
        insert = { a = { fg = colors.base00, bg = colors.base0D, gui = 'bold' } },
        visual = { a = { fg = colors.base00, bg = colors.base0A, gui = 'bold' } },
        replace = { a = { fg = colors.base00, bg = colors.base08, gui = 'bold' } },
        command = { a = { fg = colors.base00, bg = colors.base0C, gui = 'bold' } },
        inactive = {
          a = { fg = colors.base03, bg = colors.base00 },
          b = { fg = colors.base03, bg = colors.base00 },
          c = { fg = colors.base03, bg = colors.base00 },
        },
      }

      require('lualine').setup { options = { theme = theme } }
    end

    local ok, matugen = pcall(require, 'matugen')
    if ok then
      matugen.setup()
      apply_lualine_theme()
    end
  end,
}
