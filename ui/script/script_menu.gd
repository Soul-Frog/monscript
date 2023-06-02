extends ScrollContainer

func _ready():
	_add_new_line()
	
func _add_new_line():
	$Lines.add_child(load("res://ui/script/script_line.tscn").instantiate())
