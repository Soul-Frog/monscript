extends CharacterBody2D

@export var speed = 200

func _ready():
	assert(speed > 0)

func update_velocity(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = speed * input_direction

func _physics_process(delta):
	update_velocity(delta)
	move_and_slide()
