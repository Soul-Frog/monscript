extends MarginContainer

signal clicked

var mouse_hovered = false

@onready var _LABEL = $Label

var _original_text: String
var _HOVER_FORMAT = "> %s <"

func _ready() -> void:
	_original_text = _LABEL.text
	
	# track when the mouse enters or exits this clickable
	mouse_entered.connect(func(): 
		mouse_hovered = true
		_LABEL.text = _HOVER_FORMAT % [_original_text]
	)
	mouse_exited.connect(func(): 
		mouse_hovered = false
		_LABEL.text = _original_text
	)
	
func _input(event: InputEvent) -> void:
	if mouse_hovered and event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked")
