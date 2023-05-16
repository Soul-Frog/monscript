extends CharacterBody2D

const SPEED = 200
const INVINCIBILITY_AFTER_ESCAPE_SECS = 5
var is_invincible = false
var escaped_recently = false

func _ready():
	assert(SPEED > 0)

func update_velocity(_delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = SPEED * input_direction

func _physics_process(delta):
	update_velocity(delta)
	move_and_slide()

func _on_area_2d_body_entered(overworld_encounter_collided_with):
	if not is_invincible: 
		Events.emit_signal("collided_with_overworld_encounter", overworld_encounter_collided_with)
		Events.emit_signal("battle_started", overworld_encounter_collided_with.mons)

func notify_escaped_from_battle():
	is_invincible = true
	Global.call_after_delay(INVINCIBILITY_AFTER_ESCAPE_SECS, func(): is_invincible = false)
