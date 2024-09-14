---TETRA ><>
---github.com/nvillar/tetra/
---k1: exit
---k2: ratchet |  k2 + k3:   |
---k3: interval | start/stop |
---e1: pitch
---e2: length
---e3: volume

--- requires
UI = require("ui")
music = require("musicutil")
nb = include("lib/nb/lib/nb")

--- list of shapes for tetras
shapes = {'O', 'I', 'T', 'S', 'Z', 'J', 'L'}

--- patterns for tetras of each shape
--- some shape have multiple orientations
patterns = {
  ["O0"]   = {{1,1}, {1,2}, {2,1}, {2,2}},    -- Square
  ["I0"]   = {{1,1}, {1,2}, {1,3}, {1,4}},    -- Line
  ["I90"]  = {{1,1}, {2,1}, {3,1}, {4,1}},
  ["Z0"]   = {{1,1}, {2,1}, {2,2}, {3,2}},    -- Z
  ["Z90"]  = {{1,1}, {1,2}, {0,2}, {0,3}},
  ["S0"]   = {{1,1}, {2,1}, {2,0}, {3,0}},    -- S
  ["S90"]  = {{1,1}, {1,2}, {2,2}, {2,3}},     
  ["T0"]   = {{1,1}, {2,1}, {3,1}, {2,2}},    -- T
  ["T90"]  = {{1,1}, {1,2}, {1,3}, {0,2}},
  ["T180"] = {{1,1}, {2,1}, {3,1}, {2,0}},  
  ["T270"] = {{1,1}, {1,2}, {1,3}, {2,2}},
  ["L0"]   = {{1,1}, {1,2}, {1,3}, {2,3}},    -- L
  ["L90"]  = {{1,1}, {2,1}, {3,1}, {1,2}},
  ["L180"] = {{1,1}, {2,1}, {2,2}, {2,3}},
  ["L270"] = {{1,1}, {2,1}, {3,1}, {3,0}},
  ["J0"]   = {{1,1}, {1,2}, {1,3}, {0,3}},    -- J
  ["J90"]  = {{1,1}, {2,1}, {3,1}, {3,2}},
  ["J180"] = {{1,1}, {2,1}, {1,2}, {1,3}},
  ["J270"] = {{1,1}, {2,1}, {3,1}, {1,0}},
}

--- list of grid keys, indexed by a coordinate in the format "x,y"
--- each key has the following states, which can be true or false:
--- pressed: true if the key is currently pressed
--- lit: true if the key light is lit
--- unclaimed: true if the key is lit and not part of a tetra
grid_keys = {}
--- list of tetras
tetras = {}
--- currently focused tetra
focus_tetra = nil
--- list of groups
groups = {}
--- list of notes in current scale
scale_notes = {}
--- max length of a tetra in beats
max_length_beats = 4
--- max volume of a tetra
max_volume = 2.00
--- max ratchet value
max_ratchet = 4
--- max interval value
max_interval = 4
--- number of keys that need to be pressed simultaneously
--- on a tetra in order to delete it
delete_keypress = 3
--- number of midi voices for n.b. engine
nb.voice_count = 1
--- state of the sequencer playback
sequencer_playing = true
--- current fractional beat
fractional_beat = 1
--- ui dials
dials = {}
--- enable screen anti-aliasing
screen.aa(1)
--- connect to the grid
g = grid.connect()

-------------------------------------------------------------------------------
--- init() is automatically called by norns
-------------------------------------------------------------------------------

function init() 
 
  nb:init()
  message = "TETRA"
  screen_dirty = true 
  screen_redraw_clock_id = clock.run(screen_redraw_clock)
  grid_redraw_clock_id = clock.run(grid_redraw_clock) 
  sequencer_clock_id = clock.run(sequencer_clock)

  local scale_names = {}
  for i = 1, #music.SCALES do
    table.insert(scale_names, music.SCALES[i].name)
  end

  params:add_separator("scale_params", "scale")
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

  params:add_separator("shape_params", "shapes")
  for i, shape in ipairs(shapes) do
    nb:add_param(shape, shape) 
  end
  
  params:add_separator("voice_params", "voices")
  nb:add_player_params()
  
  --- x, y, size, value, min_value, max_value, rounding, start_value, markers, units, title
  dials[1] = UI.Dial.new(10, 6, 22, 0, 0.0, 1.0, 0, 0, {},'','note')
  dials[2] = UI.Dial.new(59, 6, 22, 0, 0.0, 1.0, 0, 0, {},'','length')
  dials[3] = UI.Dial.new(94, 6, 22, 0, 0.0, 1.0, 0, 0, {},'','volume')  

  reset()

  params:default()
