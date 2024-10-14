local api_path = "https://lua.j4.pm/"

functions = {}
functions.download = {}

local function ensure_dirs(filepath)
  local split = filepath:split("/", true)
  local cur_path = "" 
  local limit = table.maxn(split)
  for k, v in pairs(split) do
    cur_path = cur_path .. "/" .. v
    print(cur_path)
    if k < limit and not fs.exists(cur_path) then
      fs.makeDir(cur_path)
    end
  end
end

functions.download.ensure_dirs = ensure_dirs

local function download_file(filepath)
  local request = http.get(api_path .. filepath)
  local filetext = request.readAll()
  request.close()
  functions.download.ensure_dirs(filepath)
  local file = io.open(filepath, "w")
  file:write(filetext)
  file:close()
end

functions.download.download_file = download_file

local unpack = table.unpack or unpack

-- https://stackoverflow.com/a/36958689

--------------------------------------------------------------------------------
-- Escape special pattern characters in string to be treated as simple characters
--------------------------------------------------------------------------------

local function escape_magic(s)
  local MAGIC_CHARS_SET = '[()%%.[^$%]*+%-?]'
  if s == nil then return end
  return (s:gsub(MAGIC_CHARS_SET,'%%%1'))
end

--------------------------------------------------------------------------------
-- Returns an iterator to split a string on the given delimiter (comma by default)
--------------------------------------------------------------------------------

function string:gsplit(delimiter)
  delimiter = delimiter or ','          --default delimiter is comma
  if self:sub(-#delimiter) ~= delimiter then self = self .. delimiter end
  return self:gmatch('(.-)'..escape_magic(delimiter))
end

--------------------------------------------------------------------------------
-- Split a string on the given delimiter (comma by default)
--------------------------------------------------------------------------------

function string:split(delimiter,tabled)
  tabled = tabled or false              --default is unpacked
  local ans = {}
  for item in self:gsplit(delimiter) do
    ans[ #ans+1 ] = item
  end
  if tabled then return ans end
  return unpack(ans)
end

-- actual code

-- minimal fileset to bootstrap and download files
if not fs.exists('/src/string.lua') then
  functions.download.download_file("src/string.lua")
end
if not fs.exists('/src/file.lua') then
  functions.download.download_file("src/file.lua")
end
if not fs.exists('/src/encrypt/md5.lua') then
  functions.download.download_file("src/encrypt/md5.lua")
end
if not fs.exists('/src/download.lua') then
  functions.download.download_file("src/download.lua")
end
if not fs.exists('/src/bootstrap.lua') then
  functions.download.download_file("src/bootstrap.lua")
end

shell.run('src/bootstrap.lua')