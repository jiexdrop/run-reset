extends Control
class_name ShopUI

signal closed

const MERCHANT_TEX  = preload("res://assets/characters/merchant.png")
const COIN_TEX      = preload("res://assets/ui/coin.png")
const BAG_TEX       = preload("res://assets/ui/bag.png")
const MONEY_BAG_TEX = preload("res://assets/ui/money_bag.png")

var _stock: Array = []
var _gift_claimed: bool = false
var _current_tab: String = "buy"   # "buy" or "sell"

# UI Node refs
var _gold_label: Label = null
var _subtitle_label: Label = null
var _buy_tab_btn: Button = null
var _sell_tab_btn: Button = null
var _content_area: Control = null
var _feedback_label: Label = null

func _ready() -> void:
	add_to_group("shop_ui")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Enable inventory drag-drop while shop is open
	_set_drag_enabled(true)

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
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
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
	panel.custom_minimum_size = Vector2(480, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.10, 0.14, 0.98)
	sb.border_color = Color(0.65, 0.52, 0.28, 0.9)
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
	avatar.custom_minimum_size = Vector2(46, 46)
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

	_subtitle_label = Label.new()
	_subtitle_label.text = "Rest your feet, traveler. Care to trade?"
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	title_col.add_child(_subtitle_label)

	# Gold badge in header
	var gold_panel := PanelContainer.new()
	var g_sb := StyleBoxFlat.new()
	g_sb.bg_color = Color(0.18, 0.15, 0.10, 0.9)
	g_sb.border_color = Color(0.8, 0.65, 0.25, 0.8)
	g_sb.set_border_width_all(1)
	g_sb.set_corner_radius_all(6)
	g_sb.content_margin_left = 8
	g_sb.content_margin_right = 10
	g_sb.content_margin_top = 4
	g_sb.content_margin_bottom = 4
	gold_panel.add_theme_stylebox_override("panel", g_sb)
	header.add_child(gold_panel)

	var g_hbox := HBoxContainer.new()
	g_hbox.add_theme_constant_override("separation", 6)
	gold_panel.add_child(g_hbox)

	var g_icon := TextureRect.new()
	g_icon.texture = COIN_TEX
	g_icon.custom_minimum_size = Vector2(16, 16)
	g_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g_hbox.add_child(g_icon)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 13)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	g_hbox.add_child(_gold_label)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	layout.add_child(HSeparator.new())

	# ── Mode Selection Tabs (Buy / Sell) ──
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	layout.add_child(tab_row)

	_buy_tab_btn = Button.new()
	_buy_tab_btn.text = "Buy Wares"
	_buy_tab_btn.icon = BAG_TEX
	_buy_tab_btn.expand_icon = true
	_buy_tab_btn.add_theme_constant_override("icon_max_width", 20)
	_buy_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_tab_btn.custom_minimum_size = Vector2(0, 34)
	_buy_tab_btn.pressed.connect(func(): _switch_tab("buy"))
	tab_row.add_child(_buy_tab_btn)

	_sell_tab_btn = Button.new()
	_sell_tab_btn.text = "Sell Items"
	_sell_tab_btn.icon = MONEY_BAG_TEX
	_sell_tab_btn.expand_icon = true
	_sell_tab_btn.add_theme_constant_override("icon_max_width", 20)
	_sell_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_tab_btn.custom_minimum_size = Vector2(0, 34)
	_sell_tab_btn.pressed.connect(func(): _switch_tab("sell"))
	tab_row.add_child(_sell_tab_btn)

	# Feedback notification label (e.g. "Sold Iron Sword for 6 Gold!")
	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 12)
	_feedback_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_feedback_label.visible = false
	layout.add_child(_feedback_label)

	# ── Main Content Area (swapped between Buy and Sell views) ──
	_content_area = VBoxContainer.new()
	_content_area.add_theme_constant_override("separation", 8)
	layout.add_child(_content_area)

	layout.add_child(HSeparator.new())

	# ── Bottom Bar ──
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	layout.add_child(bottom_row)

	var bag_btn := Button.new()
	bag_btn.text = "Open Bag"
	bag_btn.tooltip_text = "View all items in your bag"
	bag_btn.pressed.connect(_on_open_bag_pressed)
	bottom_row.add_child(bag_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)

	var leave_btn := Button.new()
	leave_btn.text = "Leave Shop"
	leave_btn.custom_minimum_size = Vector2(100, 30)
	leave_btn.pressed.connect(_on_close)
	bottom_row.add_child(leave_btn)


func _switch_tab(tab: String) -> void:
	_current_tab = tab
	_refresh()


