class_name UITooltip
extends MarginContainer

static var _TOOLTIP_SCENE = preload("res://ui/tooltip.tscn")

# call as: UITooltip.create(self, "tooltip txt", get_global_mouse_position(), get_tree().root)
# unfortunately this is a static function so it cannot call the last two parameters itself
# automatic_destroy - if true, this tooltip will delete itself when the mouse exits the parent control; otherwise
# the programmer is responsible for destroying it with destroy_tooltip()
static func create(parent: Control, text: String, global_mouse_position: Vector2, scene_root: Node, automatic_destroy := true) -> UITooltip:
	var tooltip: UITooltip = _TOOLTIP_SCENE.instantiate()
	assert(tooltip.get_child_count())
	tooltip.find_child("TextMargin").find_child("TooltipText").text = text
	if automatic_destroy:
		parent.mouse_exited.connect(tooltip.destroy_tooltip)
	tooltip.position = global_mouse_position
	scene_root.add_child(tooltip)
	return tooltip

func _input(event: InputEvent):
	# update position based on mouse position and screen position
	pass

func destroy_tooltip():
	# if you hit this assertion, you are manually calling destroy_tooltip() when
	# the tooltip was created with automatic_destroy = true. If automatic_destroy = true, 
	# don't call destroy_tooltip(). If you want to destroy the tooltip manually, create it
	# with automatic_destroy = false.
	assert(is_instance_valid(self), "This tooltip has already been destroyed (see comment)")
	queue_free()
