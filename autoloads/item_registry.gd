extends Node

## ItemRegistry — maps item_key strings to item definitions.
##
## Add new items here.  The key must match what you store in InventoryState slots.
##
## Example definition:
##   "health_potion": {
##       "name":  "Health Potion",
##       "icon":  preload("res://assets/items/health_potion.png"),
##       "desc":  "Restores 3 HP.",
##   }
##
## If you haven't created item assets yet, icons will be null and the slot
## will display empty (no icon shown).

var _items: Dictionary = {
	# Populate with your actual items once assets exist, e.g.:
	# "sword":         { "name": "Iron Sword",    "icon": preload("res://assets/items/sword.png"),         "desc": "A trusty blade." },
	# "health_potion": { "name": "Health Potion",  "icon": preload("res://assets/items/health_potion.png"), "desc": "Restores 3 HP." },
}


func get_icon(item_key: String) -> Texture2D:
	if _items.has(item_key):
		return _items[item_key].get("icon", null)
	return null


func get_name(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("name", item_key)
	return item_key


func get_desc(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("desc", "")
	return ""


func register(item_key: String, data: Dictionary) -> void:
	_items[item_key] = data
