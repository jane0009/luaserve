require('/src/download')
functions.download.ensure_latest('/src/download.lua')
functions.download.ensure_latest('/src/string.lua')
functions.download.ensure_latest('/src/logging.lua')
require('/src/string')
require('/src/logging')

if not functions.file then
  functions.file = {}
end

local allowed_search_paths = { "/data", "/src" }

local function search_dir_for(dir, filename)
  local dirlist = fs.list(dir)
  local result = nil
  for _, v in ipairs(dirlist) do
    functions.logging.debug('checking ' .. dir .. "/" .. v)
    if fs.isDir(dir .. "/" .. v) then
      print('is dir')
      if string.find(string.lower(v), string.lower(filename)) then
        if fs.exists(dir .. "/" .. v .. "/index.lua") then
          result = dir .. "/" .. v .. "/index.lua"
          break
        elseif fs.exists(dir .. "/" .. v .. "/" .. v .. ".lua") then
          result = dir .. "/" .. v .. "/" .. v .. ".lua"
          break
        end
        functions.logging.debug('not found ' .. string.lower(v) .. ', ' .. string.lower(filename))
      else
        functions.logging.debug('searching subdirectory ' .. v)
        local sub_result = search_dir_for(dir .. "/" .. v, filename)
        if sub_result ~= nil then
          result = sub_result
          break
        end
      end
    else
      --print('not dir')
      if string.find(string.lower(v), string.lower(filename)) then
        result = dir .. "/" .. v
        break
      end
      functions.logging.debug('not found ' .. string.lower(v) .. ', ' .. string.lower(filename))
    end
  end
  functions.logging.debug('result is ' .. result)
  return result
end

local function find_path(filename)
  for _, v in ipairs(allowed_search_paths) do
    if fs.exists(v) then
      functions.logging.debug('searching ' .. v)
      local result = search_dir_for(v, filename)
      if result ~= nil then
        return result
      end
    end
  end
end
functions.file.find_path = find_path

local function recursive_ensure(path, libname)
  --print('recurse ' .. path .. ' - ' .. libname)
  functions.download.ensure_latest(path .. '/' .. libname .. ".lua")
  local list = fs.list(path)
  for _, v in ipairs(list) do
    if fs.isDir(path .. v) then
      recursive_ensure(path .. v, libname)
    end
  end
end

local loaded = {}

local function require_lib(libname)
  recursive_ensure('/src', libname)

  local match = find_path(libname)
  if match ~= nil then
    functions.logging.verbose('match ' .. match)
    local sanitized_match = match:gsub("%.lua", "")
    if not loaded[sanitized_match] then
      loaded[sanitized_match] = true
      require(sanitized_match)
    else
      functions.logging.debug('already loaded ' .. libname)
    end
  else
    functions.logging.warn('could not match ' .. libname .. ', attempting download')
    functions.download.ensure_latest('/src/' .. libname .. '.lua')
  end
end
functions.file.require_lib = require_lib
