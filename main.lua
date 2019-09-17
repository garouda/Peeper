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

local basic_message
supported_filetypes = {"jpg","png"}
base_path = ""
directory_index = 1
directory = {}
sort_method = "ABC"

local import_thread = love.thread.newThread[[
  local path, supported_filetypes, recursion_ok = ...
  local __ = require("libs.underscore")
  local directory = {}
  local function recursive_retrieve(dir,t)
    for i,v in ipairs(love.filesystem.getDirectoryItems(dir)) do
    if love.thread.getChannel('abort_import'):pop() then return t end
      local file = dir.."/"..v
      local info = love.filesystem.getInfo(file)
      if info and info.type=="file" then
        if v:lower():match("%.[^%.]+$")
        and __.detect(supported_filetypes, function(_,t) return t==v:lower():match("%.([^%.]+)$") end) then
          table.insert(t,file)
          love.thread.getChannel('directory_progress'):push("Importing image #"..#directory..":\n"..v.."\nPress \'Esc\' to cancel.")
        end
      elseif info and info.type=="directory" and recursion_ok then
--      add children to file table
        recursive_retrieve(file, t)
      end
    end
    return t
  end
  --
  recursive_retrieve("working_dir",directory)
  love.thread.getChannel('finished'):push(directory)
]]

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
  directory_index = 1
  if type(directory[directory_index]) ~= "table" then
      img.set(love.filesystem.newFile(directory[directory_index]))
    else
      img.set(directory[directory_index])
    end
  menu.reset()
end
--
local waiting_func
local function wait_for_thread(channel,after_func)
  waiting_func = function()
    local result = channel:pop()
    if result then waiting_func = nil return after_func(result) end
  end
end
--

function love.load()
  math.randomseed(os.time())
  if love.filesystem.getInfo("peeper_config.txt") then
    local config = love.filesystem.read("peeper_config.txt")
    config = config:gsub("borderless=%w+","borderless=false"):gsub("fullscreen=%w+","fullscreen=false")
    assert(loadstring(config))()
  end

  screen_width, screen_height = love.window.getMode()
  base_screen_height, base_screen_width = screen_width, screen_height

  menu.reset()
  menu.toggle()
  love.keyboard.setKeyRepeat(true)
end
--

function love.update(dt)
  dt = math.min(dt, 0.07)
  if waiting_func then waiting_func() end
  img.update(dt)
  menu.update(dt)
  timer.update(dt)
  basic_message = love.thread.getChannel('directory_progress'):pop() or basic_message
  while not import_thread:isRunning() and love.thread.getChannel('directory_progress'):getCount() > 0 do
    love.thread.getChannel('directory_progress'):pop()
  end
end
--
local font = love.graphics.newFont("font.otf",24)
function love.draw()
  love.graphics.setFont(font)
  if not next(directory) then
    local msg = basic_message or "Drag and drop an image, folder, or .zip here to start."
    love.graphics.setColor(1,1,1)
    love.graphics.printf(msg, 0, screen_height/2-love.graphics.getFont():getHeight(), screen_width, "center")
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
  if key=="escape" then
    basic_message = nil
    if import_thread:isRunning() then love.thread.getChannel('abort_import'):push(true) end
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
  if file:getFilename():lower():match("%.zip$") then
--    return love.directorydropped(file:getFilename():match("(.+)\\"))
    return love.directorydropped(file:getFilename())
  end
  img.set(file, #directory+1)
  img.set(directory[#directory])
  directory_index = #directory
  file:close()
  base_path = ""
end
--

local function after_directory_scrape(dir)
  directory = dir
  sort_directory("alphabetical")
  if not next(directory) or not directory[directory_index] then return end
  print("Loading file mounted at "..directory[directory_index])
  local file = love.filesystem.newFile(directory[directory_index])
  img.set(file)
  menu.reset()
end
--

function love.directorydropped(path)
  print("Mounting dropped directory "..path)
  love.filesystem.unmount(base_path)
  love.filesystem.mount(path, "working_dir")
  directory_index = 1
  directory = {}
  base_path = path
  basic_message = nil
  local recursion_ok = false
  for i,v in ipairs(love.filesystem.getDirectoryItems("working_dir")) do
    local info = love.filesystem.getInfo("working_dir/"..v)
    if info.type=="directory" then
      if msgbox("Fetching images...", "This folder has one or more subfolders.\nDo you want Peeper to fetch images from those subfolders as well?",{"No","Sure",enterbutton=1,escapebutton=2}) == 2 then
        recursion_ok = true
      else
        recursion_ok = false
      end
      break
    end
  end

  import_thread:start(path,supported_filetypes,recursion_ok)
  wait_for_thread(love.thread.getChannel('finished'), after_directory_scrape)
end
--

function love.quit(r)
  local w, h, window = love.window.getMode()
  love.filesystem.write("peeper_config.txt",
    string.format([[timer.target = %s
menu.show_info = %s
menu.show_timer = %s
menu.show_buttons = %s]],
      timer.target, menu.show_info, menu.show_timer, menu.show_buttons)
  )
  local peeper_window = "width:"..w.." ".."height:"..h.." "
  for i,v in pairs(window) do
    peeper_window = peeper_window..i..":"..tostring(v).." "
  end
  love.filesystem.write("peeper_window.txt", peeper_window)
end
--