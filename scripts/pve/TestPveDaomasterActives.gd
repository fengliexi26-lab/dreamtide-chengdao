extends Node

const ActiveRuntimeScript = preload("res://scripts/pve/PveDaomasterActiveRuntime.gd")
const PvePulseRuntimeScript = preload("res://scripts/pve/PvePulseRuntime.gd")
const RunStateScript = preload("res://scripts/pve/RunState.gd")
const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const DAOMASTER_DATA_PATH := "res://data/daomasters/daomasters_v0.json"
const V1_DECK_DIR := "res://data/decks/pve_v1/"

var catalog = PveCardV1CatalogScript.new()


func _ready() -> void:
	if not _test_power_basics():
		return
	if not _test_skill_metadata():
		return
	if not _test_fengmai_guard_state():
		return
	if not _test_yefu_state_machine():
		return
	if not _test_fuguan_mark_state():
		return
	if not _test_pulse_deferred_and_resolve():
		return
	if not catalog.load_catalog():
		return _fail_bool("catalog should load for battle integration tests")
	if not await _test_battle_hengjie_fengmai():
		return
	if not await _test_battle_zhiye_yefu():
		return
	if not await _test_battle_fuguan_daishou():
		return
	print("[TestPveDaomasterActives] all tests passed")
	get_tree().quit(0)


func _test_power_basics() -> bool:
	var runtime = ActiveRuntimeScript.new()
	runtime.setup("zaiheng_jun", "hengjie", "宰衡君")
	runtime.reset_for_battle()
	if runtime.get_power() != ActiveRuntimeScript.START_POWER:
		return _fail_bool("power should start at 1")
	if runtime.get_max_power() != 3 or runtime.get_active_cost() != 3:
		return _fail_bool("power max/cost should be 3")
	var first: Dictionary = runtime.try_gain_power("hengjie")
	if not bool(first.get("ok", false)) or runtime.get_power() != 2:
		return _fail_bool("first gain should increase power to 2")
	var second: Dictionary = runtime.try_gain_power("hengjie")
	if bool(second.get("ok", false)) or runtime.get_power() != 2:
		return _fail_bool("second same-turn gain should fail without changing power")
	runtime.begin_player_turn()
	var third: Dictionary = runtime.try_gain_power("hengjie")
	if not bool(third.get("ok", false)) or runtime.get_power() != 3:
		return _fail_bool("new turn should allow power gain to max")
	var capped: Dictionary = runtime.try_gain_power("hengjie")
	if bool(capped.get("ok", false)) or runtime.get_power() != 3:
		return _fail_bool("power should not exceed max")
	runtime.begin_player_turn()
	var still_capped: Dictionary = runtime.try_gain_power("hengjie")
	if bool(still_capped.get("ok", false)) or runtime.get_power() != 3:
		return _fail_bool("cap failure should not change power")
	var spend: Dictionary = runtime.spend_for_active()
	if not bool(spend.get("ok", false)) or runtime.get_power() != 0 or not runtime.is_active_used_this_turn():
		return _fail_bool("spend should consume 3 and mark active used")
	var repeat: Dictionary = runtime.spend_for_active()
	if bool(repeat.get("ok", false)) or runtime.get_power() != 0:
		return _fail_bool("same-turn active should not repeat")
	runtime.reset_for_battle()
	if runtime.get_power() != 1 or runtime.is_active_used_this_turn():
		return _fail_bool("restart should restore power and clear active usage")
	return true


func _test_skill_metadata() -> bool:
	var runtime = ActiveRuntimeScript.new()
	runtime.setup("zaiheng_jun", "hengjie", "宰衡君")
	if runtime.get_skill_id() != "fengmai_jieyue" or runtime.get_skill_name() != "封脉界约" or runtime.get_target_mode() != "none":
		return _fail_bool("hengjie should map to fengmai_jieyue")
	runtime.setup("zhiye_jun", "liuxiao", "织夜君")
	if runtime.get_skill_id() != "yefu_canshi" or runtime.get_skill_name() != "夜覆残世" or runtime.get_target_mode() != "none":
		return _fail_bool("liuxiao should map to yefu_canshi")
	runtime.setup("fuguan_seng", "songgui", "负棺僧")
	if runtime.get_skill_id() != "fuguan_daishou" or runtime.get_skill_name() != "负棺代受" or runtime.get_target_mode() != "beast":
		return _fail_bool("songgui should map to fuguan_daishou")
	return true


