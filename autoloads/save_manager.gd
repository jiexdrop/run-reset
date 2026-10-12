extends Node

const SAVE_PATH = "user://save.json"

func save() -> void:
	var data = {
		"tiles":       GameState.tiles,
		"monsters":    GameState.monsters,
		"player":      GameState.player,
		"player_tile": GameState.player_tile,
		"inventory":   InventoryState.to_dict(),
		"zone":        GameState.zone,
		"zone_stage":  GameState.zone_stage,
		"level":       GameState.level,
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	GameState.dirty = false

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed:
		GameState.tiles      = parsed.get("tiles",    {})
		GameState.monsters   = parsed.get("monsters", [])
		GameState.player     = parsed.get("player",   GameState.player)
		if parsed.has("inventory"):
			InventoryState.from_dict(parsed["inventory"])
		GameState.zone       = parsed.get("zone", "default")
		GameState.zone_stage = parsed.get("zone_stage", 1)
		GameState.level      = parsed.get("level", 1)
		var saved_tile = str(parsed.get("player_tile", "0,0"))
		GameState.player_tile = saved_tile if GameState.tiles.has(saved_tile) else "0,0"
		_sync_phase_config()
	#if InventoryState.DEBUG_GIVE_WEAPONS:
		#InventoryState.debug_grant_weapons_and_spells()

## Phase-gating config is stored on each saved mob. Re-sync it from the
## MobDef so saves written before the phase categories were renamed (e.g.
## "throwable"/"sword" -> "ranged"/"melee") keep matching the current attack
## range classification instead of deflecting every attack.
func _sync_phase_config() -> void:
	for mob in GameState.monsters:
		if not (mob is Dictionary):
			continue
		var def = MobRegistry.get_def(String(mob.get("mob_key", "")))
		if def == null:
			continue
		mob["phase_split_hp"]      = def.phase_split_hp
		mob["phase1_allowed"]      = def.phase1_allowed.duplicate()
		mob["phase2_allowed"]      = def.phase2_allowed.duplicate()
		mob["phase1_deny_message"] = def.phase1_deny_message
		mob["phase2_deny_message"] = def.phase2_deny_message

func reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.tiles      = {}
	GameState.monsters   = []
	GameState.player     = {
		"hp":         10,
		"max_hp":     10,
		"attack":      1,
		"level":       1,
		"xp":          0,
		"xp_to_next": 4,
		"energy":     10,
		"max_energy": 10,
		"poison_turns": 0,
		"frozen_turns": 0,
		"electrified_turns": 0,
	}
	GameState.zone       = "default"
	GameState.zone_stage = 1
	GameState.level      = 1
	GameState.player_tile = "0,0"
	GameState.dirty      = false
	InventoryState.from_dict({})
	InventoryState.add_item("health_potion", 1)   # starter kit: one free potion
	if InventoryState.DEBUG_GIVE_WEAPONS:
		InventoryState.debug_grant_weapons_and_spells()
