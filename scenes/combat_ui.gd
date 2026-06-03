extends Control

## CombatUI — right-hand panel: player stats + active combat.
##
## PUBLIC API
## ──────────
##   add_mob_to_combat(mob_idx, player_attacks)
##   end_combat()
##   refresh_stats()

const HEART_FULL   = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY  = preload("res://assets/ui/heart_empty.png")
const ENERGY_FULL  = preload("res://assets/ui/energy_full.png")
const ENERGY_EMPTY = preload("res://assets/ui/energy_empty.png")
const EXP_FULL     = preload("res://assets/ui/exp_full.png")
const EXP_EMPTY    = preload("res://assets/ui/exp_empty.png")

const ICON_SIZE = Vector2(20, 20)

const MobCardScene = preload("res://scenes/mob_card.tscn")

@onready var level_label:    Label           = $MarginContainer/VBox/StatsSection/LevelLabel
@onready var hearts_row:     HBoxContainer   = $MarginContainer/VBox/StatsSection/HeartsRow
@onready var energy_row:     HBoxContainer   = $MarginContainer/VBox/StatsSection/EnergyRow
@onready var exp_row:        HBoxContainer   = $MarginContainer/VBox/StatsSection/ExpRow
@onready var mob_scroll:     ScrollContainer = $MarginContainer/VBox/CombatSection/MobCarousel/MobScroll
@onready var mob_row:        HBoxContainer   = $MarginContainer/VBox/CombatSection/MobCarousel/MobScroll/MobRow
@onready var prev_button:    Button          = $MarginContainer/VBox/CombatSection/MobCarousel/PrevButton
@onready var next_button:    Button          = $MarginContainer/VBox/CombatSection/MobCarousel/NextButton
@onready var attack_bar:     HFlowContainer  = $MarginContainer/VBox/AttackBar
@onready var combat_section: Control         = $MarginContainer/VBox/CombatSection
@onready var log_label:      Label           = $MarginContainer/VBox/LogLabel
@onready var inv_ui:         Control         = $MarginContainer/VBox/InventoryUI

var _active_mob_ids:   Array  = []
var _attacks:          Array  = []
var _selected_attack:  int    = 0
var _player_stunned:   bool   = false

var _scroll_index: int = 0
const CARD_WIDTH = 130  # match MobCard's custom_minimum_size.x + separation

func _ready() -> void:
	add_to_group("combat_ui")
	refresh_stats()
	combat_section.visible = false
	prev_button.pressed.connect(_scroll_mobs.bind(-1))
	next_button.pressed.connect(_scroll_mobs.bind(1))
	if inv_ui:
		inv_ui.slot_clicked.connect(_on_inventory_slot_clicked)

func refresh_stats() -> void:
	var p = GameState.player
	level_label.text = "Level  %d" % p.get("level", 1)
	_build_icon_row(hearts_row, p.get("hp", 0),      p.get("max_hp", 10),     HEART_FULL,  HEART_EMPTY)
	_build_icon_row(energy_row, p.get("energy", 10),  p.get("max_energy", 10), ENERGY_FULL, ENERGY_EMPTY)
	_build_icon_row(exp_row,    p.get("xp", 0),       p.get("xp_to_next", 10), EXP_FULL,    EXP_EMPTY)


func add_mob_to_combat(mob_idx: int, player_attacks: Array) -> void:
	if _active_mob_ids.has(mob_idx):
		return

	if not combat_section.visible:
		_active_mob_ids  = [mob_idx]
		_attacks         = player_attacks.duplicate()
		_selected_attack = 0
		_player_stunned  = false
		combat_section.visible = true
		_rebuild_attack_bar()
		_log("")
	else:
		_active_mob_ids.append(mob_idx)
		for atk in player_attacks:
			var already_have = false
			for existing in _attacks:
				if existing.attack_name == atk.attack_name:
					already_have = true
					break
			if not already_have:
				_attacks.append(atk)
		_rebuild_attack_bar()
		_log("A new enemy joins the fight!")

	_rebuild_mob_cards()


func end_combat() -> void:
	combat_section.visible = false
	_active_mob_ids = []
	_attacks        = []
	_clear_children(mob_row)
	_clear_children(attack_bar)
	_log("")


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
		var card = MobCardScene.instantiate()
		mob_row.add_child(card)
		card.setup(mob_id, GameState.monsters[mob_id])
		card.mob_attacked.connect(_on_mob_attacked)
		card.mob_died.connect(_on_mob_died)


