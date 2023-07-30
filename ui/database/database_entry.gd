class_name DatabaseEntry
extends BoxContainer

signal clicked

var is_mouse_over := false
var mon_type

func ready() -> void:
	$BackgroundSelected.visible = false
	$BackgroundUnselected.visible = true
	$BackgroundDisabled.visible = true

func setup(type) -> void:
	self.mon_type = type
	$Free/SpriteContainer/MonSprite.texture = MonData.get_texture_for(mon_type)
	refresh()

func refresh() -> void:
	assert(GameData.compilation_progress_per_mon[mon_type] >= 0 && GameData.compilation_progress_per_mon[mon_type] <= 100)
	$Free/ProgressBar.value = GameData.compilation_progress_per_mon[mon_type]
	$Free/SpriteContainer/MonSprite.modulate = Global.COLOR_BLACK if $Free/ProgressBar.value != 100 else Global.COLOR_WHITE
	$BackgroundDisabled.visible = $Free/ProgressBar.value != 100

func select():
	$BackgroundUnselected.visible = false
	$BackgroundSelected.visible = true

func unselect():
	$BackgroundUnselected.visible = true
	$BackgroundSelected.visible = false

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
	return MonData.get_texture_for(mon_type)

func get_health_bar_value():
	return MonData.get_health_percentile_for(mon_type)

func get_attack_bar_value():
	return MonData.get_attack_percentile_for(mon_type)

func get_defense_bar_value():
	return MonData.get_defense_percentile_for(mon_type)

func get_speed_bar_value():
	return MonData.get_speed_percentile_for(mon_type)

func _selectable() -> bool:
	return $Free/ProgressBar.value == 100

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_mouse_over and _selectable():
		emit_signal("clicked", self)

func _on_mouse_entered():
	is_mouse_over = true

func _on_mouse_exited():
	is_mouse_over = false
