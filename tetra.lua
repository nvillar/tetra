-- https://github.com/nvillar/tetra/
-- TETRA
-- >> k1: exit
-- >> k2: next e2 parameter
-- >> k3: next e3 parameter
-- >> e1: pitch
-- >> e2: timbre / shape / volume
-- >> e3: attack / sustain / release


--- TODO
--- while two in a group are pressed, the group is selected
--- and the encoders do the following:
--- e2: clock divider
--- e3: playback (up, down, ping-pong, random)
---
--- pressing two adjacent grid corners will:
---   if no tetras are pressed: start/stop all group sequencers
---   if any tetra are pressed: start/stop sequence that tetra is part of (if any)
---
--- x of a tetra on grid affects its stereo panning


music = require("musicutil")
engine.name = 'Pond'
Pond = include 'lib/Pond_engine'

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

engine_config = {
  -- Square
  ["r0"]   = {synth = engine.resonz, patch = {Pond_resonz_amp = 6, Pond_resonz_index = 0.1, Pond_resonz_pan = 0.0}},
  -- Line
  ["i0"]   = {synth = engine.karplu, patch = {Pond_karplu_amp = 0.2, Pond_karplu_index = 2, Pond_karplu_coef = 0.0, Pond_karplu_pan = 0.1}},                 
  ["i90"]  = {synth = engine.karplu, patch = {Pond_karplu_amp = 0.2, Pond_karplu_index = 2, Pond_karplu_coef = 0.3, Pond_karplu_pan = 0.1}},
  -- T     
  ["t0"]   = {synth = engine.ringer, patch = {Pond_ringer_amp = 0.2, Pond_ringer_index = 3, Pond_ringer_pan = 0.0}},   
  ["t180"] = {synth = engine.ringer, patch = {Pond_ringer_amp = 0.2, Pond_ringer_index = 3, Pond_ringer_pan = 0.0}},       
  ["t90"]  = {synth = engine.ringer, patch = {Pond_ringer_amp = 0.2, Pond_ringer_index = 1, Pond_ringer_pan = 0.0}},   
  ["t270"] = {synth = engine.ringer, patch = {Pond_ringer_amp = 0.2, Pond_ringer_index = 1, Pond_ringer_pan = 0.0}},   
  -- Z
  ["z0"]   = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 1, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.1, Pond_sinfm_release = 0.2, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["z90"]  = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 1, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.0, Pond_sinfm_release = 0.2, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  -- S
  ["s0"]   = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 3, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.1, Pond_sinfm_release = 0.2, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["s90"]  = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 3, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.0, Pond_sinfm_release = 0.2, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  -- L
  ["l0"]   = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 1, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.0, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["l180"] = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 1, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.0, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["l90"]  = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 3, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.3, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["l270"] = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 3, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.3, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  -- J
  ["j0"]   = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 2, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.0, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["j180"] = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 2, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.0, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["j90"]  = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 4, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.3, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}},
  ["j270"] = {synth = engine.sinfm, patch = {Pond_sinfm_amp = 0.2, Pond_sinfm_index = 1, Pond_sinfm_modnum = 4, Pond_sinfm_modeno = 1, Pond_sinfm_attack = 0.3, Pond_sinfm_release = 1.0, Pond_sinfm_phase = 0.0, Pond_sinfm_pan = 0.0}}
} 

