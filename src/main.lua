screen_width, screen_height = love.window.getMode()
require("libs.utf8-l")
__ = require("libs.underscore")
__.extend(math,require("libs.mlib"))
Misc = require("libs.misc_functions")
newButton = require("ui.button")
timer = require("timer")
event = require("libs.event")
menu = require("menu")
img = require("image")

supported_filetypes = {"jpg","png"}
base_path = ""
directory_index = 1
directory = {}
sort_method = "ABC"

function msgbox(title,message,buttons)
  title = title or ""
  message = message or ""
  buttons = buttons or {"OK", enterbutton=1, escapebutton=1}
  return love.window.showMessageBox(title, message, buttons)
end
--

function sort_directory(method)
  method = (method or "alphabetical"):lower()
  local sorting = {
    alphabetical = function()
      sort_method = "ABC"
      table.sort(directory)
    end,
    random = function()
      sort_method = "Random"
      for o = #directory, 2, -1 do
        local t = math.random(1, o)
        directory[o], directory[t] = directory[t], directory[o]
      end
    end,
  }
  setmetatable(sorting, {__index = function() return sorting.alphabetical end})
  sorting[method]()
  directory_index = 0
  menu.next()
end
--

function love.load()
  math.randomseed(os.time())
  --[[
  if love.filesystem.getInfo("peeper_config") then
    local config = love.filesystem.read("peeper_config")
    config = config:gsub("borderless=%w+","borderless=false"):gsub("fullscreen=%w+","fullscreen=false")
    assert(loadstring(config))()
  end
  --]]
  screen_width, screen_height = love.window.getMode()
  base_screen_height, base_screen_width = screen_width, screen_height

  menu.toggle()
  love.keyboard.setKeyRepeat(true)
end
--

function love.update(dt)
  dt = math.min(dt, 0.07)
  img.update(dt)
  menu.update(dt)
  timer.update(dt)
end
--
local font = love.graphics.newFont("font.otf",24)
function love.draw()
  love.graphics.setFont(font)
  if not next(directory) then
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Drag and drop an image or folder here to start.", 0, screen_height/2-love.graphics.getFont():getHeight(), screen_width, "center")
  end
  img.draw()
  timer.draw()
  menu.draw()
end
--

function love.keypressed(key)
  if love.keyboard.isDown("lalt") and key=="return" then
    love.window.setFullscreen(not love.window.getFullscreen())
    return
  end
  menu.keypressed(key)
end
--

function love.textinput(text)
  menu.textinput(text)
end
--

function love.mousepressed(x,y,b,t)
  menu.mousepressed(x,y,b,t)
end
--
function love.mousereleased(x,y,b,t)
  menu.mousereleased(x,y,b,t)
end
--
function love.mousemoved(x,y,dx,dy)
  img.mousemoved(x,y,dx,dy)
end
--
function love.wheelmoved(x,y)
  img.wheelmoved(x,y)
end
--

function love.resize(w,h)
  screen_width, screen_height = w, h
  event.grant("resized")
end
--
function love.filedropped(file)
  print("Loading in dropped file "..file:getFilename())
  img.set(file, #directory+1)
  img.set(directory[#directory])
  directory_index = #directory
  file:close()
  base_path = ""
end
--
function love.directorydropped(path)
  print("Mounting dropped directory "..path)
  love.filesystem.mount(path, "working_dir")
  directory_index = 1
  directory = {}

  local recursion_ok
  local function recursive_retrieve(dir,t) 
    for i,v in ipairs(love.filesystem.getDirectoryItems(dir)) do
      local file = dir.."/"..v
      local info = love.filesystem.getInfo(file)
      if info.type=="file" then
        if v:lower():match("%.[^%.]+$")
        and __.detect(supported_filetypes, function(_,t) return t==v:lower():match("%.([^%.]+)$") end) then
          table.insert(t,file)
        end
      elseif info.type=="directory" then
        if recursion_ok==nil then
          if msgbox("Fetching images...", "This folder has one or more subfolders.\nDo you want Peeper to fetch images from those subfolders as well?",{"No","Sure",enterbutton=1,escapebutton=2}) == 2 then
            recursion_ok = true
          else
            recursion_ok = false
          end
        elseif recursion_ok then
--        add children to file table
          recursive_retrieve(file, t)
        end
      end
    end
    return t
  end
  --
  recursive_retrieve("working_dir",directory)

  sort_directory("alphabetical")
  if not next(directory) then return end
  print("Loading file mounted at "..directory[directory_index])
  local file = love.filesystem.newFile(directory[directory_index])
  base_path = path
  img.set(file)
end
--

function love.quit(r)
  local w, h, window = love.window.getMode()
  local set = ""
  for i,v in pairs(window) do
    set = set..i.."="..tostring(v)..", "
  end
  love.filesystem.write("peeper_config",
    string.format([[timer.target = %s
menu.show_info = %s
menu.show_timer = %s
menu.show_buttons = %s
love.window.setMode(%s,%s,{%s})]],
      timer.target, menu.show_info, menu.show_timer, menu.show_buttons, w, h, set)
  )
end
--