func _refresh() -> void:
	var gold: int = GameState.get_gold()
	if _gold_label:
		_gold_label.text = "%d Gold" % gold

	# Style tab buttons
	if _buy_tab_btn and _sell_tab_btn:
		_style_tab_btn(_buy_tab_btn, _current_tab == "buy")
		_style_tab_btn(_sell_tab_btn, _current_tab == "sell")

	if _content_area == null:
		return

	for c in _content_area.get_children():
		c.queue_free()

	if _current_tab == "buy":
		_subtitle_label.text = "Browse fine wares for sale. Prices in Gold."
		_build_buy_view()
	else:
		_subtitle_label.text = "Exchange any item from your pack for Gold."
		_build_sell_view()


func _style_tab_btn(btn: Button, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.24, 0.20, 0.14, 0.98)
		sb.border_color = Color(0.9, 0.75, 0.35, 1.0)
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	else:
		sb.bg_color = Color(0.14, 0.13, 0.17, 0.8)
		sb.border_color = Color(0.3, 0.28, 0.35, 0.6)
		sb.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)


# ── BUY VIEW ──────────────────────────────────────────────────────────────────

func _build_buy_view() -> void:
	var gold := GameState.get_gold()

	var wares_box := VBoxContainer.new()
	wares_box.add_theme_constant_override("separation", 6)
	_content_area.add_child(wares_box)

	for idx in range(_stock.size()):
		var item: Dictionary = _stock[idx]
		var item_key: String = item.get("item_key", "")
		var count: int       = int(item.get("count", 1))
		var cost: int        = int(item.get("cost", ItemRegistry.get_buy_price(item_key) * count))
		var sold: bool       = bool(item.get("sold", false))

		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.18, 0.17, 0.22, 0.75) if not sold else Color(0.12, 0.12, 0.14, 0.4)
		card_sb.border_color = Color(0.4, 0.36, 0.45, 0.6) if not sold else Color(0.2, 0.2, 0.2, 0.3)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(6)
		card_sb.content_margin_left   = 8
		card_sb.content_margin_right  = 8
		card_sb.content_margin_top    = 6
		card_sb.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", card_sb)
		wares_box.add_child(card)

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
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95) if not sold else Color(0.5, 0.5, 0.5))
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
		buy_col.custom_minimum_size = Vector2(90, 0)
		row.add_child(buy_col)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(90, 30)

		if sold:
			buy_btn.text = "Sold"
			buy_btn.icon = null
			buy_btn.disabled = true
		else:
			buy_btn.text = "%d Gold" % cost
			buy_btn.icon = COIN_TEX
			buy_btn.expand_icon = true
			buy_btn.add_theme_constant_override("icon_max_width", 16)
			var can_afford: bool = (gold >= cost)
			var has_space: bool = (InventoryState.get_free_space(item_key) >= count)
			buy_btn.disabled = (not can_afford) or (not has_space)
			if not has_space:
				buy_btn.tooltip_text = "Pack is full!"
			elif not can_afford:
				buy_btn.tooltip_text = "Need %d Gold (you have %d)" % [cost, gold]
			else:
				buy_btn.tooltip_text = "Click to purchase"
			buy_btn.pressed.connect(_on_buy_pressed.bind(idx))

		buy_col.add_child(buy_btn)

	# Starter gift if player has 0 gold
	if not _gift_claimed and gold == 0:
		var gift_panel := PanelContainer.new()
		var g_sb := StyleBoxFlat.new()
		g_sb.bg_color = Color(0.2, 0.18, 0.12, 0.8)
		g_sb.border_color = Color(0.7, 0.58, 0.22, 0.8)
		g_sb.set_border_width_all(1)
		g_sb.set_corner_radius_all(6)
		g_sb.content_margin_left   = 10
		g_sb.content_margin_right  = 10
		g_sb.content_margin_top    = 6
		g_sb.content_margin_bottom = 6
		gift_panel.add_theme_stylebox_override("panel", g_sb)
		_content_area.add_child(gift_panel)

		var g_row := HBoxContainer.new()
		g_row.add_theme_constant_override("separation", 8)
		gift_panel.add_child(g_row)

		var g_lbl := Label.new()
		g_lbl.text = "Need starting funds? Take 5 Gold on the house."
		g_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g_lbl.add_theme_font_size_override("font_size", 12)
		g_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		g_row.add_child(g_lbl)

		var g_btn := Button.new()
		g_btn.text = "Take 5 Gold"
		g_btn.custom_minimum_size = Vector2(95, 26)
		g_btn.pressed.connect(_on_claim_starter_gift)
		g_row.add_child(g_btn)


