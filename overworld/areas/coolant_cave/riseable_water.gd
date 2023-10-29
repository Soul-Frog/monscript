extends Sprite2D

func _ready():
	# connect ourself so we can see when the water level changes
	Events.coolant_cave_water_level_changed.connect(_on_water_changed)
	
	# set the max alpha of the fade based on the alpha of water in editor
	if find_child("FadeDecorator"):
		$FadeDecorator.max_alpha = modulate.a
	
	_update_collisions() # set collisions on/off based on initial state
	
	# hide water if it's lowered, otherwise leave it in default state (raised)
	if not GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED):
		modulate.a = 0

# update water collision (enable if up, disable if down)
func _update_collisions():
	if find_child("WaterCollision"):
		for collision_shape in $WaterCollision.get_children():
			collision_shape.disabled = not GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED)

func _on_water_changed():
	_update_collisions()
	
	# fade the water in/out depending on if it's up/down
	if find_child("FadeDecorator"):
		$FadeDecorator.fade_in() if GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED) else $FadeDecorator.fade_out()
