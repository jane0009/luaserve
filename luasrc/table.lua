if not functions then
  functions = {}
end

if not functions.table then
  functions.table = {}
end

--[[
  returns true if the tables are the same, false otherwise
]]
local function compare_table(t1, t2)
  local diff = functions.table.get_differing_indexes(t1, t2)
  if diff == nil or #diff == 0 then
    return true
  end
  return false
end
functions.table.compare_table = compare_table

--[[
  returns a table of indexes that are different between t1 and t2
]]
local function get_differing_indexes(t1, t2)
  local diff = {}
  for k, v in pairs(t1) do
    if t2[k] == nil or (type(v) ~= "table" and t2[k] ~= v) then
      table.insert(diff, k)
    elseif type(v) == table then
      local sub_diff = functions.table.get_differing_indexes(v, t2[k])
      if sub_diff ~= nil and #sub_diff > 0 then
        diff.insert(k) -- we don't care about the sub_diff, just that there is a difference
      end
    end
  end
  for k, v in pairs(t2) do
    if t1[k] == nil or (type(v) ~= "table" and t1[k] ~= v) then
      table.insert(diff, k)
    elseif type(v) == table then
      local sub_diff = functions.table.get_differing_indexes(t1[k], v)
      if sub_diff ~= nil and #sub_diff > 0 then
        diff.insert(k)
      end
    end
  end
  return diff
end
functions.table.get_differing_indexes = get_differing_indexes