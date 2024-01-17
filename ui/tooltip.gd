class_name UITooltip
extends MarginContainer

static var _TOOLTIP_SCENE = preload("res://ui/tooltip.tscn")
static var _ENABLED := true
static var _ALL_TOOLTIPS: Array[UITooltip] = []

# offset of the tooltip from the mouse
const _TOOLTIP_OFFSET := Vector2(3, 5)

# maximum width of a tooltip - note that tooltips can exceed this,
# but this is around where they will cap.
const _MAX_WIDTH_THRESHOLD := 130

const _FORMAT := "[center]%s[/center]"

static func enable_tooltips():
	_ENABLED = true
	for tooltip in _ALL_TOOLTIPS:
		tooltip.visible = true

static func disable_tooltips():
	_ENABLED = false
	for tooltip in _ALL_TOOLTIPS:
		tooltip.visible = false

static func clear_tooltips():
	for tooltip in _ALL_TOOLTIPS:
		tooltip.queue_free() #not sure this is safe; keep an eye on this
	_ALL_TOOLTIPS.clear()

var source_control: Control

# call as: UITooltip.create(self, "tooltip txt", get_global_mouse_position(), get_tree().root)
# unfortunately this is a static function so it cannot call the last two parameters itself
# NOTE - Tooltips created by this function are automatically destroyed.
static func create(source: Control, text: String, global_mouse_position: Vector2, scene_root: Node) -> void:
	var tooltip: UITooltip = create_manual(source, text, global_mouse_position, scene_root)
	tooltip.source_control.mouse_exited.connect(tooltip.destroy_tooltip) # add a connect destroying this when mouse exits parent
	tooltip.source_control.tree_exiting.connect(tooltip.destroy_tooltip) # destroy tooltip when parent exits tree (ie parent is deleted)

# call as UITooltip.create(self, "tooltip txt", get_global_mouse_position(), get_tree().root)
# NOTE - Tooltips created in this way must be manually deleted with destroy_tooltip.
static func create_manual(source: Control, text: String, global_mouse_position: Vector2, scene_root: Node) -> UITooltip:
	var tooltip: UITooltip = _TOOLTIP_SCENE.instantiate()
	assert(tooltip.get_child_count())
	
	tooltip.source_control = source
	
	var label: RichTextLabel = tooltip.find_child("TextMargin").find_child("TooltipText")
	
	# replace img tags with a single letter to help space them 
	# (for now, only works with small images)
	var text_no_tags = text
	while text_no_tags.find("[img]") != -1:
		var img_start = text_no_tags.find("[img]")
		var img_end = text_no_tags.find("[/img]")
		text_no_tags = text_no_tags.erase(text_no_tags.find("[img]"), img_end - img_start + 6)
		text_no_tags = text_no_tags.insert(img_start, "XX")
	
	# note - tags like bold will not work yet; need smarter handling RIGHT HERE if desired
	# see https://github.com/godotengine/godot-proposals/issues/5056 comments for a handler
	
	# the text does not contain \n, automatically break the text and format a nice tooltip.
	if not text_no_tags.contains("\n"):
		# calculate a reasonable tooltip size
		# basically, add words one at a time until we exceed the threshold. that's the length we want.
		# this fanciness guarantees that the first line in the tooltip is the longest, which looks nice
		var words = text_no_tags.split(" ", false)
		var first_line = ""
		for word in words:
			var text_length := tooltip.get_theme().get_default_font().get_string_size(first_line).x
			if text_length > _MAX_WIDTH_THRESHOLD:
				break
			first_line += word + " "
		
		label.custom_minimum_size.x = tooltip.get_theme().get_default_font().get_string_size(first_line).x
	# otherwise set the tooltip size based on the longest line
	else:
		var longest_line_size = -1
		for line in text_no_tags.split("\n"):
			var line_size = tooltip.get_theme().get_default_font().get_string_size(line).x
			if line_size > longest_line_size:
				longest_line_size = line_size
		label.custom_minimum_size.x = longest_line_size
		
	label.text = _FORMAT % text
	
	tooltip.position = global_mouse_position + _TOOLTIP_OFFSET
	scene_root.add_child(tooltip)
	_ALL_TOOLTIPS.append(tooltip)
	
	tooltip._force_position_onto_screen()
	
	# set initial visibility based on if tooltips are enabled
	tooltip.visible = _ENABLED
	
	return tooltip

func _process(delta):
	var mouse_position = get_global_mouse_position()
	if not Rect2(source_control.global_position, source_control.size).has_point(mouse_position):
		destroy_tooltip() # if the source_control has moved away from mouse, destroy the tooltip
	position = Vector2(int(mouse_position.x), int(mouse_position.y)) + _TOOLTIP_OFFSET
	_force_position_onto_screen()

# force the tooltip to be within the screen boundaries and not overlapping the mouse
func _force_position_onto_screen():
	# update position based on mouse position and screen position
	var mouse_position = get_global_mouse_position()
	var viewport_rect = get_viewport_rect()
	
	# if we are off the right of the screen, move left until that's no longer the case.
	while position.x + size.x > viewport_rect.size.x:
		position.x -= 1
	
	# if we are off the bottom of the screen, move up until that's no longer the case.
	while position.y + size.y > viewport_rect.size.y:
		position.y -= 1
	
	# but now we might be overlapping the mouse, so continue moving up until we aren't.
	var shifted := false
	while get_rect().has_point(mouse_position):
		shifted = true
		position.y -= 1
		
	if shifted: # if we had to shift back up, go a bit more to match the same offset as normal
		position.y -= _TOOLTIP_OFFSET.y

func destroy_tooltip():
	assert(is_instance_valid(self), "This tooltip has already been destroyed?")
	_ALL_TOOLTIPS.erase(self)
	queue_free()