encoder_config = {
  -- Square
  ["r"] = {e2_param = "Pond_resonz_index", e2_min = 0.02, e2_max = 1.0, e2_step = 0.01, e3_param = "Pond_resonz_amp", e3_min = 0, e3_max = 15.0, e3_step = 0.5},
  -- Line
  ["i"] = {e2_param = "Pond_karplu_index", e2_min = 0.1, e2_max = 10, e2_step = 0.5, e3_param = "Pond_karplu_amp", e3_min = 0, e3_max = 0.5, e3_step = 0.01},
  -- T
  ["t"] =  {e2_param = "Pond_ringer_index", e2_min = 1, e2_max = 24, e2_step = 1, e3_param = "Pond_ringer_amp", e3_min = 0, e3_max = 0.5, e3_step = 0.01},
  -- Z
  ["z"] = {e2_param = "Pond_sinfm_index", e2_min = 0, e2_max = 2, e2_step = 0.1, e3_param = "Pond_sinfm_amp", e3_min = 0, e3_max = 0.4, e3_step = 0.01},
  -- S
  ["s"] = {e2_param = "Pond_sinfm_index", e2_min = 0, e2_max = 2, e2_step = 0.1, e3_param = "Pond_sinfm_amp", e3_min = 0, e3_max = 0.4, e3_step = 0.01},
  -- L
  ["l"] = {e2_param = "Pond_sinfm_index", e2_min = 0, e2_max = 2, e2_step = 0.1, e3_param = "Pond_sinfm_amp", e3_min = 0, e3_max = 0.4, e3_step = 0.01},
 -- J
  ["j"] = {e2_param = "Pond_sinfm_index", e2_min = 0, e2_max = 2, e2_step = 0.1, e3_param = "Pond_sinfm_amp", e3_min = 0, e3_max = 0.4, e3_step = 0.01},
}

--- list of grid keys, indexed by a coordinate in the format "x,y"
--- each key has a state: pressed, lit, free
--- pressed: true if the key is currently pressed'
--- lit: true if the key light is lit
--- free: true if the key is not part of a tetra
grid_keys = {}
tetras = {}
groups = {}

scale_notes = {}

delete_keypress = 3
focus_tetra = nil

g = grid.connect()

-------------------------------------------------------------------------------
--- init() is automatically called by norns
-------------------------------------------------------------------------------

function init() 
  message = "TETRA" ----------------- set our initial message
  screen_dirty = true ------------------------ ensure we only redraw when something changes
  screen_redraw_clock_id = clock.run(screen_redraw_clock) -- create a "screen_redraw_clock" and note the id
  grid_redraw_clock_id = clock.run(grid_redraw_clock) 
  sequence_clock_id = clock.run(sequence_clock)


  local scale_names = {}
  for i = 1, #music.SCALES do
  table.insert(scale_names, music.SCALES[i].name)
  end
  -- setting root notes using params
    params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 36, formatter = function(param) return music.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end} 

  -- setting scale type using params
  params:add{type = "option", id = "scale", name = "scale",
    options = scale_names, default = 1,
    action = function() build_scale() end}
  
  -- setting how many octaves are included from the scale, starting from the root note
  params:add{type = "number", id = "scale_octaves", name = "octaves",
    min = 1, max = 7, default = 5,
    action = function() build_scale() end}

  build_scale()

  Pond.add_params()

  reset()
end

-------------------------------------------------------------------------------
--- reset the state of the grid
--- clear all tetras, reset the grid_keys table
-------------------------------------------------------------------------------
function reset()
  local w, h = g.cols, g.rows
  print('--- reset ---')
  --- engine.stopAll()
  grid_keys = {}
  focus_tetra = nil
  --- init grid_keys table
  for x = 1, w do
    for y = 1, h do
      local coord = x .. "," .. y
      grid_keys[coord] = {x = x, y = y, pressed = false, lit = false, free = false}
    end
  end
  tetras = {}
  groups = {}
  grid_dirty = true
end

