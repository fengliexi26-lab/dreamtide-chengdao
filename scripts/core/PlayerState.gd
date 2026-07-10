extends RefCounted
class_name PlayerState

var id: String
var display_name: String
var base_realm: int
var combat_realm: int
var max_life_source: int
var life_source: int
var dao_paths: Array[String]
var dao_progress: int = 0
var formation_value: int = 0
var formation_slots: int = 1
var active_formations: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var equipment: Array[Dictionary] = []
var deck: Array[Dictionary] = []

func _init(
	p_id: String = "player",
	p_display_name: String = "修行者",
	p_base_realm: int = Realm.Rank.HUANG_RANG,
	p_dao_paths: Array[String] = []
) -> void:
	id = p_id
	display_name = p_display_name
	base_realm = Realm.clamp_rank(p_base_realm)
	combat_realm = base_realm
	max_life_source = Realm.get_life_source(combat_realm)
	life_source = max_life_source
	dao_paths = p_dao_paths.duplicate()


func set_combat_realm(rank: int, keep_life_delta: bool = true) -> void:
	var old_max := max_life_source
	combat_realm = Realm.clamp_rank(rank)
	max_life_source = Realm.get_life_source(combat_realm)
	if keep_life_delta:
		life_source += max_life_source - old_max
	life_source = clampi(life_source, 0, max_life_source)


func take_damage(amount: int) -> int:
	var actual := clampi(amount, 0, life_source)
	life_source -= actual
	return actual


func heal(amount: int) -> int:
	var old_life := life_source
	life_source = clampi(life_source + maxi(0, amount), 0, max_life_source)
	return life_source - old_life


func is_defeated() -> bool:
	return life_source <= 0


func has_dao_path(path: String) -> bool:
	return dao_paths.has(path)


func has_free_formation_slot() -> bool:
	return active_formations.size() < formation_slots
