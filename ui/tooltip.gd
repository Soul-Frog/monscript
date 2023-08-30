class_name UITooltip
extends MarginContainer

@onready var _TEXT = $TooltipMargin/TooltipText

static var _TOOLTIP_SCENE = preload("res://ui/tooltip.tscn")

static func create() -> UITooltip:
	var tooltip = _TOOLTIP_SCENE.instantiate()
	tooltip._TEXT.text = tooltip
	return tooltip

func _input(event: InputEvent):
	pass
	# update position based on mouse position and screen position
