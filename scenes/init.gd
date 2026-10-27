extends Control

const GAME_SCENE = "res://scenes/main.tscn"
const OptionsMenu := preload("res://scenes/options_menu.gd")

var _options: Control = null

func _ready() -> void:
	# Same beige the default zone uses, so the menu matches floor 1.
	RenderingServer.set_default_clear_color(ZoneRegistry.get_bg_color(ZoneRegistry.DEFAULT_ZONE))
	OptionsMenu.apply_saved()
	# No save to continue: hide the button entirely rather than showing it greyed out.
	$VBoxContainer/ContinueButton.visible = FileAccess.file_exists(SaveManager.SAVE_PATH)
	# Quit does nothing in web exports, so don't show it there.
	$VBoxContainer/QuitButton.visible = not OS.has_feature("web")

func _on_continue_pressed() -> void:
	SaveManager.load_save()                        # populate GameState before entering game
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_new_game_pressed() -> void:
	SaveManager.reset()                            # clear file + GameState
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_options_pressed() -> void:
	$VBoxContainer.hide()
	_options = OptionsMenu.new()
	add_child(_options)
	_options.closed.connect(_on_options_closed)

func _on_options_closed() -> void:
	if is_instance_valid(_options):
		_options.queue_free()
	_options = null
	$VBoxContainer.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
