local font = love.graphics.newFont()

local function new(label,func,x,y,w,h)
  label = label or "???"

  local func_r = function() end
  func = func or function() end

  if type(label)=="string" then
    w = w or font:getWidth(label)*1.75
    h = h or font:getHeight()+16
  else
    h = w or label:getHeight()
    w = w or label:getWidth()
  end

  x,y = math.floor(x), math.floor(y)

  local visible = true

  local cols = {
    bg = {
      --Default
      {1,1,1,0.25},
      --Hovered
      {1,1,1,0.55},
      --Pressed
      {0.03,0.12,0.1,0.4},
    },
    fg = {
      --Default
      {1,1,1,0.75},
      --Hovered
      {1,1,1},
      --Pressed
      {1,1,1,0.4},
    }
  }

  local selected_on_prev_frame

  local function update(self,dt,x,y)
    if not self.visible then return end
    if self.inactive then self.selected = false self.button_down = false return end
    local mx,my = love.mouse.getPosition()
    local xx,yy = self.x+(x or 0), self.y+(y or 0)
    if Misc.checkPoint(mx,my, xx,yy,self.w,self.h) then
      self.selected = true
    else
      self.selected = false
    end

    if not love.mouse.isDown(1) and not love.mouse.isDown(2) then self.button_down = false end
    if self.key_selected then self.selected = true end
    selected_on_prev_frame = self.selected
  end
  local function draw(self,x,y,alpha)
    if not self.visible then return end
    local line_width = love.graphics.getLineWidth()

    love.graphics.setFont(font)
    self.cols = self.cols
    local active_col = 1
    if self.selected then active_col=2 end
    if self.button_down then active_col=3 end

    if type(label)=="string" then
      love.graphics.setColor(self.cols.bg[active_col])
      love.graphics.rectangle("fill",self.x,self.y,self.w,self.h,6,6)
      love.graphics.setColor(0,0,0,self.cols.bg[active_col][4])
      love.graphics.rectangle("line",self.x,self.y,self.w,self.h,6,6)
      love.graphics.setColor(0,0,0)
      love.graphics.print(self.label, self.x + self.w/2 - font:getWidth(label)/2, self.y+self.h/2-font:getHeight(label)/2-2)
      love.graphics.setLineWidth(1)
    else
      love.graphics.setColor(self.cols.fg[active_col][1], self.cols.fg[active_col][2], self.cols.fg[active_col][3], (self.cols.fg[active_col][4] or 1)*(alpha or 1))
      love.graphics.draw(self.label,self.x,self.y,nil,w/self.label:getWidth(),h/self.label:getHeight())
    end
    love.graphics.setLineWidth(line_width)
  end
  local function mousepressed(self,x,y,b,xo,yo)
    if not self.visible then return end
    if self.inactive then return end
    self.button_down = false
    local xx, yy = self.x + (xo or 0), self.y + (yo or 0)
    if Misc.checkPoint(x,y, xx, yy, self.w, self.h) then
      self.button_down = true
      return true
    end
  end
  local function mousereleased(self,x,y,b,xo,yo)
    if not self.visible then return end
    if self.inactive then return end
    local xx, yy = self.x + (xo or 0), self.y + (yo or 0)
    if Misc.checkPoint(x,y, xx, yy, self.w, self.h) and self.button_down then
      if b==1 then self.func() end
      self.button_down = false
      return true
    end
    self.button_down = false
  end

  return {label=label,func=func,func_r=func_r,x=x,y=y,w=w,h=h,cols=cols,selected=false,key_selected=false,font=font,visible=visible,inactive=inactive,    update=update,draw=draw,mousepressed=mousepressed,mousereleased=mousereleased,}
end
--

return new
