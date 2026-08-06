extends Control

## Emitted when a slot is clicked. Passes the container + index (matches ItemSlot signal).
signal slot_clicked(index: int)
## Emitted when the bag button is pressed.
signal bag_opened

# ── Configuration ────────────────────────────────────────────────────────────
const ItemSlotScene   = preload("res://scenes/item_slot.tscn")
const BAG_ICON_TEX    = preload("res://assets/ui/slot_bag.png")
const SLOT_MIN_COLS   := 2
const SLOT_MAX_COLS   := 10
const SLOT_SIZE       := 56.0   # matches ItemSlot custom_minimum_size
const SLOT_SEPARATION := 4      # must match the scene's h_separation / v_separation

# ── Node refs ────────────────────────────────────────────────────────────────
@onready var slot_grid: GridContainer = $VBox/ScrollContainer/SlotGrid

# ── State ─────────────────────────────────────────────────────────────────────
var _slots: Array = []
var _bag_button: TextureButton = null
var _trash_slot: ItemSlot = null
var _columns_dirty: bool = false   # debounce flag


func _ready() -> void:
	resized.connect(_queue_update_columns)
	_build_slots()
	InventoryState.inventory_changed.connect(_on_inventory_changed)
	call_deferred("_update_columns")


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
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		slot.slot_clicked.connect(_on_slot_clicked)
		_slots.append(slot)

	_build_bag_button()
	_build_trash_slot()

	slot_grid.columns = SLOT_MIN_COLS


## Builds the "open bag" button as a slot-sized tile living in the same grid
## as the hotbar slots, using the slot_bag texture instead of an emoji.
func _build_bag_button() -> void:
	_bag_button = TextureButton.new()
	_bag_button.texture_normal      = BAG_ICON_TEX
	_bag_button.ignore_texture_size = true
	_bag_button.stretch_mode        = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_bag_button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	_bag_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bag_button.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_bag_button.tooltip_text        = "Open Bag"
	_bag_button.pressed.connect(_on_bag_pressed)
	slot_grid.add_child(_bag_button)


func _build_trash_slot() -> void:
	_trash_slot = ItemSlotScene.instantiate()
	slot_grid.add_child(_trash_slot)
	_trash_slot.setup("trash", 0, false)
	# Match the hotbar: this becomes draggable only while the bag is open.
	_trash_slot.set_drag_enabled(false)
	_trash_slot.tooltip_text = "Trash: drop an item here. The previous trash item is deleted."


func _on_inventory_changed() -> void:
	for slot in _slots:
		slot.refresh()
	if is_instance_valid(_trash_slot):
		_trash_slot.refresh()


## Queue a column update — deferred so many resize events in one frame
## collapse into a single recalculation at the end of the frame.
func _queue_update_columns() -> void:
	if not _columns_dirty:
		_columns_dirty = true
		call_deferred("_update_columns")


func _update_columns() -> void:
	_columns_dirty = false

	if slot_grid == null:
		return

	# Use the InventoryUI's own width — it's the most stable reference point
	# because it's sized by the parent VBoxContainer, not by its own contents.
	# The ScrollContainer and SlotGrid sizes fluctuate during layout passes
	# (e.g. when combat UI adds/removes mobs), causing the old code to read
	# transient near-zero or oversized values and snap to wrong column counts.
	var available: float = size.x
	if available <= 0.0:
		# Layout not resolved yet — retry next frame.
		call_deferred("_update_columns")
		return

	# Leave a small margin so the grid never forces a horizontal scrollbar.
	available = max(0.0, available - SLOT_SEPARATION * 2)

	var cols := int((available + SLOT_SEPARATION) / (SLOT_SIZE + SLOT_SEPARATION))
	cols = clampi(cols, SLOT_MIN_COLS, SLOT_MAX_COLS)

	if slot_grid.columns != cols:
		slot_grid.columns = cols


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_slot_clicked(container: String, index: int) -> void:
	if container == "hotbar":
		slot_clicked.emit(index)


func _on_bag_pressed() -> void:
	bag_opened.emit()
	
## Enables/disables drag-and-drop on all hotbar slots (only while the bag is open).
func set_drag_enabled(enabled: bool) -> void:
	for slot in _slots:
		slot.set_drag_enabled(enabled)
	if is_instance_valid(_trash_slot):
		_trash_slot.set_drag_enabled(enabled)
