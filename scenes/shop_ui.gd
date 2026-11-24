extends Control
class_name ShopUI

signal closed

const MERCHANT_TEX = preload("res://assets/characters/merchant.png")
const BERRY_TEX    = preload("res://assets/items/berries.png")

var _stock: Array = []
var _gift_claimed: bool = false
var _berry_count_label: Label = null
var _wares_container: VBoxContainer = null
var _gift_container: Control = null

func _ready() -> void:
	add_to_group("shop_ui")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_refresh()


func setup(stock: Array, gift_claimed: bool = false) -> void:
	_stock = stock
	_gift_claimed = gift_claimed
	if is_inside_tree():
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_close()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	# Dark backdrop
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_close()
	)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.11, 0.15, 0.98)
	sb.border_color = Color(0.55, 0.45, 0.28, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left   = 16
	sb.content_margin_right  = 16
	sb.content_margin_top    = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	# ── Header ──
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var avatar := TextureRect.new()
	avatar.texture = MERCHANT_TEX
	avatar.custom_minimum_size = Vector2(44, 44)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(avatar)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	header.add_child(title_col)

	var title := Label.new()
	title.text = "Traveling Merchant"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.42))
	title_col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Rest your feet, traveler. Care to trade?"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	title_col.add_child(subtitle)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	layout.add_child(HSeparator.new())

	# ── Currency Status ──
	var berry_row := HBoxContainer.new()
	berry_row.add_theme_constant_override("separation", 6)
	layout.add_child(berry_row)

	var berry_icon := TextureRect.new()
	berry_icon.texture = BERRY_TEX
	berry_icon.custom_minimum_size = Vector2(20, 20)
	berry_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	berry_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	berry_row.add_child(berry_icon)

	_berry_count_label = Label.new()
	_berry_count_label.add_theme_font_size_override("font_size", 13)
	berry_row.add_child(_berry_count_label)

	layout.add_child(HSeparator.new())

	# ── Wares ──
	_wares_container = VBoxContainer.new()
	_wares_container.add_theme_constant_override("separation", 8)
	layout.add_child(_wares_container)

	# ── Gift Container (if broke) ──
	_gift_container = VBoxContainer.new()
	_gift_container.add_theme_constant_override("separation", 4)
	layout.add_child(_gift_container)

	layout.add_child(HSeparator.new())

	# ── Leave button ──
	var leave_btn := Button.new()
	leave_btn.text = "Leave Shop"
	leave_btn.custom_minimum_size = Vector2(0, 32)
	leave_btn.pressed.connect(_on_close)
	layout.add_child(leave_btn)


