class_name SelectableButton
extends TextureButton

signal state_changed
signal button_selected
signal button_unselected

@export var texture_selected: Texture2D
@export var texture_selected_hover: Texture2D
@export var texture_selected_pressed: Texture2D
@export var texture_unselected: Texture2D
@export var texture_unselected_hover: Texture2D
@export var texture_unselected_pressed: Texture2D
@export var selected = false # if this button starts in the selected position
var _default_state
@export var toggleable = false # if this button can be toggled between states (or if it just goes from unselected->selected)

func _ready():
	assert(texture_selected)
	assert(texture_selected_hover)
	assert(texture_unselected)
	assert(texture_selected)
	self.pressed.connect(_on_pressed)
	_default_state = selected
	_update_textures()

func reset():
	if _default_state:
		select()
	else:
		unselect()

func select():
	selected = true
	_update_textures()
	emit_signal("state_changed")
	emit_signal("button_selected")

func unselect():
	selected = false
	_update_textures()
	emit_signal("state_changed")
	emit_signal("button_unselected")

func _update_textures():
	texture_normal = texture_selected if selected else texture_unselected
	texture_pressed = texture_selected_pressed if selected else texture_unselected_pressed
	texture_hover = texture_selected_hover if selected else texture_unselected_hover

func _on_pressed():
	if toggleable and selected:
		unselect()
	else:
		select()
