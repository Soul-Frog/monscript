extends Player

const SPEED = 110 # Movement speed
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_FALL_SPEED = GRAVITY/2 #maximum speed the player can be falling
const JUMP_VELOCITY = -271.0 #this is ~56 pixels high with current gravity

func _physics_process(delta): 
	if can_move:
		# Add the gravity.
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		
		# Cap maximum fall speed
		if velocity.y >= MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

		# Handle Jump on space or up.
		if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("up"))and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		# pass through 1ways
		if is_on_floor() and Input.is_action_just_pressed("down"):
			position.y += 1

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		move_and_slide()