-------------------------------------------------------------------------------
--- grid key event handler, called when a grid key is pressed or released
-------------------------------------------------------------------------------
function g.key(x, y, z)

  --- prepare grid coordinates
  --- get the dimensions of the grid
  local w, h = g.cols, g.rows
  --- grid_keys table is indexed by a coordinate in the format "x,y"
  --- for a 128 grid (8 rows, 16 columns), coordinates will be in 
  --- the range of "1,1" to "8,16"
  --- prepare the coordinate for the key that was pressed
  local coord =  x .. "," .. y
  
  --- update the pressed state in the grid_keys table
  local pressed = false
  if z == 1 then
    pressed = true
  end 
  grid_keys[coord].pressed = pressed
  
  --- process keys that are pressed and determine if they are lit or free
  --- turn key off if: it is free, pressed and lit
  if grid_keys[coord].lit 
        and grid_keys[coord].free 
        and pressed then
    grid_keys[coord].lit = false
    grid_keys[coord].free = true

  --- turn key on if is off and pressed, but only if 
  --- no tetras are pressed, otherwise be considered a translation,
  --- a condition that is handled further down the code
  elseif not grid_keys[coord].lit 
      and #get_pressed_tetras() == 0
      and pressed then
    grid_keys[coord].lit = true
    grid_keys[coord].free = true
  end

  --- check for special reset conditions
  --- reset if two diagonally opposite corners are pressed
  if (grid_keys["1,1"].pressed and grid_keys[w .. "," .. h].pressed) or
      (grid_keys["1,".. h].pressed and grid_keys[w..",1"].pressed) then
    reset()
    return
  end
  --- parse grid, look for new tetras and create them
  --- returns true if any tetras are created
  parse_tetras()
  
  --- check for interaction with tetras (pressing, deleting)
  update_tetras()
  
  --- get a list of tetras that are currently pressed
  local pressed_tetras = get_pressed_tetras()

  --- if only a single tetra is pressed, focus on it
  if pressed  
      and #pressed_tetras == 1
      and focus_tetra ~= pressed_tetras[1] then
    focus_tetra = pressed_tetras[1]
    print("focus " .. pressed_tetras[1].pattern)
  end

  --- if a tetra is pressed and a available key is pressed, translate the tetra
  if pressed and #pressed_tetras == 1 and not grid_keys[coord].lit then
    local tetra = pressed_tetras[1]
    if is_valid_location(tetra, grid_keys[coord]) then
      translate_tetra(tetra, grid_keys[coord])
    end
  end

  --- start playing pressed tetras if they are not already playing
  --- stop playing tetras that are not pressed
  for i, tetra in ipairs(tetras) do
    if not tetra.playing and tetra.pressed then
      play_tetra(tetra)
    elseif tetra.playing and tetra.released then
      stop_tetra(tetra)
      tetra.released = false
    end
  end

  grid_dirty = true
  screen_dirty = true

end

function play_tetra(tetra)

  --- apply the tetra configuration to the engine params
  for k, v in pairs(tetra.engine_config.patch) do
    params:set(k, v)
  end

  local hz = music.note_num_to_freq(tetra.engine_note)
  tetra.engine_config.synth(hz)

  tetra.playing = true
end

function stop_tetra(tetra)
  tetra.playing = false
end


-------------------------------------------------------------------------------
--- parse_groups() looks for and creates new groups
--- where a group is a set of of tetras that are connected by one or more keys
-------------------------------------------------------------------------------
function parse_groups(moved_tetra)

 local in_group = get_group(moved_tetra)

 --- if tetra was part of a group, delete the group
 --- so that it can be re-calculated
 if in_group ~= nil then
    print("deleted group")
    for i, group in ipairs(groups) do
      if group == in_group then
        table.remove(groups, i)
      end
    end
  end

  --- look for groups
  for i, tetra in ipairs(tetras) do
    for j, key in ipairs(tetra.keys) do
      for k, tetra2 in ipairs(tetras) do
        if tetra ~= tetra2 then
          for l, key2 in ipairs(tetra2.keys) do            
            if (math.abs(key.x - key2.x) == 1 and key.y == key2.y) 
                or (math.abs(key.y - key2.y) == 1 and key.x == key2.x) then
              in_group = get_group(tetra) 
              local in_group_2 = get_group(tetra2)
              if in_group == nil and in_group_2 == nil then
                print("created group with tetras " .. tetra.pattern .. " and " .. tetra2.pattern)
                local new_group = {}
                new_group.tetras = {tetra, tetra2}
                table.insert(groups, new_group)
              elseif in_group ~= nil and in_group_2 == nil then
                print("added tetra " .. tetra2.pattern .. " to existing group")
                table.insert(in_group.tetras, tetra2)
              elseif in_group == nil and in_group_2 ~= nil then
                print("added tetra " .. tetra.pattern .. " to existing group")
                table.insert(in_group_2.tetras, tetra)
              elseif in_group ~= nil and in_group_2 ~= nil then
                if in_group ~= in_group_2 then
                  print("merged groups")
                  for i, tetra in ipairs(in_group_2.tetras) do
                    table.insert(in_group.tetras, tetra)
                  end
                  for i, group in ipairs(groups) do
                    if group == in_group_2 then
                      table.remove(groups, i)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  print_groups()
