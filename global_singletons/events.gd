extends Node

# called to signal start of battle; usually overworld encounter collision
# but can also be used outside of that
signal battle_started

# called to signal that the current battle has ended
signal battle_ended

# called to signal an area change, usually by warp
signal area_changed

# called when the water level changes in coolant cave
signal coolant_cave_water_level_changed

# called when customization color is changed by clicking on customization button
signal recolor_player_sprite
