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
@export var loot_table: Array[Dictionary]    = []
@export var resistances: Dictionary          = {} 
@export var burrows:    bool                 = false

## Optional two-phase armor (used by the Raptor Skeleton boss).
## When phase_split_hp >= 0, the fight is split by current HP:
##   Phase 1 (hp > phase_split_hp): only `phase1_allowed` categories land.
##   Phase 2 (hp <= phase_split_hp): only `phase2_allowed` categories land.
## Categories are "throwable" (bombs, bows/arrows), "sword", or "other".
@export var phase_split_hp:       int          = -1
@export var phase1_allowed:       Array[String] = ["throwable"]
@export var phase2_allowed:       Array[String] = ["sword"]
@export var phase1_deny_message:  String        = ""
@export var phase2_deny_message:  String        = ""
