#an overworld mon which wanders around randomly
class_name Wanderer
extends OverworldMon

enum {
	MOVING_SOON, MOVING, IDLE
}

@export_group("Overworld Movement")
# how far the mon is allowed to wander when moving
@export var min_wander_range = 50
@export var max_wander_range = 150
# time the mon is stationary before attempting to move
@export var min_time_between_movement = 0
@export var max_time_between_movement = 0.2

var state = IDLE
var target = Vector2.ZERO

func _ready():
	super()
	_start_idling()

func _randomize_wander_target():
	var success = false
	var attempts = 0
	while not success and attempts <= 100: # try 100 times to find a valid movement
		attempts += 1
		
		# choose a random nearby point
		# generate a value within the set [-max_wander, -min_wander]U(min_wander, max_wander) for both x and y
		var x_movement = Global.RNG.randi_range(min_wander_range, max_wander_range) * (1 if Global.RNG.randi_range(0, 1) else -1)
		var y_movement = Global.RNG.randi_range(min_wander_range, max_wander_range) * (1 if Global.RNG.randi_range(0, 1) else -1)
		var movement = Vector2(x_movement, y_movement)
		var trial_target = position + movement
		
		# create a raycast from each corner of the rectangle; if none collide, movement is safe
		var col_mask = collision_mask
		
		var x_offset = $CollisionHitbox.shape.size.x / 2.0
		var y_offset = $CollisionHitbox.shape.size.y / 2.0
		var top_left_offset = Vector2(-x_offset, -y_offset)
		var top_right_offset = Vector2(x_offset, -y_offset)
		var bottom_left_offset = Vector2(-x_offset, y_offset)
		var bottom_right_offset = Vector2(x_offset, y_offset)
		var line_start = position + top_left_offset
		var line_end = trial_target + top_left_offset
		var line_start2 = position + top_right_offset
		var line_end2 = trial_target + top_right_offset
		var line_start3 = position + bottom_right_offset
		var line_end3 = trial_target + bottom_right_offset
		var line_start4 = position + bottom_left_offset
		var line_end4 = trial_target + bottom_left_offset
		var query_topleft = PhysicsRayQueryParameters2D.create(line_start, line_end, col_mask)
		var query_topright = PhysicsRayQueryParameters2D.create(line_start2, line_end2, col_mask)
		var query_bottomleft = PhysicsRayQueryParameters2D.create(line_start3, line_end3, col_mask)
		var query_bottomright = PhysicsRayQueryParameters2D.create(line_start4, line_end4, col_mask)
		
		var result_topleft = get_world_2d().direct_space_state.intersect_ray(query_topleft)
		if result_topleft:
			continue
		
		var result_topright = get_world_2d().direct_space_state.intersect_ray(query_topright)
		if result_topright:
			continue
			
		var result_bottomleft = get_world_2d().direct_space_state.intersect_ray(query_bottomleft)
		if result_bottomleft:
			continue
			
		var result_bottomright = get_world_2d().direct_space_state.intersect_ray(query_bottomright)
		if result_bottomright:
			continue
		
		target = trial_target
		
		# get direction vector and set velocity
		var direction = (target - position).normalized()
		velocity = SPEED * direction
		state = MOVING
		
		success = true
	
	if not success:
		pass
		# print("couldn't find a valid path for %s" % name)
		#if Global.DEBUG_CONSOLE:
		#	assert(success, "Couldn't find a valid path - check your maximum and minimum wander range")


func _start_idling():
	state = IDLE
	velocity = Vector2.ZERO
	var wait_time = Global.RNG.randf_range(min_time_between_movement, max_time_between_movement)
	await Global.delay(wait_time)
	_on_movement_timer_timeout()

func _physics_process(_delta):
	if state == MOVING_SOON: 
		# raycasts can only be performed during physics_process due to threading concerns,
		# which is why the MOVING_SOON state exists
		_randomize_wander_target()
	elif state == MOVING:
		var collided = move_and_slide()
		if position.distance_to(target) < SPEED/75.0 or collided:
			_start_idling()

func _on_movement_timer_timeout():
	assert(state == IDLE)
	state = MOVING_SOON
