class_name PveCardEffectAdapter
extends RefCounted

const SUPPORTED_PHASE1_EFFECTS := {
	"deal_damage": true,
	"gain_formation": true,
	"draw": true,
	"gain_daoxi": true,
	"gain_reflux": true,
	"reduce_reflux": true,
	"summon": true,
	"add_pulse_buildup": true,
	"reduce_pulse_buildup": true,
	"apply_status": true
}

const PULSE_FIRE := "fire"
const TARGET_ENEMY := "enemy"
const TARGET_SELF := "self"
const TARGET_PLAYER := "player"

const KEYWORD_RETAIN := "凝梦"
const KEYWORD_EXHAUST := "消耗"


func is_v1_card(card: Dictionary) -> bool:
	return card.has("effects") or str(card.get("implementation_phase", "")) == "phase_1_base"


func get_effects(card: Dictionary) -> Array:
	var raw_effects = card.get("effects", [])
	if typeof(raw_effects) != TYPE_ARRAY:
		return []
	return raw_effects.duplicate(true)


func get_effects_by_type(card: Dictionary, effect_type: String) -> Array:
	var result: Array = []
	for effect in get_effects(card):
		if typeof(effect) == TYPE_DICTIONARY and str(effect.get("type", "")) == effect_type:
			result.append(effect.duplicate(true))
	return result


func get_total_value(card: Dictionary, effect_type: String) -> int:
	var total := 0
	if is_v1_card(card):
		for effect in get_effects_by_type(card, effect_type):
			var value = effect.get("value", 0)
			if _is_non_negative_integer_number(value):
				total += int(value)
		return total

	match effect_type:
		"gain_formation":
			return int(card.get("formation_gain", 0))
		"draw":
			return int(card.get("draw_count", 0))
		_:
			return 0


func has_keyword(card: Dictionary, keyword: String) -> bool:
	var keywords = card.get("keywords", [])
	if typeof(keywords) == TYPE_ARRAY:
		for item in keywords:
			if str(item) == keyword:
				return true

	if is_v1_card(card):
		return false

	var text := "%s %s %s" % [
		str(card.get("effect_text", "")),
		str(card.get("description", "")),
		str(card.get("text", ""))
	]
	return text.find(keyword) >= 0


func get_damage_spec(card: Dictionary) -> Dictionary:
	if is_v1_card(card):
		var amount := get_total_value(card, "deal_damage")
		if amount > 0:
			return {
				"mode": "amount",
				"amount": amount
			}
		return {}

	if card.has("damage_tier"):
		return {
			"mode": "legacy_tier",
			"tier": card.get("damage_tier")
		}
	return {}


func get_summon_spec(card: Dictionary) -> Dictionary:
	if is_v1_card(card):
		var summon_data = card.get("summon_data", {})
		if typeof(summon_data) == TYPE_DICTIONARY and not summon_data.is_empty():
			return _normalize_summon_spec(summon_data)
		for effect in get_effects_by_type(card, "summon"):
			return _normalize_summon_spec(effect)
		return {}

	if str(card.get("type", card.get("card_type", ""))) == "chengdao":
		return {
			"summon_id": str(card.get("id", "")),
			"attack": int(card.get("attack", card.get("power", card.get("offense", 0)))),
			"life": int(card.get("life", card.get("life_source", 0))),
			"side": str(card.get("side", "neutral")),
			"chengdao_kind": str(card.get("chengdao_kind", "")),
			"death_destination": str(card.get("death_destination", "discard")),
			"is_special": bool(card.get("is_special", false)),
			"dao_tags": card.get("dao_tags", []).duplicate(true) if typeof(card.get("dao_tags", [])) == TYPE_ARRAY else []
		}
	return {}


