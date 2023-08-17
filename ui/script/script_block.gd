class_name UIScriptBlock
extends MarginContainer

signal clicked

const IF_SPRITE := preload("res://assets/gui/script/if.png")
const DO_SPRITE := preload("res://assets/gui/script/do.png")
const TO_SPRITE := preload("res://assets/gui/script/to.png")
const BASE_SIZE := 16

var block_type
var block_name

func set_data(blockType: ScriptData.Block.Type, blockName: String) -> void:
	self.block_type = blockType
	self.block_name = blockName
	_set_block_type()
	_set_block_name()

func _set_block_type() -> void:
	match block_type:
		ScriptData.Block.Type.IF:
			$BlockClickable/Type.texture = IF_SPRITE
		ScriptData.Block.Type.DO:
			$BlockClickable/Type.texture = DO_SPRITE
		ScriptData.Block.Type.TO:
			$BlockClickable/Type.texture = TO_SPRITE

func _set_block_name() -> void:
	$BlockClickable/Name.text = block_name
	
	# We want to resize the rest of the node based on the text size,
	# but the size of a the name node does not immediately update, so
	# we need to wait a frame before using it. 
	call_deferred("_update_size")

func _update_size():
	# change both size (for visuals) and custom minimum size (so container
	# can't resize this to a smaller size)
	$BlockClickable.custom_minimum_size.x = BASE_SIZE + $BlockClickable/Name.size.x
	$BlockClickable.size.x = BASE_SIZE + $BlockClickable/Name.size.x
	$BlockClickable/Background.custom_minimum_size.x = $BlockClickable.size.x
	$BlockClickable/Background.size.x = $BlockClickable.size.x
	
func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed() and $BlockClickable.get_global_rect().has_point(event.position) and visible:
			emit_signal("clicked", self)
