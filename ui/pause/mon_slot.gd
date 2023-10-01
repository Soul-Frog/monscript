class_name MonSlot
extends Node2D

signal clicked
signal mon_changed

@export var is_active_mon: bool
@export var index: int

@onready var _MON = $Mon
@onready var _MON_POSITION = _MON.position
@onready var _FRAME_BUTTON = $FrameButton

var _current_mon_scene: MonScene = null
var _current_mon: MonData.Mon = null

var _TOOLTIP_FORMAT = "%s Lv%d\nHP %d  ATK %d\nDEF %d  SPD %d"

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

func get_mon():
	return _current_mon

# clears this slot and returns an array containing the removed [MonData.mon, MonScene]
func pop_mon():
	assert((_current_mon != null) == (_current_mon_scene != null), "Mon and MonScene are not synced - one is null; other is not.")
	var mon = _current_mon
	var scene = _current_mon_scene
	remove_child(_current_mon_scene)
	_current_mon_scene = null
	_current_mon = null
	return [mon, scene]

func has_mon() -> bool:
	assert((_current_mon != null) == (_current_mon_scene != null), "Mon and MonScene are not synced - one is null; other is not.")
	return _current_mon != null

func _on_clicked():
	emit_signal("clicked", self)

# create tooltip when moused over
func _on_frame_button_mouse_entered():
	if _current_mon != null:
		var tooltip = _TOOLTIP_FORMAT % [_current_mon.get_name(), _current_mon.get_level(), _current_mon.get_max_health(),
			_current_mon.get_attack(), _current_mon.get_defense(), _current_mon.get_speed()]
		UITooltip.create(_FRAME_BUTTON, tooltip, get_global_mouse_position(), get_tree().root)
