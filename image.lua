local img = {}
local canvas = love.graphics.newCanvas()
local boxblur = love.graphics.newShader[[
    extern vec2 direction;
    extern number radius;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      vec4 c = vec4(0.0f);

      for (float i = -radius; i <= radius; i += 1.0f)
      {
        c += Texel(texture, tc + i * direction);
      }
      return c / (2.0f * radius + 1.0f) * color;
    }
]]
event.wish({"resized","setimage"}, function()
    if not img.current then return end
    img.scale = 1
    img.target_scale = 1
    img.viewport = {x=0,y=0}
    img.viewport_target = {x=0,y=0}
    local image = img.current.image
    canvas = love.graphics.newCanvas()
    love.graphics.setColor(1,1,1)
    boxblur:send('direction', {1 / screen_width, 0})
    boxblur:send('radius', math.floor(20 + .5))
    love.graphics.setShader(boxblur)
    love.graphics.setCanvas(canvas)
    love.graphics.draw(image,
      screen_width/2, screen_height/2, nil, 
      screen_width/(image:getWidth()),
      screen_height/(image:getHeight()),
      image:getWidth()/2, image:getHeight()/2)
    love.graphics.setCanvas()
    love.graphics.setShader()
  end)
img.current = nil
img.panning = false
img.scale = 1
img.target_scale = 1
img.viewport = {x=0,y=0}
img.viewport_target = {x=0,y=0}

local function clamp_viewport(x,y)
  local cur = img.current
  if not cur then return end
  local image = cur.image
  local scaled_w = image:getWidth() * math.clamp(0, math.min(screen_width/image:getWidth(), screen_height/image:getHeight()), 1) * img.target_scale
  local scaled_h = image:getHeight() * math.clamp(0, math.min(screen_width/image:getWidth(), screen_height/image:getHeight()), 1) * img.target_scale
  img.viewport_target.x = math.clamp((-scaled_w)/2 + screen_width/2, x, (scaled_w)/2 - screen_width/2)
  img.viewport_target.y = math.clamp((-scaled_h)/2 + screen_height/2, y, (scaled_h)/2 - screen_height/2)
  
  if scaled_w <= screen_width then
    img.viewport_target.x = 0
  end
  if scaled_h <= screen_height then
    img.viewport_target.y = 0
  end
end
--

function img.set(file,index)
  local filename
  local imagedata
  if not file then return end
  index = index or directory_index
  if file.getFilename then filename = file:getFilename() else filename = file.filename end
  if not __.detect(supported_filetypes, function(_,v) return v==filename:lower():match("%.([^%.]+)$") end) then return end
  local t = {}
  t.filename=(file.filename or (base_path~="" and base_path.."\\" or "")..filename):gsub("working_dir/",""):gsub("/","\\")
  if not file.image then
    local err
    err, imagedata = pcall(love.image.newImageData, file)
    if not err then
      if msgbox("ERROR", "\""..t.filename.."\"\ncould not be decoded.\nThe file may be corrupt, or configured in a peculiar way.",{"OK","Copy path"}) == 2 then
        love.system.setClipboardText(t.filename)
      end
      table.remove(directory,index)
      return menu.next()
    end
  end
  t.image=file.image or love.graphics.newImage(imagedata)
  timer.start()
  if index~=directory_index then
    directory[index] = t
    return t
  else
    directory[index] = directory[index] or t
    img.current = t
    return t, event.grant("setimage")
  end
end
--

function img.update(dt)
  if not next(directory) or not img.current then return end
  img.scale = Misc.lerp(12*dt, img.scale, img.target_scale)
  img.viewport.x = Misc.lerp(12*dt, img.viewport.x, img.viewport_target.x)
  img.viewport.y = Misc.lerp(12*dt, img.viewport.y, img.viewport_target.y)
  if love.mouse.isDown(1) then img.panning = true else img.panning = false end
end
--

function img.draw()
  local cur = img.current
  if not next(directory) or not cur then return end
  local image = cur.image
  boxblur:send('direction', {0, 1 / screen_height})
  boxblur:send('radius', math.floor(20 + .5))
  love.graphics.setColor(0.8,0.8,0.8)
  love.graphics.setShader(boxblur)
  love.graphics.draw(canvas)
  love.graphics.setShader()

  love.graphics.push()
  love.graphics.translate(img.viewport.x,img.viewport.y)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(image,
    screen_width/2, screen_height/2, nil, 
    math.clamp(0, math.min(screen_width/image:getWidth(), screen_height/image:getHeight()), 1) * img.scale,
    math.clamp(0, math.min(screen_width/image:getWidth(), screen_height/image:getHeight()), 1) * img.scale,
    image:getWidth()/2, image:getHeight()/2)
  love.graphics.pop()
end
--

function img.mousemoved(x,y,dx,dy)
  if not next(directory) or not img.current then return end
  if not img.panning or img.target_scale == 1 then return end
  clamp_viewport(img.viewport_target.x + dx, img.viewport_target.y + dy)
end
--
function img.wheelmoved(x,y)
  img.target_scale = math.clamp(1, img.target_scale + y, 10)
  clamp_viewport(img.viewport_target.x, img.viewport_target.y)
end
--

return img