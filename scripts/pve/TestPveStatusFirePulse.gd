extends Node

const PveCombatEventQueueScript = preload("res://scripts/pve/PveCombatEventQueue.gd")
const PveStatusRuntimeScript = preload("res://scripts/pve/PveStatusRuntime.gd")
const PvePulseRuntimeScript = preload("res://scripts/pve/PvePulseRuntime.gd")
const PveCardEffectAdapterScript = preload("res://scripts/pve/PveCardEffectAdapter.gd")
const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"


func _ready() -> void:
	if not _test_event_queue_fifo():
		return
	if not _test_event_depth():
		return
	if not _test_event_max_guard():
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
	if not await _test_battle_scene_fire_pulse_chain():
		return
	if not await _test_real_effect_play_paths():
		return
	if not await _test_owner_turn_end_lifecycle_paths():
		return
	if not await _test_enemy_fire_intent_execution():
		return
	if not await _test_restart_clears_combat_runtime():
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


func _test_event_max_guard() -> bool:
	var queue = PveCombatEventQueueScript.new()
	for i in range(PveCombatEventQueueScript.MAX_EVENTS_PER_DRAIN + 1):
		var result: Dictionary = queue.enqueue("guard")
		if not bool(result.get("ok", false)):
			return _fail_bool("event max guard setup should enqueue")
	var drained: Dictionary = queue.drain(func(_event: Dictionary) -> void:
		pass
	)
	if bool(drained.get("ok", false)):
		return _fail_bool("event queue should reject drains beyond max event guard")
	if int(drained.get("processed", 0)) != PveCombatEventQueueScript.MAX_EVENTS_PER_DRAIN:
		return _fail_bool("event queue max guard should process exactly max events")
	queue.reset()
	if queue.get_pending_count() != 0 or not queue.get_history().is_empty() or queue.is_processing():
		return _fail_bool("event queue reset should clear max guard state")
	if not bool(queue.enqueue("after_max_reset").get("ok", false)):
		return _fail_bool("event queue should be reusable after max guard reset")
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
	if adapter.get_validation_errors(_effect_card({"type": "add_pulse_buildup", "pulse_id": "fire", "value": 1, "target": "ghost"})).is_empty():
		return _fail_bool("adapter should reject illegal pulse target")
	if adapter.get_validation_errors(_effect_card({"type": "apply_status", "status_id": "zhuomai", "stacks": 1, "target": "ghost"})).is_empty():
		return _fail_bool("adapter should reject illegal status target")
	if adapter.get_validation_errors(_effect_card({"type": "deal_damage", "value": 1, "target": "self"})).is_empty():
		return _fail_bool("adapter should reject self deal_damage")
	if adapter.get_validation_errors(_effect_card({"type": "summon", "target": "enemy", "summon_id": "bad", "attack": 1, "life": 1, "side": "neutral", "dao_tags": [], "chengdao_kind": "neutral_beast", "death_destination": "discard", "is_special": false})).is_empty():
		return _fail_bool("adapter should reject enemy summon")

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


