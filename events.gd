extends Node

# called to signal start of battle; usually overworld encounter collision
# but can also be used outside of that
signal battle_started

# called to signal that the current battle has ended
signal battle_ended

# called to signal an area change, usually by warp
signal area_changed

# called by player when colliding with overworld encounter
signal collided_with_overworld_encounter
