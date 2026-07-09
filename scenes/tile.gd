extends Area2D

@export var grid_x: int = 0
@export var grid_y: int = 0

var _mob_key:  String = ""
var _mob_dead: bool   = false

var _mob_indicator: Node2D = null


func set_mob(mob_key: String, mob_dead: bool) -> void:
	_mob_key  = mob_key
	_mob_dead = mob_dead
	_refresh_mob_indicator()


func reveal() -> void:
	visible = true
	GameState.tiles["%d,%d" % [grid_x, grid_y]]["visible"] = true
	GameState.mark_dirty()
	SaveManager.save()
	get_tree().get_first_node_in_group("game").center_camera_on_revealed()
	_refresh_mob_indicator()  # show indicator now that tile is visible

	# If this tile has a live mob, add it to combat automatically.
	if _mob_key != "" and not _mob_dead:
		_trigger_combat()

func _refresh_mob_indicator() -> void:
	print("_refresh_mob_indicator")
	if is_instance_valid(_mob_indicator):
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
	sprite.centered = true

	var icon_size := 50.0
	if sprite.texture:
		var tex_size = sprite.texture.get_size()
		var scale_factor = min(icon_size / tex_size.x, icon_size / tex_size.y)
		sprite.scale = Vector2.ONE * scale_factor

	indicator.add_child(sprite)
	add_child(indicator)
	_mob_indicator = indicator

func _trigger_combat() -> void:
	var def: MobDef = MobRegistry.get_def(_mob_key)
	if def == null:
		push_warning("tile._trigger_combat: unknown mob key '%s'" % _mob_key)
		return

	var tile_key_str = "%d,%d" % [grid_x, grid_y]

	# If a live entry already exists for this tile, reuse it — don't overwrite.
	var existing_idx = -1
	for i in range(GameState.monsters.size()):
		if GameState.monsters[i].get("tile_key", "") == tile_key_str:
			existing_idx = i
			break

	var mob_idx: int
	if existing_idx >= 0 and GameState.monsters[existing_idx].get("hp", 0) > 0:
		# Already registered and alive — just re-open combat (e.g. after a save/load).
		mob_idx = existing_idx
	else:
		# Build a fresh runtime mob entry.
		var mob_entry = {
			"name":      def.mob_name,
			"sprite":    def.sprite,
			"hp":        def.max_hp,
			"max_hp":    def.max_hp,
			"xp_reward": def.xp_reward,
			"attacks":   [],
			"tile_key":  tile_key_str,
		}
		for atk in def.attacks:
			mob_entry["attacks"].append({
				"attack_name": atk.attack_name,
				"damage":      atk.damage,
				"effect":      atk.effect,
			})

		if existing_idx >= 0:
			GameState.monsters[existing_idx] = mob_entry
			mob_idx = existing_idx
		else:
			GameState.monsters.append(mob_entry)
			mob_idx = GameState.monsters.size() - 1

		GameState.mark_dirty()
		SaveManager.save()

	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if combat_ui:
		combat_ui.add_mob_to_combat(mob_idx)
	else:
		push_warning("tile: no node in group 'combat_ui' found")


func on_mob_defeated() -> void:
	_mob_dead = true
	var key = "%d,%d" % [grid_x, grid_y]
	if GameState.tiles.has(key):
		GameState.tiles[key]["mob_dead"] = true
	GameState.mark_dirty()
	SaveManager.save()
	_refresh_mob_indicator()
	
func set_tile_texture(tex: Texture2D) -> void:
	$Sprite2D.texture = tex
