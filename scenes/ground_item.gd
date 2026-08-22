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
		InventoryState.add_item(_item_key, 1)
		if GameState.tiles.has(_tile_key):
			GameState.tiles[_tile_key]["item_collected"] = true
		GameState.mark_dirty()
		SaveManager.save()
		queue_free()
