extends Node

var passed := 0
var failed := 0

func _ready() -> void:
	print("=== Dreamtide Chengdao v0.1 Core Tests ===")
	_test_realm_life_sources()
	_test_damage_scaling()
	_test_formation_skips_dao_compatibility()
	_test_fate_pact_backlash()
	_test_breakthrough()
	print("=== TestBattleCore complete: %d passed, %d failed ===" % [passed, failed])


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[PASS] %s" % label)
	else:
		failed += 1
		push_error("[FAIL] %s" % label)


func _test_realm_life_sources() -> void:
	_assert_true(Realm.get_life_source(Realm.Rank.HUANG_RANG) == 150, "荒壤命源为 150")
	_assert_true(Realm.get_life_source(Realm.Rank.MING_HE) == 300, "命河命源为 300")
	_assert_true(Realm.get_life_source(Realm.Rank.DI_QUE) == 10000, "帝阙命源为 10000")
	_assert_true(Realm.get_realm_name(Realm.Rank.GUI_XU) == "归墟", "归墟境界名称正确")


func _test_damage_scaling() -> void:
	_assert_true(Damage.calculate(Damage.Tier.MICRO, Realm.Rank.HUANG_RANG) == 8, "荒壤微额伤害向上取整为 8")
	_assert_true(Damage.calculate(Damage.Tier.SMALL, Realm.Rank.MING_HE) == 30, "命河小额伤害为 30")
	_assert_true(Damage.calculate(Damage.Tier.BURST, Realm.Rank.DI_QUE) == 4500, "帝阙爆发伤害为 4500")


func _test_formation_skips_dao_compatibility() -> void:
	var player := PlayerState.new("tester", "测试者", Realm.Rank.HUANG_RANG, ["潮"])
	player.formation_value = 3
	var formation_card := {
		"id": "test_formation",
		"name": "异脉法阵",
		"type": CardTypes.FORMATION,
		"dao_tags": ["山"],
		"realm_requirement": Realm.Rank.HUANG_RANG,
		"formation_cost": 2
	}
	_assert_true(not Compatibility.participates_in_compatibility(formation_card), "法阵牌不参与道脉适配")
	var result := Formation.play(player, formation_card)
	_assert_true(bool(result.get("ok", false)) == true, "法阵只看境界、命源、阵势值和法阵位")
	_assert_true(player.active_formations.size() == 1, "法阵占用一个法阵位")


func _test_fate_pact_backlash() -> void:
	var player := PlayerState.new("outsider", "非适格者", Realm.Rank.MING_HE, ["潮"])
	var pact_weapon := {
		"id": "mingqi_owner_only",
		"name": "承道命契剑",
		"type": CardTypes.LIFE_ARTIFACT,
		"fate_pact": {
			"required_owner_id": "chosen_one",
			"required_dao_path": "火",
			"backlash_tier": Damage.Tier.SMALL
		}
	}
	var before_life := player.life_source
	var result := BattleEngine.handle_card_obtained(player, pact_weapon, "draw")
	_assert_true(bool(result.get("ok", true)) == false and str(result.get("reason", "")) == "命契反噬", "非适格单位抽到命契专武会反噬")
	_assert_true(player.life_source == before_life - 30, "命河小额反噬伤害为 30")
	_assert_true(player.hand.is_empty() and player.discard_pile.size() == 1, "反噬后弃置该牌且不入手牌")


func _test_breakthrough() -> void:
	var player := PlayerState.new("cultivator", "破境者", Realm.Rank.HUANG_RANG, ["潮"])
	Breakthrough.add_dao_progress(player, 100)
	var result := Breakthrough.try_breakthrough(player)
	_assert_true(bool(result.get("ok", false)) == true, "道行足够时可临战破境")
	_assert_true(player.combat_realm == Realm.Rank.MING_HE, "荒壤破境到命河")
	_assert_true(player.max_life_source == 300 and player.life_source == 300, "破境后临战命源上限与当前命源提高")
	_assert_true(player.base_realm == Realm.Rank.HUANG_RANG, "临战破境不改变基础境界")
