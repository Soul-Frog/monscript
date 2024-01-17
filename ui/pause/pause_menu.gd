extends Node2D

signal script_menu_opened # emitted when the script menu should be opened, sends a Mon
signal database_menu_opened
signal settings_menu_opened
signal save
signal closed

@onready var TEAM_MONS = $TeamMons
@onready var STORAGE_PAGE_LABEL = $Storage/StoragePage
@onready var STORAGE_PAGE_SLOTS = $Storage/Slots
@onready var DATABASE_BUTTON = $Buttons/DatabaseButton
@onready var SAVE_BUTTON = $Buttons/SaveButton
@onready var SETTINGS_BUTTON = $Buttons/SettingsButton
@onready var X_BUTTON = $XButton
@onready var NO_MON_POPUP = $NoMonPopup
@onready var SAVE_POPUP = $SavePopup
@onready var BITS_AMOUNT_LABEL = $BitsAmount
@onready var BUGS = $Bugs

@onready var HELD = $Held
const _HELD_OFFSET = Vector2(16, 16)
var _held_mon = null

var _storage_page = 0 #the current page of storage open
const _STORAGE_PAGE_LABEL_FORMAT = "%d/%d"

var _is_saving = false # if the game is currently saving (used to prevent the menu from closing while save is in progress)

func _ready() -> void:
	assert(TEAM_MONS)
	assert(STORAGE_PAGE_LABEL)
	assert(STORAGE_PAGE_SLOTS)
	assert(DATABASE_BUTTON)
	assert(SAVE_BUTTON)
	assert(SETTINGS_BUTTON)
	assert(X_BUTTON)
	assert(NO_MON_POPUP)
	assert(not NO_MON_POPUP.visible)
	assert(SAVE_POPUP)
	assert(not SAVE_POPUP.visible)
	assert(HELD)
	assert(STORAGE_PAGE_SLOTS.get_child_count() == GameData.MONS_PER_STORAGE_PAGE, "Not enough slots per page.")
	assert(BUGS)
	assert(BITS_AMOUNT_LABEL)
	
	assert(TEAM_MONS.get_children().size() == GameData.MONS_PER_TEAM, "Wrong number of team slots!")
	_change_storage_page(0) # set the initial storage page

func setup() -> void:
	# put the player's mons into the team slots
	for i in GameData.MONS_PER_TEAM:
		TEAM_MONS.get_child(i).set_mon(GameData.team[i])
	
	# update the storage page
	_change_storage_page(_storage_page)
	
	# update the amount of bits
	BITS_AMOUNT_LABEL.text = Global.int_to_str_zero_padded(GameData.get_var(GameData.BITS), 6)

# changes to a new storage page, updates mons, updates label
func _change_storage_page(new_page: int):
	assert(new_page < GameData.get_var(GameData.STORAGE_PAGES))
	assert(new_page >= 0)
	
	_storage_page = new_page
	
	# update the label
	STORAGE_PAGE_LABEL.text = _STORAGE_PAGE_LABEL_FORMAT % [new_page + 1, GameData.get_var(GameData.STORAGE_PAGES)]
	
	# update the slots
	for i in STORAGE_PAGE_SLOTS.get_child_count():
		# get a mon from the global storage array corresponding to this slot
		var storage_index = (_storage_page * GameData.MONS_PER_STORAGE_PAGE) + i
		STORAGE_PAGE_SLOTS.get_children()[i].set_mon(GameData.storage[storage_index])

func _input(event) -> void:
	if event is InputEventMouseMotion:
		HELD.position = get_viewport().get_mouse_position() - _HELD_OFFSET
	if Input.is_action_just_released("tab"):
		_on_right_storage_arrow_pressed()

func _on_database_button_pressed() -> void:
	emit_signal("database_menu_opened")

func _on_save_button_pressed():
	_is_saving = true # prevent the menu from being closed while saving
	if not _is_team_valid():
		NO_MON_POPUP.show()
	else:
		await GameData.save_game()
		SAVE_POPUP.show()
		var continueGame = await SAVE_POPUP.selection_made
		if not continueGame:
			get_tree().quit()
	_is_saving = false # done saving; menu can be closed now if needed

