extends Node

var tiles: Dictionary = {}     # key: "x,y"  value: { visible, type, … }
var monsters: Array = []       # [ { id, name, hp, max_hp, … }, … ]
var player: Dictionary = {
	"hp": 100, "max_hp": 100,
	"attack": 10, "level": 1, "xp": 0
}
var dirty: bool = false        # true = unsaved changes

func mark_dirty() -> void:
	dirty = true
