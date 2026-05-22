extends Control

## Emitted when a slot is clicked. Passes the slot index.
signal slot_clicked(index: int)
## Emitted when the bag button is pressed.
signal bag_opened

# ── Configuration ────────────────────────────────────────────────────────────
const SLOT_MIN_SIZE  := Vector2(40, 40)  # minimum slot size before shrinking
const SLOT_MIN_COLS  := 2                # never fewer than this many columns
const SLOT_MAX_COLS  := 10               # never more than this many columns
const SLOT_SEPARATION := 4              # must match the scene's h_separation

# ── Node refs ────────────────────────────────────────────────────────────────
@onready var slot_grid  : GridContainer = $VBox/ScrollContainer/SlotGrid
@onready var bag_button : Button        = $VBox/HeaderRow/BagButton

# ── State ─────────────────────────────────────────────────────────────────────
var slot_buttons : Array[Button] = []
var item_data    : Array         = []   # fill from outside; one entry per slot


func _ready() -> void:
	bag_button.pressed.connect(_on_bag_pressed)
	# Recalculate columns whenever our width changes.
	resized.connect(_update_columns)


# ── Public API ────────────────────────────────────────────────────────────────

## Call this to (re)build the slot grid with `count` slots.
func setup(count: int) -> void:
	_clear_slots()
	for i in count:
		var btn := Button.new()
		btn.custom_minimum_size = SLOT_MIN_SIZE
		# Expand horizontally AND vertically so slots fill all available space.
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		btn.flat = false
		btn.name = "Slot%d" % i
		btn.tooltip_text = "Slot %d" % (i + 1)
		btn.pressed.connect(_on_slot_pressed.bind(i))
		slot_grid.add_child(btn)
		slot_buttons.append(btn)
	_update_columns()


## Refresh a single slot's icon/text from `item_data`.
func refresh_slot(index: int) -> void:
	if index >= slot_buttons.size():
		return
	var btn := slot_buttons[index]
	if index < item_data.size() and item_data[index] != null:
		var item = item_data[index]
		btn.text = item.get("icon_text", "")
		btn.tooltip_text = item.get("name", "Slot %d" % (index + 1))
	else:
		btn.text = ""
		btn.tooltip_text = "Slot %d" % (index + 1)


## Refresh every slot at once.
func refresh_all() -> void:
	for i in slot_buttons.size():
		refresh_slot(i)


# ── Internal helpers ──────────────────────────────────────────────────────────

func _clear_slots() -> void:
	for btn in slot_buttons:
		btn.queue_free()
	slot_buttons.clear()


## Recalculate how many columns fit in the current width.
func _update_columns() -> void:
	if slot_grid == null:
		return
	var available: float = (slot_grid.get_parent() as Control).size.x  # ScrollContainer width
	if available <= 0:
		available = size.x                            # fallback to Control width
	if available <= 0:
		return
	# cols = floor((available + sep) / (min_slot_size + sep))
	var cols := int((available + SLOT_SEPARATION) / (SLOT_MIN_SIZE.x + SLOT_SEPARATION))
	cols = clampi(cols, SLOT_MIN_COLS, SLOT_MAX_COLS)
	if slot_grid.columns != cols:
		slot_grid.columns = cols


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_slot_pressed(index: int) -> void:
	slot_clicked.emit(index)


func _on_bag_pressed() -> void:
	bag_opened.emit()
