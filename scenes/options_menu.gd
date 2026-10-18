extends Control

## Emitted when the player presses Back (or Esc).
signal closed

const SETTINGS_PATH := "user://settings.cfg"

var _volume_slider: HSlider
var _volume_value: Label
var _fullscreen_check: CheckButton


## Applies saved audio + display settings. Safe to call when no file exists.
static func apply_saved() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)   # missing file just leaves cfg empty -> defaults below
	_apply_volume(float(cfg.get_value("audio", "master", 1.0)))
	_apply_fullscreen(bool(cfg.get_value("display", "fullscreen", false)))


static func _apply_volume(v: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(idx, v <= 0.001)


static func _apply_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	var volume: float = float(cfg.get_value("audio", "master", 1.0))
	var fullscreen: bool = bool(cfg.get_value("display", "fullscreen", false))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Master volume
	var vol_label := Label.new()
	vol_label.text = "Master Volume"
	vbox.add_child(vol_label)

	var vol_row := HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 10)
	vbox.add_child(vol_row)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.value = volume
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume_slider.value_changed.connect(_on_volume_changed)
	vol_row.add_child(_volume_slider)

	_volume_value = Label.new()
	_volume_value.custom_minimum_size = Vector2(48, 0)
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_volume_value.text = "%d%%" % int(round(volume * 100.0))
	vol_row.add_child(_volume_value)

	# Fullscreen
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Fullscreen"
	_fullscreen_check.button_pressed = fullscreen
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(_fullscreen_check)

	vbox.add_child(HSeparator.new())

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 44)
	back.pressed.connect(_on_back)
	vbox.add_child(back)


func _make_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.14, 0.97)
	sb.border_color = Color(0.35, 0.35, 0.42, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	return sb


func _on_volume_changed(v: float) -> void:
	_volume_value.text = "%d%%" % int(round(v * 100.0))
	_apply_volume(v)
	_save()


func _on_fullscreen_toggled(on: bool) -> void:
	_apply_fullscreen(on)
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", _volume_slider.value)
	cfg.set_value("display", "fullscreen", _fullscreen_check.button_pressed)
	cfg.save(SETTINGS_PATH)


func _on_back() -> void:
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()