end


-------------------------------------------------------------------------------
--- get_group() returns the group that a tetra is in
--- if the tetra is not in a group, it returns nil
-------------------------------------------------------------------------------
function get_group(tetra)
  for i, group in ipairs(groups) do
    for j, group_tetra in ipairs(group.tetras) do
      if group_tetra == tetra then
        return group
      end
    end
  end
  return nil
end

  
-------------------------------------------------------------------------------
--- parse_tetras() is called when a key is pressed
--- it checks if a new tetra has been formed in the grid
--- by grid keys that lit and free (not already part of a tetra)
--- if a tetra is found, it is added to the list of tetras 
--- and the keys are marked as free = false (claimed by the tetra)
-------------------------------------------------------------------------------
function parse_tetras()
  --- check if a tetra is present in the grid
  for pattern_name, pattern in pairs(patterns) do
    for coord, grid_key in pairs(grid_keys) do
      local x, y, free = grid_key.x, grid_key.y, grid_key.free
      --- a tetra can only be formed from free keys
      if free then
        --- check if the pattern matches a set of lit, free keys
        for i, pattern_key in ipairs(pattern) do
          local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
          local tetra_key_x, tetra_key_y = x - pattern_x + 1, y - pattern_y + 1
          local tetra_key_coord = tetra_key_x .. "," .. tetra_key_y
          --- if the key is not present in the grid or is not lit and free, break
          if grid_keys[tetra_key_coord] == nil or not grid_keys[tetra_key_coord].free or not grid_keys[tetra_key_coord].lit then
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
              grid_keys[tetra_key_coord].free = false
            end
            --- create a new tetra
            create_tetra(pattern_name, tetra_keys)        
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
--- this defines the default values of the new tetra, and then creates it
--- a tetra is considered new when it is first created, and until it is released
--- this allows the tetra to be created by pressing multiple buttons simulataneously
--- otherwise, the tetra would be deleted immediately after it is created unless
--- every key is pressed one after the other to form the tetra
-------------------------------------------------------------------------------
function create_tetra(pattern_name, keys)

  local tetra = {}

  --- default across all tetras
  --- can be ovewritten by each tetra.pattern
  tetra.new = true
  tetra.pressed = false
  tetra.released = false
  tetra.pattern = pattern_name
  tetra.keys = keys
  tetra.playing = false
  tetra.engine_note = get_random_note_in_scale()

  --- make a shallow copy of the engine_config for that pattern,
  --- so that each tetra can have its own configuration
  tetra.engine_config = {}
  for k, v in pairs(engine_config[tetra.pattern]) do
    tetra.engine_config[k] = v
  end

  print ("created tetra " .. tetra.pattern)
  table.insert(tetras, tetra)
  parse_groups(tetra)
end

-------------------------------------------------------------------------------
--- update_tetras() is called when a key is pressed
--- it checks if a tetra is pressed or deleted
-------------------------------------------------------------------------------
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
      --- if tetra is still new, don't delete it 
      if tetra.pressed and pressed_tetra_keys == delete_keypress and tetra.new == false then
        --- if a tetra was already pressed and another key of the same tetra is pressed, delete it
        for k, key in ipairs(tetra.keys) do
          grid_keys[key.coord].lit = false
          grid_keys[key.coord].free = false
        end
        --- tetra would have been focused, so reset focus
        focus_tetra = nil

        --- delete the tetra        
        print("deleted tetra " .. tetra.pattern)        
        table.remove(tetras, i)  
        parse_groups(tetra)
        break
        
      else
        tetra.release = false
        tetra.pressed = true
        i = i + 1
      end
    else

      if tetra.pressed then
        tetra.released = true
      end
      --- if none keys belonging to the tetra are pressed
      --- the tetra is not pressed
      tetra.pressed = false
      --- a tetra is considered new until it is released
      --- the first time after it is created
      tetra.new = false
      i = i + 1
    end
  end
  grid_dirty = true  
