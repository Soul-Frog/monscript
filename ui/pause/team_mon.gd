class_name TeamMon
extends Node2D

@export var index: int

@onready var NAME = $Name
@onready var SLOT := $Slot
@onready var LEVEL = $Level
@onready var HP = $HP
@onready var ATK = $ATK
@onready var DEF = $DEF
@onready var SPD = $SPD
@onready var XP_BAR = $XPBar
@onready var EDIT_SCRIPT_BUTTON = $EditScriptButton

signal edit_script
signal slot_clicked

var _mon: MonData.Mon = null

func _ready() -> void:
	# make sure required elements exist
	assert(SLOT)
	assert(LEVEL)
	assert(HP)
	assert(ATK)
	assert(DEF)
	assert(SPD)
	assert(XP_BAR)
	
	SLOT.is_active_mon = true
	SLOT.index = index

func set_mon(mon: MonData.Mon) -> void:
	_mon = mon
	
	# update name
	NAME.text = mon.get_name() if mon else ""
	
	# update the slot
	SLOT.set_mon(mon)
	
	# update stats
	HP.text = Global.int_to_str_zero_padded(mon.get_max_health(), 3) if mon else "---"
	ATK.text = Global.int_to_str_zero_padded(mon.get_attack(), 3) if mon else "---"
	DEF.text = Global.int_to_str_zero_padded(mon.get_defense(), 3) if mon else "---"
	SPD.text = Global.int_to_str_zero_padded(mon.get_speed(), 3) if mon else "---"
	
	# update level and XP bar
	LEVEL.text = Global.int_to_str_zero_padded(mon.get_level(), 2) if mon else "--"
	if mon:
		if mon.get_level() == MonData.MAX_LEVEL: # if max level, just show a full bar
			XP_BAR.max_value = 1
			XP_BAR.value = 1
		else: # otherwise set the bar's values
			XP_BAR.max_value = MonData.XP_for_level(mon.get_level() + 1) # max is the amount needed for next level
			XP_BAR.value = mon.get_current_XP() # progress is how much the mon has now
	else: # if no mon, just use an empty bar
		XP_BAR.max_value = 1
		XP_BAR.value = 0
	
	# update visiblity of edit script button
	EDIT_SCRIPT_BUTTON.visible = mon != null

func has_mon() -> bool:
	return SLOT.has_mon()

func _on_edit_script_button_pressed() -> void:
	assert(_mon)
	emit_signal("edit_script", _mon)

func _on_slot_clicked(slot: MonSlot) -> void:
	assert(slot)
	emit_signal("slot_clicked", slot)

func set_edit_script_disabled(disabled: bool) -> void:
	EDIT_SCRIPT_BUTTON.disabled = disabled

func notify_update() -> void:
	set_mon(SLOT.get_mon())
