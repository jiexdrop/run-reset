extends Node

## ZoneRegistry — single place to register every zone.
##
## TO ADD A NEW ZONE
## ──────────────────
## 1. Add its tile textures under res://assets/tiles/<zone>/
## 2. Register its mobs in MobRegistry.gd first (regular pool + optional boss)
## 3. Add an entry below in _build_registry()
##
## The registry is a plain Dictionary: String → Dictionary
##   { tiles: Array[Texture2D], mob_pool: Array[String], boss: String, bg_color: Color }
##
## Access it anywhere via   ZoneRegistry.get_tiles("ribera")  etc.

const DEFAULT_ZONE = "default"

var _registry: Dictionary = {}


func _ready() -> void:
	_build_registry()


func get_tiles(zone: String) -> Array:
	return _registry.get(zone, _registry[DEFAULT_ZONE]).get("tiles", [])


func get_pool(zone: String) -> Array:
	return _registry.get(zone, _registry[DEFAULT_ZONE]).get("mob_pool", [])


func get_boss(zone: String) -> String:
	return _registry.get(zone, _registry[DEFAULT_ZONE]).get("boss", "")


func get_bg_color(zone: String) -> Color:
	return _registry.get(zone, _registry[DEFAULT_ZONE]).get("bg_color", Color(0.796, 0.781, 0.718))


## Returns zone ids eligible for random selection when starting a new cycle.
## exclude_default = true skips "default" (used for floor 4+ picks).
func get_zone_ids(exclude_default: bool = false) -> Array:
	var ids: Array = []
	for id in _registry.keys():
		if exclude_default and id == DEFAULT_ZONE:
			continue
		ids.append(id)
	return ids


# ── Internal ──────────────────────────────────────────────────────────────────

func _build_registry() -> void:
	_registry[DEFAULT_ZONE] = {
		"tiles": [
			preload("res://assets/tiles/tile_main.png"),
		],
		"mob_pool": ["spider", "rat"],
		"boss": "",
		"bg_color": Color(0.796, 0.781, 0.718, 1.0),
	}

	_registry["ribera"] = {
		"tiles": [
			preload("res://assets/tiles/ribera/tile_0.png"),
			preload("res://assets/tiles/ribera/tile_1.png"),
		],
		"mob_pool": ["frozelin"],
		"boss": "glaciarch",
		"bg_color": Color(0.75, 0.88, 0.95, 1.0),
	}

	_registry["pikoterra"] = {
		"tiles": [
			preload("res://assets/tiles/pikoterra/tile_0.png"),
		],
		"mob_pool": ["pikonaut"],
		"boss": "gomelin",
		"bg_color": Color(0.72, 0.80, 0.55, 1.0),
	}
