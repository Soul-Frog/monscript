class_name UIScriptMenu
extends Node2D

# emitted when this menu should be closed
signal closed

var _active_file_tab = 1
var _active_drawer_tab = 1

# the block currently picked up; moves with mouse cursor
var held_block = null

const SCRIPT_BLOCK_SCENE = preload("res://ui/script/script_block.tscn")
const SCRIPT_LINE_SCENE = preload("res://ui/script/script_line.tscn")

func _ready():
	# create blocks
	for ifBlock in ScriptData.IF_BLOCK_LIST:
		_create_and_add_block_to($BlockDrawer/Drawers/IfDrawer/BlockScroll/Blocks, ifBlock.type, ifBlock.name)
	for doBlock in ScriptData.DO_BLOCK_LIST:
		_create_and_add_block_to($BlockDrawer/Drawers/DoDrawer/BlockScroll/Blocks, doBlock.type, doBlock.name)
	for toBlock in ScriptData.TO_BLOCK_LIST:
		_create_and_add_block_to($BlockDrawer/Drawers/ToDrawer/BlockScroll/Blocks, toBlock.type, toBlock.name)
	_update_drawer()
	_update_file_tabs()

func setup(mon: MonData.Mon):
	held_block = null
	$DiscardBlockArea/Shape.disabled = true

func _create_block(block_type: ScriptData.Block.Type, block_name: String):
	var block := SCRIPT_BLOCK_SCENE.instantiate()
	block.set_data(block_type, block_name)
	return block

func _create_and_add_block_to(drawer: FlowContainer, block_type: ScriptData.Block.Type, block_name: String):
	var block = _create_block(block_type, block_name)
	drawer.add_child(block)
	block.clicked.connect(_on_block_clicked)
	block.visible = false

func _update_drawer():
	_select_one_tab(_active_drawer_tab, $BlockDrawer/Tabs.get_children()) # update the tabs
	var n := 1
	for drawer in $BlockDrawer/Drawers.get_children():
		drawer.visible = n == _active_drawer_tab
		for block in drawer.find_child("BlockScroll").find_child("Blocks").get_children():
			block.visible = n == _active_drawer_tab
		n += 1

func _update_file_tabs():
	_select_one_tab(_active_file_tab, $FileTabs.get_children())

func _select_one_tab(active_tab: int, tab_elements: Array):
	var n = 1
	for tab in tab_elements:
		tab.select() if n == active_tab else tab.unselect()
		n += 1

func _on_file_tab_1_clicked():
	_active_file_tab = 1
	_update_file_tabs()

func _on_file_tab_2_clicked():
	_active_file_tab = 2
	_update_file_tabs()

func _on_file_tab_3_clicked():
	_active_file_tab = 3
	_update_file_tabs()

func _on_clear_button_pressed():
	print("CLEAR")

func _on_x_button_pressed():
	emit_signal("closed")

func _on_if_tab_clicked():
	_active_drawer_tab = 1
	_update_drawer()

func _on_do_tab_clicked():
	_active_drawer_tab = 2
	_update_drawer()

func _on_to_tab_clicked():
	_active_drawer_tab = 3
	_update_drawer()

func _on_block_clicked(block: UIScriptBlock):
	# if we aren't already holding a block
	if held_block == null:
		# create a duplicate of this block and hold it
		_pickup_held_block(_create_block(block.block_type, block.block_name))

func _set_initial_block_position():
	if(held_block != null):
		held_block.position = Global.centered_position(held_block, get_viewport().get_mouse_position())

func _input(event):
	if event is InputEventMouseMotion:
		if held_block != null:
			held_block.position = Global.centered_position(held_block, event.position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and held_block != null:
		_discard_held_block()

func _on_discard_block_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and held_block != null:
			_discard_held_block()

func _pickup_held_block(new_held_block: UIScriptBlock):
	held_block = new_held_block
	add_child(held_block)
	new_held_block.position = Vector2(-100, -100)
	new_held_block.z_index = 100 # draw this on top of everything
	call_deferred("_set_initial_block_position") # wait a frame to set this so size can update
	$DiscardBlockArea/Shape.disabled = false

func _discard_held_block():
	held_block.queue_free()
	held_block = null
	$DiscardBlockArea/Shape.disabled = true

func _on_new_line_button_pressed():
	var newline = SCRIPT_LINE_SCENE.instantiate()
	newline.deleted.connect(_on_line_deleted)
	$ScriptScroll/Script/ScriptLines.add_child(newline)
	_update_line_numbers()

func _on_line_deleted(deleted_line: UIScriptLine):
	deleted_line.get_parent().remove_child(deleted_line)
	deleted_line.queue_free()
	_update_line_numbers()

func _update_line_numbers():
	var n := 1
	for script_line in $ScriptScroll/Script/ScriptLines.get_children():
		script_line.set_line_number(n)
		n += 1
