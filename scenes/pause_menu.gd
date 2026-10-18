extends CanvasLayer

const OptionsMenu := preload("res://scenes/options_menu.gd")
const MAIN_MENU_SCENE := "res://scenes/init.tscn"

var _root: Control
var _center: CenterContainer
var _options: Control = null


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks to the map/UI below
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.14, 0.97)
	sb.border_color = Color(0.35, 0.35, 0.42, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", sb)
	_center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(260, 0)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	vbox.add_child(_make_button("Resume", _on_resume))
	vbox.add_child(_make_button("Options", _on_options))
	vbox.add_child(_make_button("Main Menu", _on_main_menu))

	var hint := Label.new()
	hint.text = "Progress is saved automatically."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.62, 0.62, 0.68))
	vbox.add_child(hint)


func _make_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(callback)
	return b


func _on_resume() -> void:
	get_viewport().set_input_as_handled()
	get_tree().paused = false
	queue_free()


func _on_options() -> void:
	_center.hide()
	_options = OptionsMenu.new()
	_root.add_child(_options)
	_options.closed.connect(_on_options_closed)


func _on_options_closed() -> void:
	if is_instance_valid(_options):
		_options.queue_free()
	_options = null
	_center.show()


func _on_main_menu() -> void:
	SaveManager.save()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	# Esc resumes. While Options is open it handles Esc itself first
	# (child nodes receive unhandled input before their parent).
	if event.is_action_pressed("ui_cancel"):
		_on_resume()
