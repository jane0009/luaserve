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

local mon = peripheral.wrap("top")
mon.setTextScale(1)
mon.setTextColor(colors.white)
mon.setBackgroundColor(colors.black)
button={}
local menu={}

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

function create(name, func, xmin, xmax, ymin, ymax, oncol, offcol, textcol)
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

function clear(name)
   table.remove(button, name)
end

function clearAll()
   button = {}
end

--[[
function funcName()
   print("You clicked buttonText")
end
        
function addButton()
   setTable("ButtonText", funcName, 5, 25, 4, 8, colors.lime, colors.red, colors.white)
end  
--]]   

function render(text, color, bData)
   mon.setBackgroundColor(color)
   local yspot = math.floor((bData["ymin"] + bData["ymax"]) /2)
   local xspot = math.floor((bData["xmax"] - bData["xmin"] - string.len(text)) /2) +1
   for j = bData["ymin"], bData["ymax"] do
      mon.setCursorPos(bData["xmin"], j)
      if j == yspot then
         for k = 0, bData["xmax"] - bData["xmin"] - string.len(text) +1 do
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
     
function update()
   local currColor
   for name,data in pairs(button) do
      local on = data["active"]
      if on == true then currColor = data["oncol"] else currColor = data["offcol"] end
      render(name, currColor, data)
   end
end

function toggle(name)
   button[name]["active"] = not button[name]["active"]
   update()
end     

function flash(name)
   toggle(name)
   sleep(0.15)
   toggle(name)
end

function checkxy(x, y)
   for name, data in pairs(button) do
      if y>=data["ymin"] and  y <= data["ymax"] then
         if x>=data["xmin"] and x<= data["xmax"] then
            if data["func"] ~= nil then data["func"]() end
            return name
            --data["active"] = not data["active"]
            --print(name)
         end
      end
   end
   return false
end

--Button Functions go here