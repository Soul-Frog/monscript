class_name UIScriptMenu
extends Node2D

# emitted when this menu should be closed
signal closed



# the currently known maximum scroll amount for script scrollbar
# used to update the scrollbar down when the line is grown at the bottom
var _max_scroll = -1

var _active_file_tab = 1
var _active_drawer_tab = 1

var _held_anchor := Vector2(0, 0)

const LINE_LIMIT_FORMAT = "Lines: %d/%d"
const SCRIPT_BLOCK_SCENE = preload("res://ui/script/script_block.tscn")
const SCRIPT_LINE_SCENE = preload("res://ui/script/script_line.tscn")
const LINE_DROPZONE_SCENE = preload("res://ui/script/line_dropzone.tscn")

@onready var SCRIPT_SCROLL = $ScriptScroll
@onready var SCRIPT_LINES = $ScriptScroll/Script/ScriptLines
@onready var BLOCK_TABS = $BlockDrawer/Tabs
@onready var BLOCK_DRAWERS = $BlockDrawer/Drawers
@onready var IF_DRAWER = $BlockDrawer/Drawers/IfDrawer/BlockScroll/Margins/Blocks
@onready var DO_DRAWER = $BlockDrawer/Drawers/DoDrawer/BlockScroll/Margins/Blocks
@onready var TO_DRAWER = $BlockDrawer/Drawers/ToDrawer/BlockScroll/Margins/Blocks
@onready var DISCARD_ZONE = $DiscardZone
@onready var FILE_TABS = $FileTabs
@onready var LINE_LIMIT = $LineLimitLabel
@onready var NEWLINE_BUTTON = $ScriptScroll/Script/NewLineMargin/NewLine
@onready var HELD = $Held

func _ready() -> void:
	assert(SCRIPT_SCROLL != null)
	assert(BLOCK_TABS != null)
	assert(BLOCK_DRAWERS != null)
	assert(IF_DRAWER != null)
	assert(DO_DRAWER != null)
	assert(TO_DRAWER != null)
	assert(DISCARD_ZONE != null)
	assert(FILE_TABS != null)
	assert(LINE_LIMIT != null)
	assert(NEWLINE_BUTTON != null)
	assert(HELD != null)
	
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
	Global.free_children(HELD)
	DISCARD_ZONE.visible = false

func _create_block(block_type: ScriptData.Block.Type, block_name: String, deletable: bool) -> UIScriptBlock:
	var block := SCRIPT_BLOCK_SCENE.instantiate()
	block.set_data(block_type, block_name, deletable)
	return block

func _create_and_add_block_to(drawer: FlowContainer, block_type: ScriptData.Block.Type, block_name: String) -> void:
	var block = _create_block(block_type, block_name, false)
	drawer.add_child(block)
	block.clicked.connect(_on_drawer_block_clicked)
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
		SCRIPT_LINES.remove_child(script_line)
	_update_line_numbers()

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

func _on_drawer_block_clicked(block: UIScriptBlock) -> void:
	# if we aren't already holding a block
	if HELD.get_child_count() == 0:
		# create a duplicate of this block and hold it
		_pickup_held_block(_create_block(block.block_type, block.block_name, true))
		call_deferred("_set_initial_block_position_and_notify_lines") # wait a frame to set this so size can update
func _set_initial_block_position_and_notify_lines() -> void:
	if(HELD.get_child_count() != 0):
		_held_anchor = Vector2(HELD.size.x/2.0, HELD.size.y/2.0)
		_update_held_position()
	_notify_lines_of_held_blocks()

func _input(event) -> void:
	if event is InputEventMouseMotion:
		_update_held_position()
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT and HELD.get_child_count() != 0:
			_discard_held_blocks(true)
		if event.button_index == MOUSE_BUTTON_LEFT and DISCARD_ZONE.visible and DISCARD_ZONE.get_global_rect().has_point(event.position):
			_discard_held_blocks(true)

func _on_discard_block_area_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.pressed and HELD.get_child_count() != 0:
			_discard_held_blocks(true)

func _pickup_held_block(new_held_block: UIScriptBlock) -> void:
	HELD.add_child(new_held_block)
	new_held_block.position = Vector2(-200, -200)
	new_held_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_set_discard_zone_active", true)

func _set_discard_zone_active(is_active: bool):
	DISCARD_ZONE.visible = is_active

func _update_held_position():
	HELD.size = Vector2(0, 0)
	HELD.position = get_viewport().get_mouse_position() - _held_anchor

func _discard_held_blocks(delete: bool) -> void:
	if delete:
		Global.free_children(HELD)
	Global.remove_children(HELD)
	call_deferred("_set_discard_zone_active", false)
	_clear_line_dropzones()
	_update_line_numbers()
	_notify_lines_of_held_blocks()

func _on_new_line_button_pressed() -> void:
	SCRIPT_LINES.add_child(_make_line())
	_update_line_numbers()
	_notify_lines_of_held_blocks()

func _make_line():
	var newline = SCRIPT_LINE_SCENE.instantiate()
	newline.deleted.connect(_on_line_deleted)
	newline.clicked_dropzone.connect(_on_dropzone_clicked)
	newline.block_clicked.connect(_on_line_block_clicked)
	newline.starter_clicked.connect(_on_line_starter_clicked)
	return newline

func _notify_lines_of_held_blocks():
	for script_line in SCRIPT_LINES.get_children():
		if script_line is UIScriptLine:
			script_line.notify_held_blocks(HELD.get_children())

