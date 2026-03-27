
bhk_sounds = {}

function bhk_sounds.default()
    return {
      footstep =  {name = "bhk_step_carpet", gain = 0.15, pitch = 1},
      dig =       {name = "bhk_step_carpet", gain = 1},
      dug =       {name = "bhk_step_carpet", gain = 1},
      place =     {name = "bhk_step_carpet", gain = 1},}
end
function bhk_sounds.carpet()
    return {
      footstep =  {name = "bhk_step_carpet", gain = 0.15, pitch = 1},
      dig =       {name = "bhk_step_carpet", gain = 1},
      dug =       {name = "bhk_step_carpet", gain = 1},
      place =     {name = "bhk_step_carpet", gain = 1},}
end
function bhk_sounds.concrete()
    return {
      footstep =  {name = "bhk_concrete_step", gain = 1, pitch = 1},
      dig =       {name = "bhk_step_carpet", gain = 1},
      dug =       {name = "bhk_step_carpet", gain = 1},
      place =     {name = "bhk_step_carpet", gain = 1},}
end
function bhk_sounds.steel()
    return {
      footstep =  {name = "bhk_concrete_step", gain = 1, pitch = 1},
      dig =       {name = "bhk_step_carpet", gain = 1},
      dug =       {name = "bhk_step_carpet", gain = 1},
      place =     {name = "bhk_step_carpet", gain = 1},}
end
function bhk_sounds.tile()
    return {
      footstep =  {name = "bhk_tile_step", gain = 1, pitch = 1},
      dig =       {name = "bhk_step_carpet", gain = 1},
      dug =       {name = "bhk_step_carpet", gain = 1},
      place =     {name = "bhk_step_carpet", gain = 1},}
end
function bhk_sounds.water()
  return {
    footstep =  {name = "bhk_water_step", gain = 1, pitch = 1},
    dig =       {name = "bhk_water_step", gain = 1},
    dug =       {name = "bhk_water_step", gain = 1},
    place =     {name = "bhk_water_step", gain = 1},}
end
