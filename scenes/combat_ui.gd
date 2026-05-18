extends Control

## CombatUI — right-hand panel: player stats + active combat.
##
## PUBLIC API
## ──────────
##   start_combat(mob_ids, player_attacks, tile_key)
##     mob_ids        : Array[int]         — indices into GameState.monsters
##     player_attacks : Array[AttackData]  — player's available attacks
##     tile_key       : String             — "x,y" of the tile that triggered combat
##
##   end_combat()      — hide panel, reset state
##   refresh_stats()   — re-draw player hearts / energy / xp from GameState

# ── Assets ────────────────────────────────────────────────────────────────────
const HEART_FULL   = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY  = preload("res://assets/ui/heart_empty.png")
const ENERGY_FULL  = preload("res://assets/ui/energy_full.png")
const ENERGY_EMPTY = preload("res://assets/ui/energy_empty.png")
const EXP_FULL     = preload("res://assets/ui/exp_full.png")
const EXP_EMPTY    = preload("res://assets/ui/exp_empty.png")

const ICON_SIZE = Vector2(20, 20)

const MobCardScene = preload("res://scenes/mob_card.tscn")

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var level_label:    Label         = $MarginContainer/VBox/StatsSection/LevelLabel
@onready var hearts_row:     HBoxContainer = $MarginContainer/VBox/StatsSection/HeartsRow
@onready var energy_row:     HBoxContainer = $MarginContainer/VBox/StatsSection/EnergyRow
@onready var exp_row:        HBoxContainer = $MarginContainer/VBox/StatsSection/ExpRow
@onready var mob_row:        HBoxContainer = $MarginContainer/VBox/CombatSection/MobRow
@onready var attack_bar:     HBoxContainer = $MarginContainer/VBox/AttackBar
@onready var combat_section: Control       = $MarginContainer/VBox/CombatSection
@onready var log_label:      Label         = $MarginContainer/VBox/LogLabel   # see note below

# ── Runtime state ─────────────────────────────────────────────────────────────
var _active_mob_ids:   Array  = []
var _attacks:          Array  = []   # Array[AttackData]
var _selected_attack:  int    = 0
var _tile_key:         String = ""   # tile that started this combat

# Effects that carry across turns
var _player_stunned:   bool   = false


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("combat_ui")
	refresh_stats()
	combat_section.visible = false


# ── Public API ────────────────────────────────────────────────────────────────

func refresh_stats() -> void:
	var p = GameState.player
	level_label.text = "Level  %d" % p.get("level", 1)
	_build_icon_row(hearts_row, p.get("hp", 0),      p.get("max_hp", 10),     HEART_FULL,  HEART_EMPTY)
	_build_icon_row(energy_row, p.get("energy", 10),  p.get("max_energy", 10), ENERGY_FULL, ENERGY_EMPTY)
	_build_icon_row(exp_row,    p.get("xp", 0),       p.get("xp_to_next", 10), EXP_FULL,    EXP_EMPTY)


## tile_key: "x,y" string so we can notify the tile when the mob dies.
func start_combat(mob_ids: Array, player_attacks: Array, tile_key: String = "") -> void:
	_active_mob_ids  = mob_ids.duplicate()
	_attacks         = player_attacks
	_selected_attack = 0
	_tile_key        = tile_key
	_player_stunned  = false
	combat_section.visible = true
	_rebuild_mob_cards()
	_rebuild_attack_bar()
	_log("")


func end_combat() -> void:
	combat_section.visible = false
	_active_mob_ids = []
	_clear_children(mob_row)
	_clear_children(attack_bar)
	_log("")


# ── Icon row builder ──────────────────────────────────────────────────────────

func _build_icon_row(row: HBoxContainer, current: int, maximum: int,
					  full_tex: Texture2D, empty_tex: Texture2D) -> void:
	_clear_children(row)
	for i in range(maximum):
		var icon = TextureRect.new()
		icon.texture             = full_tex if i < current else empty_tex
		icon.custom_minimum_size = ICON_SIZE
		icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)


# ── Mob cards ─────────────────────────────────────────────────────────────────

func _rebuild_mob_cards() -> void:
	_clear_children(mob_row)
	for mob_id in _active_mob_ids:
		if mob_id >= GameState.monsters.size():
			continue
		var card = MobCardScene.instantiate()
		mob_row.add_child(card)
		card.setup(mob_id, GameState.monsters[mob_id])
		card.mob_attacked.connect(_on_mob_attacked)
		card.mob_died.connect(_on_mob_died)


# ── Attack bar ────────────────────────────────────────────────────────────────

func _rebuild_attack_bar() -> void:
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


# ── Signal handlers ───────────────────────────────────────────────────────────

