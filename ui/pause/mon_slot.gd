extends Node2D

@onready var _MON = $Mon
@onready var _MON_POSITION = _MON.position

var _current_mon_scene: MonScene = null
var _current_mon: MonData.Mon = null

func _ready() -> void:
	_MON.queue_free() # delete the placeholder

func set_mon(mon: MonData.Mon):
	assert((_current_mon != null) == (_current_mon_scene != null), "Mon and MonScene are not synced - one is null; other is not.")
	
	# remove the active mon if it already exists
	if _current_mon_scene != null:
		pop_mon()
	
	# now create a new mon, if we were given one
	if mon != null:
		var m = load(mon.get_scene_path()).instantiate()
		m.position = _MON_POSITION
		_current_mon_scene = m
		_current_mon = mon
		add_child(_current_mon_scene)

func pop_mon() -> MonData.Mon:
	assert((_current_mon != null) == (_current_mon_scene != null), "Mon and MonScene are not synced - one is null; other is not.")
	var mon = _current_mon
	_current_mon_scene.queue_free()
	_current_mon_scene = null
	_current_mon = null
	return mon

func has_mon() -> bool:
	assert((_current_mon != null) == (_current_mon_scene != null), "Mon and MonScene are not synced - one is null; other is not.")
	return _current_mon != null
