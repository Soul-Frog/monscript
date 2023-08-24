class_name UIScriptLine
extends MarginContainer

signal deleted
signal block_clicked
signal clicked_dropzone

# maximum possible size for a number
const NUM_SIZE = 2

@onready var NUMBER_LABEL = $HBox/StarterMargin/Starter/Number
@onready var DROPZONE = $HBox/DropzoneMargin/Dropzone
@onready var DROPZONE_IF_INDICATOR = $HBox/DropzoneMargin/Dropzone/IfIndicator
@onready var DROPZONE_DO_INDICATOR = $HBox/DropzoneMargin/Dropzone/DoIndicator
@onready var DROPZONE_TO_INDICATOR = $HBox/DropzoneMargin/Dropzone/ToIndicator
@onready var BLOCK_CONTAINER = $HBox/BlockMargin
@onready var BLOCKS = $HBox/BlockMargin/Blocks
@onready var STARTER = $HBox/StarterMargin/Starter

@onready var DEFAULT_SIZE = DROPZONE.size.x

func _ready():
	assert(NUMBER_LABEL != null)
	assert(DROPZONE != null)
	assert(BLOCKS != null)	
	assert(STARTER != null)
	_update_dropzone_indicators_and_validity()

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
	block.deleted.connect(_on_block_deleted)
	block.clicked.connect(_on_block_clicked)
	BLOCKS.add_child(block)
	_update_dropzone_indicators_and_validity()

func next_block_types() -> Array[ScriptData.Block.Type]:
	# if there are no blocks, the first block can be IF or DO
	if BLOCKS.get_child_count() == 0:
		return [ScriptData.Block.Type.IF, ScriptData.Block.Type.DO]
		
	# otherwise, it's based on the final block
	return [BLOCKS.get_children()[-1].to_block().next_block_type]

var held_block
func notify_held_block(block: UIScriptBlock) -> void:
	held_block = block
	if held_block == null:
		#DROPZONE.visible = not next_block_types().has(ScriptData.Block.Type.NONE)
		DROPZONE.custom_minimum_size.x = DEFAULT_SIZE
	else:
		#DROPZONE.visible = next_block_types().has(held_block.block_type)
		DROPZONE.custom_minimum_size.x = held_block.size_no_margins().x
	_update_dropzone_indicators_and_validity()

func _update_dropzone_indicators_and_validity() -> void:
	var valid_types = next_block_types()
	
	# if we aren't holding a block, show all options.
	# if we are holding a block, additionally don't show unless the held block matches.
	DROPZONE_IF_INDICATOR.visible = valid_types.has(ScriptData.Block.Type.IF) and (held_block == null or held_block.block_type == ScriptData.Block.Type.IF)
	DROPZONE_DO_INDICATOR.visible = valid_types.has(ScriptData.Block.Type.DO) and (held_block == null or held_block.block_type == ScriptData.Block.Type.DO)
	DROPZONE_TO_INDICATOR.visible = valid_types.has(ScriptData.Block.Type.TO) and (held_block == null or held_block.block_type == ScriptData.Block.Type.TO)
	
	if is_line_valid():
		assert(valid_types.size() == 1)
		NUMBER_LABEL.add_theme_color_override("font_color", Global.COLOR_GREEN)
	else:
		NUMBER_LABEL.remove_theme_color_override("font_color")

func is_line_valid():
	return next_block_types().has(ScriptData.Block.Type.NONE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# check for right click on starter
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT and STARTER.get_global_rect().has_point(event.position):
			emit_signal("deleted", self)
		# check for left click on dropzone
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and DROPZONE.get_global_rect().has_point(event.position):
			emit_signal("clicked_dropzone", self)

func _on_block_deleted(block: UIScriptBlock) -> void:
	# get all blocks connected (on the right) to this deleted block
	var to_delete = [block]
	to_delete.append_array(_next_blocks_for(block))
	
	# delete all of them
	for b in to_delete:
		BLOCKS.remove_child(b)
		b.queue_free()
		
	# small visual fix; without this the dropzones are slightly misaligned
	if BLOCKS.get_child_count() == 0:
		BLOCK_CONTAINER.visible = false
	
	_update_dropzone_indicators_and_validity()

func _on_block_clicked(block: UIScriptBlock) -> void:
	# don't emit if a block is currently being held
	if held_block == null:
		# remove these blocks from the line and remove their signal connections
		var to_remove: Array[UIScriptBlock] = [block]
		to_remove.append_array(_next_blocks_for(block))
		for b in to_remove:
			b.deleted.disconnect(_on_block_deleted)
			b.clicked.disconnect(_on_block_clicked)
			BLOCKS.remove_child(b)
		_update_dropzone_indicators_and_validity()
		
		emit_signal("block_clicked", to_remove)

# returns all blocks after the given block in the line
func _next_blocks_for(block: UIScriptBlock) -> Array[UIScriptBlock]:
	var next_blocks: Array[UIScriptBlock] = []
	var found_start = false
	for b in BLOCKS.get_children():
		if block == b:
			found_start = true
		elif found_start: # previous block was this one, so this is next
			next_blocks.append(b)
	assert(found_start, "Block was not part of line!")
	return next_blocks
