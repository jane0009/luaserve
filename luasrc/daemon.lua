require('/src/file')
functions.file.require_lib('settings')
functions.file.require_lib('string')
functions.file.require_lib('logging')
functions.file.require_lib('event')
functions.file.require_lib('gui')

if not functions then
  functions = {}
end
if not functions.daemon then
  functions.daemon = {}
end

local tick_time = functions.settings.get("tick_time", 1)

local _tid
local ticks = 0

local event_handlers = {}
event_handlers["terminate"] = function(event)
  functions.gui.clear()
  return {
    terminate = true
  }
end

event_handlers["timer"] = function(event)
  local event, id = table.unpack(event)
  if id == _tid then
    -- ontick code
    ticks = ticks + 1
    functions.logging.debug("tick " .. ticks)
    functions.event.emit("tick", ticks)
    -- schedule next tick
    _tid = os.startTimer(tick_time)
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
    local result = event_handlers[event[1]](event)
    if result ~= nil and result.terminate == true then
      should_terminate = true
    end
  end
  functions.event.emit(event[1], event)
  if functions.gui.active then
    functions.gui.gui_tick(ticks)
  end
  return should_terminate
end
functions.daemon.daemon_poll = daemon_poll
