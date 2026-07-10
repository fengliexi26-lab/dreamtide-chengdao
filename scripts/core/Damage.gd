extends RefCounted
class_name Damage

enum Tier {
	MICRO,
	SMALL,
	MEDIUM,
	LARGE,
	BURST
}

const TIER_NAMES: Array[String] = [
	"微额伤害",
	"小额伤害",
	"中额伤害",
	"大额伤害",
	"爆发伤害"
]

const TIER_RATIOS: Array[float] = [
	0.05,
	0.10,
	0.18,
	0.30,
	0.45
]

static func clamp_tier(tier: int) -> int:
	return clampi(tier, 0, TIER_NAMES.size() - 1)


static func get_tier_name(tier: int) -> String:
	return TIER_NAMES[clamp_tier(tier)]


static func calculate(tier: int, user_combat_realm: int) -> int:
	var life_source := Realm.get_life_source(user_combat_realm)
	var ratio := TIER_RATIOS[clamp_tier(tier)]
	return maxi(1, int(ceil(float(life_source) * ratio)))
