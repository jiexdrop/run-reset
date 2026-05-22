extends Control
class_name InventoryUI

## InventoryUI — hotbar strip shown permanently inside CombatUI.
## Mirrors BagUI's pattern exactly: builds ItemSlot instances, listens to
## InventoryState.inventory_changed, and forwards drag/drop signals upward.

signal drag_requested(container: String, index: int)
signal drop_requested(container: String, index: int)
signal bag_opened

const ItemSlotScene = preload("res://scenes/item_slot.tscn")

@onready var slot_grid  : GridContainer = $VBox/ScrollContainer/SlotGrid
@onready var bag_button : Button        = $VBox/HeaderRow/BagButton

var _slots: Array = []


func _ready() -> void:
	bag_button.pressed.connect(func(): bag_opened.emit())
	_build_slots()
	InventoryState.inventory_changed.connect(_on_inventory_changed)
	# Keep columns responsive to width changes.
	resized.connect(_update_columns)
	_update_columns()


# ── Slot construction ─────────────────────────────────────────────────────────

func _build_slots() -> void:
	for child in slot_grid.get_children():
		child.queue_free()
	_slots.clear()

	for i in range(InventoryState.HOTBAR_SIZE):
		var slot: ItemSlot = ItemSlotScene.instantiate()
		slot_grid.add_child(slot)
		slot.setup("hotbar", i, false)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.drag_started.connect(_on_slot_drag)
		slot.drop_received.connect(_on_slot_drop)
		_slots.append(slot)


# ── Responsive columns ────────────────────────────────────────────────────────

func _update_columns() -> void:
	if slot_grid == null:
		return
	const SLOT_W   :       = 56   # ItemSlot custom_minimum_size.x
	const SEP      :       = 4    # h_separation in the scene
	var available  : float = slot_grid.get_parent().size.x
	if available <= 0:
		available = size.x
	var cols := int((available + SEP) / (SLOT_W + SEP))
	cols = clampi(cols, 2, InventoryState.HOTBAR_SIZE)
	if slot_grid.columns != cols:
		slot_grid.columns = cols


# ── Signal forwarding ─────────────────────────────────────────────────────────

func _on_inventory_changed() -> void:
	for slot in _slots:
		slot.refresh()


func _on_slot_clicked(container: String, index: int) -> void:
	drop_requested.emit(container, index)


func _on_slot_drag(container: String, index: int) -> void:
	drag_requested.emit(container, index)


func _on_slot_drop(container: String, index: int) -> void:
	drop_requested.emit(container, index)
