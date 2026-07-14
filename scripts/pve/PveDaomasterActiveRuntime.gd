class_name PveDaomasterActiveRuntime
extends RefCounted

const MAX_POWER := 3
const START_POWER := 1
const ACTIVE_COST := 3

const SKILL_FENGMAI_JIEYUE := "fengmai_jieyue"
const SKILL_YEFU_CANSHI := "yefu_canshi"
const SKILL_FUGUAN_DAISHOU := "fuguan_daishou"

var daomaster_id := ""
var passive_id := ""
var daomaster_name := ""
var power := START_POWER
var gained_this_turn := false
var active_used_this_turn := false

var fengmai_guard_active := false
var fengmai_hengyin_eligible := false
var yefu_deferred_active := false
var yefu_unlock_block_turn := false
var yefu_lock_next_turn := false
var fuguan_marked_beast_id := ""
var fuguan_mark_triggered := false
var yugu_eligible := false


func setup(p_daomaster_id: String, p_passive_id: String, p_daomaster_name: String) -> void:
	daomaster_id = p_daomaster_id
	passive_id = p_passive_id
	daomaster_name = p_daomaster_name


func reset_for_battle() -> void:
	power = START_POWER
	gained_this_turn = false
	active_used_this_turn = false
	fengmai_guard_active = false
	fengmai_hengyin_eligible = false
	yefu_deferred_active = false
	yefu_unlock_block_turn = false
	yefu_lock_next_turn = false
	fuguan_marked_beast_id = ""
	fuguan_mark_triggered = false
	yugu_eligible = false


func begin_player_turn() -> Dictionary:
	gained_this_turn = false
	active_used_this_turn = false
	var expired := {
		"fengmai_guard_expired": fengmai_guard_active,
		"yefu_should_resolve": yefu_deferred_active,
		"fuguan_mark_expired": fuguan_marked_beast_id != "",
		"yefu_lock_cleared": yefu_unlock_block_turn
	}
	fengmai_guard_active = false
	fuguan_marked_beast_id = ""
	if yefu_deferred_active:
		yefu_deferred_active = false
		yefu_unlock_block_turn = true
	elif yefu_unlock_block_turn:
		yefu_unlock_block_turn = false
	if yefu_lock_next_turn:
		yefu_unlock_block_turn = true
		yefu_lock_next_turn = false
	return expired


func try_gain_power(source_id: String) -> Dictionary:
	if power >= MAX_POWER:
		return _gain_result(false, "道主势已达上限。", source_id, power, power)
	if gained_this_turn:
		return _gain_result(false, "本回合已经获得过道主势。", source_id, power, power)
	var before := power
	power = mini(MAX_POWER, power + 1)
	gained_this_turn = true
	return _gain_result(true, "", source_id, before, power)


func can_spend_for_active() -> Dictionary:
	if active_used_this_turn:
		return {"ok": false, "reason": "本回合已使用主动技能。"}
	if power < ACTIVE_COST:
		return {"ok": false, "reason": "道主势不足：需要 %d，当前 %d。" % [ACTIVE_COST, power]}
	return {"ok": true, "reason": ""}


func spend_for_active() -> Dictionary:
	var check := can_spend_for_active()
	if not bool(check.get("ok", false)):
		return {
			"ok": false,
			"reason": str(check.get("reason", "")),
			"cost": ACTIVE_COST,
			"before": power,
			"after": power
		}
	var before := power
	power -= ACTIVE_COST
	active_used_this_turn = true
	return {"ok": true, "reason": "", "cost": ACTIVE_COST, "before": before, "after": power}


func activate_fengmai_guard() -> void:
	fengmai_guard_active = true


func consume_fengmai_guard(incoming_amount: int) -> Dictionary:
	if not fengmai_guard_active or incoming_amount <= 0:
		return {"consumed": false, "before": incoming_amount, "after": incoming_amount, "reduced": 0, "fully_blocked": false}
	var after := maxi(0, incoming_amount - 4)
	fengmai_guard_active = false
	if after == 0:
		fengmai_hengyin_eligible = true
	return {
		"consumed": true,
		"before": incoming_amount,
		"after": after,
		"reduced": incoming_amount - after,
		"fully_blocked": after == 0
	}


