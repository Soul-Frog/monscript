class_name UIDatabaseMenu
extends Node2D

# emitted when this menu should be closed
signal closed

# MonType -> DatabaseEntry; maps montypes to their database entry scenes
var active_entry = null

const DATABASE_ENTRY_SCENE := preload("res://ui/database/database_entry.tscn")

const NAME_FORMAT = "[center]%s[/center]"
const SPECIAL_NAME_FORMAT = "[center]%s[/center]"
const PASSIVE_NAME_FORMAT = "[center]%s[/center]"
const SPECIAL_DESCRIPTION_FORMAT = "%s"
const PASSIVE_DESCRIPTION_FORMAT = "%s"

func _ready() -> void:
	# create the database entries, one for each mon type
	for montype in MonData.MonType.values():
		if montype == MonData.MonType.NONE:
			continue
		var entry: DatabaseEntry = DATABASE_ENTRY_SCENE.instantiate()
		entry.setup(montype)
		$DatabaseScroll/Database.add_child(entry)
		entry.clicked.connect(_on_entry_clicked)
		for child in $MonInfo.get_children():
			child.visible = false

func setup() -> void:
	for entry in $DatabaseScroll/Database.get_children():
		entry.refresh() # update progress values of each entry

func _on_entry_clicked(entry: DatabaseEntry) -> void:
	$DatabaseMonFileDefault.visible = false
	if active_entry:
		active_entry.unselect()
	active_entry = entry
	active_entry.select()
	$MonInfo/NameLabel.text = NAME_FORMAT % active_entry.get_mon_name()
	$MonInfo/SpecialNameLabel.text = SPECIAL_NAME_FORMAT % active_entry.get_special_name()
	$MonInfo/SpecialDescriptionLabel.text = SPECIAL_DESCRIPTION_FORMAT % active_entry.get_special_description()
	$MonInfo/PassiveNameLabel.text = PASSIVE_NAME_FORMAT % active_entry.get_passive_name()
	$MonInfo/PassiveDescriptionLabel.text = PASSIVE_DESCRIPTION_FORMAT % active_entry.get_passive_description()
	$MonInfo/SpriteContainer/MonSprite.texture = active_entry.get_sprite()
	$MonInfo/HealthBar.value = active_entry.get_health_bar_value()
	$MonInfo/AttackBar.value = active_entry.get_attack_bar_value()
	$MonInfo/DefenseBar.value = active_entry.get_defense_bar_value()
	$MonInfo/SpeedBar.value = active_entry.get_speed_bar_value()
	for child in $MonInfo.get_children():
		child.visible = true

func _on_exit_pressed() -> void:
	emit_signal("closed")
