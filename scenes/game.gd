extends Node2D

const TILE = preload("uid://ceosbosrytods")

@onready var camera_2d: Camera2D = $Camera2D

const TILE_SIZE = 78
const NUM_ROOMS = 20


func _ready() -> void:
	add_to_group("game")
	if GameState.tiles.is_empty():
		generate_tiles()
	else:
		restore_tiles()
	center_camera_on_revealed()


# ── Fresh generation (New Game) ───────────────────────────────────────────────

func generate_tiles() -> void:
	var floor_tiles: Dictionary = {}
	var room_cells: Dictionary = {}

	var too_close_to_room = func(pos: Vector2i) -> bool:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var neighbour = "%d,%d" % [pos.x + dx, pos.y + dy]
				if room_cells.has(neighbour):
					return true
		return false

	var origin = Vector2i(0, 0)
	floor_tiles["0,0"] = "room"
	room_cells["0,0"] = true
	var rooms: Array = [origin]

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for _i in range(NUM_ROOMS - 1):
		var placed = false
		for _attempt in range(100):
			var base: Vector2i = rooms[rng.randi_range(0, rooms.size() - 1)]
			var dir: Vector2i  = dirs[rng.randi_range(0, 3)]
			var length         = rng.randi_range(1, 3)

			var room_pos = base + dir * (length + 1)
			var room_key = "%d,%d" % [room_pos.x, room_pos.y]

			if floor_tiles.has(room_key):
				continue
			if too_close_to_room.call(room_pos):
				continue

			var corridor_cells: Array = []
			var blocked = false
			for step in range(1, length + 1):
				var c = base + dir * step
				var ck = "%d,%d" % [c.x, c.y]
				if room_cells.has(ck):
					blocked = true
					break
				corridor_cells.append(c)
			if blocked:
				continue

			for c in corridor_cells:
				var ck = "%d,%d" % [c.x, c.y]
				if not floor_tiles.has(ck):
					floor_tiles[ck] = "corridor"

			floor_tiles[room_key] = "room"
			room_cells[room_key]  = true
			rooms.append(room_pos)
			placed = true
			break

		if not placed:
			print("[gen] could not place room ", _i + 1, " after 100 attempts — skipping")

	for key in floor_tiles:
		GameState.tiles[key] = { "visible": key == "0,0", "type": floor_tiles[key] }

	_spawn_tiles()


# ── Restore from save (Continue) ─────────────────────────────────────────────

func restore_tiles() -> void:
	_spawn_tiles()


# ── Shared tile spawning ──────────────────────────────────────────────────────

func _spawn_tiles() -> void:
	for key in GameState.tiles:
		var parts    = key.split(",")
		var gx       = parts[0].to_int()
		var gy       = parts[1].to_int()
		var instance = TILE.instantiate()
		instance.position.x = gx * TILE_SIZE
		instance.position.y = gy * TILE_SIZE
		instance.grid_x     = gx
		instance.grid_y     = gy
		instance.visible    = GameState.tiles[key].get("visible", false)
		add_child(instance)


# ── Camera ────────────────────────────────────────────────────────────────────

func center_camera_on_revealed() -> void:
	var revealed: Array = []
	for key in GameState.tiles:
		if GameState.tiles[key].get("visible", false):
			var parts = key.split(",")
			revealed.append(Vector2(parts[0].to_int(), parts[1].to_int()))

	if revealed.is_empty():
		camera_2d.position = Vector2.ZERO
		return

	# Bounding box in grid coords
	var min_x = revealed[0].x
	var max_x = revealed[0].x
	var min_y = revealed[0].y
	var max_y = revealed[0].y
	for v in revealed:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)

	# Convert to world coords and centre
	var world_min = Vector2(min_x, min_y) * TILE_SIZE
	var world_max = Vector2(max_x, max_y) * TILE_SIZE
	camera_2d.position = (world_min + world_max) / 2.0


func _process(_delta: float) -> void:
	pass
