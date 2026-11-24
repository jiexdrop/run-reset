extends Node

signal gold_changed(new_amount: int)

var tiles: Dictionary = {}
var monsters: Array = []
var level: int = 1
var player: Dictionary = {
	"hp":           10,
	"max_hp":       10,
	"attack":       1,
	"level":        1,
	"xp":           0,
	"xp_to_next":   4,
	"energy":       10,
	"max_energy":   10,
	"poison_turns": 0,
	"frozen_turns": 0,
	"electrified_turns": 0,
	"gold":         0,
}
var zone: String = "default"
var zone_stage: int = 1
## Key of the tile the player is standing on ("x,y"). Every tile reveal is a
## step, so this follows the most recently revealed tile.
var player_tile: String = "0,0"
var dirty: bool = false

func mark_dirty() -> void:
	dirty = true


func get_gold() -> int:
	return int(player.get("gold", 0))


func add_gold(amount: int) -> void:
	player["gold"] = max(0, get_gold() + amount)
	mark_dirty()
	emit_signal("gold_changed", player["gold"])


func spend_gold(amount: int) -> bool:
	if get_gold() < amount:
		return false
	player["gold"] -= amount
	mark_dirty()
	emit_signal("gold_changed", player["gold"])
	return true