end


-------------------------------------------------------------------------------
--- reset the state of the grid, stop all notes,
--- clear all tetras, reset the grid_keys table
-------------------------------------------------------------------------------
function reset()
  local w, h = g.cols, g.rows
  print('--- reset ---')

  note_stop_all()

  grid_keys = {}
  focus_tetra = nil
  --- init grid_keys table
  for x = 1, w do
    for y = 1, h do
      local coord = x .. "," .. y
      grid_keys[coord] = {x = x, y = y, pressed = false, lit = false, unclaimed = false}
    end
  end
  tetras = {}
  groups = {}
  fractional_beat = 1
  grid_dirty = true
  screen_dirty = true
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
  
  --- process keys that are pressed and determine if they are lit or unclaimed
  --- turn key off if: it is unclaimed, pressed and lit
  if grid_keys[coord].lit 
        and grid_keys[coord].unclaimed 
        and pressed then
    grid_keys[coord].lit = false
    grid_keys[coord].unclaimed = false --- unclaimable

  --- turn key on if is off and pressed, but only if 
  --- no tetras are pressed, otherwise be considered a translation,
  --- a condition that is handled further down the code
  elseif not grid_keys[coord].lit 
      and #get_pressed_tetras() == 0
      and pressed then
    grid_keys[coord].lit = true
    grid_keys[coord].unclaimed = true
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
    --- trigger all encoders with no deltas to update the ui dials
    enc(0, 0)
    print("focus " .. pressed_tetras[1].pattern)
  end

  --- if a tetra is pressed and a available key is pressed, translate the tetra
  if pressed and #pressed_tetras == 1 and not grid_keys[coord].lit then
    local tetra = pressed_tetras[1]
    if is_valid_location(tetra, grid_keys[coord]) then
      translate_tetra(tetra, grid_keys[coord])
    end
  --- if no tetras are pressed, reset the focus
  elseif pressed and #pressed_tetras == 0 then
    focus_tetra = nil
    screen_dirty = true
  end

  --- start playing pressed tetras if they are not already playing
  --- stop playing tetras that are not pressed
  for i, tetra in ipairs(tetras) do
    if tetra.pressed  then
      note_on(tetra)
    elseif not tetra.pressed and tetra.playing then
      note_off(tetra)
    end
  end

  grid_dirty = true
  -- screen_dirty = true
end

-------------------------------------------------------------------------------
--- note_play() plays a tetra with the n.b. engine associated 
--- with the tetra, if any, for the length of the tetra, then stops the note
-------------------------------------------------------------------------------
function note_play(tetra)
  --- get first character of tetra.pattern to determine the voice_id
  local id = string.sub(tetra.pattern, 1, 1)
  local player = params:lookup_param(id):get_player()

  if player ~= nil then
    --- don't play the note at all if the length is 0
    --- to allow for long monophonic notes to play without being cut off
    if tetra.length_beats > 0 then
      local length_sec = clock.get_beat_sec () * tetra.length_beats
      player:play_note(tetra.note, tetra.volume, length_sec)
    end    
    tetra.playing = true
  end  
end

-------------------------------------------------------------------------------
--- note_on() starts playing a tetra with the n.b. engine associated
--- with the tetra, if any
-------------------------------------------------------------------------------
function note_on(tetra)
  --- get first character of tetra.pattern to determine the voice_id
  local id = string.sub(tetra.pattern, 1, 1)
  local player = params:lookup_param(id):get_player()

  if player ~= nil then
    player:note_on(tetra.note, tetra.volume)
    tetra.playing = true
  end
end

-------------------------------------------------------------------------------
--- note_off() stops playing a tetra with the n.b. engine associated
--- with the tetra, if any
-------------------------------------------------------------------------------
function note_off(tetra)
  --- get first character of tetra.pattern to determine the voice_id
  local id = string.sub(tetra.pattern, 1, 1)
  local player = params:lookup_param(id):get_player()

  if player ~= nil then
    player:note_off(tetra.note)
    tetra.playing = false
  end
