extends Node2D

@export var timeout := 0.25
@export var left := 0
@export var right := 0
@export var up := 0
@export var down := 0

var timer: Timer;

var y_shifts_remaining := up
var y_direction := -1 # go up first

var x_shifts_remaining := left
var x_direction := -1 # go left first

func _ready() -> void:
	assert(timeout >= 0)
	assert(left >= 0)
	assert(right >= 0)
	assert(up >= 0)
	assert(down >= 0)
	timer = Timer.new()
	timer.wait_time = timeout
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_timeout)
	x_shifts_remaining = left
	y_shifts_remaining = up

func _on_timeout():
	if y_shifts_remaining != 0:
		get_parent().position.y += y_direction
		y_shifts_remaining -= 1
	
	if y_shifts_remaining == 0:
		y_direction = -y_direction
		y_shifts_remaining = up + down
		assert(y_direction == 1 or y_direction == -1)
	assert(y_shifts_remaining >= 0)
	
	if x_shifts_remaining != 0:
		get_parent().position.x += x_direction
		x_shifts_remaining -= 1
	
	if x_shifts_remaining == 0:
		x_direction = -x_direction
		x_shifts_remaining = left + right
		assert(x_direction == 1 or x_direction == -1)
	assert(x_shifts_remaining >= 0)
