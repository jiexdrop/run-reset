extends Node2D

const TILE = preload("uid://ceosbosrytods")
const BUSH = preload("res://scenes/bush.tscn")

@onready var camera_2d: Camera2D = $Camera2D

const TILE_SIZE = 70
const NUM_ROOMS = 12
const MOB_SPAWN_CHANCE  = 0.6
const BUSH_SPAWN_CHANCE = 0.10
const ZONE_CYCLE_LENGTH = 3

const CAMERA_PADDING  = 1.5
const CAMERA_SPEED    = 4.0
const ZOOM_SPEED      = 3.0

# ── Dungeon generation tuning ───────────────────────────────────────────────
const DIRS: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const MAX_LEG          = 3   # longest single straight run (either a whole
							  # straight corridor, or one leg of a bend)
const MAX_CORRIDOR_LEN = 5   # hard cap on total corridor length (both legs)
const CANDIDATE_POOL   = 4   # randomly choose among this many best-scoring
							  # placements, for variety without losing compactness

var _target_position: Vector2 = Vector2.ZERO
var _target_zoom:     Vector2 = Vector2.ONE
var _spawned_tiles: Array = []
var _door_node: Node2D = null

# Scratch dungeon-generation state (only valid while generate_tiles() runs).
var _gen_floor: Dictionary = {}
var _edge_dots: Dictionary = {} 

func _ready() -> void:
	add_to_group("game")
	_apply_theme()

	if GameState.tiles.is_empty():
		generate_tiles()
	else:
		restore_tiles()
		_check_restore_door()

	call_deferred("_snap_camera_initial")


func _snap_camera_initial() -> void:
	_update_camera_target()
	camera_2d.position = _target_position
	camera_2d.zoom     = _target_zoom

func _apply_theme() -> void:
	RenderingServer.set_default_clear_color(ZoneRegistry.get_bg_color(GameState.zone))


func _key(p: Vector2i) -> String:
	return "%d,%d" % [p.x, p.y]


func _is_orth_neighbor(a: Vector2i, b: Vector2i) -> bool:
	var d = a - b
	return (abs(d.x) + abs(d.y)) == 1


func _perp_dirs(d: Vector2i) -> Array:
	if d.x != 0:  # horizontal travel → perpendicular is vertical
		return [Vector2i(0, 1), Vector2i(0, -1)]
	else:          # vertical travel → perpendicular is horizontal
		return [Vector2i(1, 0), Vector2i(-1, 0)]


func _diag_clear(pos: Vector2i, anchor: Vector2i) -> bool:
	for dx in [-1, 1]:
		for dy in [-1, 1]:
			var npos = pos + Vector2i(dx, dy)
			if _gen_floor.has(_key(npos)):
				# Expected diagonal "kiss" at a branch point or bend — allowed.
				if _is_orth_neighbor(npos, anchor):
					continue
				return false
	return true


# Validate a candidate corridor cell given current travel direction `dir`,
# extending from `anchor` (the previous cell on this path).
func _corridor_cell_ok(pos: Vector2i, dir: Vector2i, anchor: Vector2i) -> bool:
	if _gen_floor.has(_key(pos)):
		return false
	if not _diag_clear(pos, anchor):
		return false
	# Perpendicular neighbours must be empty (keeps the corridor single-file).
	for pd in _perp_dirs(dir):
		if _gen_floor.has(_key(pos + pd)):
			return false
	return true


# Validate a candidate room cell. Its only allowed orthogonal neighbour is
# the single incoming corridor tile `entry_key`.
func _room_cell_ok(pos: Vector2i, entry_key: String, anchor: Vector2i) -> bool:
	var key = _key(pos)
	if _gen_floor.has(key):
		return false
	if not _diag_clear(pos, anchor):
		return false
	for d in DIRS:
		var nk = _key(pos + d)
		if _gen_floor.has(nk) and nk != entry_key:
			return false
	return true


