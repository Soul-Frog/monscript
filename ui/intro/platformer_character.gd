extends CharacterBody2D

const _SPEED = 60.0
const _JUMP_VELOCITY = -260.0

var _gravity = 800

var _enabled = true

@onready var _starting_position = position

@onready var _SPRITE = $Sprite

func reset():
	position = _starting_position

func enable():
	_enabled = true

func disable():
	_enabled = false

func offset_sprite(offset_vector: Vector2):
	_SPRITE.offset = offset_vector

func is_sprite_offset() -> bool:
	return _SPRITE.offset != Vector2.ZERO

func _physics_process(delta):
	if _enabled and visible:
		# Add the gravity.
		if not is_on_floor():
			velocity.y += _gravity * delta

		# Handle Jump.
		if Input.is_action_just_pressed("dash") and is_on_floor():
			velocity.y = _JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * _SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, _SPEED)

		move_and_slide()
