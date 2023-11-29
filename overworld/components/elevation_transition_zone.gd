extends Area2D

enum Type {
	ToTop, ToUpper, ToMiddle, ToLower, ToBottom, None
}

@export var transition_type = Type.None

func _ready():
	assert(transition_type != Type.None)

# set the mask values such that exactly 'mask' is true and the rest are false
# basically, we can only be on one layer at a time
func _set_one_mask(body, mask):
	body.set_collision_mask_value(5, 5 == mask)
	body.set_collision_mask_value(6, 6 == mask)
	body.set_collision_mask_value(7, 7 == mask)
	body.set_collision_mask_value(8, 8 == mask)
	body.set_collision_mask_value(9, 9 == mask)

func _on_body_entered(body):
	if transition_type == Type.ToTop:
		_set_one_mask(body, 5)
	elif transition_type == Type.ToUpper:
		_set_one_mask(body, 6)
	elif transition_type == Type.ToMiddle:
		_set_one_mask(body, 7)
	elif transition_type == Type.ToLower:
		_set_one_mask(body, 8)
	elif transition_type == Type.ToBottom:
		_set_one_mask(body, 9)
