class_name MobView
extends VBoxContainer

## MobView — displays one mob at native sprite size with a fixed-size
## health bar above it. Clicking the sprite attacks the mob directly
## (no separate attack button). Bottom-alignment within the mob row is
## achieved via size_flags_vertical = SIZE_SHRINK_END (set below).

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

const HEALTH_BAR_SIZE: Vector2 = Vector2(56, 8)
const HP_BAR_FILL_COLOR: Color = Color(0.75, 0.2, 0.2)
const HP_BAR_BG_COLOR:   Color = Color(0.2, 0.2, 0.2)
const DEAD_MODULATE: Color = Color(0.4, 0.4, 0.4, 0.7)

var mob_id:   int        = -1
var mob_data: Dictionary = {}
var _mob_attacks: Array = []

@onready var name_label:   Label         = $NameLabel
@onready var resist_row:   HBoxContainer = $ResistRow
@onready var hp_bar:       ProgressBar   = $HPBar
@onready var sprite:       TextureRect   = $Sprite

const ELEMENT_DISPLAY: Dictionary = {
	"physical": "Physical", "fire": "Fire", "ice": "Ice",
}

const RESIST_ICON_SIZE: Vector2 = Vector2(1, 1)
const RESIST_ICONS: Dictionary = {
	"fire":     preload("res://assets/resistance/fire.png"),
	"ice":      preload("res://assets/resistance/ice.png"),
	"physical": preload("res://assets/resistance/physical.png"),
}
const RESIST_COLOR: Color = Color(0.55, 0.85, 0.4)   # resists → "+"
const WEAK_COLOR:   Color = Color(0.9, 0.35, 0.35)   # weak → "-"


func _ready() -> void:
	# Bottom-align this mob within MobRow regardless of its own height.
	size_flags_vertical = Control.SIZE_SHRINK_END

	hp_bar.custom_minimum_size   = HEALTH_BAR_SIZE
	hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hp_bar.show_percentage       = false
	_style_hp_bar()

	sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	sprite.gui_input.connect(_on_sprite_gui_input)


func setup(id: int, data: Dictionary) -> void:
	mob_id       = id
	mob_data     = data
	_mob_attacks = data.get("attacks", [])
	_refresh()


func refresh_from_state() -> void:
	mob_data     = GameState.monsters[mob_id]
	_mob_attacks = mob_data.get("attacks", [])
	_refresh()


func do_mob_turn() -> Dictionary:
	if _mob_attacks.is_empty():
		return {}
	return _mob_attacks[randi() % _mob_attacks.size()]


func _refresh() -> void:
	name_label.text = mob_data.get("name", "???")
	_refresh_resist_label()

	var sprite_key = mob_data.get("sprite", "")
	var tex: Texture2D = MOB_SPRITES.get(sprite_key, null)
	sprite.texture = tex
	if tex:
		sprite.custom_minimum_size = tex.get_size()

	var hp     = mob_data.get("hp",     1)
	var max_hp = mob_data.get("max_hp", hp)
	hp_bar.max_value = max(1, max_hp)
	hp_bar.value     = clampi(hp, 0, max_hp)

	sprite.modulate = DEAD_MODULATE if hp <= 0 else Color.WHITE


func _style_hp_bar() -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = HP_BAR_FILL_COLOR
	hp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = HP_BAR_BG_COLOR
	hp_bar.add_theme_stylebox_override("background", bg_style)


func _on_sprite_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mob_data.get("hp", 0) > 0:
			attack_requested.emit(mob_id)

func _refresh_resist_label() -> void:
	for child in resist_row.get_children():
		child.queue_free()

	var resistances: Dictionary = mob_data.get("resistances", {})
	var has_any := false

	for element in resistances:
		var mult: float = resistances[element]
		if mult == 1.0:
			continue
		has_any = true

		var icon_tex: Texture2D = RESIST_ICONS.get(element, null)
		if icon_tex:
			var icon := TextureRect.new()
			icon.texture             = icon_tex
			icon.custom_minimum_size = RESIST_ICON_SIZE
			icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			resist_row.add_child(icon)

		var sign_lbl := Label.new()
		sign_lbl.text = "+" if mult < 1.0 else "-"
		sign_lbl.add_theme_font_size_override("font_size", 18)
		sign_lbl.add_theme_color_override("font_color", RESIST_COLOR if mult < 1.0 else WEAK_COLOR)
		resist_row.add_child(sign_lbl)

	resist_row.visible = has_any
