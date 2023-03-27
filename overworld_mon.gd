extends CharacterBody2D

@export var speed = 20

# time the mon is stationary before attempting to move
@export var min_stationary_time = 3
@export var max_stationary_time = 6

# time to mon moves before stopping
@export var min_move_time = 1 
@export var max_move_time = 2

@onready var movementTimer = get_node("MovementTimer");

var rng = RandomNumberGenerator.new()

func _ready():
	_stop_wandering()

func _start_wandering():
	_randomize_direction()
	movementTimer.wait_time = rng.randf_range(min_move_time, max_move_time)
	movementTimer.start()

func _stop_wandering():
	velocity = Vector2.ZERO
	movementTimer.wait_time = rng.randf_range(min_stationary_time, max_stationary_time)
	movementTimer.start()

func _randomize_direction():
	var input_direction = Vector2(rng.randfn(-1, 1), rng.randfn(-1, 1)).normalized()
	velocity = speed * input_direction

func _physics_process(_delta):
	move_and_slide()

func _on_movement_timer_timeout():
	# if moving, stop. if not moving, start
	if velocity == Vector2.ZERO:
		_start_wandering()
	else:
		_stop_wandering()
