class_name UIScriptBlock
extends MarginContainer

signal clicked
signal deleted

const IF_SPRITE := preload("res://assets/gui/script/if.png")
const DO_SPRITE := preload("res://assets/gui/script/do.png")
const TO_SPRITE := preload("res://assets/gui/script/to.png")
const BASE_SIZE := 16

var block_type
var block_name

# if this block can be deleted or not
# blocks in script lines can be deleted, blocks in drawers cannot
var _deleteable = false

var _tooltip: UITooltip

func set_data(blockType: ScriptData.Block.Type, blockName: String, deleteable: bool) -> void:
	self.block_type = blockType
	self.block_name = blockName
	self._deleteable = deleteable
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

func size_no_margins() -> Vector2:
	return $BlockClickable.size

func to_block() -> ScriptData.Block:
	var block = ScriptData.get_block_by_name(block_name)
	assert(block != null)
	return block

func _set_block_name() -> void:
	$BlockClickable/Name.text = block_name
	
	# We want to resize the rest of the node based on the text size,
	# but the size of a the name node does not immediately update, so
	# we need to wait a frame before using it. 
	call_deferred("_update_size")

func _update_size() -> void:
	# change both size (for visuals) and custom minimum size (so container
	# can't resize this to a smaller size)
	$BlockClickable.custom_minimum_size.x = BASE_SIZE + $BlockClickable/Name.size.x
	$BlockClickable.size.x = BASE_SIZE + $BlockClickable/Name.size.x
	$BlockClickable/Background.custom_minimum_size.x = $BlockClickable.size.x
	$BlockClickable/Background.size.x = $BlockClickable.size.x

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and $MouseoverWatcher.mouse_over() and visible:
			emit_signal("clicked", self)
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT and $MouseoverWatcher.mouse_over() and _deleteable:
			emit_signal("deleted", self)

func _create_tooltip():
	_tooltip = UITooltip.create(self, "This is a test tooltip!", get_global_mouse_position(), get_tree().root, false)
