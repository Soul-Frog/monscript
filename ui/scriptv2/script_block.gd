class_name UIScriptBlock2
extends MarginContainer

const IF_SPRITE := preload("res://assets/gui/script/if.png")
const DO_SPRITE := preload("res://assets/gui/script/do.png")
const TO_SPRITE := preload("res://assets/gui/script/to.png")
const BASE_SIZE := 16

func set_data(block_type: ScriptData.Block.Type, block_name: String) -> void:
	_set_block_type(block_type)
	_set_block_name(block_name)

func _set_block_type(block_type: ScriptData.Block.Type) -> void:
	match block_type:
		ScriptData.Block.Type.IF:
			$BlockClickable/Type.texture = IF_SPRITE
		ScriptData.Block.Type.DO:
			$BlockClickable/Type.texture = DO_SPRITE
		ScriptData.Block.Type.TO:
			$BlockClickable/Type.texture = TO_SPRITE

func _set_block_name(block_name: String) -> void:
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
	
	
