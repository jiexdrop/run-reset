extends Node

const SAVE_PATH = "user://save.json"   # was save.json — must match init.gd

func save() -> void:
	print("[SAVING]")
	var data = {
		"tiles":    GameState.tiles,
		"monsters": GameState.monsters,
		"player":   GameState.player
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	GameState.dirty = false

func load_save() -> void:          # renamed from load() — avoids shadowing built-in
	if not FileAccess.file_exists(SAVE_PATH): return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed:
		GameState.tiles    = parsed.get("tiles",    {})
		GameState.monsters = parsed.get("monsters", [])
		GameState.player   = parsed.get("player",   GameState.player)

func reset() -> void:              # wipe state for a new game
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.tiles    = {}
	GameState.monsters = []
	GameState.player   = { "hp": 100, "max_hp": 100, "attack": 10, "level": 1, "xp": 0 }
	GameState.dirty    = false
