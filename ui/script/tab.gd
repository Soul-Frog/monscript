class_name UITab
extends Node2D

signal clicked

@export_group("Textures")
@export var texture_selected: Texture2D
@export var texture_selected_hover: Texture2D
@export var texture_unselected: Texture2D
@export var texture_unselected_hover: Texture2D

@onready var _button = $Button

func _ready() -> void:
	_button.pressed.connect(_on_clicked)
	unselect()

func select() -> void:
	_button.texture_normal = texture_selected
	_button.texture_hover = texture_selected_hover

func unselect() -> void:
	_button.texture_normal = texture_unselected
	_button.texture_hover = texture_unselected_hover

func _on_clicked() -> void:
	emit_signal("clicked")
