class_name MonScene
extends CharacterBody2D

func get_texture() -> Texture2D:
	return $Sprite.sprite_frames.get_frame_texture("default", 0)
