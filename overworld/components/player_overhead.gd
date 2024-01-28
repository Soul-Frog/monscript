class_name PlayerOverhead
extends Player

const SPEED = 150 # Movement speed
const FRICTION = 0.4
const ACCELERATION = 0.4

const DASH_DURATION = 0.05
const DASH_SPEED = SPEED * 4

var orientation = Vector2.ZERO # direction the player last moved; used for dash direction
var dashing = false # if the player is currently dashing

func _input(event):
	if event.is_action_released("dash"):
		dashing = true
		await Global.delay(DASH_DURATION)
		dashing = false

func _ready():
	assert(SPEED > 0)
	super._ready()

func update_velocity():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	# get inputs
	# if in a cutscene, move towards target if assigned. otherwise don't move
	if _in_cutscene:
		input_direction = Vector2.ZERO
		
		if _cutscene_movement_point != null:
			# see if we've gotten 'close enough' to the target point
			const THRESHOLD = 3.0
			var at_correct_x = abs(position.x - _cutscene_movement_point.x) <= THRESHOLD
			var at_correct_y = abs(position.y - _cutscene_movement_point.y) <= THRESHOLD
			
			if at_correct_x and at_correct_y: # if we reached it, emit and set target to null
				_cutscene_movement_point = null
				emit_signal("reached_point")
			else: #otherwise move towards
				if not at_correct_x:
					if position.x < _cutscene_movement_point.x:
						input_direction.x = 1
					else:
						input_direction.x = -1
				if not at_correct_y:
					if position.y < _cutscene_movement_point.y:
						input_direction.y = 1
					else:
						input_direction.y = -1
	
	# if any movement is forced, overwrite these inputs
	if _forced_movement:
		if _forced_direction_vector.x != 0:
			input_direction.x = _forced_direction_vector.x
		if _forced_direction_vector.y != 0:
			input_direction.y = _forced_direction_vector.y
	
	if input_direction != Vector2.ZERO:
		velocity = lerp(velocity, SPEED * input_direction, ACCELERATION)
		set_animation("walk")
		if input_direction.x != 0:
			face_left() if input_direction.x < 0 else face_right()
	else:
		velocity = lerp(velocity, Vector2.ZERO, FRICTION)
		set_animation("stand")
	
	# apply external velocity
	velocity.x += _external_velocity.x
	velocity.y += _external_velocity.y
	_external_velocity = Vector2.ZERO
	
	if dashing:
		velocity = DASH_SPEED * orientation
	if input_direction != Vector2.ZERO and not dashing: #update orientation
		orientation = input_direction

func _physics_process(delta):
	if _can_move:
		update_velocity()
		move_and_slide()
