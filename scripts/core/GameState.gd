extends RefCounted
class_name GameState

var players: Array[PlayerState] = []
var active_player_index: int = 0
var turn_number: int = 1
var battle_log: Array[String] = []
var rng := RandomNumberGenerator.new()

func _init(p_players: Array[PlayerState] = []) -> void:
	players = p_players.duplicate()
	rng.randomize()


func get_active_player() -> PlayerState:
	if players.is_empty():
		return null
	return players[clampi(active_player_index, 0, players.size() - 1)]


func get_opponent_of(player: PlayerState) -> PlayerState:
	for candidate in players:
		if candidate != player:
			return candidate
	return null


func add_log(message: String) -> void:
	battle_log.append(message)
	print(message)


func advance_turn() -> void:
	if players.is_empty():
		return
	active_player_index = (active_player_index + 1) % players.size()
	if active_player_index == 0:
		turn_number += 1