func _test_fengmai_guard_state() -> bool:
	var runtime = ActiveRuntimeScript.new()
	runtime.setup("zaiheng_jun", "hengjie", "宰衡君")
	runtime.reset_for_battle()
	runtime.activate_fengmai_guard()
	var reduced: Dictionary = runtime.consume_fengmai_guard(5)
	if not bool(reduced.get("consumed", false)) or int(reduced.get("after", -1)) != 1:
		return _fail_bool("fengmai should reduce next incoming pulse by 4")
	var second: Dictionary = runtime.consume_fengmai_guard(4)
	if bool(second.get("consumed", false)) or int(second.get("after", -1)) != 4:
		return _fail_bool("fengmai guard should only apply once")
	runtime.activate_fengmai_guard()
	var blocked: Dictionary = runtime.consume_fengmai_guard(2)
	if int(blocked.get("after", -1)) != 0 or not bool(runtime.fengmai_hengyin_eligible):
		return _fail_bool("fully blocked pulse should mark hengyin eligibility")
	runtime.activate_fengmai_guard()
	var expired: Dictionary = runtime.begin_player_turn()
	if not bool(expired.get("fengmai_guard_expired", false)) or bool(runtime.fengmai_guard_active):
		return _fail_bool("new turn should expire unused fengmai guard")
	return true


func _test_yefu_state_machine() -> bool:
	var runtime = ActiveRuntimeScript.new()
	runtime.setup("zhiye_jun", "liuxiao", "织夜君")
	runtime.reset_for_battle()
	if bool(runtime.can_use_yefu(0).get("ok", false)):
		return _fail_bool("yefu should require current player fire")
	runtime.try_gain_power("a")
	runtime.begin_player_turn()
	runtime.try_gain_power("b")
	var spend := runtime.spend_for_active()
	if not bool(spend.get("ok", false)):
		return _fail_bool("test setup should spend active")
	runtime.activate_yefu()
	if bool(runtime.can_use_yefu(8).get("ok", false)):
		return _fail_bool("yefu should not be reusable while deferred")
	var transition: Dictionary = runtime.begin_player_turn()
	if not bool(transition.get("yefu_should_resolve", false)) or not bool(runtime.yefu_unlock_block_turn):
		return _fail_bool("next turn should request yefu resolution and lock current turn")
	if bool(runtime.can_use_yefu(8).get("ok", false)):
		return _fail_bool("yefu unlock turn should block reuse")
	runtime.begin_player_turn()
	if bool(runtime.yefu_unlock_block_turn):
		return _fail_bool("following turn should clear yefu lock")
	return true


func _test_fuguan_mark_state() -> bool:
	var runtime = ActiveRuntimeScript.new()
	runtime.setup("fuguan_seng", "songgui", "负棺僧")
	runtime.reset_for_battle()
	if bool(runtime.can_use_fuguan(0, true).get("ok", false)):
		return _fail_bool("fuguan should require player fire")
	if bool(runtime.can_use_fuguan(5, false).get("ok", false)):
		return _fail_bool("fuguan should require a beast")
	runtime.mark_fuguan_beast("beast_a")
	if runtime.on_marked_beast_died("beast_b"):
		return _fail_bool("wrong beast should not trigger fuguan mark")
	if not runtime.on_marked_beast_died("beast_a") or not bool(runtime.fuguan_mark_triggered) or not bool(runtime.yugu_eligible):
		return _fail_bool("marked beast death should trigger fuguan state")
	runtime.mark_fuguan_beast("beast_c")
	var expired: Dictionary = runtime.begin_player_turn()
	if not bool(expired.get("fuguan_mark_expired", false)) or runtime.fuguan_marked_beast_id != "":
		return _fail_bool("new turn should expire fuguan mark")
	runtime.reset_for_battle()
	if runtime.fuguan_marked_beast_id != "" or bool(runtime.fuguan_mark_triggered):
		return _fail_bool("restart should clear fuguan mark state")
	return true