func _move_scroll_to_bottom() -> void:
	# if we're holding something (a line), don't scroll
	if HELD.get_child_count() != 0:
		pass
	
	# if the scrollbar has grown, we just added a new line
	# move down to the next line.
	if _max_scroll < SCRIPT_SCROLL.get_v_scroll_bar().max_value:
		SCRIPT_SCROLL.scroll_vertical = SCRIPT_SCROLL.get_v_scroll_bar().max_value
		
	# either way, update our known scroll size.
	_max_scroll = SCRIPT_SCROLL.get_v_scroll_bar().max_value

func _adjust_scroll_after_line_pickup(deleted_position: int) -> void:
	print("# adjusts %d" % [int(SCRIPT_LINES.get_child_count()/2.0) + 1])
	print("deleted at %d" % deleted_position)
	print("scroll is currently %d" % SCRIPT_SCROLL.scroll_vertical)
	print("max %d" % SCRIPT_SCROLL.get_v_scroll_bar().max_value)
	
	print(SCRIPT_LINES.get_child(deleted_position * 2 - 1))
	
	# wait a frame, then move the scroll so that the line directly above selected line is at top
	await get_tree().process_frame
	if deleted_position == 0: #special case
		SCRIPT_SCROLL.scroll_vertical = 0
	else:
		SCRIPT_SCROLL.ensure_control_visible(SCRIPT_LINES.get_child(deleted_position * 2 - 1))
	
	print(get_global_mouse_position())
	print(SCRIPT_SCROLL.position)

func _on_line_deleted(deleted_line: UIScriptLine) -> void:
	deleted_line.get_parent().remove_child(deleted_line)
	deleted_line.queue_free()
	_update_line_numbers()
	
#todo - rename this to something like _on_num_lines_changed
func _update_line_numbers() -> void:
	var n := 0
	for script_line in SCRIPT_LINES.get_children():
		if script_line is UIScriptLine:
			n += 1
			script_line.set_line_number(n)
	LINE_LIMIT.text = LINE_LIMIT_FORMAT % [n, GameData.line_limit]
	LINE_LIMIT.flash()
	NEWLINE_BUTTON.visible = n != GameData.line_limit

func _put_held_blocks_in_line(line: UIScriptLine):
	for block in HELD.get_children():
		block.mouse_filter = Control.MOUSE_FILTER_STOP
		HELD.remove_child(block)
		line.add_block(block)
	_discard_held_blocks(false)

func _on_dropzone_clicked(line: UIScriptLine) -> void:
	var front_block = HELD.get_child(0) if HELD.get_child_count() != 0 else null
	if front_block != null and front_block is UIScriptBlock and line.next_block_types().has(front_block.block_type):
		_put_held_blocks_in_line(line)

func _on_line_block_clicked(blocks: Array[UIScriptBlock], first_position: Vector2) -> void:
	assert(blocks.size() != 0)
	if HELD.get_child_count() != 0:
		return #we shouldn't be calling this while holding a block, but it can happen if spam clicking - ignore this
	
	
	for block in blocks:
		_pickup_held_block(block)
		#HELD.add_child(block)
	_held_anchor = get_viewport().get_mouse_position() - first_position
	_update_held_position()
	_notify_lines_of_held_blocks()

func _on_line_starter_clicked(deleted_line: UIScriptLine, line_pieces: Array, starter_position: Vector2) -> void:
	assert(line_pieces.size() != 0)
	assert(HELD.get_child_count() == 0)
	
	# delete the old line
	var deleted_position = -1
	for line in SCRIPT_LINES.get_children():
		deleted_position += 1
		if line == deleted_line:
			break
	deleted_line.get_parent().remove_child(deleted_line)
	deleted_line.queue_free()
	
	_held_anchor = get_viewport().get_mouse_position() - starter_position
	for piece in line_pieces:
		HELD.add_child(piece)
	
	# need to insert a line dropzone after each line in script
	# get each line and remove
	var lines = SCRIPT_LINES.get_children()
	Global.remove_children(SCRIPT_LINES)
	
	# now add them all back to the line, but put dropzones in between
	SCRIPT_LINES.add_child(_make_line_dropzone())
	for line in lines:
		SCRIPT_LINES.add_child(line)
		SCRIPT_LINES.add_child(_make_line_dropzone())
		
	call_deferred("_set_discard_zone_active", true)
	
	_update_held_position()
	_notify_lines_of_held_blocks()
	_adjust_scroll_after_line_pickup(deleted_position)

func _make_line_dropzone():
	var dropzone = LINE_DROPZONE_SCENE.instantiate()
	# set the dropzone's size based on held
	var held_size = HELD.get_children().size() - 1 #spacing pixels
	for piece in HELD.get_children():
		held_size += piece.size.x
	dropzone.custom_minimum_size.x = held_size
	
	dropzone.clicked.connect(_on_line_dropzone_clicked)
	
	return dropzone

func _on_line_dropzone_clicked(clicked_dropzone) -> void:
	assert(HELD.get_children().size() != 0) #line dropzones shouldn't be visible
	assert(HELD.get_child(0) != UIScriptBlock) #first piece should be a starter
	
	# place line down
	# create a new line at the right spot...
	var n = 0
	for child in SCRIPT_LINES.get_children():
		if child == clicked_dropzone:
			var newline = _make_line()
			SCRIPT_LINES.add_child(newline)
			HELD.remove_child(HELD.get_child(0)) #remove the starter
			SCRIPT_LINES.move_child(newline, n) #move to correct spot
			_put_held_blocks_in_line(newline)
			_update_line_numbers()
			return
		n += 1
	assert(false, "Clicked dropzone isn't a child of SCRIPT_LINES?")

func _clear_line_dropzones() -> void:
	for child in SCRIPT_LINES.get_children():
		if not child is UIScriptLine:
			SCRIPT_LINES.remove_child(child)
			child.queue_free()