func _refresh() -> void:
	var berries := InventoryState.count_item("berries")
	if _berry_count_label:
		_berry_count_label.text = "Berries in pack: %d" % berries

	if _wares_container == null:
		return

	for c in _wares_container.get_children():
		c.queue_free()

	for idx in range(_stock.size()):
		var item: Dictionary = _stock[idx]
		var item_key: String = item.get("item_key", "")
		var count: int       = int(item.get("count", 1))
		var cost: int        = int(item.get("cost", 2))
		var sold: bool       = bool(item.get("sold", false))

		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.18, 0.17, 0.22, 0.75) if not sold else Color(0.12, 0.12, 0.14, 0.4)
		card_sb.border_color = Color(0.38, 0.35, 0.42, 0.6) if not sold else Color(0.2, 0.2, 0.2, 0.3)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(6)
		card_sb.content_margin_left   = 8
		card_sb.content_margin_right  = 8
		card_sb.content_margin_top    = 6
		card_sb.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", card_sb)
		_wares_container.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var icon := TextureRect.new()
		icon.texture = ItemRegistry.get_icon(item_key)
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if sold:
			icon.modulate = Color(0.4, 0.4, 0.4, 0.7)
		row.add_child(icon)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_col.add_theme_constant_override("separation", 2)
		row.add_child(info_col)

		var name_lbl := Label.new()
		var display_name := ItemRegistry.get_item_name(item_key)
		if count > 1:
			display_name += " x%d" % count
		name_lbl.text = display_name
		name_lbl.add_theme_font_size_override("font_size", 14)
		if sold:
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		info_col.add_child(name_lbl)

		var desc_lbl := Label.new()
		var desc_text := ItemRegistry.get_desc(item_key).strip_edges().split("\n")[0]
		desc_lbl.text = desc_text
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info_col.add_child(desc_lbl)

		var buy_col := VBoxContainer.new()
		buy_col.alignment = BoxContainer.ALIGNMENT_CENTER
		buy_col.custom_minimum_size = Vector2(85, 0)
		row.add_child(buy_col)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(85, 30)

		if sold:
			buy_btn.text = "Sold"
			buy_btn.disabled = true
		else:
			buy_btn.text = "%d Berries" % cost
			var can_afford: bool = (berries >= cost)
			var has_space: bool = (InventoryState.get_free_space(item_key) >= count)
			buy_btn.disabled = (not can_afford) or (not has_space)
			if not has_space:
				buy_btn.tooltip_text = "Pack is full!"
			elif not can_afford:
				buy_btn.tooltip_text = "Need %d berries (you have %d)" % [cost, berries]
			else:
				buy_btn.tooltip_text = "Click to purchase"
			buy_btn.pressed.connect(_on_buy_pressed.bind(idx))

		buy_col.add_child(buy_btn)

	# ── Gift logic ──
	for c in _gift_container.get_children():
		c.queue_free()

	if not _gift_claimed and berries < 2:
		var gift_panel := PanelContainer.new()
		var g_sb := StyleBoxFlat.new()
		g_sb.bg_color = Color(0.2, 0.18, 0.12, 0.8)
		g_sb.border_color = Color(0.6, 0.5, 0.2, 0.7)
		g_sb.set_border_width_all(1)
		g_sb.set_corner_radius_all(6)
		g_sb.content_margin_left   = 8
		g_sb.content_margin_right  = 8
		g_sb.content_margin_top    = 6
		g_sb.content_margin_bottom = 6
		gift_panel.add_theme_stylebox_override("panel", g_sb)
		_gift_container.add_child(gift_panel)

		var g_row := HBoxContainer.new()
		g_row.add_theme_constant_override("separation", 8)
		gift_panel.add_child(g_row)

		var g_lbl := Label.new()
		g_lbl.text = "Down on your luck? Take some berries on the house."
		g_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g_lbl.add_theme_font_size_override("font_size", 11)
		g_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		g_row.add_child(g_lbl)

		var g_btn := Button.new()
		g_btn.text = "Take 2 Berries"
		g_btn.custom_minimum_size = Vector2(95, 26)
		g_btn.pressed.connect(_on_claim_gift)
		g_row.add_child(g_btn)


func _on_buy_pressed(idx: int) -> void:
	if idx < 0 or idx >= _stock.size():
		return
	var item: Dictionary = _stock[idx]
	if item.get("sold", false):
		return

	var item_key: String = item.get("item_key", "")
	var count: int       = int(item.get("count", 1))
	var cost: int        = int(item.get("cost", 2))

	var berries := InventoryState.count_item("berries")
	if berries < cost:
		_log_to_combat("Not enough berries to buy %s." % ItemRegistry.get_item_name(item_key))
		return

	if InventoryState.get_free_space(item_key) < count:
		_log_to_combat("Your pack is full — cannot carry %s." % ItemRegistry.get_item_name(item_key))
		return

	for _i in range(cost):
		InventoryState.consume_item("berries")

	InventoryState.add_item(item_key, count)
	item["sold"] = true
	_stock[idx] = item

	# Save to tile state
	if GameState.tiles.has("1,0"):
		GameState.tiles["1,0"]["merchant_stock"] = _stock
	GameState.mark_dirty()
	SaveManager.save()

	var item_name := ItemRegistry.get_item_name(item_key)
	if count > 1:
		_log_to_combat("Bought %s x%d for %d Berries." % [item_name, count, cost])
	else:
		_log_to_combat("Bought %s for %d Berries." % [item_name, cost])

	_refresh()


func _on_claim_gift() -> void:
	if _gift_claimed:
		return
	_gift_claimed = true
	InventoryState.add_item("berries", 2)

	if GameState.tiles.has("1,0"):
		GameState.tiles["1,0"]["gift_claimed"] = true
	GameState.mark_dirty()
	SaveManager.save()

	_log_to_combat("The merchant hands you 2 wild berries.")
	_refresh()


func _log_to_combat(msg: String) -> void:
	var cui = get_tree().get_first_node_in_group("combat_ui")
	if cui and cui.has_method("log_message"):
		cui.log_message(msg)


func _on_close() -> void:
	emit_signal("closed")
	queue_free()
