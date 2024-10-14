require('/src/string')
require('/src/encrypt/md5')
if fs.exists("/src/settings.lua") then
  require('/src/settings')
end
local api_path
if functions.settings ~= nil then
  api_path = functions.settings.get("api_path", "http://lua.j4.pm/")
else
  api_path = "https://lua.j4.pm/"
end

if not functions then
  functions = {}
end
if not functions.download then
  functions.download = {}
end

local log
if fs.exists("/src/logging.lua") then
  require('/src/logging')
end
if not functions.logging then
  log = {}
  log.debug = print
  log.verbose = print
  log.info = print
  log.warn = print
  log.error = print
else
  log = functions.logging
end

local function ensure_dirs(filepath)
  local split = filepath:split("/", true)
  local cur_path = ""
  local limit = table.maxn(split)
  for k, v in pairs(split) do
    cur_path = cur_path .. "/" .. v
    --print(cur_path)
    if k < limit and not fs.exists(cur_path) then
      fs.makeDir(cur_path)
    end
  end
end

functions.download.ensure_dirs = ensure_dirs

local function download_file(filepath, dir_override)
  local request = http.get(api_path .. filepath)
  if request ~= nil then
    local code = request.getResponseCode()
    local filetext = request.readAll()
    request.close()
    if code ~= 200 then
      log.error("response code is " .. code)
      return
    end
    local path = dir_override ~= nil and dir_override or filepath
    functions.download.ensure_dirs("/" .. path)
    local file = io.open("/" .. path, "w")
    if file ~= nil then
      file:write(filetext)
      file:close()
    else
      log.error('could not open file')
    end
  else
    log.error('nil response for ' .. filepath)
  end
end

functions.download.download_file = download_file

local check_time
-- 5 minutes
if functions.settings ~= nil then
  check_time = functions.settings.get("check_time", 300)
else
  check_time = 300
end

local function write_version(sanitized_filepath)
  local file = io.open("/src/" .. sanitized_filepath .. ".lc", "w")
  file:write(os.clock())
  file:close()
end

local function version_check(sanitized_filepath)
  local time = os.clock() -- we are "".
  if not fs.exists("/src/" .. sanitized_filepath .. ".lc") then
    write_version(sanitized_filepath)
    return true
  end
  local file = io.open("/src/" .. sanitized_filepath .. ".lc", "r")
  if file == nil then
    write_version(sanitized_filepath)
    return true
  end
  local text = file:read("a")
  file:close()
  -- parse into number
  local last_check = tonumber(text)
  -- the 'or 0' may not work the intended way
  if last_check == nil then last_check = 0 end
  log.debug(time .. " - " .. last_check .. " = " .. time - last_check)
  -- the computer must have restarted
  if last_check > time then
    log.verbose("last check was in the future, resetting")
    write_version(sanitized_filepath)
    return true
  end
  if time - last_check > check_time then
    write_version(sanitized_filepath)
    return true
  end
  return false
end

local function versioned_download(sanitized_filepath, versions, dir_override)
  log.verbose("downloading new version of " .. sanitized_filepath)
  download_file("/src/" .. sanitized_filepath, dir_override)
  local vf = io.open("/src/" .. sanitized_filepath .. ".vs", "w")
  vf:write(versions[sanitized_filepath])
  vf:close()
end

local function ensure_latest(filepath)
  local sanitized_filepath = filepath:gsub("%/src%/", "")
  local vc = version_check(sanitized_filepath)
  if not vc then
    log.verbose("skipping version check, as it was performed recently")
    return
  end
  log.verbose('ensure_latest ' .. filepath)
  if not fs.exists(filepath) then
    log.verbose("file does not exist, downloading")
    download_file(filepath)
    return
  end

  -- get the latest version file
  if fs.exists("/src/.versions") then
    fs.delete("/src/.versions")
  end
  download_file("/version")             -- download the global version table
  fs.move("/version", "/src/.versions") -- move it to the correct location
  -- open and parse
  local file = io.open("/src/.versions", "r")
  if file == nil then
    download_file("/version")
    fs.move("/version", "/src/.versions")
    return
  end
  local text = file:read("a")
  file:close()
  local versions = textutils.unserializeJSON(text)

  -- check if we have a local version file
  log.debug("sanitized_filepath: " .. sanitized_filepath)
  --[[
  
  if not fs.exists("/src/" .. sanitized_filepath .. ".vs") then
    log.info("no version file found for " .. sanitized_filepath .. ", downloading")
    versioned_download(sanitized_filepath, versions)
    return
  end

  -- open and parse
  local vf = io.open("/src/" .. sanitized_filepath .. ".vs", "r")
  if vf == nil then
    log.info("no version file found for " .. sanitized_filepath .. ", downloading")
    versioned_download(sanitized_filepath, versions)
    return
  end

  local current_version = tonumber(vf:read("a"))
  vf:close()

  --]]

  local current_verison
  if fs.exists(sanitized_filepath) then
    local file = io.open(sanitized_filepath, "r")
    local content = file:read("a")
    current_version = functions.md5.sumhexa(content)
  end

  if versions[sanitized_filepath] == nil or current_version == nil then
    log.info("no version found for " .. sanitized_filepath .. ", downloading")
    versioned_download(sanitized_filepath, versions)
  elseif versions[sanitized_filepath] ~= current_version then
    log.info(sanitized_filepath .. " is different, downloading")
    log.debug("ver:" .. versions[sanitized_filepath] .. " - cur:" .. current_version)
    versioned_download(sanitized_filepath, versions)
  end
end

functions.download.ensure_latest = ensure_latest
