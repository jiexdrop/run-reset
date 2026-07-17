class_name MobCard
extends PanelContainer

signal attack_requested(mob_id: int)
signal mob_died(mob_id: int)

const MOB_SPRITES: Dictionary = {
	"spider": preload("res://assets/mobs/spider.png"),
	"rat": preload("res://assets/mobs/rat.png"),
	"glaciarch":    preload("res://assets/mobs/ribera/glaciarch.png"),
	"frozelin":     preload("res://assets/mobs/ribera/frozelin.png"),
	"gomelin":      preload("res://assets/mobs/pikoterra/gomelin.png"),
	"pikonaut":     preload("res://assets/mobs/pikoterra/pikonaut.png"),
	"kaze_shroom":  preload("res://assets/mobs/evergreen/kaze_shroom.png"),
	"sapguard":     preload("res://assets/mobs/evergreen/sapguard.png"),
}

const HP_BAR_FILL_COLOR: Color = Color(0.75, 0.2, 0.2)
const HP_BAR_BG_COLOR:   Color = Color(0.2, 0.2, 0.2)

var mob_id:   int        = -1
var mob_data: Dictionary = {}
var _mob_attacks: Array = []

@onready var mob_sprite:    TextureRect   = $VBoxContainer/MobSprite
@onready var name_label:    Label         = $VBoxContainer/NameLabel
@onready var hp_bar:        ProgressBar   = $VBoxContainer/HPBar
@onready var attack_button: Button        = $VBoxContainer/AttackButton


func setup(id: int, data: Dictionary) -> void:
	mob_id      = id
	mob_data    = data
	_mob_attacks = data.get("attacks", [])
	_style_hp_bar()
	_refresh()
	attack_button.pressed.connect(_on_attack_pressed)


func refresh_from_state() -> void:
	mob_data    = GameState.monsters[mob_id]
	_mob_attacks = mob_data.get("attacks", [])
	_refresh()


func do_mob_turn() -> Dictionary:
	if _mob_attacks.is_empty():
		return {}
	return _mob_attacks[randi() % _mob_attacks.size()]


func _refresh() -> void:
	name_label.text = mob_data.get("name", "???")
	var sprite_key = mob_data.get("sprite", "")
	if MOB_SPRITES.has(sprite_key):
		mob_sprite.texture = MOB_SPRITES[sprite_key]
	var hp     = mob_data.get("hp",     1)
	var max_hp = mob_data.get("max_hp", hp)
	_update_hp_bar(hp, max_hp)
	attack_button.disabled = (hp <= 0)


func _style_hp_bar() -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = HP_BAR_FILL_COLOR
	hp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = HP_BAR_BG_COLOR
	hp_bar.add_theme_stylebox_override("background", bg_style)


func _update_hp_bar(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max(1, max_hp)
	hp_bar.value     = clampi(hp, 0, max_hp)


func _on_attack_pressed() -> void:
	attack_requested.emit(mob_id)
