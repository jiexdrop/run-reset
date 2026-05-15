extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
					result.collider.visible = true
