extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"

func _ready() -> void:
	var packed_scene: PackedScene = load(BATTLE_SCENE_PATH)
	if packed_scene == null:
		push_error("[TestBattleSceneBoot] Failed to load %s" % BATTLE_SCENE_PATH)
		get_tree().quit(1)
		return

	var scene: Node = packed_scene.instantiate()
	if scene == null:
		push_error("[TestBattleSceneBoot] Failed to instantiate BattleScene.")
		get_tree().quit(1)
		return

	add_child(scene)
	print("[TestBattleSceneBoot] BattleScene instantiated.")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("[TestBattleSceneBoot] BattleScene boot check passed.")
	remove_child(scene)
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)