end

-------------------------------------------------------------------------------
--- stop all notes on all players
-------------------------------------------------------------------------------
function note_stop_all()
  for i, voice_id in ipairs(shapes) do
    local player = params:lookup_param(voice_id):get_player()
    if player ~= nil then
      player:stop_all()
    end
  end
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
  -- print_groups()
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
--- by grid keys that lit and unclaimed (not already part of a tetra)
--- if a tetra is found, it is added to the list of tetras 
--- and the keys are marked as unclaimed = false (claimed by the tetra)
-------------------------------------------------------------------------------
function parse_tetras()
  --- check if a tetra is present in the grid
  for pattern_name, pattern in pairs(patterns) do
    for coord, grid_key in pairs(grid_keys) do
      local x, y, unclaimed = grid_key.x, grid_key.y, grid_key.unclaimed
      --- a tetra can only be formed from unclaimed keys
      if unclaimed then
        --- check if the pattern matches a set of lit, unclaimed keys
        for i, pattern_key in ipairs(pattern) do
          local pattern_x, pattern_y = pattern_key[1], pattern_key[2]
          local tetra_key_x, tetra_key_y = x - pattern_x + 1, y - pattern_y + 1
          local tetra_key_coord = tetra_key_x .. "," .. tetra_key_y
          --- if the key is not present in the grid or is not lit and unclaimed, break
          if grid_keys[tetra_key_coord] == nil or not grid_keys[tetra_key_coord].unclaimed or not grid_keys[tetra_key_coord].lit then
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
--- a tetra is considered 'new' when it is first created, and up until it is 
--- first released. this 'new' state allows the tetra to be created by pressing 
--- multiple buttons simulataneously - a gesture normally reserved for deleting
--- so the tetra would be deleted immediately after it is created in this way
-------------------------------------------------------------------------------
function create_tetra(pattern_name, keys)

  local tetra = {}

  --- default across all tetras
  --- can be ovewritten by each tetra.pattern
  tetra.new = true
  tetra.pressed = false
  tetra.pattern = pattern_name
  tetra.keys = keys
  tetra.playing = false
  tetra.note = get_random_note_in_scale()
  tetra.length_beats = 1
  tetra.volume = 1.0
  tetra.ratchet = 1
  tetra.interval = 1

  print("created tetra " .. tetra.pattern)

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
          grid_keys[key.coord].unclaimed = false
        end
        --- tetra would have been focused, so reset focus
        focus_tetra = nil

        --- delete the tetra        
        print("deleting tetra " .. tetra.pattern)     
        note_off(tetra)   
        table.remove(tetras, i)  
        parse_groups(tetra)
        screen_dirty = true
        break
        
      else
        tetra.pressed = true
        i = i + 1
      end
    else
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
--- and if the new location is not occupied by another tetra or a lit+unclaimed key
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
        print("self overlap")
        self_overlap = true
      end
    end

    --- check if the new location is not occupied by an lit/unclaimed key or another tetra,
    if (grid_keys[new_coord].lit or grid_keys[new_coord].unclaimed) and not self_overlap then
      print ("occupied")
      print ("for tetra key at " .. key.x .. "," .. key.y .. " new coord: " .. new_coord .. " is lit: " .. tostring(grid_keys[new_coord].lit) .. ", unclaimed: " .. tostring(grid_keys[new_coord].unclaimed))
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
    grid_keys[key.coord].unclaimed = false
  end

  -- update the keys at the new locations
  for i, key in ipairs(tetra.keys) do
    local new_location = new_locations[i]
    grid_keys[new_location.coord].lit = true
    grid_keys[new_location.coord].unclaimed = false
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
--- get_tetra_coords() returns the x,y coordinate of the middle of a tetra
-------------------------------------------------------------------------------
function get_tetra_coords(tetra)
  local coord = {x = 0, y = 0}

  for i, key in ipairs(tetra.keys) do
    coord.x = coord.x + key.x
    coord.y = coord.y + key.y
  end
  coord.x = coord.x / #tetra.keys
  coord.y = coord.y / #tetra.keys

  if coord.x < g.cols  / 2 then
    coord.x = math.floor(coord.x)
  else
    coord.x = math.ceil(coord.x)
  end

  if coord.y < g.rows / 2 then
    coord.y = math.floor(coord.y)
  else
    coord.y = math.ceil(coord.y)
  end

  return coord
