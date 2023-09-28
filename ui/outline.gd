@tool
extends Polygon2D

@export var outline_color := Color(0,0,0): set = set_clr
@export var width := 2.0: set = set_wth

@onready var _FADE: FadeDecorator = $Fade

func _draw():
	var poly = get_polygon()
	for i in range(1 , poly.size()):
		draw_line(poly[i-1] , poly[i], outline_color, width)
	draw_line(poly[poly.size() - 1] , poly[0], outline_color , width)

func set_clr(clr):
	outline_color = clr
	queue_redraw()

func set_wth(new_width):
	width = new_width
	queue_redraw()

func activate():
	_FADE.fade_in()

func deactivate():
	_FADE.min_alpha = 0
	_FADE.fade_out()

func _on_fade_fade_in_done():
	_FADE.oscillate()
	_FADE.min_alpha = 0.5
