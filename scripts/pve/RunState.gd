extends RefCounted
class_name RunState

static var current = null

var selected_daomaster_id := ""
var selected_daomaster_name := ""
var selected_daomaster_title := ""
var selected_passive_id := ""
var selected_passive_name := ""
var selected_passive_desc := ""
var dao_tags: Array = []
var max_life := 70
var current_life := 70
var base_daoxi := 3
var current_daoxi := 3
var formation := 0
var reflux := 0
var daoxing := 0
var current_deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var card_data_version := "legacy"
var starter_deck_path := ""
var uses_pve_card_v1 := false
var relics: Array = []
var weapons: Array = []
var current_floor := 1
var current_node := 1
var run_started := false
var run_over := false

static func set_current(run_state) -> void:
	current = run_state


static func get_current():
	return current


static func clear_current() -> void:
	current = null


func start_new(daomaster: Dictionary, starter_cards: Array) -> void:
	selected_daomaster_id = str(daomaster.get("id", ""))
	selected_daomaster_name = str(daomaster.get("name", ""))
	selected_daomaster_title = str(daomaster.get("title", selected_daomaster_name))
	selected_passive_id = str(daomaster.get("passive_id", ""))
	selected_passive_name = str(daomaster.get("passive_name", ""))
	selected_passive_desc = str(daomaster.get("passive_desc", ""))
	dao_tags = daomaster.get("dao_tags", []).duplicate(true)
	max_life = 70
	current_life = max_life
	base_daoxi = 3
	current_daoxi = base_daoxi
	formation = 0
	reflux = 0
	daoxing = 0
	current_deck = starter_cards.duplicate(true)
	draw_pile = current_deck.duplicate(true)
	discard_pile.clear()
	exhaust_pile.clear()
	card_data_version = "legacy"
	starter_deck_path = ""
	uses_pve_card_v1 = false
	relics.clear()
	weapons.clear()
	current_floor = 1
	current_node = 1
	run_started = true
	run_over = false


func enable_pve_card_v1(deck_path: String, deck_card_ids: Array) -> void:
	card_data_version = "pve_v1"
	starter_deck_path = deck_path
	uses_pve_card_v1 = true
	current_deck = deck_card_ids.duplicate(true)
	draw_pile = current_deck.duplicate(true)


func debug_summary() -> String:
	return "RunState: %s / %s | passive %s / %s | life %d/%d | daoxi %d/%d | formation %d | reflux %d | daoxing %d | deck %d | card_data %s | v1 %s | floor %d node %d | started %s over %s" % [
		selected_daomaster_title,
		selected_daomaster_name,
		selected_passive_id,
		selected_passive_name,
		current_life,
		max_life,
		current_daoxi,
		base_daoxi,
		formation,
		reflux,
		daoxing,
		current_deck.size(),
		card_data_version,
		str(uses_pve_card_v1),
		current_floor,
		current_node,
		str(run_started),
		str(run_over)
	]


func to_daomaster_card() -> Dictionary:
	return {
		"id": selected_daomaster_id,
		"title": selected_daomaster_title,
		"name": selected_daomaster_title,
		"real_name": selected_daomaster_name,
		"passive_id": selected_passive_id,
		"passive_name": selected_passive_name,
		"passive_desc": selected_passive_desc,
		"type": "character",
		"dao_tags": dao_tags.duplicate(true),
		"side": "neutral",
		"base_realm": 0,
		"base_life": max_life,
		"base_daoxi": base_daoxi,
		"base_formation": formation,
		"base_tide": reflux,
		"base_daoxing": daoxing,
		"traits": [],
		"compatible_weapons": []
	}
