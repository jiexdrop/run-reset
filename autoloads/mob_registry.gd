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


func get_pool() -> Array[String]:
	return ROOM_MOB_POOL


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
	spider.max_hp    = 3
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
	rat.max_hp    = 2
	rat.xp_reward = 1
	rat.attacks   = [gnaw] as Array[MobAttackData]
	_registry["rat"] = rat

	# ── Add more mobs here ─────────────────────────────────────────────────────
