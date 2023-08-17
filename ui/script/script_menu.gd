class_name UIScriptMenu
extends Node2D

# emitted when this menu should be closed
signal closed

var _active_file_tab = 1
var _active_drawer_tab = 1

const SCRIPT_BLOCK_SCENE = preload("res://ui/script/script_block.tscn")

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
	pass

func _create_and_add_block_to(drawer: FlowContainer, block_type: ScriptData.Block.Type, block_name: String):
	var block := SCRIPT_BLOCK_SCENE.instantiate()
	block.set_data(block_type, block_name)
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
	print(block)
	
