extends Control

const HEART_FULL   = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY  = preload("res://assets/ui/heart_empty.png")
const ENERGY_FULL  = preload("res://assets/ui/energy_full.png")
const ENERGY_EMPTY = preload("res://assets/ui/energy_empty.png")
const EXP_FULL     = preload("res://assets/ui/exp_full.png")
const EXP_EMPTY    = preload("res://assets/ui/exp_empty.png")
const POISON_ICON        = preload("res://assets/ui/poison.png")
const FROZEN_ICON        = preload("res://assets/ui/frozen.png")
const HEART_FULL_POISON  = preload("res://assets/ui/heart_full_poison.png")
const HEART_EMPTY_POISON = preload("res://assets/ui/heart_empty_poison.png")

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

@onready var level_label:      Label           = $MarginContainer/ContentArea/VBox/StatsSection/LevelLabel
@onready var hearts_grid:      GridContainer   = $MarginContainer/ContentArea/VBox/StatsSection/HeartsGrid
@onready var energy_grid:      GridContainer   = $MarginContainer/ContentArea/VBox/StatsSection/EnergyGrid
@onready var exp_row:          HBoxContainer   = $MarginContainer/ContentArea/VBox/StatsSection/ExpRow
@onready var mob_scroll:       ScrollContainer = $MarginContainer/ContentArea/VBox/CombatSection/MobCarousel/MobScroll
@onready var mob_row:          HBoxContainer   = $MarginContainer/ContentArea/VBox/CombatSection/MobCarousel/MobScroll/MobRow
@onready var attack_bar:       HFlowContainer  = $MarginContainer/ContentArea/VBox/AttackBar
@onready var combat_section:   Control         = $MarginContainer/ContentArea/VBox/CombatSection
@onready var log_label:        Label           = $MarginContainer/ContentArea/VBox/LogLabel
@onready var inv_ui:           Control         = $MarginContainer/ContentArea/InventoryUI
@onready var effect_badge:     Control         = $MarginContainer/ContentArea/VBox/StatsSection/EffectBadge
@onready var effect_icon:      TextureRect     = $MarginContainer/ContentArea/VBox/StatsSection/EffectBadge/Icon
@onready var effect_label:     Label           = $MarginContainer/ContentArea/VBox/StatsSection/EffectBadge/Label
@onready var pass_turn_button: Button          = $MarginContainer/ContentArea/VBox/CombatSection/PassTurnButton

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
var _telegraphed: Dictionary = {}  # mob_id -> attack selected for its next turn
var _shielded_this_turn: bool = false
var _pending_bombs: Dictionary = {}   # mob_id -> pending damage
var _exploded: Dictionary = {}

func _ready() -> void:
	add_to_group("combat_ui")
	refresh_stats()
	pass_turn_button.disabled = true
	if inv_ui:
		inv_ui.slot_clicked.connect(_on_inventory_slot_clicked)
		inv_ui.bag_opened.connect(_on_bag_opened)
	InventoryState.inventory_changed.connect(_rebuild_attack_bar)
	_rebuild_attack_bar()


func refresh_stats() -> void:
	var p = GameState.player
	var poisoned = p.get("poison_turns", 0) > 0

	level_label.text = "Level  %d" % p.get("level", 1)

	var heart_full  = HEART_FULL_POISON  if poisoned else HEART_FULL
	var heart_empty = HEART_EMPTY_POISON if poisoned else HEART_EMPTY
	_build_icon_grid(hearts_grid, p.get("hp", 0),      p.get("max_hp", 10),     heart_full,  heart_empty)
	_build_icon_grid(energy_grid, p.get("energy", 10),  p.get("max_energy", 10), ENERGY_FULL, ENERGY_EMPTY)
	_build_icon_row(exp_row,    p.get("xp", 0),       p.get("xp_to_next", 10), EXP_FULL,    EXP_EMPTY)

	_update_effect_badge(p)


