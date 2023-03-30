extends CharacterBody2D

#todo - perform a raycast (?) to ensure that the wander will be successful?

signal collided_with_player_start_battle

enum {
	MOVING, IDLE
}

@export var speed = 20
@export var wander_range = 20

# time the mon is stationary before attempting to move
@export var min_time_between_movement = 0.5
@export var max_time_between_movement = 1

@onready var movementTimer = $MovementTimer

var rng = RandomNumberGenerator.new()
var state = IDLE
var target = Vector2.ZERO

func _ready():
	_start_idling()

func _start_wandering():
	print("moving")
	
	# choose a random nearby point
	target = Vector2(position.x + rng.randi_range(-wander_range, wander_range), position.y + rng.randi_range(-wander_range, wander_range))
	print(target)
	
	# get direction vector
	var direction = (target - position).normalized()
	
	# set velocity 
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
	draw_circle(target, 2, Color.AQUAMARINE)

func _physics_process(_delta):
	if state == MOVING:
		move_and_slide()
		if position.distance_to(target) < 1:
			print("reached dest")
			_start_idling()

func _on_movement_timer_timeout():
	assert(state == IDLE)
	_start_wandering()

func _on_battle_start_hitbox_body_entered(body):
	emit_signal("collided_with_player_start_battle")
