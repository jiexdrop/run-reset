extends Area2D
class_name GroundItem

var _tile_key: String = ""
var _item_key: String = ""

@onready var _sprite: Sprite2D = $Sprite2D

func setup(tile_key: String, item_key: String) -> void:
	_tile_key = tile_key
	_item_key = item_key
	_sprite.texture = ItemRegistry.get_icon(item_key)
	input_pickable = true
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item_name := ItemRegistry.get_item_name(_item_key)
		# Nothing to add means nothing is consumed — a full pack never eats loot.
		if InventoryState.add_item(_item_key, 1) > 0:
			_log_message("Your pack is full — leave the %s for later." % item_name)
			return
		if GameState.tiles.has(_tile_key):
			GameState.tiles[_tile_key]["item_collected"] = true
		GameState.mark_dirty()
		SaveManager.save()
		_log_message("Picked up %s." % item_name)
		queue_free()


func _log_message(msg: String) -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if combat_ui and combat_ui.has_method("log_message"):
		combat_ui.log_message(msg)
