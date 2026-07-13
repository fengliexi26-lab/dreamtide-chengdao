extends Node

const PveCombatEventQueueScript = preload("res://scripts/pve/PveCombatEventQueue.gd")
const PveStatusRuntimeScript = preload("res://scripts/pve/PveStatusRuntime.gd")
const PvePulseRuntimeScript = preload("res://scripts/pve/PvePulseRuntime.gd")
const PveCardEffectAdapterScript = preload("res://scripts/pve/PveCardEffectAdapter.gd")
const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")


func _ready() -> void:
	if not _test_event_queue_fifo():
		return
	if not _test_event_depth():
		return
	if not _test_trigger_dedupe():
		return
	if not _test_status_stacking():
		return
	if not _test_fire_threshold_and_overflow():
		return
	if not _test_reduce_pulse():
		return
	if not _test_adapter_new_effects():
		return
	print("[TestPveStatusFirePulse] all tests passed")
	get_tree().quit(0)


func _test_event_queue_fifo() -> bool:
	var queue = PveCombatEventQueueScript.new()
	var a: Dictionary = queue.enqueue("A").get("event", {})
	var b: Dictionary = queue.enqueue("B").get("event", {})
	var c: Dictionary = queue.enqueue("C").get("event", {})
	var drained: Array[String] = []
	var result: Dictionary = queue.drain(func(event: Dictionary) -> void:
		drained.append(str(event.get("event_type", "")))
	)
	if not bool(result.get("ok", false)):
		return _fail_bool("event queue drain should pass")
	if drained != ["A", "B", "C"]:
		return _fail_bool("event queue should drain FIFO")
	if str(a.get("event_id", "")) == str(b.get("event_id", "")) or str(b.get("event_id", "")) == str(c.get("event_id", "")):
		return _fail_bool("event ids should be unique")
	var history := queue.get_history()
	if history.size() != 3 or str(history[0].get("event_type", "")) != "A" or str(history[2].get("event_type", "")) != "C":
		return _fail_bool("event history should match drain order")
	return true


func _test_event_depth() -> bool:
	var queue = PveCombatEventQueueScript.new()
	var root: Dictionary = queue.enqueue("root").get("event", {})
	var parent_id := str(root.get("event_id", ""))
	for i in range(PveCombatEventQueueScript.MAX_EVENT_DEPTH):
		var result: Dictionary = queue.enqueue("child", {}, parent_id)
		if not bool(result.get("ok", false)):
			return _fail_bool("event depth 32 should be allowed")
		parent_id = str((result.get("event", {}) as Dictionary).get("event_id", ""))
	var too_deep: Dictionary = queue.enqueue("too_deep", {}, parent_id)
	if bool(too_deep.get("ok", false)):
		return _fail_bool("event depth 33 should be rejected")
	queue.reset()
	if queue.get_pending_count() != 0 or not queue.get_history().is_empty():
		return _fail_bool("event queue reset should clear queue and history")
	if not bool(queue.enqueue("after_reset").get("ok", false)):
		return _fail_bool("event queue should be reusable after reset")
	return true


func _test_trigger_dedupe() -> bool:
	var queue = PveCombatEventQueueScript.new()
	var event_id := str(queue.enqueue("trigger").get("event", {}).get("event_id", ""))
	if not queue.claim_trigger(event_id, "songgui"):
		return _fail_bool("first trigger claim should pass")
	if queue.claim_trigger(event_id, "songgui"):
		return _fail_bool("second trigger claim should fail")
	if not queue.claim_trigger(event_id, "other"):
		return _fail_bool("different trigger id should pass")
	queue.reset()
	if not queue.claim_trigger(event_id, "songgui"):
		return _fail_bool("trigger claim should reset")
	return true


func _test_status_stacking() -> bool:
	var runtime = PveStatusRuntimeScript.new()
	var target_id := "enemy:primary"
	runtime.apply_status(target_id, _zhuomai_spec(3))
	runtime.apply_status(target_id, _zhuomai_spec(2))
	if int(runtime.get_status(target_id, "zhuomai").get("stacks", 0)) != 5:
		return _fail_bool("zhuomai should stack to 5")
	runtime.apply_status(target_id, _zhuomai_spec(2))
	if int(runtime.get_status(target_id, "zhuomai").get("stacks", 0)) != 6:
		return _fail_bool("zhuomai should clamp to 6")
	var copied: Dictionary = runtime.get_status(target_id, "zhuomai")
	copied["stacks"] = 99
	if int(runtime.get_status(target_id, "zhuomai").get("stacks", 0)) != 6:
		return _fail_bool("status query should return a copy")
	runtime.set_stacks(target_id, "zhuomai", 0)
	if runtime.has_status(target_id, "zhuomai"):
		return _fail_bool("status should be removed at 0 stacks")
	return true


