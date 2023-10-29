extends Area2D

enum Type {
	ToLower, ToUpper
}

@export var transition_type = Type.ToLower

func _on_body_entered(body):
	if transition_type == Type.ToLower:
		# change from upper to lower level
		body.set_collision_mask_value(5, false)
		body.set_collision_mask_value(6, true)
	else:
		# change from lower to upper level
		body.set_collision_mask_value(6, false)
		body.set_collision_mask_value(5, true)
