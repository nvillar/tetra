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

voice_ids = {}
max_voices = 16

engine.name = 'PolySub'
g = grid.connect()

function init() ------------------------------ init() is automatically called by norns
  message = "NORNSILERPLATE" ----------------- set our initial message
  screen_dirty = true ------------------------ ensure we only redraw when something changes
  screen_redraw_clock_id = clock.run(screen_redraw_clock) -- create a "screen_redraw_clock" and note the id
  grid_redraw_clock_id = clock.run(grid_redraw_clock) 
  --- tetra_animate_clock_id = clock.run(tetra_animate_clock)

  reset()
end

function reset()
  local w, h = g.cols, g.rows
  print('--- reset ---')
  engine.stopAll()
  voice_ids = {}
  grid_keys = {}
  --- init grid_keys table
  for x = 1, w do
    for y = 1, h do
      local coord = x .. "," .. y
      grid_keys[coord] = {x = x, y = y, pressed = false, active = false, unclaimed = false}
    end
  end
  tetras = {}
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
  --- and no tetras are pressed
  elseif pressed and not grid_keys[coord].active and #get_pressed_tetras() == 0 then
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

  --- print("Number of free voices: " .. get_number_of_free_voices())
  --- parse for new tetras
 parse_tetras()
  
  --- check for interaction with tetras (pressing, deleting)
  update_tetras()
  
  local pressed_tetras = get_pressed_tetras()
  
  --- if a tetra is pressed and a available key is pressed, translate the tetra
  if pressed and #pressed_tetras == 1 and not grid_keys[coord].active then
    local tetra = pressed_tetras[1]
    if is_valid_location(tetra, grid_keys[coord]) then
      translate_tetra(tetra, grid_keys[coord])
    end
  end

  for i, tetra in ipairs(tetras) do
    if not tetra.playing and tetra.pressed then
      if tetra.voice_id == nil then
        tetra.voice_id = get_free_voice_id()
      end
      if tetra.engine_frequency == nil then
        tetra.engine_frequency = get_random_note_in_c_minor_pentatonic_scale_as_hz()
      end
      if tetra.engine_timbre == nil then

        --- default
        tetra.engine_release = 1

        if tetra.pattern == "r0" then
          tetra.engine_shape = 0
          tetra.engine_timbre = 0
          tetra.engine_frequency = tetra.engine_frequency / 6
        elseif tetra.pattern == "i0" or tetra.pattern == "i90" then
          tetra.engine_shape = 0.15
          tetra.engine_timbre = 0.15
          tetra.engine_release = 0.2
        elseif tetra.pattern == "z0" or tetra.pattern == "z90" then
          tetra.engine_shape = 0.3
          tetra.engine_timbre = 0.3
        elseif tetra.pattern == "s0" or tetra.pattern == "s90" then
          tetra.engine_shape = 0.45
          tetra.engine_timbre = 0.45
        elseif tetra.pattern == "t0" or tetra.pattern == "t90" or tetra.pattern == "t180" or tetra.pattern == "t270" then
          tetra.engine_shape = 0.6
          tetra.engine_timbre = 0.6
        elseif tetra.pattern == "l0" or tetra.pattern == "l90" or tetra.pattern == "l180" or tetra.pattern == "l270" then
          tetra.engine_shape = 0.65
          tetra.engine_timbre = 0.65
        elseif tetra.pattern == "j0" or tetra.pattern == "j90" or tetra.pattern == "j180" or tetra.pattern == "j270" then
          tetra.engine_shape = 0.8
          tetra.engine_timbre = 0.8
        end
      end
      engine.ampRel(tetra.engine_release)
      engine.shape(tetra.engine_shape)
      engine.timbre(tetra.engine_timbre)
      engine.solo(tetra.voice_id, tetra.engine_frequency)
      tetra.playing = true
    elseif tetra.playing and not tetra.pressed then
      engine.stop(tetra.voice_id)
      tetra.playing = false
    end
  end

  grid_dirty = true

end

--- parse_tetras() is called when a key is pressed
--- it checks if anew tetra has been formed in the grid
--- by active, uncloaimed grid keys
function parse_tetras()
    --- check if a tetra is present in the grid
    for pattern_name, pattern in pairs(patterns) do
      for coord, grid_key in pairs(grid_keys) do
        local x, y, unclaimed = grid_key.x, grid_key.y, grid_key.unclaimed
        --- a tetra can only be formed from unclaimed keys
        if unclaimed then
          --- check if the pattern matches a set of active, unclaimed keys
          for i, pattern_key in ipairs(pattern) do
            local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
            local tetra_key_x, tetra_key_y = x - pattern_x + 1, y - pattern_y + 1
            local tetra_key_coord = tetra_key_x .. "," .. tetra_key_y
            --- if the key is not present in the grid or is not active and unclaimed, break
            if grid_keys[tetra_key_coord] == nil or not grid_keys[tetra_key_coord].unclaimed or not grid_keys[tetra_key_coord].active then
              break
            end
            --- if the last key in the pattern is found, create the tetra
            if i == #pattern then
              --- keep track of the keys that form the tetra
              tetra_keys = {}
              for i, pattern_key in ipairs(pattern) do
                local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
                local tetra_key_x, tetra_key_y = x - pattern_x + 1, y - pattern_y + 1
                local tetra_key_coord = tetra_key_x .. "," .. tetra_key_y
                table.insert(tetra_keys, {coord = tetra_key_coord, x = tetra_key_x, y = tetra_key_y})
                --- mark the key as claimed
                grid_keys[tetra_key_coord].unclaimed = false
              end
              --- add the tetra to the list of tetras
              print ("create tetra")
              table.insert(tetras, {new = true, pattern = pattern_name, keys = tetra_keys, playing= false})
              return true
            end
          end
        end
      end
    end
    return false
