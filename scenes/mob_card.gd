class_name MobCard
extends PanelContainer

## MobCard — one enemy slot in the CombatUI.
##
## TO ADD A NEW MOB SPRITE
## ─────────────────────────
## Add an entry to MOB_SPRITES: "key" → preload("res://assets/mobs/key.png")
## The "sprite" field in the mob dictionary must match the key.

signal mob_attacked(mob_id: int, damage: int)
signal mob_died(mob_id: int)

# ── Sprite paths ──────────────────────────────────────────────────────────────
# Add more mobs here; key matches the "sprite" field in the mob dictionary.
const MOB_SPRITES: Dictionary = {
	"spider": preload("res://assets/mobs/spider.png"),
	"rat": preload("res://assets/mobs/rat.png"),
	"glaciarch": preload("res://assets/mobs/ribera/glaciarch.png"),
	"frozelin":  preload("res://assets/mobs/ribera/frozelin.png"),
	"gomelin":   preload("res://assets/mobs/pikoterra/gomelin.png"),
	"pikonaut":  preload("res://assets/mobs/pikoterra/pikonaut.png"), 
}

const HP_FULL      = preload("res://assets/ui/heart_full.png")
const HP_EMPTY     = preload("res://assets/ui/heart_empty.png")
const HP_ICON_SIZE = Vector2(16, 16)

# ── Internal state ────────────────────────────────────────────────────────────
var mob_id:   int        = -1
var mob_data: Dictionary = {}

# Parsed MobAttackData-equivalent dicts from mob_data["attacks"]
var _mob_attacks: Array = []

@onready var mob_sprite:    TextureRect   = $VBoxContainer/MobSprite
@onready var name_label:    Label         = $VBoxContainer/NameLabel
@onready var hp_container:  HBoxContainer = $VBoxContainer/HPContainer
@onready var attack_button: Button        = $VBoxContainer/AttackButton


# ── Public API ────────────────────────────────────────────────────────────────

## id   = index in GameState.monsters
## data = mob Dictionary: { name, hp, max_hp, sprite, attacks: [...], … }
func setup(id: int, data: Dictionary) -> void:
	mob_id      = id
	mob_data    = data
	_mob_attacks = data.get("attacks", [])
	_refresh()
	attack_button.pressed.connect(_on_attack_pressed)


func refresh_from_state() -> void:
	mob_data    = GameState.monsters[mob_id]
	_mob_attacks = mob_data.get("attacks", [])
	_refresh()


# ── Mob takes its turn (called by CombatUI after player acts) ─────────────────

## Returns the attack dict the mob used, or {} if no attacks defined.
func do_mob_turn() -> Dictionary:
	if _mob_attacks.is_empty():
		return {}
	# Pick a random attack
	var atk: Dictionary = _mob_attacks[randi() % _mob_attacks.size()]
	return atk


# ── Private ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	name_label.text = mob_data.get("name", "???")

	var sprite_key = mob_data.get("sprite", "")
	if MOB_SPRITES.has(sprite_key):
		mob_sprite.texture = MOB_SPRITES[sprite_key]

	var hp     = mob_data.get("hp",     1)
	var max_hp = mob_data.get("max_hp", hp)
	_build_hearts(hp, max_hp)
	attack_button.disabled = (hp <= 0)


func _build_hearts(hp: int, max_hp: int) -> void:
	for child in hp_container.get_children():
		child.queue_free()
	for i in range(max_hp):
		var icon             = TextureRect.new()
		icon.texture         = HP_FULL if i < hp else HP_EMPTY
		icon.custom_minimum_size = HP_ICON_SIZE
		icon.stretch_mode    = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_container.add_child(icon)


func _on_attack_pressed() -> void:
	# Player attacks the mob using player's attack stat.
	# CombatUI applies the selected AttackData's damage via _on_mob_attacked().
	var dmg       = GameState.player.get("attack", 1)
	mob_data["hp"] = max(0, mob_data.get("hp", 0) - dmg)
	GameState.monsters[mob_id] = mob_data
	GameState.mark_dirty()
	_refresh()
	mob_attacked.emit(mob_id, dmg)
	if mob_data["hp"] <= 0:
		mob_died.emit(mob_id)
