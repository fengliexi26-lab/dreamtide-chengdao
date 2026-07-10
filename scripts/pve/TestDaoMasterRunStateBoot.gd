extends Node

const DAOMASTER_DATA_PATH := "res://data/daomasters/daomasters_v0.json"
const STARTER_DECK_DIR := "res://data/decks/pve/"
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const RunStateScript = preload("res://scripts/pve/RunState.gd")

func _ready() -> void:
	var daomasters := _load_daomasters()
	var battle_scene: PackedScene = load(BATTLE_SCENE_PATH)
	if battle_scene == null:
		push_error("[TestDaoMasterRunStateBoot] Failed to load BattleScene.")
		get_tree().quit(1)
		return

	var checked := 0
	for daomaster in daomasters:
		if not bool(daomaster.get("unlocked", false)):
			continue
		var starter_cards := _load_starter_deck_cards(str(daomaster.get("starter_deck_id", "")))
		if starter_cards.size() != 12:
			push_error("[TestDaoMasterRunStateBoot] Invalid starter deck for %s." % str(daomaster.get("id", "")))
			get_tree().quit(1)
			return
		var run_state = RunStateScript.new()
		run_state.start_new(daomaster, starter_cards)
		if str(run_state.selected_passive_id) == "" or str(run_state.selected_passive_name) == "":
			push_error("[TestDaoMasterRunStateBoot] %s missing passive data in RunState." % str(daomaster.get("id", "")))
			get_tree().quit(1)
			return
		RunStateScript.set_current(run_state)
		var scene: Node = battle_scene.instantiate()
		add_child(scene)
		await get_tree().process_frame
		await get_tree().process_frame
		var game_state = scene.get("game_state")
		if game_state == null:
			push_error("[TestDaoMasterRunStateBoot] BattleScene did not create game_state.")
			get_tree().quit(1)
			return
		var player = game_state.players[0]
		var total_cards: int = player.hand.size() + scene.get("draw_pile").size() + scene.get("discard_pile").size() + scene.get("exhaust_pile").size()
		if total_cards != 12:
			push_error("[TestDaoMasterRunStateBoot] %s expected 12 run deck cards, got %d." % [str(daomaster.get("id", "")), total_cards])
			get_tree().quit(1)
			return
		if player.hand.size() != 5:
			push_error("[TestDaoMasterRunStateBoot] %s expected opening hand 5, got %d." % [str(daomaster.get("id", "")), player.hand.size()])
			get_tree().quit(1)
			return
		scene.call("_finish_end_turn", player)
		await get_tree().process_frame
		await get_tree().process_frame
		if bool(scene.get("discard_phase")):
			push_error("[TestDaoMasterRunStateBoot] %s should not enter manual discard_phase in PVE." % str(daomaster.get("id", "")))
			get_tree().quit(1)
			return
		if player.hand.size() > 10:
			push_error("[TestDaoMasterRunStateBoot] %s hand exceeded limit 10 after new turn." % str(daomaster.get("id", "")))
			get_tree().quit(1)
			return
		total_cards = player.hand.size() + scene.get("draw_pile").size() + scene.get("discard_pile").size() + scene.get("exhaust_pile").size()
		if total_cards != 12:
			push_error("[TestDaoMasterRunStateBoot] %s expected 12 cards after turn flow, got %d." % [str(daomaster.get("id", "")), total_cards])
			get_tree().quit(1)
			return
		print("[TestDaoMasterRunStateBoot] OK: %s -> starter %s, opening hand 5, new turn hand %d." % [
			str(daomaster.get("id", "")),
			str(daomaster.get("starter_deck_id", "")),
			player.hand.size()
		])
		remove_child(scene)
		scene.queue_free()
		await get_tree().process_frame
		checked += 1

	if checked != 3:
		push_error("[TestDaoMasterRunStateBoot] Expected 3 unlocked daomasters, got %d." % checked)
		get_tree().quit(1)
		return
	print("[TestDaoMasterRunStateBoot] All unlocked daomasters passed.")
	get_tree().quit(0)


func _load_daomasters() -> Array:
	var file: FileAccess = FileAccess.open(DAOMASTER_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("[TestDaoMasterRunStateBoot] Failed to read daomaster data.")
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("[TestDaoMasterRunStateBoot] Daomaster data is not an array.")
		return []
	return parsed


func _load_starter_deck_cards(starter_deck_id: String) -> Array:
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
