require('/src/file')
functions.file.require_lib('string')
functions.file.require_lib('logging')
functions.file.require_lib('event')

if not functions then
  functions = {}
end
if not functions.daemon then
  functions.daemon = {}
end

local _tid

local event_handlers = {}
event_handlers["terminate"] = function(event)
  return true
end

event_handlers["timer"] = function(event)
  local event, id = table.unpack(event)
  if id == _tid then
    -- ontick code
    functions.logging.debug("tick")
    -- schedule next tick
    _tid = os.startTimer(2)
  end
end

local function daemon_poll(tid)
  if not _tid then
    _tid = tid
  end
  -- functions.logging.debug(_tid)
  local event = table.pack(os.pullEventRaw())
  -- functions.logging.debug(functions.string.table_to_string ~= nil)
  functions.logging.debug("poll " .. event[1])
  local should_terminate = false
  if event_handlers[event[1]] ~= nil then
    should_terminate = event_handlers[event[1]](event)
  end
  functions.event.emit(event[1], event)
  return should_terminate
end
functions.daemon.daemon_poll = daemon_poll
