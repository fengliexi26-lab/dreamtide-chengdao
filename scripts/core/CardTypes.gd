extends RefCounted
class_name CardTypes

const CHENGDAO := "chengdao"
const DAOFA := "daofa"
const FORMATION := "formation"
const DAO_MARK := "dao_mark"
const TRAP := "trap"
const DOMAIN := "domain"
const LIFE_ARTIFACT := "life_artifact"

const DISPLAY_NAMES := {
	CHENGDAO: "承道牌",
	DAOFA: "道术牌 / 道法",
	FORMATION: "道术牌 / 法阵",
	DAO_MARK: "道痕牌",
	TRAP: "伏法牌",
	DOMAIN: "域界牌",
	LIFE_ARTIFACT: "命器牌"
}

static func get_display_name(card_type: String) -> String:
	return DISPLAY_NAMES.get(card_type, card_type)


static func participates_in_dao_compatibility(card_type: String) -> bool:
	return card_type == CHENGDAO or card_type == DAOFA


static func uses_fate_pact_check(card_type: String) -> bool:
	return card_type == LIFE_ARTIFACT


static func is_formation(card_type: String) -> bool:
	return card_type == FORMATION
