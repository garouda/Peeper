local event = {}
-- IDs are strings that the requester or wisher knows to search for. "enemydied", "levelup", "newarea" etc.

event.queue = {}
event.wishes = {}

function event.push(id,data)
  if data then
    event.queue[id] = event.queue[id] or {}
    table.insert(event.queue[id],data)
  end

  -- Return any wishes with that ID
  return event.wishes[id] or {}
end
--

function event.pop(id,index)
  if not event.exists(id) then return end
  local r = event.queue[id]
  r = table.remove(event.queue[id], index or 1) or r
  if not next(event.queue[id]) then event.queue[id] = nil end
  return r
end
--

function event.poll(id)
  local t = event.queue[id] or {}
  return next, t
end
--

function event.exists(id)
  return event.queue[id]
end
--

function event.clear(...)
  local args = {...}
  for i=1,#args do event.queue[args[i]] = nil end
end
--

function event.wish(id,data)
  if type(id)=="string" then id = {id} end
  for i,v in pairs(id) do
    event.wishes[v] = event.wishes[v] or {}
    table.insert(event.wishes[v], data)
  end
end
--

function event.grant(id,...)
  if type(id)=="string" then id = {id}
    for i,v in ipairs(id) do
      for i,v in pairs(event.wishes[v] or {}) do 
        if type(v)=="function" then
          v(unpack({...})) 
        end 
      end
    end
  end
end
--

return event