func _on_buy_pressed(idx: int) -> void:
	if idx < 0 or idx >= _stock.size():
		return
	var item: Dictionary = _stock[idx]
	if item.get("sold", false):
		return

	var item_key: String = item.get("item_key", "")
	var count: int       = int(item.get("count", 1))
	var cost: int        = int(item.get("cost", ItemRegistry.get_buy_price(item_key) * count))

	if not GameState.spend_gold(cost):
		_show_feedback("Not enough Gold to buy %s." % ItemRegistry.get_item_name(item_key), false)
		return

	if InventoryState.get_free_space(item_key) < count:
		# Refund
		GameState.add_gold(cost)
		_show_feedback("Your pack is full — cannot carry %s." % ItemRegistry.get_item_name(item_key), false)
		return

	InventoryState.add_item(item_key, count)
	item["sold"] = true
	_stock[idx] = item

	# Save to tile state
	if GameState.tiles.has("1,0"):
		GameState.tiles["1,0"]["merchant_stock"] = _stock
	GameState.mark_dirty()
	SaveManager.save()

	var item_name := ItemRegistry.get_item_name(item_key)
	var count_str := (" x%d" % count) if count > 1 else ""
	var msg := "Bought %s%s for %d Gold." % [item_name, count_str, cost]
	_log_to_combat(msg)
	_show_feedback(msg, true)
	_refresh()


func _on_claim_starter_gift() -> void:
	if _gift_claimed:
		return
	_gift_claimed = true
	GameState.add_gold(5)

	if GameState.tiles.has("1,0"):
		GameState.tiles["1,0"]["gift_claimed"] = true
	GameState.mark_dirty()
	SaveManager.save()

	_log_to_combat("The merchant gives you 5 Gold.")
	_show_feedback("Received 5 Gold from the merchant!", true)
	_refresh()


# ── SELL VIEW ─────────────────────────────────────────────────────────────────

func _build_sell_view() -> void:
	# 1. Prominent Sell Drop Zone
	var drop_zone := _SellDropTarget.new()
	drop_zone.shop_ui = self
	drop_zone.custom_minimum_size = Vector2(0, 85)
	_content_area.add_child(drop_zone)

	var drop_box := PanelContainer.new()
	drop_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drop_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dz_sb := StyleBoxFlat.new()
	dz_sb.bg_color = Color(0.14, 0.12, 0.16, 0.95)
	dz_sb.border_color = Color(0.95, 0.78, 0.32, 0.9)
	dz_sb.set_border_width_all(2)
	dz_sb.set_corner_radius_all(8)
	dz_sb.content_margin_left   = 12
	dz_sb.content_margin_right  = 12
	dz_sb.content_margin_top    = 10
	dz_sb.content_margin_bottom = 10
	drop_box.add_theme_stylebox_override("panel", dz_sb)
	drop_zone.add_child(drop_box)

	var dz_vbox := VBoxContainer.new()
	dz_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dz_vbox.add_theme_constant_override("separation", 3)
	drop_box.add_child(dz_vbox)

	var dz_title_row := HBoxContainer.new()
	dz_title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dz_title_row.add_theme_constant_override("separation", 8)
	dz_vbox.add_child(dz_title_row)

	var dz_icon := TextureRect.new()
	dz_icon.texture = MONEY_BAG_TEX
	dz_icon.custom_minimum_size = Vector2(20, 20)
	dz_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dz_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dz_title_row.add_child(dz_icon)

	var dz_title := Label.new()
	dz_title.text = "DROP ANY ITEM HERE TO SELL"
	dz_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dz_title.add_theme_font_size_override("font_size", 14)
	dz_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	dz_title_row.add_child(dz_title)

	var dz_sub := Label.new()
	dz_sub.text = "Drag an item from your Hotbar or Bag and release it here."
	dz_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dz_sub.add_theme_font_size_override("font_size", 11)
	dz_sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	dz_vbox.add_child(dz_sub)

	# 2. Quick Sell Pack List
	var list_header := HBoxContainer.new()
	_content_area.add_child(list_header)

	var lh_title := Label.new()
	lh_title.text = "Your Pack (Click to Sell):"
	lh_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lh_title.add_theme_font_size_override("font_size", 13)
	lh_title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	list_header.add_child(lh_title)

	# Scrollable inventory items list
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 160)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_area.add_child(scroll)

	var inv_list := VBoxContainer.new()
	inv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_list.add_theme_constant_override("separation", 4)
	scroll.add_child(inv_list)

	var items_found := 0

	# Iterate Hotbar and Bag
	for container_name in ["hotbar", "bag"]:
		var slots: Array = InventoryState.hotbar if container_name == "hotbar" else InventoryState.bag
		for idx in range(slots.size()):
			var slot: Dictionary = slots[idx]
			var item_key: String = slot.get("item_key", "")
			var count: int       = int(slot.get("count", 0))
			if item_key == "" or count <= 0:
				continue

			items_found += 1
			var unit_val: int = ItemRegistry.get_sell_value(item_key)
			var total_val: int = unit_val * count

			var item_row := PanelContainer.new()
			var r_sb := StyleBoxFlat.new()
			r_sb.bg_color = Color(0.16, 0.15, 0.19, 0.7)
			r_sb.border_color = Color(0.28, 0.26, 0.33, 0.5)
			r_sb.set_border_width_all(1)
			r_sb.set_corner_radius_all(5)
			r_sb.content_margin_left   = 6
			r_sb.content_margin_right  = 6
			r_sb.content_margin_top    = 4
			r_sb.content_margin_bottom = 4
			item_row.add_theme_stylebox_override("panel", r_sb)
			inv_list.add_child(item_row)

			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			item_row.add_child(h)

			var icon := TextureRect.new()
			icon.texture = ItemRegistry.get_icon(item_key)
			icon.custom_minimum_size = Vector2(28, 28)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h.add_child(icon)

			var name_col := VBoxContainer.new()
			name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_col.add_theme_constant_override("separation", 0)
			h.add_child(name_col)

			var name_l := Label.new()
			name_l.text = "%s%s" % [ItemRegistry.get_item_name(item_key), (" x%d" % count) if count > 1 else ""]
			name_l.add_theme_font_size_override("font_size", 13)
			name_col.add_child(name_l)

			var loc_l := Label.new()
			loc_l.text = "%s slot %d" % [container_name.capitalize(), idx + 1]
			loc_l.add_theme_font_size_override("font_size", 10)
			loc_l.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
			name_col.add_child(loc_l)

			var val_box := HBoxContainer.new()
			val_box.add_theme_constant_override("separation", 4)
			h.add_child(val_box)

			var val_icon := TextureRect.new()
			val_icon.texture = COIN_TEX
			val_icon.custom_minimum_size = Vector2(14, 14)
			val_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			val_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			val_box.add_child(val_icon)

			var val_l := Label.new()
			val_l.text = "+%d Gold" % total_val
			val_l.add_theme_font_size_override("font_size", 12)
			val_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
			val_box.add_child(val_l)

			var sell_btn := Button.new()
			sell_btn.text = "Sell"
			sell_btn.custom_minimum_size = Vector2(60, 24)
			sell_btn.pressed.connect(_on_quick_sell_pressed.bind(container_name, idx))
			h.add_child(sell_btn)

	if items_found == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "Your pack is empty! Find loot in the dungeon to sell."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		inv_list.add_child(empty_lbl)


