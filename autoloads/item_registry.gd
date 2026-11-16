extends Node

## ATTACK_TYPES — shared behavior table for weapon/spell "attack_type" tags.
## hits         : number of sequential strikes
## damage_mult  : multiplies the item's base `damage`, split across hits
## energy_mult  : multiplies the item's base `energy_cost`
## label        : appended to the attack name in the UI (e.g. " x2")
## effect_scene : VFX played on the mob for each hit
## range        : attack range classification — "ranged" or "melee". Attack
##                types without it (e.g. spells) are not range-classified and
##                resolve to "other" (see get_attack_range). Phased bosses
##                gate attacks by this classification.
const ATTACK_TYPES: Dictionary = {
	"single_swing": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": "",
		"range": "melee",
		"effect_scene": preload("res://scenes/effects/slash_effect.tscn"),
	},
	"double_swing": {
		"hits": 2, "damage_mult": 0.6, "energy_mult": 1.5, "label": " x2",
		"range": "melee",
		"effect_scene": preload("res://scenes/effects/slash_effect.tscn"),
	},
	"heavy_swing": {
		"hits": 1, "damage_mult": 1.8, "energy_mult": 2.0, "label": " (Heavy)",
		"range": "melee",
		"effect_scene": preload("res://scenes/effects/slash_effect.tscn"),
	},
	"heavy_swing_basic": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": " (Heavy)",
		"range": "melee",
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
	"bomb_throw": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": "",
		"range": "ranged",
		"effect_scene": preload("res://scenes/effects/explosion_effect.tscn"),
	},
	"bow_shot": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": "",
		"range": "ranged",
		"effect_scene": preload("res://scenes/effects/arrow_effect.tscn"),
	},
	"shuriken_throw": {
		"hits": 1, "damage_mult": 1.0, "energy_mult": 1.0, "label": "",
		"range": "ranged",
		"effect_scene": preload("res://scenes/effects/shuriken_effect.tscn"),
	},
}

