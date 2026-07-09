extends Node

const HOTBAR_SIZE = 8
const BAG_SIZE    = 24

const DEBUG_GIVE_WEAPONS := true
const DEBUG_WEAPON_KEYS: Array[String] = ["iron_sword", "steel_sword", "stone_sword"]
const DEBUG_SPELL_KEYS:  Array[String] = ["spell_ice", "spell_fire"]
const DEBUG_SPELL_COUNT := 8

signal inventory_changed

var hotbar: Array = []
var bag:    Array = []
var equipped_index: int = -1   ## hotbar index of the equipped weapon/spell, -1 = none (Fists)


func _ready() -> void:
	_init_slots()


func _init_slots() -> void:
	hotbar.clear()
	for i in range(HOTBAR_SIZE):
		hotbar.append(_empty_slot())
	bag.clear()
	for i in range(BAG_SIZE):
		bag.append(_empty_slot())
	equipped_index = -1


func _empty_slot() -> Dictionary:
	return { "item_key": "", "frozen": false, "count": 0 }


func add_item(item_key: String, amount: int = 1) -> int:
	var max_stack = ItemRegistry.get_max_stack(item_key)

	for arr in [hotbar, bag]:
		for slot in arr:
			if slot["item_key"] == item_key and not slot.get("frozen", false):
				var space = max_stack - slot.get("count", 0)
				if space > 0:
					var add = min(space, amount)
					slot["count"] += add
					amount -= add
					if amount == 0:
						emit_signal("inventory_changed")
						return 0

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

	if amount < (ItemRegistry.get_max_stack(item_key) * (HOTBAR_SIZE + BAG_SIZE)):
		emit_signal("inventory_changed")
	return amount


func consume_hotbar_item(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	var slot = hotbar[slot_idx]
	slot["count"] = max(0, slot.get("count", 1) - 1)
	if slot["count"] <= 0:
		slot["item_key"] = ""
		slot["count"]    = 0
		_unequip_if_empty(slot_idx)
	emit_signal("inventory_changed")


func set_hotbar_item(slot_idx: int, item_key: String, count: int = 1) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	hotbar[slot_idx]["item_key"] = item_key
	hotbar[slot_idx]["count"]    = count if item_key != "" else 0
	if item_key == "":
		_unequip_if_empty(slot_idx)
	emit_signal("inventory_changed")


func set_bag_item(slot_idx: int, item_key: String) -> void:
	if slot_idx < 0 or slot_idx >= BAG_SIZE:
		return
	bag[slot_idx]["item_key"] = item_key
	emit_signal("inventory_changed")


func set_hotbar_frozen(slot_idx: int, frozen: bool) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	hotbar[slot_idx]["frozen"] = frozen
	emit_signal("inventory_changed")


func set_bag_frozen(slot_idx: int, frozen: bool) -> void:
	if slot_idx < 0 or slot_idx >= BAG_SIZE:
		return
	bag[slot_idx]["frozen"] = frozen
	emit_signal("inventory_changed")


func swap_slots(container_a: String, idx_a: int,
				container_b: String, idx_b: int) -> void:
	var arr_a = hotbar if container_a == "hotbar" else bag
	var arr_b = hotbar if container_b == "hotbar" else bag

	if idx_a < 0 or idx_a >= arr_a.size(): return
	if idx_b < 0 or idx_b >= arr_b.size(): return
	if arr_a[idx_a]["frozen"] or arr_b[idx_b]["frozen"]:
		return

	var tmp         = arr_a[idx_a].duplicate()
	arr_a[idx_a]    = arr_b[idx_b].duplicate()
	arr_b[idx_b]    = tmp
	arr_a[idx_a]["frozen"] = false
	arr_b[idx_b]["frozen"] = false

	# Equipped weapon follows its item if it was moved between hotbar slots;
	# if it left the hotbar entirely, unequip.
	if container_a == "hotbar" and idx_a == equipped_index and container_b != "hotbar":
		equipped_index = -1
	elif container_b == "hotbar" and idx_b == equipped_index and container_a != "hotbar":
		equipped_index = -1
	elif container_a == "hotbar" and container_b == "hotbar":
		if equipped_index == idx_a:
			equipped_index = idx_b
		elif equipped_index == idx_b:
			equipped_index = idx_a

	emit_signal("inventory_changed")


## Equip/unequip a weapon or spell living in a hotbar slot. Toggling the
## already-equipped slot unequips it (falls back to Fists in combat).
func equip_item(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= HOTBAR_SIZE:
		return
	var slot = hotbar[slot_idx]
	if slot.get("item_key", "") == "" or slot.get("frozen", false):
		return
	var item_type = ItemRegistry.get_type(slot["item_key"])
	if item_type != "weapon" and item_type != "spell":
		return
	equipped_index = -1 if equipped_index == slot_idx else slot_idx
	emit_signal("inventory_changed")


func _unequip_if_empty(slot_idx: int) -> void:
	if equipped_index == slot_idx:
		equipped_index = -1


func debug_grant_weapons_and_spells() -> void:
	for key in DEBUG_WEAPON_KEYS:
		add_item(key, 1)
	for key in DEBUG_SPELL_KEYS:
		add_item(key, DEBUG_SPELL_COUNT)


func to_dict() -> Dictionary:
	return {
		"hotbar":         hotbar.duplicate(true),
		"bag":            bag.duplicate(true),
		"equipped_index": equipped_index,
	}


func from_dict(data: Dictionary) -> void:
	_init_slots()
	var saved_hotbar = data.get("hotbar", [])
	for i in range(min(saved_hotbar.size(), HOTBAR_SIZE)):
		hotbar[i] = saved_hotbar[i]
	var saved_bag = data.get("bag", [])
	for i in range(min(saved_bag.size(), BAG_SIZE)):
		bag[i] = saved_bag[i]
	equipped_index = data.get("equipped_index", -1)
	emit_signal("inventory_changed")
