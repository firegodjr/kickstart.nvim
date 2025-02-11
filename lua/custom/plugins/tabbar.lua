vim.o.showtabline = 2;

return {
  {
    'nanozuki/tabby.nvim',
    event = 'VimEnter',
    dependencies = 'nvim-tree/nvim-web-devicons',
    keys = {
      { "<A-,>", "<cmd>bprev<cr>", { silent = true } },
      { "<A-.>", "<cmd>bnext<cr>", { silent = true } },
      { "<A-c>", "<cmd>bp|bd#<cr>", { silent = true } },
      { "<A-x>", "<cmd>bp|bd!#<cr>", { silent = true } },
      { "<A-<>", "<cmd>tabn<cr>", { silent = true } },
      { "<A->>", "<cmd>tabp<cr>", { silent = true } },
      { "<A-S-c>", "<cmd>tabclose<cr>", { silent = true } },
    },
    config = function()
      local theme = {
        fill = 'TabLineFill',
        head = 'TabLine',
        current_tab = 'TabLineSel',
        tab = 'TabLine',
        win = 'TabLine',
        tail = 'TabLine',
      }
      require('tabby').setup({
        line = function(line)
          return {
            line.bufs().foreach(function(buf)
              local hl = buf.is_current() and theme.current_tab or theme.tab
              return {
                '▎',
                buf.id,
                buf.file_icon(),
                buf.name(),
                buf.is_changed() and '' or '',
                line.sep(' ', hl, theme.fill),
                hl = hl,
                margin = ' ',
            }
            end),
            line.spacer(),
            line.tabs().foreach(function(tab)
              local hl = tab.is_current() and theme.current_tab or theme.tab
              return {
                '▎',
                tab.number(),
                tab.name(),
                tab.close_btn(''),
                line.sep(' ', hl, theme.fill),
                hl = hl,
                margin = ' ',
            }
            end),
          }
        end,
        option = {
          buf_name = {
            mode = 'tail'
          }
        }
      });
    end,
  },
  {
    'tiagovla/scope.nvim',
    config = function()
      require('scope').setup({
        
      });
    end,
  }
}
-- return {
--     'romgrk/barbar.nvim',
--     dependencies = {
--       'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
--       'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
--     },
--     init = function() vim.g.barbar_auto_setup = false end,
--     opts = {
--
--       exclude_name = {'powershell.EXE'},
--       maximum_length = 30,
--       sidebar_filetypes = {
--         ['neo-tree'] = true,
--       }
--     },
--     version = '^1.0.0', -- optional: only update when a new 1.x version is released
-- }