func _test_pulse_deferred_and_resolve() -> bool:
	var pulse = PvePulseRuntimeScript.new()
	var target := "player:p1"
	var deferred: Dictionary = pulse.add_buildup_deferred(target, "fire", 13)
	if not bool(deferred.get("ok", false)) or int(deferred.get("breaks", -1)) != 0:
		return _fail_bool("deferred buildup should not break")
	if pulse.get_buildup(target, "fire") != 13:
		return _fail_bool("deferred buildup should preserve raw 13")
	var resolved: Dictionary = pulse.resolve_thresholds(target, "fire")
	if int(resolved.get("breaks", -1)) != 1 or int(resolved.get("after", -1)) != 3:
		return _fail_bool("resolve should consume one threshold and keep overflow")
	var normal: Dictionary = pulse.add_buildup(target, "fire", 17)
	if int(normal.get("breaks", -1)) != 2 or int(normal.get("after", -1)) != 0:
		return _fail_bool("normal add should preserve existing immediate break behavior")
	if bool(pulse.add_buildup_deferred(target, "ice", 1).get("ok", false)):
		return _fail_bool("deferred should reject unsupported pulse")
	if bool(pulse.add_buildup_deferred(target, "fire", -1).get("ok", false)):
		return _fail_bool("deferred should reject negative amount")
	return true


func _test_battle_hengjie_fengmai() -> bool:
	var scene: Node = await _boot_battle_scene("zaiheng_jun")
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	var runtime = scene.get("daomaster_active_runtime")
	var pulse_runtime = scene.get("pve_pulse_runtime")
	player.formation_value = 0
	runtime.power = 3
	runtime.gained_this_turn = false
	scene.get("passive_runtime").hengjie_used_this_turn = false
	var enemy_life_before := int(scene.get("enemy").get("life", 0))
	scene.call("_on_dao_strike_pressed")
	if int(scene.get("enemy").get("life", 0)) != enemy_life_before:
		return _cleanup_scene_fail(scene, "normal v1 active button should not use old dao strike damage")
	if player.formation_value != 8:
		return _cleanup_scene_fail(scene, "fengmai should gain 6 formation plus hengjie 2")
	if runtime.get_power() != 1 or not runtime.is_active_used_this_turn():
		return _cleanup_scene_fail(scene, "fengmai should spend 3 then regain 1 through hengjie")
	runtime.power = 3
	var formation_after_first_active: int = player.formation_value
	scene.call("_on_dao_strike_pressed")
	if player.formation_value != formation_after_first_active or runtime.get_power() != 3:
		return _cleanup_scene_fail(scene, "same-turn active should be rejected even if power is restored")
	runtime.active_used_this_turn = false
	scene.set("is_resolving_v1_card", true)
	scene.call("_on_dao_strike_pressed")
	scene.set("is_resolving_v1_card", false)
	if runtime.get_power() != 3 or player.formation_value != formation_after_first_active:
		return _cleanup_scene_fail(scene, "resolving card lock should reject active without spending")
	runtime.power = 3
	runtime.active_used_this_turn = false
	runtime.gained_this_turn = true
	scene.get("passive_runtime").hengjie_used_this_turn = true
	scene.call("_apply_pulse_buildup", scene.call("_get_player_target_id"), "fire", 5, "test")
	if pulse_runtime.get_buildup(scene.call("_get_player_target_id"), "fire") != 1:
		return _cleanup_scene_fail(scene, "fengmai should reduce next player fire 5 to 1")
	scene.call("_apply_pulse_buildup", scene.call("_get_player_target_id"), "fire", 4, "test")
	if pulse_runtime.get_buildup(scene.call("_get_player_target_id"), "fire") != 5:
		return _cleanup_scene_fail(scene, "fengmai should only reduce one source")
	runtime.power = 3
	runtime.active_used_this_turn = false
	runtime.gained_this_turn = true
	scene.get("passive_runtime").hengjie_used_this_turn = true
	scene.call("_on_dao_strike_pressed")
	scene.call("_apply_pulse_buildup", scene.call("_get_player_target_id"), "fire", 2, "test")
	if not bool(runtime.fengmai_hengyin_eligible):
		return _cleanup_scene_fail(scene, "fully blocked pulse should mark hengyin eligibility")
	_cleanup_scene(scene)
	return true


