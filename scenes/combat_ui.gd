extends Control

const HEART_FULL   = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY  = preload("res://assets/ui/heart_empty.png")
const ENERGY_FULL  = preload("res://assets/ui/energy_full.png")
const ENERGY_EMPTY = preload("res://assets/ui/energy_empty.png")
const EXP_FULL     = preload("res://assets/ui/exp_full.png")
const EXP_EMPTY    = preload("res://assets/ui/exp_empty.png")

const ICON_SIZE = Vector2(20, 20)
const HIT_DELAY = 0.15   # pause between hits of a multi-hit attack

const MobViewScene = preload("res://scenes/mob_view.tscn")
const BagUIScene   = preload("res://scenes/bag_ui.tscn")

const MOB_ATTACK_EFFECTS: Dictionary = {
	"Explode": preload("res://scenes/effects/explosion_effect.tscn"),
}

const SELF_DESTRUCT_ATTACKS: Dictionary = {
	"Explode": true,
}

@onready var level_label:    Label           = $MarginContainer/VBox/StatsSection/LevelLabel
@onready var hearts_grid:    GridContainer   = $MarginContainer/VBox/StatsSection/HeartsGrid
@onready var energy_grid:    GridContainer   = $MarginContainer/VBox/StatsSection/EnergyGrid
@onready var exp_row:        HBoxContainer   = $MarginContainer/VBox/StatsSection/ExpRow
@onready var mob_scroll:     ScrollContainer = $MarginContainer/VBox/CombatSection/MobCarousel/MobScroll
@onready var mob_row:        HBoxContainer   = $MarginContainer/VBox/CombatSection/MobCarousel/MobScroll/MobRow
@onready var attack_bar:     HFlowContainer  = $MarginContainer/VBox/AttackBar
@onready var combat_section: Control         = $MarginContainer/VBox/CombatSection
@onready var log_label:      Label           = $MarginContainer/VBox/LogLabel
@onready var inv_ui:         Control         = $MarginContainer/VBox/InventoryUI

var _active_mob_ids: Array = []
var _player_stunned: bool  = false
var _attack_in_progress: bool = false

var _scroll_index: int = 0
const CARD_WIDTH = 130

var _bag_ui: Control = null
const ICONS_PER_ROW = 12

const DEATH_VFX_DURATION = 1.5
const MOVE_TURN_DELAY = 0.35   # pause between each mob's turn in a move-triggered sequence
const LUNGE_OUT_DIST  = 18.0

var _mob_turns_running: bool = false
var _skip_next_turn: Dictionary = {}

func _ready() -> void:
	add_to_group("combat_ui")
	refresh_stats()
	combat_section.visible = false
	if inv_ui:
		inv_ui.slot_clicked.connect(_on_inventory_slot_clicked)
		inv_ui.bag_opened.connect(_on_bag_opened)
	InventoryState.inventory_changed.connect(_rebuild_attack_bar)
	_rebuild_attack_bar()


func refresh_stats() -> void:
	var p = GameState.player
	level_label.text = "Level  %d" % p.get("level", 1)
	_build_icon_grid(hearts_grid, p.get("hp", 0),      p.get("max_hp", 10),     HEART_FULL,  HEART_EMPTY)
	_build_icon_grid(energy_grid, p.get("energy", 10),  p.get("max_energy", 10), ENERGY_FULL, ENERGY_EMPTY)
	_build_icon_row(exp_row,    p.get("xp", 0),       p.get("xp_to_next", 10), EXP_FULL,    EXP_EMPTY)


func add_mob_to_combat(mob_idx: int) -> void:
	if _active_mob_ids.has(mob_idx):
		return
	if not combat_section.visible:
		_active_mob_ids  = [mob_idx]
		_player_stunned  = false
		combat_section.visible = true
		_log("")
	else:
		_active_mob_ids.append(mob_idx)
		_log("A new enemy joins the fight!")
	_skip_next_turn[mob_idx] = true
	_rebuild_mob_cards()


func end_combat() -> void:
	combat_section.visible = false
	_active_mob_ids = []
	_skip_next_turn.clear()
	_clear_children(mob_row)
	_log("")