func _test_battle_scene_fire_pulse_chain() -> bool:
	var scene: Node = await _boot_battle_scene()
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	_prepare_scene_for_fire_test(scene, player)

	var enemy_target := str(scene.call("_get_enemy_target_id"))
	scene.call("_apply_pulse_buildup", enemy_target, "fire", 10, "test")
	var status_runtime = scene.get("pve_status_runtime")
	var pulse_runtime = scene.get("pve_pulse_runtime")
	if int(status_runtime.get_status(enemy_target, "zhuomai").get("stacks", 0)) != 3:
		return _cleanup_scene_fail(scene, "fire break should apply 3 zhuomai")
	if pulse_runtime.get_buildup(enemy_target, "fire") != 0:
		return _cleanup_scene_fail(scene, "fire break should consume threshold")

	scene.get("enemy")["block"] = 1
	var before_enemy_life := int(scene.get("enemy").get("life", 0))
	scene.call("_process_owner_turn_end_statuses", "enemy")
	if int(scene.get("enemy").get("life", 0)) != before_enemy_life - 2:
		return _cleanup_scene_fail(scene, "enemy zhuomai should damage after block")
	if int(status_runtime.get_status(enemy_target, "zhuomai").get("stacks", 0)) != 2:
		return _cleanup_scene_fail(scene, "enemy zhuomai should decay")

	var player_target := str(scene.call("_get_player_target_id"))
	scene.call("_apply_pulse_buildup", player_target, "fire", 25, "test")
	if pulse_runtime.get_buildup(player_target, "fire") != 5:
		return _cleanup_scene_fail(scene, "player fire overflow should remain 5")
	if int(status_runtime.get_status(player_target, "zhuomai").get("stacks", 0)) != 5:
		return _cleanup_scene_fail(scene, "two fire breaks should stack zhuomai to 5")

	player.formation_value = 2
	var before_player_life := int(player.life_source)
	scene.call("_process_owner_turn_end_statuses", "player")
	if int(player.life_source) != before_player_life - 3:
		return _cleanup_scene_fail(scene, "player zhuomai should damage through formation")
	if int(status_runtime.get_status(player_target, "zhuomai").get("stacks", 0)) != 4:
		return _cleanup_scene_fail(scene, "player zhuomai should decay")

	var full_pulse := int(scene.call("_calculate_attack_pulse_amount", 4, {"life_damage": 0, "defense_broken": true}, false))
	var half_pulse := int(scene.call("_calculate_attack_pulse_amount", 5, {"life_damage": 0, "defense_broken": false}, false))
	var conductive_pulse := int(scene.call("_calculate_attack_pulse_amount", 5, {"life_damage": 0, "defense_broken": false}, true))
	if full_pulse != 4 or half_pulse != 2 or conductive_pulse != 5:
		return _cleanup_scene_fail(scene, "attack pulse scaling should follow defense/life/conductive rules")

	scene.get("enemy")["turn_index"] = 1
	scene.call("_set_enemy_intent")
	if str(scene.get("enemy").get("intent", "")) != "fire_attack":
		return _cleanup_scene_fail(scene, "enemy second intent should be fire_attack")

	scene.call("_start_pve_battle")
	await get_tree().process_frame
	if scene.get("pve_status_runtime").has_status(player_target, "zhuomai"):
		return _cleanup_scene_fail(scene, "restart should clear status runtime")
	if scene.get("pve_pulse_runtime").get_buildup(player_target, "fire") != 0:
		return _cleanup_scene_fail(scene, "restart should clear pulse runtime")
	_cleanup_scene(scene)
	return true


