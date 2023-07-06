class_name DatabaseEntry
extends HBoxContainer

func set_texture(texture: Texture2D) -> void:
	$MonSprite.texture = texture

func set_progress(progress: int) -> void:
	assert(progress >= 0 && progress <= 100, "Progress must be a percentage from 0-100%")
	$ProgressBar.value = progress
	$MonSprite.modulate = Global.COLOR_BLACK if $ProgressBar.value != 100 else Global.COLOR_WHITE
