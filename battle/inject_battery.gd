extends Control

signal clicked

const BATTERY_SEGMENT_UNDER = preload("res://assets/ui/battle/inject/inject_battery_segment_under.png")
const BATTERY_SEGMENT_PROGRESS = preload("res://assets/ui/battle/inject/inject_battery_segment_progress.png")

# green color of a full bar
const BATTERY_FULL_COLOR = Color(114.0/255.0, 213.0/255.0, 114.0/225.0)
var BATTERY_FULL_HOVER_COLOR = Color(BATTERY_FULL_COLOR.r + 0.1, BATTERY_FULL_COLOR.g + 0.1, BATTERY_FULL_COLOR.b + 0.1)
# yellow color of a filling bar
const BATTERY_PARTIAL_COLOR = Color(255.0/255.0, 245.0/255.0, 157.0/255.0)
var BATTERY_PARTIAL_HOVER_COLOR = Color(BATTERY_PARTIAL_COLOR.r + 0.15, BATTERY_PARTIAL_COLOR.g + 0.15, BATTERY_PARTIAL_COLOR.b + 0.15)


@onready var _bar = $Bar
@onready var _top = $Bar/Top

func _ready() -> void:
	assert(_bar)
	assert(_top)
	_top.max_value = BattleData.POINTS_PER_INJECT
	assert(BATTERY_SEGMENT_UNDER)
	assert(BATTERY_SEGMENT_PROGRESS)
	update()

func _get_bottommost_bar() -> TextureProgressBar:
	return _bar.get_child(_bar.get_child_count() - 1)

# create a new segment and add it to the bar
func _grow() -> void:
	var new_segment := TextureProgressBar.new()
	new_segment.texture_under = BATTERY_SEGMENT_UNDER
	new_segment.texture_progress = BATTERY_SEGMENT_PROGRESS
	new_segment.max_value = BattleData.POINTS_PER_INJECT
	new_segment.fill_mode = new_segment.FILL_BOTTOM_TO_TOP
	new_segment.texture_progress_offset = Vector2(3, 1)
	
	# it should be placed 3 pixels above the bottom pixel of the bottommost bar..
	var bottom = _get_bottommost_bar()
	new_segment.position = Vector2(bottom.position.x, bottom.position.y + bottom.texture_under.get_height() - 3)
	
	# add segment to bar
	_bar.add_child(new_segment)

# remove the bottommost segment of the bar
func _shrink() -> void:
	var bottom = _get_bottommost_bar()
	_bar.remove_child(bottom)
	bottom.queue_free()
	
func update() -> void:
	_update_bar_size()
	_update_progress()

func _update_progress() -> void:
	var progress_left = GameData.inject_points
	
	# from bottom to top bar, fill according to progress
	var segs_reversed = _bar.get_children()
	segs_reversed.reverse()
	for segment in segs_reversed:
		var progress_for_bar = BattleData.POINTS_PER_INJECT if progress_left > BattleData.POINTS_PER_INJECT else progress_left
		progress_left -= progress_for_bar
		segment.value = progress_for_bar
		segment.tint_progress = BATTERY_FULL_COLOR if segment.value == BattleData.POINTS_PER_INJECT else BATTERY_PARTIAL_COLOR

func _update_bar_size() -> void:
	var segments = GameData.get_var(GameData.MAX_INJECTS)
	if segments == 0:
		hide()
	else:
		show()
		while _bar.get_child_count() != segments:
			_grow() if _bar.get_child_count() < segments else _shrink()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and $MouseoverWatcher.mouse_over() and visible:
			emit_signal("clicked")

func _on_mouse_entered():
	# when mouse enters, we need to modify the sprite of the bar segments to enlargen
	for segment in _bar.get_children():
		var tween = create_tween()
		var new_color = BATTERY_FULL_HOVER_COLOR if segment.value == BattleData.POINTS_PER_INJECT else BATTERY_PARTIAL_HOVER_COLOR
		tween.tween_property(segment, "tint_progress", new_color, 0.1)

func _on_mouse_exited():
	# when mouse exits, we need to modify the sprite of the bar segments to shrink
	for segment in _bar.get_children():
		var tween = create_tween()
		var new_color = BATTERY_FULL_COLOR if segment.value == BattleData.POINTS_PER_INJECT else BATTERY_PARTIAL_COLOR
		tween.tween_property(segment, "tint_progress", new_color, 0.1)
