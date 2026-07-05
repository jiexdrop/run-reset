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
	var bite        = MobAttackData.new()
	bite.attack_name = "Bite"
	bite.damage      = 1
	bite.effect      = MobAttackData.Effect.NONE

	var venom       = MobAttackData.new()
	venom.attack_name = "Venom"
	venom.damage      = 1
	venom.effect      = MobAttackData.Effect.POISON

	var spider      = MobDef.new()
	spider.mob_name  = "Cave Spider"
	spider.sprite    = "spider"
	spider.max_hp    = 2
	spider.xp_reward = 2
	spider.attacks   = [bite, venom] as Array[MobAttackData]
	_registry["spider"] = spider

	# ── Sewer Rat ──────────────────────────────────────────────────────────────
	var gnaw        = MobAttackData.new()
	gnaw.attack_name = "Gnaw"
	gnaw.damage      = 2
	gnaw.effect      = MobAttackData.Effect.NONE

	var rat         = MobDef.new()
	rat.mob_name  = "Sewer Rat"
	rat.sprite    = "rat"
	rat.max_hp    = 1
	rat.xp_reward = 1
	rat.attacks   = [gnaw] as Array[MobAttackData]
	_registry["rat"] = rat

	# ── Glaciarch (Ribera boss) ─────────────────────────────────────────────────
	var frost_bite   = MobAttackData.new()
	frost_bite.attack_name = "Frost Bite"
	frost_bite.damage      = 2
	frost_bite.effect      = MobAttackData.Effect.NONE

	var freeze       = MobAttackData.new()
	freeze.attack_name = "Freeze"
	freeze.damage      = 1
	freeze.effect      = MobAttackData.Effect.STUN

	var glaciarch    = MobDef.new()
	glaciarch.mob_name  = "Glaciarch"
	glaciarch.sprite    = "glaciarch"
	glaciarch.max_hp    = 8
	glaciarch.xp_reward = 6
	glaciarch.attacks   = [frost_bite, freeze] as Array[MobAttackData]
	_registry["glaciarch"] = glaciarch

	# ── Frozelin (Ribera regular) ────────────────────────────────────────────────
	var chill        = MobAttackData.new()
	chill.attack_name = "Chill"
	chill.damage      = 1
	chill.effect      = MobAttackData.Effect.NONE

	var frozelin     = MobDef.new()
	frozelin.mob_name  = "Frozelin"
	frozelin.sprite    = "frozelin"
	frozelin.max_hp    = 2
	frozelin.xp_reward = 2
	frozelin.attacks   = [chill] as Array[MobAttackData]
	_registry["frozelin"] = frozelin

	# ── Gomelin (Pikoterra boss) ─────────────────────────────────────────────────
	var pilfer       = MobAttackData.new()
	pilfer.attack_name = "Pilfer"
	pilfer.damage      = 2
	pilfer.effect      = MobAttackData.Effect.BLEED

	var slam         = MobAttackData.new()
	slam.attack_name = "Slam"
	slam.damage      = 3
	slam.effect      = MobAttackData.Effect.NONE

	var gomelin      = MobDef.new()
	gomelin.mob_name  = "Gomelin"
	gomelin.sprite    = "gomelin"
	gomelin.max_hp    = 8
	gomelin.xp_reward = 6
	gomelin.attacks   = [pilfer, slam] as Array[MobAttackData]
	_registry["gomelin"] = gomelin

	# ── Pikonaut (Pikoterra regular) ─────────────────────────────────────────────
	var poke         = MobAttackData.new()
	poke.attack_name = "Poke"
	poke.damage      = 1
	poke.effect      = MobAttackData.Effect.NONE

	var pikonaut     = MobDef.new()
	pikonaut.mob_name  = "Pikonaut"
	pikonaut.sprite    = "pikonaut"
	pikonaut.max_hp    = 2
	pikonaut.xp_reward = 2
	pikonaut.attacks   = [poke] as Array[MobAttackData]
	_registry["pikonaut"] = pikonaut

	# ── Add more mobs here ────────────────────
