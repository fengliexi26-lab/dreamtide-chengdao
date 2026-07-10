extends Node

const DAOMASTER_DATA_PATH := "res://data/daomasters/daomasters_v0.json"
const STARTER_DECK_PATH := "res://data/decks/pve/starter_zaiheng.json"
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const RunStateScript = preload("res://scripts/pve/RunState.gd")

func _ready() -> void:
	var daomaster := _load_zaiheng()
	var starter_cards := _load_starter_cards()
	if daomaster.is_empty() or starter_cards.size() != 12:
		push_error("[TestPveTurnFlow] Failed to load test data.")
		get_tree().quit(1)
		return

	var run_state = RunStateScript.new()
	run_state.start_new(daomaster, starter_cards)
	RunStateScript.set_current(run_state)

	var packed_scene: PackedScene = load(BATTLE_SCENE_PATH)
	var scene: Node = packed_scene.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var game_state = scene.get("game_state")
	var player = game_state.players[0]
	if player.hand.size() != 5:
		_fail("opening hand should be 5, got %d" % player.hand.size())
		return
	if scene.get("draw_pile").size() != 7:
		_fail("draw pile should be 7 after opening draw, got %d" % scene.get("draw_pile").size())
		return
	if not _test_play_failure_keeps_card(scene, player):
		return
	if not _test_exhaust_card_goes_to_exhaust(scene, player):
		return
	if not _test_retain_card_stays_in_hand(scene, player):
		return

	scene.call("_finish_end_turn", player)
	await get_tree().process_frame
	await get_tree().process_frame

	if bool(scene.get("discard_phase")):
		_fail("PVE should not enter manual discard_phase.")
		return
	if player.hand.size() > 10:
		_fail("hand exceeded limit 10.")
		return
	if scene.get("discard_pile").size() <= 0:
		_fail("end turn should auto discard non-retain cards.")
		return

	var draw_pile: Array = scene.get("draw_pile")
	var discard_pile: Array = scene.get("discard_pile")
	draw_pile.clear()
	discard_pile.clear()
	discard_pile.append({"id": "test_shuffle_card", "name": "洗牌测试", "type": "daofa", "cost": 0})
	player.hand.clear()
	scene.call("_draw_cards", player, 1)
	await get_tree().process_frame
	if player.hand.size() != 1:
		_fail("draw should shuffle discard into draw pile when needed.")
		return

	print("[TestPveTurnFlow] PVE turn flow passed.")
	remove_child(scene)
	scene.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _test_play_failure_keeps_card(scene: Node, player) -> bool:
	player.hand.clear()
	scene.get("discard_pile").clear()
	scene.get("exhaust_pile").clear()
	var fail_card := {
		"id": "test_fail_daofa",
		"name": "失败测试道法",
		"type": "daofa",
		"cost": 99,
		"damage_tier": 0,
		"realm_requirement": 0
	}
	player.hand.append(fail_card)
	scene.set("selected_card", fail_card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_enemy_target_pressed")
	if player.hand.size() != 1:
		_fail("failed play should keep card in hand.")
		return false
	if scene.get("discard_pile").size() != 0 or scene.get("exhaust_pile").size() != 0:
		_fail("failed play should not enter discard/exhaust pile.")
		return false
	return true


func _test_exhaust_card_goes_to_exhaust(scene: Node, player) -> bool:
	player.hand.clear()
	scene.get("discard_pile").clear()
	scene.get("exhaust_pile").clear()
	var exhaust_card := {
		"id": "test_exhaust_daofa",
		"name": "消耗测试道法",
		"type": "daofa",
		"cost": 0,
		"damage_tier": 0,
		"realm_requirement": 0,
		"keywords": ["消耗"]
	}
	player.hand.append(exhaust_card)
	scene.set("selected_card", exhaust_card)
	scene.set("selected_card_source", "hand")
	scene.call("_on_enemy_target_pressed")
	if player.hand.size() != 0:
		_fail("successful exhaust card should leave hand.")
		return false
	if scene.get("exhaust_pile").size() != 1:
		_fail("successful exhaust card should enter exhaust pile.")
		return false
	if scene.get("discard_pile").size() != 0:
		_fail("exhaust card should not enter discard pile.")
		return false
	return true


func _test_retain_card_stays_in_hand(scene: Node, player) -> bool:
	player.hand.clear()
	scene.get("discard_pile").clear()
	scene.get("exhaust_pile").clear()
	var retain_card := {
		"id": "test_retain_card",
		"name": "凝梦测试牌",
		"type": "daofa",
		"cost": 0,
		"keywords": ["凝梦"]
	}
	var normal_card := {
		"id": "test_normal_card",
		"name": "普通测试牌",
		"type": "daofa",
		"cost": 0
	}
	player.hand.append(retain_card)
	player.hand.append(normal_card)
	scene.call("_end_pve_player_turn", player)
	if player.hand.size() != 1 or str(player.hand[0].get("id", "")) != "test_retain_card":
		_fail("retain card should remain in hand after end turn.")
		return false
	if scene.get("discard_pile").size() != 1:
		_fail("normal card should enter discard pile on end turn.")
		return false
	return true


func _fail(message: String) -> void:
	push_error("[TestPveTurnFlow] %s" % message)
	get_tree().quit(1)


func _load_zaiheng() -> Dictionary:
	var file: FileAccess = FileAccess.open(DAOMASTER_DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return {}
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == "zaiheng_jun":
			return item
	return {}


func _load_starter_cards() -> Array:
	var file: FileAccess = FileAccess.open(STARTER_DECK_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var deck: Dictionary = parsed
	return deck.get("cards", []).duplicate(true)
