extends Node

const DAOMASTER_DATA_PATH := "res://data/daomasters/daomasters_v0.json"
const STARTER_DECK_DIR := "res://data/decks/pve/"
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const RunStateScript = preload("res://scripts/pve/RunState.gd")


func _ready() -> void:
	if not await _test_hengjie():
		return
	if not await _test_liuxiao():
		return
	if not await _test_songgui():
		return
	print("[TestDaomasterPassives] All passive tests passed.")
	get_tree().quit(0)


func _test_hengjie() -> bool:
	var scene = await _start_scene("zaiheng_jun")
	var player = _player(scene)
	player.formation_value = 0
	scene.call("gain_formation", 1, "test", true)
	if player.formation_value != 3:
		return _fail("hengjie first formation gain should become 3, got %d." % player.formation_value)
	scene.call("gain_formation", 1, "test", true)
	if player.formation_value != 4:
		return _fail("hengjie second same-turn formation gain should only add 1, got %d." % player.formation_value)
	scene.get("passive_runtime").on_player_turn_start()
	player.formation_value = 0
	scene.call("gain_formation", 1, "test", true)
	if player.formation_value != 3:
		return _fail("hengjie should reset on new player turn, got %d." % player.formation_value)
	_cleanup_scene(scene)
	return true


func _test_liuxiao() -> bool:
	var scene = await _start_scene("zhiye_jun")
	var player = _player(scene)
	if not _check_liuxiao_case(scene, player, 0, 0):
		return false
	if not _check_liuxiao_case(scene, player, 1, 1):
		return false
	if not _check_liuxiao_case(scene, player, 2, 2):
		return false
	if not _check_liuxiao_case(scene, player, 4, 3):
		return false
	_cleanup_scene(scene)
	return true


func _check_liuxiao_case(scene: Node, player, retain_count: int, expected_formation: int) -> bool:
	player.hand.clear()
	player.formation_value = 0
	scene.get("discard_pile").clear()
	for i in range(retain_count):
		player.hand.append({"id": "retain_%d" % i, "name": "凝梦测试%d" % i, "type": "daofa", "keywords": ["凝梦"]})
	player.hand.append({"id": "normal_for_liuxiao", "name": "普通测试牌", "type": "daofa"})
	scene.call("_end_pve_player_turn", player)
	if player.formation_value != expected_formation:
		return _fail("liuxiao retain %d should gain %d formation, got %d." % [retain_count, expected_formation, player.formation_value])
	if player.hand.size() != retain_count:
		return _fail("liuxiao should only keep retain cards, expected %d hand, got %d." % [retain_count, player.hand.size()])
	return true


func _test_songgui() -> bool:
	var scene = await _start_scene("fuguan_seng")
	var player = _player(scene)
	var runtime = scene.get("passive_runtime")
	player.hand.clear()
	for i in range(8):
		player.hand.append({"id": "hand_%d" % i, "name": "占位手牌%d" % i, "type": "daofa"})
	var draw_pile: Array = scene.get("draw_pile")
	draw_pile.clear()
	for i in range(5):
		draw_pile.append({"id": "draw_%d" % i, "name": "抽牌测试%d" % i, "type": "daofa", "cost": 0})
	var before_daoxi := _current_daoxi(scene, player)
	scene.call("_notify_chengdao_beast_died", 0, {"name": "送归测试兽"})
	if not bool(runtime.songgui_pending_reward):
		return _fail("songgui first own beast death should set pending reward.")
	scene.call("_notify_chengdao_beast_died", 0, {"name": "送归测试兽二"})
	if _current_daoxi(scene, player) != before_daoxi or player.hand.size() != 8:
		return _fail("songgui should not grant reward immediately during the death event.")
	scene.call("_start_pve_player_turn", player, false)
	if bool(runtime.songgui_pending_reward):
		return _fail("songgui pending reward should be consumed on next player turn.")
	if _current_daoxi(scene, player) != 4:
		return _fail("songgui should grant +1 daoxi after base restore, got %d." % _current_daoxi(scene, player))
	if player.hand.size() != 10:
		return _fail("songgui extra draw should respect hand limit 10, got %d." % player.hand.size())
	scene.call("_notify_chengdao_beast_died", 0, {"name": "送归测试兽三"})
	if bool(runtime.songgui_pending_reward):
		return _fail("songgui should only trigger once per battle.")
	scene.call("_start_pve_battle")
	await get_tree().process_frame
	await get_tree().process_frame
	runtime = scene.get("passive_runtime")
	scene.call("_notify_chengdao_beast_died", 0, {"name": "重启后送归测试兽"})
	if not bool(runtime.songgui_pending_reward):
		return _fail("songgui should reset after battle restart.")
	_cleanup_scene(scene)
	return true


func _start_scene(daomaster_id: String):
	var daomaster := _load_daomaster(daomaster_id)
	var starter_cards := _load_starter_cards(str(daomaster.get("starter_deck_id", "")))
	if daomaster.is_empty() or starter_cards.is_empty():
		_fail("failed to load daomaster or starter deck: %s." % daomaster_id)
		return null
	var run_state = RunStateScript.new()
	run_state.start_new(daomaster, starter_cards)
	RunStateScript.set_current(run_state)
	var packed_scene: PackedScene = load(BATTLE_SCENE_PATH)
	var scene: Node = packed_scene.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func _cleanup_scene(scene: Node) -> void:
	remove_child(scene)
	scene.queue_free()


func _player(scene: Node):
	return scene.get("game_state").players[0]


func _current_daoxi(scene: Node, player) -> int:
	var extra_stats: Dictionary = scene.get("extra_stats")
	var stats: Dictionary = extra_stats.get(player.id, {})
	return int(stats.get("dao_breath", 0))


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


func _load_starter_cards(starter_deck_id: String) -> Array:
	if starter_deck_id == "":
		return []
	var file: FileAccess = FileAccess.open("%s%s.json" % [STARTER_DECK_DIR, starter_deck_id], FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var deck_data: Dictionary = parsed
	return deck_data.get("cards", []).duplicate(true)


func _fail(message: String) -> bool:
	push_error("[TestDaomasterPassives] %s" % message)
	get_tree().quit(1)
	return false
