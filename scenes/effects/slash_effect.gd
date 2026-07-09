extends Node2D

func _ready() -> void:
	modulate.a = 0.9
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property($Polygon2D, "scale", Vector2(1.3, 1.3), 0.3)
	tween.tween_callback(queue_free)
