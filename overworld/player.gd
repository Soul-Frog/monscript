extends CharacterBody2D

const SPEED = 200
const INVINCIBILITY_AFTER_ESCAPE_SECS = 2
const INVINCIBILITY_AFTER_WIN_SECS = 1
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

func activate_invincibility(battle_end_condition):
	is_invincible = true
	
	var length = INVINCIBILITY_AFTER_ESCAPE_SECS if battle_end_condition == Global.BattleEndCondition.ESCAPE else INVINCIBILITY_AFTER_WIN_SECS
	Global.call_after_delay(length, self, func(player): 
		if is_instance_valid(player):
			is_invincible = false)
