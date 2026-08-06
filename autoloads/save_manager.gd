extends Node

const SAVE_PATH = "user://save.json"

func save() -> void:
	print("[SAVING]")
	var data = {
		"tiles":      GameState.tiles,
		"monsters":   GameState.monsters,
		"player":     GameState.player,
		"inventory":  InventoryState.to_dict(),
		"zone":       GameState.zone,
		"zone_stage": GameState.zone_stage,
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
	#if InventoryState.DEBUG_GIVE_WEAPONS:
		#InventoryState.debug_grant_weapons_and_spells()

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
		"xp_to_next": 10,
		"energy":     10,
		"max_energy": 10,
		"poison_turns": 0,
		"frozen_turns": 0,
	}
	GameState.zone       = "default"
	GameState.zone_stage = 1
	GameState.dirty      = false
	InventoryState.from_dict({})
	if InventoryState.DEBUG_GIVE_WEAPONS:
		InventoryState.debug_grant_weapons_and_spells()
