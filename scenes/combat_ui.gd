extends Control

## CombatUI — right-hand panel showing player stats and active combat.
##
## ── Wiring ──────────────────────────────────────────────────────────────────
## Call from game.gd (or wherever combat starts):
##
##   CombatUI.start_combat(monsters_subset, attacks)
##
## monsters_subset : Array of mob dictionaries (slice of GameState.monsters)
## attacks         : Array[AttackData]           (from attack_data.gd)
##
## ── Extending ───────────────────────────────────────────────────────────────
## • New mob type  → add its sprite key to mob_card.gd MOB_SPRITES
## • New attack    → create an AttackData resource and pass it in start_combat()
## • More hearts / energy / xp slots → just raise max_* in GameState.player

# ── Sprite assets ─────────────────────────────────────────────────────────────
const HEART_FULL  = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY = preload("res://assets/ui/heart_empty.png")
const ENERGY_FULL  = preload("res://assets/ui/energy_full.png")
const ENERGY_EMPTY = preload("res://assets/ui/energy_empty.png")
const EXP_FULL    = preload("res://assets/ui/exp_full.png")
const EXP_EMPTY   = preload("res://assets/ui/exp_empty.png")

const ICON_SIZE = Vector2(20, 20)

# ── Scene references ──────────────────────────────────────────────────────────
const MobCardScene = preload("res://scenes/mob_card.tscn")

# ── Nodes (assigned in _ready via $-paths; keep in sync with combat_ui.tscn) ─
@onready var level_label:     Label         = $MarginContainer/VBox/StatsSection/LevelLabel
@onready var hearts_row:      HBoxContainer = $MarginContainer/VBox/StatsSection/HeartsRow
@onready var energy_row:      HBoxContainer = $MarginContainer/VBox/StatsSection/EnergyRow
@onready var exp_row:         HBoxContainer = $MarginContainer/VBox/StatsSection/ExpRow
@onready var mob_row:         HBoxContainer = $MarginContainer/VBox/CombatSection/MobRow
@onready var attack_bar:      HBoxContainer = $MarginContainer/VBox/AttackBar
@onready var combat_section:  Control       = $MarginContainer/VBox/CombatSection

# ── Runtime state ─────────────────────────────────────────────────────────────
var _active_mob_ids: Array = []          # indices into GameState.monsters
var _attacks: Array        = []          # Array[AttackData]
var _selected_attack: int  = 0           # index into _attacks


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	refresh_stats()
	combat_section.visible = false       # hidden until start_combat()


# ── Public API ────────────────────────────────────────────────────────────────

## Refresh the player stats display from GameState.
func refresh_stats() -> void:
	var p = GameState.player
	level_label.text = "Level  %d" % p.get("level", 1)
	_build_icon_row(hearts_row, p.get("hp", 0),     p.get("max_hp", 10),     HEART_FULL,  HEART_EMPTY)
	_build_icon_row(energy_row, p.get("energy", 10), p.get("max_energy", 10), ENERGY_FULL, ENERGY_EMPTY)
	_build_icon_row(exp_row,    p.get("xp", 0),      p.get("xp_to_next", 10), EXP_FULL,    EXP_EMPTY)


## Show the combat panel with the given mobs and attack choices.
## mob_ids : Array[int] — indices into GameState.monsters
## attacks : Array[AttackData]
func start_combat(mob_ids: Array, attacks: Array) -> void:
	_active_mob_ids = mob_ids
	_attacks        = attacks
	_selected_attack = 0
	combat_section.visible = true
	_rebuild_mob_cards()
	_rebuild_attack_bar()


## Hide combat panel (call when all mobs are dead or combat ends).
func end_combat() -> void:
	combat_section.visible = false
	_active_mob_ids = []
	_clear_children(mob_row)
	_clear_children(attack_bar)


# ── Icon row builder ──────────────────────────────────────────────────────────

func _build_icon_row(row: HBoxContainer, current: int, maximum: int,
					  full_tex: Texture2D, empty_tex: Texture2D) -> void:
	_clear_children(row)
	for i in range(maximum):
		var icon = TextureRect.new()
		icon.texture          = full_tex if i < current else empty_tex
		icon.custom_minimum_size = ICON_SIZE
		icon.stretch_mode     = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
		var btn = Button.new()
		btn.icon             = atk.icon
		btn.text             = "%s\n(%d ⚡)" % [atk.attack_name, atk.energy_cost]
		btn.tooltip_text     = "Damage: %d  |  Energy: %d" % [atk.damage, atk.energy_cost]
		btn.custom_minimum_size = Vector2(80, 64)
		btn.toggle_mode      = true
		btn.button_pressed   = (i == _selected_attack)
		var idx = i          # capture for closure
		btn.pressed.connect(func(): _select_attack(idx))
		attack_bar.add_child(btn)


func _select_attack(idx: int) -> void:
	_selected_attack = idx
	# Update toggle visuals
	for i in range(attack_bar.get_child_count()):
		var btn = attack_bar.get_child(i) as Button
		if btn:
			btn.button_pressed = (i == idx)


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_mob_attacked(mob_id: int, _dmg: int) -> void:
	# Consume energy from selected attack
	if _attacks.is_empty():
		return
	var atk: AttackData = _attacks[_selected_attack]
	var p = GameState.player
	p["energy"] = max(0, p.get("energy", 0) - atk.energy_cost)
	GameState.player = p
	refresh_stats()
	SaveManager.save()


func _on_mob_died(mob_id: int) -> void:
	# Grant XP, handle level-up
	var xp_gain = GameState.monsters[mob_id].get("xp_reward", 1)
	var p = GameState.player
	p["xp"] = p.get("xp", 0) + xp_gain
	var xp_needed = p.get("xp_to_next", 10)
	if p["xp"] >= xp_needed:
		p["xp"]    -= xp_needed
		p["level"]  = p.get("level", 1) + 1
		# Optional: expand hearts/energy on level-up here
	GameState.player = p
	refresh_stats()

	# Remove dead mob card
	_active_mob_ids.erase(mob_id)
	_rebuild_mob_cards()

	if _active_mob_ids.is_empty():
		end_combat()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
