-- sidebar.lua --
-- Docks tool panels into one right-hand column via edgy.nvim

local SIDEBAR_WIDTH = 50
local FILES_FT = 'neo-tree'
local OUTLINE_FT = 'Outline'
local TESTS_FT = 'neotest-summary'

local function win_with_ft(ft)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == ft then
      return win
    end
  end
end

local function focus_later(ft)
  vim.schedule(function()
    local win = win_with_ft(ft)

    if win then
      pcall(vim.api.nvim_set_current_win, win)
    end
  end)
end

-- outline captures its code window when the provider answers, which for LSP is after
-- focus has already moved to the tree, so point it back at the real code window
local function keep_code_win(win)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = OUTLINE_FT,
    once = true,
    callback = function()
      vim.schedule(function()
        local outline = require('outline')._get_sidebar()

        if outline and vim.api.nvim_win_is_valid(win) then
          outline.code = { win = win, buf = vim.api.nvim_win_get_buf(win) }
        end
      end)
    end,
  })
end

local function toggle_sidebar()
  require('edgy').goto_main()

  if win_with_ft(FILES_FT) or win_with_ft(OUTLINE_FT) then
    pcall(vim.cmd, 'Neotree close')
    pcall(vim.cmd, 'OutlineClose')
    return
  end

  keep_code_win(vim.api.nvim_get_current_win())

  vim.cmd 'OutlineOpen'
  vim.cmd 'Neotree reveal position=right source=filesystem'

  focus_later(FILES_FT)
end

return {
  {
    'folke/edgy.nvim',
    event = 'VeryLazy',
    opts = {
      animate = { enabled = false },
      options = {
        right = { size = SIDEBAR_WIDTH },
      },
      -- To add a panel: append its buffer filetype below, where list order is
      -- top-to-bottom priority, and add that filetype to open_files_do_not_replace_types
      -- in ui.lua so neo-tree never opens a file into it.
      right = {
        {
          title = 'Files',
          ft = FILES_FT,
          filter = function(buf)
            return vim.b[buf].neo_tree_source == 'filesystem'
          end,
        },
        {
          title = 'Outline',
          ft = OUTLINE_FT,
          size = { height = 0.33 },
        },
        {
          title = 'Tests',
          ft = TESTS_FT,
          size = { height = 0.33 },
        },
      },
    },
    config = function(_, opts)
      require('edgy').setup(opts)

      -- closing a panel fires only WinClosed, which edgy does not relayout on, so the
      -- survivors keep their equalised heights instead of their declared shares
      vim.api.nvim_create_autocmd('WinClosed', {
        callback = function()
          vim.schedule(require('edgy.layout').update)
        end,
      })
    end,
    keys = {
      { '\\', toggle_sidebar, desc = 'Toggle sidebar' },
    },
  },
}