func _build_icon_grid(grid: GridContainer, current: int, maximum: int,
					   full_tex: Texture2D, empty_tex: Texture2D) -> void:
	_clear_children(grid)
	grid.columns = ICONS_PER_ROW
	for i in range(maximum):
		var icon = TextureRect.new()
		icon.texture             = full_tex if i < current else empty_tex
		icon.custom_minimum_size = ICON_SIZE
		icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		grid.add_child(icon)

func _build_icon_row(row: HBoxContainer, current: int, maximum: int,
					  full_tex: Texture2D, empty_tex: Texture2D) -> void:
	_clear_children(row)
	for i in range(maximum):
		var icon = TextureRect.new()
		icon.texture             = full_tex if i < current else empty_tex
		icon.custom_minimum_size = ICON_SIZE
		icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)


func _rebuild_mob_cards() -> void:
	_scroll_index = 0
	if mob_row == null:
		return
	_clear_children(mob_row)
	for mob_id in _active_mob_ids:
		if mob_id >= GameState.monsters.size():
			continue
		var mob_view = MobViewScene.instantiate()
		mob_row.add_child(mob_view)
		mob_view.setup(mob_id, GameState.monsters[mob_id])
		mob_view.attack_requested.connect(_on_attack_requested)
		mob_view.mob_died.connect(_on_mob_died)


## Reads the currently equipped hotbar item and returns a normalized attack
## dict. Falls back to bare-handed "Fists" if nothing valid is equipped.
func _get_equipped_attack() -> Dictionary:
	var idx = InventoryState.equipped_index
	if idx >= 0 and idx < InventoryState.hotbar.size():
		var slot = InventoryState.hotbar[idx]
		var key  = slot.get("item_key", "")
		var item_type = ItemRegistry.get_type(key)
		if key != "" and (item_type == "weapon" or item_type == "spell"):
			return {
				"item_key":     key,
				"name":         ItemRegistry.get_item_name(key),
				"damage":       ItemRegistry.get_damage(key),
				"energy_cost":  ItemRegistry.get_energy_cost(key),
				"attack_type":  ItemRegistry.get_attack_type(key),
				"is_spell":     item_type == "spell",
				"hotbar_index": idx,
			}
	return {
		"item_key": "", "name": "Fists", "damage": max(1, GameState.player.get("attack", 1)),
		"energy_cost": 0, "attack_type": "single_swing", "is_spell": false, "hotbar_index": -1,
	}


func _rebuild_attack_bar() -> void:
	if attack_bar == null:
		return
	_clear_children(attack_bar)
	var atk = _get_equipped_attack()
	var type_data = ItemRegistry.get_attack_type_data(atk.attack_type)

	var lbl = Label.new()
	var energy_txt = "  |  %d energy" % int(ceil(atk.energy_cost * type_data.get("energy_mult", 1.0))) if atk.energy_cost > 0 else ""
	lbl.text = "Equipped: %s%s  (DMG %d%s)" % [atk.name, type_data.get("label", ""), atk.damage, energy_txt]
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.custom_minimum_size.x = 0
	attack_bar.add_child(lbl)


func _on_attack_requested(mob_id: int) -> void:
	if _attack_in_progress:
		return
	_do_player_attack(mob_id)


