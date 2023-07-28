class_name DatabaseEntry
extends BoxContainer

signal clicked

var is_mouse_over := false

func set_texture(texture: Texture2D) -> void:
	$Free/SpriteContainer/MonSprite.texture = texture

func set_progress(progress: int) -> void:
	assert(progress >= 0 && progress <= 100, "Progress must be a percentage from 0-100%")
	$Free/ProgressBar.value = progress
	$Free/SpriteContainer/MonSprite.modulate = Global.COLOR_BLACK if $Free/ProgressBar.value != 100 else Global.COLOR_WHITE

func select():
	$BackgroundUnselected.visible = false
	$BackgroundSelected.visible = true

func unselect():
	$BackgroundUnselected.visible = true
	$BackgroundSelected.visible = false

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_mouse_over:
		emit_signal("clicked", self)


func _on_mouse_entered():
	is_mouse_over = true


func _on_mouse_exited():
	is_mouse_over = false
