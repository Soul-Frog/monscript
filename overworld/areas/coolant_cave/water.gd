extends Sprite2D

func _ready():
	# connect ourself so we can see when the water level changes
	Events.coolant_cave_water_level_changed.connect(_on_water_changed)

func _on_water_changed():
	print("Water is diff!")
