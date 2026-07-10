extends RefCounted
class_name Breakthrough

const BREAKTHROUGH_COSTS: Array[int] = [
	100,
	200,
	350,
	550,
	800,
	1100,
	1450,
	1850,
	2300,
	2800
]

static func get_cost_to_next(current_realm: int) -> int:
	if not Realm.can_advance(current_realm):
		return -1
	return BREAKTHROUGH_COSTS[Realm.clamp_rank(current_realm)]


static func add_dao_progress(player: PlayerState, amount: int) -> void:
	player.dao_progress += maxi(0, amount)


static func can_breakthrough(player: PlayerState) -> bool:
	var cost := get_cost_to_next(player.combat_realm)
	return cost >= 0 and player.dao_progress >= cost


static func try_breakthrough(player: PlayerState) -> Dictionary:
	if not Realm.can_advance(player.combat_realm):
		return {"ok": false, "reason": "已达最高境界"}
	var cost := get_cost_to_next(player.combat_realm)
	if player.dao_progress < cost:
		return {"ok": false, "reason": "道行值不足", "required": cost, "current": player.dao_progress}
	player.dao_progress -= cost
	player.set_combat_realm(player.combat_realm + 1, true)
	return {
		"ok": true,
		"reason": "破境成功",
		"new_realm": player.combat_realm,
		"new_realm_name": Realm.get_realm_name(player.combat_realm)
	}
