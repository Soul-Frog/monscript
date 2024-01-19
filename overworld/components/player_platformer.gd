class_name PlayerPlatformer
extends Player

const SPEED = 110.0 # Movement speed
const FRICTION = 20.0 # How quickly the player stops moving when direction is released
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_FALL_SPEED = GRAVITY/2.0 #maximum speed the player can be falling
const JUMP_VELOCITY = -271.0 #this is ~56 pixels high with default gravity

var SWIM_SPEED = SPEED/1.5
var SWIM_FRICTION = FRICTION/15.0
var SWIM_GROUNDED_SPEED = SPEED/3.0
var SWIM_GRAVITY = GRAVITY/4.0
var MAX_SWIM_FALL_SPEED = SWIM_GRAVITY/2.0
const SWIM_JUMP_VELOCITY = JUMP_VELOCITY/2.0 # jump velocity in water
const SWIM_TOPWATER_JUMP_VELOCITY = JUMP_VELOCITY/1.2 # jump velocity while exiting water

var is_swimming = false # if the player is in water
var is_topwater = false # if the player is swimming but near the top of the water

func _physics_process(delta): 
	if _can_move:
		# set the values to use depending on our current state
		var speed = SPEED
		if is_swimming:
			if is_on_floor():
				speed = SWIM_GROUNDED_SPEED
			else:
				speed = SWIM_SPEED
		var gravity = (SWIM_GRAVITY if is_swimming else GRAVITY)
		var max_fall_speed = (MAX_SWIM_FALL_SPEED if is_swimming else MAX_FALL_SPEED)
		var jump_velocity = (SWIM_TOPWATER_JUMP_VELOCITY if is_topwater else SWIM_JUMP_VELOCITY) if is_swimming or is_topwater else JUMP_VELOCITY
		var friction = (SWIM_FRICTION if (is_swimming and not is_on_floor()) else FRICTION)
		
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Cap maximum fall speed
		if velocity.y >= max_fall_speed:
			velocity.y = max_fall_speed

		# Handle Jump on space or up.
		var up_input = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("up")
		if _forced_movement and _forced_direction_vector.y != 0: # if a control is forced, overwrite the input with up/down depending on the force
			up_input = _forced_direction_vector.y > 0
		if (up_input and (is_on_floor() or is_swimming)): #attempt to jump
			velocity.y = jump_velocity
		
		# pass through 1 ways by pressing down
		var down_input = Input.is_action_just_pressed("down")
		if _forced_movement and _forced_direction_vector.y != 0:
			down_input = _forced_direction_vector.y < 0
		if down_input and is_on_floor():
			position.y += 1

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("left", "right")
		if _forced_movement and _forced_direction_vector.x != 0:
			direction = _forced_direction_vector.x
		
		
		if direction != 0:
			_SPRITE.flip_h = direction < 0
		
		if direction != 0 and not is_swimming:
			_SPRITE.play("walk")
		else:
			_SPRITE.play("stand")
		
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, friction)
			
		# TODO - apply external velocity (ex pushzones)
		# doesn't work correctly (adds too much since it adds it every frame we're being pushed, can't do it the same way as overhead)
		#velocity.x += external_velocity.x
		#velocity.y += external_velocity.y
		#external_velocity = Vector2.ZERO
		
		move_and_slide()

func notify_entered_water():
	is_swimming = true

func notify_exited_water():
	is_swimming = false

func notify_entered_topwater():
	is_topwater = true

func notify_exited_topwater():
	is_topwater = false
