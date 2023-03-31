extends CharacterBody2D

#todo - perform a raycast (?) to ensure that the wander will be successful?

signal collided_with_player_start_battle

enum {
	MOVING_SOON, MOVING, IDLE
}

# mon's speed while moving
@export var speed = 100

# how far the mon is allowed to wander when moving
@export var wander_range = 100

# time the mon is stationary before attempting to move
@export var min_time_between_movement = 1
@export var max_time_between_movement = 2

@onready var movementTimer = $MovementTimer

var rng = RandomNumberGenerator.new()
var state = IDLE
var target = Vector2.ZERO

func _ready():
	_start_idling()



func _randomize_wander_target():
	var success = false
	var attempts = 0
	while not success and attempts <= 10:
		#give up after 10 tries
		attempts += 1
		
		# choose a random nearby point
		# generate a value within the set [-range, -range/2]U(range/2, range) for both x and y
		var x_movement = rng.randi_range(wander_range/2, wander_range) * (1 if rng.randi_range(0, 1) else -1)
		var y_movement = rng.randi_range(wander_range/2, wander_range) * (1 if rng.randi_range(0, 1) else -1)
		var movement = Vector2(x_movement, y_movement)
		var trial_target = position + Vector2(x_movement, y_movement)
		
		# create a raycast from each corner of the rectangle; if none collide, movement is safe
		var collision_mask = 0b100 # 0b100 is a collision mask representing only the world collisions
		var x_offset = $CollisionHitbox.shape.size.x / 2.0
		var y_offset = $CollisionHitbox.shape.size.y / 2.0
		var top_left_offset = Vector2(-x_offset, -y_offset)
		var top_right_offset = Vector2(x_offset, -y_offset)
		var bottom_left_offset = Vector2(-x_offset, y_offset)
		var bottom_right_offset = Vector2(x_offset, y_offset)
		
		var query_topleft = PhysicsRayQueryParameters2D.create(position + top_left_offset, trial_target + top_left_offset, collision_mask)
		var query_topright = PhysicsRayQueryParameters2D.create(position + top_right_offset, trial_target + top_right_offset, collision_mask)
		var query_bottomleft = PhysicsRayQueryParameters2D.create(position + bottom_left_offset, trial_target + bottom_left_offset, collision_mask)
		var query_bottomright = PhysicsRayQueryParameters2D.create(position + bottom_right_offset, trial_target + bottom_right_offset, collision_mask)
		
		var result_topleft = get_world_2d().direct_space_state.intersect_ray(query_topleft)
		if result_topleft:
			print("Hit top left")
			continue
		
		var result_topright = get_world_2d().direct_space_state.intersect_ray(query_topright)
		if result_topright:
			print("Hit top right")
			continue
			
		var result_bottomleft = get_world_2d().direct_space_state.intersect_ray(query_bottomleft)
		if result_bottomleft:
			print("Hit bottom left")
			continue
			
		var result_bottomright = get_world_2d().direct_space_state.intersect_ray(query_bottomright)
		if result_bottomright:
			print("Hit bottom right")
			continue
		
		target = trial_target
		success = true
	
	# get direction vector and set velocity
	var direction = (target - position).normalized()
	velocity = speed * direction
	
	state = MOVING

func _start_idling():
	state = IDLE
	velocity = Vector2.ZERO
	movementTimer.wait_time = rng.randf_range(min_time_between_movement, max_time_between_movement)
	movementTimer.start()

func _randomize_direction():
	var input_direction = Vector2(rng.randfn(-1, 1), rng.randfn(-1, 1)).normalized()
	

func _draw():
	draw_circle(target - position, 1, Color.AQUAMARINE)

func _process(_delta):
	queue_redraw()

func _physics_process(_delta):
	if state == MOVING_SOON: 
		# raycasts can only be performed during physics_process due to threading concerns,
		# which is why the MOVING_SOON state exists
		_randomize_wander_target()
	elif state == MOVING:
		var collided = move_and_slide()
		if position.distance_to(target) < 3 or collided:
			if collided:
				print("collided!")
				#assert(false) # collided? should not happen without dynamic terrain
			print("reached dest")
			_start_idling()


func _on_movement_timer_timeout():
	assert(state == IDLE)
	state = MOVING_SOON

func _on_battle_start_hitbox_body_entered(body):
	emit_signal("collided_with_player_start_battle")
