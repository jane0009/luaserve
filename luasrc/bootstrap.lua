if not functions then
  functions = {}
end

if not data then
  data = {}
end

--
require('/src/download')
functions.download.ensure_latest('/src/settings.lua')
functions.download.ensure_latest('/src/bootstrap.lua')
functions.download.ensure_latest('/src/file.lua')
functions.download.ensure_latest('/src/daemon.lua')
require('/src/file')
functions.file.require_lib('logging')
functions.file.require_lib('settings')
functions.file.require_lib('string')
functions.file.require_lib('download')
functions.file.require_lib('daemon')
functions.file.require_lib('update')

functions.update.update() -- ensure all files are up to date

if not fs.exists("/startup") then
  local file = io.open("/startup", "w")
  if file ~= nil then
    file:write("shell.run(\"src/bootstrap.lua\")")
    file:close()
  end
end

-- take control from craftos

functions.logging.verbose('debug')

local killsig = false
local tick = os.startTimer(2)
repeat
  killsig = functions.daemon.daemon_poll(tick)
until (killsig == true)
