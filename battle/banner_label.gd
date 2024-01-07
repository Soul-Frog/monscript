extends RichTextLabel

const _ZOOM_FADE_TIME = 0.11
const _ZOOM_SIZE_TIME = 0.14
const _FONT_SIZE = 16
const _ZOOMOUT_SIZE = 64
const _FORMAT = "[center]%s[/center]"

func _ready() -> void:
	modulate.a = 0
	add_theme_font_size_override("normal_font_size", _ZOOMOUT_SIZE)
	text = ""

func display_text(new_text: String, animated: bool = false):
	if animated and text.length() != 0: # remove the current text letter by letter
		await create_tween().tween_property(self, "visible_characters", 0, 0.1).finished
	
	text = _FORMAT % new_text
	
	if animated: # display the next text letter by letter
		await create_tween().tween_property(self, "visible_characters", text.length(), 0.1).finished

func zoom_out():
	modulate.a = 1
	add_theme_font_size_override("normal_font_size", _FONT_SIZE)
	
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "modulate:a", 0, _ZOOM_FADE_TIME).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(self, "theme_override_font_sizes/normal_font_size", _ZOOMOUT_SIZE, _ZOOM_SIZE_TIME).set_trans(Tween.TRANS_CUBIC)
		await tween.finished

func zoom_in():
	modulate.a = 0
	add_theme_font_size_override("normal_font_size", _ZOOMOUT_SIZE)
	
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "modulate:a", 1, _ZOOM_FADE_TIME).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(self, "theme_override_font_sizes/normal_font_size", _FONT_SIZE, _ZOOM_SIZE_TIME).set_trans(Tween.TRANS_CUBIC)
		await tween.finished

func zoom_out_instant():
	modulate.a = 0
	add_theme_font_size_override("normal_font_size", _ZOOMOUT_SIZE)
