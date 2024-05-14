require('/src/file')
functions.file.require_lib('string') -- for string functions
functions.file.require_lib('logging')
functions.file.require_lib('settings')
functions.file.require_lib('event')

local modem = peripheral.find('modem')
if modem == nil then
  functions.logging.error("no modem found")
  return
end

local broadcast_channel = functions.settings.get("broadcast_channel", 1)

if not modem.isOpen(broadcast_channel) then
  functions.logging.debug("opening broadcast channel")
  modem.open(broadcast_channel)
else
  functions.logging.debug("broadcast channel already open")
end

if not functions.modem then
  functions.modem = {}
end

local wait_time = functions.settings.get("modem_timeout", 5)
local messages = {}

-- message formats
local formats = {}
-- syn-ack-ack
formats["negotiate"] = function(target, label, preferred_channel)
  if preferred_channel ~= nil then 
    preferred_channel = tostring(preferred_channel)
  else
    preferred_channel = "none"
  end
  return "SYN-" .. target .. "-" .. label .. "-" .. preferred_channel
end
-- the client should NOT rely on getting this response
-- if the computer does not exist or is not listening,
-- it should time out instead.
formats["negotiate_drop"] = function(targeter, label)
  return "DRP-" .. targeter .. "-" .. label
end
formats["negotiate_acknowledge"] = function(targeter, label, channel)
  return "ACK-" .. targeter .. "-" .. label .. "-" .. channel
end

-- message encode special characters
local subs = {
  {"-", "%MIN%"},
  {":", "%COL%"},
  {",", "%COM%"},
  {" ", "%SPC%"},
  {"%", "%PRC%"},
  {"!", "%EXC%"},
  {"@", "%ATT%"},
  {"#", "%HSH%"},
  {"$", "%DOL%"},
  {"^", "%CRT%"},
  {"&", "%AMP%"},
  {"*", "%STR%"},
  {"(", "%OPR%"},
  {")", "%CPR%"},
  {"_", "%UND%"},
  {"+", "%PLS%"},
  {"=", "%EQL%"},
  {"{", "%OBR%"},
  {"}", "%CBR%"},
  {"[", "%OSB%"},
  {"]", "%CSB%"},
  {"|", "%PIP%"},
  {";", "%SEM%"},
  {"'", "%SQT%"},
  {'"', "%DQT%"},
  {"<", "%LTT%"},
  {">", "%GTT%"},
  {"/", "%FSH%"},
  {"\\", "%BSH%"},
  {"?", "%QST%"},
  {"~", "%TLD%"},
  {"`", "%GRV%"},
  {"\n", "%NWL%"},
  {"\t", "%TAB%"},
  {"\r", "%RTN%"},
  {"\v", "%VTL%"},
  {"\f", "%FFD%"},
  {"\a", "%BEL%"},
  {"\b", "%BKS%"},
  {"\0", "%NUL%"},
}
formats["generic_message"] = function(target, sender, message)
  local sanitized_message_content = message
  for _, sub in ipairs(subs) do
    sanitized_message_content = string:gsub(sanitized_message_content, sub[1], sub[2])
  end
  return "MSG-" .. target .. "-" .. sender .. "-" .. message
end

-- todo move this to a system where any file can interface with the modem api and
-- specify a new protocol, which has a formatter, a matcher and a parser

-- EVENTS

local function ev_handler(data)
  local event, side, channel, reply_channel, message, distance = table.unpack(data)
  functions.modem.handle_modem_event(event, side, channel, reply_channel, message, distance)
end
functions.event.sub("modem_message", ev_handler)

local function tick_handler(tick)

end
functions.event.sub("tick", tick_handler)

local function handle_modem_event(event, side, channel, reply_channel, message, distance)
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
functions.modem.handle_modem_event = handle_modem_event

local function get_channel_backlog(channel)
  if messages[channel] == nil then
    return nil
  end
  return messages[channel]
end
functions.modem.get_channel_backlog = get_channel_backlog

local function await_message(channel)
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
functions.modem.await_message = await_message

local function send_message(message, channel, reply_channel, await_response)
  reply_channel = reply_channel or channel
  await_response = await_response or false
  if not modem.isOpen(channel) then
    modem.open(channel)
  end
  modem.transmit(channel, reply_channel, message)
  if await_response then
    return await_message(reply_channel)
  end
  return nil
end
functions.modem.send_message = send_message

local function broadcast(message, response_channel)
  local ch = response_channel ~= nil and response_channel or broadcast_channel

  if not modem.isOpen(ch) then
    modem.open(ch)
  end
  modem.transmit(broadcast_channel, ch, message)
  -- local response = pull_message(ch)
  -- if response ~= "timed out" then
  --   return response
  -- else
  --   functions.logging.warn("no reply in " .. wait_time .. " seconds")
  --   return nil
  -- end
end
functions.modem.broadcast = broadcast

local function negotiate_channel(label)
  return functions.modem.broadcast("NEG " .. label)
end
functions.modem.negotiate_channel = negotiate_channel

-- todo
local function format_message() end
local function parse_message() end

-- todo heartbeats
-- sub to tick
-- pull list of clients from settings?
-- based on computer label
-- each other client maintains a list of active peers
-- look at rednet/cryptoNet for inspiration