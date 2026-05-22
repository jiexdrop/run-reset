extends Control

## Emitted when a slot is clicked. Passes the container + index (matches ItemSlot signal).
signal slot_clicked(index: int)
## Emitted when the bag button is pressed.
signal bag_opened

# ── Configuration ────────────────────────────────────────────────────────────
const ItemSlotScene  = preload("res://scenes/item_slot.tscn")
const SLOT_MIN_COLS  := 2
const SLOT_MAX_COLS  := 10
const SLOT_SEPARATION := 4   # must match the scene's h_separation / v_separation

# ── Node refs ────────────────────────────────────────────────────────────────
@onready var slot_grid  : GridContainer = $VBox/ScrollContainer/SlotGrid
@onready var bag_button : Button        = $VBox/HeaderRow/BagButton

# ── State ─────────────────────────────────────────────────────────────────────
var _slots: Array = []


func _ready() -> void:
	bag_button.pressed.connect(_on_bag_pressed)
	resized.connect(_update_columns)
	_build_slots()
	InventoryState.inventory_changed.connect(_on_inventory_changed)


# ── Public API ────────────────────────────────────────────────────────────────

## Kept for backwards-compat — slots are now always built from InventoryState.
func setup(_count: int) -> void:
	pass


func refresh_all() -> void:
	for slot in _slots:
		slot.refresh()


# ── Internal ──────────────────────────────────────────────────────────────────

func _build_slots() -> void:
	for child in slot_grid.get_children():
		child.queue_free()
	_slots.clear()

	for i in range(InventoryState.HOTBAR_SIZE):
		var slot: ItemSlot = ItemSlotScene.instantiate()
		slot_grid.add_child(slot)
		slot.setup("hotbar", i, false)
		# Expand to fill grid cell.
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		slot.slot_clicked.connect(_on_slot_clicked)
		_slots.append(slot)

	_update_columns()


func _on_inventory_changed() -> void:
	for slot in _slots:
		slot.refresh()


func _update_columns() -> void:
	if slot_grid == null:
		return
	var available: float = (slot_grid.get_parent() as Control).size.x
	if available <= 0:
		available = size.x
	if available <= 0:
		return
	# Use the ItemSlot's minimum size (56px from item_slot.tscn) as the column unit.
	var slot_min := 56.0
	var cols := int((available + SLOT_SEPARATION) / (slot_min + SLOT_SEPARATION))
	cols = clampi(cols, SLOT_MIN_COLS, SLOT_MAX_COLS)
	if slot_grid.columns != cols:
		slot_grid.columns = cols


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_slot_clicked(container: String, index: int) -> void:
	# Forward as a flat index for backwards-compat with any existing listeners.
	if container == "hotbar":
		slot_clicked.emit(index)


func _on_bag_pressed() -> void:
	bag_opened.emit()
