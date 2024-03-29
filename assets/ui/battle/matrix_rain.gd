extends Node2D

class Glyph:
	var alpha = 0.0
	var glyph = "0"

class Rain:
	var _tail_size
	var _position = Vector2.ZERO
	var _max_y
	var _tail = []
	var _prev_glyph_index = null
	
	func _init(position: Vector2, max_y: int, tail_size: int) -> void:
		self._position = position
		self._max_y = max_y
		self._tail_size = tail_size
	
	func update(matrix: Array, charset: String, ordered: bool) -> void:
		# move down 1 space
		_position.y += 1
		if _position.y >= _max_y:
			_position.y = 0
		
		# update this glyph
		var active_glyph = matrix[_position.x][_position.y]
		
		# figure out the next character to use
		var glyph_index = -1
		if ordered and _prev_glyph_index != null: # if going in order, get the next in order
			glyph_index = _prev_glyph_index + 1 if _prev_glyph_index + 1 < charset.length() else 0
		else: # otherwise randomize
			glyph_index = Global.RNG.randi_range(0, charset.length() - 1)
		
		# update the current glpyh to the correct character
		active_glyph.glyph = charset[glyph_index]
		_prev_glyph_index = glyph_index
		
		# update tail glyphs (alpha)
		assert(_tail.size() <= _tail_size)
		if _tail.size() == _tail_size:
			_tail.pop_front().alpha = 0.0
		_tail.push_back(active_glyph)
		
		for i in _tail_size:
			if _tail.size() > i:
				var glyph = _tail[i]
				glyph.alpha = 1.0 * ((i+1.0) / _tail_size)

@export var font: Font
@export var width: int = 320
@export var height: int = 180
@export var spacing: int = 8
@export var font_size: int = 16
@export var tail_size: int = 10
@export var charset: String = "0123456789ABCDEF"
@export var charset_ordered: bool = false
@export var time_between_updates: float = 0.1
@export var color: Color = Color.GREEN
@export var autostart: bool = true

@onready var _TIMER = $StepTimer

var _stopped = false
var _matrix = []
var _rain = []
var _max_x = 0
var _max_y = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	@warning_ignore("integer_division")
	_max_x = width/spacing
	@warning_ignore("integer_division")
	_max_y = height/spacing
	
	_TIMER.wait_time = time_between_updates
	
	# build the matrix
	_matrix = []
	for x in _max_x:
		_matrix.append([])
		for y in _max_y:
			_matrix[x].append(Glyph.new())
	
	# create the rain
	var prev = -1
	for r in _max_x:
		var rand_y = Global.RNG.randi_range(0, _max_y - 1)
		while rand_y == prev: # prevent adjacent rain trails from starting at same y
			rand_y = Global.RNG.randi_range(0, _max_y - 1)
		
		var new_rain = Rain.new(Vector2(r, rand_y), _max_y, tail_size)
		_rain.append(new_rain)
		prev = rand_y
		
		for i in tail_size:
			new_rain.update(_matrix, charset, charset_ordered)
	
	start() if autostart else stop()

func stop() -> void:
	_stopped= true
	_TIMER.stop()

func start() -> void:
	_stopped = false
	_TIMER.start()

func _draw():
	for x in _max_x:
		var x_pos = x * spacing
		for y in _max_y:
			var y_pos = spacing + (y * spacing)
			draw_string(font, Vector2(x_pos, y_pos), str(_matrix[x][y].glyph), HORIZONTAL_ALIGNMENT_CENTER, spacing, font_size, color * _matrix[x][y].alpha)

func _on_step_timer_timeout():
	for rain in _rain:
		rain.update(_matrix, charset, charset_ordered)
	
	queue_redraw()

func set_speed_scale(new_speed: float):
	if new_speed == 0:
		_TIMER.stop()
	else:
		_TIMER.wait_time = time_between_updates / new_speed
		if not _stopped:
			_TIMER.start()

# immediately peform some number of steps
func step(steps: int) -> void:
	for s in steps:
		_on_step_timer_timeout()
