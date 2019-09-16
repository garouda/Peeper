local menu = {}
local input = require("input")
local font = love.graphics.newFont()
menu.visible = false
menu.box = {
  x = 0,
  y = screen_height,
  ty = screen_height,
  w = screen_width,
  h = screen_height/5,
}
local buttons = {}
local _prev, _next
local double_click_timer = 0
menu.show_info = true
menu.show_timer = true
menu.show_buttons = true
menu.show_countdown = false
table.insert(buttons,newButton("Back", function() menu.prev() end, 15, screen_height-60, 100, 45))
table.insert(buttons,newButton("Skip", function() menu.next() end, screen_width-115, screen_height-60, 100, 45))
buttons.sort = newButton("Sort: "..(sort_method or "ABC"), function()
    sort_directory(sort_method=="ABC" and "random" or "alphabetical")
    buttons.sort = newButton("Sort: "..sort_method, buttons.sort.func, buttons.sort.x,buttons.sort.y,buttons.sort.w,buttons.sort.h)
  end, screen_width/2 - 125/2, 45, 125, 45)

function menu.next()
  if #directory < 2 then return end
  _prev = img.current
  directory_index = (directory_index + 1 - 1) % #directory + 1
  if not directory[directory_index] then return end
  if not _next then
    if type(directory[directory_index]) ~= "table" then
      img.set(love.filesystem.newFile(directory[directory_index]))
    else
      img.set(directory[directory_index])
    end
  else
    img.set(_next)
  end
  _next = nil
  collectgarbage()
end
--
function menu.prev()
  if #directory < 2 then return end
  _next = img.current
  directory_index = (directory_index - 1 - 1) % #directory + 1
  if not directory[directory_index] then return end
  if not _prev then 
    if type(directory[directory_index]) ~= "table" then
      img.set(love.filesystem.newFile(directory[directory_index]))
    else
      img.set(directory[directory_index])
    end
  else
    img.set(_prev)
  end
  _prev = nil
  collectgarbage()
end
--

function menu.toggle()
  menu.box.visible = not menu.box.visible
  if img.current then timer.paused = menu.box.visible end
  buttons.sort.visible = menu.box.visible
end
--

function menu.update(dt)
  menu.box.w = screen_width
  menu.box.ty = not menu.box.visible and screen_height or screen_height-menu.box.h
  menu.box.y = Misc.lerp(12*dt, menu.box.y, menu.box.ty)
  for i=1,2 do
    local v = buttons[i]
    v.y = menu.box.y - 15 - v.h
    if i==2 then v.x = screen_width - 15 - v.w end
    v:update(dt)
  end
  for i=3,#buttons do
    local v = buttons[i]
    v.y = menu.box.y + menu.box.h/2-v.h/2
    v:update(dt)
  end
  buttons.sort:update(dt)
  input.update(dt)
  double_click_timer = math.max(0, double_click_timer - dt)
end
--

local function draw_info()
  local file = img.current or "No file opened yet"
  local filename = file.filename or file
  local left = filename
  love.graphics.print(left,15,15)
  local right = "Image: "..math.min(#directory, directory_index).."/"..#directory
  right = right.."\nEstimated time: "..math.ceil(math.max(0, timer.target*((#directory-1)-directory_index)-timer.current)).." seconds"
  love.graphics.printf(right,0,15,screen_width-15,"right")
end
--
local function draw_timer()
  love.graphics.setColor(1,1,1,0.2)
  love.graphics.rectangle("fill",menu.box.x+115+30,menu.box.y-15-8,menu.box.w-(115+30)*2,6)
  love.graphics.setColor(0,1,0,0.66)
  love.graphics.rectangle("fill",menu.box.x+115+30,menu.box.y-15-8,(menu.box.w-(115+30)*2)*math.clamp(0,timer.current/timer.target,1),6)
  love.graphics.setColor(0,0,0,0.66)
  love.graphics.rectangle("line",menu.box.x+115+30,menu.box.y-15-8,menu.box.w-(115+30)*2,6)
end
--

function menu.draw()
  love.graphics.setFont(font)
  if menu.show_info then
    love.graphics.setColor(0,0,0,1/3)
    for o = -1, 1, 2 do
      love.graphics.push()
      love.graphics.translate(o,0)
      draw_info()
      love.graphics.translate(-o,o)
      draw_info()
      love.graphics.pop()
    end
    love.graphics.setColor(1,1,1)
    draw_info()
  end
  if menu.show_timer then draw_timer() end

  if menu.visible or menu.box.y < screen_height-1 then
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle("fill",menu.box.x,menu.box.y,menu.box.w,menu.box.h)
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.line(menu.box.x,menu.box.y,menu.box.x+menu.box.w,menu.box.y)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("- Timer Paused -", menu.box.x,menu.box.y+10,menu.box.w,"center")
    love.graphics.printf(string.format("\nHOTKEYS:\nDouble-click OR Space: Pause timer, show/hide this menu\nLeft OR Right : Move to previous or next image\nC : %s image countdown\n1 : %s information overlay\n2 : %s the timer\n3 : %s Buttons", (menu.show_countdown and "Disable" or "Enable"),(menu.show_info and "Hide" or "Show"), (menu.show_timer and "Hide" or "Show"), (menu.show_buttons and "Hide" or "Show")), menu.box.x,menu.box.y+10,menu.box.w/2,"center")
    love.graphics.printf("\nTime until next image:", menu.box.x+menu.box.w/2,menu.box.y+10,menu.box.w/2,"center")
    input.draw()
  end
  if menu.show_buttons then for i,v in pairs(buttons) do v:draw() end end
end
--

function menu.keypressed(key)
  if key == "space" then return menu.toggle() end
  if menu.box.visible then
    if input.keypressed(key) then return end
  end  
  if key == "right" then
    return menu.next()
  elseif key == "left" then
    return menu.prev()
  elseif key == "2" then
    menu.show_timer = not menu.show_timer
    return
  elseif key == "1" then
    menu.show_info = not menu.show_info
    return
  elseif key == "3" then
    menu.show_buttons = not menu.show_buttons
    return
  elseif key == "c" then
    menu.show_countdown = not menu.show_countdown
    return
  elseif key == "escape" then
    img.current = nil
    _prev, _next = nil, nil
    timer.reset()
    directory = {}
    directory_index = 1
    return
  end
end
--

function menu.keyreleased(key)
end
--

function menu.textinput(text)
  if not menu.box.visible then return end
  if input.textinput(text) then return end
end
--

function menu.mousepressed(x,y,b,t)
  for i,v in pairs(buttons) do if v:mousepressed(x,y,b,t) then return end end
  if input.mousepressed(x,y,b,t) then return end
  if not Misc.checkPoint(x,y, menu.box.x, menu.box.y, menu.box.w, menu.box.h)
  and double_click_timer > 0 then
    menu.toggle()
    double_click_timer = 0
    return
  end
  double_click_timer = 0.4
end
--

function menu.mousereleased(x,y,b,t)
  if not menu.show_buttons then return end
  for i,v in pairs(buttons) do if v:mousereleased(x,y,b,t) then return end end
end
--

function menu.mousemoved(x,y,dx,dy)
end
--

function menu.touchmoved(id,x,y,dx,dy)
end
--

function menu.wheelmoved(x,y)
end
--

return menu