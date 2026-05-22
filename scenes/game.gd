extends Node2D

const TILE = preload("uid://ceosbosrytods")

@onready var camera_2d: Camera2D = $Camera2D

const TILE_SIZE = 70
const NUM_ROOMS = 20
const MOB_SPAWN_CHANCE = 0.6

const CAMERA_PADDING  = 1.5
const CAMERA_SPEED    = 4.0
const ZOOM_SPEED      = 3.0

var _target_position: Vector2 = Vector2.ZERO
var _target_zoom:     Vector2 = Vector2.ONE
var _spawned_tiles: Array = []
var _door_node: Node2D = null


func _ready() -> void:
	add_to_group("game")
	_apply_theme()

	if GameState.tiles.is_empty():
		generate_tiles()
	else:
		restore_tiles()
		# Restore door if all mobs were already dead when we saved.
		_check_restore_door()

	_update_camera_target()
	camera_2d.position = _target_position
	camera_2d.zoom     = _target_zoom


func _apply_theme() -> void:
	RenderingServer.set_default_clear_color(Color(0.796, 0.781, 0.718, 1.0))


# ── Fresh generation ──────────────────────────────────────────────────────────

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

	var pool = MobRegistry.get_pool()
	for key in floor_tiles:
		var tile_type = floor_tiles[key]
		var mob_key: String = ""
		if tile_type == "room" and key != "0,0" and not pool.is_empty():
			if randf() < MOB_SPAWN_CHANCE:
				mob_key = pool[randi() % pool.size()]

		GameState.tiles[key] = {
			"visible":  key == "0,0",
			"type":     tile_type,
			"mob":      mob_key,
			"mob_dead": false,
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
		var sword         = AttackData.new()
		sword.attack_name = "Sword"
		sword.damage      = GameState.player.get("attack", 1)
		sword.energy_cost = 1
		combat_ui.add_mob_to_combat(mob_idx, [sword])


# ── Door: spawn when all mobs are cleared ─────────────────────────────────────

## Called by CombatUI when the last monster on the level dies.
func spawn_exit_door() -> void:
	if _door_node != null:
		return  # already spawned

	# Place the door at the centroid of all revealed tiles.
	var revealed: Array = []
	for key in GameState.tiles:
		if GameState.tiles[key].get("visible", false):
			var parts = key.split(",")
			revealed.append(Vector2(parts[0].to_int(), parts[1].to_int()))

	var center := Vector2.ZERO
	if revealed.is_empty():
		center = Vector2.ZERO
	else:
		for v in revealed:
			center += v
		center /= revealed.size()

	# Snap to the nearest tile position.
	var best_key := "0,0"
	var best_dist := INF
	for key in GameState.tiles:
		if GameState.tiles[key].get("visible", false):
			var parts = key.split(",")
			var v = Vector2(parts[0].to_int(), parts[1].to_int())
			var d = v.distance_to(center)
			if d < best_dist:
				best_dist = d
				best_key = key

	var bparts = best_key.split(",")
	var door_world_pos = Vector2(bparts[0].to_int(), bparts[1].to_int()) * TILE_SIZE

	_door_node = _build_door_node(door_world_pos)
	add_child(_door_node)

	# Persist door state so a reload knows to show it.
	GameState.tiles["door_spawned"] = {"door": true}
	GameState.mark_dirty()
	SaveManager.save()


func _check_restore_door() -> void:
	if not GameState.tiles.has("door_spawned"):
		return
	# All mobs cleared on a saved game — restore the door.
	# Re-use spawn_exit_door; temporarily remove the sentinel so it doesn't
	# short-circuit, then remove it from tiles since spawn adds it back.
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

	# Label above the door.
	var lbl               := Label.new()
	lbl.text              = "Next Floor"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position         = Vector2(-40, -45)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	door.add_child(lbl)

	# Clickable area.
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
	GameState.mark_dirty()
	SaveManager.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ── Shared tile spawning ──────────────────────────────────────────────────────

func _spawn_tiles() -> void:
	_spawned_tiles.clear()
	for key in GameState.tiles:
		# Skip the door sentinel key.
		if key == "door_spawned":
			continue
		var parts    = key.split(",")
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
		var mob_key  = GameState.tiles[key].get("mob", "")
		var mob_dead = GameState.tiles[key].get("mob_dead", false)
		instance.set_mob(mob_key, mob_dead)
		add_child(instance)
		_spawned_tiles.append(instance)


# ── Camera ────────────────────────────────────────────────────────────────────

func center_camera_on_revealed() -> void:
	_update_camera_target()


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

	var viewport_size  = get_viewport().get_visible_rect().size
	var content_width  = (max_x - min_x + 1 + CAMERA_PADDING * 2) * TILE_SIZE
	var content_height = (max_y - min_y + 1 + CAMERA_PADDING * 2) * TILE_SIZE

	var zoom_x = viewport_size.x / content_width
	var zoom_y = viewport_size.y / content_height
	_target_zoom = Vector2(min(zoom_x, zoom_y), min(zoom_x, zoom_y))


func _process(delta: float) -> void:
	camera_2d.position = camera_2d.position.lerp(_target_position, CAMERA_SPEED * delta)
	camera_2d.zoom     = camera_2d.zoom.lerp(_target_zoom,         ZOOM_SPEED  * delta)
