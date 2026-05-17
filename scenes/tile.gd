extends Area2D

@export var grid_x: int = 0
@export var grid_y: int = 0


# tile.gd — inside reveal()
func reveal() -> void:
	visible = true
	GameState.tiles["%d,%d" % [grid_x, grid_y]]["visible"] = true
	GameState.mark_dirty()
	SaveManager.save()
	# Recenter camera on all revealed tiles
	get_tree().get_first_node_in_group("game").center_camera_on_revealed()
	
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print(event.position)
			var space_state = get_world_2d().direct_space_state
			
			var directions = [
				Vector2(50, 0),   # Right
				Vector2(-50, 0),  # Left
				Vector2(0, 50),   # Down
				Vector2(0, -50),  # Up
			]
			
			for dir in directions:
				var query = PhysicsRayQueryParameters2D.create(position, position + dir)
				query.collide_with_areas = true
				var result = space_state.intersect_ray(query)
				if result:
					print("Hit at point: ", result.position)
					result.collider.reveal()
