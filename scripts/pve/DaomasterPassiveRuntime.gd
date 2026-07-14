extends RefCounted
class_name DaomasterPassiveRuntime

var battle_scene: Node
var passive_id := ""
var passive_name := ""
var passive_desc := ""

var hengjie_used_this_turn := false
var songgui_triggered_this_battle := false
var songgui_pending_reward := false


func setup(p_battle_scene: Node, run_state) -> void:
	battle_scene = p_battle_scene
	if run_state == null:
		passive_id = ""
		passive_name = ""
		passive_desc = ""
		return
	passive_id = str(run_state.selected_passive_id)
	passive_name = str(run_state.selected_passive_name)
	passive_desc = str(run_state.selected_passive_desc)


func setup_fallback(p_battle_scene: Node, p_passive_id: String, p_passive_name: String, p_passive_desc: String) -> void:
	battle_scene = p_battle_scene
	passive_id = p_passive_id
	passive_name = p_passive_name
	passive_desc = p_passive_desc


func reset_for_battle() -> void:
	hengjie_used_this_turn = false
	songgui_triggered_this_battle = false
	songgui_pending_reward = false


func on_player_turn_start() -> void:
	hengjie_used_this_turn = false
	if passive_id != "songgui" or not songgui_pending_reward:
		return
	songgui_pending_reward = false
	if battle_scene == null:
		return
	battle_scene.add_current_daoxi(1, "送归")
	battle_scene._draw_cards(battle_scene.game_state.get_active_player(), 2)
	battle_scene._log("送归：额外获得 1 点道息并抽 2 张牌。")


func on_player_turn_end() -> void:
	if passive_id != "liuxiao" or battle_scene == null:
		return
	var player = battle_scene.game_state.get_active_player()
	var retain_count := 0
	for card in player.hand:
		if battle_scene._card_has_retain(card):
			retain_count += 1
	var gained := mini(retain_count, 3)
	if gained <= 0:
		return
	battle_scene.gain_formation(gained, "留宵", false)
	battle_scene._log("留宵：因保留 %d 张凝梦牌，获得 %d 点阵势。" % [retain_count, gained])
	if gained >= 2 and battle_scene.has_method("_on_daomaster_power_source"):
		battle_scene._on_daomaster_power_source("liuxiao")


func on_formation_gained(amount: int, source: String) -> void:
	if passive_id != "hengjie" or battle_scene == null:
		return
	if amount <= 0 or hengjie_used_this_turn:
		return
	hengjie_used_this_turn = true
	battle_scene.gain_formation(2, "衡界", false)
	battle_scene._log("衡界：额外获得 2 点阵势。")
	if battle_scene.has_method("_on_daomaster_power_source"):
		battle_scene._on_daomaster_power_source("hengjie")


func on_chengdao_beast_died(beast_data: Dictionary) -> void:
	if passive_id != "songgui":
		return
	if battle_scene != null and battle_scene.has_method("_on_daomaster_power_source"):
		battle_scene._on_daomaster_power_source("chengdao_death")
	if songgui_triggered_this_battle:
		return
	songgui_triggered_this_battle = true
	songgui_pending_reward = true
	if battle_scene != null:
		battle_scene._log("送归：承道兽已归，奖励将在下个玩家回合结算。")


func get_passive_name() -> String:
	return passive_name


func get_passive_description() -> String:
	return passive_desc


func get_debug_summary() -> String:
	return "PassiveRuntime: %s / %s | hengjie_used %s | songgui_triggered %s pending %s" % [
		passive_id,
		passive_name,
		str(hengjie_used_this_turn),
		str(songgui_triggered_this_battle),
		str(songgui_pending_reward)
	]
