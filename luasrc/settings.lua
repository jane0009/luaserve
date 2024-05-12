if not functions then
  functions = {}
end

if not functions.settings then
  functions.settings = {}
end

local log = {}
local function g(l)
  return function(...)
    if functions.logging ~= nil and functions.logging[l] ~= nil then
      functions.logging[l](...)
    else
      print(...)
    end
  end
end
log.debug = g("debug")
log.verbose = g("verbose")
log.info = g("info")
log.warn = g("warn")
log.error = g("error")

local jsettings = {}

local set_default = function(setting, default)
  log.verbose("setting default for " .. setting .. " to " .. default)
  log.verbose("jsettings is " .. textutils.serializeJSON(jsettings))
  if default ~= nil then
    functions.settings.set(setting, default)
  end
end

local get_setting = function(setting, default)
  log.debug("get_setting " .. setting)
  default = default or nil
  log.debug(jsettings[setting])
  if jsettings[setting] == nil then
    log.debug("setting is nil")
    -- check if the file has it, first
    local file = io.open("/.settings", "r")
    if file == nil then
      set_default(setting, default)
      return default
    end
    local text = file:read("a")
    if text == nil then
      file:close()
      set_default(setting, default)
      return default
    end
    local decoded = textutils.unserialize(text)
    if decoded == nil or type(decoded) ~= "table" then
      file:close()
      set_default(setting, default)
      return default
    end
    jsettings = decoded
    file:close()
  end
  -- if it's still not there, we default
    if jsettings[setting] == nil then
      set_default(setting, default)
    end
  return jsettings[setting] or default
end

functions.settings.get = get_setting

local set_setting = function(setting, value)
  log.verbose("setting " .. setting .. " to " .. value)
  jsettings[setting] = value
  log.verbose(jsettings)
  local file = io.open("/.settings", "w")
  file:write(textutils.serialize(jsettings, { compact = false}))
  file:close()
end

functions.settings.set = set_setting