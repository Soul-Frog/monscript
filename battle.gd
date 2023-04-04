extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var timer = Timer.new()
	timer.autostart = true
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(timeout)

func timeout():
	print("1 second")

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	pass
