extends CharacterBody2D

@export var speed = 200
var is_invincible = false

func _ready():
	assert(speed > 0)

func update_velocity(_delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = speed * input_direction

func _physics_process(delta):
	update_velocity(delta)
	move_and_slide()

func _on_area_2d_body_entered(overworld_encounter_collided_with):
	if not is_invincible: 
		Events.emit_signal("collided_with_overworld_encounter", overworld_encounter_collided_with)
		Events.emit_signal("battle_started", overworld_encounter_collided_with.mons)

func notify_escaped_from_battle():
	is_invincible = true
