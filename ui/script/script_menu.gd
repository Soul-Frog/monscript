class_name UIScriptMenu
extends Node2D

# emitted when this menu should be closed
signal closed

var _active_file_tab = 1
var _active_drawer_tab = 1

# the currently known maximum scroll amount for script scrollbar
var _max_scroll = -1

# the block currently picked up; moves with mouse cursor
var held_block = null

const SCRIPT_BLOCK_SCENE = preload("res://ui/script/script_block.tscn")
const SCRIPT_LINE_SCENE = preload("res://ui/script/script_line.tscn")

@onready var SCRIPT_SCROLL = $ScriptScroll
@onready var SCRIPT_LINES = $ScriptScroll/Script/ScriptLines

@onready var BLOCK_TABS = $BlockDrawer/Tabs
@onready var BLOCK_DRAWERS = $BlockDrawer/Drawers
@onready var IF_DRAWER = $BlockDrawer/Drawers/IfDrawer/BlockScroll/Margins/Blocks
@onready var DO_DRAWER = $BlockDrawer/Drawers/DoDrawer/BlockScroll/Margins/Blocks
@onready var TO_DRAWER = $BlockDrawer/Drawers/ToDrawer/BlockScroll/Margins/Blocks

@onready var DISCARD_ZONE = $DiscardBlockArea/Shape

@onready var FILE_TABS = $FileTabs


func _ready() -> void:
	assert(SCRIPT_SCROLL != null)
	assert(SCRIPT_LINES != null)
	assert(BLOCK_TABS != null)
	assert(BLOCK_DRAWERS != null)
	assert(IF_DRAWER != null)
	assert(DO_DRAWER != null)
	assert(TO_DRAWER != null)
	assert(DISCARD_ZONE != null)
	assert(FILE_TABS != null)
	
	# create blocks
	for ifBlock in ScriptData.IF_BLOCK_LIST:
		_create_and_add_block_to(IF_DRAWER, ifBlock.type, ifBlock.name)
	for doBlock in ScriptData.DO_BLOCK_LIST:
		_create_and_add_block_to(DO_DRAWER, doBlock.type, doBlock.name)
	for toBlock in ScriptData.TO_BLOCK_LIST:
		_create_and_add_block_to(TO_DRAWER, toBlock.type, toBlock.name)
	_update_drawer()
	_update_file_tabs()
	
	# when the scrollbar size changes, move the scrollbar down
	SCRIPT_SCROLL.get_v_scroll_bar().changed.connect(_move_scroll_to_bottom)

func setup(mon: MonData.Mon) -> void:
	held_block = null
	DISCARD_ZONE.disabled = true

func _create_block(block_type: ScriptData.Block.Type, block_name: String) -> UIScriptBlock:
	var block := SCRIPT_BLOCK_SCENE.instantiate()
	block.set_data(block_type, block_name)
	return block

func _create_and_add_block_to(drawer: FlowContainer, block_type: ScriptData.Block.Type, block_name: String) -> void:
	var block = _create_block(block_type, block_name)
	drawer.add_child(block)
	block.clicked.connect(_on_block_clicked)
	block.visible = false

func _update_drawer() -> void:
	_select_one_tab(_active_drawer_tab, BLOCK_TABS.get_children()) # update the tabs
	var n := 1
	for drawer in BLOCK_DRAWERS.get_children():
		drawer.visible = n == _active_drawer_tab
		for block in drawer.find_child("BlockScroll").find_child("Blocks").get_children():
			block.visible = n == _active_drawer_tab
		n += 1

func _update_file_tabs() -> void:
	_select_one_tab(_active_file_tab, FILE_TABS.get_children())

func _select_one_tab(active_tab: int, tab_elements: Array) -> void:
	var n = 1
	for tab in tab_elements:
		tab.select() if n == active_tab else tab.unselect()
		n += 1

func _on_file_tab_1_clicked() -> void:
	_active_file_tab = 1
	_update_file_tabs()

func _on_file_tab_2_clicked() -> void:
	_active_file_tab = 2
	_update_file_tabs()

func _on_file_tab_3_clicked() -> void:
	_active_file_tab = 3
	_update_file_tabs()

func _on_clear_button_pressed() -> void:
	for script_line in SCRIPT_LINES.get_children():
		script_line.queue_free()

func _on_x_button_pressed() -> void:
	emit_signal("closed")

func _on_if_tab_clicked() -> void:
	_active_drawer_tab = 1
	_update_drawer()

func _on_do_tab_clicked() -> void:
	_active_drawer_tab = 2
	_update_drawer()

func _on_to_tab_clicked() -> void:
	_active_drawer_tab = 3
	_update_drawer()

func _on_block_clicked(block: UIScriptBlock) -> void:
	# if we aren't already holding a block
	if held_block == null:
		# create a duplicate of this block and hold it
		_pickup_held_block(_create_block(block.block_type, block.block_name))

func _input(event) -> void:
	if event is InputEventMouseMotion:
		if held_block != null:
			held_block.position = Global.centered_position(held_block, event.position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and held_block != null:
		_discard_held_block(true)

func _on_discard_block_area_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.pressed and held_block != null:
			_discard_held_block(true)

func _pickup_held_block(new_held_block: UIScriptBlock) -> void:
	held_block = new_held_block
	add_child(held_block)
	new_held_block.position = Vector2(-100, -100)
	new_held_block.z_index = 100 # draw this on top of everything
	call_deferred("_set_initial_block_position_and_notify_lines") # wait a frame to set this so size can update
	DISCARD_ZONE.disabled = false
func _set_initial_block_position_and_notify_lines() -> void:
	if(held_block != null):
		held_block.position = Global.centered_position(held_block, get_viewport().get_mouse_position())
		for script_line in SCRIPT_LINES.get_children():
			script_line.notify_held_block(held_block)

func _discard_held_block(delete: bool) -> void:
	if delete:
		held_block.queue_free()
	held_block = null
	DISCARD_ZONE.disabled = true
	for script_line in SCRIPT_LINES.get_children():
		script_line.notify_held_block(null)

func _on_new_line_button_pressed() -> void:
	var newline = SCRIPT_LINE_SCENE.instantiate()
	newline.deleted.connect(_on_line_deleted)
	newline.clicked_dropzone.connect(_on_dropzone_clicked)
	SCRIPT_LINES.add_child(newline)
	_update_line_numbers()
	
func _move_scroll_to_bottom() -> void:
	# if the scrollbar has grown, we just added a new line
	# move down to the next line.
	if _max_scroll < SCRIPT_SCROLL.get_v_scroll_bar().max_value:
		SCRIPT_SCROLL.scroll_vertical = SCRIPT_SCROLL.get_v_scroll_bar().max_value
		
	# either way, update our known scroll size.
	_max_scroll = SCRIPT_SCROLL.get_v_scroll_bar().max_value

func _on_line_deleted(deleted_line: UIScriptLine) -> void:
	deleted_line.get_parent().remove_child(deleted_line)
	deleted_line.queue_free()
	_update_line_numbers()

func _update_line_numbers() -> void:
	var n := 1
	for script_line in SCRIPT_LINES.get_children():
		script_line.set_line_number(n)
		n += 1

func _on_dropzone_clicked(line: UIScriptLine) -> void:
	if held_block != null and line.next_block_types().has(held_block.block_type):
		remove_child(held_block)
		line.add_block(held_block)
		_discard_held_block(false)
