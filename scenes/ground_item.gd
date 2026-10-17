extends Area2D
class_name GroundItem

var _tile_key: String = ""
var _item_key: String = ""
var _count: int = 1
var _count_label: Label = null

@onready var _sprite: Sprite2D = $Sprite2D

func setup(tile_key: String, item_key: String, count: int = 1) -> void:
	_tile_key = tile_key
	_item_key = item_key
	_count = max(1, count)
	_sprite.texture = ItemRegistry.get_icon(item_key)
	if _count > 1:
		_add_count_label()
	input_pickable = true
	input_event.connect(_on_input_event)


## Bundle badge ("x8") pinned to the sprite's bottom-right corner. The
## sprite is centred on this node and scaled down by the scene, so the
## corner is half of its scaled size.
func _add_count_label() -> void:
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.add_theme_font_size_override("font_size", 11)
	_count_label.add_theme_color_override("font_color", Color.WHITE)
	_count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_count_label.add_theme_constant_override("shadow_offset_x", 1)
	_count_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_count_label)
	_position_count_label()


## Repositions the badge after its text changes (e.g. a partial pickup
## shrank the stack), keeping it flush with the sprite's bottom-right.
func _position_count_label() -> void:
	if _count_label == null:
		return
	_count_label.text = "x%d" % _count
	var label_size := _count_label.get_combined_minimum_size()
	_count_label.size = label_size
	var half := Vector2(24, 24)
	if _sprite.texture != null:
		half = _sprite.texture.get_size() * _sprite.scale * 0.5
	_count_label.position = Vector2(half.x - label_size.x, half.y - label_size.y)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item_name := ItemRegistry.get_item_name(_item_key)
		var leftover: int = InventoryState.add_item(_item_key, _count)
		print("[PICKUP] key=%s requested=%d leftover=%d" % [_item_key, _count, leftover])
		if leftover >= _count:
			# Nothing fit — a full pack never eats loot.
			_log_message("Your pack is full — leave the %s for later." % item_name)
			return
		if leftover > 0:
			# Partial pickup: keep the remainder on the ground.
			var taken := _count - leftover
			_count = leftover
			_position_count_label()
			if GameState.tiles.has(_tile_key):
				GameState.tiles[_tile_key]["item_count"] = leftover
			GameState.mark_dirty()
			SaveManager.save()
			_log_message("Picked up %s x%d — your pack is full, %d left." % [item_name, taken, leftover])
			return
		if GameState.tiles.has(_tile_key):
			GameState.tiles[_tile_key]["item_collected"] = true
		GameState.mark_dirty()
		SaveManager.save()
		if _count > 1:
			_log_message("Picked up %s x%d." % [item_name, _count])
		else:
			_log_message("Picked up %s." % item_name)
		queue_free()


func _log_message(msg: String) -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if combat_ui and combat_ui.has_method("log_message"):
		combat_ui.log_message(msg)
