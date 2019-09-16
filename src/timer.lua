local time = {}

local temp_for_count

local countdown_lo = love.audio.newSource("countdown_lo.ogg","static")
local countdown_hi = love.audio.newSource("countdown_hi.ogg","static")
countdown_lo:setVolume(0.4)
countdown_hi:setVolume(0.4)

time.current = 0
time.target = 0
time.paused = true

function time.start(target)
  time.current = menu.show_countdown and -3 or 0
  if not menu.box.visible then time.paused = false end
  time.target = target or time.target
  temp_for_count = nil
end
--
function time.reset()
  time.current = 0
  time.target = 0
  temp_for_count = nil
end
--

local font = love.graphics.newFont("font.otf",60)
function time.draw()
  if time.current >= 0 then return end
  love.graphics.setFont(font)
  love.graphics.setColor(0,0,0,0.9)
  love.graphics.rectangle("fill",0,0,screen_width,screen_height)
  love.graphics.setColor(1+(time.current-math.ceil(time.current)),1,1+(time.current-math.ceil(time.current)),0.8)
  love.graphics.printf(math.ceil(math.abs(time.current)), 0, screen_height/2-font:getHeight()/2, screen_width, "center")
end
--
function time.update(dt)
  if time.target == 0 or time.paused then time.paused = true return end
  time.current = math.min(time.current + dt, time.target)

  if menu.show_countdown and time.current < 1 and math.floor(time.current)~=temp_for_count then
    temp_for_count = math.floor(time.current)
    if time.current < 0 then countdown_lo:play() elseif time.current > 0 then countdown_hi:play()end
  end

  if time.current == time.target then
    menu.next()
  end
end
--

return time