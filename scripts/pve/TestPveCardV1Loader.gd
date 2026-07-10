extends Node

const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")
const PveCardEffectAdapterScript = preload("res://scripts/pve/PveCardEffectAdapter.gd")

const DECKS := {
	"zaiheng_jun": "res://data/decks/pve_v1/starter_zaiheng_v1.json",
	"zhiye_jun": "res://data/decks/pve_v1/starter_zhiye_v1.json",
	"fuguan_seng": "res://data/decks/pve_v1/starter_fuguan_v1.json"
}

var catalog = PveCardV1CatalogScript.new()
var adapter = PveCardEffectAdapterScript.new()


func _ready() -> void:
	if not _test_catalog():
		return
	if not _test_starter_decks():
		return
	if not _test_instance_isolation():
		return
	if not _test_effect_adapter():
		return
	if not _test_malformed_data():
		return
	print("[TestPveCardV1Loader] all tests passed")
	get_tree().quit(0)


func _test_catalog() -> bool:
	if not catalog.load_catalog():
		return _fail("catalog failed: %s" % str(catalog.get_load_errors()))
	if catalog.get_card_count() != 39:
		return _fail("catalog count should be 39, got %d" % catalog.get_card_count())
	if catalog.get_cards_by_owner_scope("universal").size() != 6:
		return _fail("universal count should be 6")
	if catalog.get_cards_by_owner_scope("shared").size() != 9:
		return _fail("shared count should be 9")
	if _count_exclusive("zaiheng_jun") != 8:
		return _fail("zaiheng exclusive count should be 8")
	if _count_exclusive("zhiye_jun") != 8:
		return _fail("zhiye exclusive count should be 8")
	if _count_exclusive("fuguan_seng") != 8:
		return _fail("fuguan exclusive count should be 8")
	if catalog.has_card("missing_card_id"):
		return _fail("missing card id should not exist")
	if not catalog.get_card_definition("missing_card_id").is_empty():
		return _fail("missing card definition should be empty")
	var ids := catalog.get_all_card_ids()
	var seen := {}
	for id in ids:
		if seen.has(id):
			return _fail("duplicate id returned by catalog: %s" % id)
		seen[id] = true
	print("[TestPveCardV1Loader] catalog loaded: 39")
	return true


func _test_starter_decks() -> bool:
	for daomaster_id in DECKS.keys():
		var result: Dictionary = catalog.load_starter_deck(DECKS[daomaster_id], daomaster_id)
		if not bool(result.get("ok", false)):
			return _fail("%s deck should load: %s" % [daomaster_id, str(result.get("errors", []))])
		if result.get("card_ids", []).size() != 12:
			return _fail("%s deck should contain 12 ids" % daomaster_id)
		if result.get("cards", []).size() != 12:
			return _fail("%s deck should contain 12 cards" % daomaster_id)
		for card in result.get("cards", []):
			if not catalog.is_card_compatible(card, daomaster_id):
				return _fail("%s contains incompatible card %s" % [daomaster_id, str(card.get("id", ""))])

	if bool(catalog.load_starter_deck(DECKS["zaiheng_jun"], "zhiye_jun").get("ok", false)):
		return _fail("zhiye should not load zaiheng starter deck")
	if bool(catalog.load_starter_deck(DECKS["zhiye_jun"], "fuguan_seng").get("ok", false)):
		return _fail("fuguan should not load zhiye starter deck")
	if bool(catalog.load_starter_deck(DECKS["fuguan_seng"], "zaiheng_jun").get("ok", false)):
		return _fail("zaiheng should not load fuguan starter deck")

	var universal_card := catalog.get_card_definition("universal_breaking_style")
	if not catalog.is_card_compatible(universal_card, "zaiheng_jun"):
		return _fail("universal should support zaiheng")
	if not catalog.is_card_compatible(universal_card, "zhiye_jun"):
		return _fail("universal should support zhiye")
	if not catalog.is_card_compatible(universal_card, "fuguan_seng"):
		return _fail("universal should support fuguan")

	if catalog.is_card_compatible(catalog.get_card_definition("zhiye_liuxiao"), "zaiheng_jun"):
		return _fail("zaiheng should not load zhiye exclusive")
	if catalog.is_card_compatible(catalog.get_card_definition("fuguan_songlu"), "zhiye_jun"):
		return _fail("zhiye should not load fuguan exclusive")
	if catalog.is_card_compatible(catalog.get_card_definition("zaiheng_jieyue"), "fuguan_seng"):
		return _fail("fuguan should not load zaiheng exclusive")

	print("[TestPveCardV1Loader] starter decks passed")
	return true


