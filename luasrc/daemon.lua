require('/src/file')
functions.file.require_lib('string')
functions.file.require_lib('logging')

if not functions then
  functions = {}
end
if not functions.daemon then
  functions.daemon = {}
end

local event_handlers = {}
event_handlers["terminate"] = function(event)
  return true
end

local function daemon_poll()
  -- todo
  local event = table.pack(os.pullEventRaw())
  -- functions.logging.debug(functions.string.table_to_string ~= nil)
  functions.logging.debug("poll " .. event[1])
  local should_terminate = false
  if event_handlers[event[1]] ~= nil then
    should_terminate = event_handlers[event[1]](event)
  else
    functions.logging.verbose("unhandled event " .. functions.string.table_to_string(event))
  end
  return should_terminate
end
functions.daemon.daemon_poll = daemon_poll
