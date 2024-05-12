if not functions then
  functions = {}
end
if not functions.peripheral then
  functions.peripheral = {}
end

local function conditional_execute(name, fn)
  local match = peripheral.find(name)
  if match ~= nil then
    fn(match)
  end
end
functions.peripheral.conditional_execute = conditional_execute