func get_unsupported_effect_types(card: Dictionary) -> Array:
	var unsupported: Array = []
	if not is_v1_card(card):
		return unsupported
	for effect in get_effects(card):
		if typeof(effect) != TYPE_DICTIONARY:
			unsupported.append("<malformed>")
			continue
		var effect_type := str(effect.get("type", ""))
		if effect_type == "" or not SUPPORTED_PHASE1_EFFECTS.has(effect_type):
			unsupported.append(effect_type if effect_type != "" else "<missing_type>")
	return unsupported


func get_validation_errors(card: Dictionary) -> Array:
	var errors: Array = []
	if not is_v1_card(card):
		return errors

	var raw_effects = card.get("effects", [])
	if typeof(raw_effects) != TYPE_ARRAY:
		errors.append("effects must be an array")
		return errors

	for index in range(raw_effects.size()):
		var effect = raw_effects[index]
		if typeof(effect) != TYPE_DICTIONARY:
			errors.append("effect %d must be a dictionary" % index)
			continue
		var effect_type := str(effect.get("type", ""))
		if effect_type == "":
			errors.append("effect %d missing type" % index)
			continue
		if not SUPPORTED_PHASE1_EFFECTS.has(effect_type):
			errors.append("effect %d unsupported type: %s" % [index, effect_type])
			continue
		if effect_type == "summon":
			var target_errors := _validate_effect_target(effect, [TARGET_SELF])
			for error in target_errors:
				errors.append("effect %d %s" % [index, error])
			var summon_errors := _validate_summon_source(effect)
			for error in summon_errors:
				errors.append("effect %d %s" % [index, error])
			continue
		if effect_type == "apply_status":
			var status_errors := _validate_apply_status_effect(effect)
			for error in status_errors:
				errors.append("effect %d %s" % [index, error])
			continue
		if effect_type == "add_pulse_buildup" or effect_type == "reduce_pulse_buildup":
			var pulse_effect_errors := _validate_pulse_effect(effect)
			for error in pulse_effect_errors:
				errors.append("effect %d %s" % [index, error])
			continue
		var allowed_targets := [TARGET_SELF, TARGET_PLAYER]
		if effect_type == "deal_damage":
			allowed_targets = [TARGET_ENEMY]
		var target_errors := _validate_effect_target(effect, allowed_targets)
		for error in target_errors:
			errors.append("effect %d %s" % [index, error])
		if not effect.has("value"):
			errors.append("effect %d missing value" % index)
			continue
		var value = effect.get("value")
		if not _is_non_negative_integer_number(value):
			errors.append("effect %d value must be a non-negative integer number" % index)
		elif int(value) < 0:
			errors.append("effect %d value must not be negative" % index)
		var pulse_errors := _validate_deal_damage_pulse_fields(effect)
		for error in pulse_errors:
			errors.append("effect %d %s" % [index, error])

	if str(card.get("card_type", "")) == "chengdao":
		var summon_errors := _validate_summon_source(card.get("summon_data", {}))
		for error in summon_errors:
			errors.append("summon_data %s" % error)
	return errors


func is_phase1_supported(card: Dictionary) -> bool:
	return get_validation_errors(card).is_empty() and get_unsupported_effect_types(card).is_empty()


func _normalize_summon_spec(source: Dictionary) -> Dictionary:
	var dao_tags: Array = []
	if typeof(source.get("dao_tags", [])) == TYPE_ARRAY:
		dao_tags = source.get("dao_tags", []).duplicate(true)
	return {
		"summon_id": str(source.get("summon_id", "")),
		"attack": int(source.get("attack", 0)),
		"life": int(source.get("life", 0)),
		"side": str(source.get("side", "neutral")),
		"chengdao_kind": str(source.get("chengdao_kind", "")),
		"death_destination": str(source.get("death_destination", "discard")),
		"is_special": bool(source.get("is_special", false)),
		"dao_tags": dao_tags
	}


