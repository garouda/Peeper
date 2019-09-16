local inp = {}

local text = ""
local cursor = 0
local blink = 0
local active = false
local box = {
}

function inp.setActive(bool)
  text = tostring(timer.target)
  cursor = #text
  blink = 0
  active = bool
  return bool
end
--

function inp.update(dt)
  if text == "" and not active then text = tostring(timer.target) end
  box = {
    x = menu.box.x+menu.box.w*0.635,
    y = menu.box.y+menu.box.h/3.5,
    w = menu.box.w/4,
    h = menu.box.h/2.5,
  }
  timer.target = tonumber(text) or 15
  if not active then return end
  blink = (blink + dt) % 1
  return true
end
--
local font = love.graphics.newFont("font.otf",45) font:setLineHeight(0.75)
function inp.draw()
  local text = text
  if not active then text = text.." sec" end
  love.graphics.setFont(font)
  love.graphics.setColor(1,1,1)
  love.graphics.printf(text, box.x, box.y, box.w, "left")
  if not active then return end
  if blink < 0.5 then
    love.graphics.setColor(1,1,1,2/3)
    love.graphics.print("|", box.x+font:getWidth(text:sub(1,cursor)), box.y-2)
  end
  love.graphics.setColor(1,1,1,0.33)
  love.graphics.rectangle("line", box.x, box.y, box.w, box.h, 5, 5)

  return true
end
--

function inp.keypressed(key)
  if not active then
    if key == "return" then return inp.setActive(true) end
    return
  end
  if key == "escape" or key == "return" then inp.setActive(false) end
  if key == "backspace" and cursor ~= 0 then
    text = text:sub(1,cursor-1)..text:sub(cursor+1)
    cursor = math.max(0, cursor - 1)
    blink = 0
  end
  if key == "delete" and cursor ~= #text then
    text = text:sub(1,cursor)..text:sub(cursor+2)
    blink = 0
  end
  if key == "left" then cursor = math.max(0, cursor - 1) blink = 0
  elseif key == "right" then cursor = math.min(#text, cursor + 1) blink = 0
  end
  if key == "end" then cursor = #text elseif key == "home" then cursor = 0 end
  if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
    if key=="c" then love.system.setClipboardText(text) elseif key=="v" then inp.textinput(tostring(love.system.getClipboardText())) end
  end
  return true
end
--

function inp.textinput(t)
  if not active then return end
  if not tonumber(t) and t~="." then return end
  if #text >= 6 then return true end
  if cursor < #text then text = text:sub(1,cursor)..t..text:sub(cursor+1) else text = text..t end
  cursor = cursor + #t
  blink = 0
  return true
end
--

function inp.mousepressed(x,y,b,t)
  local a = Misc.checkPoint(x,y, box.x, box.y, box.w, box.h)
  inp.setActive(a)
  return a
end
--

return inp