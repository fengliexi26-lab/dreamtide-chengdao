extends Control

const DAOMASTER_DATA_PATH := "res://data/daomasters/daomasters_v0.json"
const CARD_DATA_PATH := "res://data/cards/cards_v0.json"
const STARTER_DECK_DIR := "res://data/decks/pve/"
const PVE_V1_DECK_DIR := "res://data/decks/pve_v1/"
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const RunStateScript = preload("res://scripts/pve/RunState.gd")
const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")

var daomasters: Array = []
var cards_by_id := {}
var selected_daomaster: Dictionary = {}
var daomaster_buttons := {}
var detail_label: Label
var status_label: Label
var start_button: Button
var grid: GridContainer
var data_errors: Array[String] = []
var starting_run := false

var panel_style := StyleBoxFlat.new()
var active_style := StyleBoxFlat.new()
var locked_style := StyleBoxFlat.new()
var gold_style := StyleBoxFlat.new()


func _ready() -> void:
	_setup_styles()
	_build_ui()
	_load_cards_by_id()
	_load_daomasters()
	_validate_daomaster_data()
	_render_daomaster_grid()
	_update_detail()


func _setup_styles() -> void:
	panel_style = _make_panel_style(Color.html("#151827"), Color.html("#3a3548"), 1, 8)
	active_style = _make_panel_style(Color.html("#172833"), Color.html("#26d8c7"), 2, 8)
	locked_style = _make_panel_style(Color.html("#10121a"), Color.html("#2b2936"), 1, 8)
	gold_style = _make_panel_style(Color.html("#3a2b12"), Color.html("#d6ad52"), 2, 8)


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _apply_button_style(button: Button, style: StyleBoxFlat) -> void:
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", locked_style)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.html("#10131d")
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_top = 14
	root.offset_right = -18
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title := Label.new()
	title.text = "梦潮：承道｜选择道主"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)

	status_label = Label.new()
	status_label.text = "请选择一位已解封道主，开始梦潮行旅。"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	root.add_child(status_label)

	var main_row := HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 14)
	root.add_child(main_row)

	var grid_panel := PanelContainer.new()
	grid_panel.name = "DaoMasterGridPanel"
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.add_theme_stylebox_override("panel", panel_style)
	main_row.add_child(grid_panel)

	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.add_child(grid_scroll)
	grid = GridContainer.new()
	grid.name = "DaoMasterGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid_scroll.add_child(grid)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "DaoMasterDetailPanel"
	detail_panel.custom_minimum_size = Vector2(330, 0)
	detail_panel.add_theme_stylebox_override("panel", panel_style)
	main_row.add_child(detail_panel)

	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 10)
	detail_panel.add_child(detail_box)
	var detail_title := Label.new()
	detail_title.text = "道主详情"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_box.add_child(detail_title)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(detail_scroll)

	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail_label)

	start_button = Button.new()
	start_button.text = "开始梦潮行旅"
	start_button.disabled = true
	_apply_button_style(start_button, gold_style)
	start_button.pressed.connect(_on_start_pressed)
	detail_box.add_child(start_button)


