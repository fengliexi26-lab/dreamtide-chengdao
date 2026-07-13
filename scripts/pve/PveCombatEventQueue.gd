class_name PveCombatEventQueue
extends RefCounted

const MAX_EVENT_DEPTH := 32
const MAX_EVENTS_PER_DRAIN := 256

var _queue: Array[Dictionary] = []
var _history: Array[Dictionary] = []
var _claimed_triggers := {}
var _event_counter := 0
var _is_processing := false


func reset() -> void:
	_queue.clear()
	_history.clear()
	_claimed_triggers.clear()
	_event_counter = 0
	_is_processing = false


func enqueue(event_type: String, payload: Dictionary = {}, parent_event_id: String = "") -> Dictionary:
	if event_type == "":
		return {"ok": false, "reason": "event_type is required", "event": {}}
	var depth := 0
	if parent_event_id != "":
		var parent := _find_event(parent_event_id)
		if parent.is_empty():
			return {"ok": false, "reason": "parent event not found", "event": {}}
		depth = int(parent.get("depth", 0)) + 1
	if depth > MAX_EVENT_DEPTH:
		push_error("[PveCombatEventQueue] event depth exceeded: %d" % depth)
		return {"ok": false, "reason": "event depth exceeded", "event": {}}
	_event_counter += 1
	var event := {
		"event_id": "event:%d" % _event_counter,
		"event_type": event_type,
		"payload": payload.duplicate(true),
		"parent_event_id": parent_event_id,
		"depth": depth,
		"sequence": _event_counter
	}
	_queue.append(event)
	return {"ok": true, "reason": "", "event": event.duplicate(true)}


func drain(handler: Callable) -> Dictionary:
	if _is_processing:
		return {"ok": false, "reason": "event queue is already processing", "processed": 0}
	_is_processing = true
	var processed := 0
	while not _queue.is_empty():
		if processed >= MAX_EVENTS_PER_DRAIN:
			push_error("[PveCombatEventQueue] max events per drain exceeded")
			_is_processing = false
			return {"ok": false, "reason": "max events per drain exceeded", "processed": processed}
		var event: Dictionary = _queue.pop_front()
		_history.append(event.duplicate(true))
		handler.call(event.duplicate(true))
		processed += 1
	_is_processing = false
	return {"ok": true, "reason": "", "processed": processed}


func claim_trigger(event_id: String, trigger_id: String) -> bool:
	if event_id == "" or trigger_id == "":
		return false
	var key := "%s::%s" % [event_id, trigger_id]
	if _claimed_triggers.has(key):
		return false
	_claimed_triggers[key] = true
	return true


func get_pending_count() -> int:
	return _queue.size()


func get_history() -> Array:
	var result: Array = []
	for event in _history:
		result.append((event as Dictionary).duplicate(true))
	return result


func is_processing() -> bool:
	return _is_processing


func _find_event(event_id: String) -> Dictionary:
	for event in _queue:
		if str((event as Dictionary).get("event_id", "")) == event_id:
			return (event as Dictionary).duplicate(true)
	for event in _history:
		if str((event as Dictionary).get("event_id", "")) == event_id:
			return (event as Dictionary).duplicate(true)
	return {}
