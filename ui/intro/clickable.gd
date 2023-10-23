extends Area2D

signal clicked

@export var examine_dialogue: String = ""

@onready var _OUTLINE = $Outline

var mouse_hovered = false

func _ready() -> void:
	assert(examine_dialogue != "", "Forgot to assign dialogue to this clickable.")
	assert(_OUTLINE, "Didn't add outline child node to clickable!")
	# track when the mouse enters or exits this clickable
	mouse_entered.connect(func(): 
		mouse_hovered = true
		if _OUTLINE:
			_OUTLINE.activate()
	)
	mouse_exited.connect(func(): 
		mouse_hovered = false
		if _OUTLINE:
			_OUTLINE.deactivate()
	)

func _input(event: InputEvent) -> void:
	if mouse_hovered and event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", examine_dialogue)