func _test_battle_zhiye_yefu() -> bool:
	var scene: Node = await _boot_battle_scene("zhiye_jun")
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	var runtime = scene.get("daomaster_active_runtime")
	var pulse_runtime = scene.get("pve_pulse_runtime")
	var status_runtime = scene.get("pve_status_runtime")
	var player_target := str(scene.call("_get_player_target_id"))
	runtime.power = 3
	scene.call("_on_dao_strike_pressed")
	if runtime.get_power() != 3 or runtime.is_active_used_this_turn():
		return _cleanup_scene_fail(scene, "yefu with 0 fire should not spend active")
	scene.call("_apply_pulse_buildup", player_target, "fire", 8, "setup")
	scene.call("_on_dao_strike_pressed")
	if runtime.get_power() != 0 or not bool(runtime.yefu_deferred_active):
		return _cleanup_scene_fail(scene, "yefu should spend and enable deferred fire")
	scene.call("_apply_pulse_buildup", player_target, "fire", 5, "test")
	if pulse_runtime.get_buildup(player_target, "fire") != 13:
		return _cleanup_scene_fail(scene, "yefu should allow raw fire above threshold")
	if status_runtime.has_status(player_target, "zhuomai"):
		return _cleanup_scene_fail(scene, "yefu should not break while deferred")
	scene.call("_start_pve_player_turn", player, false)
	if pulse_runtime.get_buildup(player_target, "fire") != 0:
		return _cleanup_scene_fail(scene, "yefu start should reduce then resolve threshold")
	if int(status_runtime.get_status(player_target, "zhuomai").get("stacks", 0)) != 3:
		return _cleanup_scene_fail(scene, "yefu release should apply one zhuomai break")
	runtime.power = 3
	scene.call("_on_dao_strike_pressed")
	if runtime.get_power() != 3:
		return _cleanup_scene_fail(scene, "yefu lock turn should not spend")
	scene.call("_start_pve_player_turn", player, false)
	if bool(runtime.yefu_unlock_block_turn):
		return _cleanup_scene_fail(scene, "second new turn should clear yefu lock")
	_cleanup_scene(scene)
	return true


