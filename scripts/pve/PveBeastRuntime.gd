extends RefCounted
class_name PveBeastRuntime

const RANK_ORDINARY := "ordinary"
const RANK_ADVANCED := "advanced"
const RANK_TOKEN := "token"
const RANK_UNIQUE := "unique"

const DEATH_DISCARD := "discard"
const DEATH_EXHAUST := "exhaust"
const DEATH_VANISH := "vanish"

const MAX_BOARD_CAPACITY := 3
const MAX_ADVANCED_BEASTS := 1

var active_beast_card_instances: Dictionary = {}
var _beast_instance_counter := 0


func reset() -> void:
	active_beast_card_instances.clear()
	_beast_instance_counter = 0


func create_beast_instance_id() -> String:
	_beast_instance_counter += 1
	return "pve_beast#%d" % _beast_instance_counter


func normalize_beast_metadata(source_card: Dictionary, summon_spec: Dictionary, overrides: Dictionary = {}) -> Dictionary:
	var rank := str(overrides.get("beast_rank", summon_spec.get("beast_rank", source_card.get("beast_rank", RANK_ORDINARY))))
	if rank == "":
		rank = RANK_ORDINARY

	var board_cost := 1
	var death_destination := DEATH_DISCARD
	var is_token := false
	match rank:
		RANK_ADVANCED:
			board_cost = 2
			death_destination = DEATH_EXHAUST
		RANK_TOKEN:
			board_cost = 1
			death_destination = DEATH_VANISH
			is_token = true
		RANK_UNIQUE:
			board_cost = 3
			death_destination = DEATH_EXHAUST
		_:
			board_cost = 1
			death_destination = DEATH_DISCARD

	var dao_tags: Array = []
	if typeof(summon_spec.get("dao_tags", source_card.get("dao_tags", []))) == TYPE_ARRAY:
		dao_tags = summon_spec.get("dao_tags", source_card.get("dao_tags", [])).duplicate(true)

	var attack := int(summon_spec.get("attack", source_card.get("attack", source_card.get("attack_value", 0))))
	var life := int(summon_spec.get("life", source_card.get("life", source_card.get("max_life", 1))))
	life = maxi(1, life)

	return {
		"beast_instance_id": "",
		"source_card_instance_id": "" if is_token else str(source_card.get("instance_id", "")),
		"source_base_card_id": "" if is_token else str(source_card.get("base_card_id", source_card.get("id", ""))),
		"name": str(summon_spec.get("name", source_card.get("name", "承道兽"))),
		"type": "chengdao",
		"summon_id": str(summon_spec.get("summon_id", source_card.get("id", ""))),
		"attack_value": attack,
		"attack": attack,
		"current_life": life,
		"max_life": life,
		"life": life,
		"side": str(summon_spec.get("side", source_card.get("side", "neutral"))),
		"chengdao_kind": str(summon_spec.get("chengdao_kind", source_card.get("chengdao_kind", ""))),
		"dao_tags": dao_tags,
		"beast_rank": rank,
		"beast_role": str(overrides.get("beast_role", summon_spec.get("beast_role", source_card.get("beast_role", "")))),
		"board_cost": board_cost,
		"death_destination": death_destination,
		"is_token": is_token,
		"action_points": 1,
		"action_points_remaining": 1,
		"has_attacked": false,
		"has_acted": false
	}


func validate_summon(current_beasts: Array, metadata: Dictionary) -> Dictionary:
	var rank := str(metadata.get("beast_rank", RANK_ORDINARY))
	if rank == RANK_UNIQUE:
		return {"ok": false, "reason": "唯一承道兽后续版本开放。"}
	if rank not in [RANK_ORDINARY, RANK_ADVANCED, RANK_TOKEN]:
		return {"ok": false, "reason": "未知承道兽阶级：%s。" % rank}
	if rank in [RANK_ORDINARY, RANK_ADVANCED] and str(metadata.get("source_card_instance_id", "")) == "":
		return {"ok": false, "reason": "承道兽缺少来源卡实例。"}

	var used_capacity := get_used_capacity(current_beasts)
	var required_capacity := get_board_cost(metadata)
	if used_capacity + required_capacity > MAX_BOARD_CAPACITY:
		return {
			"ok": false,
			"reason": "无法召唤：承道兽占位不足，需要 %d，剩余 %d。" % [required_capacity, MAX_BOARD_CAPACITY - used_capacity],
			"used_capacity": used_capacity,
			"required_capacity": required_capacity
		}
	if rank == RANK_ADVANCED and get_advanced_count(current_beasts) >= MAX_ADVANCED_BEASTS:
		return {"ok": false, "reason": "无法召唤：进阶承道兽最多存在 1 只。"}
	return {
		"ok": true,
		"reason": "",
		"used_capacity": used_capacity,
		"required_capacity": required_capacity,
		"remaining_capacity": MAX_BOARD_CAPACITY - used_capacity - required_capacity
	}


func register_source_card(beast_instance_id: String, source_card: Dictionary) -> Dictionary:
	if beast_instance_id == "":
		return {"ok": false, "reason": "缺少承道兽实例 id。"}
	if source_card.is_empty():
		return {"ok": false, "reason": "缺少来源卡。"}
	var source_instance_id := str(source_card.get("instance_id", ""))
	if source_instance_id == "":
		return {"ok": false, "reason": "来源卡缺少 instance_id。"}
	for active_card in active_beast_card_instances.values():
		if typeof(active_card) == TYPE_DICTIONARY and str((active_card as Dictionary).get("instance_id", "")) == source_instance_id:
			return {"ok": false, "reason": "来源卡已登记为场上承道兽。"}
	active_beast_card_instances[beast_instance_id] = source_card
	return {"ok": true, "reason": ""}


func release_source_card(beast_instance_id: String) -> Dictionary:
	if not active_beast_card_instances.has(beast_instance_id):
		return {}
	var source_card: Dictionary = active_beast_card_instances[beast_instance_id]
	active_beast_card_instances.erase(beast_instance_id)
	return source_card


func has_source_card(beast_instance_id: String) -> bool:
	return active_beast_card_instances.has(beast_instance_id)


func get_active_source_count() -> int:
	return active_beast_card_instances.size()


func get_board_cost(beast_unit: Dictionary) -> int:
	return maxi(1, int(beast_unit.get("board_cost", 1)))


func get_used_capacity(beast_units: Array) -> int:
	var total := 0
	for unit in beast_units:
		if typeof(unit) == TYPE_DICTIONARY:
			total += get_board_cost(unit)
	return total


func get_advanced_count(beast_units: Array) -> int:
	var total := 0
	for unit in beast_units:
		if typeof(unit) == TYPE_DICTIONARY and str((unit as Dictionary).get("beast_rank", RANK_ORDINARY)) == RANK_ADVANCED:
			total += 1
	return total
