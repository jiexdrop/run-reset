extends Node2D
class_name ShurikenEffect


## Time the shuriken takes to travel to its target. combat_ui waits this long
## before applying damage so the hit lands exactly on impact.
const FLIGHT_TIME := 0.25
const START_OFFSET := Vector2(0, 50)   # starts below the mob (the player side), like ArrowEffect


@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	z_index = 20
	_scale_sprite()
	_fly()


func _scale_sprite() -> void:
	if _sprite.texture == null:
		return
	var sz := _sprite.texture.get_size()
	var factor = 32.0 / max(sz.x, sz.y)
	_sprite.scale = Vector2.ONE * factor


func _fly() -> void:
	_sprite.position = START_OFFSET
	var tween := create_tween()
	tween.tween_property(_sprite, "position", Vector2.ZERO, FLIGHT_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_sprite, "rotation", TAU * 2.0, FLIGHT_TIME)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.06)\
		.set_delay(FLIGHT_TIME - 0.06)
	tween.parallel().tween_property(self, "scale", Vector2(0.6, 0.6), 0.06)\
		.set_delay(FLIGHT_TIME - 0.06)
	tween.tween_callback(queue_free)