func _do_player_attack(mob_id: int) -> void:
	var atk       = _get_equipped_attack()
	var type_data = ItemRegistry.get_attack_type_data(atk.attack_type)
	var p         = GameState.player

	var energy_needed = int(ceil(atk.energy_cost * type_data.get("energy_mult", 1.0)))
	if energy_needed > 0 and p.get("energy", 0) < energy_needed:
		_log("Not enough energy!")
		return

	p["energy"] = max(0, p.get("energy", 0) - energy_needed)
	GameState.player = p
	refresh_stats()

	var hits        = max(1, type_data.get("hits", 1))
	var dmg_per_hit = max(1, int(round(atk.damage * type_data.get("damage_mult", 1.0) / hits)))

	var target_mob    = GameState.monsters[mob_id]
	var resistances    = target_mob.get("resistances", {})
	var atk_element     = ItemRegistry.get_element(atk.item_key) if atk.item_key != "" else "physical"
	var resist_mult     = resistances.get(atk_element, 1.0)
	dmg_per_hit = max(1, int(round(dmg_per_hit * resist_mult)))
	
	_attack_in_progress = true
	for i in range(hits):
		var mob = GameState.monsters[mob_id]
		if mob.get("hp", 0) <= 0:
			break
		mob["hp"] = max(0, mob.get("hp", 0) - dmg_per_hit)
		GameState.monsters[mob_id] = mob

		_spawn_attack_effect(mob_id, type_data)
		var card = _get_card_for_mob(mob_id)
		if card:
			card.refresh_from_state()

		if hits > 1 and i < hits - 1:
			await get_tree().create_timer(HIT_DELAY).timeout
	_attack_in_progress = false

	if atk.is_spell and atk.hotbar_index >= 0:
		InventoryState.consume_hotbar_item(atk.hotbar_index)

	GameState.mark_dirty()
	SaveManager.save()

	var mob = GameState.monsters[mob_id]
	if mob.get("hp", 0) <= 0:
		_on_mob_died(mob_id)
	else:
		_do_mob_turn(mob_id)


func _spawn_attack_effect(mob_id: int, type_data: Dictionary) -> void:
	var scene: PackedScene = type_data.get("effect_scene", null)
	if scene == null:
		return
	var card = _get_card_for_mob(mob_id)
	if card == null:
		return
	var fx: Node2D = scene.instantiate()
	fx.position = Vector2(60, 40)  # roughly centered over MobCard's sprite
	card.add_child(fx)


func _on_mob_died(mob_id: int) -> void:
	var xp_gain = GameState.monsters[mob_id].get("xp_reward", 1)
	var p       = GameState.player
	p["xp"]     = p.get("xp", 0) + xp_gain
	if p["xp"] >= p.get("xp_to_next", 10):
		p["xp"]    -= p["xp_to_next"]
		p["level"]  = p.get("level", 1) + 1
		_log("Level up! Now level %d" % p["level"])
	GameState.player = p
	refresh_stats()

	var explode_msg = _apply_death_explosion(mob_id)
	var drop_msg     = _roll_loot(mob_id)

	_notify_tile_mob_dead(mob_id)

	GameState.monsters[mob_id]["hp"] = 0
	GameState.mark_dirty()
	SaveManager.save()

	var final_msgs: Array = []
	if explode_msg != "": final_msgs.append(explode_msg)
	if drop_msg    != "": final_msgs.append(drop_msg)
	if not final_msgs.is_empty():
		_log(" ".join(final_msgs))

	await get_tree().create_timer(DEATH_VFX_DURATION).timeout

	if not is_inside_tree():
		return   # scene changed / node freed while we were waiting

	_active_mob_ids.erase(mob_id)
	_skip_next_turn.erase(mob_id)
	_rebuild_mob_cards()

	if _active_mob_ids.is_empty():
		end_combat()
		_check_all_mobs_cleared()
	else:
		_log("")

func _check_all_mobs_cleared() -> void:
	for monster in GameState.monsters:
		if monster.get("hp", 0) > 0:
			return
	if not is_inside_tree():
		return
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_method("spawn_exit_door"):
		game.spawn_exit_door()


func _do_mob_turn(mob_id: int) -> void:
	if _player_stunned:
		_player_stunned = false
		_log("You were stunned — mob skips!")
		return

	var card = _get_card_for_mob(mob_id)
	if card == null:
		return

	var atk: Dictionary = card.do_mob_turn()
	if atk.is_empty():
		return

	await _play_attack_lunge(card)
	if not is_inside_tree():
		return

	_spawn_mob_attack_effect(mob_id, atk.get("attack_name", ""))

	var p      = GameState.player
	var damage = atk.get("damage", 1)
	var effect = atk.get("effect", 0)

	p["hp"] = max(0, p.get("hp", 0) - damage)
	var msg = "%s hits you for %d!" % [GameState.monsters[mob_id].get("name", "Mob"), damage]

	match effect:
		1:
			p["hp"] = max(0, p["hp"] - 1)
			msg += " Poisoned! (-1 extra)"
		2:
			_player_stunned = true
			msg += " You are stunned!"
		4:
			var stolen = _steal_random_item()
			if stolen != "":
				msg += " Gomelin steals your %s!" % ItemRegistry.get_item_name(stolen)

	GameState.player = p
	GameState.mark_dirty()
	SaveManager.save()
	refresh_stats()
	_log(msg)

	if p["hp"] <= 0:
		_on_player_died()