func _on_settings_button_pressed() -> void:
	print("Settings!")	#TODO settings
	emit_signal("settings_menu_opened")

func _on_edit_script_button_pressed(mon: MonData.Mon) -> void:
	assert(mon != null)
	emit_signal("script_menu_opened", mon)

func _on_x_button_pressed():
	if not _is_team_valid():
		NO_MON_POPUP.show()
	else:
		emit_signal("closed")

func _on_left_storage_arrow_pressed():
	# switch to the next page down, but roll around to max if needed
	_change_storage_page(GameData.get_var(GameData.STORAGE_PAGES) - 1 if _storage_page == 0 else _storage_page - 1)

func _on_right_storage_arrow_pressed():
	# switch to the next page up, but roll around to 0 if needed
	_change_storage_page(0 if _storage_page == GameData.get_var(GameData.STORAGE_PAGES) - 1 else _storage_page + 1)

func _on_slot_clicked(slot: MonSlot):
	assert(slot)
	assert((_held_mon == null and HELD.get_child_count() == 0) or (_held_mon != null and HELD.get_child_count() == 1))
	
	# if we are holding nothing...
	if _held_mon == null:
		#...and the slot is empty, do nothing
		if not slot.has_mon():
			return
		#...and the slot is not empty, pick up that mon
		else:
			var popped = slot.pop_mon()
			_held_mon = popped[0]
			HELD.add_child(popped[1])
	# if we are holding a mon...
	else:
		#...and the slot is empty, place mon in slot
		if not slot.has_mon():
			slot.set_mon(_held_mon)
			Global.free_children(HELD)
			_held_mon = null
		#...and the slot is not empty, swap the held mon with the mon in the slot
		else:
			var popped = slot.pop_mon()
			slot.set_mon(_held_mon)
			Global.free_children(HELD)
			_held_mon = popped[0]
			HELD.add_child(popped[1])
	
	# remind this slot that the mouse is hovering; to display the tooltip
	slot._on_frame_button_mouse_entered()
	
	# if we changed an active mon, update the info
	if slot.is_active_mon:
		TEAM_MONS.get_children()[slot.index].notify_update()
	
	# update the global storage with the result of this click
	if slot.is_active_mon: # in team
		GameData.team[slot.index] = slot.get_mon()
	else: # in storage
		GameData.storage[(_storage_page * GameData.MONS_PER_STORAGE_PAGE) + slot.index] = slot.get_mon()
	
	# update button state based on if we're holding a mon or not
	DATABASE_BUTTON.disabled = _held_mon != null
	SAVE_BUTTON.disabled = _held_mon != null
	SETTINGS_BUTTON.disabled = _held_mon != null
	X_BUTTON.disabled = _held_mon != null
	for team_mon in TEAM_MONS.get_children():
		team_mon.set_edit_script_disabled(_held_mon != null)
	
	# while held, disable tooltips; if not held, re-enable tooltips
	UITooltip.disable_tooltips() if _held_mon else UITooltip.enable_tooltips()

func _is_team_valid():
	for team_mon in TEAM_MONS.get_children():
		if team_mon.has_mon():
			return true
	return false

# if the pause menu can currently be closed
# (false if save popup is open)
# (false if we're holding a mon)
# (false if the team is invalid [empty])
func is_closable():
	return (not _is_saving) and HELD.get_child_count() == 0 and _is_team_valid()

func _on_bugs_mouse_entered():
	var line_format = "[img]%s[/img] %d"
	var tooltip = ""
	for i in BugData.Type.size():
		var bugType = BugData.Type.values()[i]
		var bug = BugData.get_bug(bugType)
		var texture_path = bug.sprite.resource_path
		tooltip += line_format % [texture_path, GameData.bug_inventory[bugType]]
		tooltip += "\n"
	UITooltip.create(BUGS, tooltip, get_global_mouse_position(), get_tree().root)
