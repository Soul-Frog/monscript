class_name SelectableButton
extends TextureButton

@export var texture_selected: Texture2D
@export var texture_selected_hover: Texture2D
@export var texture_selected_pressed: Texture2D
@export var texture_unselected: Texture2D
@export var texture_unselected_hover: Texture2D
@export var texture_unselected_pressed: Texture2D
@export var selected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(texture_selected)
	assert(texture_selected_hover)
	assert(texture_unselected)
	assert(texture_selected)
	_update_textures()

func select():
	selected = true
	_update_textures()

func unselect():
	selected = false
	_update_textures()

func _update_textures():
	texture_normal = texture_selected if selected else texture_unselected
	texture_pressed = texture_selected_pressed if selected else texture_unselected_pressed
	texture_hover = texture_selected_hover if selected else texture_unselected_hover

func _on_pressed():
	select()
