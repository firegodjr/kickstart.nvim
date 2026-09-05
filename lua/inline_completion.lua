local M = {}

local yaml = require 'inline_completion.yaml'

local CLIENT_NAME = 'inline-completion'
local MARKER_NAME = '.nvim/inline-completion.yaml'
local LEGACY_MARKER_NAME = '.nvim/inline-completion.json'
local STATE_FILE = vim.fs.normalize(vim.fn.stdpath 'state' .. '/inline-completion.yaml')
local LEGACY_STATE_FILE = vim.fs.normalize(vim.fn.stdpath 'state' .. '/inline-completion.json')
local PROVIDERS_DIR = vim.fs.normalize(vim.fn.stdpath 'config' .. '/inline-completion/providers')

local LOG_FILE = vim.fs.normalize(vim.fn.stdpath 'log' .. '/inline-completion.log')
local LOG_ENTRIES = 10
local LOG_SECTION_CHARS = 4000

local DEFAULT_PROVIDER = 'azure'

local KIND = { AZURE = 'azure', OPENAI = 'openai' }
local ROUTE = { AUTO = 'auto', V1 = 'v1', DEPLOYMENTS = 'deployments', RESPONSES = 'responses' }
local FORMAT = { AUTO = 'auto', CHAT = 'chat', RESPONSES = 'responses', FIM = 'fim' }
local TEMPERATURE = { SUPPORTED = 'supported', UNSUPPORTED = 'unsupported' }
local PROMPT = { CURSOR = 'cursor', PREFIX_SUFFIX = 'prefix_suffix' }

local state = {
  configured = false,
  client_ids = {},
  requests = {},
  next_request_id = 0,
  notifications = {},
  log = {},
}

local function merge(base, extra)
  local result = vim.deepcopy(base)
  for key, value in pairs(extra or {}) do
    if type(value) == 'table' and type(result[key]) == 'table' then
      result[key] = merge(result[key], value)
    else
      result[key] = value
    end
  end
  return result
end

local function notify(message, level, key)
  key = key or message
  local now = vim.uv.now()
  if state.notifications[key] and now - state.notifications[key] < 10000 then
    return
  end
  state.notifications[key] = now
  vim.notify(message, level or vim.log.levels.INFO, { title = 'Inline completion' })
end

local function announce(message, level)
  notify(message, level, tostring(vim.uv.now()))
end

local function path_is_dir(path)
  return path and vim.fn.isdirectory(path) == 1
end

local function project_root(bufnr)
  local configured_root = vim.g.inline_completion_project_root
  if path_is_dir(configured_root) then
    return vim.fs.normalize(configured_root)
  end

  local source = vim.api.nvim_buf_get_name(bufnr or 0)
  if source == '' then
    source = vim.fn.getcwd()
  end
  local root = vim.fs.root(source, {
    '.git',
    'Makefile',
    'package.json',
    '*.sln',
    'pyproject.toml',
    'go.mod',
    'Cargo.toml',
  })
  return root and vim.fs.normalize(root) or nil
end

local function marker_path(root)
  return root and (root .. '/' .. MARKER_NAME) or nil
end

local function legacy_marker_path(root)
  return root and (root .. '/' .. LEGACY_MARKER_NAME) or nil
end

local function read_approval(root)
  local value = marker_path(root) and yaml.read(marker_path(root))
  if not value then
    local legacy = legacy_marker_path(root)
    if not legacy or vim.fn.filereadable(legacy) ~= 1 then
      return false
    end
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(legacy), '\n'))
    value = ok and decoded or nil
  end
  if type(value) ~= 'table' or value.approved ~= true then
    return false
  end
  for key in pairs(value) do
    if key ~= 'approved' then
      return false
    end
  end
  return true
end

local function write_approval(root)
  if not root then
    return false, 'no project root was detected'
  end
  local directory = root .. '/.nvim'
  if vim.fn.mkdir(directory, 'p', 448) ~= 1 and vim.fn.isdirectory(directory) ~= 1 then
    return false, 'could not create the project approval directory'
  end
  local path = marker_path(root)
  local temporary = path .. '.tmp.' .. tostring(vim.fn.getpid())
  local ok, encoded = pcall(yaml.encode, { approved = true })
  if not ok then
    return false, 'could not encode the approval marker'
  end
  if vim.fn.writefile(encoded, temporary) ~= 0 then
    return false, 'could not write the approval marker'
  end
  local renamed, rename_error = vim.uv.fs_rename(temporary, path)
  if not renamed then
    vim.fn.delete(temporary)
    return false, rename_error or 'could not install the approval marker'
  end
  return true
end

local function remove_approval(root)
  local path = marker_path(root)
  if not path then
    return false, 'no project root was detected'
  end
  for _, target in ipairs { path, legacy_marker_path(root) } do
    if vim.fn.filereadable(target) == 1 and vim.fn.delete(target) ~= 0 then
      return false, 'could not remove the approval marker'
    end
  end
  return true
