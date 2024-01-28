extends Node2D

# - All buttons are clickable already but we need to detect when it was clicked
# - One can be active at a time and show it visually, and report which color has been selected (getter)
# - Detect what button was clicked and print to console

@onready var active_button:TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_button = $Colors.get_child(0)
	_on_button_pressed(active_button)
	for child in $Colors.get_children():
		child.pressed.connect(_on_button_pressed.bind(child))
		child.mouse_entered.connect(_on_button_mouse_entered.bind(child))
		child.mouse_exited.connect(_on_button_mouse_exited.bind(child))

func _on_button_mouse_exited(child:TextureButton) -> void:
	child.z_index = 0

func _on_button_mouse_entered(child:TextureButton) -> void:
	if child != active_button:
		child.z_index = 1

func _on_button_pressed(child:TextureButton) -> void:
	active_button.disabled = false
	active_button = child
	active_button.z_index = 0
	var color = child.name
	$Indicator.position = active_button.position
	$Indicator.visible = true
	active_button.disabled = true
	
	