func _rebuild_attack_bar() -> void:
	if attack_bar == null:
		return
	_clear_children(attack_bar)
	for i in range(_attacks.size()):
		var atk: AttackData = _attacks[i]
		var btn             = Button.new()
		btn.icon             = atk.icon
		btn.text             = "%s\n(%d ⚡)" % [atk.attack_name, atk.energy_cost]
		btn.tooltip_text     = "Damage: %d  |  Energy: %d" % [atk.damage, atk.energy_cost]
		btn.custom_minimum_size = Vector2(80, 64)
		btn.toggle_mode      = true
		btn.button_pressed   = (i == _selected_attack)
		var idx = i
		btn.pressed.connect(func(): _select_attack(idx))
		attack_bar.add_child(btn)


func _select_attack(idx: int) -> void:
	_selected_attack = idx
	for i in range(attack_bar.get_child_count()):
		var btn = attack_bar.get_child(i) as Button
		if btn:
			btn.button_pressed = (i == idx)


func _on_mob_attacked(mob_id: int, base_dmg: int) -> void:
	if _attacks.is_empty():
		return

	var atk: AttackData = _attacks[_selected_attack]
	var p = GameState.player

	var mob = GameState.monsters[mob_id]
	mob["hp"] = max(0, mob.get("hp", 0) - (atk.damage - base_dmg))
	GameState.monsters[mob_id] = mob

	p["energy"] = max(0, p.get("energy", 0) - atk.energy_cost)
	GameState.player = p
	refresh_stats()

	GameState.mark_dirty()
	SaveManager.save()

	if mob["hp"] <= 0:
		return

	_do_mob_turn(mob_id)


func _on_mob_died(mob_id: int) -> void:
	var xp_gain = GameState.monsters[mob_id].get("xp_reward", 1)
	var p       = GameState.player
	p["xp"]     = p.get("xp", 0) + xp_gain
	if p["xp"] >= p.get("xp_to_next", 10):
		p["xp"]    -= p["xp_to_next"]
		p["level"]  = p.get("level", 1) + 1
		p["max_hp"] = p.get("max_hp", 10) + 1
		p["hp"]     = p["max_hp"]
		_log("Level up! Now level %d" % p["level"])
	GameState.player = p
	refresh_stats()

	_notify_tile_mob_dead(mob_id)

	GameState.monsters[mob_id]["hp"] = 0
	GameState.mark_dirty()
	SaveManager.save()

	_active_mob_ids.erase(mob_id)
	_rebuild_mob_cards()

	if _active_mob_ids.is_empty():
		end_combat()
		_check_all_mobs_cleared()
	else:
		_log("")


func _check_all_mobs_cleared() -> void:
	# All mobs are dead when every monster entry has hp <= 0.
	for monster in GameState.monsters:
		if monster.get("hp", 0) > 0:
			return
	# Signal the game node to spawn the exit door.
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

	var p       = GameState.player
	var damage  = atk.get("damage", 1)
	var effect  = atk.get("effect", 0)

	p["hp"] = max(0, p.get("hp", 0) - damage)

	var msg = "%s hits you for %d!" % [GameState.monsters[mob_id].get("name", "Mob"), damage]

	match effect:
		1:
			p["hp"] = max(0, p["hp"] - 1)
			msg += " Poisoned! (-1 extra)"
		2:
			_player_stunned = true
			msg += " You are stunned!"

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

	# get_nodes_in_group is sceneTree-wide, but SubViewport can isolate it.
	# Walk all scene trees to find the tile.
	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.grid_x == gx and tile.grid_y == gy:
			tile.on_mob_defeated()
			return

	# Fallback: SubViewport isolation — find game node directly.
	var game = get_tree().get_first_node_in_group("game")
	if game:
		for tile in game.get_children():
			if tile.get("grid_x") == gx and tile.get("grid_y") == gy:
				tile.on_mob_defeated()
				return

	# Last resort: update state only.
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
	prev_button.disabled = (_scroll_index == 0)
	next_button.disabled = (_scroll_index >= card_count - 1)

func _on_inventory_slot_clicked(index: int) -> void:
	var slot = InventoryState.hotbar[index]
	var item_key = slot.get("item_key", "")
	if slot.get("frozen", false) or item_key == "":
		return
	# Handle berries
	if item_key == "berries":
		var p = GameState.player
		p["hp"] = min(p.get("hp", 0) + 3, p.get("max_hp", 10))
		GameState.player = p
		InventoryState.set_hotbar_item(index, "")
		GameState.mark_dirty()
		SaveManager.save()
		refresh_stats()
		_log("You eat berries and restore 3 HP.")
