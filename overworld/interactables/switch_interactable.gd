extends Interactable

var water_up = true

func _onInteract():
	water_up = not water_up
	_SPRITE.play("raise_water" if water_up else "lower_water")
