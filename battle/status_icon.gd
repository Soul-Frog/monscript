extends Node2D


@onready var _status_to_icon = {
	BattleMon.Status.LEAK : $StatusLeak,
	BattleMon.Status.SLEEP : $StatusSleep
}

@onready var _rotate_timer: Timer = $RotateTimer
var _icon_rotation: Array[Sprite2D] = []
var _current_icon: Sprite2D = null

func reset() -> void:
	_icon_rotation = []
	if _current_icon:
		_current_icon.hide()
	_current_icon = null

func on_status_changed(status: BattleMon.Status, has_status: bool) -> void:
	var icon = _status_to_icon[status]
	
	if has_status:
		assert(_icon_rotation.find(icon) == -1)
		_icon_rotation.append(icon) 
		_make_active_icon(icon) # make the newly added status the active icon
		_rotate_timer.start() # and reset the rotation timer
	else:
		assert(_icon_rotation.find(icon) != -1)
		if icon == _current_icon:
			_rotate_icon() # rotate to the next icon, if there is one
			_rotate_timer.start() # and reset the rotation timer
		_icon_rotation.erase(icon)
		if _icon_rotation.size() == 0: # if we just deleted the last icon, hide ourselves
			_rotate_icon()

func _make_active_icon(icon: Sprite2D):
	if _current_icon != null:
		_current_icon.visible = false
	_current_icon = icon
	_current_icon.visible = true
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(_rotate_timer)
	for status in BattleMon.Status.values():
		assert(_status_to_icon.has(status))
		assert(_status_to_icon[status])
	_rotate_timer.timeout.connect(_rotate_icon)

func _rotate_icon() -> void:
	# hide the current icon
	if _current_icon != null:
		_current_icon.visible = false
	
	if _icon_rotation.size() == 0:
		_current_icon = null
		return # if there are no icons to show, just exit
	
	if _current_icon == null:
		_current_icon = _icon_rotation[0] # start at the front if we have no active icon
	else:
		for i in _icon_rotation.size():
			if _icon_rotation[i] == _current_icon:
				# now get the next element, or wrap around if needed
				if _icon_rotation.size() == i+1: #wrap around
					_current_icon = _icon_rotation[0]
				else:
					_current_icon = _icon_rotation[i+1]
				break
	
	# and make the new icon visible
	_current_icon.visible = true
