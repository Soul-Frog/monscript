class_name UITab
extends Node2D

signal clicked

@export_group("Textures")
@export var texture_selected: Texture2D
@export var texture_selected_hover: Texture2D
@export var texture_unselected: Texture2D
@export var texture_unselected_hover: Texture2D

@export_group("Label")
@export var label_hover_delta: Vector2
@export var label_selected_color: Color
@export var label_unselected_color: Color

var _label: Label = null
@onready var _button = $Button

func _ready() -> void:
	_label = find_child("Label")
	_button.pressed.connect(_on_clicked)
	unselect()

func select() -> void:
	_button.texture_normal = texture_selected
	_button.texture_hover = texture_selected_hover
	if _label != null:
		_label.add_theme_color_override("font_color", label_selected_color)

func unselect() -> void:
	_button.texture_normal = texture_unselected
	_button.texture_hover = texture_unselected_hover
	if _label != null:
		_label.add_theme_color_override("font_color", label_unselected_color)

func set_label_colors(selected_color: Color, unselected_color: Color):
	label_selected_color = selected_color
	label_unselected_color = unselected_color

func _on_clicked() -> void:
	emit_signal("clicked")

func _on_button_mouse_entered():
	if _label != null:
		_label.position += label_hover_delta

func _on_button_mouse_exited():
	if _label != null:
		_label.position -= label_hover_delta
		
		
