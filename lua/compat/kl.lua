local M = {}

-- Returns the target path for jumping between viewmodel and view files.
local function get_target_path(filepath)
  local ts_exts = { ".ts", ".tsx" }
  local html_exts = { ".html", ".htm" }

  local function is_ts_file(path)
    for _, ext in ipairs(ts_exts) do
      if path:sub(-#ext) == ext then return true end
    end
    return false
  end

  local function is_html_file(path)
    for _, ext in ipairs(html_exts) do
      if path:sub(-#ext) == ext then return true end
    end
    return false
  end

  local function replace_ext(path, new_ext)
    return path:gsub("%.[^%.]+$", new_ext)
  end

  local function try_paths(paths)
    for _, p in ipairs(paths) do
      if vim.fn.filereadable(p) == 1 then return p end
    end
    return nil
  end

  local sep = package.config:sub(1,1)
  local parts = vim.split(filepath, sep)
  local filename = parts[#parts]
  local base = filename:gsub("%.[^%.]+$", "")

  if is_ts_file(filepath) then
    -- Try same folder
    local html_path = replace_ext(filepath, ".html")
    local htm_path = replace_ext(filepath, ".htm")
    local found = try_paths { html_path, htm_path }
    if found then return found end

    -- Try sibling folder named 'views' or 'view'
    for _, folder in ipairs { "views", "view" } do
      parts[#parts] = folder .. sep .. base .. ".html"
      local candidate = table.concat(parts, sep)
      if vim.fn.filereadable(candidate) == 1 then return candidate end
      parts[#parts] = folder .. sep .. base .. ".htm"
      candidate = table.concat(parts, sep)
      if vim.fn.filereadable(candidate) == 1 then return candidate end
    end

    -- Try replacing 'viewmodels' with 'views' in path
    local vm_idx
    for i, p in ipairs(parts) do
      if p:lower():find("viewmodel") then vm_idx = i end
    end
    if vm_idx then
      for _, folder in ipairs { "views", "view" } do
        local new_parts = vim.deepcopy(parts)
        new_parts[vm_idx] = folder
        local candidate = table.concat(new_parts, sep)
        candidate = replace_ext(candidate, ".html")
        if vim.fn.filereadable(candidate) == 1 then return candidate end
        candidate = replace_ext(candidate, ".htm")
        if vim.fn.filereadable(candidate) == 1 then return candidate end
      end
    end
  elseif is_html_file(filepath) then
    -- Try same folder
    local ts_path = replace_ext(filepath, ".ts")
    local tsx_path = replace_ext(filepath, ".tsx")
    local found = try_paths { ts_path, tsx_path }
    if found then return found end

    -- Try sibling folder named 'viewmodels' or 'viewmodel'
    for _, folder in ipairs { "viewmodels", "viewmodel" } do
      parts[#parts] = folder .. sep .. base .. ".ts"
      local candidate = table.concat(parts, sep)
      if vim.fn.filereadable(candidate) == 1 then return candidate end
      parts[#parts] = folder .. sep .. base .. ".tsx"
      candidate = table.concat(parts, sep)
      if vim.fn.filereadable(candidate) == 1 then return candidate end
    end

    -- Try replacing 'views' with 'viewmodels' in path
    local v_idx
    for i, p in ipairs(parts) do
      if p:lower():find("view") and not p:lower():find("viewmodel") then v_idx = i end
    end
    if v_idx then
      for _, folder in ipairs { "viewmodels", "viewmodel" } do
        local new_parts = vim.deepcopy(parts)
        new_parts[v_idx] = folder
        local candidate = table.concat(new_parts, sep)
        candidate = replace_ext(candidate, ".ts")
        if vim.fn.filereadable(candidate) == 1 then return candidate end
        candidate = replace_ext(candidate, ".tsx")
        if vim.fn.filereadable(candidate) == 1 then return candidate end
      end
    end
  end

  return nil
end

-- Jump between TypeScript viewmodel and HTML/HTM view files
function M.jump()
  local filepath = vim.api.nvim_buf_get_name(0)
  local target = get_target_path(filepath)
  if target then
    vim.api.nvim_command("edit " .. target)
  else
    vim.notify("No corresponding file found", vim.log.levels.WARN)
  end
end

-- Set up keymap and user command when module loads, but only once
if not vim.g.kl_jump_setup_done then
  vim.keymap.set('n', '<leader>kv', function() require('compat.kl').jump() end, { desc = 'Jump between [K]L viewmodel/view' })
  vim.api.nvim_create_user_command('JumpKL', function() require('compat.kl').jump() end, { desc = 'Jump between KL viewmodel/view' })
  vim.g.kl_jump_setup_done = true
end

return M
