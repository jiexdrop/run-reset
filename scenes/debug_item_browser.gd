extends Control

## A debug-only, Too Many Items-style catalog. Main creates this node only when
## OS.is_debug_build() is true, keeping it out of release/package builds.

const PANEL_SIZE := Vector2(620, 520)
const CARD_WIDTH := 180

var _panel: PanelContainer
var _status: Label
var _search: LineEdit
var _grid: GridContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_launcher()
	_build_panel()


func _build_launcher() -> void:
	var launcher := Button.new()
	launcher.text = "Items"
	launcher.tooltip_text = "Debug item browser"
	launcher.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	launcher.position = Vector2(-82, 14)
	launcher.size = Vector2(68, 34)
	launcher.pressed.connect(func() -> void:
		_panel.visible = not _panel.visible
		if _panel.visible:
			_search.grab_focus()
	)
	add_child(launcher)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DebugItemBrowser"
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
	title.text = "Debug Items"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func() -> void: _panel.hide())
	title_row.add_child(close)

	_search = LineEdit.new()
	_search.placeholder_text = "Filter items..."
	_search.text_changed.connect(func(_text: String) -> void: _rebuild_items())
	layout.add_child(_search)

	var hint := Label.new()
	hint.text = "Click Give to add one full stack to your inventory."
	hint.modulate = Color(0.75, 0.75, 0.75)
	layout.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status)
	_rebuild_items()


func _rebuild_items() -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		child.queue_free()

	var filter := _search.text.strip_edges().to_lower()
	for item_key in ItemRegistry.get_item_keys():
		var item_name := ItemRegistry.get_item_name(item_key)
		if not filter.is_empty() and filter not in item_name.to_lower() and filter not in item_key.to_lower():
			continue
		_grid.add_child(_make_item_card(item_key, item_name))


func _make_item_card(item_key: String, item_name: String) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	card.add_theme_constant_override("separation", 3)

	var info := HBoxContainer.new()
	card.add_child(info)
	var icon := TextureRect.new()
	icon.texture = ItemRegistry.get_icon(item_key)
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info.add_child(icon)
	var name_label := Label.new()
	name_label.text = item_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(name_label)

	var give := Button.new()
	var amount := ItemRegistry.get_max_stack(item_key)
	give.text = "Give x%d" % amount
	give.tooltip_text = ItemRegistry.get_desc(item_key)
	give.pressed.connect(func() -> void: _give_item(item_key, amount))
	card.add_child(give)
	return card


func _give_item(item_key: String, amount: int) -> void:
	var remaining := InventoryState.add_item(item_key, amount)
	var added := amount - remaining
	if added == 0:
		_status.text = "Inventory is full — could not add %s." % ItemRegistry.get_item_name(item_key)
		return
	_status.text = "Added %d x %s%s" % [
		added,
		ItemRegistry.get_item_name(item_key),
		" (inventory full)" if remaining > 0 else ".",
	]
	SaveManager.save()
