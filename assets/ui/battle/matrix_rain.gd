@tool
extends Node2D

# disable this outside of debugging!
func _process(_delta) -> void:
	queue_redraw()

class Glyph:
	var alpha = 0.0
	var glyph = "0"

class Rain:
	const _TAIL_SIZE = 15.0
	var _position = Vector2.ZERO
	var _tail = []
	var _prev_glyph_index = null
	
	func _init(position: Vector2) -> void:
		self._position = position
	
	func update(matrix, max_y, charset, ordered) -> void:
		# move down 1 space
		_position.y += 1
		if _position.y >= max_y:
			_position.y = 0
		
		# update this glyph
		var active_glyph = matrix[_position.x][_position.y]
		
		var glyph_index = -1
		if ordered and _prev_glyph_index != null:
			glyph_index = _prev_glyph_index + 1
			if glyph_index >= charset.length():
				glyph_index = 0
		else:
			glyph_index = Global.RNG.randi_range(0, charset.length() - 1)
			
		active_glyph.glyph = charset[glyph_index]
		_prev_glyph_index = glyph_index
		
		# update tail
		assert(_tail.size() <= _TAIL_SIZE)
		if _tail.size() == _TAIL_SIZE:
			_tail.pop_front().alpha = 0.0
		_tail.push_back(active_glyph)
		
		for i in _TAIL_SIZE:
			if _tail.size() > i:
				var glyph = _tail[i]
				glyph.alpha = 1.0 * ((i+1.0) / _TAIL_SIZE)

@export var font: Font

@export var width: int = 100
@export var height: int = 100
@export var spacing: int = 8
@export var font_size: int = 16
@export var charset: String = "0123456789ABCDEF"
@export var charset_ordered: bool = false
@export var color: Color = Color.GREEN

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
	
	# build the matrix
	_matrix = []
	for x in _max_x:
		_matrix.append([])
		for y in _max_y:
			_matrix[x].append(Glyph.new())
	
	var prev = -1
	# create the rain
	for r in _max_x:
		var rand_y = Global.RNG.randi_range(0, _max_y - 1)
		while rand_y == prev:
			rand_y = Global.RNG.randi_range(0, _max_y - 1)
		_rain.append(Rain.new(Vector2(r, rand_y)))
		prev = rand_y

func _draw():
	for x in _max_x:
		var x_pos = x * spacing
		for y in _max_y:
			var y_pos = spacing + (y * spacing)
			draw_string(font, Vector2(x_pos, y_pos), str(_matrix[x][y].glyph), HORIZONTAL_ALIGNMENT_CENTER, spacing, font_size, color * _matrix[x][y].alpha)

func _on_step_timer_timeout():
	for rain in _rain:
		rain.update(_matrix, _max_y, charset, charset_ordered)
	
	queue_redraw()









# randomizes the contents of the matrix
#func _randomize():
#	var prev = matrix.duplicate(true)
#	matrix = []
#	for x in _rows: 
#		matrix.append([])
#		for y in _cols:
#			var newchar = Global.choose_char(legal_characters)
#			if prev.size() != 0:
#				while prev.size() != 0 and newchar == prev[x][y]:
#					newchar = Global.choose_char(legal_characters)
#			matrix[x].append(newchar)