func generate_tiles() -> void:
	_gen_floor = {}

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	_gen_floor["0,0"] = "room"
	var rooms: Array = [Vector2i(0, 0)]

	for _i in range(NUM_ROOMS - 1):
		# Centroid of the current dungeon — candidates closer to it score
		# better, which keeps growth clustered instead of sprawling.
		var centroid := Vector2.ZERO
		for r in rooms:
			centroid += Vector2(r)
		centroid /= rooms.size()

		var candidates: Array = []  # { room_pos, cells, score }

		for base in rooms:
			# ── Straight shots in each of the 4 directions ──
			for dir in DIRS:
				var anchor = base
				var cells: Array = []
				for step in range(1, MAX_CORRIDOR_LEN + 1):
					var c = base + dir * step
					if not _corridor_cell_ok(c, dir, anchor):
						break
					cells.append(c)
					anchor = c

					var room_pos  = c + dir
					var entry_key = _key(c)
					if _room_cell_ok(room_pos, entry_key, c):
						var dist = Vector2(room_pos).distance_to(centroid)
						candidates.append({
							"room_pos": room_pos,
							"cells":    cells.duplicate(),
							"score":    cells.size() * 10.0 + dist,
						})

			# ── L-shaped paths: leg in dir1, 90° turn, leg in dir2 ──
			for dir1 in DIRS:
				var anchor1 = base
				var cells1: Array = []
				for len1 in range(1, MAX_LEG + 1):
					var c1 = base + dir1 * len1
					if not _corridor_cell_ok(c1, dir1, anchor1):
						break
					cells1.append(c1)
					anchor1 = c1

					for dir2 in _perp_dirs(dir1):
						var anchor2 = c1
						var cells2: Array = []
						for len2 in range(1, MAX_LEG + 1):
							if cells1.size() + len2 > MAX_CORRIDOR_LEN:
								break
							var c2 = c1 + dir2 * len2
							if not _corridor_cell_ok(c2, dir2, anchor2):
								break
							cells2.append(c2)
							anchor2 = c2

							var room_pos  = c2 + dir2
							var entry_key = _key(c2)
							if _room_cell_ok(room_pos, entry_key, c2):
								var all_cells = cells1 + cells2
								var dist = Vector2(room_pos).distance_to(centroid)
								candidates.append({
									"room_pos": room_pos,
									"cells":    all_cells,
									"score":    all_cells.size() * 10.0 + dist,
								})

		if candidates.is_empty():
			print("[gen] could not place room ", _i + 1, " — skipping")
			continue

		candidates.sort_custom(func(a, b): return a["score"] < b["score"])
		var pool_size = min(CANDIDATE_POOL, candidates.size())
		var pick = candidates[rng.randi_range(0, pool_size - 1)]

		for c in pick["cells"]:
			_gen_floor[_key(c)] = "corridor"
		var rp = pick["room_pos"]
		_gen_floor[_key(rp)] = "room"
		rooms.append(rp)

	# Populate GameState.
	var pool = MobRegistry.get_pool(GameState.zone)
	var boss_key: String = ZoneRegistry.get_boss(GameState.zone)
	var place_boss: bool = (GameState.zone_stage == ZONE_CYCLE_LENGTH) and boss_key != ""

	# Candidate rooms for the boss: any room tile except the entry room "0,0".
	var boss_candidates: Array = []
	for key in _gen_floor:
		if key != "0,0" and _gen_floor[key] == "room":
			boss_candidates.append(key)

	var boss_room_key: String = ""
	if place_boss and not boss_candidates.is_empty():
		boss_room_key = boss_candidates[rng.randi_range(0, boss_candidates.size() - 1)]

	for key in _gen_floor:
		var tile_type = _gen_floor[key]
		var mob_key: String = ""

		if key == boss_room_key:
			mob_key = boss_key
		elif tile_type == "room" and key != "0,0" and not pool.is_empty():
			if randf() < MOB_SPAWN_CHANCE:
				mob_key = pool[randi() % pool.size()]

		var has_bush: bool = false
		if tile_type == "room" and key != "0,0" and mob_key == "":
			has_bush = randf() < BUSH_SPAWN_CHANCE

		GameState.tiles[key] = {
			"visible":        key == "0,0",
			"type":           tile_type,
			"mob":            mob_key,
			"mob_dead":       false,
			"has_bush":       has_bush,
			"bush_harvested": false,
		}

	_spawn_tiles()


# ── Restore from save ─────────────────────────────────────────────────────────

func restore_tiles() -> void:
	_spawn_tiles()


func restore_combat(combat_ui: Control) -> void:
	var key_to_idx: Dictionary = {}
	for i in range(GameState.monsters.size()):
		var tile_key = GameState.monsters[i].get("tile_key", "")
		if tile_key != "":
			key_to_idx[tile_key] = i

	if key_to_idx.is_empty():
		return

	for tile in _spawned_tiles:
		var tile_key   = "%d,%d" % [tile.grid_x, tile.grid_y]
		var tile_state = GameState.tiles.get(tile_key, {})
		if not tile_state.get("visible", false):
			continue
		if not key_to_idx.has(tile_key):
			continue
		var mob_idx = key_to_idx[tile_key]
		var monster = GameState.monsters[mob_idx]
		if monster.get("hp", 0) <= 0:
			continue

		combat_ui.add_mob_to_combat(mob_idx)


# ── Door ──────────────────────────────────────────────────────────────────────

