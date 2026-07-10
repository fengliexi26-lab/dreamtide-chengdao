extends RefCounted
class_name Compatibility

static func participates_in_compatibility(card: Dictionary) -> bool:
	return CardTypes.participates_in_dao_compatibility(str(card.get("type", "")))


static func is_dao_compatible(player: PlayerState, card: Dictionary) -> bool:
	if not participates_in_compatibility(card):
		return true
	var tags: Array = card.get("dao_tags", [])
	if tags.is_empty():
		return true
	for tag in tags:
		if player.has_dao_path(str(tag)):
			return true
	return false


static func is_life_artifact_eligible(player: PlayerState, card: Dictionary) -> bool:
	if str(card.get("type", "")) != CardTypes.LIFE_ARTIFACT:
		return true
	var fate_pact: Dictionary = card.get("fate_pact", {})
	if fate_pact.is_empty():
		return true
	var required_owner_id := str(fate_pact.get("required_owner_id", ""))
	if required_owner_id != "" and required_owner_id != player.id:
		return false
	var required_dao_path := str(fate_pact.get("required_dao_path", ""))
	if required_dao_path != "" and not player.has_dao_path(required_dao_path):
		return false
	return true


static func should_trigger_fate_backlash(player: PlayerState, card: Dictionary) -> bool:
	return str(card.get("type", "")) == CardTypes.LIFE_ARTIFACT and not is_life_artifact_eligible(player, card)
