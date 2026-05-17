extends PanelContainer

## MobCard — one enemy slot in the CombatUI.
## Drop it into any HBoxContainer; call setup() to initialise.

signal mob_attacked(mob_id: int, damage: int)
signal mob_died(mob_id: int)

# ── Sprite paths ──────────────────────────────────────────────────────────────
# Add more mobs here; the key matches the "sprite" field on the mob dictionary.
const MOB_SPRITES: Dictionary = {
	"spider": preload("res://assets/mobs/spider.png"),
}

const HP_FULL  = preload("res://assets/ui/heart_full.png")
const HP_EMPTY = preload("res://assets/ui/heart_empty.png")
const HP_ICON_SIZE = Vector2(16, 16)

# ── Internal state ────────────────────────────────────────────────────────────
var mob_id:   int    = -1   # index into GameState.monsters
var mob_data: Dictionary = {}

@onready var mob_sprite:    TextureRect  = $VBoxContainer/MobSprite
@onready var name_label:    Label        = $VBoxContainer/NameLabel
@onready var hp_container:  HBoxContainer = $VBoxContainer/HPContainer
@onready var attack_button: Button       = $VBoxContainer/AttackButton


# ── Public API ────────────────────────────────────────────────────────────────

## Call this after instantiating the card.
## id  = index in GameState.monsters
## data = the mob Dictionary: { id, name, hp, max_hp, sprite, … }
func setup(id: int, data: Dictionary) -> void:
	mob_id   = id
	mob_data = data
	_refresh()
	attack_button.pressed.connect(_on_attack_pressed)


## Refresh visuals from mob_data (call after any hp change).
func refresh_from_state() -> void:
	mob_data = GameState.monsters[mob_id]
	_refresh()


# ── Private ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	name_label.text = mob_data.get("name", "???")

	# Sprite
	var sprite_key = mob_data.get("sprite", "")
	if MOB_SPRITES.has(sprite_key):
		mob_sprite.texture = MOB_SPRITES[sprite_key]

	# HP hearts (capped at max_hp, max_hp defaults to hp if absent)
	var hp     = mob_data.get("hp",     1)
	var max_hp = mob_data.get("max_hp", hp)
	_build_hearts(hp, max_hp)

	# Disable button if dead
	attack_button.disabled = (hp <= 0)


func _build_hearts(hp: int, max_hp: int) -> void:
	# Clear old icons
	for child in hp_container.get_children():
		child.queue_free()

	for i in range(max_hp):
		var icon        = TextureRect.new()
		icon.texture    = HP_FULL if i < hp else HP_EMPTY
		icon.custom_minimum_size = HP_ICON_SIZE
		icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_container.add_child(icon)


func _on_attack_pressed() -> void:
	# Default damage = player attack stat; CombatUI can override via signal.
	var dmg = GameState.player.get("attack", 1)
	mob_data["hp"] = max(0, mob_data.get("hp", 0) - dmg)
	GameState.monsters[mob_id] = mob_data
	GameState.mark_dirty()
	_refresh()
	mob_attacked.emit(mob_id, dmg)
	if mob_data["hp"] <= 0:
		mob_died.emit(mob_id)
