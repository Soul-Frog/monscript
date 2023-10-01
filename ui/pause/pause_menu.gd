extends Node2D

signal script_menu_opened # emitted when the script menu should be opened, sends a Mon
signal database_menu_opened
signal settings_menu_opened
signal save
signal closed

@onready var ACTIVE_MONS = $ActiveMons
@onready var STORAGE_PAGE_LABEL = $Storage/StoragePage
@onready var STORAGE_PAGE_SLOTS = $Storage/Slots

var _storage_page = 0
var _STORAGE_PAGE_LABEL_FORMAT = "%d/%d"

func _ready() -> void:
	assert(ACTIVE_MONS)
	assert(STORAGE_PAGE_LABEL)
	assert(STORAGE_PAGE_SLOTS)
	assert(STORAGE_PAGE_SLOTS.get_child_count() == PlayerData.MONS_PER_STORAGE_PAGE, "Not enough slots per page.")
	
	assert(ACTIVE_MONS.get_children().size() == Global.MONS_PER_TEAM, "Wrong number of placeholder positions!")
	_change_storage_page(0) # set the initial storage page
	setup() #todo - remove this

func setup() -> void:
	# put the player's mons into the active slots
	for i in Global.MONS_PER_TEAM:
		ACTIVE_MONS.get_child(i).set_mon(PlayerData.team[i])
	
	# update the storage page
	_change_storage_page(_storage_page)

# changes to a new storage page, updates mons, updates label
func _change_storage_page(new_page: int):
	assert(new_page < PlayerData.STORAGE_PAGES)
	assert(new_page >= 0)
	
	_storage_page = new_page
	
	# update the label
	STORAGE_PAGE_LABEL.text = _STORAGE_PAGE_LABEL_FORMAT % [new_page + 1, PlayerData.STORAGE_PAGES]
	
	# update the slots
	for i in STORAGE_PAGE_SLOTS.get_child_count():
		# get a mon from the global storage array corresponding to this slot
		var storage_index = (_storage_page * PlayerData.MONS_PER_STORAGE_PAGE) + i
		STORAGE_PAGE_SLOTS.get_children()[i].set_mon(PlayerData.storage[storage_index])

func _on_database_button_pressed() -> void:
	emit_signal("database_menu_opened")

func _on_save_button_pressed():
	#TODO save
	print("Save!")
	emit_signal("save")

func _on_settings_button_pressed() -> void:
	#TODO settings
	print("Settings!")
	emit_signal("settings_menu_opened")

func _on_edit_script_button_pressed(mon: MonData.Mon) -> void:
	assert(mon != null)
	emit_signal("script_menu_opened", mon)

func _on_x_button_pressed():
	emit_signal("closed")

func _on_left_storage_arrow_pressed():
	var new_page = PlayerData.STORAGE_PAGES - 1 if _storage_page == 0 else _storage_page - 1
	_change_storage_page(new_page)

func _on_right_storage_arrow_pressed():
	var new_page = 0 if _storage_page == PlayerData.STORAGE_PAGES - 1 else _storage_page + 1
	_change_storage_page(new_page)
