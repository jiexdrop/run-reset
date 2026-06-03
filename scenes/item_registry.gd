extends Node

## ItemRegistry — maps item_key strings to item definitions.
##
## Add new items here. The key must match what you store in InventoryState slots.
##
## max_stack controls how many of this item fit in one slot:
##   consumables (berries, potions) → 8 or 16
##   equipment / unique items       → 1

var _items: Dictionary = {
	"berries": {
		"name":      "Berries",
		"icon":      preload("res://assets/items/berries.png"),
		"desc":      "A handful of wild berries. Restores 3 HP.",
		"max_stack": 16,
	},
	# "health_potion": {
	#     "name": "Health Potion", "icon": preload("res://assets/items/health_potion.png"),
	#     "desc": "Restores 3 HP.", "max_stack": 8,
	# },
	# "sword": {
	#     "name": "Iron Sword", "icon": preload("res://assets/items/sword.png"),
	#     "desc": "A trusty blade.", "max_stack": 1,
	# },
}


func get_icon(item_key: String) -> Texture2D:
	if _items.has(item_key):
		return _items[item_key].get("icon", null)
	return null


func get_item_name(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("name", item_key)
	return item_key


func get_desc(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("desc", "")
	return ""


## Returns the maximum number of this item that fits in a single slot.
func get_max_stack(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("max_stack", 1)
	return 1


func register(item_key: String, data: Dictionary) -> void:
	_items[item_key] = data
