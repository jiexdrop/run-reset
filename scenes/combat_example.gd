## combat_example.gd
## ─────────────────────────────────────────────────────────────────────────────
## Drop this code into any script that wants to trigger combat.
## Typically you'd call this from tile.gd when the player enters a room,
## or from game.gd after dungeon generation seeds monsters.
##
## USAGE
## ──────
## 1. Add monsters to GameState.monsters before calling start_combat():
##
##      GameState.monsters.append({
##          "id":        0,
##          "name":      "Cave Spider",
##          "hp":        3,
##          "max_hp":    3,
##          "sprite":    "spider",     # must match MOB_SPRITES key in mob_card.gd
##          "xp_reward": 2,
##      })
##
## 2. Build your attacks (or load them as saved Resources):
##
##      var sword        = AttackData.new()
##      sword.attack_name = "Sword"
##      sword.damage      = 3
##      sword.energy_cost = 2
##      sword.icon        = preload("res://assets/attacks/sword.png")
##
## 3. Get CombatUI and start:
##
##      var combat_ui = get_tree().get_first_node_in_group("combat_ui")
##      combat_ui.start_combat([0], [sword])   # pass mob indices + attacks
##
## ADDING NEW MOBS
## ───────────────
## • Add a sprite entry in mob_card.gd → MOB_SPRITES
## • Append a dictionary with the new mob's fields to GameState.monsters
##
## ADDING NEW ATTACKS
## ──────────────────
## • Create a new AttackData resource (or instantiate in code as above)
## • Add it to the attacks array passed to start_combat()
##
## UNLOCKING MORE HEARTS / ENERGY
## ───────────────────────────────
## • Modify GameState.player["max_hp"]     (the icon row auto-scales)
## • Modify GameState.player["max_energy"] (same)
## • Call combat_ui.refresh_stats() after the change

## Nothing to extend here — this file is documentation / copy-paste reference.
