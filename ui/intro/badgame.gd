extends Node2D

signal fallen

@onready var CHARACTER = $PlatformerCharacter

func reset():
	CHARACTER.reset()
	
func disable():
	CHARACTER.disable()

func enable():
	CHARACTER.enable()


func _on_fallen_area_body_entered(body):
	print("fell")
	emit_signal("fallen")
	reset()
