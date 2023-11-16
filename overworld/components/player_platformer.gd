class_name PlayerPlatformer
extends Player

const SPEED = 110 # Movement speed
const FRICTION = 20 # How quickly the player stops moving when direction is released
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_FALL_SPEED = GRAVITY/2.0 #maximum speed the player can be falling
const JUMP_VELOCITY = -271.0 #this is ~56 pixels high with default gravity

var SWIM_SPEED = SPEED/1.5
var SWIM_GROUNDED_SPEED = SPEED/3.0
var SWIM_GRAVITY = GRAVITY/4.0
var MAX_SWIM_FALL_SPEED = SWIM_GRAVITY/2.0
const SWIM_JUMP_VELOCITY = JUMP_VELOCITY/2.0 # jump velocity in water
const SWIM_TOPWATER_JUMP_VELOCITY = JUMP_VELOCITY/1.2 # jump velocity while exiting water

var is_swimming = false # if the player is in water
var is_topwater = false # if the player is swimming but near the top of the water

func _physics_process(delta): 
	if can_move:
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
		
		#TODO - walk really slow if grounded
		
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Cap maximum fall speed
		if velocity.y >= max_fall_speed:
			velocity.y = max_fall_speed

		# Handle Jump on space or up.
		if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("up")) and (is_on_floor() or is_swimming):
			velocity.y = jump_velocity
		
		# pass through 1 ways by pressing down
		if is_on_floor() and Input.is_action_just_pressed("down"):
			position.y += 1

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION)
			
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
