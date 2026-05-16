extends Control

const SAVE_PATH = "user://save.dat"
const GAME_SCENE = "uid://caxkx57v2uspr"

func _ready() -> void:
	# Disable Continue if no save exists
	$VBoxContainer/ContinueButton.disabled = not FileAccess.file_exists(SAVE_PATH)


func _on_continue_pressed() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().change_scene_to_file("res://scenes/game.tscn")
