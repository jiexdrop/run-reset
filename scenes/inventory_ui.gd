extends Control
class_name InventoryUI

## InventoryUI — the 8-slot hotbar strip shown inside CombatUI.
##
## Layout (left→right):
##   [Slot0][Slot1]…[Slot7]  [🎒 Bag]
##
## The "Bag" button opens the BagUI overlay (spawned as a sibling in the scene tree).

const ItemSlotScene = preload("res://scenes/item_slot.tscn")
const BagUIScene    = preload("res://scenes/bag_ui.tscn")

@onready var _slot_row: HBoxContainer = $HBox/SlotRow
@onready var _bag_btn:  Button        = $HBox/BagButton

var _slots: Array  = []    # Array[ItemSlot]
var _bag_ui: Control = null

# Drag state
var _drag_container: String = ""
var _drag_index:     int    = -1
var _drag_ghost:     Control = null


func _ready() -> void:
	_build_slots()
	InventoryState.inventory_changed.connect(_on_inventory_changed)
	_bag_btn.pressed.connect(_toggle_bag)


# ── Build ─────────────────────────────────────────────────────────────────────

func _build_slots() -> void:
	for child in _slot_row.get_children():
		child.queue_free()
	_slots.clear()

	for i in range(InventoryState.HOTBAR_SIZE):
		var slot: ItemSlot = ItemSlotScene.instantiate()
		_slot_row.add_child(slot)
		slot.setup("hotbar", i, false)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.drag_started.connect(_on_drag_started)
		slot.drop_received.connect(_on_drop_received)
		_slots.append(slot)


# ── Refresh ───────────────────────────────────────────────────────────────────

func _on_inventory_changed() -> void:
	for slot in _slots:
		slot.refresh()


# ── Slot interaction ──────────────────────────────────────────────────────────

func _on_slot_clicked(container: String, index: int) -> void:
	# If a drag is in progress, treat click as a drop target.
	if _drag_index >= 0:
		_complete_drop(container, index)
		return
	# Otherwise start drag from this slot (if non-empty and not frozen).
	var slot_data = InventoryState.hotbar[index] if container == "hotbar" else InventoryState.bag[index]
	if slot_data.get("item_key", "") == "" or slot_data.get("frozen", false):
		return
	_start_drag(container, index)


func _on_drag_started(container: String, index: int) -> void:
	_start_drag(container, index)


func _on_drop_received(container: String, index: int) -> void:
	_complete_drop(container, index)


func _start_drag(container: String, index: int) -> void:
	_drag_container = container
	_drag_index     = index
	_spawn_ghost(container, index)


func _complete_drop(target_container: String, target_index: int) -> void:
	if _drag_index < 0:
		return
	InventoryState.swap_slots(_drag_container, _drag_index, target_container, target_index)
	_cancel_drag()


func _cancel_drag() -> void:
	_drag_container = ""
	_drag_index     = -1
	if _drag_ghost:
		_drag_ghost.queue_free()
		_drag_ghost = null


# ── Ghost drag visual ─────────────────────────────────────────────────────────

func _spawn_ghost(container: String, index: int) -> void:
	if _drag_ghost:
		_drag_ghost.queue_free()

	var slot_data = InventoryState.hotbar[index] if container == "hotbar" else InventoryState.bag[index]
	var item_key  = slot_data.get("item_key", "")
	if item_key == "":
		return

	var ghost      = TextureRect.new()
	ghost.texture  = ItemRegistry.get_icon(item_key)
	ghost.custom_minimum_size = Vector2(48, 48)
	ghost.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.modulate            = Color(1, 1, 1, 0.7)
	ghost.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	ghost.z_index             = 100
	add_child(ghost)
	_drag_ghost = ghost


func _process(_delta: float) -> void:
	if _drag_ghost and _drag_index >= 0:
		_drag_ghost.global_position = get_global_mouse_position() - Vector2(24, 24)


func _unhandled_input(event: InputEvent) -> void:
	if _drag_index >= 0 and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_drag()


# ── Bag toggle ────────────────────────────────────────────────────────────────

func _toggle_bag() -> void:
	if _bag_ui and is_instance_valid(_bag_ui):
		_bag_ui.queue_free()
		_bag_ui = null
		_bag_btn.text = "🎒"
		return

	_bag_ui = BagUIScene.instantiate()
	# Add as sibling so it can float above CombatUI layout.
	get_parent().add_child(_bag_ui)
	_bag_ui.drag_requested.connect(_on_bag_drag_requested)
	_bag_ui.drop_requested.connect(_on_bag_drop_requested)
	_bag_ui.closed.connect(_on_bag_closed)
	_bag_btn.text = "✕"


func _on_bag_closed() -> void:
	_bag_ui = null
	_bag_btn.text = "🎒"


# Forwarded from BagUI — treat the same as hotbar drag/drop.
func _on_bag_drag_requested(container: String, index: int) -> void:
	_start_drag(container, index)


func _on_bag_drop_requested(container: String, index: int) -> void:
	_complete_drop(container, index)