var _items: Dictionary = {
	"berries": {
		"name": "Berries",
		"icon": preload("res://assets/items/berries.png"),
		"desc": "A handful of wild berries. Restores 3 HP.",
		"max_stack": 16,
		"type": "consumable",
		"heal_amount": 3,
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
	"lemon": {
		"name": "Lemon",
		"icon": preload("res://assets/items/lemon.png"),
		"desc": "A sour cistronian lemon. \nRestores 3 energy and electrifies you for 5 turns. \nWhile Electrified, you finish foes in Cistronia at no extra cost.",
		"max_stack": 8,
		"type": "consumable",
		"energy_amount": 3,
		"electrified_turns": 5,
	},
	
	# ── Swords ────────────────────────────────────────────────────────────────
	"iron_sword": {
		"name": "Iron Sword",
		"icon": preload("res://assets/items/iron_sword.png"),
		"desc": "A sturdy iron blade.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 3,
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
	},

	# ── Spells ────────────────────────────────────────────────────────────────
	"spell_ice": {
		"name": "Ice Spell",
		"icon": preload("res://assets/items/spell_ice.png"),
		"desc": "Conjures a freezing blast that hits every enemy in combat and freezes them solid — a frozen enemy skips its next attack.",
		"max_stack": 8,
		"type": "spell",
		"damage": 2,
		"energy_cost": 2,
		"attack_type": "ice_spell",
		"element": "ice",
	},
	"spell_fire": {
		"name": "Fire Spell",
		"icon": preload("res://assets/items/spell_fire.png"),
		"desc": "Hurls a burst of flame that engulfs every enemy in combat.",
		"max_stack": 8,
		"type": "spell",
		"damage": 3,
		"energy_cost": 3,
		"attack_type": "fire_spell",
		"element": "fire",
	},
	"spell_find_mobs": {
		"name": "Seer's Glimpse",
		"icon": preload("res://assets/items/spell_find_mobs.png"),
		"desc": "Reveals which unexplored tiles hide enemies. Costs 1 energy.",
		"max_stack": 8,
		"type": "spell",
		"damage": 0,
		"energy_cost": 1,
		"attack_type": "single_swing",
		"element": "physical",
	},
	
	"bomb": {
		"name": "Bomb",
		"icon": preload("res://assets/items/bomb.png"),
		"desc": "Lob it at an enemy — it detonates on impact. Ranged: cracks the Raptor Skeleton's armored plates, and sets off a Kaze Shroom from a safe distance.",
		"max_stack": 8,
		"type": "spell",
		"damage": 5,
		"energy_cost": 0,
		"attack_type": "bomb_throw",
		"element": "physical",
	},

	# ── Bows & Arrows (ranged damage) ─────────────────────────────────────────
	# The bow is the weapon; arrows are its ammunition — every shot eats one
	# arrow (see combat_ui). Both classify as ranged (bow_shot) for phased
	# bosses (see ATTACK_TYPES `range` classification).
	# Icons use load() instead of preload() so the game still runs (with a
	# placeholder icon) before the art files below have been added.
	"bow": {
		"name": "Hunting Bow",
		"icon": load("res://assets/items/bow.png"),
		"desc": "A short hunting bow. Equip it and click an enemy to loose an arrow. Each shot consumes 1 Arrow.",
		"max_stack": 1,
		"type": "weapon",
		"damage": 3,
		"energy_cost": 1,
		"attack_type": "bow_shot",
	},
	"arrow": {
		"name": "Arrow",
		"icon": load("res://assets/items/arrow.png"),
		"desc": "Ammunition for the Hunting Bow.",
		"max_stack": 64,
		"type": "ammo",
		"ground_amount_min": 5,
		"ground_amount_max": 8,
	},
	"shuriken": {
		"name": "Shuriken",
		"icon": preload("res://assets/items/shuriken.png"),
		"desc": "A razor-edged throwing star.\nUses up one per throw.\nRicochet: after hitting, it bounces to another enemy for 1 damage.\nRanged: cracks the Raptor Skeleton's armored plates.",
		"max_stack": 8,
		"type": "spell",
		"damage": 2,
		"energy_cost": 1,
		"attack_type": "shuriken_throw",
		"element": "physical",
		"ground_amount_min": 5,
		"ground_amount_max": 8,
	},

	# ── Shields ───────────────────────────────────────────────────────────────
	"wood_shield": {
		"name": "Wood Shield",
		"icon": preload("res://assets/items/shield.png"),
		"desc": "A simple wooden shield. Blocks 2 damage from the next telegraphed attack.",
		"max_stack": 1,
		"type": "shield",
		"block_amount": 2,
		"energy_cost": 2,
	},
}


func get_icon(item_key: String) -> Texture2D:
	if _items.has(item_key):
		var icon: Texture2D = _items[item_key].get("icon", null)
		if icon == null and (item_key == "bow" or item_key == "arrow"):
			# Placeholder until res://assets/items/bow.png /
			# res://assets/items/arrow.png are added.
			return _items.get("bomb", {}).get("icon", null)
		return icon
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

## How many of this item a ground cache holds when it is generated (1 unless
## the item declares a bundle range, e.g. arrows). Rolled once per cache, the
## same way mob loot tables roll min..max.
func get_ground_amount(item_key: String) -> int:
	if _items.has(item_key):
		var entry: Dictionary = _items[item_key]
		var amount_min: int = int(entry.get("ground_amount_min", 1))
		var amount_max: int = int(entry.get("ground_amount_max", 1))
		return maxi(1, randi_range(amount_min, amount_max))
	return 1

func get_type(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("type", "consumable")
	return "consumable"

func get_damage(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("damage", 0)
	return 0

func get_block_amount(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("block_amount", 0)
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

func get_electrified_turns(item_key: String) -> int:
	if _items.has(item_key):
		return _items[item_key].get("electrified_turns", 0)
	return 0
	
func get_attack_type(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("attack_type", "single_swing")
	return "single_swing"

func get_element(item_key: String) -> String:
	if _items.has(item_key):
		return _items[item_key].get("element", "physical")
	return "physical"


## Returns every item known to the game for developer-facing tools.
## Sorting by display name keeps the debug item browser predictable even as
## additional items are registered later.
func get_item_keys() -> Array[String]:
	var keys: Array[String] = []
	for item_key in _items:
		keys.append(item_key)
	keys.sort_custom(func(a: String, b: String) -> bool:
		return get_item_name(a).naturalnocasecmp_to(get_item_name(b)) < 0
	)
	return keys

func get_attack_type_data(attack_type: String) -> Dictionary:
	return ATTACK_TYPES.get(attack_type, ATTACK_TYPES["single_swing"])

## Range classification of an attack type: "ranged", "melee", or "other" for
## attack types that declare no range (e.g. spells). Unknown attack types fall
## back to single_swing, mirroring get_attack_type_data.
func get_attack_range(attack_type: String) -> String:
	var data: Dictionary = ATTACK_TYPES.get(attack_type, ATTACK_TYPES["single_swing"])
	return String(data.get("range", "other"))

## Builds the hover tooltip for an item. Only stats that apply to the item's
## type are listed (e.g. no heal line on a sword, no damage line on a potion).
func get_tooltip_text(item_key: String) -> String:
	if not _items.has(item_key):
		return ""
	var type: String = get_type(item_key)
	var lines: Array[String] = ["%s (%s)" % [get_item_name(item_key), type.capitalize()]]

	match type:
		"weapon", "spell":
			var type_data: Dictionary = get_attack_type_data(get_attack_type(item_key))
			var hits: int = max(1, int(type_data.get("hits", 1)))
			var dmg: int = max(1, int(round(get_damage(item_key) * float(type_data.get("damage_mult", 1.0)) / hits)))
			if hits > 1:
				lines.append("Damage: %d x%d" % [dmg, hits])
			else:
				lines.append("Damage: %d" % dmg)
			var energy: int = int(ceil(get_energy_cost(item_key) * float(type_data.get("energy_mult", 1.0))))
			if energy > 0:
				lines.append("Energy cost: %d" % energy)
			var element: String = get_element(item_key)
			if type == "spell" and element != "physical":
				lines.append("Element: %s" % element.capitalize())
		"shield":
			lines.append("Blocks: %d damage" % get_block_amount(item_key))
			var shield_energy: int = get_energy_cost(item_key)
			if shield_energy > 0:
				lines.append("Energy cost: %d" % shield_energy)
		"consumable":
			if get_heal_amount(item_key) > 0:
				lines.append("Restores: %d HP" % get_heal_amount(item_key))
			if get_energy_amount(item_key) > 0:
				lines.append("Restores: %d energy" % get_energy_amount(item_key))
			if get_electrified_turns(item_key) > 0:
				lines.append("Electrified: %d turns" % get_electrified_turns(item_key))

	var desc: String = get_desc(item_key)
	if desc != "":
		lines.append("")
		lines.append(desc)
	return "\n".join(lines)

func register(item_key: String, data: Dictionary) -> void:
	_items[item_key] = data
