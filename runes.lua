-- HTTPS://NOR.THE-RN.INFO
-- NORNSILERPLATE
-- >> k1: exit
-- >> k2:
-- >> k3:
-- >> e1:
-- >> e2:
-- >> e3:


---- TODO: ALLOW 4-key shape to be created at once (special case for 4 keys, 2 and 3 at a time don't happen)

patterns = {
  ["r0"]   = {{1,1}, {1,2}, {2,1}, {2,2}},    -- Square
  ["i0"]   = {{1,1}, {1,2}, {1,3}, {1,4}},    -- Line
  ["i90"]  = {{1,1}, {2,1}, {3,1}, {4,1}},
  ["z0"]   = {{1,1}, {2,1}, {2,2}, {3,2}},    -- Z
  ["z90"]  = {{1,1}, {1,2}, {0,2}, {0,3}},
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
  --- rune_animate_clock_id = clock.run(rune_animate_clock)
  reset()
end


function reset()
  local w, h = g.cols, g.rows
  print('--- reset ---')
  grid_keys = {}
  --- init grid_keys table
  for x = 1, w do
    for y = 1, h do
      local coord = x .. "," .. y
      grid_keys[coord] = {x = x, y = y, pressed = false, active = false, unclaimed = false}
    end
  end
  runes = {}
  grid_dirty = true
end

function g.key(x, y, z) ---------------------- g.key() is automatically called by norns
  --- used to identify the key in the grid_keys table, 
  --- e.g. for a 128 grid, a value between 1,1 and 8,16
  local coord =  x .. "," .. y
  local w, h = g.cols, g.rows

  local pressed = false
  if z == 1 then
    pressed = true
  end 
  
  --- toggle off active state if the key is pressed and is unclaimed (only on press-down)
  if pressed and grid_keys[coord].active and grid_keys[coord].unclaimed then
    grid_keys[coord].active = false
    grid_keys[coord].unclaimed = false
  --- toggle on active state if the key is pressed and is not active (only on press-down)
  --- and no runes are pressed
  elseif pressed and not grid_keys[coord].active and #get_pressed_runes() == 0 then
    grid_keys[coord].active = true
    grid_keys[coord].unclaimed = true
  end
  --- update the pressed state
  grid_keys[coord].pressed = pressed

  --- reset if two diagonally opposite corners are pressed
  if (grid_keys["1,1"].pressed and grid_keys[w .. "," .. h].pressed) or
      (grid_keys["1,".. h].pressed and grid_keys[w..",1"].pressed) then
      reset()
      return
  end
  --- parse for new runes
  parse_runes()
  --- check for interaction with runes (pressing, deleting)
  update_runes()

  local pressed_runes = get_pressed_runes()
  if pressed and #pressed_runes == 1 and not grid_keys[coord].active then
    local rune = pressed_runes[1]
    if is_valid_location(rune, grid_keys[coord]) then
      translate_rune(rune, grid_keys[coord])
    end
  end

  grid_dirty = true

end

--- parse_runes() is called when a key is pressed
--- it checks if anew rune has been formed in the grid
--- by active, uncloaimed grid keys
function parse_runes()
    --- check if a rune is present in the grid
    for pattern_name, pattern in pairs(patterns) do
      for coord, grid_key in pairs(grid_keys) do
        local x, y, unclaimed = grid_key.x, grid_key.y, grid_key.unclaimed
        --- a rune can only be formed from unclaimed keys
        if unclaimed then
          --- check if the pattern matches a set of active, unclaimed keys
          for i, pattern_key in ipairs(pattern) do
            local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
            local rune_key_x, rune_key_y = x - pattern_x + 1, y - pattern_y + 1
            local rune_key_coord = rune_key_x .. "," .. rune_key_y
            --- if the key is not present in the grid or is not active and unclaimed, break
            if grid_keys[rune_key_coord] == nil or not grid_keys[rune_key_coord].unclaimed or not grid_keys[rune_key_coord].active then
              break
            end
            --- if the last key in the pattern is found, create the rune
            if i == #pattern then
              --- keep track of the keys that form the rune
              rune_keys = {}
              for i, pattern_key in ipairs(pattern) do
                local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
                local rune_key_x, rune_key_y = x - pattern_x + 1, y - pattern_y + 1
                local rune_key_coord = rune_key_x .. "," .. rune_key_y
                table.insert(rune_keys, {coord = rune_key_coord, x = rune_key_x, y = rune_key_y})
                --- mark the key as claimed
                grid_keys[rune_key_coord].unclaimed = false
              end
              --- add the rune to the list of runes
              print ("create rune")
              table.insert(runes, {pattern = pattern_name, keys = rune_keys})
              return true
            end
          end
        end
      end
    end
    return false
end

--- update_runes() is called when a key is pressed
--- it checks if a rune is pressed or deleted
function update_runes()
  --- use a while loop to iterate over the runes instead of a for loop
  --- because we may need to delete runes while iterating
  local i = 1
  while i <= #runes do
    local rune = runes[i]
    local pressed_rune_keys = 0
    for j, key in ipairs(rune.keys) do
      --- count the number of keys in the rune that are pressed
      if grid_keys[key.coord].pressed then
        pressed_rune_keys = pressed_rune_keys + 1
      end
    end
    --- if one or more keys are pressed, process the rune
    if pressed_rune_keys >= 1 then
      if rune.pressed and pressed_rune_keys == 3 then
        --- if a rune was already pressed and another key of the same rune is pressed, delete it
        for k, key in ipairs(rune.keys) do
          grid_keys[key.coord].active = false
          grid_keys[key.coord].unclaimed = false
        end
        print("deleted rune")
        --- delete the rune
        table.remove(runes, i)
        break
      else
        rune.pressed = true
        i = i + 1
      end
    else
      rune.pressed = false
      i = i + 1
    end
  end
  grid_dirty = true  
end

function is_valid_location(rune, new_key)

  --- get the pressed keys 
  --- calculate the translation offsets
  local dx = new_key.x - get_pressed_rune_key(rune).x
  local dy = new_key.y - get_pressed_rune_key(rune).y
  for i, key in ipairs(rune.keys) do
    --- calculate the new location for the key
    local new_x = key.x + dx
    local new_y = key.y + dy
    local new_coord = new_x .. "," .. new_y

    --- check if the new location is within the boundaries of the grid
    if new_x < 1 or new_x > g.cols or new_y < 1 or new_y > g.rows then
      print("out of bounds")
      return false
    end

    self_overlap = false
    --- allow the key to be placed on top of another key in the same rune
    for j, rune_key in ipairs(rune.keys) do
      if rune_key.x == new_x and rune_key.y == new_y then
        self_overlap = true
      end
    end

    --- check if the new location is not occupied by an active/unclaimed key or another rune,
    if (grid_keys[new_coord].active or grid_keys[new_coord].unclaimed) and not self_overlap then
      print("occupied")
      return false
    end
  
  end
  print("valid")
  return true
end


function translate_rune(rune, new_key)
  -- calculate the translation offsets
  local dx = new_key.x - get_pressed_rune_key(rune).x
  local dy = new_key.y - get_pressed_rune_key(rune).y

  -- calculate the new locations for each key in the rune
  local new_locations = {}
  for i, key in ipairs(rune.keys) do
    local new_x = key.x + dx
    local new_y = key.y + dy
    local new_coord = new_x .. "," .. new_y
    new_locations[i] = {x = new_x, y = new_y, coord = new_coord}
  end

  -- update the keys at the old locations
  for i, key in ipairs(rune.keys) do
    grid_keys[key.coord].active = false
    grid_keys[key.coord].unclaimed = false
  end

  -- update the keys at the new locations
  for i, key in ipairs(rune.keys) do
    local new_location = new_locations[i]
    grid_keys[new_location.coord].active = true
    grid_keys[new_location.coord].unclaimed = false
    key.x = new_location.x
    key.y = new_location.y
    key.coord = new_location.coord
  end
end


function get_pressed_runes()
  local pressed_runes = {}
  for i, rune in ipairs(runes) do
    if rune.pressed then
      table.insert(pressed_runes, rune)
    end
  end
  return pressed_runes
end


function get_pressed_rune_key(rune)
    if rune.pressed then
      for j, key in ipairs(rune.keys) do
        if grid_keys[key.coord].pressed then
          return key
        end
      end
    end
  return nil
end

--- print the state of the grid, with a visual representation of the key state
--- using 'a' for active false, 'A' for active true, 'p' for pressed false, 'P' for pressed true
--- and 'u' for unclaimed false, 'U' for unclaimed true
function print_grid()
  local w, h = g.cols, g.rows
  for y = 1, h do
    local line = ""
    for x = 1, w do
      local coord = x .. "," .. y
      local key = grid_keys[coord]
      if key.active then
          line = line .. "A"
      else
          line = line .. "a"
      end
      if key.pressed then
        line = line .. "P"
      else
        line = line .. "p"
      end
      if key.unclaimed then
        line = line .. "U"
      else
        line = line .. "u"
      end
      line = line .. " "
    end
    print(line)
  end
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
      if rune.pressed then
        rune.level = 14
      else 
        rune.level = 8
      end
      g:led(key.x, key.y, rune.level)
    end
  end
  
  --- draw the unclaimed keys and pressed locations
  for coord, grid_key in pairs(grid_keys) do
    local x, y, pressed, active, unclaimed = grid_key.x, grid_key.y, grid_key.pressed, grid_key.active, grid_key.unclaimed
    if active then
      if unclaimed then
        g:led(x, y, 15)
      end
    else
      g:led(x, y, 0)
    end
  end

  g:refresh()

end

function rune_animate_clock()
  while true do
    clock.sleep(1/15)
    for i, rune in ipairs(runes) do
      if not rune.pressed then
        if rune.level_up then
          rune.level = rune.level + 1
          if rune.level >= 12 then
            rune.level_up = false
          end
        else
          rune.level = rune.level - 1
          if rune.level <= 2 then
            rune.level_up = true
          end
        end
      end
    end
    grid_dirty = true
  end
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
  clock.cancel(rune_animate_clock_id)
end