extends Control

@onready var game: Node2D = $HBoxContainer/SubViewportContainer/SubViewport/Game
@onready var combat_ui: Control = $HBoxContainer/CombatUi

func _ready() -> void:
	game.restore_combat(combat_ui)
