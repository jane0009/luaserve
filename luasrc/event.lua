if not functions then
  functions = {}
end

if not functions.event then
  functions.event = {}
end

local subscribers = {}

local function subscribe(event, callback)
  if subscribers[event] == nil then
    subscribers[event] = {}
  end
  local idx = #subscribers[event] + 1
  subscribers[event][idx] = callback
  return idx
end
functions.event.sub = subscribe

local function unsubscribe(event, idx)
  if subscribers[event] == nil then
    return
  end
  subscribers[event][idx] = nil
end
functions.event.unsub = unsubscribe

local function emit(event, ...)
  if subscribers[event] == nil then
    return
  end
  for _, callback in ipairs(subscribers[event]) do
    callback(...)
  end
end
functions.event.emit = emit