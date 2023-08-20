class_name UIScriptLine
extends MarginContainer

signal deleted
signal clicked_dropzone

# maximum possible size for a number
const NUM_SIZE = 2

@onready var NUMBER_LABEL = $HBox/Margin/Starter/Number
@onready var DROPZONE = $HBox/DropzoneMargin/Dropzone
@onready var DROPZONE_IF_INDICATOR = $HBox/DropzoneMargin/Dropzone/IfIndicator
@onready var DROPZONE_DO_INDICATOR = $HBox/DropzoneMargin/Dropzone/DoIndicator
@onready var DROPZONE_TO_INDICATOR = $HBox/DropzoneMargin/Dropzone/ToIndicator
@onready var BLOCK_CONTAINER = $HBox/BlockMargin
@onready var BLOCKS = $HBox/BlockMargin/Blocks
@onready var STARTER = $HBox/Margin/Starter

@onready var DEFAULT_SIZE = DROPZONE.size.x

func _ready():
	assert(NUMBER_LABEL != null)
	assert(DROPZONE != null)
	assert(BLOCKS != null)	
	assert(STARTER != null)
	_update_dropzone_indicators(null)

func set_line_number(num: int) -> void:
	assert(num > 0 and num < 100)
	NUMBER_LABEL.text = Global.int_to_str_zero_padded(num, NUM_SIZE)

func _set_dropzone_size(dropzone_size: int) -> void:
	assert(dropzone_size > -1)
	DROPZONE.custom_minimum_size.x = dropzone_size
	DROPZONE.size.x = dropzone_size

func add_block(block: UIScriptBlock) -> void:
	BLOCK_CONTAINER.visible = true
	assert(next_block_types().has(block.block_type))
	BLOCKS.add_child(block)
	_update_dropzone_indicators(null)

func next_block_types() -> Array[ScriptData.Block.Type]:
	# if there are no blocks, the first block can be IF or DO
	if BLOCKS.get_child_count() == 0:
		return [ScriptData.Block.Type.IF, ScriptData.Block.Type.DO]
		
	# otherwise, it's based on the final block
	return [BLOCKS.get_children()[-1].to_block().next_block_type]

func notify_held_block(block: UIScriptBlock) -> void:
	if block == null:
		DROPZONE.visible = not next_block_types().has(ScriptData.Block.Type.NONE)
		DROPZONE.custom_minimum_size.x = DEFAULT_SIZE
	else:
		DROPZONE.visible = next_block_types().has(block.block_type)
		DROPZONE.custom_minimum_size.x = block.size_no_margins().x
	_update_dropzone_indicators(block)

func _update_dropzone_indicators(held_block: UIScriptBlock) -> void:
	var valid_types = next_block_types()
	
	# if we aren't holding a block, show all options.
	# if we are holding a block, additionally don't show unless the held block matches.
	DROPZONE_IF_INDICATOR.visible = valid_types.has(ScriptData.Block.Type.IF) and (held_block == null or held_block.block_type == ScriptData.Block.Type.IF)
	DROPZONE_DO_INDICATOR.visible = valid_types.has(ScriptData.Block.Type.DO) and (held_block == null or held_block.block_type == ScriptData.Block.Type.DO)
	DROPZONE_TO_INDICATOR.visible = valid_types.has(ScriptData.Block.Type.TO) and (held_block == null or held_block.block_type == ScriptData.Block.Type.TO)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		# check for right click on starter
		if event.button_index == MOUSE_BUTTON_RIGHT and STARTER.get_global_rect().has_point(event.position):
			emit_signal("deleted", self)
		# check for left click on dropzone
		if event.button_index == MOUSE_BUTTON_LEFT and DROPZONE.get_global_rect().has_point(event.position):
			emit_signal("clicked_dropzone", self)