func _on_player_died() -> void:
	_log("You died! Resetting...")
	await get_tree().create_timer(1.5).timeout
	SaveManager.reset()
	get_tree().change_scene_to_file("res://scenes/init.tscn")


func _notify_tile_mob_dead(mob_id: int) -> void:
	var tile_key = GameState.monsters[mob_id].get("tile_key", "")
	if tile_key == "":
		return
	var parts = tile_key.split(",")
	if parts.size() < 2:
		return
	var gx = parts[0].to_int()
	var gy = parts[1].to_int()

	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.grid_x == gx and tile.grid_y == gy:
			tile.on_mob_defeated()
			return

	var game = get_tree().get_first_node_in_group("game")
	if game:
		for tile in game.get_children():
			if tile.get("grid_x") == gx and tile.get("grid_y") == gy:
				tile.on_mob_defeated()
				return

	if GameState.tiles.has(tile_key):
		GameState.tiles[tile_key]["mob_dead"] = true

func _get_card_for_mob(mob_id: int) -> Node:
	for card in mob_row.get_children():
		if card.mob_id == mob_id:
			return card
	return null


func _log(msg: String) -> void:
	if log_label:
		log_label.text = msg


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()

func _scroll_mobs(direction: int) -> void:
	var card_count = mob_row.get_child_count()
	_scroll_index = clampi(_scroll_index + direction, 0, max(0, card_count - 1))
	mob_scroll.scroll_horizontal = _scroll_index * CARD_WIDTH

func _on_inventory_slot_clicked(index: int) -> void:
	var slot = InventoryState.hotbar[index]
	var item_key = slot.get("item_key", "")
	if slot.get("frozen", false) or item_key == "":
		return

	var item_type = ItemRegistry.get_type(item_key)

	if item_type == "weapon" or item_type == "spell":
		InventoryState.equip_item(index)
		var equipped = InventoryState.equipped_index == index
		_log("%s %s." % [ItemRegistry.get_item_name(item_key), "equipped" if equipped else "unequipped"])
		return

	if item_key == "berries":
		var p = GameState.player
		p["hp"] = min(p.get("hp", 0) + 3, p.get("max_hp", 10))
		GameState.player = p
		InventoryState.consume_hotbar_item(index)
		GameState.mark_dirty()
		SaveManager.save()
		refresh_stats()
		_log("You eat berries and restore 3 HP.")

	if item_key == "health_potion":
		var p = GameState.player
		p["hp"] = min(p.get("hp", 0) + ItemRegistry.get_heal_amount(item_key), p.get("max_hp", 10))
		GameState.player = p
		InventoryState.consume_hotbar_item(index)
		GameState.mark_dirty()
		SaveManager.save()
		refresh_stats()
		_log("You drink a Health Potion and restore %d HP." % ItemRegistry.get_heal_amount(item_key))
		return

	if item_key == "energy_potion":
		var p = GameState.player
		p["energy"] = min(p.get("energy", 0) + ItemRegistry.get_energy_amount(item_key), p.get("max_energy", 10))
		GameState.player = p
		InventoryState.consume_hotbar_item(index)
		GameState.mark_dirty()
		SaveManager.save()
		refresh_stats()
		_log("You drink an Energy Potion and restore %d energy." % ItemRegistry.get_energy_amount(item_key))
		return

func _on_bag_opened() -> void:
	if is_instance_valid(_bag_ui):
		return
	_bag_ui = BagUIScene.instantiate()
	get_tree().current_scene.add_child(_bag_ui)
	_bag_ui.closed.connect(_on_bag_closed)