func _test_battle_fuguan_daishou() -> bool:
	var scene: Node = await _boot_battle_scene("fuguan_seng")
	if scene == null:
		return false
	var player = scene.get("game_state").players[0]
	var runtime = scene.get("daomaster_active_runtime")
	var pulse_runtime = scene.get("pve_pulse_runtime")
	var status_runtime = scene.get("pve_status_runtime")
	var player_target := str(scene.call("_get_player_target_id"))
	runtime.power = 3
	scene.call("_on_dao_strike_pressed")
	if scene.get("daomaster_active_target_mode") != "" or runtime.get_power() != 3:
		return _cleanup_scene_fail(scene, "fuguan with no fire/beast should not enter mode or spend")
	var card := _instance("fuguan_coffin_wisp")
	player.hand.clear()
	player.hand.append(card)
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_central_battlefield_pressed")
	var beast: Dictionary = scene.get("player_boards")[0].get_card("chengdao", 0)
	if beast.is_empty():
		return _cleanup_scene_fail(scene, "fuguan setup should summon a beast")
	var beast_target := str(scene.call("_get_beast_target_id", beast))
	scene.call("_apply_pulse_buildup", player_target, "fire", 8, "setup")
	scene.call("_apply_pulse_buildup", beast_target, "fire", 6, "setup")
	runtime.power = 3
	scene.call("_on_dao_strike_pressed")
	if scene.get("daomaster_active_target_mode") != "fuguan_beast_target" or runtime.get_power() != 3:
		return _cleanup_scene_fail(scene, "fuguan button should enter target mode without spending")
	scene.call("_on_battlefield_card_pressed", 0, "chengdao", 0)
	if runtime.get_power() != 0 or scene.get("daomaster_active_target_mode") != "":
		return _cleanup_scene_fail(scene, "fuguan target confirm should spend and exit mode")
	if pulse_runtime.get_buildup(player_target, "fire") != 3:
		return _cleanup_scene_fail(scene, "fuguan should reduce player fire by 5")
	if pulse_runtime.get_buildup(beast_target, "fire") != 1:
		return _cleanup_scene_fail(scene, "fuguan should transfer fire and resolve beast threshold")
	if int(status_runtime.get_status(beast_target, "zhuomai").get("stacks", 0)) != 3:
		return _cleanup_scene_fail(scene, "fuguan transferred fire should break on beast")
	if str(runtime.fuguan_marked_beast_id) != str(beast.get("beast_instance_id", "")):
		return _cleanup_scene_fail(scene, "fuguan should mark the selected beast")
	scene.call("_damage_pve_beast", 0, 0, 999)
	if not bool(runtime.fuguan_mark_triggered) or not bool(runtime.yugu_eligible):
		return _cleanup_scene_fail(scene, "marked beast death should record fuguan future yugu eligibility")
	if not bool(scene.get("passive_runtime").songgui_pending_reward):
		return _cleanup_scene_fail(scene, "marked beast death should still trigger songgui pending reward")
	var found_event := false
	for event in scene.get("pve_event_queue").get_history():
		if str((event as Dictionary).get("event_type", "")) == "fuguan_marked_beast_died":
			found_event = true
	if not found_event:
		return _cleanup_scene_fail(scene, "marked beast death event should be recorded")
	scene.call("_start_pve_battle")
	await get_tree().process_frame
	await get_tree().process_frame
	runtime = scene.get("daomaster_active_runtime")
	if runtime.get_power() != 1 or runtime.fuguan_marked_beast_id != "" or bool(runtime.fuguan_mark_triggered):
		return _cleanup_scene_fail(scene, "restart should clear fuguan active state")
	_cleanup_scene(scene)
	return true


func _boot_battle_scene(daomaster_id: String):
	var daomaster := _load_daomaster(daomaster_id)
	if daomaster.is_empty():
		return null
	var deck_path := "%sstarter_%s_v1.json" % [V1_DECK_DIR, daomaster_id.replace("_jun", "").replace("_seng", "")]
	if daomaster_id == "zaiheng_jun":
		deck_path = "%sstarter_zaiheng_v1.json" % V1_DECK_DIR
	elif daomaster_id == "zhiye_jun":
		deck_path = "%sstarter_zhiye_v1.json" % V1_DECK_DIR
	elif daomaster_id == "fuguan_seng":
		deck_path = "%sstarter_fuguan_v1.json" % V1_DECK_DIR
	var deck_result: Dictionary = catalog.load_starter_deck(deck_path, daomaster_id, daomaster)
	if not bool(deck_result.get("ok", false)):
		return null
	var run_state = RunStateScript.new()
	run_state.start_new(daomaster, deck_result.get("card_ids", []))
	run_state.enable_pve_card_v1(deck_path, deck_result.get("card_ids", []))
	RunStateScript.set_current(run_state)
	var packed_scene: PackedScene = load(BATTLE_SCENE_PATH)
	var scene: Node = packed_scene.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func _load_daomaster(daomaster_id: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(DAOMASTER_DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return {}
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == daomaster_id:
			return item
	return {}


func _instance(card_id: String) -> Dictionary:
	var instances := catalog.build_battle_instances([card_id])
	if instances.is_empty():
		_fail_bool("failed to create card instance: %s" % card_id)
		return {}
	return instances[0]


func _cleanup_scene(scene: Node) -> void:
	remove_child(scene)
	scene.queue_free()


func _cleanup_scene_fail(scene: Node, message: String) -> bool:
	_cleanup_scene(scene)
	return _fail_bool(message)


func _fail_bool(message: String) -> bool:
	push_error("[TestPveDaomasterActives] %s" % message)
	get_tree().quit(1)
	return false
