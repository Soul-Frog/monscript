class_name VNClickable
extends Area2D

signal clicked

@export var examine_dialogue: String = ""

var mouse_hovered = false

func _ready():
	assert(examine_dialogue != "", "Forgot to assign dialogue to this clickable.")
	# track when the mouse enters or exits this clickable
	mouse_entered.connect(func(): mouse_hovered = true)
	mouse_exited.connect(func(): mouse_hovered = false)

func _input(event: InputEvent):
	if mouse_hovered and event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", examine_dialogue)
