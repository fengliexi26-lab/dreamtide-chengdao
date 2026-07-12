extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const DAOMASTER_DATA_PATH := "res://data/daomasters/daomasters_v0.json"
const V1_DECK_PATH := "res://data/decks/pve_v1/starter_zaiheng_v1.json"
const RunStateScript = preload("res://scripts/pve/RunState.gd")
const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")

const V1_DECKS := {
	"zaiheng_jun": "res://data/decks/pve_v1/starter_zaiheng_v1.json",
	"zhiye_jun": "res://data/decks/pve_v1/starter_zhiye_v1.json",
	"fuguan_seng": "res://data/decks/pve_v1/starter_fuguan_v1.json"
}

var catalog = PveCardV1CatalogScript.new()


func _ready() -> void:
	if not catalog.load_catalog():
		_fail("catalog failed: %s" % str(catalog.get_load_errors()))
		return
	if not await _test_all_daomaster_v1_boots():
		return
	if not await _test_v1_load_failure_blocks_fallback():
		return
	var scene: Node = await _boot_scene()
	if scene == null:
		return
	if not _test_v1_boot(scene):
		return
	if not _test_v1_damage(scene):
		return
	if not _test_v1_formation(scene):
		return
	if not _test_v1_exhaust(scene):
		return
	if not _test_v1_summon(scene):
		return
	if not _test_v1_failure_keeps_card(scene):
		return
	print("[TestPveCardV1BattleIntegration] all tests passed")
	get_tree().quit(0)


func _test_all_daomaster_v1_boots() -> bool:
	for daomaster_id in V1_DECKS.keys():
		var scene: Node = await _boot_scene_for(daomaster_id, str(V1_DECKS[daomaster_id]))
		if scene == null:
			return false
		var ok: bool = str(scene.get("pve_card_data_mode")) == "pve_v1"
		var player = scene.get("game_state").players[0]
		ok = ok and player.hand.size() == 5
		ok = ok and (player.hand.is_empty() or str(player.hand[0].get("data_version", "")) == "pve_v1")
		remove_child(scene)
		scene.queue_free()
		await get_tree().process_frame
		if not ok:
			return _fail_bool("%s should boot with pve_v1 deck and v1 hand" % daomaster_id)
		print("[TestPveCardV1Battle] %s v1 run passed" % daomaster_id)
	return true


func _test_v1_load_failure_blocks_fallback() -> bool:
	var daomaster := _load_daomaster("zaiheng_jun")
	var run_state = RunStateScript.new()
	run_state.start_new(daomaster, ["missing_card"])
	run_state.enable_pve_card_v1("res://data/decks/pve_v1/missing_v1.json", ["missing_card"])
	RunStateScript.set_current(run_state)
	var packed_scene: PackedScene = load(BATTLE_SCENE_PATH)
	var scene: Node = packed_scene.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var ok := str(scene.get("pve_card_data_mode")) == "pve_v1_error" and bool(scene.get("game_over"))
	remove_child(scene)
	scene.queue_free()
	await get_tree().process_frame
	if not ok:
		return _fail_bool("invalid v1 RunState should block battle and must not silently fallback")
	print("[TestPveCardV1Battle] v1 load failure passed")
	return true


func _boot_scene():
	return await _boot_scene_for("zaiheng_jun", V1_DECK_PATH)


func _boot_scene_for(daomaster_id: String, deck_path: String):
	var daomaster := _load_daomaster(daomaster_id)
	if daomaster.is_empty():
		_fail("missing %s daomaster" % daomaster_id)
		return null
	var deck_result: Dictionary = catalog.load_starter_deck(deck_path, daomaster_id, daomaster)
	if not bool(deck_result.get("ok", false)):
		_fail("%s should load: %s" % [deck_path, str(deck_result.get("errors", []))])
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


func _test_v1_boot(scene: Node) -> bool:
	if str(scene.get("pve_card_data_mode")) != "pve_v1":
		return _fail_bool("BattleScene should use pve_v1 mode, got %s" % str(scene.get("pve_card_data_mode")))
	var game_state = scene.get("game_state")
	if game_state == null:
		return _fail_bool("BattleScene did not create game_state")
	var player = game_state.players[0]
	if player.hand.size() != 5:
		return _fail_bool("opening hand should be 5, got %d" % player.hand.size())
	if not player.hand.is_empty() and str(player.hand[0].get("data_version", "")) != "pve_v1":
		return _fail_bool("opening hand should contain v1 instances")
	var total: int = player.hand.size() + scene.get("draw_pile").size() + scene.get("discard_pile").size() + scene.get("exhaust_pile").size()
	if total != 12:
		return _fail_bool("v1 starter deck total should be 12, got %d" % total)
	return true


