class_name DatabaseEntry
extends BoxContainer

signal clicked

enum Status {
	SELECTED, UNSELECTED, DISABLED
}

var is_mouse_over := false
var mon_type
var _status = Status.DISABLED

func _update_background():
	for bg in $Free/BGs.get_children():
		bg.visible = false
	if _status == Status.DISABLED:
		$Free/BGs/BackgroundDisabled.visible = true
	elif _status == Status.UNSELECTED:
		$Free/BGs/BackgroundUnselected.visible = !is_mouse_over
		$Free/BGs/BackgroundUnselectedHover.visible = is_mouse_over
	else:
		$Free/BGs/BackgroundSelected.visible = !is_mouse_over
		$Free/BGs/BackgroundSelectedHover.visible = is_mouse_over

func ready() -> void:
	_update_background()

func setup(type) -> void:
	self.mon_type = type
	var mon = load(MonData.get_mon_scene_path(mon_type)).instantiate()
	$Free/SpriteAnchor.add_child(mon)
	refresh()
	_update_background()

func refresh() -> void:
	var maxProgress = MonData.get_decompilation_progress_required_for(mon_type)
	assert(GameData.decompilation_progress_per_mon[mon_type] >= 0 && GameData.decompilation_progress_per_mon[mon_type] <= maxProgress)
	$Free/ProgressBar.value = GameData.decompilation_progress_per_mon[mon_type]
	$Free/ProgressBar.max_value = maxProgress
	$Free/SpriteAnchor.get_child(0).modulate = Global.COLOR_BLACK if $Free/ProgressBar.value != maxProgress else Global.COLOR_WHITE
	$Free/Percentage.text = "%d%%" % int(100 * $Free/ProgressBar.value / $Free/ProgressBar.max_value)
	if $Free/ProgressBar.value == maxProgress:
		_status = Status.UNSELECTED
		_update_background()

func select():
	assert(_status != Status.DISABLED)
	_status = Status.SELECTED
	_update_background()

func unselect():
	assert(_status != Status.DISABLED)
	_status = Status.UNSELECTED
	_update_background()

func get_mon_name():
	return MonData.get_name_for(mon_type)

func get_special_name():
	return MonData.get_special_name_for(mon_type)

func get_passive_name():
	return MonData.get_passive_name_for(mon_type)

func get_special_description():
	return MonData.get_special_description_for(mon_type)
	
func get_passive_description():
	return MonData.get_passive_description_for(mon_type)

func get_sprite():
	return MonData.get_database_texture_for(mon_type)

func get_health_bar_value():
	return MonData.get_health_percentile_for(mon_type)

func get_attack_bar_value():
	return MonData.get_attack_percentile_for(mon_type)

func get_defense_bar_value():
	return MonData.get_defense_percentile_for(mon_type)

func get_speed_bar_value():
	return MonData.get_speed_percentile_for(mon_type)

func get_heat_multiplier():
	return MonData.get_damage_multiplier_for(mon_type, MonData.DamageType.HEAT)

func get_chill_multiplier():
	return MonData.get_damage_multiplier_for(mon_type, MonData.DamageType.CHILL)

func get_volt_multiplier():
	return MonData.get_damage_multiplier_for(mon_type, MonData.DamageType.VOLT)

func is_compiled():
	return $Free/ProgressBar.value == $Free/ProgressBar.max_value

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_mouse_over and is_compiled():
		emit_signal("clicked", self)

func _on_mouse_entered():
	is_mouse_over = true
	_update_background()
	if _status != Status.DISABLED:
		UITooltip.create(self, get_mon_name(), get_global_mouse_position(), get_tree().root)

func _on_mouse_exited():
	is_mouse_over = false
	_update_background()
