extends PanelContainer
class_name ItemSlot

## ItemSlot — one inventory slot.
##
## States
## ──────
##   normal   : slot.png background
##   frozen   : slot_ice.png overlay (cannot drag)
##   selected : highlighted border (optional)
##
## Signals
## ───────
##   slot_clicked(container, index)
##   drag_started(container, index)
##   drop_received(container, index)

signal slot_clicked(container: String, index: int)
signal drag_started(container: String, index: int)
signal drop_received(container: String, index: int)

# Textures — set at runtime by InventoryUI / BagUI.
const TEX_SLOT     = preload("res://assets/ui/slot.png")
const TEX_SLOT_ICE = preload("res://assets/ui/slot_ice.png")
const TEX_SLOT_BAG = preload("res://assets/ui/slot.png")

const ICON_SIZE    = Vector2(48, 48)

# ── Which slot am I? ──────────────────────────────────────────────────────────
var container: String = "hotbar"   # "hotbar" or "bag"
var slot_index: int   = 0
var is_bag_slot: bool = false      # controls which base texture to use

# ── Internal state ─────────────────────────────────────────────────────────────
var _item_key: String = ""
var _frozen:   bool   = false
var _drag_enabled: bool = false

@onready var _bg:      TextureRect = $BgRect
@onready var _ice:     TextureRect = $IceOverlay
@onready var _icon:    TextureRect = $IconRect
@onready var _label:   Label       = $Label

# Shared across all ItemSlot instances — only one drag can be active at a time.
static var _drag_icon:   TextureRect = null
static var _drag_source: Dictionary = {}   # {"container": String, "index": int}
static var _dragging:    bool = false


# ── Setup ─────────────────────────────────────────────────────────────────────

func setup(p_container: String, p_index: int, p_is_bag: bool = false) -> void:
	container   = p_container
	slot_index  = p_index
	is_bag_slot = p_is_bag
	_bg.texture = TEX_SLOT_BAG if p_is_bag else TEX_SLOT
	_style_label()
	refresh()


func refresh() -> void:
	var slot_data: Dictionary = {}
	if container == "hotbar":
		if slot_index < InventoryState.hotbar.size():
			slot_data = InventoryState.hotbar[slot_index]
	else:
		if slot_index < InventoryState.bag.size():
			slot_data = InventoryState.bag[slot_index]

	_item_key = slot_data.get("item_key", "")
	_frozen   = slot_data.get("frozen", false)
	var count: int = slot_data.get("count", 0)
	var equipped: bool = (container == "hotbar" and slot_index == InventoryState.equipped_index)

	_ice.visible = _frozen

	if _item_key != "":
		var tex = ItemRegistry.get_icon(_item_key)
		_icon.texture = tex
		_icon.visible = (tex != null)
		_label.text = str(count) if count > 1 else ""
	else:
		_icon.visible = false
		_label.text   = ""

	if equipped:
		modulate = Color(1.0, 0.85, 0.35)
	elif _frozen:
		modulate = Color(0.7, 0.85, 1.0)
	else:
		modulate = Color.WHITE


# ── Mouse input / drag-drop (floating icon) ───────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not _drag_enabled:
		if event.pressed:
			emit_signal("slot_clicked", container, slot_index)
		return

	# Bag is open — clicks drive the manual drag instead of equip/consume.
	if event.pressed:
		_try_begin_drag()
	else:
		_try_end_drag()


func _process(_delta: float) -> void:
	if _dragging and is_instance_valid(_drag_icon):
		_drag_icon.global_position = get_global_mouse_position() - ICON_SIZE / 2.0


func _try_begin_drag() -> void:
	if _dragging or _frozen or _item_key == "":
		return

	_dragging    = true
	_drag_source = {"container": container, "index": slot_index}

	_drag_icon = TextureRect.new()
	_drag_icon.texture       = ItemRegistry.get_icon(_item_key)
	_drag_icon.custom_minimum_size = ICON_SIZE
	_drag_icon.size          = ICON_SIZE
	_drag_icon.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	_drag_icon.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_icon.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_drag_icon.modulate.a    = 0.85
	_drag_icon.z_index       = 4096

	get_tree().root.add_child(_drag_icon)
	_drag_icon.global_position = get_global_mouse_position() - ICON_SIZE / 2.0

	emit_signal("drag_started", container, slot_index)


func _try_end_drag() -> void:
	if not _dragging:
		return

	# NOTE: mouse-button capture means this release event is always routed
	# back to the slot where the drag *started*, not the slot currently under
	# the cursor — so we can't just check self's rect here. Ask the viewport
	# for the control actually being hovered instead.
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered is ItemSlot:
		hovered.receive_drop()

	_cleanup_drag()


## Called externally (e.g. BagUI on close, or a global cancel) to abort a
## drag without completing a drop.
static func cancel_drag() -> void:
	if _dragging:
		_cleanup_drag()


static func _cleanup_drag() -> void:
	if is_instance_valid(_drag_icon):
		_drag_icon.queue_free()
	_drag_icon   = null
	_dragging    = false
	_drag_source = {}


## Called when a drop resolves on this slot; uses the shared static
## _drag_source instead of Godot's built-in drag payload.
func receive_drop() -> void:
	if _drag_source.is_empty():
		return
	InventoryState.swap_slots(_drag_source["container"], _drag_source["index"], container, slot_index)


# ── Private ────────────────────────────────────────────────────────────────────

func _style_label() -> void:
	# Anchor the count label to the bottom-right corner of the slot.
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color",        Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)


## Called by InventoryUI / BagUI to turn dragging on/off for this slot.
func set_drag_enabled(enabled: bool) -> void:
	_drag_enabled = enabled
