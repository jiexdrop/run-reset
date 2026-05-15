extends Node2D

const TILE = preload("uid://ceosbosrytods")

@onready var camera_2d: Camera2D = $Camera2D

const TILE_SIZE = 78


var camera_pos = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for i in range(9):
		for j in range(9):
			var instance = TILE.instantiate()
			instance.position.x = i * TILE_SIZE
			instance.position.y = j * TILE_SIZE
			instance.grid_x = i   # ← set before add_child
			instance.grid_y = j
			camera_pos = instance.position
			if i != 4 or j != 4:
				instance.visible = false
			add_child(instance)
			
	center_camera()

func center_camera() -> void:
	camera_pos /= 2;
	camera_2d.position = camera_pos;
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
