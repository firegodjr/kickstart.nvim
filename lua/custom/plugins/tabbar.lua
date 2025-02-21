vim.o.showtabline = 2;

return {
  {
    'nanozuki/tabby.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'uga-rosa/utf8.nvim' },
    keys = {
      { "<A-,>", "<cmd>bprev<cr>", { silent = true } },
      { "<A-.>", "<cmd>bnext<cr>", { silent = true } },
      { "<A-c>", "<cmd>bp|bd#<cr>", { silent = true } },
      { "<A-x>", "<cmd>bp|bd!#<cr>", { silent = true } },
      { "<A-<>", "<cmd>tabp<cr>", { silent = true } },
      { "<A->>", "<cmd>tabn<cr>", { silent = true } },
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
          local utf8 = require("utf8");
          local function sub(s,i,j)
                i=utf8.offset(s,i)
                j=utf8.offset(s,j+1)-1
                return string.sub(s,i,j)
          end
          local tabIcons = '󰋜󰅩󰯉';
          return {
            line.bufs().foreach(function(buf)
              local hl = buf.is_current() and theme.current_tab or theme.tab
              return {
                line.sep('', hl, theme.fill),
                buf.file_icon(),
                buf.name(),
                -- buf.id,
                buf.is_changed() and '' or '',
                line.sep('', hl, theme.fill),
                hl = hl,
                margin = ' ',
            }
            end),
            line.spacer(),
            line.tabs().foreach(function(tab)
              local hl = tab.is_current() and theme.current_tab or theme.tab
              return {
                line.sep('', hl, theme.fill),
                utf8.len(tabIcons) > tab.id and sub(tabIcons, tab.id, tab.id) or tab.id,
                -- tab.name(),
                #tab.wins().wins >= 1 and (#tab.wins().wins) or '',
                -- tab.close_btn(''),
                line.sep('', hl, theme.fill),
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
