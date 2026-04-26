local wk = require 'which-key'

local dap = require 'dap'

local function spawn_in_terminal(cmd)
  if vim.env.TMUX then
    vim.fn.jobstart({ 'tmux', 'split-window', '-h', cmd }, { detach = true })
  else
    vim.fn.jobstart({ 'alacritty', '-e', 'sh', '-c', cmd }, { detach = true })
  end
end

local function get_pid()
  local dll = require('dap.utils').pick_file { executables = false, filter = 'bin/.*%.dll$' }
  if dll == '' then
    return nil
  end

  local pid_file = vim.fn.tempname()
  local shell_cmd = string.format('echo $$ > %s; sleep 0.5; exec dotnet %s', pid_file, vim.fn.shellescape(dll))

  spawn_in_terminal(shell_cmd)

  local pid
  vim.wait(5000, function()
    if vim.fn.filereadable(pid_file) == 1 then
      local line = (vim.fn.readfile(pid_file) or {})[1]
      pid = line and tonumber(line) or nil
      return pid ~= nil
    end
    return false
  end, 50)

  vim.defer_fn(function()
    pcall(os.remove, pid_file)
  end, 3000)

  if not pid then
    vim.notify("Couldn't capture dotnet PID", vim.log.levels.ERROR)
    return nil
  end
  return pid
end

table.insert(dap.configurations.cs, 1, {
  type = 'coreclr',
  name = 'Launch (tmux/alacritty)',
  request = 'attach',
  processId = get_pid,
})

wk.add {
  { '<leader>D', group = '[D]otnet' },
  {
    '<leader>Db',
    function()
      vim.cmd [[
        compiler dotnet
        make
      ]]
    end,
    desc = '[D]otnet [b]uild',
  },
  {
    '<leader>Dr',
    function()
      vim.cmd [[
        compiler dotnet
        make
      ]]
      dap.run {
        type = 'coreclr',
        name = 'Launch (tmux/alacritty)',
        request = 'attach',
        processId = get_pid,
      }
    end,
    desc = '[D]otnet [r]un',
  },
}
