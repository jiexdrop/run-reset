extends Node2D
class_name ArrowEffect


## Time the arrow takes to travel to its target. combat_ui waits this long
## before applying damage so the hit lands exactly on impact.
const FLIGHT_TIME := 0.18
const START_OFFSET := Vector2(0, 50)   # arrow starts below the mob (the player side); kept
									   # short so it spawns inside MobScroll's clipped area


const SHAFT_COLOR := Color(0.55, 0.38, 0.2)
const HEAD_COLOR  := Color(0.85, 0.87, 0.9)
const FLETCH_COLOR := Color(0.9, 0.9, 0.85)


var _arrow: Node2D
var _trail: Line2D




func _ready() -> void:
	z_index = 20
	_build_arrow()
	_fly()




func _build_arrow() -> void:
	# Trail (behind the arrow, fades as it flies)
	_trail = Line2D.new()
	_trail.width = 3.0
	_trail.points = PackedVector2Array([Vector2(0, 0), Vector2(0, 40)])
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.55))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	_trail.gradient = grad
	add_child(_trail)


	# Arrow origin is the tip, pointing up (-Y).
	_arrow = Node2D.new()
	add_child(_arrow)


	var shaft := Line2D.new()
	shaft.width = 2.0
	shaft.default_color = SHAFT_COLOR
	shaft.points = PackedVector2Array([Vector2(0, 6), Vector2(0, 30)])
	_arrow.add_child(shaft)


	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([Vector2(0, -4), Vector2(-4, 8), Vector2(0, 5), Vector2(4, 8)])
	head.color = HEAD_COLOR
	_arrow.add_child(head)


	for side in [-1, 1]:
		var fletch := Polygon2D.new()
		fletch.polygon = PackedVector2Array([
			Vector2(0, 24), Vector2(side * 5, 32), Vector2(side * 5, 36), Vector2(0, 30)])
		fletch.color = FLETCH_COLOR
		_arrow.add_child(fletch)


	_arrow.position = START_OFFSET
	_trail.position = START_OFFSET
	modulate.a = 0.0




func _fly() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.03)
	tween.parallel().tween_property(_arrow, "position", Vector2.ZERO, FLIGHT_TIME)
	tween.parallel().tween_property(_trail, "position", Vector2.ZERO, FLIGHT_TIME)
	tween.tween_callback(_impact)




func _impact() -> void:
	_trail.visible = false


	# Spark burst
	for i in range(6):
		var spark := Line2D.new()
		spark.width = 2.0
		spark.default_color = Color(1.0, 0.95, 0.7)
		var dir := Vector2.from_angle(randf_range(-PI, 0.0) + randf_range(-0.3, 0.3))
		spark.points = PackedVector2Array([Vector2.ZERO, dir * 5.0])
		add_child(spark)
		var t := create_tween()
		t.tween_property(spark, "points",
			PackedVector2Array([dir * 10.0, dir * 20.0]), 0.18)
		t.parallel().tween_property(spark, "modulate:a", 0.0, 0.18)
		t.tween_callback(spark.queue_free)


	# Arrow sticks in, wobbles, fades.
	var wobble := create_tween()
	wobble.tween_property(_arrow, "rotation", 0.12, 0.04)
	wobble.tween_property(_arrow, "rotation", -0.09, 0.05)
	wobble.tween_property(_arrow, "rotation", 0.0, 0.05)
	wobble.tween_property(self, "modulate:a", 0.0, 0.2)
	wobble.tween_callback(queue_free)