func _update_effect_badge(p: Dictionary) -> void:
	var frozen_turns = p.get("frozen_turns", 0)
	var poison_turns = p.get("poison_turns", 0)
	effect_badge.visible = frozen_turns > 0 or poison_turns > 0
	if frozen_turns > 0:
		effect_icon.texture = FROZEN_ICON
		effect_label.text = "FRZ x%d" % frozen_turns
	elif poison_turns > 0:
		effect_icon.texture = POISON_ICON
		effect_label.text = "PSN x%d" % poison_turns
		

func add_mob_to_combat(mob_idx: int) -> void:
	if _active_mob_ids.has(mob_idx):
		return
	if _active_mob_ids.is_empty():
		_active_mob_ids  = [mob_idx]
		_player_stunned  = false
		_log("")
	else:
		_active_mob_ids.append(mob_idx)
		_log("A new enemy joins the fight!")
	_skip_next_turn[mob_idx] = true
	pass_turn_button.disabled = false
	_rebuild_mob_cards()


func end_combat() -> void:
	pass_turn_button.disabled = true
	_active_mob_ids = []
	_skip_next_turn.clear()
	_telegraphed.clear()
	_shielded_this_turn = false
	_pending_bombs.clear()
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
		mob_view.set_telegraphed(_telegraphed.has(mob_id))
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

	var shield_idx := InventoryState.equipped_shield_index
	if shield_idx >= 0 and shield_idx < InventoryState.hotbar.size():
		var shield_key: String = InventoryState.hotbar[shield_idx].get("item_key", "")
		if ItemRegistry.get_type(shield_key) == "shield":
			var shield_button := Button.new()
			shield_button.text = "Shield"
			shield_button.icon = ItemRegistry.get_icon(shield_key)
			shield_button.tooltip_text = "Block the next telegraphed attack this turn."
			shield_button.pressed.connect(_on_shield_pressed)
			attack_bar.add_child(shield_button)


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
	
	if atk.attack_type == "bomb_throw":
		_throw_bomb(mob_id, atk)
		return

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

	# Burrow check — if the mob just hit can burrow, send it underground and
	# make it skip its next turn opportunity.
	var mob = GameState.monsters[mob_id]
	if mob.get("hp", 0) > 0:
		var def = MobRegistry.get_def(mob.get("mob_key", ""))
		if def and def.burrows:
			mob["burrowed"] = true
			_skip_next_turn[mob_id] = true
			GameState.monsters[mob_id] = mob
			var burrow_card = _get_card_for_mob(mob_id)
			if burrow_card:
				burrow_card.refresh_from_state()

	if atk.is_spell and atk.hotbar_index >= 0:
		InventoryState.consume_hotbar_item(atk.hotbar_index)

	GameState.mark_dirty()
	SaveManager.save()

	mob = GameState.monsters[mob_id]
	if mob.get("hp", 0) <= 0:
		_on_mob_died(mob_id)
	elif mob.get("burrowed", false):
		pass   # underground — sits out this attack; _run_mob_turn_sequence
			   # (triggered by the player's next move) will consume _skip_next_turn
			   # and resurface it there, exactly once
	elif _skip_next_turn.get(mob_id, false):
		_skip_next_turn.erase(mob_id)
	else:
		_do_mob_turn(mob_id)
		_resolve_pending_bomb(mob_id)

func _throw_bomb(mob_id: int, atk: Dictionary) -> void:
	var target_mob = GameState.monsters[mob_id]
	var resistances = target_mob.get("resistances", {})
	var atk_element = ItemRegistry.get_element(atk.item_key)
	var resist_mult  = resistances.get(atk_element, 1.0)
	var dmg = max(1, int(round(atk.damage * resist_mult)))

	_pending_bombs[mob_id] = _pending_bombs.get(mob_id, 0) + dmg

	if atk.hotbar_index >= 0:
		InventoryState.consume_hotbar_item(atk.hotbar_index)

	_log("You lob a bomb and step back — fuse burning...")
	GameState.mark_dirty()
	SaveManager.save()
	# Deliberately no _do_mob_turn call here — that's the whole point of the
	# quirk: the mob gets its next turn opportunity for free, then the bomb
	# goes off once that turn resolves (see _resolve_pending_bomb).

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


