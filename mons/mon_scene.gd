class_name MonScene
extends CharacterBody2D

# mon's speed while moving
@export var SPEED = 70

@onready var SPRITE = $Sprite

signal reached_point
var target_point = null

func _ready() -> void:
	update_sprite()
	Events.update_player_sprite.connect(update_sprite)

func update_sprite():
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR1", GameData.customization_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][0])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR2", GameData.customization_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][0])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR3", GameData.customization_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][0])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR4", GameData.customization_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][1])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR5", GameData.customization_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][1])

func set_animation(animation: String) -> void:
	assert($Sprite.sprite_frames.has_animation(animation))
	$Sprite.play(animation)

func get_headshot() -> Texture2D:
	assert($Sprite.sprite_frames.has_animation("headshot"))
	return $Sprite.sprite_frames.get_frame_texture("headshot", 0)

func get_texture() -> Texture2D:
	assert($Sprite.sprite_frames.has_animation("default"))
	return $Sprite.sprite_frames.get_frame_texture("default", 0)

func _physics_process(delta):
	var input_direction = Vector2.ZERO
	
	if target_point != null:
		input_direction = Global.direction_towards_point(position, target_point)
		
		if input_direction == Vector2.ZERO:
			target_point = null
			emit_signal("reached_point")
	
	velocity = SPEED * input_direction
	
	if velocity.x != 0:
		face_left() if velocity.x < 0 else face_right()
	
	move_and_slide()

func disable_collisions() -> void:
	$CollisionHitbox.disabled = true

func enable_collisions() -> void:
	$CollisionHitbox.disabled = false

func move_to_point(point: Vector2) -> void:
	target_point = point

func face_left() -> void:
	SPRITE.flip_h = true

func face_right() -> void:
	SPRITE.flip_h = false
