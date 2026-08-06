extends Node

var tiles: Dictionary = {}
var monsters: Array = []
var level: int = 1
var player: Dictionary = {
	"hp":           10,
	"max_hp":       10,
	"attack":       1,
	"level":        1,
	"xp":           0,
	"xp_to_next":   10,
	"energy":       10,
	"max_energy":   10,
	"poison_turns": 0,
}
var zone: String = "default"
var zone_stage: int = 1
var dirty: bool = false

func mark_dirty() -> void:
	dirty = true
