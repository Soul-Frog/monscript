class_name UIScriptMenu2 #TODO
extends Node2D

var _active_file_tab = 1
var _active_drawer_tab = 1

func _ready():
	_update_drawer()
	_update_file_tabs()

func _update_drawer():
	_select_one_tab(_active_drawer_tab, $SnippetDrawer/Tabs.get_children()) # update the tabs
	var n := 1
	for drawer in $SnippetDrawer/Drawers.get_children():
		drawer.visible = n == _active_drawer_tab
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
	print("X")

func _on_if_tab_clicked():
	_active_drawer_tab = 1
	_update_drawer()

func _on_do_tab_clicked():
	_active_drawer_tab = 2
	_update_drawer()

func _on_to_tab_clicked():
	_active_drawer_tab = 3
	_update_drawer()