end

--- update_tetras() is called when a key is pressed
--- it checks if a tetra is pressed or deleted
function update_tetras()
  --- use a while loop to iterate over the tetras instead of a for loop
  --- because we may need to delete tetras while iterating
  local i = 1
  while i <= #tetras do
    local tetra = tetras[i]
    local pressed_tetra_keys = 0
    for j, key in ipairs(tetra.keys) do
      --- count the number of keys in the tetra that are pressed
      if grid_keys[key.coord].pressed then
        pressed_tetra_keys = pressed_tetra_keys + 1
      end
    end
    --- if one or more keys are pressed, process the tetra
    if pressed_tetra_keys >= 1 then
      --- if tetra is still new, 
      if tetra.pressed and pressed_tetra_keys == 2 and tetra.new == false then
        --- if a tetra was already pressed and another key of the same tetra is pressed, delete it
        for k, key in ipairs(tetra.keys) do
          grid_keys[key.coord].active = false
          grid_keys[key.coord].unclaimed = false
        end
        print("deleted tetra")

        if tetra.voice_id ~= nil then
          engine.stop(tetra.voice_id)
          release_voice_id(tetra.voice_id)
        end

        --- delete the tetra
        table.remove(tetras, i)
        break
      else
        tetra.pressed = true
        i = i + 1
      end
    else
      tetra.pressed = false
      tetra.new = false
      i = i + 1
    end
  end
  grid_dirty = true  
end

function is_valid_location(tetra, new_key)

  --- get the pressed keys 
  --- calculate the translation offsets
  local dx = new_key.x - get_pressed_tetra_key(tetra).x
  local dy = new_key.y - get_pressed_tetra_key(tetra).y
  for i, key in ipairs(tetra.keys) do
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
    --- allow the key to be placed on top of another key in the same tetra
    for j, tetra_key in ipairs(tetra.keys) do
      if tetra_key.x == new_x and tetra_key.y == new_y then
        self_overlap = true
      end
    end

    --- check if the new location is not occupied by an active/unclaimed key or another tetra,
    if (grid_keys[new_coord].active or grid_keys[new_coord].unclaimed) and not self_overlap then
      return false
    end
  
  end
  return true
end


function translate_tetra(tetra, new_key)
  -- calculate the translation offsets
  local dx = new_key.x - get_pressed_tetra_key(tetra).x
  local dy = new_key.y - get_pressed_tetra_key(tetra).y

  -- calculate the new locations for each key in the tetra
  local new_locations = {}
  for i, key in ipairs(tetra.keys) do
    local new_x = key.x + dx
    local new_y = key.y + dy
    local new_coord = new_x .. "," .. new_y
    new_locations[i] = {x = new_x, y = new_y, coord = new_coord}
  end

  -- update the keys at the old locations
  for i, key in ipairs(tetra.keys) do
    grid_keys[key.coord].active = false
    grid_keys[key.coord].unclaimed = false
  end

  -- update the keys at the new locations
  for i, key in ipairs(tetra.keys) do
    local new_location = new_locations[i]
    grid_keys[new_location.coord].active = true
    grid_keys[new_location.coord].unclaimed = false
    key.x = new_location.x
    key.y = new_location.y
    key.coord = new_location.coord
  end
end


function get_pressed_tetras()
  local pressed_tetras = {}
  for i, tetra in ipairs(tetras) do
    if tetra.pressed then
      table.insert(pressed_tetras, tetra)
    end
  end
  return pressed_tetras
end


function get_pressed_tetra_key(tetra)
    if tetra.pressed then
      for j, key in ipairs(tetra.keys) do
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

--- get the next free voice id. There are a maximum of 16 voices. If all voices are taken, return nil
-- otherwise, return the next free voice id
function get_free_voice_id()
  for i = 1, 16 do
    if voice_ids[i] == nil then
      voice_ids[i] = true
      return i
    end
  end
  return nil
end

-- release a voice id
function release_voice_id(id)
  voice_ids[id] = nil
end

function get_number_of_free_voices()
  local count = 0
  for i = 1, max_voices do
    if voice_ids[i] == nil then
      count = count + 1
    end
  end
  return count
end

function get_random_note_in_c_minor_pentatonic_scale_as_hz()
  local notes = {261.63, 293.66, 329.63, 392.00, 440.00, 493.88, 523.25}
  return notes[math.random(1, #notes)]
end

function get_note_in_c_minor_pentatonic_scale_as_hz(index)
  local notes = {261.63, 293.66, 329.63, 392.00, 440.00, 493.88, 523.25}
  return notes[index]
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

  --- draw the tetras
  for i, tetra in ipairs(tetras) do
    for j, key in ipairs(tetra.keys) do
      if tetra.pressed then
        tetra.level = 14
      else 
        tetra.level = 8
      end
      g:led(key.x, key.y, tetra.level)
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

function tetra_animate_clock()
  while true do
    clock.sleep(1/15)
    for i, tetra in ipairs(tetras) do
      if not tetra.pressed then
        if tetra.level_up then
          tetra.level = tetra.level + 1
          if tetra.level >= 12 then
            tetra.level_up = false
          end
        else
          tetra.level = tetra.level - 1
          if tetra.level <= 2 then
            tetra.level_up = true
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
  clock.cancel(tetra_animate_clock_id)
end
