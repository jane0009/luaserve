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

if not functions then
  functions = {}
end

if not functions.string then
  functions.string = {}
end

local function table_to_string(tbl)
  local result = "{"
  for k, v in pairs(tbl) do
    -- Check the key type (ignore any numerical keys - assume its an array)
    if type(k) == "string" then
      result = result .. "[\"" .. k .. "\"]" .. "="
    end

    -- Check the value type
    if type(v) == "table" then
      result = result .. table_to_string(v)
    elseif type(v) == "boolean" then
      result = result .. tostring(v)
    else
      result = result .. "\"" .. v .. "\""
    end
    result = result .. ","
  end
  -- Remove leading commas from the result
  if result ~= "" then
    result = result:sub(1, result:len() - 1)
  end
  return result .. "}"
end

functions.string.table_to_string = table_to_string

local function stringify(...)
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
functions.string.stringify = stringify