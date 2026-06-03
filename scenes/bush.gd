extends Area2D
class_name Bush

## Bush — a harvestable tile decoration.
## Spawned by game.gd on top of revealed tiles.
## Click to harvest berries; sprite swaps to the empty bush.

const TEX_BERRIES = preload("res://assets/bush/bush_berries.png")
const TEX_EMPTY   = preload("res://assets/bush/bush.png")

const ICON_SIZE   = 50.0

var _harvested: bool = false
var _tile_key:  String = ""

@onready var _sprite: Sprite2D = $Sprite2D


func setup(tile_key: String, already_harvested: bool) -> void:
	_tile_key   = tile_key
	_harvested  = already_harvested
	_refresh()


func _refresh() -> void:
	_sprite.texture = TEX_EMPTY if _harvested else TEX_BERRIES
	_scale_sprite()


func _scale_sprite() -> void:
	if _sprite.texture == null:
		return
	var sz = _sprite.texture.get_size()
	var factor = ICON_SIZE / max(sz.x, sz.y)
	_sprite.scale = Vector2.ONE * factor


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_harvest()


func _harvest() -> void:
	if _harvested:
		return
	_harvested = true
	_refresh()

	# Persist harvested state.
	if GameState.tiles.has(_tile_key):
		GameState.tiles[_tile_key]["bush_harvested"] = true
	GameState.mark_dirty()
	SaveManager.save()

	# Add berries to the first free inventory slot (hotbar first, then bag).
	_give_berries()


func _give_berries() -> void:
	# Try hotbar first.
	for i in range(InventoryState.HOTBAR_SIZE):
		if InventoryState.hotbar[i].get("item_key", "") == "":
			InventoryState.add_item("berries", 1)
			return
	# Fall back to bag.
	for i in range(InventoryState.BAG_SIZE):
		if InventoryState.bag[i].get("item_key", "") == "":
			InventoryState.set_bag_item(i, "berries")
			return
	# Inventory full — silently drop (could log a message here).
