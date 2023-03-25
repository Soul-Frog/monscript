extends CharacterBody2D

@export var speed = 200
@export var acceleration = 100000 
@export var friction = 100000

func _ready():
	assert(speed > 0)
	assert(acceleration > 0)
	assert(friction > 0)

func update_velocity(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity += input_direction * acceleration * delta
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	velocity = velocity.clamp(Vector2(-speed, -speed), Vector2(speed, speed))
	

func _physics_process(delta):
	update_velocity(delta)
	move_and_slide()
