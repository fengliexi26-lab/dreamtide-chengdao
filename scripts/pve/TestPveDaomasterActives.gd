extends Node

const ActiveRuntimeScript = preload("res://scripts/pve/PveDaomasterActiveRuntime.gd")
const PvePulseRuntimeScript = preload("res://scripts/pve/PvePulseRuntime.gd")


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


func _fail_bool(message: String) -> bool:
	push_error("[TestPveDaomasterActives] %s" % message)
	get_tree().quit(1)
	return false
