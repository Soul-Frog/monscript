extends Node2D

enum CustomizationPart {
	HAIR,
	EYES,
	SHIRT,
	SKIN
}

@export var customization_part : CustomizationPart

@onready var active_button:TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_button = $Colors.get_child(0)
	_on_button_pressed(active_button)
	for child in $Colors.get_children():
		child.pressed.connect(_on_button_pressed.bind(child))
		child.mouse_entered.connect(_on_button_mouse_entered.bind(child))
		child.mouse_exited.connect(_on_button_mouse_exited.bind(child))

func _on_button_mouse_exited(child:TextureButton) -> void:
	child.z_index = 0

func _on_button_mouse_entered(child:TextureButton) -> void:
	if child != active_button:
		child.z_index = 1

func _on_button_pressed(child: TextureButton) -> void:
	active_button.disabled = false
	active_button = child
	active_button.z_index = 0
	$Indicator.position = active_button.position
	$Indicator.visible = true
	active_button.disabled = true
	if (customization_part == CustomizationPart.HAIR):
		GameData.set_var(GameData.HAIR_CUSTOMIZATION_COLOR, child.customization_color)
		Events.emit_signal("update_player_sprite")
	elif (customization_part == CustomizationPart.EYES):
		GameData.set_var(GameData.EYE_CUSTOMIZATION_COLOR, child.customization_color)
		Events.emit_signal("update_player_sprite")
	elif (customization_part == CustomizationPart.SHIRT):
		GameData.set_var(GameData.SHIRT_CUSTOMIZATION_COLOR, child.customization_color)
		Events.emit_signal("update_player_sprite")
	elif (customization_part == CustomizationPart.SKIN):
		GameData.set_var(GameData.SKIN_CUSTOMIZATION_COLOR, child.customization_color)
		Events.emit_signal("update_player_sprite")
	
	
