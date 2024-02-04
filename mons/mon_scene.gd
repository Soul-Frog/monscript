class_name MonScene
extends CharacterBody2D

# mon's speed while moving
@export var SPEED = 70

@onready var SPRITE = $Sprite

signal reached_point
var _target_point = null
var _time_blocked = 0.0
const _TIME_BLOCKED_BEFORE_GIVE_UP = 0.5

func _ready() -> void:
	update_sprite()
	Events.save_loaded.connect(update_sprite)
	Events.update_player_sprite.connect(update_sprite)

func update_sprite():
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR1", GameData.bitleon_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][0])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR2", GameData.bitleon_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][1])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR3", GameData.bitleon_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][2])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR4", GameData.bitleon_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][3])
	SPRITE.material.set_shader_parameter("BITLEON_RECOLOR5", GameData.bitleon_colors[int(GameData.get_var(GameData.SHIRT_CUSTOMIZATION_COLOR))][4])

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
	if _target_point != null: #todo hack
		var input_direction = Vector2.ZERO
		
		if _target_point != null:
			input_direction = Global.direction_towards_point(position, _target_point)
			
			if input_direction == Vector2.ZERO:
				_on_reached_point()
		
		velocity = SPEED * input_direction
		
		if velocity.x != 0:
			face_left() if velocity.x < 0 else face_right()
		
		var previous_position = position
		move_and_slide()
		
		# if we're trying to move to a point but get stuck, give up after some time
		if _target_point != null and previous_position == position:
			_time_blocked += delta
			if _time_blocked >= _TIME_BLOCKED_BEFORE_GIVE_UP:
				_on_reached_point()
			else:
				_time_blocked = 0.0

func _on_reached_point() -> void:
	_target_point = null
	emit_signal("reached_point")

func disable_collisions() -> void:
	$CollisionHitbox.disabled = true

func enable_collisions() -> void:
	$CollisionHitbox.disabled = false

func move_to_point(point: Vector2) -> void:
	_target_point = point
	_time_blocked = 0.0

func face_left() -> void:
	$Sprite.flip_h = true

func face_right() -> void:
	$Sprite.flip_h = false
