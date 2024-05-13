if not functions then
  functions = {}
end
if not functions.peripheral then
  functions.peripheral = {}
end

-- todo keep track of all active peripherals
-- handle finding peripherals
-- allow for targeting by certain attributes
-- interface with event emitter

local function conditional_execute(name, fn)
  local match = peripheral.find(name)
  if match ~= nil then
    fn(match)
  end
end
functions.peripheral.conditional_execute = conditional_execute
