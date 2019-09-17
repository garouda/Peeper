local function autocast(text)
  local t = text:lower()
  if t:find("^[%-%d%.]+$") and not t:find("%a") then return tonumber(text)
  elseif t == "true" then return true
  elseif t == "false" then return false
  elseif t == "" or t == "nil" then return nil end
  return text
end
--

function love.conf(t)
  local loaded_conf = {}
  if love.filesystem.getInfo("peeper_window.txt") then
    local config = love.filesystem.read("peeper_window.txt")
    for i,v in config:gmatch("(%w+):(%w+)%s*") do
      loaded_conf[i] = autocast(v)
    end
  end

  t.identity = "peeper"                    -- The name of the save directory (string)
  t.version = "11.1"               -- The LÖVE version this game was made for (string)
  t.console = false                  -- Attach a console (boolean, Windows only)
  t.externalstorage = true           -- True to save files (and read from the save directory) in external storage on Android (boolean) 

  t.window.title = "Peeper"         -- The window title (string)
  t.window.icon = "icon.png"  -- Filepath to an image to use as the window's icon (string)
  t.window.width = loaded_conf.width or 1080               -- The window width (number)
  t.window.height = loaded_conf.height or 720               -- The window height (number)
  t.window.vsync = nil               -- Enable vertical sync (boolean)
  t.window.resizable = true
  t.window.fullscreentype = "desktop"
  t.window.fullscreen = loaded_conf.fullscreen or false
  t.window.display = loaded_conf.display or 1                -- Index of the monitor to show the window in (number)
  t.window.x = loaded_conf.x or nil                   -- The x-coordinate of the window's position in the specified display (number)
  t.window.y = loaded_conf.y or nil                    -- The y-coordinate of the window's position in the specified display (number)

  t.modules.audio = true              -- Enable the audio module (boolean)
  t.modules.event = true              -- Enable the event module (boolean)
  t.modules.graphics = true           -- Enable the graphics module (boolean)
  t.modules.image = true              -- Enable the image module (boolean)
  t.modules.joystick = false           -- Enable the joystick module (boolean)
  t.modules.keyboard = true           -- Enable the keyboard module (boolean)
  t.modules.math = true               -- Enable the math module (boolean)
  t.modules.mouse = true              -- Enable the mouse module (boolean)
  t.modules.physics = false           -- Enable the physics module (boolean)
  t.modules.sound = true              -- Enable the sound module (boolean)
  t.modules.system = true             -- Enable the system module (boolean)
  t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
  t.modules.touch = false              -- Enable the touch module (boolean)
  t.modules.video = false              -- Enable the video module (boolean)
  t.modules.window = true             -- Enable the window module (boolean)
  t.modules.thread = true             -- Enable the thread module (boolean)
end