func _on_bag_closed() -> void:
	_bag_ui = null

func _steal_random_item() -> String:
	var candidates: Array = []
	for i in range(InventoryState.HOTBAR_SIZE):
		var slot = InventoryState.hotbar[i]
		if slot.get("item_key", "") != "" and not slot.get("frozen", false):
			candidates.append(i)
	if candidates.is_empty():
		return ""
	var idx = candidates[randi() % candidates.size()]
	var item_key = InventoryState.hotbar[idx]["item_key"]
	InventoryState.consume_hotbar_item(idx)
	return item_key
	
func _roll_loot(mob_id: int) -> String:
	var loot_table: Array = GameState.monsters[mob_id].get("loot_table", [])
	if loot_table.is_empty():
		return ""

	var drops: Array = []
	for entry in loot_table:
		if randf() < entry.get("chance", 0.0):
			var amount = randi_range(entry.get("min", 1), entry.get("max", 1))
			InventoryState.add_item(entry.get("item_key", ""), amount)
			drops.append("%s x%d" % [ItemRegistry.get_item_name(entry.get("item_key", "")), amount])

	if drops.is_empty():
		return ""
	return "%s dropped: %s" % [GameState.monsters[mob_id].get("name", "Mob"), ", ".join(drops)]
	
	
func _spawn_mob_attack_effect(mob_id: int, attack_name: String) -> void:
	var scene: PackedScene = MOB_ATTACK_EFFECTS.get(attack_name, null)
	if scene == null:
		return
	var card = _get_card_for_mob(mob_id)
	if card == null:
		return
	var fx: Node2D = scene.instantiate()
	fx.position = Vector2(60, 40)  # roughly centered over MobCard's sprite
	card.add_child(fx)

## If the dying mob has a self-destruct attack (e.g. Kaze Shroom's Explode),
## apply its damage to the player and play its effect, even though the mob
## never got to take its normal turn.
func _apply_death_explosion(mob_id: int) -> String:
	var attacks: Array = GameState.monsters[mob_id].get("attacks", [])
	for atk in attacks:
		var atk_name: String = atk.get("attack_name", "")
		if SELF_DESTRUCT_ATTACKS.get(atk_name, false):
			_spawn_mob_attack_effect(mob_id, atk_name)
			var damage: int = atk.get("damage", 0)
			var p = GameState.player
			p["hp"] = max(0, p.get("hp", 0) - damage)
			GameState.player = p
			refresh_stats()
			if p["hp"] <= 0:
				_on_player_died()
			return "%s explodes for %d damage!" % [GameState.monsters[mob_id].get("name", "Mob"), damage]
	return ""
	
func on_player_moved() -> void:
	if _mob_turns_running or _attack_in_progress:
		return
	if not combat_section.visible or _active_mob_ids.is_empty():
		return
	_run_mob_turn_sequence()


func _run_mob_turn_sequence() -> void:
	_mob_turns_running = true
	for mob_id in _active_mob_ids.duplicate():
		if not _active_mob_ids.has(mob_id):
			continue
		if mob_id >= GameState.monsters.size():
			continue
		if GameState.monsters[mob_id].get("hp", 0) <= 0:
			continue

		if _skip_next_turn.get(mob_id, false):
			_skip_next_turn.erase(mob_id)   # sat out its first opportunity — now fair game
			continue

		await _do_mob_turn(mob_id)

		if not is_inside_tree():
			_mob_turns_running = false
			return
		if GameState.player.get("hp", 0) <= 0:
			_mob_turns_running = false
			return

		await get_tree().create_timer(MOVE_TURN_DELAY).timeout
	_mob_turns_running = false

## Quick back-and-forth "lunge" on the mob's card to sell an attack —
## moves toward the player, then springs back to its original spot.
func _play_attack_lunge(card: Control) -> void:
	if card == null or not is_instance_valid(card):
		return
	var start_y = card.position.y
	var tween = create_tween()
	tween.tween_property(card, "position:y", start_y - LUNGE_OUT_DIST, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position:y", start_y, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
