extends RefCounted
class_name BattleEngine

static func apply_damage_tier(user: PlayerState, target: PlayerState, tier: int) -> Dictionary:
	var amount := Damage.calculate(tier, user.combat_realm)
	var actual := target.take_damage(amount)
	return {
		"amount": amount,
		"actual": actual,
		"tier": tier,
		"tier_name": Damage.get_tier_name(tier),
		"target_defeated": target.is_defeated()
	}


static func handle_card_obtained(player: PlayerState, card: Dictionary, source: String = "draw") -> Dictionary:
	if Compatibility.should_trigger_fate_backlash(player, card):
		return trigger_fate_backlash(player, card, source)
	player.hand.append(card)
	return {"ok": true, "reason": "获得卡牌", "source": source, "card": card}


static func equip_life_artifact(player: PlayerState, card: Dictionary) -> Dictionary:
	if Compatibility.should_trigger_fate_backlash(player, card):
		return trigger_fate_backlash(player, card, "equip")
	player.equipment.append(card)
	return {"ok": true, "reason": "命器装备成功", "card": card}


static func trigger_fate_backlash(player: PlayerState, card: Dictionary, source: String) -> Dictionary:
	var fate_pact: Dictionary = card.get("fate_pact", {})
	var backlash_tier := int(fate_pact.get("backlash_tier", Damage.Tier.SMALL))
	var damage := Damage.calculate(backlash_tier, player.combat_realm)
	var actual := player.take_damage(damage)
	player.discard_pile.append(card)
	return {
		"ok": false,
		"reason": "命契反噬",
		"source": source,
		"card": card,
		"damage": damage,
		"actual_damage": actual,
		"discarded": true
	}


static func play_card(player: PlayerState, card: Dictionary) -> Dictionary:
	var card_type := str(card.get("type", ""))
	if card_type == CardTypes.FORMATION:
		return Formation.play(player, card)
	if CardTypes.participates_in_dao_compatibility(card_type) and not Compatibility.is_dao_compatible(player, card):
		return {"ok": false, "reason": "道脉不适配", "card": card}
	if card_type == CardTypes.LIFE_ARTIFACT:
		return equip_life_artifact(player, card)
	return {"ok": true, "reason": "卡牌使用成功", "card": card}
