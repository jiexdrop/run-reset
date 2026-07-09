class_name MobCard
extends PanelContainer

signal attack_requested(mob_id: int)
signal mob_died(mob_id: int)

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

var mob_id:   int        = -1
var mob_data: Dictionary = {}
var _mob_attacks: Array = []

@onready var mob_sprite:    TextureRect   = $VBoxContainer/MobSprite
@onready var name_label:    Label         = $VBoxContainer/NameLabel
@onready var hp_container:  HBoxContainer = $VBoxContainer/HPContainer
@onready var attack_button: Button        = $VBoxContainer/AttackButton


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
	if mob_data.get("hp", 0) <= 0:
		mob_died.emit(mob_id)


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
	_build_hearts(hp, max_hp)
	attack_button.disabled = (hp <= 0)


func _build_hearts(hp: int, max_hp: int) -> void:
	for child in hp_container.get_children():
		child.queue_free()
	for i in range(max_hp):
		var icon = TextureRect.new()
		icon.texture         = HP_FULL if i < hp else HP_EMPTY
		icon.custom_minimum_size = HP_ICON_SIZE
		icon.stretch_mode    = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_container.add_child(icon)


func _on_attack_pressed() -> void:
	attack_requested.emit(mob_id)
