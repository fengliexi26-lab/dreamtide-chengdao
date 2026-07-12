extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const DAOMASTER_DATA_PATH := "res://data/daomasters/daomasters_v0.json"
const V1_DECK_PATH := "res://data/decks/pve_v1/starter_zaiheng_v1.json"
const RunStateScript = preload("res://scripts/pve/RunState.gd")
const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")

var catalog = PveCardV1CatalogScript.new()


func _ready() -> void:
	if not catalog.load_catalog():
		_fail("catalog failed: %s" % str(catalog.get_load_errors()))
		return
	var scene: Node = await _boot_scene()
	if scene == null:
		return
	if not _test_ordinary_source_returns_to_discard(scene):
		return
	if not _test_battlefield_beast_is_lightweight(scene):
		return
	if not _test_advanced_source_returns_to_exhaust(scene):
		return
	if not _test_token_vanishes(scene):
		return
	if not _test_board_capacity(scene):
		return
	if not _test_three_ordinary_and_fourth_fails(scene):
		return
	if not _test_advanced_limit_reason(scene):
		return
	if not _test_token_capacity(scene):
		return
	if not _test_duplicate_source_registration(scene):
		return
	if not _test_duplicate_source_preflight_keeps_state(scene):
		return
	if not await _test_real_starter_deck_conservation(scene):
		return
	if not _test_death_notification_once(scene):
		return
	if not _test_beast_action_points(scene):
		return
	if not await _test_restart_isolation(scene):
		return
	print("[TestPveBeastLifecycle] all tests passed")
	get_tree().quit(0)


