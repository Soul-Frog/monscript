class_name UIScriptLine
extends MarginContainer

signal deleted

# maximum possible size for a number
const NUM_SIZE = 2

func set_line_number(num: int):
	$HBox/Starter/Number.text = Global.int_to_str_zero_padded(num, NUM_SIZE)

func _input(event: InputEvent):
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and $HBox/Starter.get_global_rect().has_point(event.position):
		emit_signal("deleted", self)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
