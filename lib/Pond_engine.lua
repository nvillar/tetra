--- Based on the LiedMotor engine for norns by @willamthazard: 
--- https://github.com/williamthazard/schicksalslied/blob/main/lib/LiedMotor_engine.lua

local Pond = {}
local Formatters = require 'formatters'

-- first, we'll collect all of our commands into norns-friendly ranges
local specs = {
  ["sinfm_amp"] = controlspec.AMP,
  ["ringer_amp"] = controlspec.AMP,
  ["karplu_amp"] = controlspec.AMP,
  ["resonz_amp"] = controlspec.new(0, 100, "lin", 0, 0.2, ""),
  ["sinfm_modnum"] = controlspec.new(1, 100, "lin", 1, 1, ""),
  ["sinfm_modeno"] = controlspec.new(1, 100, "lin", 1, 1, ""),
  ["karplu_coef"] = controlspec.new(-1, 1, "lin", 0, 0.5, ""),
  ["sinfm_index"] = controlspec.new(-24, 24, "lin", 0, 0, ""),
  ["ringer_index"] = controlspec.new(0, 24, "lin", 0, 3, ""),
  ["karplu_index"] = controlspec.new(0, 24, "lin", 0, 3, ""),
  ["resonz_index"] = controlspec.new(0, 1, "lin", 0, 0.1, ""),
  ["sinfm_attack"] = controlspec.new(0.003, 8, "exp", 0, 0, "s"),
  ["sinfm_release"] = controlspec.new(0.003, 8, "exp", 0, 1, "s"),
  ["sinfm_phase"] = controlspec.PHASE,
  ["sinfm_pan"] = controlspec.PAN,
  ["ringer_pan"] = controlspec.PAN,
  ["karplu_pan"] = controlspec.PAN,
  ["resonz_pan"] = controlspec.PAN
}

-- this table establishes an order for parameter initialization:
local param_names = {"sinfm_attack","sinfm_release","sinfm_phase","sinfm_index","sinfm_modnum","sinfm_modeno","sinfm_amp","sinfm_pan","ringer_index","ringer_amp","ringer_pan","karplu_index","karplu_coef","karplu_amp","karplu_pan","resonz_index","resonz_amp","resonz_pan"}

-- initialize parameters:
function Pond.add_params()
  params:add_group("Pond",#param_names)

  for i = 1,#param_names do
    local p_name = param_names[i]
    params:add{
      type = "control",
      id = "Pond_"..p_name,
      name = p_name,
      controlspec = specs[p_name],
      formatter = p_name == "pan" and Formatters.bipolar_as_pan_widget or nil,      
      -- every time a parameter changes, we'll send it to the SuperCollider engine:
      action = function(x) engine[p_name](x) end
    }    
  end
  
 -- params:bang()
end

-- a single-purpose triggering command fire a note
-- function Pond.trigsinfm(hz)
--   if hz ~= nil then
--     engine.sinfm(hz)
--   end
-- end

-- function Pond.trigringer(hz)
--   if hz ~= nil then
--     engine.ringerhz(hz)
--   end
-- end

-- function Pond.trigkarplu(hz)
--   if hz ~= nil then
--     engine.karpluhz(hz)
--   end
-- end

-- function Pond.trigresonz(hz)
--   if hz ~= nil then
--     engine.resonzhz(hz)
--   end
-- end

 -- we return these engine-specific Lua functions back to the host script:
return Pond
