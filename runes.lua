-- HTTPS://NOR.THE-RN.INFO
-- NORNSILERPLATE
-- >> k1: exit
-- >> k2:
-- >> k3:
-- >> e1:
-- >> e2:
-- >> e3:

patterns = {
  ["r0"]   = {{1,1}, {1,2}, {2,1}, {2,2}},    -- Square
  ["i0"]   = {{1,1}, {1,2}, {1,3}, {1,4}},    -- Line
  ["i90"]  = {{1,1}, {2,1}, {3,1}, {4,1}},
  ["z0"]   = {{1,1}, {2,1}, {2,2}, {3,2}},    -- Z
  ["z90"]  = {{1,1}, {1,2}, {2,2}, {2,3}},
  ["s0"]   = {{1,1}, {2,1}, {2,0}, {3,0}},    -- S
  ["s90"]  = {{1,1}, {1,2}, {2,2}, {2,3}},     
  ["t0"]   = {{1,1}, {2,1}, {3,1}, {2,2}},    -- T
  ["t90"]  = {{1,1}, {1,2}, {1,3}, {0,2}},
  ["t180"] = {{1,1}, {2,1}, {3,1}, {2,0}},  
  ["t270"] = {{1,1}, {1,2}, {1,3}, {2,2}},
  ["l0"]   = {{1,1}, {1,2}, {1,3}, {2,3}},    -- L
  ["l90"]  = {{1,1}, {2,1}, {3,1}, {1,2}},
  ["l180"] = {{1,1}, {2,1}, {2,2}, {2,3}},
  ["l270"] = {{1,1}, {2,1}, {3,1}, {3,0}},
  ["j0"]   = {{1,1}, {1,2}, {1,3}, {0,3}},    -- J
  ["j90"]  = {{1,1}, {2,1}, {3,1}, {3,2}},
  ["j180"] = {{1,1}, {2,1}, {1,2}, {1,3}},
  ["j270"] = {{1,1}, {2,1}, {3,1}, {1,0}},
}

g = grid.connect()

function init() ------------------------------ init() is automatically called by norns
  message = "NORNSILERPLATE" ----------------- set our initial message
  screen_dirty = true ------------------------ ensure we only redraw when something changes
  screen_redraw_clock_id = clock.run(screen_redraw_clock) -- create a "screen_redraw_clock" and note the id
  grid_redraw_clock_id = clock.run(grid_redraw_clock) 
  reset()
end

function reset()
  print('--- reset ---')
  grid_keys = {}
  runes = {}
  g:all(0)
end

function parse_runes()
   --- Look through the grid_keys, and check if any of the unclaimed keys form a complete rune shape based on the pattern list
   --- Account for the fact that the patterns are relative to the top-left corner of a shape starting at position 1,1
   --- but runes can be anywhere on the grid
   --- If any are found, remove them from the unclaimed keys list, create a rune to contain them
   --- and add it to the runes list
    for pattern_name, pattern in pairs(patterns) do
      for coord, grid_key in pairs(grid_keys) do
        local x, y, unclaimed = grid_key.x, grid_key.y, grid_key.unclaimed
        if unclaimed then
          for i, pattern_key in ipairs(pattern) do
            local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
            local rune_key_x, rune_key_y = x - pattern_x + 1, y - pattern_y + 1
            local rune_key_coord = rune_key_x .. "," .. rune_key_y
            if grid_keys[rune_key_coord] == nil or not grid_keys[rune_key_coord].unclaimed or not grid_keys[rune_key_coord].active then
              break
            end
            if i == #pattern then
              rune_keys = {}
              for i, pattern_key in ipairs(pattern) do
                local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
                local rune_key_x, rune_key_y = x - pattern_x + 1, y - pattern_y + 1
                local rune_key_coord = rune_key_x .. "," .. rune_key_y
                table.insert(rune_keys, {coord = rune_key_coord, x = rune_key_x, y = rune_key_y})
                grid_keys[rune_key_coord].unclaimed = false
              end
              table.insert(runes, {pattern = pattern_name, keys = rune_keys, level = 15})
            end
          end
        end
      end
    end
end

function check_runes()

  for i, rune in ipairs(runes) do
    
    local pressed = false

    for j, key in ipairs(rune.keys) do
      if grid_keys[key.coord].pressed then
        pressed = true
        break
      end
      --- if all of the keys in the rune are not pressed, then the rune is not pressed
      pressed = false
    end
    
    if pressed then
      rune.level = 12
      print ("---------- rune pressed " .. rune.pattern .. " " .. tostring(pressed))
    else
      rune.level = 2
      print ("---------- rune not pressed " .. rune.pattern .. " " .. tostring(pressed))
    end

    rune.pressed = pressed
  end
    grid_dirty = true  
