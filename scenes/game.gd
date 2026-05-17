extends Node2D

const TILE = preload("uid://ceosbosrytods")

@onready var camera_2d: Camera2D = $Camera2D

const TILE_SIZE = 70
const NUM_ROOMS = 20

# Camera tuning
const CAMERA_PADDING  = 1.5   # extra tiles of breathing room on each side
const CAMERA_SPEED    = 4.0   # lerp speed for position (units/s feel)
const ZOOM_SPEED      = 3.0   # lerp speed for zoom

var _target_position: Vector2 = Vector2.ZERO
var _target_zoom:     Vector2 = Vector2.ONE


func _ready() -> void:
	add_to_group("game")
	_apply_theme()

	if GameState.tiles.is_empty():
		generate_tiles()
	else:
		restore_tiles()

	# Snap instantly on first load — no slide-in from (0,0)
	_update_camera_target()
	camera_2d.position = _target_position
	camera_2d.zoom     = _target_zoom


func _apply_theme() -> void:
	RenderingServer.set_default_clear_color(Color(0.796, 0.781, 0.718, 1.0))


# ── Fresh generation (New Game) ───────────────────────────────────────────────

func generate_tiles() -> void:
	var floor_tiles: Dictionary = {}
	var room_cells:  Dictionary = {}

	var too_close_to_room = func(pos: Vector2i) -> bool:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				if room_cells.has("%d,%d" % [pos.x + dx, pos.y + dy]):
					return true
		return false

	floor_tiles["0,0"] = "room"
	room_cells["0,0"]  = true
	var rooms: Array   = [Vector2i(0, 0)]

	var rng  = RandomNumberGenerator.new()
	rng.randomize()
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	for _i in range(NUM_ROOMS - 1):
		var placed = false
		for _attempt in range(100):
			var base: Vector2i = rooms[rng.randi_range(0, rooms.size() - 1)]
			var dir:  Vector2i = dirs[rng.randi_range(0, 3)]
			var length         = rng.randi_range(1, 3)
			var room_pos       = base + dir * (length + 1)
			var room_key       = "%d,%d" % [room_pos.x, room_pos.y]

			if floor_tiles.has(room_key):
				continue
			if too_close_to_room.call(room_pos):
				continue

			var corridor_cells: Array = []
			var blocked = false
			for step in range(1, length + 1):
				var c  = base + dir * step
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

## Call this whenever revealed tiles change; sets _target_position / _target_zoom.
func center_camera_on_revealed() -> void:
	_update_camera_target()

func _update_camera_target() -> void:
	var revealed: Array = []
	for key in GameState.tiles:
		if GameState.tiles[key].get("visible", false):
			var parts = key.split(",")
			revealed.append(Vector2(parts[0].to_int(), parts[1].to_int()))

	if revealed.is_empty():
		_target_position = Vector2.ZERO
		_target_zoom     = Vector2.ONE
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

	# World-space bounding box (tile centres), expanded by padding
	var world_min = Vector2(min_x, min_y) * TILE_SIZE
	var world_max = Vector2(max_x, max_y) * TILE_SIZE
	_target_position = (world_min + world_max) / 2.0

	# Compute zoom so all tiles + padding fit inside the viewport
	var viewport_size  = get_viewport().get_visible_rect().size
	var content_width  = (max_x - min_x + 1 + CAMERA_PADDING * 2) * TILE_SIZE
	var content_height = (max_y - min_y + 1 + CAMERA_PADDING * 2) * TILE_SIZE

	var zoom_x = viewport_size.x / content_width
	var zoom_y = viewport_size.y / content_height
	var zoom   = min(zoom_x, zoom_y)          # fit the tighter axis; never crop
	_target_zoom = Vector2(zoom, zoom)


func _process(delta: float) -> void:
	# Smooth-lerp position and zoom every frame
	camera_2d.position = camera_2d.position.lerp(_target_position, CAMERA_SPEED * delta)
	camera_2d.zoom     = camera_2d.zoom.lerp(_target_zoom,         ZOOM_SPEED  * delta)
