class_name PvePulseRuntime
extends RefCounted

const PULSE_FIRE := "fire"
const FIRE_THRESHOLD := 10

var buildup_by_target := {}


func reset() -> void:
	buildup_by_target.clear()


func is_supported_pulse(pulse_id: String) -> bool:
	return pulse_id == PULSE_FIRE


func get_buildup(target_id: String, pulse_id: String) -> int:
	if not buildup_by_target.has(target_id):
		return 0
	var target_buildup: Dictionary = buildup_by_target[target_id]
	return int(target_buildup.get(pulse_id, 0))


func get_all_buildup(target_id: String) -> Dictionary:
	if not buildup_by_target.has(target_id):
		return {}
	return (buildup_by_target[target_id] as Dictionary).duplicate(true)


func add_buildup(target_id: String, pulse_id: String, amount: int) -> Dictionary:
	var add_result := add_buildup_deferred(target_id, pulse_id, amount)
	if not bool(add_result.get("ok", false)):
		return add_result
	var resolve_result := resolve_thresholds(target_id, pulse_id)
	if not bool(resolve_result.get("ok", false)):
		return resolve_result
	return _result(
		true,
		"",
		target_id,
		pulse_id,
		int(add_result.get("before", 0)),
		amount,
		int(resolve_result.get("after", 0)),
		int(resolve_result.get("breaks", 0))
	)


func add_buildup_deferred(target_id: String, pulse_id: String, amount: int) -> Dictionary:
	if target_id == "":
		return _result(false, "target_id is required", target_id, pulse_id, 0, amount, 0, 0)
	if not is_supported_pulse(pulse_id):
		return _result(false, "unsupported pulse_id", target_id, pulse_id, 0, amount, 0, 0)
	if amount < 0:
		return _result(false, "amount must not be negative", target_id, pulse_id, get_buildup(target_id, pulse_id), amount, get_buildup(target_id, pulse_id), 0)
	if not buildup_by_target.has(target_id):
		buildup_by_target[target_id] = {}
	var target_buildup: Dictionary = buildup_by_target[target_id]
	var before := int(target_buildup.get(pulse_id, 0))
	var value := before + amount
	target_buildup[pulse_id] = value
	return _result(true, "", target_id, pulse_id, before, amount, value, 0)


func resolve_thresholds(target_id: String, pulse_id: String) -> Dictionary:
	if target_id == "":
		return _result(false, "target_id is required", target_id, pulse_id, 0, 0, 0, 0)
	if not is_supported_pulse(pulse_id):
		return _result(false, "unsupported pulse_id", target_id, pulse_id, 0, 0, 0, 0)
	if not buildup_by_target.has(target_id):
		buildup_by_target[target_id] = {}
	var target_buildup: Dictionary = buildup_by_target[target_id]
	var before := int(target_buildup.get(pulse_id, 0))
	var value := before
	var breaks := 0
	while value >= FIRE_THRESHOLD:
		value -= FIRE_THRESHOLD
		breaks += 1
	target_buildup[pulse_id] = value
	return _result(true, "", target_id, pulse_id, before, 0, value, breaks)


func reduce_buildup(target_id: String, pulse_id: String, amount: int) -> Dictionary:
	if target_id == "":
		return _reduce_result(false, "target_id is required", target_id, pulse_id, 0, amount, 0, 0)
	if not is_supported_pulse(pulse_id):
		return _reduce_result(false, "unsupported pulse_id", target_id, pulse_id, 0, amount, 0, 0)
	if amount < 0:
		return _reduce_result(false, "amount must not be negative", target_id, pulse_id, get_buildup(target_id, pulse_id), amount, get_buildup(target_id, pulse_id), 0)
	if not buildup_by_target.has(target_id):
		buildup_by_target[target_id] = {}
	var target_buildup: Dictionary = buildup_by_target[target_id]
	var before := int(target_buildup.get(pulse_id, 0))
	var reduced := mini(before, amount)
	var after := before - reduced
	target_buildup[pulse_id] = after
	return _reduce_result(true, "", target_id, pulse_id, before, amount, after, reduced)


func clear_target(target_id: String) -> void:
	buildup_by_target.erase(target_id)


func _result(ok: bool, reason: String, target_id: String, pulse_id: String, before: int, added: int, after: int, breaks: int) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"target_id": target_id,
		"pulse_id": pulse_id,
		"before": before,
		"added": added,
		"after": after,
		"breaks": breaks,
		"threshold": FIRE_THRESHOLD
	}


func _reduce_result(ok: bool, reason: String, target_id: String, pulse_id: String, before: int, requested: int, after: int, reduced: int) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"target_id": target_id,
		"pulse_id": pulse_id,
		"before": before,
		"requested": requested,
		"after": after,
		"reduced": reduced,
		"breaks": 0,
		"threshold": FIRE_THRESHOLD
	}
