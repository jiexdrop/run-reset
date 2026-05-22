extends Control
class_name BagUI

## BagUI — floating overlay showing all 24 bag slots.
##
## Signals forwarded to InventoryUI for unified drag-drop handling:
##   drag_requested(container, index)
##   drop_requested(container, index)
##   closed()

signal drag_requested(container: String, index: int)
signal drop_requested(container: String, index: int)
signal closed

const ItemSlotScene = preload("res://scenes/item_slot.tscn")
const COLUMNS       = 6

@onready var _grid:      GridContainer = $Panel/VBox/SlotGrid
@onready var _close_btn: Button        = $Panel/VBox/TitleBar/CloseButton

var _slots: Array = []


func _ready() -> void:
	_close_btn.pressed.connect(_on_close)
	_build_slots()
	InventoryState.inventory_changed.connect(_on_inventory_changed)
	_grid.columns = COLUMNS


func _build_slots() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_slots.clear()

	for i in range(InventoryState.BAG_SIZE):
		var slot: ItemSlot = ItemSlotScene.instantiate()
		_grid.add_child(slot)
		slot.setup("bag", i, true)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.drag_started.connect(_on_slot_drag)
		slot.drop_received.connect(_on_slot_drop)
		_slots.append(slot)


func _on_inventory_changed() -> void:
	for slot in _slots:
		slot.refresh()


func _on_slot_clicked(container: String, index: int) -> void:
	emit_signal("drop_requested", container, index)


func _on_slot_drag(container: String, index: int) -> void:
	emit_signal("drag_requested", container, index)


func _on_slot_drop(container: String, index: int) -> void:
	emit_signal("drop_requested", container, index)


func _on_close() -> void:
	emit_signal("closed")
	queue_free()