func _boot_scene():
	var daomaster := _load_daomaster("zaiheng_jun")
	if daomaster.is_empty():
		_fail("missing zaiheng_jun daomaster")
		return null
	var deck_result: Dictionary = catalog.load_starter_deck(V1_DECK_PATH, "zaiheng_jun", daomaster)
	if not bool(deck_result.get("ok", false)):
		_fail("starter deck should load: %s" % str(deck_result.get("errors", [])))
		return null
	var run_state = RunStateScript.new()
	run_state.start_new(daomaster, deck_result.get("card_ids", []))
	run_state.enable_pve_card_v1(V1_DECK_PATH, deck_result.get("card_ids", []))
	RunStateScript.set_current(run_state)

	var packed_scene: PackedScene = load(BATTLE_SCENE_PATH)
	var scene: Node = packed_scene.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func _test_ordinary_source_returns_to_discard(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var card := _instance("shared_order_jade_deer")
	player.hand.append(card)
	_play_selected(scene, card)
	var board = scene.get("player_boards")[0]
	var beast: Dictionary = board.get_card(CardTypes.CHENGDAO, 0)
	if beast.is_empty():
		return _fail_bool("ordinary summon should place a beast")
	if str(beast.get("beast_rank", "")) != "ordinary" or int(beast.get("board_cost", 0)) != 1:
		return _fail_bool("ordinary beast should default to rank ordinary and board cost 1")
	if scene.get("pve_beast_runtime").get_active_source_count() != 1:
		return _fail_bool("ordinary beast source should be registered")
	if _tracked_card_total(scene, player) != 1:
		return _fail_bool("summoned source card should have exactly one active home")
	var source_id := str(card.get("instance_id", ""))
	scene.call("_damage_pve_beast", 0, 0, 999)
	if scene.get("discard_pile").size() != 1:
		return _fail_bool("ordinary beast death should move source card to discard")
	if not is_same(scene.get("discard_pile")[0], card):
		return _fail_bool("ordinary beast death should return the same source object")
	if str(scene.get("discard_pile")[0].get("instance_id", "")) != source_id:
		return _fail_bool("ordinary beast death should return the original source instance")
	if scene.get("pve_beast_runtime").get_active_source_count() != 0:
		return _fail_bool("ordinary beast death should release source registry")
	if _tracked_card_total(scene, player) != 1:
		return _fail_bool("defeated source card should still have exactly one home")
	return true


func _test_battlefield_beast_is_lightweight(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var card := _instance("shared_order_jade_deer")
	player.hand.append(card)
	_play_selected(scene, card)
	var beast: Dictionary = scene.get("player_boards")[0].get_card(CardTypes.CHENGDAO, 0)
	for required in ["beast_instance_id", "source_card_instance_id", "beast_rank", "board_cost", "death_destination", "action_points", "action_points_remaining"]:
		if not beast.has(required):
			return _fail_bool("battlefield beast missing lightweight field: %s" % required)
	for forbidden in ["effects", "runtime_state", "summon_data", "implementation_phase"]:
		if beast.has(forbidden):
			return _fail_bool("battlefield beast should not contain source field: %s" % forbidden)
	if is_same(beast, card):
		return _fail_bool("battlefield beast must not be the source card object")
	var registered: Dictionary = scene.get("pve_beast_runtime").active_beast_card_instances.get(str(beast.get("beast_instance_id", "")), {})
	if not is_same(registered, card):
		return _fail_bool("registry should keep the original hand card object")
	return true


func _test_advanced_source_returns_to_exhaust(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var card := _instance("shared_order_jade_deer")
	card["beast_rank"] = "advanced"
	player.hand.append(card)
	_play_selected(scene, card)
	var beast: Dictionary = scene.get("player_boards")[0].get_card(CardTypes.CHENGDAO, 0)
	if str(beast.get("beast_rank", "")) != "advanced" or int(beast.get("board_cost", 0)) != 2:
		return _fail_bool("advanced beast should cost 2 board capacity")
	scene.call("_damage_pve_beast", 0, 0, 999)
	if scene.get("exhaust_pile").size() != 1:
		return _fail_bool("advanced beast death should move source card to exhaust")
	if scene.get("discard_pile").size() != 0:
		return _fail_bool("advanced beast death should not move source card to discard")
	return true


func _test_token_vanishes(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var runtime = scene.get("pve_beast_runtime")
	var token: Dictionary = runtime.normalize_beast_metadata({}, {
		"summon_id": "test_token",
		"name": "测试衍生兽",
		"attack": 1,
		"life": 1,
		"side": "neutral",
		"chengdao_kind": "token_beast",
		"dao_tags": []
	}, {"beast_rank": "token"})
	token["beast_instance_id"] = runtime.create_beast_instance_id()
	scene.get("player_boards")[0].place_card(CardTypes.CHENGDAO, 0, token)
	scene.call("_damage_pve_beast", 0, 0, 999)
	if scene.get("discard_pile").size() != 0 or scene.get("exhaust_pile").size() != 0:
		return _fail_bool("token beast death should not enter discard or exhaust")
	if runtime.get_active_source_count() != 0:
		return _fail_bool("token beast should not register source card")
	return true


func _test_board_capacity(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var advanced := _instance("shared_order_jade_deer")
	advanced["beast_rank"] = "advanced"
	var ordinary_a := _instance("universal_roaming_spirit_hound")
	var ordinary_b := _instance("shared_order_jade_deer")
	player.hand.append(advanced)
	player.hand.append(ordinary_a)
	player.hand.append(ordinary_b)
	_play_selected(scene, advanced)
	_play_selected(scene, ordinary_a)
	_play_selected(scene, ordinary_b)
	var runtime = scene.get("pve_beast_runtime")
	var board: BoardView = scene.get("player_boards")[0]
	if runtime.get_used_capacity(board.get_cards_in_slots(CardTypes.CHENGDAO)) != 3:
		return _fail_bool("advanced + ordinary should use exactly 3 board capacity")
	if player.hand.size() != 1:
		return _fail_bool("third summon over capacity should remain in hand")
	if runtime.get_active_source_count() != 2:
		return _fail_bool("only successful summons should be registered")
	return true


func _test_three_ordinary_and_fourth_fails(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var cards := [
		_instance("shared_order_jade_deer"),
		_instance("universal_roaming_spirit_hound"),
		_instance("shared_order_jade_deer"),
		_instance("universal_roaming_spirit_hound")
	]
	for card in cards:
		player.hand.append(card)
	var before_daoxi := _current_daoxi(scene, player)
	_play_selected(scene, cards[0])
	_play_selected(scene, cards[1])
	_play_selected(scene, cards[2])
	var after_three_daoxi := _current_daoxi(scene, player)
	_play_selected(scene, cards[3])
	var runtime = scene.get("pve_beast_runtime")
	if runtime.get_used_capacity(scene.get("player_boards")[0].get_cards_in_slots(CardTypes.CHENGDAO)) != 3:
		return _fail_bool("three ordinary beasts should use 3 capacity")
	if runtime.get_active_source_count() != 3:
		return _fail_bool("three ordinary beasts should register three sources")
	if player.hand.size() != 1 or not is_same(player.hand[0], cards[3]):
		return _fail_bool("fourth ordinary beast should remain in hand")
	if _current_daoxi(scene, player) != after_three_daoxi:
		return _fail_bool("fourth failed summon should not spend daoxi")
	if before_daoxi - after_three_daoxi != 3:
		return _fail_bool("first three summons should spend exactly three daoxi in this test")
	return true


func _test_advanced_limit_reason(scene: Node) -> bool:
	var runtime = scene.get("pve_beast_runtime")
	runtime.reset()
	var first := _instance("shared_order_jade_deer")
	first["beast_rank"] = "advanced"
	var first_meta: Dictionary = runtime.normalize_beast_metadata(first, _summon_spec_for(first))
	first_meta["beast_instance_id"] = runtime.create_beast_instance_id()
	var second := _instance("universal_roaming_spirit_hound")
	second["beast_rank"] = "advanced"
	var second_meta: Dictionary = runtime.normalize_beast_metadata(second, _summon_spec_for(second))
	var result: Dictionary = runtime.validate_summon([first_meta], second_meta)
	if bool(result.get("ok", false)):
		return _fail_bool("second advanced beast should fail validation")
	if str(result.get("reason", "")).find("高阶承道兽") < 0:
		return _fail_bool("second advanced beast should fail with advanced limit reason")
	return true


func _test_token_capacity(scene: Node) -> bool:
	var runtime = scene.get("pve_beast_runtime")
	runtime.reset()
	var token_spec := {
		"summon_id": "test_token",
		"name": "测试衍生兽",
		"attack": 1,
		"life": 1,
		"side": "neutral",
		"chengdao_kind": "token_beast",
		"dao_tags": []
	}
	var token: Dictionary = runtime.normalize_beast_metadata({}, token_spec, {"beast_rank": "token", "board_cost": 0})
	if int(token.get("board_cost", 0)) != 1:
		return _fail_bool("token board cost should normalize to 1")
	var full_board := [token.duplicate(true), token.duplicate(true), token.duplicate(true)]
	var result: Dictionary = runtime.validate_summon(full_board, token)
	if bool(result.get("ok", false)):
		return _fail_bool("token should fail when board capacity is already full")
	if runtime.get_active_source_count() != 0:
		return _fail_bool("token validation should not mutate registry")
	return true


func _test_duplicate_source_registration(scene: Node) -> bool:
	var runtime = scene.get("pve_beast_runtime")
	runtime.reset()
	var card := _instance("shared_order_jade_deer")
	var first: Dictionary = runtime.register_source_card("beast-a", card)
	var duplicate_source: Dictionary = runtime.register_source_card("beast-b", card)
	var duplicate_beast: Dictionary = runtime.register_source_card("beast-a", _instance("universal_roaming_spirit_hound"))
	if not bool(first.get("ok", false)):
		return _fail_bool("first source registration should pass")
	if bool(duplicate_source.get("ok", false)):
		return _fail_bool("duplicate source instance registration should fail")
	if bool(duplicate_beast.get("ok", false)):
		return _fail_bool("duplicate beast id registration should fail")
	if runtime.get_active_source_count() != 1:
		return _fail_bool("failed duplicate registration should not mutate registry")
	return true


func _test_duplicate_source_preflight_keeps_state(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var card := _instance("shared_order_jade_deer")
	player.hand.append(card)
	var runtime = scene.get("pve_beast_runtime")
	runtime.register_source_card("already-active", card)
	var before_daoxi := _current_daoxi(scene, player)
	var before_hand: int = player.hand.size()
	_play_selected(scene, card)
	if _current_daoxi(scene, player) != before_daoxi:
		return _fail_bool("duplicate source preflight should not spend daoxi")
	if player.hand.size() != before_hand or not is_same(player.hand[0], card):
		return _fail_bool("duplicate source preflight should keep hand unchanged")
	if runtime.get_active_source_count() != 1:
		return _fail_bool("duplicate source preflight should not add registry entries")
	if not scene.get("player_boards")[0].get_card(CardTypes.CHENGDAO, 0).is_empty():
		return _fail_bool("duplicate source preflight should not place a beast")
	return true


func _test_real_starter_deck_conservation(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	scene.call("_start_pve_battle")
	await get_tree().process_frame
	player = scene.get("game_state").players[0]
	if _tracked_card_total(scene, player) != 12:
		return _fail_bool("real starter deck total should be 12 at battle start")
	var summon_index := _find_summon_card_index(player.hand)
	if summon_index < 0:
		for i in range(10):
			scene.call("_draw_pve_cards", player, 1)
			summon_index = _find_summon_card_index(player.hand)
			if summon_index >= 0:
				break
	if summon_index < 0:
		var draw_pile: Array = scene.get("draw_pile")
		var draw_index := _find_summon_card_index(draw_pile)
		if draw_index >= 0:
			var moved_card: Dictionary = draw_pile[draw_index]
			draw_pile.remove_at(draw_index)
			player.hand.append(moved_card)
			summon_index = player.hand.size() - 1
	if summon_index < 0:
		return _fail_bool("test starter deck should provide a summon card")
	var card: Dictionary = player.hand[summon_index]
	_play_selected(scene, card)
	if _tracked_card_total(scene, player) != 12:
		return _fail_bool("real starter deck total should remain 12 after summon")
	scene.call("_damage_pve_beast", 0, 0, 999)
	if _tracked_card_total(scene, player) != 12:
		return _fail_bool("real starter deck total should remain 12 after beast death")
	scene.call("_shuffle_discard_into_draw_pile")
	if _tracked_card_total(scene, player) != 12:
		return _fail_bool("real starter deck total should remain 12 after discard shuffle")
	return true


func _test_death_notification_once(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var passive = scene.get("passive_runtime")
	if passive != null:
		passive.songgui_triggered_this_battle = false
		passive.songgui_pending_reward = false
	var card := _instance("shared_order_jade_deer")
	player.hand.append(card)
	_play_selected(scene, card)
	scene.call("_damage_pve_beast", 0, 0, 999)
	var discard_count: int = scene.get("discard_pile").size()
	var registry_count: int = scene.get("pve_beast_runtime").get_active_source_count()
	var pending := bool(passive.songgui_pending_reward) if passive != null else false
	scene.call("_damage_pve_beast", 0, 0, 999)
	if scene.get("discard_pile").size() != discard_count:
		return _fail_bool("second death call on empty slot should not add discard")
	if scene.get("pve_beast_runtime").get_active_source_count() != registry_count:
		return _fail_bool("second death call on empty slot should not mutate registry")
	if passive != null and bool(passive.songgui_pending_reward) != pending:
		return _fail_bool("second death call should not trigger passive again")
	return true


func _test_beast_action_points(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var card := _instance("shared_order_jade_deer")
	player.hand.append(card)
	_play_selected(scene, card)
	var enemy: Dictionary = scene.get("enemy")
	var before := int(enemy.get("life", 0))
	scene.call("_basic_attack_with_beast_to_enemy", player, 0)
	var after_first := int(scene.get("enemy").get("life", 0))
	if after_first >= before:
		return _fail_bool("beast attack should damage enemy")
	scene.call("_basic_attack_with_beast_to_enemy", player, 0)
	var after_second := int(scene.get("enemy").get("life", 0))
	if after_second != after_first:
		return _fail_bool("beast should not attack twice in one turn")
	var beast: Dictionary = scene.get("player_boards")[0].get_card(CardTypes.CHENGDAO, 0)
	if int(beast.get("action_points_remaining", -1)) != 0 or not bool(beast.get("has_attacked", false)):
		return _fail_bool("beast attack should consume action point")
	scene.get("player_boards")[0].reset_beast_actions()
	beast = scene.get("player_boards")[0].get_card(CardTypes.CHENGDAO, 0)
	if int(beast.get("action_points_remaining", 0)) != int(beast.get("action_points", 1)):
		return _fail_bool("beast action points should reset")
	return true


func _test_restart_isolation(scene: Node) -> bool:
	var player = scene.get("game_state").players[0]
	_reset_scene(scene, player)
	var old_card := _instance("shared_order_jade_deer")
	player.hand.append(old_card)
	_play_selected(scene, old_card)
	var old_beast: Dictionary = scene.get("player_boards")[0].get_card(CardTypes.CHENGDAO, 0)
	if old_beast.is_empty() or scene.get("pve_beast_runtime").get_active_source_count() != 1:
		return _fail_bool("restart setup should place one active beast")
	scene.call("_start_pve_battle")
	await get_tree().process_frame
	player = scene.get("game_state").players[0]
	if scene.get("pve_beast_runtime").get_active_source_count() != 0:
		return _fail_bool("restart should clear source registry")
	if not scene.get("player_boards")[0].get_card(CardTypes.CHENGDAO, 0).is_empty():
		return _fail_bool("restart should clear battlefield beasts")
	if _tracked_card_total(scene, player) != 12:
		return _fail_bool("restart should rebuild a 12 card deck")
	if scene.get("discard_pile").size() != 0 or scene.get("exhaust_pile").size() != 0:
		return _fail_bool("old battlefield beast should not enter new discard or exhaust piles")
	for card in player.hand:
		if is_same(card, old_card):
			return _fail_bool("restart should create isolated card instances")
	return true


func _play_selected(scene: Node, card: Dictionary) -> void:
	scene.set("selected_card", card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_central_battlefield_pressed")


func _current_daoxi(scene: Node, player) -> int:
	var stats: Dictionary = scene.get("extra_stats").get(player.id, {"dao_breath": 0, "return_tide": 0})
	return int(stats.get("dao_breath", 0))


func _summon_spec_for(card: Dictionary) -> Dictionary:
	return scene_effect_adapter().get_summon_spec(card)


func scene_effect_adapter():
	return load("res://scripts/pve/PveCardEffectAdapter.gd").new()


func _find_summon_card_index(cards: Array) -> int:
	var adapter = scene_effect_adapter()
	for i in range(cards.size()):
		if typeof(cards[i]) == TYPE_DICTIONARY and not adapter.get_summon_spec(cards[i]).is_empty():
			return i
	return -1


func _reset_scene(scene: Node, player) -> void:
	player.hand.clear()
	player.formation_value = 0
	scene.get("draw_pile").clear()
	scene.get("discard_pile").clear()
	scene.get("exhaust_pile").clear()
	scene.get("pve_beast_runtime").reset()
	scene.set("selected_card", {})
	scene.set("selected_card_source", "")
	scene.set("selected_attacker", {"player_index": -1, "slot_index": -1})
	var stats: Dictionary = scene.get("extra_stats").get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = 99
	stats["return_tide"] = 0
	scene.get("extra_stats")[player.id] = stats
	for board in scene.get("player_boards"):
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


func _tracked_card_total(scene: Node, player) -> int:
	return player.hand.size() + scene.get("draw_pile").size() + scene.get("discard_pile").size() + scene.get("exhaust_pile").size() + scene.get("pve_beast_runtime").get_active_source_count()


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
	push_error("[TestPveBeastLifecycle] ERROR %s" % message)
	get_tree().quit(1)