func _on_mob_died(mob_id: int, explosion_msg: String = "") -> void:
	var xp_gain = GameState.monsters[mob_id].get("xp_reward", 1)
	var p       = GameState.player
	p["xp"]     = p.get("xp", 0) + xp_gain
	if p["xp"] >= p.get("xp_to_next", 10):
		p["xp"]    -= p["xp_to_next"]
		p["level"]  = p.get("level", 1) + 1
		_log("Level up! Now level %d" % p["level"])
	GameState.player = p
	refresh_stats()

	# If the mob just self-destructed on its own turn, the explosion damage
	# was already applied there — reuse that message instead of applying
	# the damage a second time via _apply_death_explosion.
	var explode_msg = explosion_msg if explosion_msg != "" else _apply_death_explosion(mob_id)
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
	_telegraphed.erase(mob_id)
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
	print(">>> _do_mob_turn START, mob_id=", mob_id)
	if _player_stunned:
		_player_stunned = false
		_log("You were stunned — mob skips!")
		return

	var card = _get_card_for_mob(mob_id)
	if card == null:
		return

	if not _telegraphed.has(mob_id):
		var selected_atk: Dictionary = card.do_mob_turn()
		if selected_atk.is_empty():
			return
		_telegraphed[mob_id] = selected_atk
		card.set_telegraphed(true)
		_log("%s is telegraphing an attack!" % GameState.monsters[mob_id].get("name", "Mob"))
		return

	var atk: Dictionary = _telegraphed[mob_id]
	_telegraphed.erase(mob_id)
	card.set_telegraphed(false)
	if _shielded_this_turn:
		_shielded_this_turn = false  # v1: blocks only the first resolving mob
		await _play_attack_lunge(card)
		if not is_inside_tree():
			return
		_spawn_mob_attack_effect(mob_id, atk.get("attack_name", ""))
		_show_block_feedback(mob_id, atk.get("attack_name", ""), card)

		var blocked_name: String = GameState.monsters[mob_id].get("name", "Mob")
		var blocked_attack: String = atk.get("attack_name", "attack")
		if SELF_DESTRUCT_ATTACKS.get(blocked_attack, false):
			# A self-destruct still consumes the monster.  The shield prevents
			# damage, but it must not cancel the explosion or leave the mob alive.
			await _self_destruct_mob(
				mob_id,
				"%s explodes harmlessly against your shield!" % blocked_name
			)
		else:
			_log("Blocked %s's %s!" % [blocked_name, blocked_attack])
		return

	print("Mob turn picked: ", atk.get("attack_name", "?")) 

	await _play_attack_lunge(card)
	print(">>> resumed after lunge, mob_id=", mob_id)
	if not is_inside_tree():
		print("_do_mob_turn bailed: not inside tree")
		return

	_spawn_mob_attack_effect(mob_id, atk.get("attack_name", ""))

	var p      = GameState.player
	var damage = atk.get("damage", 1)
	var effect = atk.get("effect", 0)
	#print("DEBUG atk=", atk, " effect=", effect, " typeof=", typeof(effect))

	p["hp"] = max(0, p.get("hp", 0) - damage)
	var msg = "%s hits you for %d!" % [GameState.monsters[mob_id].get("name", "Mob"), damage]

	var atk_name: String = atk.get("attack_name", "")
	var is_self_destruct: bool = SELF_DESTRUCT_ATTACKS.get(atk_name, false)

	match int(effect):
		MobAttackData.Effect.POISON:
			msg += _apply_poison_status(p)
		MobAttackData.Effect.STUN:
			_player_stunned = true
			msg += " You are stunned!"
		MobAttackData.Effect.STEAL:
			var stolen = _steal_random_item()
			if stolen != "":
				msg += " Gomelin steals your %s!" % ItemRegistry.get_item_name(stolen)
		MobAttackData.Effect.FREEZE:
			msg += _apply_freeze_status(p)

	# Poison ticks down once per mob turn — but not on the turn it was just
	# applied/refreshed, so a fresh poison always lasts its full 3-5 turns.
	if effect != MobAttackData.Effect.POISON and p.get("poison_turns", 0) > 0:
		p["poison_turns"] = max(0, p["poison_turns"] - 1)
		if p["poison_turns"] == 0:
			msg += " Poison wears off."
	if effect != MobAttackData.Effect.FREEZE and p.get("frozen_turns", 0) > 0:
		p["frozen_turns"] = max(0, p["frozen_turns"] - 1)
		if p["frozen_turns"] == 0:
			InventoryState.thaw_all_slots()
			msg += " Your inventory thaws."

	GameState.player = p
	GameState.mark_dirty()
	SaveManager.save()
	refresh_stats()
	_log(msg)

	if p["hp"] <= 0:
		_on_player_died()
		return

	# Self-destruct attacks (e.g. Kaze Shroom's Explode) kill the mob itself
	# when used on its own turn, mirroring the death-explosion that already
	# happens when the mob is killed by the player/a bomb.
	if is_self_destruct:
		await _self_destruct_mob(
			mob_id,
			"%s explodes for %d damage!" % [GameState.monsters[mob_id].get("name", "Mob"), damage]
		)