func spawn_exit_door() -> void:
	if _door_node != null:
		return

	for key in GameState.tiles:
		if key == "door_spawned":
			continue
		var tdata = GameState.tiles[key]
		var mob_key: String = tdata.get("mob", "")
		if mob_key != "" and not tdata.get("mob_dead", false):
			return

	var revealed: Array = []
	for key in GameState.tiles:
		if key == "door_spawned":
			continue
		if GameState.tiles[key].get("visible", false):
			var parts = key.split(",")
			revealed.append(Vector2(parts[0].to_int(), parts[1].to_int()))

	var center := Vector2.ZERO
	if not revealed.is_empty():
		for v in revealed:
			center += v
		center /= revealed.size()

	var _is_safe_tile = func(k: String) -> bool:
		if k == "0,0":
			return false
		var td = GameState.tiles[k]
		if not td.get("visible", false):
			return false
		var mk: String = td.get("mob", "")
		if mk != "" and not td.get("mob_dead", false):
			return false
		if td.get("has_bush", false) and not td.get("bush_harvested", false):
			return false
		return true

	var best_key := ""
	var best_dist := INF
	for key in GameState.tiles:
		if key == "door_spawned":
			continue
		if not _is_safe_tile.call(key):
			continue
		var parts = key.split(",")
		var v = Vector2(parts[0].to_int(), parts[1].to_int())
		var d = v.distance_to(center)
		if d < best_dist:
			best_dist = d
			best_key = key

	if best_key == "":
		for key in GameState.tiles:
			if key == "door_spawned":
				continue
			var tdata = GameState.tiles[key]
			if tdata.get("visible", false) and tdata.get("type", "") == "room":
				best_key = key
				break

	if best_key == "":
		best_key = "0,0"

	var bparts = best_key.split(",")
	var door_world_pos = Vector2(bparts[0].to_int(), bparts[1].to_int()) * TILE_SIZE

	_door_node = _build_door_node(door_world_pos)
	add_child(_door_node)

	GameState.tiles["door_spawned"] = {"door": true}
	GameState.mark_dirty()
	SaveManager.save()


func _check_restore_door() -> void:
	if not GameState.tiles.has("door_spawned"):
		return
	GameState.tiles.erase("door_spawned")
	spawn_exit_door()


func _build_door_node(world_pos: Vector2) -> Node2D:
	var door       := Node2D.new()
	door.name      = "ExitDoor"
	door.position  = world_pos
	door.z_index   = 10

	var tex_rect           := Sprite2D.new()
	tex_rect.texture       = load("res://assets/door/door.png")
	tex_rect.centered      = true
	var door_display_size  := 50.0
	if tex_rect.texture:
		var sz = tex_rect.texture.get_size()
		tex_rect.scale = Vector2(door_display_size / sz.x, door_display_size / sz.y)
	door.add_child(tex_rect)

	var lbl               := Label.new()
	lbl.text              = "Next Floor"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position         = Vector2(-40, -45)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	door.add_child(lbl)

	var area     := Area2D.new()
	var shape    := CollisionShape2D.new()
	var rect_shp := RectangleShape2D.new()
	rect_shp.size = Vector2(60, 60)
	shape.shape   = rect_shp
	area.add_child(shape)
	door.add_child(area)
	area.input_pickable = true
	area.input_event.connect(_on_door_clicked)

	return door


func _on_door_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_enter_next_level()


func _enter_next_level() -> void:
	GameState.tiles = {}
	GameState.monsters = []
	GameState.level += 1

	# ── Zone cycling ──────────────────────────────────────────────────────────
	# Floors run in fixed-length cycles per zone. Floor 1 is always "default"
	# (set by GameState's initial values / reset()) — this only advances the
	# cycle on floors after that.
	GameState.zone_stage += 1
	if GameState.zone_stage > ZONE_CYCLE_LENGTH:
		GameState.zone_stage = 1
		var choices: Array = ZoneRegistry.get_zone_ids(true)  # exclude "default"
		# Avoid picking the same zone twice in a row when more than one exists.
		if choices.size() > 1:
			choices.erase(GameState.zone)
		GameState.zone = choices[randi() % choices.size()]

	GameState.mark_dirty()
	SaveManager.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ── Shared tile spawning ──────────────────────────────────────────────────────

func _spawn_tiles() -> void:
	_spawned_tiles.clear()
	var zone_tiles: Array = ZoneRegistry.get_tiles(GameState.zone)

	for key in GameState.tiles:
		if key == "door_spawned":
			continue
		var parts = key.split(",")
		if parts.size() < 2:
			continue
		var gx       = parts[0].to_int()
		var gy       = parts[1].to_int()
		var instance = TILE.instantiate()
		instance.position.x = gx * TILE_SIZE
		instance.position.y = gy * TILE_SIZE
		instance.grid_x     = gx
		instance.grid_y     = gy
		instance.visible    = GameState.tiles[key].get("visible", false)
		if not zone_tiles.is_empty():
			instance.set_tile_texture(zone_tiles[randi() % zone_tiles.size()])
		var mob_key  = GameState.tiles[key].get("mob", "")
		var mob_dead = GameState.tiles[key].get("mob_dead", false)
		instance.set_mob(mob_key, mob_dead)
		add_child(instance)
		_spawned_tiles.append(instance)

		if GameState.tiles[key].get("has_bush", false):
			_spawn_bush(key, gx, gy,
				GameState.tiles[key].get("visible", false),
				GameState.tiles[key].get("bush_harvested", false))

	update_edge_dots()

