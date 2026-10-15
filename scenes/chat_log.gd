extends PanelContainer
class_name ChatLog


## ChatLog — bottom-left message window. Finds itself via group "chat_log";
## combat_ui.gd forwards every _log() call here. Children are built in code.


const MAX_PARAGRAPHS := 80
const FONT_SIZE      := 13
const HEADER_SIZE    := 11

const BG_ALPHA_ON  := 0.45
const BG_ALPHA_OFF := 0.0
const BORDER_ALPHA_ON := 0.7
const LINGER_TIME  := 5.0


const COLOR_DEFAULT := Color(0.89, 0.89, 0.91)
const COLOR_DAMAGE  := Color(1.00, 0.56, 0.52)
const COLOR_STATUS  := Color(0.66, 0.84, 1.00)
const COLOR_REWARD  := Color(1.00, 0.85, 0.42)
const COLOR_HEAL    := Color(0.60, 0.90, 0.62)
const COLOR_SYSTEM  := Color(0.62, 0.62, 0.68)


var _text: RichTextLabel
var _has_content := false
var _panel_sb: StyleBoxFlat
var _bg_on := false
var _linger := 0.0
var _last_msg: String = ""
var _repeat: int = 1




func _ready() -> void:
	add_to_group("chat_log")


	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.border_color = Color(0.28, 0.28, 0.34, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left   = 12
	sb.content_margin_right  = 12
	sb.content_margin_top    = 6
	sb.content_margin_bottom = 6
	_panel_sb = sb
	add_theme_stylebox_override("panel", sb)
	_apply_bg(false)


	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)


	var header := Label.new()
	header.text = "LOG"
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_font_size_override("font_size", HEADER_SIZE)
	header.add_theme_color_override("font_color", COLOR_SYSTEM)
	vbox.add_child(header)


	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)


	_text = RichTextLabel.new()
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.scroll_following = true
	_text.fit_content = false
	_text.selection_enabled = false
	_text.context_menu_enabled = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_STOP
	_text.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_text.add_theme_color_override("default_color", COLOR_DEFAULT)
	_text.add_theme_constant_override("line_separation", 3)
	vbox.add_child(_text)



func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if get_global_rect().has_point(get_global_mouse_position()):
			_linger = LINGER_TIME


func _apply_bg(on: bool) -> void:
	if on == _bg_on:
		return
	_bg_on = on
	_panel_sb.bg_color.a     = BG_ALPHA_ON if on else BG_ALPHA_OFF
	_panel_sb.border_color.a = BORDER_ALPHA_ON if on else 0.0




func add_message(msg: String) -> void:
	if msg == "" or _text == null:
		return
	if _has_content and msg == _last_msg:
		_repeat += 1
		_text.remove_paragraph(_text.get_paragraph_count() - 1)
	else:
		_repeat = 1
		_last_msg = msg
	var safe := msg.replace("[", "[lb]")
	if _repeat > 1:
		safe += " (x%d)" % _repeat
	var line := "[color=#%s]%s[/color]" % [_color_for(msg).to_html(false), safe]
	var prefix := "\n" if _text.get_paragraph_count() > 0 else ""
	_text.append_text(prefix + line)
	_has_content = true
	while _text.get_paragraph_count() > MAX_PARAGRAPHS:
		_text.remove_paragraph(0)




## Keyword-based tint so damage, status, loot and rejected actions can be
## told apart at a glance. Purely cosmetic: unmatched lines use the default.
func _color_for(msg: String) -> Color:
	for k in ["Wait for your turn", "Not enough", "pack is full", "need a Hunting Bow",
			"already", "nothing to hit", "No enemy", "deflect", "scatter harmlessly"]:
		if msg.contains(k):
			return COLOR_SYSTEM
	for k in [" hits you", "explodes!", "Poison flares", "gets through", "You died"]:
		if msg.contains(k):
			return COLOR_DAMAGE
	for k in ["poisoned", "freezes", "frozen", "thaws", "Electrified", "stunned",
			"Poison wears off", "current leaves", "steals"]:
		if msg.contains(k):
			return COLOR_STATUS
	for k in ["Level up", "dropped:", "Picked up"]:
		if msg.contains(k):
			return COLOR_REWARD
	for k in ["restore", "pick some berries"]:
		if msg.contains(k):
			return COLOR_HEAL
	return COLOR_DEFAULT
