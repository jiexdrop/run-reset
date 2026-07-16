extends Node2D

func _ready() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property($Sprite2D, "scale", Vector2(1.4, 1.4), 0.5)
	tween.tween_callback(queue_free)