end

-------------------------------------------------------------------------------
--- is_valid_location() checks if a tetra can be translated to a new location
--- by checking if the new location is within the boundaries of the grid
--- and if the new location is not occupied by another tetra or a lit+free key
-------------------------------------------------------------------------------
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

    --- check if the new location is not occupied by an lit/free key or another tetra,
    if (grid_keys[new_coord].lit or grid_keys[new_coord].free) and not self_overlap then
      return false
    end
  
  end
  return true
end

-------------------------------------------------------------------------------
--- translate_tetra() translates a tetra to a new location
-------------------------------------------------------------------------------
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
    grid_keys[key.coord].lit = false
    grid_keys[key.coord].free = false
  end

  -- update the keys at the new locations
  for i, key in ipairs(tetra.keys) do
    local new_location = new_locations[i]
    grid_keys[new_location.coord].lit = true
    grid_keys[new_location.coord].free = false
    key.x = new_location.x
    key.y = new_location.y
    key.coord = new_location.coord
  end
  print("translated tetra  " .. tetra.pattern)
  parse_groups(tetra)
end

-------------------------------------------------------------------------------
--- get_pressed_tetras() returns a list of tetras that are currently pressed
-------------------------------------------------------------------------------
function get_pressed_tetras()
  local pressed_tetras = {}
  for i, tetra in ipairs(tetras) do
    if tetra.pressed then
      table.insert(pressed_tetras, tetra)
    end
  end
  return pressed_tetras
end

-------------------------------------------------------------------------------
--- get_pressed_tetra_key() returns the key that is pressed in a tetra
--- if multiple keys are pressed, it returns the first key that is pressed
-------------------------------------------------------------------------------
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




-------------------------------------------------------------------------------
--- build the scale
-------------------------------------------------------------------------------
function build_scale()
  scale_notes = music.generate_scale(params:get("root_note"), params:get("scale"), params:get("scale_octaves")) -- builds scale
  --- print all the notes in the scale
  print("--- scale notes ---")
  for i, note in ipairs(scale_notes) do
    print(music.note_num_to_name(note, true))
  end
end

