## MobAttackData — one attack a mob can perform.
## Create in code or as a .tres resource.
##
##   var bite = MobAttackData.new()
##   bite.attack_name = "Bite"
##   bite.damage      = 2
##   bite.effect      = MobAttackData.Effect.NONE
##
## Add more Effect variants to extend the system.

extends Resource
class_name MobAttackData

enum Effect {
	NONE,       # plain damage
	POISON,     # deal damage + apply poison (extend in combat_ui as needed)
	STUN,       # skip player next turn
}

@export var attack_name: String        = "Attack"
@export var damage:      int           = 1
@export var effect:      Effect        = Effect.NONE
@export var icon:        Texture2D     = null