func _load_cards_by_id() -> void:
	cards_by_id.clear()
	var file: FileAccess = FileAccess.open(CARD_DATA_PATH, FileAccess.READ)
	if file == null:
		_record_data_error("无法读取卡牌数据：%s" % CARD_DATA_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		_record_data_error("卡牌数据格式错误：%s" % CARD_DATA_PATH)
		return
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			var card: Dictionary = item
			cards_by_id[str(card.get("id", ""))] = card


func _load_daomasters() -> void:
	var file: FileAccess = FileAccess.open(DAOMASTER_DATA_PATH, FileAccess.READ)
	if file == null:
		_record_data_error("无法读取道主数据：%s" % DAOMASTER_DATA_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		_record_data_error("道主数据格式错误：%s" % DAOMASTER_DATA_PATH)
		return
	daomasters.clear()
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			daomasters.append(item)


func _validate_daomaster_data() -> void:
	var seen_ids := {}
	if daomasters.size() != 9:
		_record_data_error("道主数据应为 9 名，当前为 %d 名。" % daomasters.size())
	for daomaster in daomasters:
		var id_text := str(daomaster.get("id", ""))
		if id_text == "":
			_record_data_error("存在缺少 id 的道主数据。")
		elif seen_ids.has(id_text):
			_record_data_error("道主 id 重复：%s" % id_text)
		else:
			seen_ids[id_text] = true
		if id_text == "fug​uan_seng" or id_text.find("\u200b") >= 0:
			_record_data_error("负棺僧 id 含不可见字符，应为 fuguan_seng。")
		if id_text == "fuguan_seng" and id_text.length() != 11:
			_record_data_error("负棺僧 id 长度异常，应为 fuguan_seng。")
		for field in ["title", "name", "group", "dao_tags", "role"]:
			if not daomaster.has(field) or str(daomaster.get(field, "")) == "":
				_record_data_error("%s 缺少必要字段：%s" % [id_text, field])
		if typeof(daomaster.get("unlocked", null)) != TYPE_BOOL:
			_record_data_error("%s 的 unlocked 必须为布尔值。" % id_text)
		if bool(daomaster.get("unlocked", false)):
			var expected := _expected_starter_deck_id(id_text)
			var starter_id := str(daomaster.get("starter_deck_id", ""))
			if expected != "" and starter_id != expected:
				_record_data_error("%s 的 starter_deck_id 应为 %s，当前为 %s。" % [id_text, expected, starter_id])
			if starter_id == "":
				_record_data_error("%s 已开放但缺少 starter_deck_id。" % id_text)
		elif str(daomaster.get("lock_reason", "")) == "":
			_record_data_error("%s 已锁定但缺少 lock_reason。" % id_text)

	if data_errors.is_empty():
		print("[DaoMasterSelectScene] daomasters_v0.json validation passed.")
	else:
		status_label.text = "道主数据存在问题，请查看 Output。"


func _expected_starter_deck_id(daomaster_id: String) -> String:
	if daomaster_id == "zaiheng_jun":
		return "starter_zaiheng"
	if daomaster_id == "zhiye_jun":
		return "starter_zhiye"
	if daomaster_id == "fuguan_seng":
		return "starter_fuguan"
	return ""


func _record_data_error(message: String) -> void:
	data_errors.append(message)
	push_error("[DaoMasterSelectScene] %s" % message)
	if status_label != null:
		status_label.text = message


func _render_daomaster_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	daomaster_buttons.clear()
	for daomaster in daomasters:
		var card := Button.new()
		card.custom_minimum_size = Vector2(210, 132)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.clip_text = true
		card.text = _format_daomaster_card(daomaster)
		card.tooltip_text = str(daomaster.get("role", ""))
		card.pressed.connect(_on_daomaster_pressed.bind(daomaster))
		_apply_button_style(card, active_style if bool(daomaster.get("unlocked", false)) else locked_style)
		card.modulate = Color.WHITE if bool(daomaster.get("unlocked", false)) else Color(0.56, 0.56, 0.62, 1.0)
		grid.add_child(card)
		daomaster_buttons[str(daomaster.get("id", ""))] = card
	_refresh_card_selection_styles()


func _format_daomaster_card(daomaster: Dictionary) -> String:
	var unlocked := bool(daomaster.get("unlocked", false))
	var state_text := "可用" if unlocked else "未解封"
	if str(daomaster.get("id", "")) == "juean_guzun":
		state_text = "隐藏命途"
	return "%s\n%s\n阵列：%s\n%s\n%s" % [
		str(daomaster.get("title", "")),
		str(daomaster.get("name", "")),
		str(daomaster.get("group", "")),
		_short_text(str(daomaster.get("role", "")), 28),
		state_text
	]


func _short_text(text: String, max_len: int) -> String:
	if text.length() <= max_len:
		return text
	return text.substr(0, max_len) + "..."


func _on_daomaster_pressed(daomaster: Dictionary) -> void:
	selected_daomaster = daomaster.duplicate(true)
	if bool(selected_daomaster.get("unlocked", false)):
		status_label.text = "已选择：%s / %s" % [
			str(selected_daomaster.get("title", "")),
			str(selected_daomaster.get("name", ""))
		]
		start_button.disabled = false
	else:
		status_label.text = "该道主尚未解封：%s" % str(selected_daomaster.get("lock_reason", "后续版本开放"))
		start_button.disabled = true
	_refresh_card_selection_styles()
	_update_detail()


func _refresh_card_selection_styles() -> void:
	var selected_id := str(selected_daomaster.get("id", ""))
	for id_text in daomaster_buttons.keys():
		var button := daomaster_buttons[id_text] as Button
		var daomaster := _find_daomaster_by_id(str(id_text))
		if button == null or daomaster.is_empty():
			continue
		var unlocked := bool(daomaster.get("unlocked", false))
		var is_selected := str(id_text) == selected_id
		var style := gold_style if is_selected else (active_style if unlocked else locked_style)
		_apply_button_style(button, style)
		button.modulate = Color.WHITE if unlocked or is_selected else Color(0.56, 0.56, 0.62, 1.0)


func _find_daomaster_by_id(id_text: String) -> Dictionary:
	for daomaster in daomasters:
		if str(daomaster.get("id", "")) == id_text:
			return daomaster
	return {}


func _update_detail() -> void:
	if selected_daomaster.is_empty():
		detail_label.text = "尚未选择道主。\n\n第一版开放：\n- 宰衡君 / 晏无咎\n- 织夜君 / 裴缝月\n- 负棺僧 / 释无葬\n\n其余命途暂时锁定。"
		start_button.disabled = true
		return
	var passive_name := str(selected_daomaster.get("passive_name", "未设置"))
	var passive_desc := str(selected_daomaster.get("passive_desc", "后续版本补充。"))
	var starter_id := str(selected_daomaster.get("starter_deck_id", ""))
	var starter_name := starter_id if starter_id != "" else "未开放"
	detail_label.text = "称号：%s\n姓名：%s\n阵列：%s\n状态：%s\n层级：%s\n道途：%s\n\n职业定位：%s\n\n专属被动：%s\n%s\n\n初始牌组：%s\n解锁状态：%s" % [
		str(selected_daomaster.get("title", "")),
		str(selected_daomaster.get("name", "")),
		str(selected_daomaster.get("group", "")),
		str(selected_daomaster.get("status", "")),
		str(selected_daomaster.get("realm_text", "")),
		_array_text(selected_daomaster.get("dao_tags", [])),
		str(selected_daomaster.get("role", "")),
		passive_name,
		passive_desc,
		starter_name,
		"可用" if bool(selected_daomaster.get("unlocked", false)) else "锁定：%s" % str(selected_daomaster.get("lock_reason", "后续版本开放"))
	]


func _on_start_pressed() -> void:
	if starting_run:
		return
	if selected_daomaster.is_empty():
		status_label.text = "请先选择一位道主。"
		return
	if not bool(selected_daomaster.get("unlocked", false)):
		status_label.text = "该道主尚未解封：%s" % str(selected_daomaster.get("lock_reason", "后续版本开放"))
		start_button.disabled = true
		return
	var daomaster_id := str(selected_daomaster.get("id", ""))
	var v1_deck_path := _v1_starter_deck_path(daomaster_id)
	if v1_deck_path == "":
		status_label.text = "无法开始：该道主没有 v1 初始牌组。"
		push_error("[DaoMasterSelectScene] missing v1 starter deck for %s" % daomaster_id)
		return
	var catalog = PveCardV1CatalogScript.new()
	if not catalog.load_catalog():
		status_label.text = "无法开始：v1 卡池读取失败。"
		push_error("[DaoMasterSelectScene] v1 catalog errors: %s" % str(catalog.get_load_errors()))
		return
	var deck_result: Dictionary = catalog.load_starter_deck(v1_deck_path, daomaster_id, selected_daomaster)
	if not bool(deck_result.get("ok", false)):
		status_label.text = "无法开始：v1 初始牌组无效。"
		push_error("[DaoMasterSelectScene] v1 starter deck errors: %s" % str(deck_result.get("errors", [])))
		return
	var starter_cards: Array = deck_result.get("card_ids", []).duplicate(true)
	if starter_cards.is_empty():
		status_label.text = "无法开始：初始牌组为空或读取失败。"
		return
	starting_run = true
	start_button.disabled = true
	var run_state = RunStateScript.new()
	run_state.start_new(selected_daomaster, starter_cards)
	run_state.enable_pve_card_v1(v1_deck_path, starter_cards)
	RunStateScript.set_current(run_state)
	status_label.text = "RunState 已创建，进入战斗..."
	print("[DaoMasterSelectScene] %s" % run_state.debug_summary())
	var error := get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
	if error != OK:
		status_label.text = "无法进入战斗场景：%s" % BATTLE_SCENE_PATH
		push_error(status_label.text)
		starting_run = false
		start_button.disabled = false


func _v1_starter_deck_path(daomaster_id: String) -> String:
	match daomaster_id:
		"zaiheng_jun":
			return PVE_V1_DECK_DIR + "starter_zaiheng_v1.json"
		"zhiye_jun":
			return PVE_V1_DECK_DIR + "starter_zhiye_v1.json"
		"fuguan_seng":
			return PVE_V1_DECK_DIR + "starter_fuguan_v1.json"
		_:
			return ""


func _load_starter_deck_cards(starter_deck_id: String) -> Array:
	if starter_deck_id == "":
		return []
	var deck_path := "%s%s.json" % [STARTER_DECK_DIR, starter_deck_id]
	var file: FileAccess = FileAccess.open(deck_path, FileAccess.READ)
	if file == null:
		push_error("无法读取 PVE 初始牌组：%s" % deck_path)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("PVE 初始牌组格式错误：%s" % deck_path)
		return []
	var deck_data: Dictionary = parsed
	var cards: Array = deck_data.get("cards", [])
	if cards.size() != 12:
		_record_data_error("%s 必须为 12 张，当前为 %d 张。" % [deck_path, cards.size()])
		return []
	for card_id in cards:
		var id_text := str(card_id)
		if not cards_by_id.has(id_text):
			_record_data_error("%s 引用了不存在的卡牌：%s" % [deck_path, id_text])
			return []
		var card: Dictionary = cards_by_id[id_text]
		if str(card.get("type", "")) == "character":
			_record_data_error("%s 不能包含人物牌：%s" % [deck_path, str(card.get("name", id_text))])
			return []
	print("[DaoMasterSelectScene] loaded starter deck %s: %d cards." % [starter_deck_id, cards.size()])
	return cards.duplicate(true)


func _array_text(values: Array) -> String:
	var text := ""
	for value in values:
		if text != "":
			text += "、"
		text += str(value)
	return text
