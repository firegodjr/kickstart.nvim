local M = {}

local function trim(text)
  return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function scalar(text)
  if text == '' or text == '~' or text == 'null' then
    return nil
  end
  local quoted = text:match '^"(.*)"$' or text:match "^'(.*)'$"
  if quoted then
    return quoted
  end
  if text == 'true' then
    return true
  end
  if text == 'false' then
    return false
  end
  return tonumber(text) or text
end

local function flow_list(text)
  local inner = text:match '^%[(.*)%]$'
  if not inner then
    return nil
  end
  local list = {}
  for item in inner:gmatch '[^,]+' do
    list[#list + 1] = scalar(trim(item))
  end
  return list
end

local function rows(text)
  local list = {}
  for line in (text .. '\n'):gmatch '(.-)\r?\n' do
    local body = line:match '^%s*#' and '' or line
    if not body:match '["\']' then
      body = body:gsub('%s+#.*$', '')
    end
    if trim(body) ~= '' then
      list[#list + 1] = { indent = #body:match '^ *', text = trim(body) }
    end
  end
  return list
end

local parse_block

local function parse_value(lines, index, text, indent)
  if text ~= '' then
    return flow_list(text) or scalar(text), index + 1
  end
  local child = lines[index + 1]
  if not child or child.indent <= indent then
    return nil, index + 1
  end
  return parse_block(lines, index + 1, child.indent)
end

parse_block = function(lines, index, indent)
  local result = {}
  local count = 0

  while index <= #lines and lines[index].indent >= indent do
    local text = lines[index].text
    local item = text:match '^%-%s*(.*)$'

    if item then
      local value
      value, index = parse_value(lines, index, item, indent)
      count = count + 1
      result[count] = value
    else
      local key, rest = text:match '^([^:]+):%s*(.*)$'
      if not key then
        return result, index + 1
      end
      key = trim(key)
      key = key:match '^"(.*)"$' or key:match "^'(.*)'$" or key
      result[key], index = parse_value(lines, index, rest, indent)
    end
  end

  return result, index
end

function M.decode(text)
  local lines = rows(text)
  if #lines == 0 then
    return {}
  end
  return (parse_block(lines, 1, lines[1].indent))
end

local function quoted(text)
  if text == '' or text:match '^[%s#]' or text:match '[:#]%s' or text:match '%s$' then
    return '"' .. text:gsub('"', '\\"') .. '"'
  end
  return text
end

local function sorted_keys(map)
  local keys = {}
  for key in pairs(map) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

local encode_map

local function encode_value(value, indent)
  if type(value) ~= 'table' then
    return ' ' .. quoted(tostring(value)), nil
  end
  if next(value) == nil then
    return ' {}', nil
  end
  return '', encode_map(value, indent .. '  ')
end

encode_map = function(map, indent)
  local lines = {}

  if vim.islist(map) then
    for _, item in ipairs(map) do
      local inline, nested = encode_value(item, indent)
      lines[#lines + 1] = indent .. '-' .. inline
      vim.list_extend(lines, nested or {})
    end
    return lines
  end

  for _, key in ipairs(sorted_keys(map)) do
    local inline, nested = encode_value(map[key], indent)
    lines[#lines + 1] = indent .. key .. ':' .. inline
    vim.list_extend(lines, nested or {})
  end
  return lines
end

function M.encode(value)
  return encode_map(value, '')
end

function M.read(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local ok, value = pcall(M.decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok or type(value) ~= 'table' then
    return nil
  end
  return value
end

return M