func _test_v1_damage(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_for_card_test(scene, player)
	var card := _instance("universal_breaking_style")
	player.hand.append(card)
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	var enemy: Dictionary = scene.get("enemy")
	var before_life := int(enemy.get("life", 0))
	scene.call("_on_enemy_target_pressed")
	enemy = scene.get("enemy")
	if int(enemy.get("life", 0)) != before_life - 7:
		return _fail_bool("deal_damage should reduce enemy life by 7")
	if player.hand.size() != 0:
		return _fail_bool("successful v1 damage card should leave hand")
	if scene.get("discard_pile").size() != 1:
		return _fail_bool("successful v1 damage card should enter discard")
	return true


func _test_v1_formation(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_for_card_test(scene, player)
	var card := _instance("universal_body_guard")
	player.hand.append(card)
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_central_battlefield_pressed")
	if player.formation_value < 6:
		return _fail_bool("gain_formation should grant at least 6 formation")
	if player.hand.size() != 0 or scene.get("discard_pile").size() != 1:
		return _fail_bool("formation card should leave hand and enter discard")
	return true


func _test_v1_exhaust(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_for_card_test(scene, player)
	var card := _instance("fuguan_wuzang_order")
	player.hand.append(card)
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_central_battlefield_pressed")
	if player.hand.size() != 0:
		return _fail_bool("exhaust card should leave hand")
	if scene.get("exhaust_pile").size() != 1:
		return _fail_bool("exhaust card should enter exhaust pile")
	if scene.get("discard_pile").size() != 0:
		return _fail_bool("exhaust card should not enter discard pile")
	return true


func _test_v1_summon(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_for_card_test(scene, player)
	var card := _instance("shared_order_jade_deer")
	player.hand.append(card)
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_central_battlefield_pressed")
	var board = scene.get("player_boards")[0]
	var beast: Dictionary = board.get_card(CardTypes.CHENGDAO, 0)
	if beast.is_empty():
		return _fail_bool("summon should create a battlefield chengdao beast")
	if int(beast.get("attack_value", 0)) != 3 or int(beast.get("current_life", 0)) != 11:
		return _fail_bool("summon beast stats should match summon_data")
	if player.hand.size() != 0:
		return _fail_bool("summon card should leave hand")
	if scene.get("discard_pile").size() != 0 or scene.get("exhaust_pile").size() != 0:
		return _fail_bool("v1 summon card body should not immediately enter discard/exhaust pile")
	if scene.get("pve_beast_runtime") == null or scene.get("pve_beast_runtime").get_active_source_count() != 1:
		return _fail_bool("v1 summon source card should be registered while beast is on battlefield")
	return true


func _test_v1_failure_keeps_card(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_for_card_test(scene, player)
	var card := _instance("universal_breaking_style")
	card["cost"] = 100
	player.hand.append(card)
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_enemy_target_pressed")
	if player.hand.size() != 1:
		return _fail_bool("failed v1 play should keep card in hand")
	if scene.get("discard_pile").size() != 0 or scene.get("exhaust_pile").size() != 0:
		return _fail_bool("failed v1 play should not enter piles")
	return true


func _reset_for_card_test(scene: Node, player) -> void:
	player.hand.clear()
	player.formation_value = 0
	scene.get("draw_pile").clear()
	scene.get("discard_pile").clear()
	scene.get("exhaust_pile").clear()
	if scene.get("pve_beast_runtime") != null:
		scene.get("pve_beast_runtime").reset()
	scene.set("selected_card", {})
	scene.set("selected_card_source", "")
	scene.set("selected_attacker", {"player_index": -1, "slot_index": -1})
	var stats: Dictionary = scene.get("extra_stats").get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = 99
	stats["return_tide"] = 0
	scene.get("extra_stats")[player.id] = stats
	var boards: Array = scene.get("player_boards")
	for board in boards:
		board.reset_board()
	scene.set("enemy", {
		"id": "test_enemy",
		"name": "测试敌人",
		"max_life": 80,
		"life": 80,
		"intent": "attack",
		"intent_value": 12,
		"block": 0,
		"turn_index": 0
	})


func _instance(card_id: String) -> Dictionary:
	var instances: Array = catalog.build_battle_instances([card_id])
	return instances[0] if not instances.is_empty() else {}


func _load_daomaster(daomaster_id: String) -> Dictionary:
	var file := FileAccess.open(DAOMASTER_DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return {}
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == daomaster_id:
			return item
	return {}


func _fail_bool(message: String) -> bool:
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("[TestPveCardV1BattleIntegration] ERROR %s" % message)
	get_tree().quit(1)
