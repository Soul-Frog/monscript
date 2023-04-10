extends LineEdit

signal debug_console_opened
signal debug_console_closed

var active
const SUCCESS_COLOR = Color.GREEN
const FAIL_COLOR = Color.RED
const DEFAULT_COLOR = Color.BLACK

func _ready():
	active = false
	self.visible = false
	self.set("theme_override_colors/font_color", DEFAULT_COLOR)

func _input(event):
	if event.is_action_released("open_debug_console"):
		if active:
			emit_signal("debug_console_closed")
		else:
			emit_signal("debug_console_opened")
			self.grab_focus()
		self.text = ""
		active = not active
		self.visible = active


func _on_text_submitted(new_text):
	assert(active)
	print("Debug Command: " + new_text)
	
	var success = true
	
	if text == "break" or text == "breakpoint":
		breakpoint
	elif text == "hello world":
		print("Hello World!")
	else:
		success = false
	
	self.set("theme_override_colors/font_color", SUCCESS_COLOR if success else FAIL_COLOR)
	
	self.text = ""