func _test_instance_isolation() -> bool:
	var card_ids := ["zaiheng_jieyue", "zaiheng_jieyue", "universal_breaking_style"]
	var instances: Array = catalog.build_battle_instances(card_ids)
	if instances.size() != 3:
		return _fail("battle instance count should be 3")
	if instances[0] == instances[1]:
		return _fail("duplicate card instances should not compare equal after runtime mutation test setup")
	if str(instances[0].get("instance_id", "")) == str(instances[1].get("instance_id", "")):
		return _fail("duplicate card instance_id should be unique")
	instances[0]["runtime_state"]["marker"] = "first"
	if instances[1].get("runtime_state", {}).has("marker"):
		return _fail("runtime_state should be isolated")
	instances[0]["name"] = "mutated"
	if catalog.get_card_definition("zaiheng_jieyue").get("name", "") == "mutated":
		return _fail("mutating instance should not affect catalog")
	var rebuilt: Array = catalog.build_battle_instances(["zaiheng_jieyue"])
	if rebuilt.is_empty() or str(rebuilt[0].get("instance_id", "")) == str(instances[0].get("instance_id", "")):
		return _fail("rebuild should create a new instance id")
	print("[TestPveCardV1Loader] instance isolation passed")
	return true


func _test_effect_adapter() -> bool:
	if adapter.get_total_value(catalog.get_card_definition("universal_breaking_style"), "deal_damage") != 7:
		return _fail("deal_damage should read 7")
	if adapter.get_total_value(catalog.get_card_definition("universal_body_guard"), "gain_formation") != 6:
		return _fail("gain_formation should read 6")
	if adapter.get_total_value(catalog.get_card_definition("universal_draw_breath"), "draw") != 1:
		return _fail("draw should read 1")
	if adapter.get_total_value(catalog.get_card_definition("zhiye_muye_breath"), "gain_daoxi") != 1:
		return _fail("gain_daoxi should read 1")
	if adapter.get_total_value(catalog.get_card_definition("fuguan_guiyuan"), "gain_reflux") != 1:
		return _fail("gain_reflux should read 1")
	if adapter.get_total_value(catalog.get_card_definition("fuguan_guiyuan"), "reduce_reflux") != 0:
		return _fail("reduce_reflux should be 0 when no card has it")
	var summon := adapter.get_summon_spec(catalog.get_card_definition("shared_order_jade_deer"))
	if str(summon.get("summon_id", "")) == "" or int(summon.get("attack", 0)) != 3 or int(summon.get("life", 0)) != 11:
		return _fail("summon spec should normalize jade deer")
	if not adapter.has_keyword(catalog.get_card_definition("zhiye_liuxiao"), "凝梦"):
		return _fail("retain keyword should be read from keywords")
	if not adapter.has_keyword(catalog.get_card_definition("fuguan_wuzang_order"), "消耗"):
		return _fail("exhaust keyword should be read from keywords")

	var text_only_v1 := {
		"id": "temp_v1_text_only",
		"implementation_phase": "phase_1_base",
		"effects": [],
		"effect_text": "获得99点阵势"
	}
	if adapter.get_total_value(text_only_v1, "gain_formation") != 0:
		return _fail("v1 card must not read effect_text as effect")

	var legacy := {
		"id": "legacy_formation",
		"formation_gain": 3,
		"effect_text": "获得 3 点阵势。"
	}
	if adapter.get_total_value(legacy, "gain_formation") != 3:
		return _fail("legacy formation_gain should be supported")
	var legacy_damage := {
		"id": "legacy_damage",
		"damage_tier": 2
	}
	var damage_spec := adapter.get_damage_spec(legacy_damage)
	if str(damage_spec.get("mode", "")) != "legacy_tier" or int(damage_spec.get("tier", -1)) != 2:
		return _fail("legacy damage_tier should return legacy_tier mode")

	print("[TestPveCardV1Loader] effect adapter passed")
	return true


func _test_malformed_data() -> bool:
	var malformed_effects := {
		"id": "bad_effects",
		"implementation_phase": "phase_1_base",
		"effects": "bad"
	}
	if adapter.get_validation_errors(malformed_effects).is_empty():
		return _fail("malformed effects should return validation errors")
	var missing_type := {
		"id": "missing_type",
		"implementation_phase": "phase_1_base",
		"effects": [{"value": 1}]
	}
	if adapter.get_validation_errors(missing_type).is_empty():
		return _fail("missing effect type should return validation errors")
	var bad_value := {
		"id": "bad_value",
		"implementation_phase": "phase_1_base",
		"effects": [{"type": "draw", "value": "1"}]
	}
	if adapter.get_validation_errors(bad_value).is_empty():
		return _fail("bad value type should return validation errors")
	var unsupported := {
		"id": "unsupported",
		"implementation_phase": "phase_1_base",
		"effects": [{"type": "future_effect", "value": 1}]
	}
	if adapter.get_unsupported_effect_types(unsupported).is_empty():
		return _fail("unsupported effect should be reported")
	print("[TestPveCardV1Loader] malformed data passed")
	return true


func _count_exclusive(daomaster_id: String) -> int:
	var count := 0
	for card_id in catalog.get_all_card_ids():
		var card := catalog.get_card_definition(card_id)
		if str(card.get("owner_scope", "")) == "exclusive" and catalog.is_card_compatible(card, daomaster_id):
			count += 1
	return count


func _fail(message: String) -> bool:
	push_error("[TestPveCardV1Loader] ERROR %s" % message)
	get_tree().quit(1)
	return false
