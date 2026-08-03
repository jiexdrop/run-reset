## MobRegistry — single place to register every mob type.
##
## TO ADD A NEW MOB
## ────────────────
## 1. Add its sprite to mob_card.gd → MOB_SPRITES
## 2. Define a MobDef + its MobAttackData entries below in _build_registry()
## 3. Append the key to ROOM_MOB_POOL (or a themed pool) so the generator picks it up.
##
## The registry is a plain Dictionary: String → MobDef
## Access it anywhere via   MobRegistry.get_def("spider")

extends Node

## Keys available for random placement.
## Edit this list to control which mobs appear in normal rooms.
const ROOM_MOB_POOL: Array[String] = ["spider", "rat"]

var _registry: Dictionary = {}


func _ready() -> void:
	_build_registry()


func get_def(key: String) -> MobDef:
	return _registry.get(key, null)


func get_pool(zone: String) -> Array:
	return ZoneRegistry.get_pool(zone)


# ── Internal ──────────────────────────────────────────────────────────────────

func _build_registry() -> void:
	# ── Cave Spider ────────────────────────────────────────────────────────────
	var bite         = MobAttackData.new()
	bite.attack_name = "Bite"
	bite.damage      = 1
	bite.effect      = MobAttackData.Effect.NONE

	var venom         = MobAttackData.new()
	venom.attack_name = "Venom"
	venom.damage      = 1
	venom.effect      = MobAttackData.Effect.POISON
 
	var spider        = MobDef.new()
	spider.mob_name   = "Cave Spider"
	spider.sprite     = "spider"
	spider.max_hp     = 3
	spider.xp_reward  = 1
	spider.attacks    = [bite, venom] as Array[MobAttackData]
	spider.loot_table = [
		{ "item_key": "health_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "stone_sword", "chance": 0.22, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["spider"] = spider

	# ── Sewer Rat ──────────────────────────────────────────────────────────────
	var gnaw        = MobAttackData.new()
	gnaw.attack_name = "Gnaw"
	gnaw.damage      = 2
	gnaw.effect      = MobAttackData.Effect.NONE

	var rat        = MobDef.new()
	rat.mob_name   = "Sewer Rat"
	rat.sprite     = "rat"
	rat.max_hp     = 2
	rat.xp_reward  = 1
	rat.attacks    = [gnaw] as Array[MobAttackData]
	rat.loot_table = [
		{ "item_key": "health_potion", "chance": 0.22, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.22, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["rat"] = rat
	
	# ── Cactus ─────────────────────────────────────────────────────────────────
	var thorn         = MobAttackData.new()
	thorn.attack_name = "Thorn Jab"
	thorn.damage      = 2
	thorn.effect      = MobAttackData.Effect.NONE

	var cactus        = MobDef.new()
	cactus.mob_name   = "Cactus"
	cactus.sprite     = "cactus"
	cactus.max_hp     = 4
	cactus.xp_reward  = 2
	cactus.attacks    = [thorn] as Array[MobAttackData]
	cactus.loot_table = [
		{ "item_key": "health_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.32, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["cactus"] = cactus

	# ── Sandipper ─────────────────────────────────────────────────────────────
	var peck         = MobAttackData.new()
	peck.attack_name = "Peck"
	peck.damage      = 1
	peck.effect      = MobAttackData.Effect.NONE

	var sandipper        = MobDef.new()
	sandipper.mob_name   = "Sandipper"
	sandipper.sprite     = "sandipper"
	sandipper.max_hp     = 2
	sandipper.xp_reward  = 1
	sandipper.attacks    = [peck] as Array[MobAttackData]
	sandipper.burrows    = true
	sandipper.loot_table = [
		{ "item_key": "health_potion", "chance": 0.22, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["sandipper"] = sandipper

	# ── Glaciarch (Ribera boss) ─────────────────────────────────────────────────
	var frost_bite   = MobAttackData.new()
	frost_bite.attack_name = "Frost Bite"
	frost_bite.damage      = 2
	frost_bite.effect      = MobAttackData.Effect.NONE

	var freeze       = MobAttackData.new()
	freeze.attack_name = "Freeze"
	freeze.damage      = 1
	freeze.effect      = MobAttackData.Effect.STUN

	var glaciarch        = MobDef.new()
	glaciarch.mob_name   = "Glaciarch"
	glaciarch.sprite     = "glaciarch"
	glaciarch.max_hp     = 8
	glaciarch.xp_reward  = 6
	glaciarch.attacks    = [frost_bite, freeze] as Array[MobAttackData]
	glaciarch.resistances = {"physical": 0.5, "ice": 0.1, "fire": 2.0}
	glaciarch.loot_table = [
		{ "item_key": "energy_potion", "chance": 1.0, "min": 1, "max": 1 },
		{ "item_key": "health_potion", "chance": 0.3, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["glaciarch"] = glaciarch

	# ── Frozelin (Ribera regular) ────────────────────────────────────────────────
	var chill        = MobAttackData.new()
	chill.attack_name = "Chill"
	chill.damage      = 1
	chill.effect      = MobAttackData.Effect.NONE

	var frozelin        = MobDef.new()
	frozelin.mob_name   = "Frozelin"
	frozelin.sprite     = "frozelin"
	frozelin.max_hp     = 3
	frozelin.xp_reward  = 2
	frozelin.attacks    = [chill] as Array[MobAttackData]
	frozelin.loot_table = [
		{ "item_key": "health_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "spell_ice", "chance": 0.32, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["frozelin"] = frozelin

	# ── Gomelin (Pikoterra boss) ─────────────────────────────────────────────────
	var pilfer       = MobAttackData.new()
	pilfer.attack_name = "Pilfer"
	pilfer.damage      = 2
	pilfer.effect      = MobAttackData.Effect.STEAL

	var gomelin         = MobDef.new()
	gomelin.mob_name    = "Gomelin"
	gomelin.sprite      = "gomelin"
	gomelin.max_hp      = 8
	gomelin.xp_reward   = 6
	gomelin.attacks     = [pilfer] as Array[MobAttackData]
	gomelin.resistances = {"physical": 0.5, "ice": 2.0, "fire": 0.1}
	gomelin.loot_table  = [
		{ "item_key": "health_potion", "chance": 1.0, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.3, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["gomelin"] = gomelin

	# ── Pikonaut (Pikoterra regular) ─────────────────────────────────────────────
	var poke         = MobAttackData.new()
	poke.attack_name = "Poke"
	poke.damage      = 1
	poke.effect      = MobAttackData.Effect.NONE

	var pikonaut         = MobDef.new()
	pikonaut.mob_name    = "Pikonaut"
	pikonaut.sprite      = "pikonaut"
	pikonaut.max_hp      = 3
	pikonaut.xp_reward   = 2
	pikonaut.attacks     = [poke] as Array[MobAttackData]
	pikonaut.resistances = {"physical": 0.5, "ice": 2.0, "fire": 0.1}
	pikonaut.loot_table  = [
		{ "item_key": "health_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "spell_fire", "chance": 0.32, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["pikonaut"] = pikonaut
	

	# ── Kaze Shroom ─────────────────────────────────────────────
	var explode         = MobAttackData.new()
	explode.attack_name    = "Explode"
	explode.damage         = 3
	explode.effect         = MobAttackData.Effect.NONE

	var kaze_shroom        = MobDef.new()
	kaze_shroom.mob_name   = "Kaze Shroom"
	kaze_shroom.sprite     = "kaze_shroom"
	kaze_shroom.max_hp     = 1
	kaze_shroom.xp_reward  = 2
	kaze_shroom.attacks    = [explode] as Array[MobAttackData]
	kaze_shroom.loot_table = [
		{ "item_key": "health_potion", "chance": 0.42, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.32, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["kaze_shroom"] = kaze_shroom

	# ── Sapguard ─────────────────────────────────────────────
	var sip         = MobAttackData.new()
	sip.attack_name    = "Sip"
	sip.damage         = 2
	sip.effect         = MobAttackData.Effect.NONE

	var sapguard         = MobDef.new()
	sapguard.mob_name    = "Sapguard"
	sapguard.sprite      = "sapguard"
	sapguard.max_hp      = 8
	sapguard.xp_reward   = 2
	sapguard.attacks     = [sip] as Array[MobAttackData]
	sapguard.resistances = {"physical": 0.1, "ice": 2.0, "fire": 2.0}
	sapguard.loot_table  = [
		{ "item_key": "health_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "energy_potion", "chance": 0.32, "min": 1, "max": 1 },
		{ "item_key": "iron_sword", "chance": 0.52, "min": 1, "max": 1 },
	] as Array[Dictionary]
	_registry["sapguard"] = sapguard

	# ── Add more mobs here ────────────────────
