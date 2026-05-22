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
const TEX_SLOT_BAG = preload("res://assets/ui/slot_bag.png")

const ICON_SIZE    = Vector2(48, 48)

# ── Which slot am I? ──────────────────────────────────────────────────────────
var container: String = "hotbar"   # "hotbar" or "bag"
var slot_index: int   = 0
var is_bag_slot: bool = false      # controls which base texture to use

# ── Internal state ─────────────────────────────────────────────────────────────
var _item_key: String = ""
var _frozen:   bool   = false

@onready var _bg:      TextureRect = $BgRect
@onready var _ice:     TextureRect = $IceOverlay
@onready var _icon:    TextureRect = $IconRect
@onready var _label:   Label       = $Label


# ── Setup ─────────────────────────────────────────────────────────────────────

func setup(p_container: String, p_index: int, p_is_bag: bool = false) -> void:
	container   = p_container
	slot_index  = p_index
	is_bag_slot = p_is_bag
	_bg.texture = TEX_SLOT_BAG if p_is_bag else TEX_SLOT
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

	# Ice overlay
	_ice.visible = _frozen

	# Item icon
	if _item_key != "":
		var tex = ItemRegistry.get_icon(_item_key)
		_icon.texture = tex
		_icon.visible = (tex != null)
		_label.text   = ""
	else:
		_icon.visible = false
		_label.text   = ""

	# Visual feedback for frozen
	modulate = Color(0.7, 0.85, 1.0) if _frozen else Color.WHITE


# ── Mouse input / drag-drop ────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("slot_clicked", container, slot_index)


## Called by the drag-drop manager when a drag starts on this slot.
func begin_drag() -> void:
	if _frozen or _item_key == "":
		return
	emit_signal("drag_started", container, slot_index)


## Called by the drag-drop manager when something is dropped here.
func receive_drop() -> void:
	emit_signal("drop_received", container, slot_index)
