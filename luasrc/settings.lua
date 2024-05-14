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

-- i did this originally to prevent a json error which
-- was likely not even caused by this being named settings,
-- but i'm too lazy to turn it back
local jsettings = {}

local helpers = {}

local get_val = function(table, key)
  -- get the first "." character
  local split = string.find(key, "%.")
  if split == nil then
    if table[key] == "true" then
      return true
    elseif table[key] == "false" then
      return false
    end
    return table[key]
  end
  local first = string.sub(key, 1, split - 1)
  local rest = string.sub(key, split + 1)
  if table[first] == nil then
    return nil
  end
  if type(table[first]) ~= "table" then
    log.warn("tried to get a tabled value on a non-table key: " .. key)
    return table[first]
  end
  return helpers.get_val(table[first], rest)
end
helpers.get_val = get_val

local set_val = function(table, key, value)
  local split = string.find(key, "%.")
  if split == nil then
    if type(value) == "boolean" then
      value = value and "true" or "false"
    end
    table[key] = value
    return
  end
  local first = string.sub(key, 1, split - 1)
  local rest = string.sub(key, split + 1)
  if table[first] == nil then
    table[first] = {}
  end
  if type(table[first]) ~= "table" then
    log.warn("tried to set a tabled value on a non-table key: " .. key)
    return
  end
  helpers.set_val(table[first], rest, value)
end
helpers.set_val = set_val
local set_default = function(setting, default)
  log.verbose("setting default for " .. setting .. " to " .. functions.string.stringify(default))
  log.debug("jsettings is " .. textutils.serializeJSON(jsettings))
  if default ~= nil then
    functions.settings.set(setting, default)
  end
end

local get_setting = function(setting, default)
  log.debug("get_setting " .. setting)
  default = default or nil
  log.debug(jsettings[setting])
  local exists = helpers.get_val(jsettings, setting)
  if exists == nil then
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
  exists = helpers.get_val(jsettings, setting)
  if exists == nil then
    set_default(setting, default)
  end
  if jsettings[setting] ~= nil then
    return jsettings[setting]
  else
    return default
  end
end

functions.settings.get = get_setting

local set_setting = function(setting, value)
  log.verbose("setting " .. setting .. " to " .. functions.string.stringify(value))
  helpers.set_val(jsettings, setting, value)
  log.debug(jsettings)
  local file = io.open("/.settings", "w")
  file:write(textutils.serialize(jsettings, { compact = false}))
  file:close()
end

functions.settings.set = set_setting