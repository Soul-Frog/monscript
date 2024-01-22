class_name MonScene
extends CharacterBody2D

func get_headshot() -> Texture2D:
	assert($Sprite.sprite_frames.has_animation("headshot"))
	return $Sprite.sprite_frames.get_frame_texture("headshot", 0)

func get_texture() -> Texture2D:
	assert($Sprite.sprite_frames.has_animation("default"))
	return $Sprite.sprite_frames.get_frame_texture("default", 0)



func move_to_point() -> void:
	pass