## Kills a mob that self-destructed as part of its own turn (e.g. Kaze
## Shroom's Explode) and routes it through the normal death flow — grey
## fade, XP, loot, tile update — without re-applying its explosion damage.
## This also covers a shielded explosion, whose damage was prevented.
func _self_destruct_mob(mob_id: int, explosion_msg: String) -> void:
	if mob_id >= GameState.monsters.size():
		return
	var mob = GameState.monsters[mob_id]
	if mob.get("hp", 0) <= 0:
		return   # already dead — avoid double death handling

	mob["hp"] = 0
	GameState.monsters[mob_id] = mob

	var card = _get_card_for_mob(mob_id)
	if card:
		card.refresh_from_state()   # grey fade fires immediately, same as other mobs

	_exploded[mob_id] = true  # death flow must not apply the explosion twice
	await _on_mob_died(mob_id, explosion_msg)

## Applies the poison status. First application just starts the timer with
## no damage. Getting poisoned again while already poisoned costs a heart
## and refreshes the duration — an incentive to clear it or avoid repeat hits.
func _apply_poison_status(p: Dictionary) -> String:
	var already_poisoned = p.get("poison_turns", 0) > 0
	p["poison_turns"] = randi_range(3, 5)
	if already_poisoned:
		p["hp"] = max(0, p.get("hp", 0) - 1)
		return " Poison flares up! (-1 heart)"
	return " You are poisoned!"


## Freeze lasts exactly five subsequent mob turns. Repeated applications
## refresh the duration and lock one more inventory slot, up to three slots.
func _apply_freeze_status(p: Dictionary) -> String:
	print("_apply_freeze_status called, frozen_turns before: ", p.get("frozen_turns", 0))
	var already_frozen = p.get("frozen_turns", 0) > 0
	p["frozen_turns"] = 5
	var froze_slot = InventoryState.freeze_random_slot(3)

	var msg := ""
	if froze_slot:
		msg = " Your inventory freezes!" if not already_frozen else " Another inventory slot freezes!"
	else:
		msg = " You are frozen!"

	if already_frozen:
		p["hp"] = max(0, p.get("hp", 0) - 1)
		msg += " (-1 heart)"

	return msg
	
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

	if item_type == "shield":
		InventoryState.equip_shield(index)
		var equipped_shield = InventoryState.equipped_shield_index == index
		_log("Shield %s." % ["equipped" if equipped_shield else "unequipped"])
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
	inv_ui.set_drag_enabled(true)


func _on_bag_closed() -> void:
	_bag_ui = null
	inv_ui.set_drag_enabled(false)

func _steal_random_item() -> String:
	var candidates: Array = []
	for i in range(InventoryState.HOTBAR_SIZE):
		if i == InventoryState.equipped_index:
			continue
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


