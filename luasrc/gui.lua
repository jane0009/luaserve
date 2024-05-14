if not functions.file then
  require('/src/file')
end
functions.file.require_lib('table')
functions.file.require_lib('settings')

if not functions then
  functions = {}
end

if not functions.gui then
  functions.gui = {}
end

functions.gui.active = functions.settings.get('gui.active', true)
functions.gui.prefer_monitor = functions.settings.get('gui.prefer_monitor', true)
functions.gui.log_if_has_monitor = functions.settings.get('gui.log_if_has_monitor', true)
functions.gui.mobile_computer = functions.settings.get('gui.mobile_computer', false)

if functions.gui.mobile_computer then
  -- cannot use monitors on mobile computers
  functions.logging.verbose('Mobile computer detected, disabling monitor use')
  functions.gui.prefer_monitor = false
  functions.gui.log_if_has_monitor = false
end

functions.gui.partial_updates = functions.settings.get('gui.partial_updates', false) -- disabled by default for now

-- todo handle monitors,
-- implement frame buffer api
-- implement colored pixels

-- frames are continuous (do not care about x,y)
local current_frame = {}
local buffered_frame = {}

local current_tick = 0

local function frame_tick(tick)
  buffered_frame = {}
  -- insert `tick` as characters into `buffered_frame`
  local tstr = tostring(tick) .. " " .. tostring(functions.gui.partial_updates)
  for i = 1, string.len(tstr) do
    table.insert(buffered_frame, string.sub(tstr, i, i))
  end
end

local function get_xy(idx)
  local w, h = term.getSize()
  local x = (idx - 1) % w + 1
  local y = math.floor((idx - 1) / w) + 1
  return x, y
end

local function gui_tick(tick)
  -- no sense re-rendering on the same tick
  if current_tick == tick then
    return
  end
  current_tick = tick
  frame_tick(tick)
  if functions.gui.partial_updates then
    local diff = functions.table.get_differing_indexes(current_frame, buffered_frame)
    if diff ~= nil and #diff > 0 then
      for i = 1, table.maxn(diff) do
        local idx = diff[i]
        local x, y = get_xy(idx)
        term.setCursorPos(x, y)
        term.write(buffered_frame[idx])
      end
      current_frame = buffered_frame
    end
  else
    term.clear()
    term.setCursorPos(1, 1)
    for i = 1, table.maxn(buffered_frame) do
      term.write(buffered_frame[i])
    end
  end
end
functions.gui.gui_tick = gui_tick

local function clear()
  term.clear()
  term.setCursorPos(1, 1)
end
functions.gui.clear = clear

-- [ DEPRECATED ]
-- todo rewrite

-- button api, modified to work with luaserve
-- and also to expand on its functionality
-- ORIGINAL COMMENT:

--Original DireWolf20's Button API modified to include better customization and integration + simple usage explanation.
--[[TL;DR:
assuming you've saved the api as 'button' usage is as follows:

button.create("Text to write on The Button", FunctionToCallOnClick, xLeft, xRight, yTop, yBot, ColorPressed, ColorUnpressed, TextColor)
^Creates a new button on the monitor/screen.

button.clear(nameString)
^Clears a button specified by 'name'.

button.clearAll()
^Wipes all buttons currently on screen. Useful for new menus/screens.

button.update()
^Updates screen with new button data (new buttons, button state(on/off), etc.)
^Generally to be called after any button.* function.
--]]

if not functions.gui.button then
  functions.gui.button = {}
end

-- todo use peripheral wrapper
local mon = peripheral.find("monitor")
if not mon then
  return -- no monitor, no api
end
mon.setTextScale(1)
mon.setTextColor(colors.white)
mon.setBackgroundColor(colors.black)
local menu = {}

if not functions.gui.button._button then
   functions.gui.button._button = {}
end

local button = functions.gui.button._button

--[[
function exportMenus(fileName)
   local h = fs.open(fileName,"w")
   local wrt = textutils.serialize(menu)
   h.writeLine(menu)
   h.close()
end

function importMenus(fileName)
   if fs.exists(fileName) then
      local h = fs.open(fileName,"r")
	  local inp = textutils.unserialize(h.readLine())
	  table.insert(menu,inp)
	  return true
   else
      return false
   end
end

function createMenu(mName, buttons)
   menu[mName] = {}
   for bName=#buttons,1,-1 do
      if buttons[bName] ~= nil then
	     table.insert(menu[mName],button[bName])
	  end
   end
end

function deleteMenu(mName)
   table.remove(menu,mName)
end
--]]

local function create(name, func, xmin, xmax, ymin, ymax, oncol, offcol, textcol)
   button[name] = {}
   button[name]["func"] = func
   button[name]["active"] = false
   button[name]["xmin"] = xmin
   button[name]["ymin"] = ymin
   button[name]["xmax"] = xmax
   button[name]["ymax"] = ymax
   button[name]["oncol"] = oncol
   button[name]["offcol"] = offcol
   button[name]["textcol"] = textcol
end
functions.gui.button.create = create

local function buttonClear(name)
   table.remove(button, name)
end
functions.gui.button.clear = buttonClear

local function clearAll()
   button = {}
end
functions.gui.button.clearAll = clearAll

--[[
function funcName()
   print("You clicked buttonText")
end

function addButton()
   setTable("ButtonText", funcName, 5, 25, 4, 8, colors.lime, colors.red, colors.white)
end
--]]

local function render(text, color, bData)
   mon.setBackgroundColor(color)
   local yspot = math.floor((bData["ymin"] + bData["ymax"]) / 2)
   local xspot = math.floor((bData["xmax"] - bData["xmin"] - string.len(text)) / 2) + 1
   for j = bData["ymin"], bData["ymax"] do
      mon.setCursorPos(bData["xmin"], j)
      if j == yspot then
         for k = 0, bData["xmax"] - bData["xmin"] - string.len(text) + 1 do
            if k == xspot then
               mon.write(text)
            else
               mon.write(" ")
            end
         end
      else
         for i = bData["xmin"], bData["xmax"] do
            mon.write(" ")
         end
      end
   end
   mon.setBackgroundColor(colors.black)
end
functions.gui.button.render = render

local function update()
   local currColor
   for name, data in pairs(button) do
      local on = data["active"]
      if on == true then currColor = data["oncol"] else currColor = data["offcol"] end
      render(name, currColor, data)
   end
end
functions.gui.button.update = update

local function toggle(name)
   button[name]["active"] = not button[name]["active"]
   update()
end
functions.gui.button.toggle = toggle

local function flash(name)
   toggle(name)
   os.sleep(0.15)
   toggle(name)
end
functions.gui.button.flash = flash

local function checkxy(x, y)
   for name, data in pairs(button) do
      if y >= data["ymin"] and y <= data["ymax"] then
         if x >= data["xmin"] and x <= data["xmax"] then
            if data["func"] ~= nil then data["func"]() end
            return name
            --data["active"] = not data["active"]
            --print(name)
         end
      end
   end
   return false
end
functions.gui.button.check = checkxy

--Button Functions go here
