extends Control

const DebugItemBrowser = preload("res://scenes/debug_item_browser.gd")
const DebugZoneBrowser = preload("res://scenes/debug_zone_browser.gd")

@onready var game: Node2D = $HBoxContainer/SubViewportContainer/SubViewport/Game
@onready var combat_ui: Control = $HBoxContainer/CombatUi

func _ready() -> void:
	game.restore_combat(combat_ui)
	if OS.is_debug_build():
		_add_debug_item_browser()
		_add_debug_zone_browser()


## This is deliberately instantiated only in debug builds. Release exports do
## not create the launcher or panel, so the developer item giver is absent from
## packaged versions of the game.
func _add_debug_item_browser() -> void:
	var browser := DebugItemBrowser.new()
	add_child(browser)


func _add_debug_zone_browser() -> void:
	var browser := DebugZoneBrowser.new()
	add_child(browser)
