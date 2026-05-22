extends Node

## InventoryState — single source of truth for all inventory data.
##
## Hotbar : 8 slots shown permanently in CombatUI.
## Bag    : 24 slots shown in the expandable bag overlay.
##
## Each slot is a Dictionary:
##   { "item_key": String, "frozen": bool }
##
## item_key == "" means the slot is empty.
## frozen   == true means the slot is locked (visually ice-overlaid).

const HOTBAR_SIZE = 8
const BAG_SIZE    = 24

## Emitted whenever any slot changes so UIs can refresh cheaply.
signal inventory_changed

var hotbar: Array = []   # Array[Dictionary]  size = HOTBAR_SIZE
var bag:    Array = []   # Array[Dictionary]  size = BAG_SIZE


func _ready() -> void:
	_init_slots()


func _init_slots() -> void:
	hotbar.clear()
	for i in range(HOTBAR_SIZE):
		hotbar.append(_empty_slot())
	bag.clear()
	for i in range(BAG_SIZE):
		bag.append(_empty_slot())


# ── Slot helpers ──────────────────────────────────────────────────────────────

func _empty_slot() -> Dictionary:
	return { "item_key": "", "frozen": false }


## Place item_key into a hotbar slot (0-7).
func set_hotbar_item(slot_idx: int, item_key: String) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	hotbar[slot_idx]["item_key"] = item_key
	emit_signal("inventory_changed")


## Place item_key into a bag slot (0-23).
func set_bag_item(slot_idx: int, item_key: String) -> void:
	if slot_idx < 0 or slot_idx >= BAG_SIZE:
		return
	bag[slot_idx]["item_key"] = item_key
	emit_signal("inventory_changed")


## Freeze / unfreeze a hotbar slot (e.g. boss ability).
func set_hotbar_frozen(slot_idx: int, frozen: bool) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	hotbar[slot_idx]["frozen"] = frozen
	emit_signal("inventory_changed")


## Freeze / unfreeze a bag slot.
func set_bag_frozen(slot_idx: int, frozen: bool) -> void:
	if slot_idx < 0 or slot_idx >= BAG_SIZE:
		return
	bag[slot_idx]["frozen"] = frozen
	emit_signal("inventory_changed")


## Swap two slots (cross-container). container_a/b: "hotbar" or "bag".
func swap_slots(container_a: String, idx_a: int,
				container_b: String, idx_b: int) -> void:
	var arr_a = hotbar if container_a == "hotbar" else bag
	var arr_b = hotbar if container_b == "hotbar" else bag

	if idx_a < 0 or idx_a >= arr_a.size(): return
	if idx_b < 0 or idx_b >= arr_b.size(): return

	# Frozen slots cannot be moved from or into.
	if arr_a[idx_a]["frozen"] or arr_b[idx_b]["frozen"]:
		return

	var tmp         = arr_a[idx_a].duplicate()
	arr_a[idx_a]    = arr_b[idx_b].duplicate()
	arr_b[idx_b]    = tmp
	# Preserve frozen state of destination (don't overwrite freeze with source).
	arr_a[idx_a]["frozen"] = false
	arr_b[idx_b]["frozen"] = false
	emit_signal("inventory_changed")


# ── Serialisation ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"hotbar": hotbar.duplicate(true),
		"bag":    bag.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	_init_slots()
	var saved_hotbar = data.get("hotbar", [])
	for i in range(min(saved_hotbar.size(), HOTBAR_SIZE)):
		hotbar[i] = saved_hotbar[i]
	var saved_bag = data.get("bag", [])
	for i in range(min(saved_bag.size(), BAG_SIZE)):
		bag[i] = saved_bag[i]
	emit_signal("inventory_changed")
