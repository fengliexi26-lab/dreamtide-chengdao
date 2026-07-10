extends RefCounted
class_name Realm

const REALM_NAMES: Array[String] = [
	"荒壤",
	"命河",
	"黄庭",
	"天枝",
	"龙脊",
	"灵台",
	"垂天",
	"敛道",
	"朝天",
	"归墟",
	"帝阙"
]

const LIFE_SOURCES: Array[int] = [
	150,
	300,
	600,
	1000,
	1600,
	2500,
	3800,
	5500,
	7500,
	9000,
	10000
]

enum Rank {
	HUANG_RANG,
	MING_HE,
	HUANG_TING,
	TIAN_ZHI,
	LONG_JI,
	LING_TAI,
	CHUI_TIAN,
	LIAN_DAO,
	CHAO_TIAN,
	GUI_XU,
	DI_QUE
}

static func is_valid_rank(rank: int) -> bool:
	return rank >= 0 and rank < REALM_NAMES.size()


static func clamp_rank(rank: int) -> int:
	return clampi(rank, 0, REALM_NAMES.size() - 1)


static func get_realm_name(rank: int) -> String:
	return REALM_NAMES[clamp_rank(rank)]


static func get_life_source(rank: int) -> int:
	return LIFE_SOURCES[clamp_rank(rank)]


static func get_rank_by_name(realm_name: String) -> int:
	var index := REALM_NAMES.find(realm_name)
	return index if index >= 0 else Rank.HUANG_RANG


static func can_advance(rank: int) -> bool:
	return rank < REALM_NAMES.size() - 1
