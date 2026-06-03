extends Node

## InventoryState — single source of truth for all inventory data.
##
## Hotbar : 8 slots shown permanently in CombatUI.
## Bag    : 24 slots shown in the expandable bag overlay.
##
## Each slot is a Dictionary:
##   { "item_key": String, "frozen": bool, "count": int }
##
## item_key == "" means the slot is empty (count is 0).
## frozen   == true means the slot is locked (visually ice-overlaid).
## count    == how many items are stacked in this slot (1–max_stack).

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
	return { "item_key": "", "frozen": false, "count": 0 }


## Place item_key (with optional explicit count) into a hotbar slot (0-7).
## Prefer add_item() for normal pickups — this is a direct setter.
func set_hotbar_item(slot_idx: int, item_key: String, count: int = 1) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	hotbar[slot_idx]["item_key"] = item_key
	hotbar[slot_idx]["count"]    = count if item_key != "" else 0
	emit_signal("inventory_changed")


## Place item_key into a bag slot (0-23).
func set_bag_item(slot_idx: int, item_key: String, count: int = 1) -> void:
	if slot_idx < 0 or slot_idx >= BAG_SIZE:
		return
	bag[slot_idx]["item_key"] = item_key
	bag[slot_idx]["count"]    = count if item_key != "" else 0
	emit_signal("inventory_changed")


## Add `amount` of item_key, auto-stacking up to max_stack per slot.
## Fills hotbar first, then bag.
## Returns the number of items that did NOT fit (overflow — 0 means all placed).
func add_item(item_key: String, amount: int = 1) -> int:
	var max_stack: int = ItemRegistry.get_max_stack(item_key)

	# Pass 1 — top up existing partial stacks (hotbar first, then bag).
	for arr in [hotbar, bag]:
		for slot in arr:
			if slot["item_key"] == item_key and not slot.get("frozen", false):
				var space: int = max_stack - slot.get("count", 0)
				if space > 0:
					var add = min(space, amount)
					slot["count"] += add
					amount -= add
					if amount == 0:
						emit_signal("inventory_changed")
						return 0

	# Pass 2 — fill empty slots.
	for arr in [hotbar, bag]:
		for slot in arr:
			if slot["item_key"] == "" and not slot.get("frozen", false):
				var add = min(max_stack, amount)
				slot["item_key"] = item_key
				slot["count"]    = add
				amount -= add
				if amount == 0:
					emit_signal("inventory_changed")
					return 0

	emit_signal("inventory_changed")
	return amount  # leftover that didn't fit


## Remove 1 of the item in hotbar slot `slot_idx`.
## Clears the slot automatically when count reaches 0.
func consume_hotbar_item(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	var slot = hotbar[slot_idx]
	if slot["item_key"] == "":
		return
	slot["count"] = max(0, slot.get("count", 1) - 1)
	if slot["count"] <= 0:
		slot["item_key"] = ""
		slot["count"]    = 0
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
		# Back-compat: old saves without "count" field.
		if not hotbar[i].has("count"):
			hotbar[i]["count"] = 1 if hotbar[i].get("item_key", "") != "" else 0
	var saved_bag = data.get("bag", [])
	for i in range(min(saved_bag.size(), BAG_SIZE)):
		bag[i] = saved_bag[i]
		if not bag[i].has("count"):
			bag[i]["count"] = 1 if bag[i].get("item_key", "") != "" else 0
	emit_signal("inventory_changed")
