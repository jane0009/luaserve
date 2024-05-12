require('/src/string')
if fs.exists("/src/settings.lua") then
  require('/src/settings')
end

if not functions then
  functions = {}
end

if not functions.logging then
  functions.logging = {}
end

local DEFAULT_LOG_LEVEL = "info"
local LOG_LEVEL
if not functions.settings then
  LOG_LEVEL = DEFAULT_LOG_LEVEL
else
  LOG_LEVEL = functions.settings.get("log_level", DEFAULT_LOG_LEVEL) or DEFAULT_LOG_LEVEL
end

local levels = {
  debug = { "debug", "verbose", "info", "warn", "error" },
  verbose = { "verbose", "info", "warn", "error" },
  info = { "info", "warn", "error" },
  warn = { "warn", "error" },
  error = { "error" }
}
-- local function set_log_level(level)
--   if levels[level] ~= nil then
--     LOG_LEVEL = level
--   else
--     functions.logging.warn("not a valid log level")
--   end
-- end
-- functions.logging.set_log_level = set_log_level

local function is_loggable(level)
  if levels[LOG_LEVEL] ~= nil then
    for _, v in ipairs(levels[LOG_LEVEL]) do
      if v == level then
        return true -- if the current log level is in the list of levels to log, return true
      end
    end
  end
  return false
end

local _print = print
local function print_shim(...)
  functions.logging.verbose(...)
end
print = print_shim

local function tostr(...)
  local args = { ... }
  local res = ""
  for _, v in ipairs(args) do
    if type(v) == "table" then
      res = res .. functions.string.table_to_string(v) .. " "
    else
      res = res .. tostring(v) .. " "
    end
  end
  return res
end

local function _log(level, ...)
  local file = io.open("/run.log", "a")
  local txt = tostr(...)
  local info = debug.getinfo(3)
  local src = info.short_src .. ":" .. info.currentline
  local msg = "[" .. level .. "] " .. "(" .. src .. ") " .. txt
  if file ~= nil then
    file:write(msg .. "\n")
    file:close()
  end
  _print(msg)
end

local function generate_log_level(level)
  return function(...)
    if is_loggable(level) then
      _log(level, ...)
    end
  end
end

functions.logging.debug = generate_log_level('debug')
functions.logging.verbose = generate_log_level('verbose')
functions.logging.info = generate_log_level('info')
functions.logging.warn = generate_log_level('warn')
functions.logging.error = generate_log_level('error')
