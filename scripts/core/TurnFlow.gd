extends RefCounted
class_name TurnFlow

enum Phase {
	TURN_START,
	DRAW,
	MAIN,
	COMBAT_RESOLVE,
	TURN_END
}

const PHASE_NAMES: Array[String] = [
	"回合开始",
	"抽牌阶段",
	"主阶段",
	"战斗结算",
	"回合结束"
]

var game_state: GameState
var phase: int = Phase.TURN_START

func _init(p_game_state: GameState = null) -> void:
	game_state = p_game_state


func get_phase_name() -> String:
	return PHASE_NAMES[clampi(phase, 0, PHASE_NAMES.size() - 1)]


func start_turn() -> void:
	phase = Phase.TURN_START
	if game_state != null:
		var player := game_state.get_active_player()
		game_state.add_log("第 %d 回合：%s 的回合开始" % [game_state.turn_number, player.display_name])


func draw_phase() -> void:
	phase = Phase.DRAW
	if game_state == null:
		return
	var player := game_state.get_active_player()
	if player.deck.is_empty():
		game_state.add_log("%s 无牌可抽" % player.display_name)
		return
	var card: Dictionary = player.deck.pop_front()
	var result := BattleEngine.handle_card_obtained(player, card, "draw")
	game_state.add_log("%s：%s" % [player.display_name, str(result.get("reason", ""))])


func main_phase() -> void:
	phase = Phase.MAIN


func combat_resolve_phase() -> void:
	phase = Phase.COMBAT_RESOLVE


func end_turn() -> void:
	phase = Phase.TURN_END
	if game_state != null:
		game_state.add_log("%s 的回合结束" % game_state.get_active_player().display_name)
		game_state.advance_turn()


func run_basic_turn() -> void:
	start_turn()
	draw_phase()
	main_phase()
	combat_resolve_phase()
	end_turn()
