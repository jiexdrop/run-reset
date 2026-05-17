extends Control

const GAME_SCENE = "res://scenes/main.tscn"

func _ready() -> void:
	$VBoxContainer/ContinueButton.disabled = not FileAccess.file_exists(SaveManager.SAVE_PATH)

func _on_continue_pressed() -> void:
	SaveManager.load_save()                        # populate GameState before entering game
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_new_game_pressed() -> void:
	SaveManager.reset()                            # clear file + GameState
	get_tree().change_scene_to_file(GAME_SCENE)
