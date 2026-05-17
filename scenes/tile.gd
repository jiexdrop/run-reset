extends Area2D

@export var grid_x: int = 0
@export var grid_y: int = 0

# Mob on this tile ("" = none)
var _mob_key:  String = ""
var _mob_dead: bool   = false

# Small mob indicator node spawned on top of the tile
var _mob_indicator: Node2D = null


# ── Called by game.gd after instantiation ────────────────────────────────────

func set_mob(mob_key: String, mob_dead: bool) -> void:
	_mob_key  = mob_key
	_mob_dead = mob_dead
	_refresh_mob_indicator()


# ── Visibility / reveal ───────────────────────────────────────────────────────

func reveal() -> void:
	visible = true
	GameState.tiles["%d,%d" % [grid_x, grid_y]]["visible"] = true
	GameState.mark_dirty()
	SaveManager.save()
	get_tree().get_first_node_in_group("game").center_camera_on_revealed()


# ── Mob indicator ─────────────────────────────────────────────────────────────

func _refresh_mob_indicator() -> void:
	# Remove old indicator if present
	if _mob_indicator:
		_mob_indicator.queue_free()
		_mob_indicator = null

	if _mob_key == "" or _mob_dead:
		return

	# Build a simple clickable circle as the mob indicator.
	# Replace with a Sprite2D + proper texture once you have mob tile sprites.
	var indicator = Node2D.new()
	indicator.name = "MobIndicator"

	# We use a Label-based button so it works without extra assets.
	# Swap this for a proper AnimatedSprite2D / Sprite2D in production.
	var btn = TextureButton.new()

	var def = MobRegistry.get_def(_mob_key)

	btn.texture_normal = MobCard.MOB_SPRITES.get(def.sprite)

	btn.custom_minimum_size = Vector2(58, 58)
	btn.position = -btn.custom_minimum_size / 2

	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	btn.tooltip_text = _get_mob_label()

	btn.pressed.connect(_on_mob_clicked)

	indicator.add_child(btn)

	add_child(indicator)
	_mob_indicator = indicator


func _get_mob_label() -> String:
	var def = MobRegistry.get_def(_mob_key)
	return def.mob_name if def else _mob_key


# ── Combat trigger ────────────────────────────────────────────────────────────

func _on_mob_clicked() -> void:
	if _mob_dead:
		return

	var def: MobDef = MobRegistry.get_def(_mob_key)
	if def == null:
		push_warning("tile._on_mob_clicked: unknown mob key '%s'" % _mob_key)
		return

	# Build a runtime mob entry and store it in GameState.monsters.
	# We keep the tile key so CombatUI can mark the mob as dead when it falls.
	var mob_entry = {
		"name":      def.mob_name,
		"sprite":    def.sprite,
		"hp":        def.max_hp,
		"max_hp":    def.max_hp,
		"xp_reward": def.xp_reward,
		"attacks":   [],          # serialised below
		"tile_key":  "%d,%d" % [grid_x, grid_y],
	}

	# Serialise MobAttackData into plain dicts for GameState (JSON-safe).
	for atk in def.attacks:
		mob_entry["attacks"].append({
			"attack_name": atk.attack_name,
			"damage":      atk.damage,
			"effect":      atk.effect,
		})

	# Replace any existing entry for this tile key (avoid duplicates on re-click).
	var existing_idx = -1
	for i in range(GameState.monsters.size()):
		if GameState.monsters[i].get("tile_key", "") == mob_entry["tile_key"]:
			existing_idx = i
			break

	var mob_idx: int
	if existing_idx >= 0:
		GameState.monsters[existing_idx] = mob_entry
		mob_idx = existing_idx
	else:
		GameState.monsters.append(mob_entry)
		mob_idx = GameState.monsters.size() - 1

	# Build player attacks from AttackData resources.
	# For now we give the player a basic sword. Extend this with your AttackData pool.
	var sword        = AttackData.new()
	sword.attack_name = "Sword"
	sword.damage      = GameState.player.get("attack", 1)
	sword.energy_cost = 1

	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if combat_ui:
		combat_ui.start_combat([mob_idx], [sword], "%d,%d" % [grid_x, grid_y])
	else:
		push_warning("tile: no node in group 'combat_ui' found")


# ── Input (tile click → reveal neighbours) ───────────────────────────────────

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var space_state = get_world_2d().direct_space_state

			var directions = [
				Vector2(50, 0),
				Vector2(-50, 0),
				Vector2(0, 50),
				Vector2(0, -50),
			]

			for dir in directions:
				var query = PhysicsRayQueryParameters2D.create(position, position + dir)
				query.collide_with_areas = true
				var result = space_state.intersect_ray(query)
				if result:
					result.collider.reveal()


# ── Called by CombatUI when the mob on this tile dies ────────────────────────

func on_mob_defeated() -> void:
	_mob_dead = true
	var key = "%d,%d" % [grid_x, grid_y]
	if GameState.tiles.has(key):
		GameState.tiles[key]["mob_dead"] = true
	GameState.mark_dirty()
	SaveManager.save()
	_refresh_mob_indicator()
