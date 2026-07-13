class_name PveStatusRuntime
extends RefCounted

const STATUS_ZHUOMAI := "zhuomai"

var statuses_by_target := {}


func reset() -> void:
	statuses_by_target.clear()


func apply_status(target_id: String, status_spec: Dictionary) -> Dictionary:
	if target_id == "":
		return {"ok": false, "reason": "target_id is required", "status": {}}
	var status_id := str(status_spec.get("status_id", ""))
	if status_id == "":
		return {"ok": false, "reason": "status_id is required", "status": {}}
	var stacks := int(status_spec.get("stacks", 0))
	if stacks <= 0:
		return {"ok": false, "reason": "stacks must be positive", "status": {}}
	if not statuses_by_target.has(target_id):
		statuses_by_target[target_id] = {}
	var target_statuses: Dictionary = statuses_by_target[target_id]
	var status: Dictionary = target_statuses.get(status_id, _default_status(target_id, status_spec))
	status["stacks"] = int(status.get("stacks", 0)) + stacks
	status["source_id"] = str(status_spec.get("source_id", status.get("source_id", "")))
	status["target_id"] = target_id
	status["display_name"] = str(status_spec.get("display_name", status.get("display_name", status_id)))
	status["max_stacks"] = int(status_spec.get("max_stacks", status.get("max_stacks", 0)))
	status["duration"] = int(status_spec.get("duration", status.get("duration", -1)))
	status["tick_timing"] = str(status_spec.get("tick_timing", status.get("tick_timing", "")))
	status["visible"] = bool(status_spec.get("visible", status.get("visible", true)))
	status["dispellable"] = bool(status_spec.get("dispellable", status.get("dispellable", true)))
	if typeof(status_spec.get("tags", status.get("tags", []))) == TYPE_ARRAY:
		status["tags"] = status_spec.get("tags", status.get("tags", [])).duplicate(true)
	_trim_status_stacks(status)
	target_statuses[status_id] = status
	if int(status.get("stacks", 0)) <= 0:
		target_statuses.erase(status_id)
	return {"ok": true, "reason": "", "status": status.duplicate(true)}


func get_status(target_id: String, status_id: String) -> Dictionary:
	if not statuses_by_target.has(target_id):
		return {}
	var target_statuses: Dictionary = statuses_by_target[target_id]
	if not target_statuses.has(status_id):
		return {}
	return (target_statuses[status_id] as Dictionary).duplicate(true)


func has_status(target_id: String, status_id: String) -> bool:
	return not get_status(target_id, status_id).is_empty()


func get_statuses(target_id: String) -> Array:
	var result: Array = []
	if not statuses_by_target.has(target_id):
		return result
	for status in (statuses_by_target[target_id] as Dictionary).values():
		result.append((status as Dictionary).duplicate(true))
	return result


func get_visible_statuses(target_id: String) -> Array:
	var result: Array = []
	for status in get_statuses(target_id):
		if bool((status as Dictionary).get("visible", true)):
			result.append((status as Dictionary).duplicate(true))
	return result


func set_stacks(target_id: String, status_id: String, stacks: int) -> Dictionary:
	if not statuses_by_target.has(target_id):
		return {"ok": false, "reason": "status not found", "status": {}}
	var target_statuses: Dictionary = statuses_by_target[target_id]
	if not target_statuses.has(status_id):
		return {"ok": false, "reason": "status not found", "status": {}}
	if stacks <= 0:
		target_statuses.erase(status_id)
		return {"ok": true, "reason": "", "status": {}}
	var status: Dictionary = target_statuses[status_id]
	status["stacks"] = stacks
	_trim_status_stacks(status)
	target_statuses[status_id] = status
	return {"ok": true, "reason": "", "status": status.duplicate(true)}


func remove_status(target_id: String, status_id: String) -> Dictionary:
	var existing := get_status(target_id, status_id)
	if statuses_by_target.has(target_id):
		(statuses_by_target[target_id] as Dictionary).erase(status_id)
	return {"ok": not existing.is_empty(), "reason": "", "status": existing}


func clear_target(target_id: String) -> void:
	statuses_by_target.erase(target_id)


func get_owner_turn_end_statuses(target_ids: Array[String]) -> Array:
	var result: Array = []
	for target_id in target_ids:
		for status in get_statuses(target_id):
			if str((status as Dictionary).get("tick_timing", "")) == "owner_turn_end":
				result.append((status as Dictionary).duplicate(true))
	return result


func _default_status(target_id: String, status_spec: Dictionary) -> Dictionary:
	return {
		"status_id": str(status_spec.get("status_id", "")),
		"display_name": str(status_spec.get("display_name", status_spec.get("status_id", ""))),
		"stacks": 0,
		"max_stacks": int(status_spec.get("max_stacks", 0)),
		"duration": int(status_spec.get("duration", -1)),
		"tick_timing": str(status_spec.get("tick_timing", "")),
		"source_id": str(status_spec.get("source_id", "")),
		"target_id": target_id,
		"visible": bool(status_spec.get("visible", true)),
		"dispellable": bool(status_spec.get("dispellable", true)),
		"tags": status_spec.get("tags", []).duplicate(true) if typeof(status_spec.get("tags", [])) == TYPE_ARRAY else []
	}


func _trim_status_stacks(status: Dictionary) -> void:
	status["stacks"] = maxi(0, int(status.get("stacks", 0)))
	var max_stacks := int(status.get("max_stacks", 0))
	if max_stacks > 0:
		status["stacks"] = mini(int(status.get("stacks", 0)), max_stacks)
