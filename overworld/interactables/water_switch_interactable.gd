extends Interactable

func _ready():
	super()
	
	# connect ourself to the signal so we can update when water changes
	Events.coolant_cave_water_level_changed.connect(_on_water_level_changed)
	
	# update sprite depending on water level
	_animate()
	_SPRITE.frame = _SPRITE.sprite_frames.get_frame_count(_SPRITE.animation) - 1 #set to last frame to skip actually playing animation

func _animate():
	_SPRITE.play("raise_water" if GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED) else "lower_water")

func _on_interact():
	# flip the water level
	GameData.set_var(GameData.COOLANT_CAVE_WATER_RAISED, not GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED))
	# signal that this has changed
	Events.emit_signal("coolant_cave_water_level_changed")

func _on_water_level_changed():
	_animate()