func _test_real_effect_play_paths() -> bool:
	var scene: Node = await _boot_battle_scene()
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	_prepare_scene_for_fire_test(scene, player)
	var enemy_target := str(scene.call("_get_enemy_target_id"))
	var player_target := str(scene.call("_get_player_target_id"))
	var pulse_runtime = scene.get("pve_pulse_runtime")
	var status_runtime = scene.get("pve_status_runtime")

	var enemy_pulse_card := _test_daofa_card("test_enemy_fire", [{"type": "add_pulse_buildup", "pulse_id": "fire", "value": 4, "target": "enemy"}], "enemy")
	if not _play_test_card(scene, player, enemy_pulse_card, "enemy"):
		return _cleanup_scene_fail(scene, "enemy add pulse card should play through enemy target")
	if pulse_runtime.get_buildup(enemy_target, "fire") != 4 or player.hand.size() != 0 or scene.get("discard_pile").size() != 1:
		return _cleanup_scene_fail(scene, "enemy add pulse should move hand to discard and add fire")

	_prepare_scene_for_fire_test(scene, player)
	scene.call("_apply_pulse_buildup", player_target, "fire", 8, "setup")
	var self_reduce_card := _test_daofa_card("test_self_reduce_fire", [{"type": "reduce_pulse_buildup", "pulse_id": "fire", "value": 3, "target": "self"}], "self")
	if not _play_test_card(scene, player, self_reduce_card, "self"):
		return _cleanup_scene_fail(scene, "self reduce pulse card should play through central battlefield")
	if pulse_runtime.get_buildup(player_target, "fire") != 5:
		return _cleanup_scene_fail(scene, "self reduce pulse should lower player fire 8 to 5")

	_prepare_scene_for_fire_test(scene, player)
	var status_card := _test_daofa_card("test_apply_zhuomai", [{"type": "apply_status", "status_id": "zhuomai", "stacks": 2, "target": "enemy"}], "enemy")
	if not _play_test_card(scene, player, status_card, "enemy"):
		return _cleanup_scene_fail(scene, "apply_status card should play through enemy target")
	var status: Dictionary = status_runtime.get_status(enemy_target, "zhuomai")
	if int(status.get("stacks", 0)) != 2 or str(status.get("display_name", "")) != "灼脉":
		return _cleanup_scene_fail(scene, "apply_status should use stacks and display zhuomai")
	if int(status.get("max_stacks", 0)) != 6 or str(status.get("tick_timing", "")) != "owner_turn_end":
		return _cleanup_scene_fail(scene, "zhuomai should be normalized")
	for required_tag in ["pulse", "fire", "damage_over_time"]:
		if not (status.get("tags", []) as Array).has(required_tag):
			return _cleanup_scene_fail(scene, "zhuomai missing normalized tag %s" % required_tag)
	var status_card_big := _test_daofa_card("test_apply_zhuomai_big", [{"type": "apply_status", "status_id": "zhuomai", "stacks": 5, "target": "enemy"}], "enemy")
	if not _play_test_card(scene, player, status_card_big, "enemy"):
		return _cleanup_scene_fail(scene, "second apply_status card should play")
	if int(status_runtime.get_status(enemy_target, "zhuomai").get("stacks", 0)) != 6:
		return _cleanup_scene_fail(scene, "zhuomai should clamp to 6")

	_prepare_scene_for_fire_test(scene, player)
	var mixed_card := _test_daofa_card("test_mixed_enemy_self", [
		{"type": "deal_damage", "value": 3, "target": "enemy"},
		{"type": "gain_formation", "value": 4, "target": "self"}
	], "enemy")
	var before_life := int(scene.get("enemy").get("life", 0))
	if not _play_test_card(scene, player, mixed_card, "enemy"):
		return _cleanup_scene_fail(scene, "mixed enemy/self card should play through enemy target")
	if int(scene.get("enemy").get("life", 0)) != before_life - 3 or player.formation_value != 4:
		return _cleanup_scene_fail(scene, "mixed card should resolve damage and formation in order")

	_prepare_scene_for_fire_test(scene, player)
	var before_daoxi := int(scene.call("_get_current_daoxi", player))
	var illegal_card := _test_daofa_card("test_illegal_target", [{"type": "add_pulse_buildup", "pulse_id": "fire", "value": 5, "target": "ghost"}], "enemy")
	player.hand.append(illegal_card)
	scene.set("selected_card", illegal_card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_enemy_target_pressed")
	if player.hand.size() != 1 or int(scene.call("_get_current_daoxi", player)) != before_daoxi:
		return _cleanup_scene_fail(scene, "illegal target should not spend or move hand card")
	if pulse_runtime.get_buildup(enemy_target, "fire") != 0 or not scene.get("discard_pile").is_empty() or not scene.get("exhaust_pile").is_empty():
		return _cleanup_scene_fail(scene, "illegal target should not mutate piles or pulse")
	_cleanup_scene(scene)
	return true


func _test_owner_turn_end_lifecycle_paths() -> bool:
	var scene: Node = await _boot_battle_scene()
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	_prepare_scene_for_fire_test(scene, player)
	scene.get("passive_runtime").setup_fallback(scene, "songgui", "送归", "test")
	scene.get("passive_runtime").reset_for_battle()
	var source_card := _test_summon_card("test_burn_beast_source", "summon_burn_beast", 1, 3)
	if not _play_test_card(scene, player, source_card, "self"):
		return _cleanup_scene_fail(scene, "summon source should play")
	var beast: Dictionary = scene.get("player_boards")[0].get_card("chengdao", 0)
	if beast.is_empty():
		return _cleanup_scene_fail(scene, "summoned beast should occupy slot 0")
	var beast_target := str(scene.call("_get_beast_target_id", beast))
	scene.call("_apply_combat_status", beast_target, {"status_id": "zhuomai", "stacks": 4, "source_id": "test"})
	scene.call("_apply_pulse_buildup", beast_target, "fire", 4, "test")
	scene.call("_process_owner_turn_end_statuses", "player")
	if not scene.get("player_boards")[0].get_card("chengdao", 0).is_empty():
		return _cleanup_scene_fail(scene, "burning should defeat beast and clear board slot")
	if scene.get("pve_beast_runtime").get_active_source_count() != 0:
		return _cleanup_scene_fail(scene, "beast source registry should be empty after death")
	if scene.get("discard_pile").size() != 1 or not is_same(scene.get("discard_pile")[0], source_card):
		return _cleanup_scene_fail(scene, "ordinary beast death should return same source card object to discard")
	if scene.get("pve_status_runtime").has_status(beast_target, "zhuomai") or scene.get("pve_pulse_runtime").get_buildup(beast_target, "fire") != 0:
		return _cleanup_scene_fail(scene, "beast status and pulse should clear on death")
	if not bool(scene.get("passive_runtime").songgui_triggered_this_battle) or not bool(scene.get("passive_runtime").songgui_pending_reward):
		return _cleanup_scene_fail(scene, "songgui should trigger once on beast death")
	scene.call("_notify_chengdao_beast_died", 0, beast)
	if not bool(scene.get("passive_runtime").songgui_triggered_this_battle) or not bool(scene.get("passive_runtime").songgui_pending_reward):
		return _cleanup_scene_fail(scene, "songgui state should remain triggered after duplicate notify")

	_prepare_scene_for_fire_test(scene, player)
	var source_a := _test_summon_card("test_slot_a", "summon_slot_a", 1, 3)
	var source_b := _test_summon_card("test_slot_b", "summon_slot_b", 1, 3)
	if not _play_test_card(scene, player, source_a, "self"):
		return _cleanup_scene_fail(scene, "slot order summon A should play")
	if not _play_test_card(scene, player, source_b, "self"):
		return _cleanup_scene_fail(scene, "slot order summon B should play")
	var board = scene.get("player_boards")[0]
	var beast_b: Dictionary = board.remove_card("chengdao", 1)
	board.place_card("chengdao", 2, beast_b)
	var beast_a: Dictionary = board.get_card("chengdao", 0)
	var target_a := str(scene.call("_get_beast_target_id", beast_a))
	var target_b := str(scene.call("_get_beast_target_id", beast_b))
	scene.call("_apply_combat_status", target_a, {"status_id": "zhuomai", "stacks": 4})
	scene.call("_apply_combat_status", target_b, {"status_id": "zhuomai", "stacks": 4})
	scene.get("pve_event_queue").reset()
	scene.call("_process_owner_turn_end_statuses", "player")
	var tick_targets: Array[String] = []
	for event in scene.get("pve_event_queue").get_history():
		if str((event as Dictionary).get("event_type", "")) == "status_tick":
			tick_targets.append(str(((event as Dictionary).get("payload", {}) as Dictionary).get("target_id", "")))
	if tick_targets.size() < 2 or tick_targets[0] != target_a or tick_targets[1] != target_b:
		return _cleanup_scene_fail(scene, "status ticks should follow stable slot order 0 then 2")

	_prepare_scene_for_fire_test(scene, player)
	var enemy_target := str(scene.call("_get_enemy_target_id"))
	scene.call("_apply_pulse_buildup", enemy_target, "fire", 4, "setup")
	scene.call("_apply_combat_status", enemy_target, {"status_id": "zhuomai", "stacks": 2})
	scene.get("pve_event_queue").reset()
	scene.call("_process_owner_turn_end_statuses", "enemy")
	if scene.get("pve_pulse_runtime").get_buildup(enemy_target, "fire") != 4:
		return _cleanup_scene_fail(scene, "zhuomai tick should not add fire pulse")
	for event in scene.get("pve_event_queue").get_history():
		if str((event as Dictionary).get("event_type", "")) == "pulse_break_triggered":
			return _cleanup_scene_fail(scene, "zhuomai tick should not trigger pulse break")

	_prepare_scene_for_fire_test(scene, player)
	var player_target := str(scene.call("_get_player_target_id"))
	player.life_source = 2
	var enemy_turn_index := int(scene.get("enemy").get("turn_index", 0))
	var turn_number := int(scene.get("game_state").turn_number)
	scene.call("_apply_combat_status", player_target, {"status_id": "zhuomai", "stacks": 3})
	scene.call("_finish_end_turn", player)
	if not bool(scene.get("game_over")) or player.life_source > 0:
		return _cleanup_scene_fail(scene, "player burning death should end battle")
	if int(scene.get("enemy").get("turn_index", 0)) != enemy_turn_index or int(scene.get("game_state").turn_number) != turn_number:
		return _cleanup_scene_fail(scene, "player burning death should block enemy action and new turn")

	_prepare_scene_for_fire_test(scene, player)
	var enemy_target_dead := str(scene.call("_get_enemy_target_id"))
	scene.get("enemy")["life"] = 2
	scene.get("enemy")["intent"] = "wait"
	var turn_before_enemy_death := int(scene.get("game_state").turn_number)
	scene.call("_apply_combat_status", enemy_target_dead, {"status_id": "zhuomai", "stacks": 3})
	scene.call("_run_enemy_turn", player)
	if not bool(scene.get("game_over")) or int(scene.get("enemy").get("life", 0)) > 0:
		return _cleanup_scene_fail(scene, "enemy burning death should end battle")
	if int(scene.get("game_state").turn_number) != turn_before_enemy_death:
		return _cleanup_scene_fail(scene, "enemy burning death should not start a new player turn")

	_prepare_scene_for_fire_test(scene, player)
	player.life_source = 1
	scene.get("enemy")["life"] = 1
	scene.get("enemy")["intent"] = "attack"
	scene.get("enemy")["intent_value"] = 5
	scene.call("_apply_combat_status", str(scene.call("_get_enemy_target_id")), {"status_id": "zhuomai", "stacks": 3})
	scene.call("_run_enemy_turn", player)
	if not bool(scene.get("game_over")) or player.life_source > 0:
		return _cleanup_scene_fail(scene, "enemy direct lethal attack should end battle")
	if int(scene.get("enemy").get("life", 0)) != 1:
		return _cleanup_scene_fail(scene, "enemy should not tick own burning after directly killing player")

	_cleanup_scene(scene)
	return true


func _test_enemy_fire_intent_execution() -> bool:
	var scene: Node = await _boot_battle_scene()
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	_prepare_scene_for_fire_test(scene, player)
	scene.get("enemy")["intent"] = "fire_attack"
	scene.get("enemy")["intent_value"] = 5
	scene.get("enemy")["pulse_value"] = 5
	scene.get("enemy")["conductive"] = false
	var intent_text := str(scene.call("_enemy_intent_text"))
	if intent_text.find("火脉攻击") < 0 or intent_text.find("非传导") < 0:
		return _cleanup_scene_fail(scene, "fire intent text should show fire attack and non-conductive")
	player.formation_value = 10
	scene.call("_run_enemy_turn", player)
	var player_target := str(scene.call("_get_player_target_id"))
	if scene.get("pve_pulse_runtime").get_buildup(player_target, "fire") != 2:
		return _cleanup_scene_fail(scene, "blocked non-conductive fire attack should add half pulse")

	_prepare_scene_for_fire_test(scene, player)
	scene.get("enemy")["intent"] = "fire_attack"
	scene.get("enemy")["intent_value"] = 5
	scene.get("enemy")["pulse_value"] = 5
	scene.get("enemy")["conductive"] = false
	player.formation_value = 5
	scene.call("_run_enemy_turn", player)
	if scene.get("pve_pulse_runtime").get_buildup(player_target, "fire") != 5:
		return _cleanup_scene_fail(scene, "exact formation break should add full pulse")

	_prepare_scene_for_fire_test(scene, player)
	scene.get("enemy")["intent"] = "fire_attack"
	scene.get("enemy")["intent_value"] = 5
	scene.get("enemy")["pulse_value"] = 5
	scene.get("enemy")["conductive"] = false
	player.formation_value = 0
	scene.call("_run_enemy_turn", player)
	if scene.get("pve_pulse_runtime").get_buildup(player_target, "fire") != 5:
		return _cleanup_scene_fail(scene, "life damage should add full pulse")

	_prepare_scene_for_fire_test(scene, player)
	scene.get("enemy")["intent"] = "fire_attack"
	scene.get("enemy")["intent_value"] = 5
	scene.get("enemy")["pulse_value"] = 5
	scene.get("enemy")["conductive"] = true
	intent_text = str(scene.call("_enemy_intent_text"))
	if intent_text.find("传导") < 0 or intent_text.find("非传导") >= 0:
		return _cleanup_scene_fail(scene, "fire intent text should show conductive dynamically")
	player.formation_value = 10
	scene.call("_run_enemy_turn", player)
	if scene.get("pve_pulse_runtime").get_buildup(player_target, "fire") != 5:
		return _cleanup_scene_fail(scene, "conductive blocked fire attack should add full pulse")
	_cleanup_scene(scene)
	return true


func _test_restart_clears_combat_runtime() -> bool:
	var scene: Node = await _boot_battle_scene()
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	_prepare_scene_for_fire_test(scene, player)
	var source_card := _test_summon_card("test_restart_source", "summon_restart", 1, 3)
	if not _play_test_card(scene, player, source_card, "self"):
		return _cleanup_scene_fail(scene, "restart summon should play")
	var beast: Dictionary = scene.get("player_boards")[0].get_card("chengdao", 0)
	var beast_target := str(scene.call("_get_beast_target_id", beast))
	var player_target := str(scene.call("_get_player_target_id"))
	var enemy_target := str(scene.call("_get_enemy_target_id"))
	scene.get("pve_event_queue").enqueue("history_seed")
	scene.get("pve_event_queue").drain(func(_event: Dictionary) -> void:
		pass
	)
	scene.get("pve_event_queue").enqueue("pending_seed")
	scene.call("_apply_pulse_buildup", player_target, "fire", 4, "restart")
	scene.call("_apply_pulse_buildup", enemy_target, "fire", 4, "restart")
	scene.call("_apply_combat_status", beast_target, {"status_id": "zhuomai", "stacks": 2})
	scene.call("_start_pve_battle")
	await get_tree().process_frame
	if scene.get("pve_event_queue").get_pending_count() != 0 or not scene.get("pve_event_queue").get_history().is_empty():
		return _cleanup_scene_fail(scene, "restart should clear pending and history events")
	if scene.get("pve_pulse_runtime").get_buildup(player_target, "fire") != 0 or scene.get("pve_pulse_runtime").get_buildup(enemy_target, "fire") != 0:
		return _cleanup_scene_fail(scene, "restart should clear old pulse targets")
	if scene.get("pve_status_runtime").has_status(beast_target, "zhuomai"):
		return _cleanup_scene_fail(scene, "restart should clear old status targets")
	if scene.get("pve_beast_runtime").get_active_source_count() != 0 or not scene.get("player_boards")[0].get_card("chengdao", 0).is_empty():
		return _cleanup_scene_fail(scene, "restart should clear beast registry and battlefield")
	var new_player = scene.get("game_state").players[0]
	var total_cards: int = new_player.hand.size() + scene.get("draw_pile").size() + scene.get("discard_pile").size() + scene.get("exhaust_pile").size()
	if total_cards != 12:
		return _cleanup_scene_fail(scene, "restart should preserve 12-card battle deck total")
	_cleanup_scene(scene)
	return true


func _boot_battle_scene():
	var packed_scene: PackedScene = load(BATTLE_SCENE_PATH)
	if packed_scene == null:
		return null
	var scene: Node = packed_scene.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func _prepare_scene_for_fire_test(scene: Node, player) -> void:
	player.hand.clear()
	player.formation_value = 0
	player.life_source = player.max_life_source
	scene.get("draw_pile").clear()
	scene.get("discard_pile").clear()
	scene.get("exhaust_pile").clear()
	scene.get("enemy")["life"] = 80
	scene.get("enemy")["block"] = 0
	scene.get("enemy")["turn_index"] = 0
	scene.get("enemy")["intent"] = "attack"
	scene.get("enemy")["intent_value"] = 12
	scene.get("enemy")["pulse_id"] = ""
	scene.get("enemy")["pulse_value"] = 0
	scene.get("enemy")["conductive"] = false
	scene.set("game_over", false)
	scene.set("selected_card", {})
	scene.set("selected_card_source", "")
	scene.set("selected_attacker", {"player_index": -1, "slot_index": -1})
	if scene.get("passive_runtime") != null:
		scene.get("passive_runtime").setup_fallback(scene, "", "", "")
		scene.get("passive_runtime").reset_for_battle()
	for board in scene.get("player_boards"):
		board.reset_board()
	if scene.get("pve_beast_runtime") != null:
		scene.get("pve_beast_runtime").reset()
	if scene.get("pve_event_queue") != null:
		scene.get("pve_event_queue").reset()
	if scene.get("pve_status_runtime") != null:
		scene.get("pve_status_runtime").reset()
	if scene.get("pve_pulse_runtime") != null:
		scene.get("pve_pulse_runtime").reset()
	var stats: Dictionary = scene.get("extra_stats").get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = 99
	stats["return_tide"] = 0
	scene.get("extra_stats")[player.id] = stats


func _test_daofa_card(card_id: String, effects: Array, target_type: String = "enemy") -> Dictionary:
	return {
		"id": card_id,
		"instance_id": "%s_instance" % card_id,
		"name": card_id,
		"card_type": "daofa",
		"type": "daofa",
		"cost": 0,
		"target_type": target_type,
		"implementation_phase": "phase_1_base",
		"data_version": "pve_v1",
		"keywords": [],
		"effects": effects.duplicate(true)
	}


func _test_summon_card(card_id: String, summon_id: String, attack: int, life: int) -> Dictionary:
	return _test_daofa_card(card_id, [{
		"type": "summon",
		"target": "self",
		"summon_id": summon_id,
		"attack": attack,
		"life": life,
		"side": "neutral",
		"dao_tags": ["test"],
		"chengdao_kind": "neutral_beast",
		"death_destination": "discard",
		"is_special": false
	}], "self")


func _play_test_card(scene: Node, player, card: Dictionary, target_mode: String) -> bool:
	player.hand.append(card)
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	if target_mode == "enemy":
		scene.call("_on_enemy_target_pressed")
	else:
		scene.call("_on_central_battlefield_pressed")
	return player.hand.find(card) < 0


func _cleanup_scene(scene: Node) -> void:
	remove_child(scene)
	scene.queue_free()


func _cleanup_scene_fail(scene: Node, message: String) -> bool:
	_cleanup_scene(scene)
	return _fail_bool(message)


func _fail_bool(message: String) -> bool:
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("[TestPveStatusFirePulse] ERROR %s" % message)
	get_tree().quit(1)
