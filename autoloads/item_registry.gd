extends Node

## ItemRegistry — maps item_key strings to item definitions.
##
## Add new items here. The key must match what you store in InventoryState slots.
##
## Common fields:
##   name, icon, desc, max_stack
## Weapon/spell fields (used by combat once wired up):
##   type      : "consumable" | "weapon" | "spell"
##   damage    : int   (weapons + spells)
##   energy_cost : int (spells)

var _items: Dictionary = {
	"berries": {
		"name": "Berries",
		"icon": preload("res://assets/items/berries.png"),
		"desc": "A handful of wild berries. Restores 1 HP.",
		"max_stack": 16,
		"type": "consumable",
	},

	# ── Swords ────────────────────────────────────────────────────────────────
	"iron_sword": {
		"name": "Iron Sword",
		"icon": preload("res://assets/items/iron_sword.png"),
		"desc": "A sturdy iron blade.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 2,
	},
	"steel_sword": {
		"name": "Steel Sword",
		"icon": preload("res://assets/items/steel_sword.png"),
		"desc": "A sharpened steel blade. Hits harder than iron.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 4,
	},
	"stone_sword": {
		"name": "Stone Sword",
		"icon": preload("res://assets/items/stone_sword.png"),
		"desc": "A crude blade chipped from stone.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 1,
	},

	# ── Spells ────────────────────────────────────────────────────────────────
	"spell_ice": {
		"name": "Ice Spell",
		"icon": preload("res://assets/items/spell_ice.png"),
		"desc": "Conjures a shard of ice to strike the enemy.",
		"max_stack": 8,
		"type": "spell",
		"damage": 2,
		"energy_cost": 2,
	},
	"spell_fire": {
		"name": "Fire Spell",
		"icon": preload("res://assets/items/spell_fire.png"),
		"desc": "Hurls a burst of flame at the enemy.",
		"max_stack": 8,
		"type": "spell",
		"damage": 3,
		"energy_cost": 3,
	},

	# "sword":         { "name": "Iron Sword",    "icon": preload("res://assets/items/sword.png"),         "desc": "A trusty blade." },
	# "health_potion": { "name": "Health Potion",  "icon": preload("res://assets/items/health_potion.png"), "desc": "Restores 3 HP." },
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

func get_max_stack(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("max_stack", 1)
	return 1

func get_type(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("type", "consumable")
	return "consumable"

func get_damage(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("damage", 0)
	return 0

func get_energy_cost(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("energy_cost", 0)
	return 0

func register(item_key: String, data: Dictionary) -> void:
	_items[item_key] = data
