extends PanelContainer
class_name ChatLog


## ChatLog — bottom-left message window. Finds itself via group "chat_log";
## combat_ui.gd forwards every _log() call here. Children are built in code.


const MAX_PARAGRAPHS := 200
const FONT_SIZE      := 14
const HEADER_SIZE    := 11


const COLOR_DEFAULT := Color(0.89, 0.89, 0.91)
const COLOR_DAMAGE  := Color(1.00, 0.56, 0.52)
const COLOR_STATUS  := Color(0.66, 0.84, 1.00)
const COLOR_REWARD  := Color(1.00, 0.85, 0.42)
const COLOR_HEAL    := Color(0.60, 0.90, 0.62)
const COLOR_SYSTEM  := Color(0.62, 0.62, 0.68)


var _text: RichTextLabel
var _has_content := false




func _ready() -> void:
	add_to_group("chat_log")


	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.07, 0.09, 0.94)
	sb.border_color = Color(0.28, 0.28, 0.34, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left   = 12
	sb.content_margin_right  = 12
	sb.content_margin_top    = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)


	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)


	var header := Label.new()
	header.text = "LOG"
	header.add_theme_font_size_override("font_size", HEADER_SIZE)
	header.add_theme_color_override("font_color", COLOR_SYSTEM)
	vbox.add_child(header)


	vbox.add_child(HSeparator.new())


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
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_text.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_text.add_theme_color_override("default_color", COLOR_DEFAULT)
	_text.add_theme_constant_override("line_separation", 3)
	vbox.add_child(_text)




func add_message(msg: String) -> void:
	if msg == "" or _text == null:
		return
	var safe := msg.replace("[", "[lb]")
	var line := "[color=#%s]%s[/color]" % [_color_for(msg).to_html(false), safe]
	if _has_content:
		_text.append_text("\n" + line)
	else:
		_text.append_text(line)
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