end

local function read_legacy_preferences()
  if vim.fn.filereadable(LEGACY_STATE_FILE) ~= 1 then
    return nil
  end
  local ok, value = pcall(vim.json.decode, table.concat(vim.fn.readfile(LEGACY_STATE_FILE), '\n'))
  return ok and type(value) == 'table' and value or nil
end

local function read_preferences()
  local value = yaml.read(STATE_FILE) or read_legacy_preferences() or {}
  value.models = type(value.models) == 'table' and value.models or {}
  return value
end

local function write_preferences(preferences)
  local directory = vim.fs.dirname(STATE_FILE)
  vim.fn.mkdir(directory, 'p')
  local ok, encoded = pcall(yaml.encode, preferences)
  if not ok then
    return false, 'could not encode the provider preferences'
  end
  if vim.fn.writefile(encoded, STATE_FILE) ~= 0 then
    return false, 'could not write the provider preferences'
  end
  return true
end

local function migrate_preferences()
  if vim.fn.filereadable(STATE_FILE) == 1 then
    return
  end
  local legacy = read_legacy_preferences()
  if legacy then
    write_preferences(legacy)
  end
end


local function env_or(value, names)
  if value ~= nil and value ~= '' then
    return value
  end
  for _, name in ipairs(names or {}) do
    if vim.env[name] and vim.env[name] ~= '' then
      return vim.env[name]
    end
  end
end

local PROVIDER_DEFAULTS = {
  kind = KIND.OPENAI,
  order = math.huge,
  api_format = FORMAT.AUTO,
  route = ROUTE.AUTO,
  temperature = TEMPERATURE.SUPPORTED,
  prompt = PROMPT.CURSOR,
}

local function load_provider(path)
  local definition = yaml.read(path)
  if not definition then
    announce('Could not read ' .. path .. '.', vim.log.levels.ERROR)
    return nil
  end

  local provider = merge(PROVIDER_DEFAULTS, definition)
  provider.label = provider.label or vim.fs.basename(path):gsub('%.yaml$', '')
  provider.endpoint = env_or(provider.endpoint, provider.endpoint_env)
  provider.model = env_or(provider.model, provider.model_env)
  provider.api_key = env_or(provider.api_key, provider.key_env)

  return provider
end

local function model_matches(pattern, model)
  if not pattern:find('*', 1, true) then
    return false
  end
  local escaped = pattern:gsub('[%^%$%(%)%%%.%[%]%+%-%?]', '%%%1'):gsub('%*', '.*')
  return model:match('^' .. escaped .. '$') ~= nil
end

