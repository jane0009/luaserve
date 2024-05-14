require('/src/download')
functions.download.ensure_latest('/src/file.lua')
require('/src/file')

if not functions then
  functions = {}
end

if not functions.update then
  functions.update = {}
end

local index = {
  "bootstrap",
  "daemon",
  "download",
  "event",
  "file",
  "gui",
  "logging",
  "modem",
  "peripheral",
  "server",
  "settings",
  "string",
  "update"
}

local function update()
  for _, v in ipairs(index) do
    functions.download.ensure_latest('/src/' .. v .. '.lua')
  end
end
functions.update.update = update
