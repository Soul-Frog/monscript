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

# called when customization is updates by clicking on customization buttons
signal update_player_sprite