local function apply_model_overrides(provider)
  local overrides = provider.models
  if not overrides or not provider.model then
    return provider
  end

  local patterns = {}
  for pattern in pairs(overrides) do
    if model_matches(pattern, provider.model) then
      patterns[#patterns + 1] = pattern
    end
  end
  table.sort(patterns, function(left, right)
    return #left < #right
  end)
  if overrides[provider.model] then
    patterns[#patterns + 1] = provider.model
  end

  local resolved = provider
  for _, pattern in ipairs(patterns) do
    resolved = merge(resolved, overrides[pattern])
  end
  return resolved
end

local function load_providers()
  local providers = {}
  for name, kind in vim.fs.dir(PROVIDERS_DIR) do
    local key = name:match '^(.+)%.yaml$'
    if key and kind == 'file' then
      providers[key] = load_provider(PROVIDERS_DIR .. '/' .. name)
    end
  end
  return providers
end

local function normalize_config(opts)
  local defaults = {
    provider = DEFAULT_PROVIDER,
    providers = load_providers(),
    max_context_lines = 80,
    max_context_chars = 12000,
    max_response_tokens = 128,
    max_completion_lines = 6,
    max_reasoning_tokens = 2048,
    temperature = 0.2,
    timeout_ms = 8000,
    transport = nil,
  }
  local config = merge(defaults, opts)

  local preferences = read_preferences()
  if config.providers[preferences.provider] then
    config.provider = preferences.provider
  end
  for name, model in pairs(preferences.models or {}) do
    if config.providers[name] and type(model) == 'string' then
      config.providers[name].model = model
    end
  end
  for name, provider in pairs(config.providers) do
    config.providers[name] = apply_model_overrides(provider)
  end
  return config
end

local function config()
  state.config = state.config or normalize_config {}
  return state.config
end

local function active_name()
  local current = config().provider
  return config().providers[current] and current or DEFAULT_PROVIDER
end

local function active()
  return config().providers[active_name()]
end

local function configured(value)
  return type(value) == 'string' and value ~= ''
end

local function model_of(provider)
  return provider.model
end

local function is_configured(provider)
  if not provider or not configured(provider.endpoint) or not configured(provider.api_key) then
    return false
  end
  return configured(model_of(provider))
end

local function trim_endpoint(endpoint)
  return (endpoint:gsub('/+$', ''))
end

local V1_PATH = '/openai/v1'
local DEPLOYMENTS_PATH = '/openai/deployments'
local RESPONSES_PATH = '/openai/responses'

local function azure_base(endpoint)
  local base = trim_endpoint(endpoint)
  local without_v1 = base:match('^(.-)' .. V1_PATH .. '$')
  if without_v1 then
    return without_v1, true
  end
  return (base:gsub('/openai$', '')), false
end

local function url_escape(value)
  return tostring(value):gsub('([^%w%-%._~])', function(char)
    return string.format('%%%02X', string.byte(char))
  end)
end

local function versioned(url, provider)
  if not configured(provider.api_version) then
    return url
  end
  return url .. '?api-version=' .. url_escape(provider.api_version)
end

local function azure_route(provider)
  if provider.route ~= ROUTE.AUTO then
    return provider.route
  end
  local _, endpoint_is_v1 = azure_base(provider.endpoint)
  return endpoint_is_v1 and ROUTE.V1 or ROUTE.DEPLOYMENTS
end

local function azure_request(name, provider)
  local base = azure_base(provider.endpoint)
  local route = azure_route(provider)
  local headers = { ['Content-Type'] = 'application/json' }
  local body = {}
  local api_format = FORMAT.CHAT
  local url

  if route == ROUTE.V1 then
    api_format = provider.api_format == FORMAT.CHAT and FORMAT.CHAT or FORMAT.RESPONSES
    url = base .. V1_PATH .. (api_format == FORMAT.RESPONSES and '/responses' or '/chat/completions')
    body.model = provider.model
    headers.Authorization = 'Bearer ' .. provider.api_key
  elseif route == ROUTE.RESPONSES then
    api_format = FORMAT.RESPONSES
    url = versioned(base .. RESPONSES_PATH, provider)
    body.model = provider.model
    headers['api-key'] = provider.api_key
  else
    url = versioned(base .. DEPLOYMENTS_PATH .. '/' .. url_escape(provider.model) .. '/chat/completions', provider)
    headers['api-key'] = provider.api_key
  end

  return {
    name = name,
    url = url,
    headers = headers,
    api_format = api_format,
    prompt = provider.prompt,
    temperature = provider.temperature,
    reasoning = provider.reasoning,
    timeout_ms = provider.timeout_ms,
    body = body,
  }
end

local FIM_PATH = '/api/generate'

local function ollama_base(endpoint)
  return (trim_endpoint(endpoint):gsub('/v1$', ''))
end

local function fim_request(name, provider)
  return {
    name = name,
    url = ollama_base(provider.endpoint) .. FIM_PATH,
    headers = { ['Content-Type'] = 'application/json' },
    api_format = FORMAT.FIM,
    timeout_ms = provider.timeout_ms,
    body = {
      model = provider.model,
      stream = false,
      options = {
        num_predict = config().max_response_tokens,
        temperature = config().temperature,
      },
    },
  }
end

local function openai_request(name, provider)
  local endpoint = trim_endpoint(provider.endpoint)
  local url = endpoint:match '/chat/completions$' and endpoint or endpoint .. '/chat/completions'
  return {
    name = name,
    url = url,
    headers = {
      ['Content-Type'] = 'application/json',
      Authorization = 'Bearer ' .. provider.api_key,
    },
    api_format = FORMAT.CHAT,
    prompt = provider.prompt,
    temperature = provider.temperature,
    timeout_ms = provider.timeout_ms,
    body = {
      model = provider.model,
      messages = {},
      max_tokens = config().max_response_tokens,
      stream = false,
    },
  }
end

local function provider_for(bufnr)
  local name = active_name()
  local provider = config().providers[name]

  if not is_configured(provider) then
    return nil, string.format('%s is not configured', provider.label)
  end

  if provider.needs_approval then
    local root = project_root(bufnr)
    if not root then
      return nil, string.format('%s needs a detectable project root', provider.label)
    end
    if not read_approval(root) then
      return nil, string.format('%s needs :InlineCompletionApprove for this project', provider.label)
    end
  end

  if provider.kind == KIND.AZURE then
    return azure_request(name, provider)
  end
  if provider.api_format == FORMAT.FIM then
    return fim_request(name, provider)
  end
  return openai_request(name, provider)
end

local function byte_index(line, character)
  local ok, index = pcall(vim.str_byteindex, line, character, true)
  if not ok or type(index) ~= 'number' or index < 0 then
    return nil
  end
  return math.min(index, #line)
end

local KEEP = { HEAD = 'head', TAIL = 'tail' }

local function bounded_text(lines, max_chars, keep)
  local text = table.concat(lines, '\n')
  if #text <= max_chars then
    return text
  end
  if keep == KEEP.HEAD then
    return text:sub(1, max_chars)
  end
  return text:sub(#text - max_chars + 1)
end

local function context_for(bufnr, row, character)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line = lines[row + 1]
  if not line then
    return nil
  end
  local byte = byte_index(line, character)
  if not byte then
    return nil
  end

  local max_lines = math.max(2, tonumber(config().max_context_lines) or 80)
  local before_count = math.floor(max_lines / 2)
  local after_count = max_lines - before_count - 1
  local start = math.max(1, row + 1 - before_count)
  local finish = math.min(#lines, row + 1 + after_count)
  local prefix = {}
  local suffix = {}
  for index = start, row + 1 do
    prefix[#prefix + 1] = index == row + 1 and line:sub(1, byte) or lines[index]
  end
  for index = row + 1, finish do
    suffix[#suffix + 1] = index == row + 1 and line:sub(byte + 1) or lines[index]
  end
  return {
    prefix = bounded_text(prefix, config().max_context_chars, KEEP.TAIL),
    suffix = bounded_text(suffix, config().max_context_chars, KEEP.HEAD),
    filetype = vim.bo[bufnr].filetype,
    row = row,
    character = character,
    changedtick = vim.b[bufnr].changedtick,
  }
end

local CURSOR = '<|cursor|>'

local STYLES = {
  [PROMPT.CURSOR] = {
    system = 'You provide inline code completions. The code you receive has '
      .. CURSOR
      .. ' marking the caret. Return only the code that replaces '
      .. CURSOR
      .. '. No explanation, no code fences, and never repeat code that already surrounds the caret. Your output must be syntactically correct in place.',
    user = function(context)
      return context.prefix .. CURSOR .. context.suffix
    end,
  },
  [PROMPT.PREFIX_SUFFIX] = {
    system = 'You provide inline code completions. Return only the code to insert. Your output must be syntactically correct when placed between prefix and suffix',
    user = function(context)
      return table.concat({ '<|prefix|>', context.prefix, '<|suffix|>', context.suffix }, '\n')
    end,
  },
}

local function completion_prompt(style, context)
  return table.concat({
    'Filetype: ' .. (context.filetype ~= '' and context.filetype or 'text'),
    style.user(context),
  }, '\n')
end

local function response_budget(request)
  if not request.reasoning then
    return config().max_response_tokens
  end
  return config().max_response_tokens + config().max_reasoning_tokens
end

local function request_body(request, context)
  if request.api_format == FORMAT.FIM then
    request.body.prompt = context.prefix
    request.body.suffix = context.suffix
    return request.body
  end

  local style = STYLES[request.prompt] or STYLES[PROMPT.CURSOR]
  local messages = {
    { role = 'system', content = style.system },
    { role = 'user', content = completion_prompt(style, context) },
  }

  if request.api_format == FORMAT.RESPONSES then
    request.body.input = messages
    request.body.max_output_tokens = response_budget(request)
    request.body.reasoning = request.reasoning
  else
    request.body.messages = messages
  end

  if request.temperature ~= TEMPERATURE.UNSUPPORTED then
    request.body.temperature = config().temperature
  end

  return request.body
end

local function curl_quote(value)
  return '"' .. tostring(value):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
end

local function curl_config(request)
  local lines = {
    'url = ' .. curl_quote(request.url),
    'request = ' .. (request.method or 'POST'),
    'silent',
    'show-error',
    'max-time = ' .. tostring(math.max(1, math.ceil(request.timeout_ms / 1000))),
    'write-out = "\\n%{http_code}"',
  }
  for name, value in pairs(request.headers) do
    lines[#lines + 1] = 'header = ' .. curl_quote(name .. ': ' .. value)
  end
  if request.body then
    lines[#lines + 1] = 'data = ' .. curl_quote(request.body)
  end
  return table.concat(lines, '\n') .. '\n'
end

local function transport_failure(code)
  local categories = {
    [6] = 'DNS lookup failure',
    [7] = 'connection failure',
    [28] = 'request timeout',
    [35] = 'TLS failure',
    [51] = 'TLS certificate failure',
    [52] = 'empty server response',
    [56] = 'network receive failure',
  }
  return categories[code] or 'network transport failure'
end

local function http_failure(status)
  if status == 401 or status == 403 then
    return 'authentication or authorization failure'
  end
  if status == 404 then
    return 'endpoint or deployment route not found'
  end
  if status == 408 then
    return 'server request timeout'
  end
  if status == 429 then
    return 'rate limit or quota exceeded'
  end
  if status >= 500 and status <= 599 then
    return 'provider server failure'
  end
  if status >= 400 and status <= 499 then
    return 'provider request rejected'
  end
  return 'unexpected HTTP response'
end

local function send_http(request, done)
  if config().transport then
    local finished = false
    local function finish(...)
      if finished then
        return
      end
      finished = true
      done(...)
    end
    local ok, result = pcall(config().transport, request, finish)
    if not ok then
      finish(result)
    elseif result ~= nil then
      finish(nil, result)
    end
    return function() end
  end

  local process = vim.system({ 'curl', '--config', '-' }, { stdin = curl_config(request), text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        done(transport_failure(result.code), nil)
        return
      end
      local output = result.stdout or ''
      local status_text = output:match '\n(%d%d%d)$'
      local status = tonumber(status_text)
      if not status then
        done('malformed HTTP response', nil)
        return
      end
      done(nil, { status = status, body = output:sub(1, #output - 4) })
    end)
  end)
  return function()
    if not process:is_closing() then
      process:kill(15)
    end
  end
end

local function fetch_models(provider, done)
  send_http({
    url = trim_endpoint(provider.endpoint) .. '/models',
    method = 'GET',
    headers = {
      ['Content-Type'] = 'application/json',
      Authorization = 'Bearer ' .. (provider.api_key or ''),
    },
    timeout_ms = config().timeout_ms,
  }, function(err, response)
    if err then
      done(nil, err)
      return
    end
    if type(response) ~= 'table' or response.status < 200 or response.status >= 300 then
      done(nil, http_failure(type(response) == 'table' and response.status or 0))
      return
    end
    local ok, decoded = pcall(vim.json.decode, response.body or '')
    if not ok or type(decoded) ~= 'table' or type(decoded.data) ~= 'table' then
      done(nil, 'malformed model list')
      return
    end
    local models = {}
    for _, item in ipairs(decoded.data) do
      if type(item.id) == 'string' then
        models[#models + 1] = item.id
      end
    end
    table.sort(models)
    done(models)
  end)
end

local function lsp_error(message, code)
  return { code = code or -32603, message = message }
end

local FENCE_OPEN = '```[%w_+#.-]*\n'

local function unfence(text)
  local closed = text:match(FENCE_OPEN .. '(.-)\n?```')
  if closed then
    return closed
  end
  return text:match(FENCE_OPEN .. '(.*)$') or text
end

local function first_content_line(text)
  for line in text:gmatch '[^\n]*' do
    if line:match '%S' then
      return (line:gsub('^%s+', ''))
    end
  end
end

local function trim_overrun(text, suffix)
  local boundary = first_content_line(suffix)
  local limit = config().max_completion_lines
  local kept = {}
  for line in text:gmatch '([^\n]*)\n?' do
    if line:gsub('^%s+', '') == boundary or #kept >= limit then
      break
    end
    kept[#kept + 1] = line
  end
  local trimmed = table.concat(kept, '\n'):gsub('%s+$', '')
  return trimmed ~= '' and trimmed or text
end

local function strip_indent(text, prefix)
  local line = prefix:match '[^\n]*$' or ''
  if not line:match '^%s*$' then
    return text
  end
  return (text:gsub('^[ \t]+', ''))
end

local function parse_completion(response)
  if type(response) ~= 'table' then
    return nil
  end
  if type(response.response) == 'string' and not response.response:match '^%s*$' then
    return unfence(response.response)
  end
  if type(response.output_text) == 'string' and not response.output_text:match '^%s*$' then
    return unfence(response.output_text)
  end
  if type(response.output) == 'table' then
    local parts = {}
    for _, item in ipairs(response.output) do
      for _, content in ipairs(item.content or {}) do
        if type(content.text) == 'string' then
          parts[#parts + 1] = content.text
        end
      end
    end
    local text = table.concat(parts)
    if not text:match '^%s*$' then
      return unfence(text)
    end
  end
  if type(response.choices) ~= 'table' then
    return nil
  end
  local choice = response.choices[1]
  local message = choice and choice.message
  local content = message and message.content
  if type(content) ~= 'string' or content:match '^%s*$' then
    return nil
  end
  return unfence(content)
end

local function truncated_reason(decoded)
  if decoded.status ~= 'incomplete' then
    return nil
  end
  local reason = (decoded.incomplete_details or {}).reason
  if reason == 'max_output_tokens' then
    return 'the model spent its whole token budget before answering'
  end
  return 'the provider returned an incomplete response' .. (reason and (': ' .. reason) or '')
end

local function truncate(text, limit)
  if #text <= limit then
    return text
  end
  return text:sub(1, limit) .. string.format('\n... [%d bytes truncated]', #text - limit)
end

local function format_entry(entry)
  local lines = {
    string.format('== %s  provider=%s  model=%s  outcome=%s  %dms', entry.time, entry.provider, entry.model, entry.outcome, entry.elapsed),
    'url      ' .. entry.url,
    string.format('buffer   %s  line=%d col=%d ft=%s', entry.source, entry.row + 1, entry.character, entry.filetype),
  }
  if entry.detail then
    lines[#lines + 1] = 'detail   ' .. entry.detail
  end

  local function section(title, body)
    lines[#lines + 1] = '--- ' .. title
    vim.list_extend(lines, vim.split(truncate(body, LOG_SECTION_CHARS), '\n', { plain = true }))
  end

  section('prefix', entry.prefix)
  section('suffix', entry.suffix)
  if entry.raw then
    section('response ' .. tostring(entry.status), entry.raw)
  end
  if entry.text then
    section('insert', entry.text)
  end
  return lines
end

local function write_log(entry)
  entry.time = os.date '%Y-%m-%d %H:%M:%S'
  entry.elapsed = vim.uv.now() - entry.started
  state.log[#state.log + 1] = format_entry(entry)
  while #state.log > LOG_ENTRIES do
    table.remove(state.log, 1)
  end

  local lines = {}
  for index = #state.log, 1, -1 do
    vim.list_extend(lines, state.log[index])
    lines[#lines + 1] = ''
  end
  vim.fn.mkdir(vim.fs.dirname(LOG_FILE), 'p')
  pcall(vim.fn.writefile, lines, LOG_FILE)
end

local function new_entry(bufnr, context, url)
  local provider = active()
  local source = vim.api.nvim_buf_get_name(bufnr)
  return {
    started = vim.uv.now(),
    provider = active_name(),
    model = model_of(provider) or '-',
    url = url or '-',
    source = source ~= '' and vim.fs.basename(source) or '[no name]',
    row = context.row,
    character = context.character,
    filetype = context.filetype ~= '' and context.filetype or 'text',
    prefix = context.prefix,
    suffix = context.suffix,
  }
end

local function complete(request_id, bufnr, params, callback)
  local position = params.position or {}
  local row = tonumber(position.line)
  local character = tonumber(position.character)
  if not row or not character or row < 0 or character < 0 then
    callback(lsp_error('invalid inline completion position', -32602), nil)
    return
  end
  local context = context_for(bufnr, row, character)
  if not context then
    callback(lsp_error('invalid inline completion buffer or position', -32602), nil)
    return
  end
  local provider, reason = provider_for(bufnr)
  if not provider then
    local log = new_entry(bufnr, context)
    log.outcome = 'unavailable'
    log.detail = reason
    write_log(log)
    notify(reason, vim.log.levels.WARN, reason)
    callback(lsp_error(reason, -32001), nil)
    return
  end

  local log = new_entry(bufnr, context, provider.url)
  local body = vim.json.encode(request_body(provider, context))
  local request = {
    url = provider.url,
    headers = provider.headers,
    body = body,
    timeout_ms = provider.timeout_ms or config().timeout_ms,
  }
  for id, pending in pairs(state.requests) do
    if pending.bufnr == bufnr then
      pending.cancelled = true
      pending.cancel()
      state.requests[id] = nil
    end
  end
  local entry = { bufnr = bufnr, cancelled = false, cancel = function() end }
  state.requests[request_id] = entry
  local function finish(err, response)
    if state.requests[request_id] ~= entry then
      return
    end
    state.requests[request_id] = nil
    local function discard(outcome, detail)
      log.outcome = outcome
      log.detail = detail
      write_log(log)
      if detail and outcome ~= 'stale' then
        notify('Inline completion: ' .. detail .. '.', vim.log.levels.WARN, outcome .. detail)
      end
      callback(nil, { items = {} })
    end

    if entry.cancelled then
      discard 'cancelled'
      return
    end
    if not vim.api.nvim_buf_is_valid(bufnr) then
      discard('stale', 'buffer is no longer valid')
      return
    end
    if vim.b[bufnr].changedtick ~= context.changedtick then
      discard('stale', string.format('buffer changed (%d -> %d)', context.changedtick, vim.b[bufnr].changedtick))
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    if cursor[1] - 1 ~= context.row or cursor[2] ~= context.character then
      discard('stale', string.format('cursor moved to line=%d col=%d', cursor[1], cursor[2]))
      return
    end
    if err then
      log.outcome = 'transport-error'
      log.detail = err
      write_log(log)
      notify('Inline completion: ' .. err .. '.', vim.log.levels.WARN, 'transport-' .. err)
      callback(lsp_error(err, -32603), nil)
      return
    end

    log.status = type(response) == 'table' and response.status or 0
    log.raw = type(response) == 'table' and response.body or ''

    if log.status < 200 or log.status >= 300 then
      local reason = type(response) == 'table' and http_failure(response.status) or 'missing HTTP response'
      log.outcome = 'http-error'
      log.detail = reason
      write_log(log)
      notify('Inline completion: ' .. reason .. '.', vim.log.levels.WARN, 'http-' .. reason)
      callback(lsp_error(reason, -32603), nil)
      return
    end
    local ok, decoded = pcall(vim.json.decode, log.raw)
    if not ok then
      discard('decode-error', 'response body is not valid JSON')
      return
    end
    local choice = decoded.choices and decoded.choices[1]
    if choice and choice.finish_reason == 'content_filter' then
      discard('filtered', 'provider filtered the response')
      return
    end
    local text = parse_completion(decoded)
    if not text then
      discard('empty', truncated_reason(decoded) or 'no usable text in the response')
      return
    end
    if provider.api_format == FORMAT.FIM then
      text = trim_overrun(text, context.suffix)
    end
    text = strip_indent(text, context.prefix)
    log.outcome = 'ok'
    log.text = text
    write_log(log)
    callback(nil, {
      items = {
        {
          insertText = text,
          insertTextFormat = 1,
          range = {
            start = { line = context.row, character = context.character },
            ['end'] = { line = context.row, character = context.character },
          },
        },
      },
    })
  end
  entry.cancel = send_http(request, finish)
end

local function client_command(dispatchers)
  local closed = false
  local function close(code, signal)
    if closed then
      return
    end
    closed = true
    dispatchers.on_exit(code or 0, signal or 0)
  end
  local client = {}
  function client.request(method, params, callback)
    state.next_request_id = state.next_request_id + 1
    local id = state.next_request_id
    if method == 'initialize' then
      callback(nil, {
        capabilities = {
          inlineCompletionProvider = {},
        },
        serverInfo = { name = CLIENT_NAME },
      }, id)
    elseif method == 'shutdown' then
      callback(nil, nil, id)
    elseif method == 'textDocument/inlineCompletion' then
      local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
      complete(id, bufnr, params, callback)
    else
      callback(nil, nil, id)
    end
    return true, id
  end
  function client.notify(method, params)
    if method == '$/cancelRequest' and params and params.id then
      local request = state.requests[params.id]
      if request then
        request.cancelled = true
        request.cancel()
        state.requests[params.id] = nil
      end
    elseif method == 'exit' then
      close(0, 0)
    end
  end
  function client.is_closing()
    return closed
  end
  function client.terminate()
    close(0, 0)
  end
  return client
end

local function dismiss(bufnr)
  vim.lsp.inline_completion.enable(false, { bufnr = bufnr })
end

local function attach_mappings(bufnr)
  if vim.b[bufnr].inline_completion_mappings then
    return
  end
  vim.b[bufnr].inline_completion_mappings = true
  local group = vim.api.nvim_create_augroup('inline-completion-manual-' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'TextChangedP' }, {
    group = group,
    buffer = bufnr,
    callback = function()
      if not vim.b[bufnr].inline_completion_manual_triggering then
        vim.lsp.inline_completion.enable(false, { bufnr = bufnr })
      end
    end,
  })
  vim.keymap.set('i', '<M-l>', function()
    return vim.lsp.inline_completion.get { bufnr = bufnr }
  end, { buffer = bufnr, expr = true, desc = 'Accept inline completion' })
  vim.keymap.set('i', '<M-]>', function()
    vim.lsp.inline_completion.select { bufnr = bufnr, count = 1 }
  end, { buffer = bufnr, desc = 'Next inline completion' })
  vim.keymap.set('i', '<M-[>', function()
    vim.lsp.inline_completion.select { bufnr = bufnr, count = -1 }
  end, { buffer = bufnr, desc = 'Previous inline completion' })
  vim.keymap.set('i', '<M-d>', function()
    dismiss(bufnr)
  end, { buffer = bufnr, desc = 'Dismiss inline completion' })
end

local function start_for_buffer(bufnr)
  if not state.configured or not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= '' then
    return
  end
  local root = project_root(bufnr) or vim.fn.getcwd()
  local client_id = vim.lsp.start({
    name = CLIENT_NAME,
    cmd = client_command,
    root_dir = root,
    on_attach = function(_, attached_bufnr)
      if vim.lsp.inline_completion then
        vim.lsp.inline_completion.enable(false, { bufnr = attached_bufnr })
        attach_mappings(attached_bufnr)
      end
    end,
  }, {
    bufnr = bufnr,
    reuse_client = function(existing, new_config)
      return existing.config.root_dir == new_config.root_dir
    end,
  })
  if client_id then
    state.client_ids[root] = client_id
  end
end

local function provider_names()
  local names = vim.tbl_keys(config().providers)
  table.sort(names, function(left, right)
    local first = config().providers[left].order or math.huge
    local second = config().providers[right].order or math.huge
    if first ~= second then
      return first < second
    end
    return left < right
  end)
  return names
end

local function describe(name)
  local provider = config().providers[name]
  local marker = name == active_name() and '>' or ' '
  local detail = is_configured(provider) and model_of(provider) or 'not configured'
  return string.format('%s %-16s %s', marker, provider.label, detail)
end

local function remember(key, value)
  local preferences = read_preferences()
  if key == 'provider' then
    preferences.provider = value
  else
    preferences.models[key] = value
  end
  local ok, err = write_preferences(preferences)
  if not ok then
    announce(err, vim.log.levels.ERROR)
  end
end

function M.select_provider()
  vim.ui.select(provider_names(), {
    prompt = 'Inline completion provider',
    format_item = describe,
  }, function(name)
    if not name then
      return
    end
    config().provider = name
    remember('provider', name)
    local provider = config().providers[name]
    announce(string.format('Inline completion uses %s (%s).', provider.label, model_of(provider) or 'no model'))
  end)
end

function M.select_model()
  local name = active_name()
  local provider = config().providers[name]

  if provider.kind == KIND.AZURE then
    vim.ui.input({ prompt = 'Azure deployment: ', default = provider.model or '' }, function(value)
      if not configured(value) then
        return
      end
      provider.model = value
      remember(name, value)
      announce('Azure deployment set to ' .. value .. '.')
    end)
    return
  end

  if not configured(provider.endpoint) then
    announce(provider.label .. ' has no endpoint.', vim.log.levels.ERROR)
    return
  end

  fetch_models(provider, function(models, err)
    if not models or #models == 0 then
      announce('Could not list models: ' .. (err or 'empty response') .. '.', vim.log.levels.ERROR)
      return
    end
    vim.ui.select(models, { prompt = provider.label .. ' model' }, function(model)
      if not model then
        return
      end
      provider.model = model
      remember(name, model)
      announce(provider.label .. ' model set to ' .. model .. '.')
    end)
  end)
end

function M.approve()
  local provider = active()
  local root = project_root(0)
  if not root then
    announce('Approval needs a detectable project root.', vim.log.levels.ERROR)
    return
  end
  vim.ui.select({ 'Approve', 'Cancel' }, {
    prompt = string.format('Send code from this project to %s?', provider.label),
  }, function(choice)
    if choice ~= 'Approve' then
      return
    end
    local ok, err = write_approval(root)
    if ok then
      announce('Remote inline completion approved for ' .. root .. '.')
    else
      announce(err, vim.log.levels.ERROR)
    end
  end)
end

function M.revoke()
  local ok, err = remove_approval(project_root(0))
  if ok then
    announce 'Remote inline completion approval revoked for this project.'
  else
    announce(err, vim.log.levels.ERROR)
  end
end

function M.show_status()
  local value = M.status()
  announce(
    string.format('%s | model=%s | %s | endpoint=%s | approval=%s', value.label, value.model or 'unset', value.ready, value.endpoint or 'unset', value.approval)
  )
end

function M.show_log()
  if vim.fn.filereadable(LOG_FILE) ~= 1 then
    announce('No completions logged yet. Log path: ' .. LOG_FILE)
    return
  end
  vim.cmd.split(vim.fn.fnameescape(LOG_FILE))
  vim.bo.swapfile = false
  vim.bo.autoread = true
end

function M.log_path()
  return LOG_FILE
end

function M.menu()
  local items = {
    { label = 'Provider', run = M.select_provider },
    { label = 'Model', run = M.select_model },
    { label = 'Status', run = M.show_status },
    { label = 'Log', run = M.show_log },
    { label = 'Approve project for remote provider', run = M.approve },
    { label = 'Revoke project approval', run = M.revoke },
    {
      label = 'Reload',
      run = function()
        M.setup(config())
        announce 'Inline completion reloaded.'
      end,
    },
  }
  vim.ui.select(items, {
    prompt = 'Inline completion (' .. active().label .. ')',
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      item.run()
    end
  end)
end

local function setup_commands()
  local function command(name, callback)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, callback, {})
  end
  command('InlineCompletion', M.menu)
  command('InlineCompletionProvider', M.select_provider)
  command('InlineCompletionModel', M.select_model)
  command('InlineCompletionStatus', M.show_status)
  command('InlineCompletionLog', M.show_log)
  command('InlineCompletionApprove', M.approve)
  command('InlineCompletionRevoke', M.revoke)
  command('InlineCompletionSetup', function()
    M.setup(config())
    announce 'Inline completion setup refreshed.'
  end)
end

function M.setup(opts)
  migrate_preferences()
  state.config = normalize_config(opts or {})
  state.configured = true
  setup_commands()
  local group = vim.api.nvim_create_augroup('inline-completion', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
    group = group,
    callback = function(args)
      start_for_buffer(args.buf)
    end,
  })
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      start_for_buffer(bufnr)
    end
  end
  return M
end

function M.status(bufnr)
  local name = active_name()
  local provider = config().providers[name]
  local root = project_root(bufnr or 0)
  return {
    provider = name,
    label = provider.label,
    model = model_of(provider),
    endpoint = provider.endpoint,
    log = LOG_FILE,
    ready = is_configured(provider) and 'configured' or 'unavailable',
    approval = (root and read_approval(root)) and 'approved' or 'not-approved',
    root = root,
  }
end

function M._select_provider(bufnr)
  return provider_for(bufnr or 0)
end

function M._unfence(text)
  return unfence(text)
end

function M._strip_indent(text, prefix)
  return strip_indent(text, prefix)
end

function M._trim_overrun(text, suffix)
  return trim_overrun(text, suffix)
end

function M._approval_path(bufnr)
  return marker_path(project_root(bufnr or 0))
end

return M
