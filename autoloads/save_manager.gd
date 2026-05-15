extends Node

const SAVE_PATH = "user://save.json"

func save() -> void:
	var data = {
		"tiles":    GameState.tiles,
		"monsters": GameState.monsters,
		"player":   GameState.player
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	GameState.dirty = false

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed:
		GameState.tiles    = parsed.get("tiles",    {})
		GameState.monsters = parsed.get("monsters", [])
		GameState.player   = parsed.get("player",   GameState.player)