func _test_fire_threshold_and_overflow() -> bool:
	var runtime = PvePulseRuntimeScript.new()
	var target_id := "enemy:primary"
	var first: Dictionary = runtime.add_buildup(target_id, "fire", 9)
	if int(first.get("breaks", -1)) != 0 or int(first.get("after", -1)) != 9:
		return _fail_bool("0 + 9 fire should not break")
	var second: Dictionary = runtime.add_buildup(target_id, "fire", 1)
	if int(second.get("breaks", -1)) != 1 or int(second.get("after", -1)) != 0:
		return _fail_bool("9 + 1 fire should break once")
	var third: Dictionary = runtime.add_buildup(target_id, "fire", 25)
	if int(third.get("breaks", -1)) != 2 or int(third.get("after", -1)) != 5:
		return _fail_bool("0 + 25 fire should break twice and keep overflow")
	return true


func _test_reduce_pulse() -> bool:
	var runtime = PvePulseRuntimeScript.new()
	var target_id := "enemy:primary"
	runtime.add_buildup(target_id, "fire", 8)
	var first: Dictionary = runtime.reduce_buildup(target_id, "fire", 3)
	if int(first.get("after", -1)) != 5 or int(first.get("breaks", -1)) != 0:
		return _fail_bool("reduce fire 8 by 3 should leave 5 and not break")
	var second: Dictionary = runtime.reduce_buildup(target_id, "fire", 99)
	if int(second.get("after", -1)) != 0 or int(second.get("reduced", -1)) != 5:
		return _fail_bool("reduce fire should clamp at 0")
	return true


func _test_adapter_new_effects() -> bool:
	var adapter = PveCardEffectAdapterScript.new()
	var valid_card := {
		"id": "test_valid_fire",
		"implementation_phase": "phase_1_base",
		"effects": [
			{"type": "deal_damage", "value": 8, "target": "enemy", "pulse_id": "fire", "pulse_value": 4, "conductive": false},
			{"type": "add_pulse_buildup", "pulse_id": "fire", "value": 4, "target": "enemy"},
			{"type": "reduce_pulse_buildup", "pulse_id": "fire", "value": 3, "target": "self"},
			{"type": "apply_status", "status_id": "zhuomai", "stacks": 2, "target": "enemy"}
		]
	}
	if not adapter.get_validation_errors(valid_card).is_empty():
		return _fail_bool("adapter should accept supported fire/status effects: %s" % str(adapter.get_validation_errors(valid_card)))
	if adapter.get_validation_errors(_effect_card({"type": "add_pulse_buildup", "pulse_id": "ice", "value": 1, "target": "enemy"})).is_empty():
		return _fail_bool("adapter should reject unknown pulse_id")
	if adapter.get_validation_errors(_effect_card({"type": "add_pulse_buildup", "value": 1, "target": "enemy"})).is_empty():
		return _fail_bool("adapter should reject missing pulse_id")
	if adapter.get_validation_errors(_effect_card({"type": "apply_status", "status_id": "zhuomai", "target": "enemy"})).is_empty():
		return _fail_bool("adapter should reject missing stacks")
	if adapter.get_validation_errors(_effect_card({"type": "deal_damage", "value": 1, "target": "enemy", "pulse_id": "fire"})).is_empty():
		return _fail_bool("adapter should reject missing pulse_value")

	var catalog = PveCardV1CatalogScript.new()
	if not catalog.load_catalog():
		return _fail_bool("v1 catalog should load")
	for card_id in catalog.get_all_card_ids():
		var card: Dictionary = catalog.get_card_definition(str(card_id))
		if not adapter.get_validation_errors(card).is_empty():
			return _fail_bool("existing v1 card should remain valid: %s %s" % [str((card as Dictionary).get("id", "")), str(adapter.get_validation_errors(card))])
	return true


func _zhuomai_spec(stacks: int) -> Dictionary:
	return {
		"status_id": "zhuomai",
		"display_name": "灼脉",
		"stacks": stacks,
		"max_stacks": 6,
		"duration": -1,
		"tick_timing": "owner_turn_end",
		"visible": true,
		"tags": ["pulse", "fire", "damage_over_time"]
	}


func _effect_card(effect: Dictionary) -> Dictionary:
	return {
		"id": "test_effect",
		"implementation_phase": "phase_1_base",
		"effects": [effect]
	}


func _fail_bool(message: String) -> bool:
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("[TestPveStatusFirePulse] ERROR %s" % message)
	get_tree().quit(1)
