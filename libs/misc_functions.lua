local misc = {}

function misc.gbd(weights)
  -- Categorical/Generalized Bernoulli Distribution
  local total_weight = __.reduce(weights, 0, function(total,_,v) return total+v end)
  local max = __.max(weights)
  for i,v in pairs(weights) do
    weights[i] = v/total_weight
  end
  return weights
end
--

function misc.roll(t)
  if type(t)~="table" then t = {t} end
  local r = math.random()
  table.sort(t)
  for i,v in pairs(t) do
    if r < v then return i,v end
    r = r - v
  end
end
--

function misc.exists(s,dirs)
  if type(dirs)~="table" then dirs = {dirs} end
  for d=1,#dirs do
    local rd = love.filesystem.getRealDirectory(dirs[d]..tostring(s)..".txt")
    if rd then return d, dirs[d]..s..".txt" end
  end
  return nil
end
--

function misc.tcopy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local working_dir = setmetatable({}, getmetatable(obj))
  s[obj] = working_dir
  for k, v in pairs(obj) do working_dir[misc.tcopy(k, s)] = misc.tcopy(v, s) end
  return working_dir
end
--
function misc.tswap(table,ind1,ind2)
  local temp = misc.tcopy(table[ind1])
  table[ind1] = misc.tcopy(table[ind2])
  table[ind2] = temp
  return table
end
--
function misc.lerp(norm, min, max) if norm and min and max then return (max - min) * norm + min else return 0 end end
--
function misc.cerp(t,a,b) local f=(1-math.cos(t*math.pi))*.5 return a*(1-f)+b*f end

function misc.HSV(h, s, v, a)
  if s <= 0 then return v,v,v,a end
  h, s, v = h*6, s, v
  local c = v*s
  local x = (1-math.abs((h%2)-1))*c
  local m,r,g,b = (v-c), 0,0,0
  if h < 1     then r,g,b = c,x,0
  elseif h < 2 then r,g,b = x,c,0
  elseif h < 3 then r,g,b = 0,c,x
  elseif h < 4 then r,g,b = 0,x,c
  elseif h < 5 then r,g,b = x,0,c
  else              r,g,b = c,0,x
  end
  return (r+m),(g+m),(b+m), a
end

function misc.checkRect(o,t)
  local x1,y1,w1,h1 = o[1],o[2],o[3],o[4]
  local x2,y2,w2,h2 = t[1],t[2],t[3],t[4]
  return x1 < x2+w2 and
  x2 < x1+w1 and
  y1 < y2+h2 and
  y2 < y1+h1
end
--
function misc.checkPoint(px,py,x,y,w,h)
  return px > x and py > y and px < x+w and py < y+h
end
--

function misc.comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end
--

function misc.autoCast(text)
  local t = text:lower()
  if t:find("^[%-%d%.]+$") and not t:find("%a") then return tonumber(text)
  elseif t == "true" then return true
  elseif t == "false" then return false
  elseif t == "" or t == "nil" then return nil end
  return text
end
--

return misc