## Invoked when an item is dragged from hotbar/bag and dropped onto the drop target
func handle_item_drop(source_container: String, source_index: int) -> void:
	var taken: Dictionary = InventoryState.take_slot_item(source_container, source_index)
	if taken.is_empty():
		return

	var item_key: String = taken.get("item_key", "")
	var count: int       = int(taken.get("count", 1))
	var unit_val: int    = ItemRegistry.get_sell_value(item_key)
	var total_gold: int  = unit_val * count

	GameState.add_gold(total_gold)

	var item_name: String = ItemRegistry.get_item_name(item_key)
	var count_str: String = (" x%d" % count) if count > 1 else ""
	var msg: String = "Sold %s%s for +%d Gold!" % [item_name, count_str, total_gold]

	_log_to_combat(msg)
	_show_feedback(msg, true)
	_refresh()


func _on_quick_sell_pressed(container: String, index: int) -> void:
	handle_item_drop(container, index)


func _show_feedback(text: String, success: bool) -> void:
	if _feedback_label == null:
		return
	_feedback_label.text = text
	_feedback_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6) if success else Color(1.0, 0.5, 0.5))
	_feedback_label.visible = true

	# Fade out after 3 seconds
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		_feedback_label.visible = false
		_feedback_label.modulate.a = 1.0
	)


func _on_open_bag_pressed() -> void:
	var cui = get_tree().get_first_node_in_group("combat_ui")
	if cui and cui.has_method("_on_bag_opened"):
		cui._on_bag_opened()


func _set_drag_enabled(enabled: bool) -> void:
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui and inv_ui.has_method("set_drag_enabled"):
		inv_ui.set_drag_enabled(enabled)


func _log_to_combat(msg: String) -> void:
	var cui = get_tree().get_first_node_in_group("combat_ui")
	if cui and cui.has_method("log_message"):
		cui.log_message(msg)


func _on_close() -> void:
	_set_drag_enabled(false)
	ItemSlot.cancel_drag()
	emit_signal("closed")
	queue_free()


# ── Internal Drop Target Class ────────────────────────────────────────────────

class _SellDropTarget extends Control:
	var shop_ui: ShopUI = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	## Custom drop handler matching ItemSlot drag logic
	func receive_inventory_drop(source_container: String, source_index: int) -> void:
		if is_instance_valid(shop_ui):
			shop_ui.handle_item_drop(source_container, source_index)
