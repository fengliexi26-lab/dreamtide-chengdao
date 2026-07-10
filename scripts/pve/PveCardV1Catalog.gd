class_name PveCardV1Catalog
extends RefCounted

const CARD_CATALOG_PATH := "res://data/cards/pve/cards_pve_v1.json"
const EffectAdapterScript = preload("res://scripts/pve/PveCardEffectAdapter.gd")

var _loaded := false
var _load_errors: Array = []
var _cards_by_id: Dictionary = {}
var _card_ids: Array[String] = []
var _instance_counter := 0
var _effect_adapter = EffectAdapterScript.new()


func load_catalog() -> bool:
	if _loaded:
		return true

	_load_errors.clear()
	_cards_by_id.clear()
	_card_ids.clear()

	var parsed = _read_json(CARD_CATALOG_PATH)
	if typeof(parsed) != TYPE_ARRAY:
		_load_errors.append("catalog root must be an array")
		return false

	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			_load_errors.append("catalog contains non-dictionary item")
			continue
		var card: Dictionary = item
		var card_id := str(card.get("id", ""))
		if card_id == "":
			_load_errors.append("catalog contains card without id")
			continue
		if _cards_by_id.has(card_id):
			_load_errors.append("duplicate card id: %s" % card_id)
			continue
		var scope := str(card.get("owner_scope", ""))
		if scope not in ["universal", "shared", "exclusive"]:
			_load_errors.append("%s has unsupported owner_scope: %s" % [card_id, scope])
		if str(card.get("card_type", "")) not in ["daofa", "chengdao"]:
			_load_errors.append("%s has unsupported card_type: %s" % [card_id, str(card.get("card_type", ""))])
		if not _effect_adapter.is_phase1_supported(card):
			for error in _effect_adapter.get_validation_errors(card):
				_load_errors.append("%s %s" % [card_id, error])
			for effect_type in _effect_adapter.get_unsupported_effect_types(card):
				_load_errors.append("%s unsupported effect: %s" % [card_id, effect_type])
		_cards_by_id[card_id] = card.duplicate(true)
		_card_ids.append(card_id)

	if not _load_errors.is_empty():
		return false

	_loaded = true
	return true


func is_loaded() -> bool:
	return _loaded


func get_load_errors() -> Array:
	return _load_errors.duplicate(true)


func get_card_count() -> int:
	return _cards_by_id.size()


func has_card(card_id: String) -> bool:
	return _cards_by_id.has(card_id)


func get_card_definition(card_id: String) -> Dictionary:
	if not _cards_by_id.has(card_id):
		return {}
	return _cards_by_id[card_id].duplicate(true)


func get_all_card_ids() -> Array[String]:
	return _card_ids.duplicate()


func get_cards_by_owner_scope(owner_scope: String) -> Array:
	var result: Array = []
	for card_id in _card_ids:
		var card: Dictionary = _cards_by_id[card_id]
		if str(card.get("owner_scope", "")) == owner_scope:
			result.append(card.duplicate(true))
	return result


func get_cards_for_daomaster(daomaster_id: String, daomaster_data := {}) -> Array:
	var result: Array = []
	for card_id in _card_ids:
		var card: Dictionary = _cards_by_id[card_id]
		if is_card_compatible(card, daomaster_id, daomaster_data):
			result.append(card.duplicate(true))
	return result


func is_card_compatible(card: Dictionary, daomaster_id: String, daomaster_data := {}) -> bool:
	var scope := str(card.get("owner_scope", ""))
	match scope:
		"universal":
			return true
		"exclusive":
			return _array_contains_string(card.get("owner_ids", []), daomaster_id)
		"shared":
			var owner_ids = card.get("owner_ids", [])
			if typeof(owner_ids) == TYPE_ARRAY and not owner_ids.is_empty():
				return _array_contains_string(owner_ids, daomaster_id)
			return _shares_pool_tag(card, daomaster_data)
		_:
			return false


func load_starter_deck(deck_path: String, daomaster_id: String, daomaster_data := {}) -> Dictionary:
	var result := {
		"ok": false,
		"errors": [],
		"deck_id": "",
		"daomaster_id": daomaster_id,
		"card_ids": [],
		"cards": []
	}

	if not load_catalog():
		result.errors.append_array(get_load_errors())
		return result

	var parsed = _read_json(deck_path)
	if typeof(parsed) != TYPE_DICTIONARY:
		result.errors.append("deck root must be a dictionary")
		return result

	var deck: Dictionary = parsed
	result.deck_id = str(deck.get("id", ""))
	var card_ids = deck.get("cards", [])
	if typeof(card_ids) != TYPE_ARRAY:
		result.errors.append("deck cards must be an array")
		return result
	if card_ids.size() != 12:
		result.errors.append("deck must contain 12 cards, got %d" % card_ids.size())

	var cards: Array = []
	for raw_card_id in card_ids:
		var card_id := str(raw_card_id)
		result.card_ids.append(card_id)
		if not has_card(card_id):
			result.errors.append("missing card id: %s" % card_id)
			continue
		var card := get_card_definition(card_id)
		if not is_card_compatible(card, daomaster_id, daomaster_data):
			result.errors.append("incompatible card for %s: %s" % [daomaster_id, card_id])
			continue
		if str(card.get("owner_scope", "")) in ["token", "enemy_only"]:
			result.errors.append("deck cannot contain scope %s: %s" % [str(card.get("owner_scope", "")), card_id])
			continue
		cards.append(card)

	result.cards = cards
	result.ok = result.errors.is_empty()
	return result


func build_battle_instances(card_ids: Array) -> Array:
	if not load_catalog():
		return []
	var instances: Array[Dictionary] = []
	for raw_card_id in card_ids:
		var card_id := str(raw_card_id)
		if not has_card(card_id):
			continue
		_instance_counter += 1
		var instance := get_card_definition(card_id)
		instance["base_card_id"] = card_id
		instance["instance_id"] = "%s#%d" % [card_id, _instance_counter]
		instance["runtime_state"] = {}
		instances.append(instance)
	return instances


func _read_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_load_errors.append("failed to open: %s" % path)
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		_load_errors.append("failed to parse json: %s" % path)
	return parsed


func _array_contains_string(values, target: String) -> bool:
	if typeof(values) != TYPE_ARRAY:
		return false
	for value in values:
		if str(value) == target:
			return true
	return false


func _shares_pool_tag(card: Dictionary, daomaster_data) -> bool:
	if typeof(daomaster_data) != TYPE_DICTIONARY:
		return false
	var card_tags = card.get("pool_tags", [])
	var dao_tags = daomaster_data.get("dao_tags", [])
	if typeof(card_tags) != TYPE_ARRAY or typeof(dao_tags) != TYPE_ARRAY:
		return false
	for tag in card_tags:
		if _array_contains_string(dao_tags, str(tag)):
			return true
	return false