func _validate_summon_source(source) -> Array:
	var errors: Array = []
	if typeof(source) != TYPE_DICTIONARY:
		return ["must be a dictionary"]
	var required_fields := ["summon_id", "attack", "life", "side", "chengdao_kind", "death_destination", "is_special", "dao_tags"]
	for field in required_fields:
		if not source.has(field):
			errors.append("missing %s" % field)
	if source.has("attack") and not _is_non_negative_integer_number(source.get("attack")):
		errors.append("attack must be a non-negative integer number")
	if source.has("life") and not _is_positive_integer_number(source.get("life")):
		errors.append("life must be a positive integer number")
	if source.has("attack") and int(source.get("attack", 0)) < 0:
		errors.append("attack must not be negative")
	if source.has("life") and int(source.get("life", 0)) <= 0:
		errors.append("life must be positive")
	if source.has("dao_tags") and typeof(source.get("dao_tags")) != TYPE_ARRAY:
		errors.append("dao_tags must be array")
	return errors


func _validate_pulse_effect(effect: Dictionary) -> Array:
	var errors: Array = []
	for error in _validate_effect_target(effect, [TARGET_ENEMY, TARGET_SELF, TARGET_PLAYER]):
		errors.append(error)
	if not effect.has("pulse_id"):
		errors.append("missing pulse_id")
	elif str(effect.get("pulse_id", "")) != PULSE_FIRE:
		errors.append("unsupported pulse_id: %s" % str(effect.get("pulse_id", "")))
	if not effect.has("value"):
		errors.append("missing value")
	elif not _is_non_negative_integer_number(effect.get("value")):
		errors.append("value must be a non-negative integer number")
	return errors


func _validate_apply_status_effect(effect: Dictionary) -> Array:
	var errors: Array = []
	for error in _validate_effect_target(effect, [TARGET_ENEMY, TARGET_SELF, TARGET_PLAYER]):
		errors.append(error)
	if not effect.has("status_id") or str(effect.get("status_id", "")) == "":
		errors.append("missing status_id")
	if not effect.has("stacks"):
		errors.append("missing stacks")
	elif not _is_positive_integer_number(effect.get("stacks")):
		errors.append("stacks must be a positive integer number")
	return errors


func _validate_effect_target(effect: Dictionary, allowed_targets: Array) -> Array:
	var errors: Array = []
	if not effect.has("target") or str(effect.get("target", "")) == "":
		errors.append("missing target")
		return errors
	var target := str(effect.get("target", ""))
	if not allowed_targets.has(target):
		errors.append("unsupported target: %s" % target)
	return errors


func _validate_deal_damage_pulse_fields(effect: Dictionary) -> Array:
	var errors: Array = []
	var has_pulse_id := effect.has("pulse_id")
	var has_pulse_value := effect.has("pulse_value")
	if not has_pulse_id and not has_pulse_value:
		return errors
	if not has_pulse_id:
		errors.append("missing pulse_id")
	elif str(effect.get("pulse_id", "")) != PULSE_FIRE:
		errors.append("unsupported pulse_id: %s" % str(effect.get("pulse_id", "")))
	if not has_pulse_value:
		errors.append("missing pulse_value")
	elif not _is_non_negative_integer_number(effect.get("pulse_value")):
		errors.append("pulse_value must be a non-negative integer number")
	if effect.has("conductive") and typeof(effect.get("conductive")) != TYPE_BOOL:
		errors.append("conductive must be bool")
	return errors


func _is_non_negative_integer_number(value) -> bool:
	if typeof(value) == TYPE_INT:
		return int(value) >= 0
	if typeof(value) == TYPE_FLOAT:
		return float(value) >= 0.0 and is_equal_approx(float(value), float(int(value)))
	return false


func _is_positive_integer_number(value) -> bool:
	if typeof(value) == TYPE_INT:
		return int(value) > 0
	if typeof(value) == TYPE_FLOAT:
		return float(value) > 0.0 and is_equal_approx(float(value), float(int(value)))
	return false
