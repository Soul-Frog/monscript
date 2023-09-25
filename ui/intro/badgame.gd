extends Node2D

signal fallen

@onready var CHARACTER = $PlatformerCharacter

const DESIGNED_BY_FORMAT = "Game designed by\n%s"

func update_name():
	$DesignedByLabel.text = DESIGNED_BY_FORMAT % GameData.PLAYER_NAME

func reset():
	CHARACTER.reset()
	
func disable():
	CHARACTER.disable()

func enable():
	CHARACTER.enable()

func bug_out():
	print("BUG ME")

func _on_fallen_area_body_entered(body):
	emit_signal("fallen")
