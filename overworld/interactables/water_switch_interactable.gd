extends Interactable

#make this global l8r and also do some nice signal trix
var water_up = true

#in ready, connect to a switched signal
#

func _onInteract():
	water_up = not water_up
	_SPRITE.play("raise_water" if water_up else "lower_water")
