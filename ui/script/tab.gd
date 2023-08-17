class_name UITab
extends Node2D

signal clicked

@export var texture_selected: Texture2D
@export var texture_selected_hover: Texture2D
@export var texture_unselected: Texture2D
@export var texture_unselected_hover: Texture2D

func _ready() -> void:
	$Button.pressed.connect(_on_clicked)
	unselect()

func select() -> void:
	$Button.texture_normal = texture_selected
	$Button.texture_hover = texture_selected_hover

func unselect() -> void:
	$Button.texture_normal = texture_unselected
	$Button.texture_hover = texture_unselected_hover

func _on_clicked() -> void:
	emit_signal("clicked")
