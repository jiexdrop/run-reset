extends Node

var tiles: Dictionary = {}     # key: "x,y"  value: { visible, type, … }
var monsters: Array = []       # [ { id, name, hp, max_hp, sprite, xp_reward, … }, … ]
var player: Dictionary = {
	"hp":         10,
	"max_hp":     10,
	"attack":      1,
	"level":       1,
	"xp":          0,
	"xp_to_next": 10,
	"energy":     10,
	"max_energy": 10,
}
var dirty: bool = false        # true = unsaved changes

func mark_dirty() -> void:
	dirty = true
