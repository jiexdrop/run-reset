extends Control

## Debug-only zone selector. It mirrors the item browser overlay and asks the
## active game scene to create a normal exit door for the selected destination.

const PANEL_SIZE := Vector2(440, 420)

var _panel: PanelContainer
var _status: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_launcher()
	_build_panel()


func _build_launcher() -> void:
	var launcher := Button.new()
	launcher.text = "Zones"
	launcher.tooltip_text = "Debug zone and floor portal"
	launcher.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	launcher.position = Vector2(-158, 14)
	launcher.size = Vector2(68, 34)
	launcher.pressed.connect(func() -> void: _panel.visible = not _panel.visible)
	add_child(launcher)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DebugZoneBrowser"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = -PANEL_SIZE / 2.0
	_panel.size = PANEL_SIZE
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	_panel.add_child(layout)

	var title_row := HBoxContainer.new()
	layout.add_child(title_row)
	var title := Label.new()
	title.text = "Debug Zones"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func() -> void: _panel.hide())
	title_row.add_child(close)

	var hint := Label.new()
	hint.text = "Choose a destination, then click the portal that appears in the dungeon."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.75, 0.75, 0.75)
	layout.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var zones := VBoxContainer.new()
	zones.add_theme_constant_override("separation", 8)
	scroll.add_child(zones)

	for zone in ZoneRegistry.get_zone_ids():
		var row := HBoxContainer.new()
		zones.add_child(row)
		var name := Label.new()
		name.text = zone.capitalize()
		name.custom_minimum_size = Vector2(120, 0)
		row.add_child(name)
		for floor in range(1, 4):
			var button := Button.new()
			button.text = "Floor %d" % floor
			button.pressed.connect(_open_portal.bind(zone, floor))
			row.add_child(button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status)


func _open_portal(zone: String, floor: int) -> void:
	var games := get_tree().get_nodes_in_group("game")
	if games.is_empty():
		_status.text = "No active dungeon found."
		return
	games[0].open_debug_portal(zone, floor)
	_status.text = "Portal opened: %s, floor %d." % [zone.capitalize(), floor]
	_panel.hide()
