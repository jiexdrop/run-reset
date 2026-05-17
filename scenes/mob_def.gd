## MobDef — blueprint for one mob type.
## Instantiate in MobRegistry.gd (or any script) to define a new enemy.
##
## Example:
##   var spider      = MobDef.new()
##   spider.mob_name = "Cave Spider"
##   spider.sprite   = "spider"
##   spider.max_hp   = 3
##   spider.xp_reward = 2
##   spider.attacks  = [bite_attack]   # Array[MobAttackData]

extends Resource
class_name MobDef

@export var mob_name:   String               = "Enemy"
@export var sprite:     String               = ""      # key into mob_card.gd MOB_SPRITES
@export var max_hp:     int                  = 3
@export var xp_reward:  int                  = 1
@export var attacks:    Array[MobAttackData] = []
