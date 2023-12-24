extends Node2D

const BATTERY_SEGMENT_UNDER = preload("res://assets/ui/battle/inject_battery_segment_under.png")
const BATTERY_SEGMENT_PROGRESS = preload("res://assets/ui/battle/inject_battery_segment_progress.png")

@onready var _bar = $Bar
@onready var _top = $Bar/Top

func _ready() -> void:
	assert(_bar)
	assert(_top)
	_top.max_value = GameData.POINTS_PER_INJECT
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
	new_segment.max_value = GameData.POINTS_PER_INJECT
	new_segment.fill_mode = new_segment.FILL_BOTTOM_TO_TOP
	
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

# returns whether an inject is possible
func can_inject() -> bool:
	var bottom = _get_bottommost_bar()
	if not visible or bottom.value != bottom.max_value:
		return false
	return true #TODO
	
func update() -> void:
	_update_bar_size()
	_update_progress()

func _update_progress() -> void:
	var progress_left = GameData.inject_points
	
	# from bottom to top bar, fill according to progress
	var segs_reversed = _bar.get_children()
	segs_reversed.reverse()
	for segment in segs_reversed:
		var progress_for_bar = 10 if progress_left > 10 else progress_left
		progress_left -= progress_for_bar
		segment.value = progress_for_bar

func _update_bar_size() -> void:
	var segments = GameData.get_var(GameData.MAX_INJECTS)
	if segments == 0:
		hide()
	else:
		show()
		while _bar.get_child_count() != segments:
			_grow() if _bar.get_child_count() < segments else _shrink()