-------------------------------------------------------------------------------
--- given a note, return the the next note in the scale
-------------------------------------------------------------------------------
function get_next_note_in_scale(note)
  note = music.snap_note_to_array(note, scale_notes)
  for i, scale_note in ipairs(scale_notes) do
    if scale_note == note then
      --- if the note is the last note in the scale, return the last note
      if i == #scale_notes then
        return scale_notes[#scale_notes]
      else
        return scale_notes[i + 1]
      end
    end
  end
end
-------------------------------------------------------------------------------
--- given a note, return the the next note in the scale
-------------------------------------------------------------------------------
function get_previous_note_in_scale(note)
  note = music.snap_note_to_array(note, scale_notes)
  for i, scale_note in ipairs(scale_notes) do
    if scale_note == note then
      --- if the note is the first note in the scale, return the first note
      if i == 1 then
        return scale_notes[1]
      else
        return scale_notes[i - 1]
      end
    end
  end
end
-------------------------------------------------------------------------------
--- get a random note from the scale
-------------------------------------------------------------------------------
function get_random_note_in_scale()
  --- get a random note from the middle third section of the scale
  --- to avoid excessively high or low notes
  local start = math.floor(#scale_notes / 3)
  local stop = math.floor(2 * #scale_notes / 4)
  local note = scale_notes[math.random(start, stop)]
  return note
end
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
--- norns controls event handlers
-------------------------------------------------------------------------------
--- encoder 
-------------------------------------------------------------------------------
function enc(e, d) --------------- enc() is automatically called by norns

  local enc_config = encoder_config[string.sub(focus_tetra.pattern, 1, 1)]

  if focus_tetra ~= nil then
    if e == 1 then 
        for i = 1, math.abs(d) do
          if d > 0 then
            focus_tetra.engine_note = get_next_note_in_scale(focus_tetra.engine_note)
          else
            focus_tetra.engine_note = get_previous_note_in_scale(focus_tetra.engine_note)
          end
        end
    elseif e == 2 then      
      local e2_inc = enc_config.e2_step * d
      local e2_min = enc_config.e2_min
      local e2_max = enc_config.e2_max
      local e2_value = util.clamp(params:get(enc_config.e2_param) + e2_inc, e2_min, e2_max)
      params:set(enc_config.e2_param, e2_value)
      focus_tetra.engine_config.patch[enc_config.e2_param] = e2_value
    elseif e == 3 then
      local e3_inc = enc_config.e3_step * d
      local e3_min = enc_config.e3_min
      local e3_max = enc_config.e3_max
      local e3_value = util.clamp(params:get(enc_config.e3_param) + e3_inc, e3_min, e3_max)
      params:set(enc_config.e3_param, e3_value)
      focus_tetra.engine_config.patch[enc_config.e3_param] = e3_value
    end
  
    --- if focus_tetra is playing, update the note to hear the result of the change
    if focus_tetra.playing then
      print("playing")
      play_tetra(focus_tetra)
    end

    screen_dirty = true
  end
end

-------------------------------------------------------------------------------
--- keys 
-------------------------------------------------------------------------------
function key(k, z) ------------------ key() is automatically called by norns
  if z == 0 then return end --------- do nothing when you release a key

  if k == 2 then 
  elseif k == 3 then
  end
  
  screen_dirty = true --------------- something changed
end

-------------------------------------------------------------------------------
function press_down(i)
  message = "press down " .. i -- build a message
end
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--- grid display functions
-------------------------------------------------------------------------------
function grid_redraw()
  g:all(0)

  --- draw the tetras
  for i, tetra in ipairs(tetras) do
    for j, key in ipairs(tetra.keys) do
      if tetra.pressed then
        tetra.level = 13
      elseif tetra == focus_tetra then
        if tetra.playing then
          tetra.level = 15
        else
          tetra.level = 10
        end
      elseif tetra.playing then
        tetra.level = 15
      else 
        tetra.level = 3
      end
      g:led(key.x, key.y, tetra.level)
    end
  end
  
  --- draw the free keys and pressed locations
  for coord, grid_key in pairs(grid_keys) do
    local x, y, pressed, lit, free = grid_key.x, grid_key.y, grid_key.pressed, grid_key.lit, grid_key.free
    if lit then
      if free then
        g:led(x, y, 15)
      end
    else
      g:led(x, y, 0)
    end
  end

  g:refresh()

end
-------------------------------------------------------------------------------
function sequence_clock()
  while true do
    --- sync to the clock
    clock.sync(1)
    for i, group in ipairs(groups) do
      if group.current_tetra_index == nil then
        group.current_tetra_index = 1
      else
        --- advance by 1, unless at the end of the group
        stop_tetra(group.tetras[group.current_tetra_index])
        group.current_tetra_index = group.current_tetra_index + 1
        if group.current_tetra_index > #group.tetras then
          group.current_tetra_index = 1
        end
      end

      play_tetra(group.tetras[group.current_tetra_index])

      grid_dirty = true
    end
  end
end
-------------------------------------------------------------------------------
function grid_redraw_clock()
  while true do
    if grid_dirty then
      grid_redraw()
      grid_dirty = false
    end
    clock.sleep(1/30)
  end
end

-------------------------------------------------------------------------------
--- screen display functions
-------------------------------------------------------------------------------
function screen_redraw_clock() ----- a clock that draws space
  while true do ------------- "while true do" means "do this forever"
    clock.sleep(1/15) ------- pause for a fifteenth of a second (aka 15fps)
    if screen_dirty then ---- only if something changed
      redraw() -------------- redraw space
      screen_dirty = false -- and everything is clean again
    end
  end
end
-------------------------------------------------------------------------------
--- redraw() is called by screen_redraw_clock()
--- and also automatically by norns when the script comes back into focus
--- after exiting the norns menu, it also prevents it from being called
--- while in the menu
-------------------------------------------------------------------------------
function redraw()
  
  local message = "X"
  local message2 = "X"

  if focus_tetra ~= nil then
    message = (focus_tetra.pattern .. " " .. music.note_num_to_name(focus_tetra.engine_note, true))
    
    -- local value2, value3 = 0
    -- local param2, param3 = ""

    -- if enc_modes[enc_mode] == "filter" then
    --   param2 = "cut"
    --   value2 = focus_tetra.engine_cut
    --   param3 = "noise"
    --   value3 = focus_tetra.engine_noise
    -- elseif  enc_modes[enc_mode] == "wave" then
    --   param2 = "timbre"
    --   value2 = focus_tetra.engine_timbre
    --   param3 = "shape"
    --   value3 = focus_tetra.engine_shape
    -- elseif  enc_modes[enc_mode] == "envelope" then
    --   param2 = "attack"
    --   value2 = focus_tetra.engine_attack
    --   param3 = "release"
    --   value3 = focus_tetra.engine_release     
    -- end

    -- message2 = (param2 .. " " .. value2 .. " " .. param3 .. " " .. value3)
  end

  screen.clear() --------------- clear space
  screen.aa(1) ----------------- enable anti-aliasing
  screen.font_face(1) ---------- set the font face to "04B_03"
  screen.font_size(8) ---------- set the size to 8
  screen.level(15) ------------- max
  screen.move(64, 32) ---------- move the pointer to x = 64, y = 32
  screen.text_center(message) -- center our message at (64, 32)
  screen.move(64, 42)
  screen.text_center(message2)
  screen.pixel(0, 0) ----------- make a pixel at the north-western most terminus
  screen.pixel(127, 0) --------- and at the north-eastern
  screen.pixel(127, 63) -------- and at the south-eastern
  screen.pixel(0, 63) ---------- and at the south-western
  screen.fill() ---------------- fill the termini and message at once
  screen.update() -------------- update space
end
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--- debug functions
-------------------------------------------------------------------------------
--- print the state of the grid, with a visual representation of the key state
--- 'a' for lit false, 'A' for lit true, 
--- 'p' for pressed false, 'P' for pressed true
--- 'f' for free false, 'F' for free true
-------------------------------------------------------------------------------
function print_grid()
  local w, h = g.cols, g.rows
  for y = 1, h do
    local line = ""
    for x = 1, w do
      local coord = x .. "," .. y
      local key = grid_keys[coord]
      if key.lit then
          line = line .. "A"
      else
          line = line .. "a"
      end
      if key.pressed then
        line = line .. "P"
      else
        line = line .. "p"
      end
      if key.free then
        line = line .. "F"
      else
        line = line .. "f"
      end
      line = line .. " "
    end
    print(line)
  end
end
-------------------------------------------------------------------------------
--- print out groups and their tetras
-------------------------------------------------------------------------------
function print_groups()
  print ('--- groups ---')
  for i, group in ipairs(groups) do
    print("group " .. i)
    for j, group_tetra in ipairs(group.tetras) do
      print("  " .. group_tetra.pattern)
    end
  end
  print ('--------------')
end
-------------------------------------------------------------------------------
--- execute r() in the repl to quickly rerun this script
-------------------------------------------------------------------------------
function r() 
  norns.script.load(norns.state.script) 
end
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--- cleanup() is automatically called by norns on script exit
-------------------------------------------------------------------------------
function cleanup() 
  engine.stopAll()
  clock.cancel(screen_redraw_clock_id)
  clock.cancel(grid_redraw_clock_id)
  clock.cancel(sequence_clock_id)
end