## Shows the outcome where the action happened, rather than leaving the
## player to infer a successful block from the combat log alone.
func _show_block_feedback(mob_id: int, attack_name: String, card: Control) -> void:
	if card == null or not is_instance_valid(card):
		return

	var mob_name: String = GameState.monsters[mob_id].get("name", "Mob")
	var feedback := Label.new()
	feedback.text = "SHIELD BLOCK!\n%s's %s" % [mob_name, attack_name]
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 15)
	feedback.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.z_index = 20

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.06, 0.18, 0.33, 0.94)
	panel.border_color = Color(0.42, 0.79, 1.0, 1.0)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(6)
	panel.content_margin_left = 8
	panel.content_margin_right = 8
	panel.content_margin_top = 4
	panel.content_margin_bottom = 4
	feedback.add_theme_stylebox_override("normal", panel)

	add_child(feedback)
	feedback.size = feedback.get_combined_minimum_size()
	feedback.position = card.get_global_rect().get_center() - global_position - feedback.size / 2.0

	var start_position := feedback.position
	feedback.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feedback, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(feedback, "position:y", start_position.y - 16.0, 0.55)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.25)
	tween.tween_callback(feedback.queue_free)

## If the dying mob has a self-destruct attack (e.g. Kaze Shroom's Explode),
## apply its damage to the player and play its effect, even though the mob
## never got to take its normal turn.
func _apply_death_explosion(mob_id: int) -> String:
	if _exploded.get(mob_id, false):
		return ""
	var attacks: Array = GameState.monsters[mob_id].get("attacks", [])
	for atk in attacks:
		var atk_name: String = atk.get("attack_name", "")
		if SELF_DESTRUCT_ATTACKS.get(atk_name, false):
			_exploded[mob_id] = true
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

func on_player_moved(shielded: bool = false) -> void:
	if _mob_turns_running or _attack_in_progress:
		return
	if _active_mob_ids.is_empty():
		return
	_run_mob_turn_sequence(shielded)


func _run_mob_turn_sequence(shielded: bool = false) -> void:
	_shielded_this_turn = shielded
	_mob_turns_running = true
	for mob_id in _active_mob_ids.duplicate():
		if not _active_mob_ids.has(mob_id):
			continue
		if mob_id >= GameState.monsters.size():
			continue
		if GameState.monsters[mob_id].get("hp", 0) <= 0:
			continue

		if _skip_next_turn.get(mob_id, false):
			_skip_next_turn.erase(mob_id)
			if GameState.monsters[mob_id].get("burrowed", false):
				GameState.monsters[mob_id]["burrowed"] = false
				var seq_card = _get_card_for_mob(mob_id)
				if seq_card:
					seq_card.refresh_from_state()
			_resolve_pending_bomb(mob_id)
			continue
			
		await _do_mob_turn(mob_id)
		
		_resolve_pending_bomb(mob_id)

		if not is_inside_tree():
			_mob_turns_running = false
			return
		if GameState.player.get("hp", 0) <= 0:
			_mob_turns_running = false
			return

		await get_tree().create_timer(MOVE_TURN_DELAY).timeout
	_mob_turns_running = false
	_shielded_this_turn = false

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
	if not is_instance_valid(card):
		return

func _on_pass_turn_pressed(shielded: bool = false) -> void:
	if _active_mob_ids.is_empty():
		return
	on_player_moved(shielded)


func _on_shield_pressed() -> void:
	if _active_mob_ids.is_empty() or _mob_turns_running:
		return
	_shielded_this_turn = true
	_log("Shield raised — the next telegraphed attack will be blocked.")
	_on_pass_turn_pressed(true)

func _resolve_pending_bomb(mob_id: int) -> void:
	if not _pending_bombs.has(mob_id):
		return
	var dmg = _pending_bombs[mob_id]
	_pending_bombs.erase(mob_id)

	if mob_id >= GameState.monsters.size():
		return
	var mob = GameState.monsters[mob_id]
	if mob.get("hp", 0) <= 0:
		return

	mob["hp"] = max(0, mob.get("hp", 0) - dmg)
	GameState.monsters[mob_id] = mob

	_spawn_attack_effect(mob_id, ItemRegistry.get_attack_type_data("bomb_throw"))
	var card = _get_card_for_mob(mob_id)
	if card:
		card.refresh_from_state()

	_log("The bomb goes off — %s takes %d damage!" % [mob.get("name", "Mob"), dmg])
	GameState.mark_dirty()
	SaveManager.save()

	if mob["hp"] <= 0:
		_on_mob_died(mob_id)