end


-------------------------------------------------------------------------------
--- build the scale
-------------------------------------------------------------------------------
function build_scale()
  scale_notes = music.generate_scale(params:get("root_note"), params:get("scale"), params:get("scale_octaves")) -- builds scale
  --- print all the notes in the scale
  -- print("--- scale notes ---")
  -- for i, note in ipairs(scale_notes) do
  --   print(music.note_num_to_name(note, true))
  -- end
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
--- enc() is automatically called by norns
--- calling enc() with a e value of 0 will force all dials to update 
-------------------------------------------------------------------------------
function enc(e, d) --------------- enc() is automatically called by norns
  if focus_tetra ~= nil then    
    
    if e == 0 or e == 1 then 
        if focus_tetra.playing then
          note_off(focus_tetra)
        end

        for i = 1, math.abs(d) do
          if d > 0 then
            focus_tetra.note = get_next_note_in_scale(focus_tetra.note)
          else
            focus_tetra.note = get_previous_note_in_scale(focus_tetra.note)
          end
        end

        dials[1]:set_value(math.abs(focus_tetra.note - scale_notes[1]) / (scale_notes[#scale_notes] - scale_notes[1]))
        dials[1].title = music.note_num_to_name(focus_tetra.note, true)
    end 
    
    if e == 0 or e == 2 then
      --- duration of the tetra note in beats, when played by a sequencer      
      focus_tetra.length_beats = util.clamp(focus_tetra.length_beats + d * (max_length_beats / 24), 0, max_length_beats)     
      --- normalize the value to 0-1 for the dial
      dials[2]:set_value(focus_tetra.length_beats / max_length_beats)
    end

    if e == 0 or e == 3 then      
      focus_tetra.volume = util.clamp(focus_tetra.volume + d * (max_volume / 50), 0, max_volume)
      --- TODO: update the default shape velocity so that new tetras have the same values   \
      --- normalize the value to 0-1 for the dial
      dials[3]:set_value(focus_tetra.volume / max_volume)
      
    end

    --- if focus_tetra is still pressed, play the note with new values
    if focus_tetra.pressed then
      note_play(focus_tetra)
    end

    --- update the screen
    screen_dirty = true
  end
end


-------------------------------------------------------------------------------
--- keys 
-------------------------------------------------------------------------------

k2_hold = false
k3_hold = false

function key(k, z) ------------------ key() is automatically called by norns

  if z == 1 then --- key pressed

    if k == 2 then
      k2_hold = true
    elseif k == 3 then
      k3_hold = true
    end

    if k2_hold and k3_hold then
      sequencer_playing = not sequencer_playing
      note_stop_all()
      focus_tetra = nil
      grid_dirty = true
    end
    
    screen_dirty = true      

  else 

    if k == 2 then
      k2_hold = false
    elseif k == 3 then
      k3_hold = false
    end

    if focus_tetra ~= nil then
      if k == 2 then
        focus_tetra.ratchet = focus_tetra.ratchet + 1
        if focus_tetra.ratchet > max_ratchet then
          focus_tetra.ratchet = 1
        end
      elseif k == 3 then
        focus_tetra.interval = focus_tetra.interval + 1
        if focus_tetra.interval > max_interval then
          focus_tetra.interval = 1
        end
      end
    end
  
    screen_dirty = true --------------- something changed

  end --------- do nothing when you release a key


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
      elseif tetra.playing then
        if tetra.length_beats > 0 then
          tetra.level = 15
        else
          tetra.level = 2
        end
      elseif tetra == focus_tetra then
        tetra.level = 10  
      else 
        tetra.level = 3
      end
      g:led(key.x, key.y, tetra.level)
    end
  end
  
  --- draw the unclaimed keys and pressed locations
  for coord, grid_key in pairs(grid_keys) do
    local x, y, pressed, lit, unclaimed = grid_key.x, grid_key.y, grid_key.pressed, grid_key.lit, grid_key.unclaimed
    if lit then
      if unclaimed then
        g:led(x, y, 15)
      end
    else
      g:led(x, y, 0)
    end
  end

  g:refresh()

end
-------------------------------------------------------------------------------
function sequencer_clock()
  
  while true do
    --- sync to the clock
    clock.sync(1/max_ratchet)    
    if sequencer_playing then
      
      for i, group in ipairs(groups) do

        advance_sequence(group)
        local tetra = group.tetras[group.tetra_sequence_index]
              
        if not tetra.pressed then
          tetra.playing = false
        end

        --- check whether the tetra should be played in this sequence iteration
        if group.sequence_iteration % tetra.interval == 0 then          
          if fractional_beat <= tetra.ratchet then
            note_play(tetra)
          end
        else
          --- skip playing the tetra and advance to the next
          advance_sequence(group)
          tetra = group.tetras[group.tetra_sequence_index]
          if fractional_beat <= tetra.ratchet then
            note_play(tetra)
          end
        end

        if fractional_beat == max_ratchet and not tetra.pressed then
          tetra.playing = false
        end

        grid_dirty = true
      end

      fractional_beat = fractional_beat + 1
      if fractional_beat > max_ratchet then
        fractional_beat = 1       
      end

    end
  end
end

-------------------------------------------------------------------------------
--- advance_sequence() advances the sequence of a group to the next tetra
--- if it gets to the end of the sequence, it loops back to the beginning
--- and increments the sequence iteration
-------------------------------------------------------------------------------
function advance_sequence(group)
  if group.tetra_sequence_index == nil then
    group.tetra_sequence_index = 1
    group.sequence_iteration = 1                  
  elseif fractional_beat == 1 then         
    --- advance by 1, loop back if at the end of the sequence
    group.tetra_sequence_index = group.tetra_sequence_index + 1
    if group.tetra_sequence_index > #group.tetras then
      group.tetra_sequence_index = 1

      --- advance the sequence iteration
      group.sequence_iteration = group.sequence_iteration + 1
      if group.sequence_iteration > max_interval then
        group.sequence_iteration = 1
      end    
    end        
  end
end


-------------------------------------------------------------------------------
--- grid_redraw_clock() is called whenever grid_dirty == true
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
  
  print("redraw")
  screen.clear() --------------- clear space
  screen.font_face(1)
  screen.update()

  if focus_tetra ~= nil then        
  
    screen.stroke()
    screen.level(15)
    screen.font_size(8) 
    screen.line_width(1)

    --- draw the dials

    if focus_tetra.length_beats == 0 then
      dials[2].title = "rest"
    else
      dials[2].title = "length"
    end

    for i = 1,3 do
      dials[i]:redraw()
    end
    
    --- draw the interval and ratchet buttons
    screen.line_width(0.5)
    
    screen.move(8, 54)
    screen.text_center("play")
    screen.stroke()

    screen.circle(27, 52, 7)
    screen.move(27, 54)
    screen.text_center(focus_tetra.ratchet)
    if k2_hold and not k3_hold then
      screen.fill()
    else
      screen.stroke()
    end

    screen.move(61, 54)
    screen.text_center("times every")
    screen.stroke()

    screen.circle(97, 52, 7)
    screen.move(97, 54)
    screen.text_center(focus_tetra.interval)

    if k3_hold and not k2_hold then
      screen.fill()
    else
      screen.stroke()
    end

    screen.move(118, 54)
    screen.text_center("loops")
    screen.stroke()
  
  else
    screen.level(15)
    screen.font_size(19) 
    screen.move(45, 37) 
    screen.text_center("TETRA")
    screen.line_width(2.5)
    screen.move(80, 26)
    screen.line_rel(15, 10)
    screen.line_rel(8, -5)
    screen.line_rel(-8, -5)
    screen.line_rel(-15, 10)
    if not sequencer_playing then
      screen.stroke()
    end
  end
  
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
--- 'f' for unclaimed false, 'F' for unclaimed true
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
      if key.unclaimed then
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
  reset()
  clock.cancel(screen_redraw_clock_id)
  clock.cancel(grid_redraw_clock_id)
  clock.cancel(sequencer_clock_id)
end
