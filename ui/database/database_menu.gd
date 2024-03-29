class_name UIDatabaseMenu
extends Node2D

# emitted when this menu should be closed
signal closed

# MonType -> DatabaseEntry; maps montypes to their database entry scenes
var active_entry = null

const DATABASE_ENTRY_SCENE := preload("res://ui/database/database_entry.tscn")

const NAME_FORMAT = "[center]%s[/center]"
const COMPLETION_FORMAT = "[center]Completion: %d/%d[/center]"
const SPECIAL_NAME_FORMAT = "[center]%s[/center]"
const PASSIVE_NAME_FORMAT = "[center]%s[/center]"
const SPECIAL_DESCRIPTION_FORMAT = "%s"
const PASSIVE_DESCRIPTION_FORMAT = "%s"

func _ready() -> void:
	for placeholder in $DatabaseScroll/Database.get_children():
		$DatabaseScroll/Database.remove_child(placeholder)
		placeholder.queue_free()
	
	# create the database entries, one for each mon type
	for montype in MonData.MonType.values():
			if montype == MonData.MonType.NONE or MonData.is_virus(montype):
				continue
			var entry: DatabaseEntry = DATABASE_ENTRY_SCENE.instantiate()
			entry.setup(montype)
			$DatabaseScroll/Database.add_child(entry)
			entry.clicked.connect(_on_entry_clicked)
			for child in $MonInfo.get_children():
				child.visible = false
	_update_completion()

func _input(_event) -> void:
	if Input.is_action_just_released("toggle_menu"):
		_on_exit_pressed()

func setup() -> void:
	#active_entry = null
	#for child in $MonInfo.get_children():
	#	child.visible = false
	for entry in $DatabaseScroll/Database.get_children():
		entry.refresh() # update progress values of each entry
		if entry == active_entry:
			active_entry.select()
	_update_completion()

func _update_completion():
	var num_entries = $DatabaseScroll/Database.get_child_count()
	var num_compiled = 0
	for entry in $DatabaseScroll/Database.get_children():
		if entry.is_compiled():
			num_compiled += 1
	$CompletionLabel.text = COMPLETION_FORMAT % [num_compiled, num_entries]
	$CompletionLabel.add_theme_color_override("default_color", Global.COLOR_GOLDEN if num_compiled == num_entries else Global.COLOR_WHITE)

func _on_entry_clicked(entry: DatabaseEntry) -> void:
	if active_entry:
		active_entry.unselect()
	active_entry = entry
	active_entry.select()
	$MonInfo/NameLabel.text = NAME_FORMAT % active_entry.get_mon_name()
	$MonInfo/SpecialNameLabel.text = SPECIAL_NAME_FORMAT % active_entry.get_special_name()
	$MonInfo/SpecialDescriptionLabel.text = SPECIAL_DESCRIPTION_FORMAT % active_entry.get_special_description()
	$MonInfo/PassiveNameLabel.text = PASSIVE_NAME_FORMAT % active_entry.get_passive_name()
	$MonInfo/PassiveDescriptionLabel.text = PASSIVE_DESCRIPTION_FORMAT % active_entry.get_passive_description()
	if $MonInfo/MonAnchor.get_child_count() != 0: # delete any older mon scenes
		$MonInfo/MonAnchor.get_child(0).queue_free()
	$MonInfo/MonAnchor.add_child(active_entry.get_mon_scene())
	$MonInfo/HealthBar.value = active_entry.get_health_bar_value()
	$MonInfo/AttackBar.value = active_entry.get_attack_bar_value()
	$MonInfo/DefenseBar.value = active_entry.get_defense_bar_value()
	$MonInfo/SpeedBar.value = active_entry.get_speed_bar_value()
	
	var update_multiplier = func(multiplier_value: float, label: Label):
		label.modulate = Color.WHITE if multiplier_value == 1.0 else (Color.LIGHT_SKY_BLUE if multiplier_value <= 1.0 else Color.LIGHT_CORAL)	
		label.text = "%1.1fx" % multiplier_value
	update_multiplier.call(active_entry.get_heat_multiplier(), $MonInfo/HeatMultiplier)
	update_multiplier.call(active_entry.get_chill_multiplier(), $MonInfo/ChillMultiplier)
	update_multiplier.call(active_entry.get_volt_multiplier(), $MonInfo/VoltMultiplier)
	
	$DatabaseMonFileDefault.visible = false
	for child in $MonInfo.get_children():
		child.visible = true

func _on_exit_pressed() -> void:
	emit_signal("closed")