## Player just hit a mob — apply selected attack's energy cost, then mob retaliates.
func _on_mob_attacked(mob_id: int, base_dmg: int) -> void:
	if _attacks.is_empty():
		return

	# 1. Apply selected attack's actual damage (overrides base_dmg from card)
	var atk: AttackData = _attacks[_selected_attack]
	var p = GameState.player

	# Reapply correct damage (mob_card used player.attack; use atk.damage instead)
	var mob = GameState.monsters[mob_id]
	mob["hp"] = max(0, mob.get("hp", 0) - (atk.damage - base_dmg))   # adjust delta
	GameState.monsters[mob_id] = mob

	# 2. Consume energy
	p["energy"] = max(0, p.get("energy", 0) - atk.energy_cost)
	GameState.player = p
	refresh_stats()

	# 3. Check if mob died from the corrected damage
	if mob["hp"] <= 0:
		return   # mob_died signal will fire from mob_card; don't do mob turn

	# 4. Mob retaliates (unless already handled by mob_died)
	_do_mob_turn(mob_id)


func _on_mob_died(mob_id: int) -> void:
	# Grant XP and handle level-up
	var xp_gain = GameState.monsters[mob_id].get("xp_reward", 1)
	var p       = GameState.player
	p["xp"]     = p.get("xp", 0) + xp_gain
	if p["xp"] >= p.get("xp_to_next", 10):
		p["xp"]    -= p["xp_to_next"]
		p["level"]  = p.get("level", 1) + 1
		p["max_hp"] = p.get("max_hp", 10) + 1   # level-up bonus: +1 heart
		p["hp"]     = p["max_hp"]                 # full heal on level-up
		_log("Level up! Now level %d" % p["level"])
	GameState.player = p
	refresh_stats()

	# Notify the tile so it removes the mob indicator
	_notify_tile_mob_dead(mob_id)

	_active_mob_ids.erase(mob_id)
	_rebuild_mob_cards()

	if _active_mob_ids.is_empty():
		end_combat()
	else:
		_log("")


# ── Mob turn ──────────────────────────────────────────────────────────────────

func _do_mob_turn(mob_id: int) -> void:
	if _player_stunned:
		_player_stunned = false
		_log("You were stunned — mob skips!")
		return

	# Find the mob card node for this id
	var card = _get_card_for_mob(mob_id)
	if card == null:
		return

	var atk: Dictionary = card.do_mob_turn()
	if atk.is_empty():
		return

	var p       = GameState.player
	var damage  = atk.get("damage", 1)
	var effect  = atk.get("effect", 0)   # MobAttackData.Effect int

	p["hp"] = max(0, p.get("hp", 0) - damage)

	var msg = "%s hits you for %d!" % [GameState.monsters[mob_id].get("name","Mob"), damage]

	# Handle effects
	match effect:
		1:   # POISON — deal 1 extra damage next turn (simple impl)
			p["hp"] = max(0, p["hp"] - 1)
			msg += " Poisoned! (-1 extra)"
		2:   # STUN
			_player_stunned = true
			msg += " You are stunned!"

	GameState.player = p
	GameState.mark_dirty()
	refresh_stats()
	_log(msg)

	if p["hp"] <= 0:
		_on_player_died()


func _on_player_died() -> void:
	_log("You died! Resetting...")
	# Small delay so the player reads the message, then reset
	await get_tree().create_timer(1.5).timeout
	SaveManager.reset()
	get_tree().change_scene_to_file("res://scenes/init.tscn")


# ── Tile notification ─────────────────────────────────────────────────────────

func _notify_tile_mob_dead(mob_id: int) -> void:
	var tile_key = GameState.monsters[mob_id].get("tile_key", "")
	if tile_key == "":
		return
	var parts = tile_key.split(",")
	if parts.size() < 2:
		return
	var gx = parts[0].to_int()
	var gy = parts[1].to_int()

	# Tiles live inside a SubViewport so get_nodes_in_group won't find them.
	# Walk down to the Game node and search its children directly.
	var game = get_tree().root.find_child("Game", true, false)
	if game == null:
		push_warning("_notify_tile_mob_dead: could not find Game node")
		return
	for tile in game.get_children():
		if tile.get("grid_x") == gx and tile.get("grid_y") == gy:
			tile.on_mob_defeated()
			return

	# Fallback
	if GameState.tiles.has(tile_key):
		GameState.tiles[tile_key]["mob_dead"] = true


# ── Helpers ───────────────────────────────────────────────────────────────────

func _get_card_for_mob(mob_id: int) -> Node:
	for card in mob_row.get_children():
		if card.mob_id == mob_id:
			return card
	return null


func _log(msg: String) -> void:
	if log_label:
		log_label.text = msg


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
