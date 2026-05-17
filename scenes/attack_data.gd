## AttackData — define one attack as a Resource.
## Create instances via File > New Resource > AttackData in the Godot editor,
## or construct them in code:
##
##   var sword = AttackData.new()
##   sword.attack_name  = "Sword"
##   sword.damage       = 3
##   sword.energy_cost  = 2
##   sword.icon         = preload("res://assets/attacks/sword.png")
##
## Pass an Array[AttackData] to CombatUI.set_attacks() to populate the attack bar.

extends Resource
class_name AttackData

@export var attack_name:  String  = "Attack"
@export var damage:       int     = 1
@export var energy_cost:  int     = 1
@export var icon: Texture2D       = null
