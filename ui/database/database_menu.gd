class_name UIDatabaseMenu
extends Node2D

# emitted when this menu should be closed
signal closed

# MonType -> DatabaseEntry; maps montypes to their database entry scenes
var _montype_to_entry_map := {}
var active_entry = null

const DATABASE_ENTRY_SCENE := preload("res://ui/database/database_entry.tscn")

func _ready() -> void:
	# create the database entries, one for each mon type
	for montype in MonData.MonType.values():
		for i in range(0, 10): # TODO - remove this
			if montype == MonData.MonType.NONE:
				continue
			var entry: DatabaseEntry = DATABASE_ENTRY_SCENE.instantiate()
			entry.set_texture(MonData.get_texture_for_mon(montype))
			entry.set_progress(50)
			_montype_to_entry_map[montype] = entry
			$DatabaseScroll/Database.add_child(entry)
			entry.clicked.connect(_on_entry_clicked)

func setup() -> void:
	# update progress values for each mon
	for montype in MonData.MonType.values():
		if montype == MonData.MonType.NONE:
			continue
		_montype_to_entry_map[montype].set_progress(GameData.compilation_progress_per_mon[montype])

func _on_entry_clicked(entry: DatabaseEntry) -> void:
	if active_entry:
		active_entry.unselect()
	active_entry = entry
	active_entry.select()

func _on_exit_pressed() -> void:
	emit_signal("closed")