func _spawn_bush(tile_key: String, gx: int, gy: int, tile_visible: bool, harvested: bool) -> void:
	var tile_node: Node2D = null
	for t in _spawned_tiles:
		if t.grid_x == gx and t.grid_y == gy:
			tile_node = t
			break
	if tile_node == null:
		return

	var bush: Bush = BUSH.instantiate()
	bush.z_index   = 5
	bush.position  = Vector2(0, 0)
	bush.visible   = tile_visible
	tile_node.add_child(bush)
	bush.setup(tile_key, harvested)

	tile_node.visibility_changed.connect(func():
		bush.visible = tile_node.visible
	)


# ── Camera ────────────────────────────────────────────────────────────────────

func center_camera_on_revealed() -> void:
	_update_camera_target()
	update_edge_dots()

func _update_camera_target() -> void:
	var revealed: Array = []
	for key in GameState.tiles:
		if key == "door_spawned":
			continue
		if GameState.tiles[key].get("visible", false):
			var parts = key.split(",")
			if parts.size() < 2:
				continue
			revealed.append(Vector2(parts[0].to_int(), parts[1].to_int()))

	if revealed.is_empty():
		_target_position = Vector2.ZERO
		_target_zoom     = Vector2.ONE
		return

	var min_x = revealed[0].x;  var max_x = revealed[0].x
	var min_y = revealed[0].y;  var max_y = revealed[0].y
	for v in revealed:
		min_x = min(min_x, v.x);  max_x = max(max_x, v.x)
		min_y = min(min_y, v.y);  max_y = max(max_y, v.y)

	var world_min = Vector2(min_x, min_y) * TILE_SIZE
	var world_max = Vector2(max_x, max_y) * TILE_SIZE
	_target_position = (world_min + world_max) / 2.0

	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		# Layout hasn't resolved yet (e.g. right after stretch=true is set on
		# SubViewportContainer). Retry next frame instead of dividing by zero.
		call_deferred("_update_camera_target")
		return

	var content_width  = (max_x - min_x + 1 + CAMERA_PADDING * 2) * TILE_SIZE
	var content_height = (max_y - min_y + 1 + CAMERA_PADDING * 2) * TILE_SIZE

	var zoom_x = viewport_size.x / content_width
	var zoom_y = viewport_size.y / content_height
	_target_zoom = Vector2(min(zoom_x, zoom_y), min(zoom_x, zoom_y))

func _process(delta: float) -> void:
	camera_2d.position = camera_2d.position.lerp(_target_position, CAMERA_SPEED * delta)
	camera_2d.zoom     = camera_2d.zoom.lerp(_target_zoom,         ZOOM_SPEED  * delta)

# ── Edge dots (unrevealed tiles adjacent to a revealed tile) ──────────────────

func update_edge_dots() -> void:
	for key in GameState.tiles.keys():
		if key == "door_spawned":
			continue

		var tdata = GameState.tiles[key]
		var revealed: bool = tdata.get("visible", false)
		var should_show := false

		if not revealed:
			var parts = key.split(",")
			if parts.size() == 2:
				var gx = parts[0].to_int()
				var gy = parts[1].to_int()
				for d in DIRS:
					var nk = _key(Vector2i(gx, gy) + d)
					if GameState.tiles.has(nk) and GameState.tiles[nk].get("visible", false):
						should_show = true
						break

		if should_show:
			if not _edge_dots.has(key):
				_spawn_edge_dot(key)
		else:
			if _edge_dots.has(key):
				_edge_dots[key].queue_free()
				_edge_dots.erase(key)


func _spawn_edge_dot(key: String) -> void:
	var parts = key.split(",")
	var gx = parts[0].to_int()
	var gy = parts[1].to_int()

	var dot := Area2D.new()
	dot.position = Vector2(gx, gy) * TILE_SIZE
	dot.z_index  = 6

	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/tiles/dot.png")
	dot.add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	dot.add_child(shape)

	dot.input_pickable = true
	dot.input_event.connect(_on_edge_dot_clicked.bind(key))

	add_child(dot)
	_edge_dots[key] = dot


func _on_edge_dot_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, key: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			for tile in _spawned_tiles:
				if "%d,%d" % [tile.grid_x, tile.grid_y] == key:
					tile.reveal()
					return