func can_use_yefu(player_fire_buildup: int) -> Dictionary:
	var spend_check := can_spend_for_active()
	if not bool(spend_check.get("ok", false)):
		return spend_check
	if player_fire_buildup <= 0:
		return {"ok": false, "reason": "当前没有可封存的火脉。"}
	if yefu_deferred_active:
		return {"ok": false, "reason": "夜覆残世已经在封存火脉。"}
	if yefu_unlock_block_turn:
		return {"ok": false, "reason": "夜覆残世解除后的当前回合不能再次封存。"}
	return {"ok": true, "reason": ""}


func activate_yefu() -> void:
	yefu_deferred_active = true
	yefu_unlock_block_turn = false


func mark_yefu_lock_after_resolution() -> void:
	yefu_lock_next_turn = true


func can_use_fuguan(player_fire_buildup: int, has_beast: bool) -> Dictionary:
	var spend_check := can_spend_for_active()
	if not bool(spend_check.get("ok", false)):
		return spend_check
	if player_fire_buildup <= 0:
		return {"ok": false, "reason": "当前没有可转移的火脉。"}
	if not has_beast:
		return {"ok": false, "reason": "场上没有可承受火脉的承道兽。"}
	return {"ok": true, "reason": ""}


func mark_fuguan_beast(beast_instance_id: String) -> void:
	fuguan_marked_beast_id = beast_instance_id


func on_marked_beast_died(beast_instance_id: String) -> bool:
	if beast_instance_id == "" or beast_instance_id != fuguan_marked_beast_id:
		return false
	fuguan_marked_beast_id = ""
	fuguan_mark_triggered = true
	yugu_eligible = true
	return true


func get_power() -> int:
	return power


func get_max_power() -> int:
	return MAX_POWER


func get_active_cost() -> int:
	return ACTIVE_COST


func get_skill_id() -> String:
	match passive_id:
		"hengjie":
			return SKILL_FENGMAI_JIEYUE
		"liuxiao":
			return SKILL_YEFU_CANSHI
		"songgui":
			return SKILL_FUGUAN_DAISHOU
		_:
			return ""


func get_skill_name() -> String:
	match get_skill_id():
		SKILL_FENGMAI_JIEYUE:
			return "封脉界约"
		SKILL_YEFU_CANSHI:
			return "夜覆残世"
		SKILL_FUGUAN_DAISHOU:
			return "负棺代受"
		_:
			return "道主主动"


func get_skill_description() -> String:
	match get_skill_id():
		SKILL_FENGMAI_JIEYUE:
			return "获得 6 点阵势，下一次玩家火脉积蓄 -4。"
		SKILL_YEFU_CANSHI:
			return "暂缓玩家火脉失衡至下个玩家回合开始，并先减少 3 点火脉。"
		SKILL_FUGUAN_DAISHOU:
			return "选择己方承道兽，将最多 5 点玩家火脉转移给它。"
		_:
			return ""


func get_target_mode() -> String:
	return "beast" if get_skill_id() == SKILL_FUGUAN_DAISHOU else "none"


func is_active_used_this_turn() -> bool:
	return active_used_this_turn


func get_visible_state_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("道主势：%d / %d" % [power, MAX_POWER])
	lines.append("主动技能：%s" % get_skill_name())
	if fengmai_guard_active:
		lines.append("界约：下一次火脉 -4")
	if yefu_deferred_active:
		lines.append("夜覆：火脉失衡暂缓")
	if yefu_unlock_block_turn:
		lines.append("夜覆：本回合无法再次封存")
	if fuguan_marked_beast_id != "":
		lines.append("代受：已标记 %s" % fuguan_marked_beast_id)
	return lines


func _gain_result(ok: bool, reason: String, source_id: String, before: int, after: int) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"source_id": source_id,
		"before": before,
		"after": after
	}