end
 

function g.key(x, y, z) ---------------------- g.key() is automatically called by norns
  --- used to identify the key in the grid_keys table, 
  --- e.g. for a 128 grid, a value between 1,1 and 8,16
  local coord =  x .. "," .. y

  print("key " .. coord .. " pressed " .. tostring(z))

  local pressed = false
  if z == 1 then
    pressed = true
  end 

  ---  if the key is not in the grid_keys table, add it with default values
  if (grid_keys[coord] == nil) then
    grid_keys[coord] = {x = x, y = y, pressed = pressed, active = true, unclaimed = true}
  else
    --- toggle off active state if the key is pressed and is unclaimed (only on press-down)
    if pressed and grid_keys[coord].active and grid_keys[coord].unclaimed then
      grid_keys[coord].active = false
      grid_keys[coord].unclaimed = false
    --- toggle on active state if the key is pressed and is not active (only on press-down)
    elseif pressed and not grid_keys[coord].active then
      grid_keys[coord].active = true
      grid_keys[coord].unclaimed = true
    end
  end

  --- update the pressed state
  grid_keys[coord].pressed = pressed

  parse_runes()

  check_runes()
  

  grid_dirty = true

end

function enc(e, d) --------------- enc() is automatically called by norns
  if e == 1 then turn(e, d) end -- turn encoder 1
  if e == 2 then turn(e, d) end -- turn encoder 2
  if e == 3 then turn(e, d) end -- turn encoder 3
  screen_dirty = true ------------ something changed
end

function turn(e, d) ----------------------------- an encoder has turned
  message = "encoder " .. e .. ", delta " .. d -- build a message
end

function key(k, z) ------------------ key() is automatically called by norns
  if z == 0 then return end --------- do nothing when you release a key
  if k == 2 then press_down(2) end -- but press_down(2)
  if k == 3 then press_down(3) end -- and press_down(3)
  screen_dirty = true --------------- something changed
end

function press_down(i) ---------- a key has been pressed
  message = "press down " .. i -- build a message
end

function grid_redraw()
  g:all(0)

  --- draw the runes
  for i, rune in ipairs(runes) do
    for j, key in ipairs(rune.keys) do
      g:led(key.x, key.y, rune.level)
    end
  end
  
  --- draw the unclaimed keys and pressed locations
  for coord, grid_key in pairs(grid_keys) do
    local x, y, pressed, active, unclaimed = grid_key.x, grid_key.y, grid_key.pressed, grid_key.active, grid_key.unclaimed
    if active then
      if unclaimed then
        g:led(x, y, 8)
      end
    else
      g:led(x, y, 0)
    end
  
    if pressed then
      g:led(x, y, 15)
    end
  end

  g:refresh()

end

function grid_redraw_clock()
  while true do
    if grid_dirty then
      grid_redraw()
      grid_dirty = false
    end
    clock.sleep(1/30)
  end
end

function screen_redraw_clock() ----- a clock that draws space
  while true do ------------- "while true do" means "do this forever"
    clock.sleep(1/15) ------- pause for a fifteenth of a second (aka 15fps)
    if screen_dirty then ---- only if something changed
      redraw() -------------- redraw space
      screen_dirty = false -- and everything is clean again
    end
  end
end

function redraw() -------------- redraw() is automatically called by norns
  screen.clear() --------------- clear space
  screen.aa(1) ----------------- enable anti-aliasing
  screen.font_face(1) ---------- set the font face to "04B_03"
  screen.font_size(8) ---------- set the size to 8
  screen.level(15) ------------- max
  screen.move(64, 32) ---------- move the pointer to x = 64, y = 32
  screen.text_center(message) -- center our message at (64, 32)
  screen.pixel(0, 0) ----------- make a pixel at the north-western most terminus
  screen.pixel(127, 0) --------- and at the north-eastern
  screen.pixel(127, 63) -------- and at the south-eastern
  screen.pixel(0, 63) ---------- and at the south-western
  screen.fill() ---------------- fill the termini and message at once
  screen.update() -------------- update space
end


function r() ----------------------------- execute r() in the repl to quickly rerun this script
  norns.script.load(norns.state.script) -- https://github.com/monome/norns/blob/main/lua/core/state.lua
end

function cleanup() --------------- cleanup() is automatically called on script close
  clock.cancel(screen_redraw_clock_id)
  clock.cancel(grid_redraw_clock_id)
end