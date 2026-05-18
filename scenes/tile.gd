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

	# If this tile has a live mob, add it to combat automatically.
	if _mob_key != "" and not _mob_dead:
		_trigger_combat()


# ── Mob indicator (visual only — no click interaction) ───────────────────────
func _refresh_mob_indicator() -> void:
	if _mob_indicator:
		_mob_indicator.queue_free()
		_mob_indicator = null

	if _mob_key == "" or _mob_dead:
		return

	var def = MobRegistry.get_def(_mob_key)
	if def == null:
		return

	var indicator := Node2D.new()
	indicator.name = "MobIndicator"

	indicator.position = Vector2.ZERO

	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = MobCard.MOB_SPRITES.get(def.sprite)

	# Scale to desired size
	var icon_size := 50.0

	if sprite.texture:
		var tex_size = sprite.texture.get_size()
		var scale_factor = min(
			icon_size / tex_size.x,
			icon_size / tex_size.y
		)
		sprite.scale = Vector2.ONE * scale_factor

	# Sprite2D is automatically centered by default
	sprite.centered = true

	indicator.add_child(sprite)
	add_child(indicator)

	_mob_indicator = indicator

# ── Combat trigger (called on reveal) ────────────────────────────────────────

func _trigger_combat() -> void:
	var def: MobDef = MobRegistry.get_def(_mob_key)
	if def == null:
		push_warning("tile._trigger_combat: unknown mob key '%s'" % _mob_key)
		return

	# Build a runtime mob entry.
	var mob_entry = {
		"name":      def.mob_name,
		"sprite":    def.sprite,
		"hp":        def.max_hp,
		"max_hp":    def.max_hp,
		"xp_reward": def.xp_reward,
		"attacks":   [],
		"tile_key":  "%d,%d" % [grid_x, grid_y],
	}

	for atk in def.attacks:
		mob_entry["attacks"].append({
			"attack_name": atk.attack_name,
			"damage":      atk.damage,
			"effect":      atk.effect,
		})

	# Replace or append in GameState.monsters.
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

	# Build the player's sword attack.
	var sword         = AttackData.new()
	sword.attack_name = "Sword"
	sword.damage      = GameState.player.get("attack", 1)
	sword.energy_cost = 1

	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if combat_ui:
		# add_mob_to_combat handles both "start fresh" and "append to existing".
		combat_ui.add_mob_to_combat(mob_idx, [sword])
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
