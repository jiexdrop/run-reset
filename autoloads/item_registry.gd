extends Node

## ATTACK_TYPES — shared behavior table for weapon/spell "attack_type" tags.
## hits         : number of sequential strikes
## damage_mult  : multiplies the item's base `damage`, split across hits
## energy_mult  : multiplies the item's base `energy_cost`
## label        : appended to the attack name in the UI (e.g. " x2")
## effect_scene : VFX played on the mob for each hit
const ATTACK_TYPES: Dictionary = {
	"single_swing": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": "",
		"effect_scene": preload("res://scenes/effects/slash_effect.tscn"),
	},
	"double_swing": {
		"hits": 2, "damage_mult": 0.6, "energy_mult": 1.5, "label": " x2",
		"effect_scene": preload("res://scenes/effects/slash_effect.tscn"),
	},
	"heavy_swing": {
		"hits": 1, "damage_mult": 1.8, "energy_mult": 2.0, "label": " (Heavy)",
		"effect_scene": preload("res://scenes/effects/slash_effect.tscn"),
	},
	"heavy_swing_basic": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": " (Heavy)",
		"effect_scene": preload("res://scenes/effects/slash_effect.tscn"),
	},
	"fire_spell": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": "",
		"effect_scene": preload("res://scenes/effects/fire_effect.tscn"),
	},
	"ice_spell": {
		"hits": 1, "damage_mult": 0.5, "energy_mult": 1.0, "label": "",
		"effect_scene": preload("res://scenes/effects/ice_effect.tscn"),
	},
}

var _items: Dictionary = {
	"berries": {
		"name": "Berries",
		"icon": preload("res://assets/items/berries.png"),
		"desc": "A handful of wild berries. Restores 1 HP.",
		"max_stack": 16,
		"type": "consumable",
	},

	# ── Potions ────────────────────────────────────────────────────────────────
	"health_potion": {
		"name": "Health Potion",
		"icon": preload("res://assets/items/health_potion.png"),
		"desc": "A vial of restorative brew. Restores 6 HP.",
		"max_stack": 8,
		"type": "consumable",
		"heal_amount": 6,
	},
	"energy_potion": {
		"name": "Energy Potion",
		"icon": preload("res://assets/items/energy_potion.png"),
		"desc": "A fizzing tonic. Restores 6 energy.",
		"max_stack": 8,
		"type": "consumable",
		"energy_amount": 6,
	},
	
	# ── Swords ────────────────────────────────────────────────────────────────
	"iron_sword": {
		"name": "Iron Sword",
		"icon": preload("res://assets/items/iron_sword.png"),
		"desc": "A sturdy iron blade.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 2,
		"attack_type": "single_swing",
	},
	"steel_sword": {
		"name": "Steel Sword",
		"icon": preload("res://assets/items/steel_sword.png"),
		"desc": "A sharpened steel blade. Strikes twice in quick succession.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 4,
		"attack_type": "double_swing",
	},
	"stone_sword": {
		"name": "Stone Sword",
		"icon": preload("res://assets/items/stone_sword.png"),
		"desc": "A crude, heavy blade chipped from stone.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 2,
		"attack_type": "heavy_swing_basic",
		"energy_cost": 1, 
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
		"attack_type": "ice_spell",
	},
	"spell_fire": {
		"name": "Fire Spell",
		"icon": preload("res://assets/items/spell_fire.png"),
		"desc": "Hurls a burst of flame at the enemy.",
		"max_stack": 8,
		"type": "spell",
		"damage": 3,
		"energy_cost": 3,
		"attack_type": "fire_spell",
	},
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
	
func get_heal_amount(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("heal_amount", 0)
	return 0

func get_energy_amount(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("energy_amount", 0)
	return 0
	
func get_attack_type(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("attack_type", "single_swing")
	return "single_swing"

func get_attack_type_data(attack_type: String) -> Dictionary:
	return ATTACK_TYPES.get(attack_type, ATTACK_TYPES["single_swing"])

func register(item_key: String, data: Dictionary) -> void:
	_items[item_key] = data
