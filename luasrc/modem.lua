require('/src/file')
functions.file.require_lib('logging')
functions.file.require_lib('settings')
functions.file.require_lib('event')

local modem = peripheral.find('modem')
if modem == nil then
  functions.logging.error("no modem found")
  return
end

local broadcast_channel = functions.settings.get('broadcast_channel', 1) or 1

modem.open(broadcast_channel)

if not functions.modem then
  functions.modem = {}
end

local wait_time = 5
local messages = {}

local function ev_handler(data)
  local event, side, channel, reply_channel, message, distance = table.unpack(data)
  functions.modem.receive_message(event, side, channel, reply_channel, message, distance)
end
functions.event.sub("modem_message", ev_handler)

local function receive_message(event, side, channel, reply_channel, message, distance)
  if not messages[channel] then
    messages[channel] = {}
  end
  messages[channel][#messages[channel]] = {
    event = event,
    side = side,
    reply_channel = reply_channel,
    message = message,
    distance = distance
  }
end
functions.modem.receive_message = receive_message

local function pull_message(channel)
  local count = 0
  if messages[channel] == nil then
    messages[channel] = {}
  end
  while messages[channel][1] == nil and count <= wait_time do os.sleep(1) end
  if messages[channel][1] == nil then
    return "timed out"
  else
    return messages[channel][1]
  end
end
functions.modem.pull_message = pull_message

local function broadcast(message, response_channel)
  local ch = response_channel ~= nil and response_channel or broadcast_channel

  modem.open(ch)
  modem.transmit(broadcast_channel, ch, message)
  local response = pull_message(ch)
  if response ~= "timed out" then
    return response
  else
    functions.logging.warn("no reply in " .. wait_time .. " seconds")
    return nil
  end
end
functions.modem.broadcast = broadcast

local function negotiate_channel(label)
  return functions.modem.broadcast("NEG " .. label)
end
functions.modem.negotiate_channel = negotiate_channel

-- todo heartbeats
-- sub to tick
-- pull list of clients from settings?
-- based on computer label
-- each other client maintains a list of active peers
