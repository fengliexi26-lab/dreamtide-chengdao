extends RefCounted
class_name Formation

static func can_play(player: PlayerState, card: Dictionary) -> Dictionary:
	if str(card.get("type", "")) != CardTypes.FORMATION:
		return {"ok": false, "reason": "不是法阵牌"}
	var realm_requirement := int(card.get("realm_requirement", 0))
	if player.combat_realm < realm_requirement:
		return {"ok": false, "reason": "境界不足"}
	var life_requirement := int(card.get("life_requirement", 0))
	if player.life_source < life_requirement:
		return {"ok": false, "reason": "命源不足"}
	var formation_cost := int(card.get("formation_cost", 0))
	if player.formation_value < formation_cost:
		return {"ok": false, "reason": "阵势值不足"}
	if not player.has_free_formation_slot():
		return {"ok": false, "reason": "没有可用法阵位"}
	return {"ok": true, "reason": "可布阵"}


static func play(player: PlayerState, card: Dictionary) -> Dictionary:
	var result := can_play(player, card)
	if not bool(result.get("ok", false)):
		return result
	player.formation_value -= int(card.get("formation_cost", 0))
	player.active_formations.append(card)
	return {"ok": true, "reason": "法阵生效", "card": card}
