extends Control

const CARD_DATA_PATH := "res://data/cards/cards_v0.json"
const STARTER_MAIN_DECK_PATH := "res://data/decks/starter_main_deck.json"
const STARTER_CHARACTER_LINEUP_PATH := "res://data/decks/starter_character_lineup.json"
const PVE_STARTER_DECK_DIR := "res://data/decks/pve/"
const RunStateScript = preload("res://scripts/pve/RunState.gd")
const PassiveRuntimeScript = preload("res://scripts/pve/DaomasterPassiveRuntime.gd")
const PveCardV1CatalogScript = preload("res://scripts/pve/PveCardV1Catalog.gd")
const PveCardEffectAdapterScript = preload("res://scripts/pve/PveCardEffectAdapter.gd")
const PveBeastRuntimeScript = preload("res://scripts/pve/PveBeastRuntime.gd")
const PveCombatEventQueueScript = preload("res://scripts/pve/PveCombatEventQueue.gd")
const PveStatusRuntimeScript = preload("res://scripts/pve/PveStatusRuntime.gd")
const PvePulseRuntimeScript = preload("res://scripts/pve/PvePulseRuntime.gd")
const MAIN_DECK_SIZE := 40
const SIDE_DECK_SIZE := 15
const HAND_LIMIT := 10

var game_state: GameState
var player_boards: Array[BoardView] = []
var player_info_panels: Array[PanelContainer] = []
var board_panels: Array[PanelContainer] = []
var dao_master_panels: Array[PanelContainer] = []
var dao_master_labels: Array[Label] = []
var player_info_labels: Array[Label] = []
var battlefield_summary_containers: Array[VBoxContainer] = []
var player_portrait_label: Label
var opponent_portrait_label: Label
var player_portrait_art_label: Label
var opponent_portrait_art_label: Label
var player_portrait_panel: PanelContainer
var opponent_portrait_panel: PanelContainer
var player_target_button: Button
var opponent_target_button: Button
var enemy_info_label: Label
var enemy_target_button: Button
var opponent_hand_overview: BoxContainer
var opponent_hand_overview_right: BoxContainer
var hand_category_buttons := {}
var chengdao_filter_buttons := {}
var hand_category_label: Label
var resource_summary_label: Label
var hand_view: HandView
var hand_area_panel: PanelContainer
var hand_title_label: Label
var central_battlefield_panel: PanelContainer
var central_battlefield_grid: GridContainer
var central_battlefield_button: Button
var dao_master_target_buttons: Array[Button] = []
var info_tabs: TabContainer
var deck_pile_label: Label
var log_view: RichTextLabel
var active_label: Label
var operation_hint_label: Label
var selected_detail_label: Label
var breakthrough_button: Button
var restart_button: Button
var next_round_button: Button
var end_turn_button: Button
var attack_button: Button
var dao_strike_button: Button
var selected_card: Dictionary = {}
var selected_card_view: CardView
var selected_card_source := ""
var selected_attacker := {"player_index": -1, "slot_index": -1}
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var exhaust_pile: Array[Dictionary] = []
var passive_runtime
var pve_card_catalog
var pve_effect_adapter
var pve_beast_runtime
var pve_event_queue
var pve_status_runtime
var pve_pulse_runtime
var pve_card_data_mode := "legacy_fallback"
var pve_card_fallback_reason := ""
var extra_stats := {}
var active_dao_masters: Dictionary = {}
var dao_strike_used := {}
var discard_phase := false
var need_discard := 0
var discard_phase_player_id := ""
var current_hand_category := "承道"
var current_chengdao_filter := "全部"
var card_load_error := ""
var game_over := false
var game_mode := "pve"
var enemy := {}
var current_match_round := 1
var player1_match_wins := 0
var player2_match_wins := 0
var player1_used_characters: Array[String] = []
var player2_used_characters: Array[String] = []
var match_over := false
var match_winner := ""
var active_panel_style := StyleBoxFlat.new()
var inactive_panel_style := StyleBoxFlat.new()
var dark_panel_style := StyleBoxFlat.new()
var player_frame_style := StyleBoxFlat.new()
var opponent_frame_style := StyleBoxFlat.new()
var player_card_style := StyleBoxFlat.new()
var opponent_card_style := StyleBoxFlat.new()
var gold_button_style := StyleBoxFlat.new()
var dim_button_style := StyleBoxFlat.new()
var disabled_button_style := StyleBoxFlat.new()
var tutorial_step := 0
var tutorial_steps: Array[String] = [
	"第一步：点击一张承道牌。",
	"第二步：点击高亮的己方承道位。",
	"第三步：点击一张道法牌。",
	"第四步：点击高亮的敌方目标。",
	"第五步：点击结束回合。"
]

func _ready() -> void:
	_setup_panel_styles()
	_build_ui()
	if game_mode == "pve":
		_start_pve_battle()
	else:
		_start_match()
	_refresh_all()


func _setup_panel_styles() -> void:
	active_panel_style = _make_panel_style(Color.html("#151827"), Color.html("#26d8c7"), 2, 6)
	inactive_panel_style = _make_panel_style(Color.html("#10131d"), Color.html("#3a3548"), 1, 6)
	dark_panel_style = _make_panel_style(Color.html("#1c1a2a"), Color.html("#2f2a3c"), 1, 6)
	player_frame_style = _make_panel_style(Color.html("#142735"), Color.html("#26d8c7"), 2, 8)
	opponent_frame_style = _make_panel_style(Color.html("#2a1b24"), Color.html("#c89b45"), 2, 8)
	player_card_style = _make_panel_style(Color.html("#162832"), Color.html("#26d8c7"), 2, 5)
	opponent_card_style = _make_panel_style(Color.html("#2a1b24"), Color.html("#c89b45"), 2, 5)
	gold_button_style = _make_panel_style(Color.html("#3a2b12"), Color.html("#d6ad52"), 2, 5)
	dim_button_style = _make_panel_style(Color.html("#171725"), Color.html("#4c465a"), 1, 5)
	disabled_button_style = _make_panel_style(Color.html("#10121a"), Color.html("#2b2936"), 1, 5)


func _make_panel_style(bg: Color, border: Color, border_width: int = 1, radius: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _apply_button_style(button: Button, style: StyleBoxFlat) -> void:
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", disabled_button_style)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BattleSceneDarkBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.html("#10131d")
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 6
	root.offset_top = 6
	root.offset_right = -6
	root.offset_bottom = -6
	root.add_theme_constant_override("separation", 5)
	add_child(root)

	root.add_child(_build_top_status_bar())

	for i in range(2):
		var board := BoardView.new()
		board.setup("玩家 %d 内部战场" % [i + 1])
		player_boards.append(board)

	root.add_child(_build_opponent_area())
	root.add_child(_build_middle_battle_area())
	root.add_child(_build_action_button_bar())
	root.add_child(_build_player_area())


func _build_top_status_bar() -> Control:
	var top_status := PanelContainer.new()
	top_status.name = "TopStatusBar"
	top_status.custom_minimum_size = Vector2(0, 38)
	top_status.add_theme_stylebox_override("panel", inactive_panel_style)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_status.add_child(top_row)
	active_label = Label.new()
	active_label.text = "梦潮：承道"
	active_label.custom_minimum_size = Vector2(760, 0)
	active_label.clip_text = true
	top_row.add_child(active_label)
	operation_hint_label = Label.new()
	operation_hint_label.name = "OperationHintBar"
	operation_hint_label.text = "请选择手牌后点击中央战场区打出"
	operation_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operation_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_row.add_child(operation_hint_label)
	return top_status


func _build_opponent_area() -> Control:
	var panel := PanelContainer.new()
	panel.name = "OpponentArea"
	panel.custom_minimum_size = Vector2(0, 92)
	panel.add_theme_stylebox_override("panel", inactive_panel_style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	if game_mode == "pve":
		var left_spacer := Control.new()
		left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left_spacer)

		var enemy_panel := PanelContainer.new()
		enemy_panel.name = "EnemyArea"
		enemy_panel.custom_minimum_size = Vector2(420, 0)
		enemy_panel.add_theme_stylebox_override("panel", opponent_frame_style)
		row.add_child(enemy_panel)
		var enemy_row := HBoxContainer.new()
		enemy_row.add_theme_constant_override("separation", 10)
		enemy_panel.add_child(enemy_row)

		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(128, 76)
		portrait_frame.add_theme_stylebox_override("panel", opponent_card_style)
		enemy_row.add_child(portrait_frame)
		var portrait_label := Label.new()
		portrait_label.text = "◆\n敌人立绘\n回潮孽物"
		portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		portrait_frame.add_child(portrait_label)

		enemy_info_label = Label.new()
		enemy_info_label.custom_minimum_size = Vector2(160, 0)
		enemy_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		enemy_row.add_child(enemy_info_label)

		enemy_target_button = Button.new()
		enemy_target_button.text = "敌人目标"
		enemy_target_button.custom_minimum_size = Vector2(120, 0)
		enemy_target_button.tooltip_text = "道法、承道兽攻击和道主道击可以指向这里"
		_apply_button_style(enemy_target_button, opponent_card_style)
		enemy_target_button.pressed.connect(_on_enemy_target_pressed)
		enemy_row.add_child(enemy_target_button)
		opponent_target_button = enemy_target_button

		var right_spacer := Control.new()
		right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(right_spacer)
		return panel

	opponent_hand_overview = HBoxContainer.new()
	opponent_hand_overview.name = "OpponentLeftCategoryGroup"
	opponent_hand_overview.custom_minimum_size = Vector2(260, 0)
	opponent_hand_overview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_hand_overview.add_theme_constant_override("separation", 4)
	row.add_child(opponent_hand_overview)
	opponent_portrait_panel = _build_portrait_panel("敌方道主", false)
	opponent_portrait_panel.name = "OpponentDaoMasterCenterPanel"
	row.add_child(opponent_portrait_panel)
	opponent_hand_overview_right = HBoxContainer.new()
	opponent_hand_overview_right.name = "OpponentRightCategoryGroup"
	opponent_hand_overview_right.custom_minimum_size = Vector2(260, 0)
	opponent_hand_overview_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_hand_overview_right.add_theme_constant_override("separation", 4)
	row.add_child(opponent_hand_overview_right)
	return panel


func _build_middle_battle_area() -> Control:
	var row := HBoxContainer.new()
	row.name = "MainBattleArea"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.add_child(_build_left_side_panel())
	row.add_child(_build_central_battlefield_panel())
	row.add_child(_build_right_side_panel())
	return row


func _build_player_area() -> Control:
	var panel := PanelContainer.new()
	panel.name = "PlayerArea"
	panel.custom_minimum_size = Vector2(0, 190)
	panel.add_theme_stylebox_override("panel", active_panel_style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)

	var top_row := HBoxContainer.new()
	top_row.name = "PlayerDaoMasterAndCategoryRow"
	top_row.custom_minimum_size = Vector2(0, 62)
	top_row.add_theme_constant_override("separation", 10)
	layout.add_child(top_row)

	top_row.add_child(_build_player_category_group("PlayerLeftCategoryGroup", ["命器", "道痕", "承道"]))
	player_portrait_panel = _build_portrait_panel("我方道主", true)
	player_portrait_panel.name = "PlayerDaoMasterCenterPanel"
	top_row.add_child(player_portrait_panel)
	top_row.add_child(_build_player_category_group("PlayerRightCategoryGroup", ["道法", "伏法", "域界"]))

	var bottom_row := HBoxContainer.new()
	bottom_row.name = "PlayerCardAndBufferRow"
	bottom_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_row.add_theme_constant_override("separation", 8)
	layout.add_child(bottom_row)
	bottom_row.add_child(_build_category_hand_area())
	return panel


func _build_player_category_group(group_name: String, categories: Array) -> Control:
	var group := HBoxContainer.new()
	group.name = group_name
	group.custom_minimum_size = Vector2(260, 0)
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.add_theme_constant_override("separation", 5)
	for category in categories:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s 0" % category
		button.pressed.connect(_on_hand_category_pressed.bind(category))
		_apply_button_style(button, dim_button_style)
		button.add_theme_font_size_override("font_size", 15)
		group.add_child(button)
		hand_category_buttons[category] = button
	return group


func _build_portrait_panel(title: String, is_player_area: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "DaoMasterPortraitPanel"
	panel.custom_minimum_size = Vector2(220, 0)
	panel.add_theme_stylebox_override("panel", player_frame_style if is_player_area else opponent_frame_style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.custom_minimum_size = Vector2(0, 44)
	portrait_frame.add_theme_stylebox_override("panel", player_card_style if is_player_area else opponent_card_style)
	box.add_child(portrait_frame)

	var portrait := Label.new()
	portrait.text = "◆\n%s\n道主立绘" % title
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.add_theme_font_size_override("font_size", 14)
	portrait_frame.add_child(portrait)

	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	var target_button := Button.new()
	target_button.text = "道主目标"
	target_button.tooltip_text = "道法牌和承道兽攻击可以指向这里"
	_apply_button_style(target_button, player_card_style if is_player_area else opponent_card_style)
	target_button.pressed.connect(_on_visible_dao_master_target_pressed.bind(not is_player_area))
	box.add_child(target_button)
	if is_player_area:
		player_portrait_label = label
		player_portrait_art_label = portrait
		player_target_button = target_button
	else:
		opponent_portrait_label = label
		opponent_portrait_art_label = portrait
		opponent_target_button = target_button
	return panel


func _build_left_side_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "LeftSidePanel"
	panel.custom_minimum_size = Vector2(145, 0)
	panel.add_theme_stylebox_override("panel", inactive_panel_style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	deck_pile_label = Label.new()
	deck_pile_label.text = "主卡组牌堆\n▣\n-- / 40\n未抽取不可查看"
	deck_pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(deck_pile_label)
	resource_summary_label = Label.new()
	resource_summary_label.text = "资源摘要"
	resource_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(resource_summary_label)
	return panel


func _build_central_battlefield_panel() -> Control:
	central_battlefield_panel = PanelContainer.new()
	central_battlefield_panel.name = "CentralBattlefieldArea"
	central_battlefield_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	central_battlefield_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	central_battlefield_panel.add_theme_stylebox_override("panel", active_panel_style)
	var central_layout := VBoxContainer.new()
	central_layout.add_theme_constant_override("separation", 8)
	central_battlefield_panel.add_child(central_layout)
	central_battlefield_button = Button.new()
	central_battlefield_button.text = "中央战场区\n选择手牌后点击这里打出。"
	central_battlefield_button.custom_minimum_size = Vector2(0, 40)
	central_battlefield_button.add_theme_stylebox_override("normal", dark_panel_style)
	central_battlefield_button.add_theme_stylebox_override("hover", active_panel_style)
	central_battlefield_button.pressed.connect(_on_central_battlefield_pressed)
	central_layout.add_child(central_battlefield_button)
	var central_scroll := ScrollContainer.new()
	central_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	central_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	central_layout.add_child(central_scroll)
	central_battlefield_grid = GridContainer.new()
	central_battlefield_grid.columns = 3
	central_battlefield_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	central_battlefield_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	central_battlefield_grid.add_theme_constant_override("h_separation", 10)
	central_battlefield_grid.add_theme_constant_override("v_separation", 10)
	central_scroll.add_child(central_battlefield_grid)
	return central_battlefield_panel


func _build_right_side_panel() -> Control:
	info_tabs = TabContainer.new()
	info_tabs.name = "RightSidePanel"
	info_tabs.custom_minimum_size = Vector2(220, 0)
	info_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_scroll := ScrollContainer.new()
	detail_scroll.name = "选中卡详情"
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_tabs.add_child(detail_scroll)
	selected_detail_label = Label.new()
	selected_detail_label.text = "尚未选择手牌。"
	selected_detail_label.custom_minimum_size = Vector2(200, 0)
	selected_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_scroll.add_child(selected_detail_label)
	log_view = RichTextLabel.new()
	log_view.name = "战斗日志"
	log_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.bbcode_enabled = false
	log_view.scroll_following = true
	log_view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_tabs.add_child(log_view)
	return info_tabs


func _build_action_button_bar() -> Control:
	var action_row := HBoxContainer.new()
	action_row.name = "ActionButtonBar"
	action_row.custom_minimum_size = Vector2(0, 34)
	action_row.add_theme_constant_override("separation", 8)
	var help_button := Button.new()
	help_button.text = "操作说明"
	_apply_button_style(help_button, dim_button_style)
	help_button.pressed.connect(_on_help_pressed)
	action_row.add_child(help_button)
	var tutorial_button := Button.new()
	tutorial_button.text = "新手演示"
	_apply_button_style(tutorial_button, dim_button_style)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	action_row.add_child(tutorial_button)
	attack_button = Button.new()
	attack_button.text = "承道兽攻击"
	_apply_button_style(attack_button, dim_button_style)
	attack_button.pressed.connect(_on_basic_attack_pressed)
	action_row.add_child(attack_button)
	dao_strike_button = Button.new()
	dao_strike_button.text = "道主道击"
	_apply_button_style(dao_strike_button, dim_button_style)
	dao_strike_button.pressed.connect(_on_dao_strike_pressed)
	action_row.add_child(dao_strike_button)
	breakthrough_button = Button.new()
	breakthrough_button.text = "突破"
	breakthrough_button.disabled = true
	_apply_button_style(breakthrough_button, dim_button_style)
	breakthrough_button.pressed.connect(_on_breakthrough_pressed)
	action_row.add_child(breakthrough_button)
	end_turn_button = Button.new()
	end_turn_button.text = "结束回合"
	end_turn_button.custom_minimum_size = Vector2(96, 0)
	_apply_button_style(end_turn_button, gold_button_style)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	action_row.add_child(end_turn_button)
	next_round_button = Button.new()
	next_round_button.text = "进入下一局"
	next_round_button.disabled = true
	_apply_button_style(next_round_button, gold_button_style)
	next_round_button.pressed.connect(_on_next_round_pressed)
	action_row.add_child(next_round_button)
	restart_button = Button.new()
	restart_button.text = "重新开始 Match"
	_apply_button_style(restart_button, dim_button_style)
	restart_button.pressed.connect(_on_restart_pressed)
	action_row.add_child(restart_button)
	return action_row


func _build_category_hand_area() -> Control:
	hand_area_panel = PanelContainer.new()
	hand_area_panel.name = "CurrentCategoryCardsArea"
	hand_area_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_area_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_area_panel.add_theme_stylebox_override("panel", active_panel_style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	hand_area_panel.add_child(box)
	var filter_row := HBoxContainer.new()
	filter_row.name = "ChengdaoFilterRow"
	filter_row.add_theme_constant_override("separation", 6)
	box.add_child(filter_row)
	for filter in ["全部", "秩序侧", "混沌侧"]:
		var button := Button.new()
		button.text = filter
		button.pressed.connect(_on_chengdao_filter_pressed.bind(filter))
		filter_row.add_child(button)
		chengdao_filter_buttons[filter] = button
	hand_category_label = Label.new()
	hand_category_label.text = "当前分类：承道    手牌 0 / 10"
	box.add_child(hand_category_label)
	var hand_scroll := ScrollContainer.new()
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(hand_scroll)
	hand_view = HandView.new()
	hand_view.name = "CategoryHandView"
	hand_view.custom_minimum_size = Vector2(0, 158)
	hand_view.card_selected.connect(_on_card_selected.bind("hand"))
	hand_scroll.add_child(hand_view)
	return hand_area_panel


func _start_match() -> void:
	current_match_round = 1
	player1_match_wins = 0
	player2_match_wins = 0
	player1_used_characters.clear()
	player2_used_characters.clear()
	match_over = false
	match_winner = ""
	if log_view != null:
		log_view.clear()
	_start_local_battle()


func _start_pve_battle() -> void:
	card_load_error = ""
	game_over = false
	selected_card = {}
	selected_card_view = null
	selected_card_source = ""
	selected_attacker = {"player_index": -1, "slot_index": -1}
	discard_phase = false
	need_discard = 0
	discard_phase_player_id = ""
	draw_pile.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	current_hand_category = "承道"
	current_chengdao_filter = "全部"
	tutorial_step = 0
	extra_stats.clear()
	active_dao_masters.clear()
	dao_strike_used.clear()
	match_over = false
	match_winner = ""
	for board in player_boards:
		board.reset_board()
	if log_view != null:
		log_view.clear()

	pve_card_catalog = null
	pve_effect_adapter = PveCardEffectAdapterScript.new()
	pve_beast_runtime = PveBeastRuntimeScript.new()
	pve_beast_runtime.reset()
	pve_event_queue = PveCombatEventQueueScript.new()
	pve_event_queue.reset()
	pve_status_runtime = PveStatusRuntimeScript.new()
	pve_status_runtime.reset()
	pve_pulse_runtime = PvePulseRuntimeScript.new()
	pve_pulse_runtime.reset()
	pve_card_data_mode = "legacy_fallback"
	pve_card_fallback_reason = ""
	var run_state = RunStateScript.get_current()
	var has_run_state := run_state != null and bool(run_state.run_started)
	var starter_deck_ids: Array[String] = []
	var player_master: Dictionary = {}
	var pve_deck: Array[Dictionary] = []
	var use_v1_run := has_run_state and bool(run_state.uses_pve_card_v1) and str(run_state.card_data_version) == "pve_v1" and str(run_state.starter_deck_path) != ""
	if use_v1_run:
		player_master = run_state.to_daomaster_card()
		var v1_setup := _build_v1_pve_deck(run_state)
		if not bool(v1_setup.get("ok", false)):
			_start_pve_battle_load_error(str(v1_setup.get("reason", "v1 卡池读取失败。")), run_state)
			return
		pve_deck = v1_setup.get("deck", [])
		pve_card_data_mode = "pve_v1"
		_log("[BattleScene] PVE card data mode: pve_v1")
		_log("[BattleScene] v1 deck loaded: %s / %d cards." % [run_state.selected_daomaster_id, pve_deck.size()])
	else:
		var cards := _load_cards()
		if has_run_state:
			player_master = run_state.to_daomaster_card()
			starter_deck_ids = _run_deck_ids(run_state)
			pve_card_fallback_reason = "RunState 未启用 v1 卡池。"
		else:
			pve_card_fallback_reason = "未检测到 RunState。"
			_log("未检测到 RunState，使用测试道主 fallback。")
			var character_lineup := _load_character_lineup(cards)
			starter_deck_ids = _load_pve_starter_deck_ids("starter_zaiheng")
			player_master = character_lineup[0] if character_lineup.size() > 0 else {}
			player_master["passive_id"] = "hengjie"
			player_master["passive_name"] = "衡界"
			player_master["passive_desc"] = "每个玩家回合第一次获得阵势时，额外获得 2 点阵势。"
		pve_deck = _make_deck(cards, starter_deck_ids, 0)
		_log("[BattleScene] PVE card data mode: legacy_fallback")
		_log("[BattleScene] fallback reason: %s" % pve_card_fallback_reason)
	var player := _create_player_from_dao_master("p1", "玩家", player_master)
	if has_run_state:
		_apply_run_state_to_player(player, run_state)
	passive_runtime = PassiveRuntimeScript.new()
	if has_run_state:
		passive_runtime.setup(self, run_state)
	else:
		passive_runtime.setup_fallback(self, "hengjie", "衡界", "每个玩家回合第一次获得阵势时，额外获得 2 点阵势。")
	passive_runtime.reset_for_battle()
	var enemy_dummy := PlayerState.new("enemy_dummy", "敌人", Realm.Rank.HUANG_RANG, [])
	enemy_dummy.max_life_source = 80
	enemy_dummy.life_source = 80
	player.deck.clear()
	player.hand.clear()
	game_state = GameState.new([player, enemy_dummy])
	game_state.active_player_index = 0
	dao_strike_used[player.id] = false
	_setup_pve_piles_from_deck(pve_deck)
	_reset_pve_enemy()
	if has_run_state:
		_log("PVE RunState 已接入：%s，牌组 %d 张。" % [_dao_master_name(player), pve_deck.size()])
		_log(run_state.debug_summary())
	if passive_runtime != null and passive_runtime.get_passive_name() != "":
		_log("道主被动：%s。" % passive_runtime.get_passive_name())
	_log("PVE 战斗开始：%s 对阵 %s。" % [_dao_master_name(player), str(enemy.get("name", "敌人"))])
	_start_pve_player_turn(player, true)


func _reset_pve_enemy() -> void:
	enemy = {
		"id": "reflux_spawn",
		"name": "回潮孽物",
		"max_life": 80,
		"life": 80,
		"intent": "attack",
		"intent_value": 12,
		"block": 0,
		"turn_index": 0
	}
	_set_enemy_intent()


func _set_enemy_intent() -> void:
	if enemy.is_empty():
		return
	var step := int(enemy.get("turn_index", 0)) % 3
	if step == 0:
		enemy["intent"] = "attack"
		enemy["intent_value"] = 12
		enemy["pulse_id"] = ""
		enemy["pulse_value"] = 0
		enemy["conductive"] = false
	elif step == 1:
		enemy["intent"] = "fire_attack"
		enemy["intent_value"] = 8
		enemy["pulse_id"] = "fire"
		enemy["pulse_value"] = 4
		enemy["conductive"] = false
	else:
		enemy["intent"] = "buff"
		enemy["intent_value"] = 6
		enemy["pulse_id"] = ""
		enemy["pulse_value"] = 0
		enemy["conductive"] = false


func _run_deck_ids(run_state) -> Array[String]:
	var ids: Array[String] = []
	for card_id in run_state.current_deck:
		ids.append(str(card_id))
	return ids


func _build_v1_pve_deck(run_state) -> Dictionary:
	var result := {"ok": false, "reason": "", "deck": []}
	pve_card_catalog = PveCardV1CatalogScript.new()
	if not pve_card_catalog.load_catalog():
		result.reason = "v1 卡池读取失败：%s" % str(pve_card_catalog.get_load_errors())
		return result
	var deck_result: Dictionary = pve_card_catalog.load_starter_deck(
		str(run_state.starter_deck_path),
		str(run_state.selected_daomaster_id),
		{"dao_tags": run_state.dao_tags}
	)
	if not bool(deck_result.get("ok", false)):
		result.reason = "v1 初始牌组无效：%s" % str(deck_result.get("errors", []))
		return result
	var card_ids: Array = deck_result.get("card_ids", []).duplicate(true)
	var instances: Array = pve_card_catalog.build_battle_instances(card_ids)
	if instances.size() != card_ids.size():
		result.reason = "v1 战斗实例数量异常：%d / %d。" % [instances.size(), card_ids.size()]
		return result
	result.ok = true
	result.deck = instances
	return result


func _start_pve_battle_load_error(reason: String, run_state) -> void:
	pve_beast_runtime = PveBeastRuntimeScript.new()
	pve_beast_runtime.reset()
	pve_event_queue = PveCombatEventQueueScript.new()
	pve_event_queue.reset()
	pve_status_runtime = PveStatusRuntimeScript.new()
	pve_status_runtime.reset()
	pve_pulse_runtime = PvePulseRuntimeScript.new()
	pve_pulse_runtime.reset()
	pve_card_data_mode = "pve_v1_error"
	card_load_error = reason
	push_error("[BattleScene] %s" % reason)
	var player_master: Dictionary = run_state.to_daomaster_card() if run_state != null else {}
	var player := _create_player_from_dao_master("p1", "玩家", player_master)
	if run_state != null:
		_apply_run_state_to_player(player, run_state)
	var enemy_dummy := PlayerState.new("enemy_dummy", "敌人", Realm.Rank.HUANG_RANG, [])
	enemy_dummy.max_life_source = 80
	enemy_dummy.life_source = 80
	game_state = GameState.new([player, enemy_dummy])
	game_state.active_player_index = 0
	_reset_pve_enemy()
	game_over = true
	_log("PVE 战斗无法开始：%s" % reason)
	if operation_hint_label != null:
		operation_hint_label.text = "v1 卡池加载失败，请查看 Output。"
	_refresh_all()


func _apply_run_state_to_player(player: PlayerState, run_state) -> void:
	player.max_life_source = int(run_state.max_life)
	player.life_source = int(run_state.current_life)
	player.formation_value = int(run_state.formation)
	player.dao_progress = int(run_state.daoxing)
	extra_stats[player.id] = {
		"dao_breath": int(run_state.current_daoxi),
		"return_tide": int(run_state.reflux)
	}


func _start_local_battle() -> void:
	card_load_error = ""
	game_over = false
	selected_card = {}
	selected_card_view = null
	selected_card_source = ""
	selected_attacker = {"player_index": -1, "slot_index": -1}
	discard_phase = false
	need_discard = 0
	discard_phase_player_id = ""
	current_hand_category = "承道"
	current_chengdao_filter = "全部"
	tutorial_step = 0
	extra_stats.clear()
	active_dao_masters.clear()
	dao_strike_used.clear()
	for board in player_boards:
		board.reset_board()
	var cards := _load_cards()
	var character_lineup := _load_character_lineup(cards)
	var starter_deck_ids := _load_starter_main_deck_ids()
	var p1_master_index := _match_character_index(current_match_round, 0)
	var p2_master_index := _match_character_index(current_match_round, 1)
	var p1_master: Dictionary = character_lineup[p1_master_index] if character_lineup.size() > p1_master_index else {}
	var p2_master: Dictionary = character_lineup[p2_master_index] if character_lineup.size() > p2_master_index else {}
	_record_used_character(player1_used_characters, p1_master)
	_record_used_character(player2_used_characters, p2_master)
	var p1 := _create_player_from_dao_master("p1", "玩家一", p1_master)
	var p2 := _create_player_from_dao_master("p2", "玩家二", p2_master)
	p1.deck = _make_deck(cards, starter_deck_ids, current_match_round - 1)
	p2.deck = _make_deck(cards, starter_deck_ids, current_match_round)
	game_state = GameState.new([p1, p2])
	dao_strike_used[p1.id] = false
	dao_strike_used[p2.id] = false
	_draw_opening_hand(p1)
	_draw_opening_hand(p2)
	_log("玩家一道主：%s" % str(p1_master.get("name", "未设置")))
	_log("玩家二道主：%s" % str(p2_master.get("name", "未设置")))
	_log("第 %d 局开始。当前版本使用占位卡面和基础结算。" % current_match_round)


func _match_character_index(round_number: int, player_index: int) -> int:
	if player_index == 0:
		return clampi(round_number - 1, 0, 2)
	return round_number % 3


func _record_used_character(used: Array[String], card: Dictionary) -> void:
	var name := str(card.get("name", "未设置"))
	if name != "" and not used.has(name):
		used.append(name)


func _load_cards() -> Array[Dictionary]:
	var file := FileAccess.open(CARD_DATA_PATH, FileAccess.READ)
	if file == null:
		card_load_error = "无法读取测试卡数据：%s" % CARD_DATA_PATH
		push_error(card_load_error)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		card_load_error = "测试卡 JSON 格式不是数组：%s" % CARD_DATA_PATH
		push_error(card_load_error)
		return []
	var cards: Array[Dictionary] = []
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			cards.append(item)
	if cards.is_empty():
		card_load_error = "测试卡数据为空：%s" % CARD_DATA_PATH
	return cards


func _load_character_lineup(cards: Array[Dictionary]) -> Array[Dictionary]:
	var file := FileAccess.open(STARTER_CHARACTER_LINEUP_PATH, FileAccess.READ)
	if file == null:
		card_load_error = "无法读取人物阵列：%s" % STARTER_CHARACTER_LINEUP_PATH
		push_error(card_load_error)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		card_load_error = "人物阵列 JSON 格式不是对象：%s" % STARTER_CHARACTER_LINEUP_PATH
		push_error(card_load_error)
		return []
	var lineup_data: Dictionary = parsed
	var character_ids: Array = lineup_data.get("characters", [])
	if character_ids.size() != 3:
		card_load_error = "人物阵列数量必须为 3，当前为 %d。" % character_ids.size()
		push_error(card_load_error)
		return []
	var cards_by_id := {}
	for card in cards:
		cards_by_id[str(card.get("id", ""))] = card
	var lineup: Array[Dictionary] = []
	for character_id in character_ids:
		var id_text := str(character_id)
		if not cards_by_id.has(id_text):
			card_load_error = "人物阵列引用了不存在的人物牌：%s" % id_text
			push_error(card_load_error)
			return []
		var character_card: Dictionary = cards_by_id[id_text]
		if str(character_card.get("type", "")) != "character":
			card_load_error = "人物阵列只能包含 type 为 character 的牌：%s" % str(character_card.get("name", id_text))
			push_error(card_load_error)
			return []
		lineup.append(character_card.duplicate(true))
	print("[BattleScene] character lineup loaded: %d" % lineup.size())
	return lineup


func _load_starter_main_deck_ids() -> Array[String]:
	var file := FileAccess.open(STARTER_MAIN_DECK_PATH, FileAccess.READ)
	if file == null:
		card_load_error = "无法读取初始主卡组：%s" % STARTER_MAIN_DECK_PATH
		push_error(card_load_error)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		card_load_error = "初始主卡组 JSON 格式不是对象：%s" % STARTER_MAIN_DECK_PATH
		push_error(card_load_error)
		return []
	var deck_data: Dictionary = parsed
	var raw_cards: Array = deck_data.get("cards", [])
	if raw_cards.is_empty():
		card_load_error = "初始主卡组没有 cards 列表：%s" % STARTER_MAIN_DECK_PATH
		push_error(card_load_error)
		return []
	if raw_cards.size() != MAIN_DECK_SIZE:
		card_load_error = "初始主卡组必须为 %d 张，当前为 %d 张。" % [MAIN_DECK_SIZE, raw_cards.size()]
		push_error(card_load_error)
		return []
	var ids: Array[String] = []
	for card_id in raw_cards:
		ids.append(str(card_id))
	return ids


func _load_pve_starter_deck_ids(deck_id: String) -> Array[String]:
	var deck_path := "%s%s.json" % [PVE_STARTER_DECK_DIR, deck_id]
	var file := FileAccess.open(deck_path, FileAccess.READ)
	if file == null:
		card_load_error = "无法读取 PVE 初始牌组：%s" % deck_path
		push_error(card_load_error)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		card_load_error = "PVE 初始牌组 JSON 格式不是对象：%s" % deck_path
		push_error(card_load_error)
		return []
	var deck_data: Dictionary = parsed
	var raw_cards: Array = deck_data.get("cards", [])
	if raw_cards.is_empty():
		card_load_error = "PVE 初始牌组没有 cards 列表：%s" % deck_path
		push_error(card_load_error)
		return []
	var ids: Array[String] = []
	for card_id in raw_cards:
		ids.append(str(card_id))
	return ids


func _make_deck(cards: Array[Dictionary], deck_ids: Array[String], offset: int) -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	if cards.is_empty() or deck_ids.is_empty():
		return deck
	var cards_by_id := {}
	for card in cards:
		cards_by_id[str(card.get("id", ""))] = card
	for i in range(deck_ids.size()):
		var card_id := deck_ids[(i + offset) % deck_ids.size()]
		if not cards_by_id.has(card_id):
			card_load_error = "初始主卡组引用了不存在的卡牌：%s" % card_id
			push_error(card_load_error)
			return []
		var source_card: Dictionary = cards_by_id[card_id]
		if str(source_card.get("type", "")) == "character":
			card_load_error = "主卡组不能包含人物牌：%s" % str(source_card.get("name", card_id))
			push_error(card_load_error)
			return []
		deck.append(source_card.duplicate(true))
	deck.shuffle()
	return deck


func _create_player_from_dao_master(player_id: String, display_name: String, dao_master: Dictionary) -> PlayerState:
	var dao_tags: Array[String] = []
	var raw_tags: Array = dao_master.get("dao_tags", [])
	for tag in raw_tags:
		dao_tags.append(str(tag))
	var base_realm := _get_character_int(dao_master, "base_realm", "base_realm", Realm.Rank.HUANG_RANG)
	var player := PlayerState.new(player_id, display_name, base_realm, dao_tags)
	active_dao_masters[player_id] = dao_master
	var base_life := _get_character_int(dao_master, "base_life", "life_source", Realm.get_life_source(base_realm))
	player.max_life_source = base_life
	player.life_source = base_life
	player.dao_progress = _get_character_int(dao_master, "base_daoxing", "dao_progress", 0)
	player.formation_value = _get_character_int(dao_master, "base_formation", "formation_value", 3)
	extra_stats[player.id] = {
		"dao_breath": _get_character_int(dao_master, "base_daoxi", "dao_breath", 2),
		"return_tide": _get_character_int(dao_master, "base_tide", "return_tide", 0)
	}
	return player


func _get_character_int(card: Dictionary, preferred_key: String, fallback_key: String, default_value: int) -> int:
	if card.has(preferred_key):
		return int(card.get(preferred_key, default_value))
	var card_name := str(card.get("name", "未知人物"))
	if card.has(fallback_key):
		push_warning("%s 缺少 %s，使用兼容字段 %s。" % [card_name, preferred_key, fallback_key])
		return int(card.get(fallback_key, default_value))
	push_warning("%s 缺少 %s，使用默认值 %d。" % [card_name, preferred_key, default_value])
	return default_value


func _draw_cards(player: PlayerState, amount: int) -> void:
	if game_mode == "pve":
		_draw_pve_cards(player, amount)
		return
	for i in range(amount):
		if player.deck.is_empty():
			return
		var card: Dictionary = player.deck.pop_front()
		var result := BattleEngine.handle_card_obtained(player, card, "draw")
		if not bool(result.get("ok", false)):
			_log("%s 抽牌触发%s，受到 %d 伤害。" % [player.display_name, str(result.get("reason", "")), int(result.get("actual_damage", 0))])
		else:
			_log("%s抽到【%s】，进入手牌。" % [player.display_name, str(card.get("name", "未知卡牌"))])


func _setup_pve_piles_from_deck(deck: Array[Dictionary]) -> void:
	draw_pile.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	if pve_beast_runtime != null:
		pve_beast_runtime.reset()
	for card in deck:
		draw_pile.append(card.duplicate(true))
	draw_pile.shuffle()
	_log("抽牌堆已建立：%d 张。" % draw_pile.size())


func _draw_pve_cards(player: PlayerState, amount: int) -> int:
	var drawn := 0
	for i in range(amount):
		if player.hand.size() >= HAND_LIMIT:
			_log("手牌已达上限，停止抽牌。")
			break
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				_log("无牌可抽。")
				break
			_shuffle_discard_into_draw_pile()
		if draw_pile.is_empty():
			_log("无牌可抽。")
			break
		var card: Dictionary = draw_pile.pop_front()
		var result := BattleEngine.handle_card_obtained(player, card, "draw")
		if not bool(result.get("ok", false)):
			_log("%s 抽牌触发%s，受到 %d 伤害。" % [player.display_name, str(result.get("reason", "")), int(result.get("actual_damage", 0))])
		else:
			drawn += 1
			_log("%s抽到【%s】，进入手牌。" % [player.display_name, str(card.get("name", "未知卡牌"))])
	_log("抽牌 %d 张。" % drawn)
	return drawn


func _shuffle_discard_into_draw_pile() -> void:
	for card in discard_pile:
		draw_pile.append(card.duplicate(true))
	discard_pile.clear()
	draw_pile.shuffle()
	_log("弃牌堆洗入抽牌堆。")


func gain_formation(amount: int, source: String = "", allow_passive: bool = true) -> int:
	if game_state == null or amount <= 0:
		return 0
	var player := game_state.get_active_player()
	player.formation_value += amount
	if allow_passive and game_mode == "pve" and passive_runtime != null:
		passive_runtime.on_formation_gained(amount, source)
	_sync_run_state_resources(player)
	return amount


func add_current_daoxi(amount: int, source: String = "") -> int:
	if game_state == null or amount == 0:
		return 0
	var player := game_state.get_active_player()
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = maxi(0, int(stats.get("dao_breath", 0)) + amount)
	extra_stats[player.id] = stats
	_sync_run_state_resources(player)
	return int(stats.get("dao_breath", 0))


func _put_card_into_pve_resolved_pile(card: Dictionary) -> void:
	if card.is_empty():
		return
	if _card_has_exhaust(card):
		exhaust_pile.append(card.duplicate(true))
		_log("【%s】进入消耗堆。" % str(card.get("name", "未知卡牌")))
	else:
		discard_pile.append(card.duplicate(true))
		_log("【%s】进入弃牌堆。" % str(card.get("name", "未知卡牌")))


func _card_has_retain(card: Dictionary) -> bool:
	return _card_has_keyword(card, ["凝梦", "保留"])


func _card_has_exhaust(card: Dictionary) -> bool:
	return _card_has_keyword(card, ["消耗"])


func _card_has_keyword(card: Dictionary, keywords: Array[String]) -> bool:
	var raw_keywords: Array = card.get("keywords", [])
	for keyword in raw_keywords:
		if keywords.has(str(keyword)):
			return true
	if _is_pve_v1_card(card):
		return false
	for field in ["effect_text", "description"]:
		var text := str(card.get(field, ""))
		for keyword in keywords:
			if text.find(keyword) >= 0:
				return true
	return false


func _is_pve_v1_card(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	if str(card.get("data_version", "")) == "pve_v1":
		return true
	if pve_effect_adapter != null:
		return pve_effect_adapter.is_v1_card(card)
	return false


func _draw_opening_hand(player: PlayerState) -> void:
	var source_deck := player.deck.duplicate(true)
	for retry in range(10):
		var candidate := source_deck.duplicate(true)
		candidate.shuffle()
		var opening := _first_cards(candidate, 5)
		var playable_count := _opening_playable_count(opening, player)
		print("[BattleScene] opening hand retry: %d" % (retry + 1))
		print("[BattleScene] opening hand playable count: %d" % playable_count)
		if _opening_hand_valid(opening, player):
			_accept_opening_hand(player, candidate)
			return
	var forced_deck := source_deck.duplicate(true)
	forced_deck.shuffle()
	var forced_opening := _build_forced_opening(forced_deck, player)
	print("[BattleScene] opening hand retry: 10")
	print("[BattleScene] opening hand playable count: %d" % _opening_playable_count(forced_opening, player))
	player.hand.clear()
	for card in forced_opening:
		player.hand.append(card)
	player.deck = forced_deck


func _first_cards(cards: Array, amount: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(mini(amount, cards.size())):
		result.append((cards[i] as Dictionary).duplicate(true))
	return result


func _accept_opening_hand(player: PlayerState, ordered_deck: Array) -> void:
	player.hand.clear()
	for i in range(5):
		if ordered_deck.is_empty():
			return
		player.hand.append(ordered_deck.pop_front())
	player.deck = ordered_deck


func _opening_hand_valid(hand: Array[Dictionary], player: PlayerState) -> bool:
	return _opening_has_playable_beast(hand, player) and _opening_playable_count(hand, player) >= 2 and _opening_high_realm_count(hand, player) <= 1


func _opening_has_playable_beast(hand: Array[Dictionary], player: PlayerState) -> bool:
	for card in hand:
		if str(card.get("type", "")) == CardTypes.CHENGDAO and _is_chengdao_beast(card) and _is_current_realm_playable(card, player):
			return true
	return false


func _opening_playable_count(hand: Array[Dictionary], player: PlayerState) -> int:
	var count := 0
	for card in hand:
		if _is_current_realm_playable(card, player):
			count += 1
	return count


func _opening_high_realm_count(hand: Array[Dictionary], player: PlayerState) -> int:
	var count := 0
	for card in hand:
		if _card_realm_requirement(card) > player.combat_realm + 2:
			count += 1
	return count


func _build_forced_opening(deck: Array, player: PlayerState) -> Array[Dictionary]:
	var opening: Array[Dictionary] = []
	_take_opening_card(deck, opening, player, "playable_beast")
	while _opening_playable_count(opening, player) < 2:
		if not _take_opening_card(deck, opening, player, "playable"):
			break
	while opening.size() < 5:
		if not _take_opening_card(deck, opening, player, "not_high"):
			if not _take_opening_card(deck, opening, player, "any"):
				break
	return opening


func _take_opening_card(deck: Array, opening: Array[Dictionary], player: PlayerState, mode: String) -> bool:
	for i in range(deck.size()):
		var card: Dictionary = deck[i]
		if _opening_card_matches(card, player, mode):
			opening.append(card)
			deck.remove_at(i)
			return true
	return false


func _opening_card_matches(card: Dictionary, player: PlayerState, mode: String) -> bool:
	if mode == "any":
		return true
	if mode == "playable":
		return _is_current_realm_playable(card, player)
	if mode == "playable_beast":
		return str(card.get("type", "")) == CardTypes.CHENGDAO and _is_chengdao_beast(card) and _is_current_realm_playable(card, player)
	if mode == "not_high":
		return _card_realm_requirement(card) <= player.combat_realm + 2
	return false


func _is_current_realm_playable(card: Dictionary, player: PlayerState) -> bool:
	return player.combat_realm >= _card_realm_requirement(card)


func _card_realm_requirement(card: Dictionary) -> int:
	if card.has("required_realm"):
		return int(card.get("required_realm", 0))
	if card.has("realm_requirement"):
		return int(card.get("realm_requirement", 0))
	if card.has("min_realm"):
		return int(card.get("min_realm", 0))
	return 0


func _on_card_selected(card: Dictionary, view: CardView, source: String) -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if source != "hand":
		_show_failure("请从手牌中选择。")
		return
	var player := game_state.get_active_player()
	if _find_card_index(_cards_for_source(player, source), card) < 0:
		_show_failure("该牌已不在当前区域，已刷新手牌。")
		_clear_selection()
		_refresh_all()
		return
	selected_card = card
	selected_card_view = view
	selected_card_source = source
	selected_attacker = {"player_index": -1, "slot_index": -1}
	_update_operation_hint()
	_update_selected_detail()
	if discard_phase and game_mode != "pve":
		_clear_board_highlights()
		_refresh_central_battlefield()
		_log("已选择要弃置的牌【%s】，请点击中央战场区确认弃置。" % str(card.get("name", "未知卡牌")))
		return
	_highlight_legal_targets()
	_refresh_central_battlefield()
	var unavailable_reason := _get_unavailable_reason(card, player)
	_log("%s选择了手牌【%s】" % [player.display_name, str(card.get("name", "未知卡牌"))])
	if unavailable_reason != "":
		_log("%s 不能使用【%s】：%s" % [player.display_name, str(card.get("name", "未知卡牌")), unavailable_reason])


func _on_central_battlefield_pressed() -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_confirm_discard_selected_card()
		return
	if _has_selected_attacker():
		_show_failure("请选择敌方道主或敌方承道兽作为攻击目标。")
		return
	if selected_card.is_empty():
		_show_failure("请先选择手牌或己方承道兽。")
		return
	var player := game_state.get_active_player()
	var card_type := str(selected_card.get("type", ""))
	if _is_pve_v1_card(selected_card) and card_type == CardTypes.DAOFA and not _v1_card_can_play_on_self(selected_card):
		_show_failure("道法牌需要选择敌人目标。")
		return
	if _is_pve_v1_card(selected_card):
		_play_v1_selected_card(player, "self")
		return
	if card_type == CardTypes.DAOFA:
		_show_failure("道法牌需要选择敌方道主或敌方承道兽。")
		return
	if card_type == "character":
		_show_failure("人物牌只能作为道主，不能进入承道位。")
		return
	if card_type == CardTypes.CHENGDAO and not _is_chengdao_beast(selected_card):
		_show_failure("承道位只允许秩序兽或混沌兽。")
		return
	var unavailable_reason := _get_unavailable_reason(selected_card, player)
	if unavailable_reason != "":
		_show_failure(unavailable_reason)
		return
	var slot_type := _expected_slot_for_card(card_type)
	if slot_type == "" or slot_type == "敌方目标" or slot_type == "道主位":
		_show_failure("该牌不能作为持续牌打入中央战场区。")
		return
	var board_index := game_state.active_player_index
	var slot_index := _find_play_slot(board_index, slot_type)
	if slot_index < 0:
		_show_failure(_central_limit_reason(slot_type))
		return
	if slot_type == CardTypes.DOMAIN and not player_boards[board_index].is_slot_empty(slot_type, slot_index):
		var replaced := player_boards[board_index].remove_card(slot_type, slot_index)
		if not replaced.is_empty():
			if game_mode == "pve":
				discard_pile.append(replaced.duplicate(true))
			else:
				player.discard_pile.append(replaced)
			_log("域界位已有域界，【%s】被替换并进入弃牌区。" % str(replaced.get("name", "")))
	var result := _play_non_daofa_card(player, selected_card)
	if not bool(result.get("ok", false)):
		_show_failure(_friendly_failure_reason(result))
		_discard_selected_if_needed(player, result)
		_refresh_all()
		return
	var card_name := str(selected_card.get("name", ""))
	_pay_card_cost(player, selected_card)
	Breakthrough.add_dao_progress(player, 5)
	var card_to_place := selected_card.duplicate(true)
	if card_type == CardTypes.CHENGDAO:
		card_to_place = _prepare_chengdao_beast_card(card_to_place)
	player_boards[board_index].place_card(slot_type, slot_index, card_to_place)
	_apply_simple_enter_effect(player, card_to_place)
	_remove_selected_from_source(player)
	if game_mode == "pve" and card_type == CardTypes.CHENGDAO:
		_put_card_into_pve_resolved_pile(selected_card)
	_log("%s打出了【%s】" % [player.display_name, card_name])
	_log("【%s】进入中央战场区：%s" % [card_name, _slot_display_name(slot_type)])
	var resonance_log := _resonance_message(selected_card, player, true)
	if resonance_log != "":
		_log(resonance_log)
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _on_dao_master_target_pressed(board_index: int) -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段只能选择手牌并点击中央战场区弃置。")
		return
	var active_index := game_state.active_player_index
	var player := game_state.players[active_index]
	var target := game_state.players[1 - active_index]
	if board_index == active_index:
		_show_failure("道法牌和攻击需要选择敌方道主目标。")
		return
	if not selected_card.is_empty():
		if str(selected_card.get("type", "")) == CardTypes.DAOFA:
			_play_daofa(player, target, "target", 0)
			return
		_show_failure("只有道法牌可以选择敌方道主目标。")
		return
	if _has_selected_attacker():
		_basic_attack_with_beast(player, target, int(selected_attacker.get("slot_index", -1)))
		return
	_show_failure("请先选择道法牌或己方承道兽。")


func _on_battlefield_card_pressed(owner_index: int, slot_type: String, slot_index: int) -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段不能操作战场牌。")
		return
	var active_index := game_state.active_player_index
	var player := game_state.players[active_index]
	var target := game_state.players[1 - active_index]
	if not selected_card.is_empty():
		if str(selected_card.get("type", "")) == CardTypes.DAOFA and owner_index != active_index and slot_type == CardTypes.CHENGDAO:
			_play_daofa(player, target, slot_type, slot_index)
			return
		if str(selected_card.get("type", "")) == CardTypes.DAOFA:
			_show_failure("道法牌需要选择敌方道主或敌方承道兽。")
			return
		_show_failure("持续牌请点击中央战场区空白处打出。")
		return
	if _has_selected_attacker():
		if owner_index != active_index and slot_type == CardTypes.CHENGDAO:
			_basic_attack_with_beast_to_beast(player, target, int(selected_attacker.get("slot_index", -1)), slot_index)
			return
		_show_failure("承道兽攻击需要选择敌方道主或敌方承道兽。")
		return
	if owner_index == active_index and slot_type == CardTypes.CHENGDAO:
		_select_attacker(slot_index)
		return
	_show_failure("请选择手牌，或点击己方承道兽作为攻击者。")


func _on_board_slot_selected(slot_type: String, index: int, board_index: int) -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段只能选择手牌并点击中央战场区弃置。")
		return
	var active_index := game_state.active_player_index
	var player := game_state.players[active_index]
	var target := game_state.players[1 - active_index]
	var card_type := str(selected_card.get("type", ""))
	if selected_card.is_empty() and board_index != active_index and slot_type == "target":
		var ready_index := _first_ready_chengdao_index(active_index)
		if ready_index >= 0:
			_basic_attack_with_beast(player, target, ready_index)
		else:
			_show_failure("没有可攻击的承道兽。")
		return
	if selected_card.is_empty() and board_index == active_index and slot_type == CardTypes.CHENGDAO and not player_boards[board_index].is_slot_empty(slot_type, index):
		_basic_attack_with_beast(player, target, index)
		return
	if selected_card.is_empty() and board_index != active_index:
		_show_failure("不是当前玩家的可操作区域。")
		return
	if selected_card.is_empty():
		_show_failure("请先选择一张手牌。")
		return

	var unavailable_reason := _get_unavailable_reason(selected_card, player)
	if unavailable_reason != "":
		_show_failure(unavailable_reason)
		return
	if board_index != active_index:
		if card_type == CardTypes.DAOFA and (slot_type == "target" or slot_type == CardTypes.CHENGDAO):
			if slot_type == CardTypes.CHENGDAO and player_boards[board_index].is_slot_empty(slot_type, index):
				_show_failure("目标区域错误。")
				return
			_play_daofa(player, target, slot_type, index)
			return
		if card_type == CardTypes.DAOFA:
			_show_failure("道法牌需要选择敌方目标。")
		else:
			_show_failure("不是当前玩家的可操作区域。")
		return
	if card_type == CardTypes.DAOFA:
		_show_failure("道法牌需要选择敌方目标。")
		return

	if card_type == "character":
		_show_failure("人物牌只能作为道主，不能进入承道位。")
		return
	if card_type == CardTypes.CHENGDAO and not _is_chengdao_beast(selected_card):
		_show_failure("承道位只允许秩序兽或混沌兽。")
		return
	if not _can_slot_accept_card(slot_type, card_type):
		_show_failure(_wrong_slot_reason(card_type))
		return
	if not player_boards[board_index].is_slot_empty(slot_type, index):
		if slot_type == CardTypes.DOMAIN and card_type == CardTypes.DOMAIN:
			var replaced := player_boards[board_index].remove_card(slot_type, index)
			if not replaced.is_empty():
				if game_mode == "pve":
					discard_pile.append(replaced.duplicate(true))
				else:
					player.discard_pile.append(replaced)
				_log("域界位已有域界，【%s】被替换并进入弃牌区。" % str(replaced.get("name", "")))
		else:
			_show_failure(_occupied_slot_reason(slot_type))
			return

	var result := _play_non_daofa_card(player, selected_card)
	if not bool(result.get("ok", false)):
		_show_failure(_friendly_failure_reason(result))
		_discard_selected_if_needed(player, result)
		_refresh_all()
		return

	var card_name := str(selected_card.get("name", ""))
	_pay_card_cost(player, selected_card)
	Breakthrough.add_dao_progress(player, 5)
	var card_to_place := selected_card.duplicate(true)
	if card_type == CardTypes.CHENGDAO:
		card_to_place = _prepare_chengdao_beast_card(card_to_place)
	player_boards[board_index].place_card(slot_type, index, card_to_place)
	_apply_simple_enter_effect(player, card_to_place)
	_remove_selected_from_source(player)
	if game_mode == "pve" and card_type == CardTypes.CHENGDAO:
		_put_card_into_pve_resolved_pile(selected_card)
	_log("%s打出了【%s】" % [player.display_name, card_name])
	_log("【%s】进入了%s" % [card_name, _slot_display_name(slot_type)])
	var resonance_log := _resonance_message(selected_card, player, true)
	if resonance_log != "":
		_log(resonance_log)
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _play_v1_selected_card(player: PlayerState, target_mode: String) -> void:
	if selected_card.is_empty():
		_show_failure("请先选择手牌。")
		return
	var hand_entry := _get_selected_hand_entry(player)
	if not bool(hand_entry.get("ok", false)):
		_show_failure(str(hand_entry.get("reason", "该牌已不在手牌中。")))
		_refresh_all()
		return
	var card: Dictionary = hand_entry.get("card", {})
	var unavailable_reason := _get_unavailable_reason(card, player)
	if unavailable_reason != "":
		_show_failure(unavailable_reason)
		return
	var summon_plan := _build_v1_summon_plan(player, card, target_mode, int(hand_entry.get("index", -1)))
	var validation_reason := _validate_v1_target_and_capacity(card, target_mode, summon_plan)
	if validation_reason != "":
		_show_failure(validation_reason)
		return
	var card_name := str(card.get("name", "未知卡牌"))
	var before_daoxi: int = _get_current_daoxi(player)
	_pay_card_cost(player, card)
	var resolved_card := _remove_hand_card_at(player, int(hand_entry.get("index", -1)), card)
	if resolved_card.is_empty():
		_set_current_daoxi(player, before_daoxi)
		_show_failure("该牌已不在手牌中。")
		_refresh_all()
		return
	if not summon_plan.is_empty():
		var register_result: Dictionary = pve_beast_runtime.register_source_card(str(summon_plan.get("beast_instance_id", "")), resolved_card)
		if not bool(register_result.get("ok", false)):
			_set_current_daoxi(player, before_daoxi)
			_restore_card_to_hand(player, int(hand_entry.get("index", -1)), resolved_card)
			push_error("[BattleScene] summon source registration failed: %s" % str(register_result.get("reason", "")))
			_show_failure(str(register_result.get("reason", "承道兽来源登记失败。")))
			_refresh_all()
			return
	_log("%s打出了【%s】。" % [player.display_name, card_name])

	var put_into_resolved_pile := true
	var effects: Array = pve_effect_adapter.get_effects(resolved_card)
	var source_id := str(resolved_card.get("instance_id", resolved_card.get("id", card_name)))
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var effect_type := str(effect.get("type", ""))
		var value := int(effect.get("value", 0))
		match effect_type:
			"deal_damage":
				var damage_result := _damage_enemy_with_result(value)
				_log("【%s】对%s造成 %d 点伤害。" % [card_name, str(enemy.get("name", "敌人")), int(damage_result.get("life_damage", 0))])
				_apply_attack_pulse_from_damage(_get_enemy_target_id(), effect, damage_result, source_id)
			"gain_formation":
				gain_formation(value, card_name)
				_log("【%s】获得 %d 点阵势。" % [card_name, value])
			"draw":
				var drawn := _draw_pve_cards(player, value)
				_log("【%s】抽 %d 张牌。" % [card_name, drawn])
			"gain_daoxi":
				var current_daoxi := add_current_daoxi(value, card_name)
				_log("【%s】获得 %d 点道息，当前道息 %d。" % [card_name, value, current_daoxi])
			"gain_reflux":
				_add_return_tide(player, value)
				_log("【%s】回潮值 +%d，当前回潮值 %d。" % [card_name, value, _get_return_tide(player)])
			"reduce_reflux":
				_add_return_tide(player, -value)
				_log("【%s】回潮值 -%d，当前回潮值 %d。" % [card_name, value, _get_return_tide(player)])
			"add_pulse_buildup":
				var pulse_target_id := _resolve_effect_target_id(effect, player)
				_apply_pulse_buildup(pulse_target_id, str(effect.get("pulse_id", "")), value, source_id)
			"reduce_pulse_buildup":
				var reduce_target_id := _resolve_effect_target_id(effect, player)
				_reduce_pulse_buildup(reduce_target_id, str(effect.get("pulse_id", "")), value, source_id)
			"apply_status":
				var status_target_id := _resolve_effect_target_id(effect, player)
				var applied := _apply_combat_status(status_target_id, {
					"status_id": str(effect.get("status_id", "")),
					"display_name": str(effect.get("display_name", effect.get("status_id", ""))),
					"stacks": value,
					"max_stacks": int(effect.get("max_stacks", 0)),
					"tick_timing": str(effect.get("tick_timing", "owner_turn_end")),
					"source_id": source_id,
					"tags": effect.get("tags", [])
				})
				if not applied.is_empty():
					_log("%s获得%s %d 层，当前 %d 层。" % [
						_target_display_name(status_target_id),
						str(applied.get("display_name", applied.get("status_id", "状态"))),
						value,
						int(applied.get("stacks", 0))
					])
			"summon":
				if not _commit_v1_summon_plan(summon_plan):
					_handle_v1_summon_internal_failure(player, before_daoxi, int(hand_entry.get("index", -1)), resolved_card, summon_plan)
					return
				put_into_resolved_pile = false
	if put_into_resolved_pile:
		_put_card_into_pve_resolved_pile(resolved_card)
	Breakthrough.add_dao_progress(player, 5)
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _validate_v1_target_and_capacity(card: Dictionary, target_mode: String, summon_plan: Dictionary = {}) -> String:
	if pve_effect_adapter == null:
		return "v1 效果适配器未初始化。"
	var errors: Array = pve_effect_adapter.get_validation_errors(card)
	if not errors.is_empty():
		return "v1 效果数据不合法：%s" % str(errors)
	var unsupported: Array = pve_effect_adapter.get_unsupported_effect_types(card)
	if not unsupported.is_empty():
		return "暂未支持该 v1 效果：%s" % str(unsupported)
	var has_damage: bool = not pve_effect_adapter.get_effects_by_type(card, "deal_damage").is_empty()
	if has_damage and target_mode != "enemy":
		return "道法牌需要选择敌人目标。"
	var has_self_effect: bool = _v1_has_non_damage_effect(card)
	if target_mode == "enemy" and not has_damage:
		return "该牌不需要选择敌人目标。"
	if target_mode == "self" and not has_self_effect and not _v1_has_summon_effect(card):
		return "该牌需要选择敌人目标。"
	if _v1_has_summon_effect(card):
		if summon_plan.is_empty():
			return "v0.4.4 暂不支持单牌多次召唤。"
		if not bool(summon_plan.get("ok", false)):
			return str(summon_plan.get("reason", "无法召唤承道兽。"))
	return ""


func _v1_card_can_play_on_self(card: Dictionary) -> bool:
	if pve_effect_adapter == null:
		return false
	for effect in pve_effect_adapter.get_effects(card):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var effect_dict: Dictionary = effect
		var effect_type := str(effect_dict.get("type", ""))
		var target := str(effect_dict.get("target", ""))
		if target == "enemy":
			return false
		if target == "" and effect_type in ["deal_damage", "add_pulse_buildup", "apply_status"]:
			return false
	return true


func _v1_has_non_damage_effect(card: Dictionary) -> bool:
	for effect in pve_effect_adapter.get_effects(card):
		if typeof(effect) == TYPE_DICTIONARY and str(effect.get("type", "")) in ["gain_formation", "draw", "gain_daoxi", "gain_reflux", "reduce_reflux"]:
			return true
	return false


func _v1_has_summon_effect(card: Dictionary) -> bool:
	if pve_effect_adapter == null:
		return false
	return not pve_effect_adapter.get_summon_spec(card).is_empty()


func _validate_pve_v1_beast_summon(card: Dictionary, overrides: Dictionary = {}) -> Dictionary:
	if pve_beast_runtime == null:
		return {"ok": false, "reason": "承道兽运行时未初始化。"}
	var summon_spec: Dictionary = pve_effect_adapter.get_summon_spec(card)
	if summon_spec.is_empty():
		return {"ok": false, "reason": "该牌没有召唤数据。"}
	var metadata: Dictionary = pve_beast_runtime.normalize_beast_metadata(card, summon_spec, overrides)
	var board_index := game_state.active_player_index
	return pve_beast_runtime.validate_summon(player_boards[board_index].get_cards_in_slots(CardTypes.CHENGDAO), metadata)


func _build_v1_summon_plan(player: PlayerState, card: Dictionary, target_mode: String, hand_index: int) -> Dictionary:
	if not _v1_has_summon_effect(card):
		return {}
	if pve_beast_runtime == null:
		return {"ok": false, "reason": "承道兽运行时未初始化。"}
	var summon_effects: Array = pve_effect_adapter.get_effects_by_type(card, "summon")
	if summon_effects.size() > 1:
		return {"ok": false, "reason": "v0.4.4 暂不支持单牌多次召唤。"}
	if target_mode != "self":
		return {"ok": false, "reason": "该牌不需要选择敌人目标。"}
	var summon_spec: Dictionary = pve_effect_adapter.get_summon_spec(card)
	if summon_spec.is_empty():
		return {"ok": false, "reason": "该牌没有召唤数据。"}
	var metadata: Dictionary = pve_beast_runtime.normalize_beast_metadata(card, summon_spec)
	var board_index := game_state.active_player_index
	var slot_index := _find_play_slot(board_index, CardTypes.CHENGDAO)
	if slot_index < 0:
		return {"ok": false, "reason": _central_limit_reason(CardTypes.CHENGDAO)}
	var summon_check: Dictionary = pve_beast_runtime.validate_summon(player_boards[board_index].get_cards_in_slots(CardTypes.CHENGDAO), metadata)
	if not bool(summon_check.get("ok", false)):
		return summon_check
	var beast_instance_id: String = pve_beast_runtime.create_beast_instance_id()
	metadata["beast_instance_id"] = beast_instance_id
	if not bool(metadata.get("is_token", false)):
		var source_check: Dictionary = pve_beast_runtime.validate_source_registration(beast_instance_id, card)
		if not bool(source_check.get("ok", false)):
			return source_check
	return {
		"ok": true,
		"reason": "",
		"source_card": card,
		"source_hand_index": hand_index,
		"summon_spec": summon_spec,
		"metadata": metadata,
		"beast_instance_id": beast_instance_id,
		"slot_index": slot_index,
		"board_index": board_index
	}


func _beast_rank_display(rank: String) -> String:
	match rank:
		"advanced":
			return "高阶"
		"token":
			return "衍生"
		"unique":
			return "唯一"
		_:
			return "普通"


func _commit_v1_summon_plan(plan: Dictionary) -> bool:
	if plan.is_empty() or not bool(plan.get("ok", false)):
		return false
	var board_index := int(plan.get("board_index", -1))
	var slot_index := int(plan.get("slot_index", -1))
	var card_to_place: Dictionary = plan.get("metadata", {})
	if board_index < 0 or board_index >= player_boards.size() or slot_index < 0:
		push_error("[BattleScene] invalid summon plan board/slot.")
		return false
	if not player_boards[board_index].is_slot_empty(CardTypes.CHENGDAO, slot_index):
		push_error("[BattleScene] summon plan slot is no longer empty.")
		return false
	player_boards[board_index].place_card(CardTypes.CHENGDAO, slot_index, card_to_place)
	Breakthrough.add_dao_progress(game_state.players[board_index], 20)
	_log("【%s】召唤%s承道兽：占位 %d，攻 %d / 命源 %d。" % [
		str(card_to_place.get("name", "承道兽")),
		_beast_rank_display(str(card_to_place.get("beast_rank", "ordinary"))),
		int(card_to_place.get("board_cost", 1)),
		int(card_to_place.get("attack_value", 0)),
		int(card_to_place.get("max_life", 0))
	])
	return true


func _handle_v1_summon_internal_failure(player: PlayerState, before_daoxi: int, hand_index: int, source_card: Dictionary, plan: Dictionary) -> void:
	push_error("[BattleScene] internal summon failure, rolling back source card.")
	var beast_instance_id := str(plan.get("beast_instance_id", ""))
	if pve_beast_runtime != null and beast_instance_id != "":
		pve_beast_runtime.release_source_card(beast_instance_id)
	_restore_card_to_hand(player, hand_index, source_card)
	_set_current_daoxi(player, before_daoxi)
	_show_failure("召唤承道兽内部失败，已回滚手牌与费用。")
	_clear_selection()
	_refresh_all()


func _play_daofa(player: PlayerState, target: PlayerState, slot_type: String, index: int) -> void:
	var unavailable_reason := _get_unavailable_reason(selected_card, player)
	if unavailable_reason != "":
		_show_failure(unavailable_reason)
		return
	var tier := int(selected_card.get("damage_tier", Damage.Tier.SMALL))
	var amount := Damage.calculate(tier, player.combat_realm)
	var card_name := str(selected_card.get("name", ""))
	_pay_card_cost(player, selected_card)
	Breakthrough.add_dao_progress(player, 5)
	if game_mode == "pve":
		_put_card_into_pve_resolved_pile(selected_card)
	else:
		player.discard_pile.append(selected_card)
	_remove_selected_from_source(player)
	var resonance_log := _resonance_message(selected_card, player, false)
	if resonance_log != "":
		_log(resonance_log)
	if slot_type == CardTypes.CHENGDAO:
		var target_card := player_boards[1 - game_state.active_player_index].get_card(CardTypes.CHENGDAO, index)
		_log("%s发动【%s】，目标：敌方承道兽【%s】。" % [player.display_name, card_name, str(target_card.get("name", ""))])
		var damage_result := player_boards[1 - game_state.active_player_index].damage_card(CardTypes.CHENGDAO, index, amount)
		if bool(damage_result.get("ok", false)):
			_log("【%s】对承道兽造成了 %d 点伤害" % [card_name, amount])
			if bool(damage_result.get("defeated", false)):
				var defeated_card: Dictionary = damage_result.get("card", {})
				target.discard_pile.append(defeated_card)
				_notify_chengdao_beast_died(1 - game_state.active_player_index, defeated_card)
				Breakthrough.add_dao_progress(player, 30)
				_log("【%s】命源归零，进入弃牌区。" % str(defeated_card.get("name", "")))
	else:
		_log("%s发动【%s】，目标：%s道主【%s】。" % [player.display_name, card_name, target.display_name, _dao_master_name(target)])
		var actual := target.take_damage(amount)
		_log("【%s】造成了 %d 点伤害" % [card_name, actual])
	_log("伤害修正参考道主【%s】的道脉与侧性。" % _dao_master_name(target))
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _play_daofa_against_enemy(player: PlayerState) -> void:
	if _is_pve_v1_card(selected_card):
		_play_v1_selected_card(player, "enemy")
		return
	var unavailable_reason := _get_unavailable_reason(selected_card, player)
	if unavailable_reason != "":
		_show_failure(unavailable_reason)
		return
	var tier := int(selected_card.get("damage_tier", Damage.Tier.SMALL))
	var amount := Damage.calculate(tier, player.combat_realm)
	var card_name := str(selected_card.get("name", "道法"))
	_pay_card_cost(player, selected_card)
	Breakthrough.add_dao_progress(player, 5)
	_put_card_into_pve_resolved_pile(selected_card)
	_remove_selected_from_source(player)
	var resonance_log := _resonance_message(selected_card, player, false)
	if resonance_log != "":
		_log(resonance_log)
	_log("%s发动【%s】，目标：%s。" % [player.display_name, card_name, str(enemy.get("name", "敌人"))])
	var actual := _damage_enemy(amount)
	_log("【%s】造成了 %d 点伤害。" % [card_name, actual])
	var formation_gain := _card_formation_gain(selected_card)
	if formation_gain > 0:
		gain_formation(formation_gain, card_name)
		_log("【%s】获得 %d 点阵势。" % [card_name, formation_gain])
	_log("伤害修正参考道主【%s】的道脉与侧性。" % _dao_master_name(player))
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _damage_enemy(amount: int) -> int:
	return int(_damage_enemy_with_result(amount).get("life_damage", 0))


func _damage_enemy_with_result(amount: int) -> Dictionary:
	var block := int(enemy.get("block", 0))
	var blocked := mini(block, maxi(0, amount))
	var remaining := maxi(0, amount - blocked)
	enemy["block"] = maxi(0, block - blocked)
	enemy["life"] = maxi(0, int(enemy.get("life", 0)) - remaining)
	if blocked > 0:
		_log("%s护盾抵挡 %d 点伤害。" % [str(enemy.get("name", "敌人")), blocked])
	return {
		"amount": amount,
		"blocked": blocked,
		"life_damage": remaining,
		"defense_before": block,
		"defense_after": int(enemy.get("block", 0)),
		"defense_broken": block > 0 and int(enemy.get("block", 0)) == 0,
		"target_defeated": int(enemy.get("life", 0)) <= 0
	}


func _damage_player_with_result(player: PlayerState, amount: int) -> Dictionary:
	var defense_before := player.formation_value
	var blocked := mini(defense_before, maxi(0, amount))
	var damage_to_life := maxi(0, amount - blocked)
	player.formation_value = maxi(0, player.formation_value - blocked)
	if damage_to_life > 0:
		player.take_damage(damage_to_life)
	return {
		"amount": amount,
		"blocked": blocked,
		"life_damage": damage_to_life,
		"defense_before": defense_before,
		"defense_after": player.formation_value,
		"defense_broken": defense_before > 0 and player.formation_value == 0,
		"target_defeated": player.life_source <= 0
	}


func _calculate_attack_pulse_amount(base_buildup: int, damage_result: Dictionary, conductive: bool) -> int:
	if base_buildup <= 0:
		return 0
	if conductive:
		return base_buildup
	if int(damage_result.get("life_damage", 0)) > 0:
		return base_buildup
	if bool(damage_result.get("defense_broken", false)):
		return base_buildup
	return int(floor(float(base_buildup) * 0.5))


func _apply_attack_pulse_from_damage(target_id: String, effect: Dictionary, damage_result: Dictionary, source_id: String) -> void:
	if not effect.has("pulse_id") and not effect.has("pulse_value"):
		return
	var pulse_id := str(effect.get("pulse_id", ""))
	var base_buildup := int(effect.get("pulse_value", 0))
	if pulse_id == "" or base_buildup <= 0:
		return
	var conductive := bool(effect.get("conductive", false))
	var amount := _calculate_attack_pulse_amount(base_buildup, damage_result, conductive)
	if amount <= 0:
		_log("%s未形成有效火脉积蓄。" % _target_display_name(target_id))
		return
	_log("%s火脉积蓄 +%d。" % [_target_display_name(target_id), amount])
	_apply_pulse_buildup(target_id, pulse_id, amount, source_id)


func _apply_pulse_buildup(target_id: String, pulse_id: String, amount: int, source_id: String = "") -> Dictionary:
	if pve_pulse_runtime == null:
		return {"ok": false, "reason": "脉冲运行时未初始化。"}
	var result: Dictionary = pve_pulse_runtime.add_buildup(target_id, pulse_id, amount)
	if not bool(result.get("ok", false)):
		_log(str(result.get("reason", "火脉积蓄失败。")))
		return result
	_queue_combat_event("pulse_buildup_changed", {
		"target_id": target_id,
		"pulse_id": pulse_id,
		"amount": amount,
		"before": int(result.get("before", 0)),
		"after": int(result.get("after", 0)),
		"source_id": source_id
	})
	var breaks := int(result.get("breaks", 0))
	for _i in range(breaks):
		_queue_combat_event("pulse_break_triggered", {
			"target_id": target_id,
			"pulse_id": pulse_id,
			"source_id": source_id
		})
		_apply_fire_break_status(target_id, source_id)
	_drain_combat_events()
	return result


func _reduce_pulse_buildup(target_id: String, pulse_id: String, amount: int, source_id: String = "") -> Dictionary:
	if pve_pulse_runtime == null:
		return {"ok": false, "reason": "脉冲运行时未初始化。"}
	var result: Dictionary = pve_pulse_runtime.reduce_buildup(target_id, pulse_id, amount)
	if bool(result.get("ok", false)):
		_queue_combat_event("pulse_buildup_reduced", {
			"target_id": target_id,
			"pulse_id": pulse_id,
			"amount": int(result.get("reduced", 0)),
			"after": int(result.get("after", 0)),
			"source_id": source_id
		})
		_drain_combat_events()
	return result


func _apply_fire_break_status(target_id: String, source_id: String = "") -> void:
	if pve_status_runtime == null:
		return
	var current: Dictionary = pve_status_runtime.get_status(target_id, "zhuomai")
	var stacks := 2 if not current.is_empty() else 3
	var status := _apply_combat_status(target_id, {
		"status_id": "zhuomai",
		"display_name": "灼脉",
		"stacks": stacks,
		"max_stacks": 6,
		"tick_timing": "owner_turn_end",
		"source_id": source_id,
		"tags": ["fire", "burning"]
	})
	_log("火脉失衡：%s获得灼脉 %d，当前灼脉 %d。" % [
		_target_display_name(target_id),
		stacks,
		int(status.get("stacks", 0))
	])


func _apply_combat_status(target_id: String, status_spec: Dictionary) -> Dictionary:
	if pve_status_runtime == null:
		return {}
	var apply_result: Dictionary = pve_status_runtime.apply_status(target_id, status_spec)
	var status: Dictionary = apply_result.get("status", {})
	if not status.is_empty():
		_queue_combat_event("status_applied", {
			"target_id": target_id,
			"status_id": str(status.get("status_id", "")),
			"stacks": int(status.get("stacks", 0)),
			"source_id": str(status_spec.get("source_id", ""))
		})
		_drain_combat_events()
	return status


func _queue_combat_event(event_type: String, payload: Dictionary = {}, parent_event_id: String = "") -> Dictionary:
	if pve_event_queue == null:
		return {}
	return pve_event_queue.enqueue(event_type, payload, parent_event_id)


func _drain_combat_events() -> void:
	if pve_event_queue == null or pve_event_queue.get_pending_count() <= 0:
		return
	pve_event_queue.drain(Callable(self, "_handle_combat_event"))


func _handle_combat_event(_event: Dictionary) -> void:
	pass


func _get_player_target_id() -> String:
	return "player:p1"


func _get_enemy_target_id() -> String:
	return "enemy:primary"


func _get_beast_target_id(beast_data: Dictionary) -> String:
	return "beast:%s" % str(beast_data.get("beast_instance_id", ""))


func _resolve_effect_target_id(effect: Dictionary, _player: PlayerState) -> String:
	var target := str(effect.get("target", "enemy"))
	if target == "self" or target == "player":
		return _get_player_target_id()
	if target == "enemy":
		return _get_enemy_target_id()
	return target


func _find_beast_slot_by_target_id(target_id: String) -> Dictionary:
	if not target_id.begins_with("beast:"):
		return {"ok": false}
	var beast_id := target_id.substr("beast:".length())
	if beast_id == "":
		return {"ok": false}
	for owner_index in range(player_boards.size()):
		for slot_index in range(_slot_count(CardTypes.CHENGDAO)):
			var beast := player_boards[owner_index].get_card(CardTypes.CHENGDAO, slot_index)
			if not beast.is_empty() and str(beast.get("beast_instance_id", "")) == beast_id:
				return {"ok": true, "owner_index": owner_index, "slot_index": slot_index, "beast": beast}
	return {"ok": false}


func _is_target_alive(target_id: String) -> bool:
	if target_id == _get_player_target_id():
		return game_state != null and game_state.players.size() > 0 and game_state.players[0].life_source > 0
	if target_id == _get_enemy_target_id():
		return not enemy.is_empty() and int(enemy.get("life", 0)) > 0
	if target_id.begins_with("beast:"):
		return bool(_find_beast_slot_by_target_id(target_id).get("ok", false))
	return false


func _target_display_name(target_id: String) -> String:
	if target_id == _get_player_target_id():
		return _dao_master_name(game_state.players[0]) if game_state != null and game_state.players.size() > 0 else "玩家"
	if target_id == _get_enemy_target_id():
		return str(enemy.get("name", "敌人"))
	if target_id.begins_with("beast:"):
		var slot := _find_beast_slot_by_target_id(target_id)
		if bool(slot.get("ok", false)):
			var beast: Dictionary = slot.get("beast", {})
			return str(beast.get("name", "承道兽"))
	return target_id


func _format_target_runtime_state(target_id: String) -> String:
	var parts: Array[String] = []
	if pve_pulse_runtime != null:
		var fire: int = pve_pulse_runtime.get_buildup(target_id, "fire")
		if fire > 0:
			parts.append("火脉 %d / %d" % [fire, PvePulseRuntimeScript.FIRE_THRESHOLD])
	if pve_status_runtime != null:
		var zhuomai: Dictionary = pve_status_runtime.get_status(target_id, "zhuomai")
		if not zhuomai.is_empty():
			parts.append("灼脉 %d" % int(zhuomai.get("stacks", 0)))
	if parts.is_empty():
		return "状态：无"
	return "状态：%s" % _array_text_with_separator(parts, "，")


func _process_owner_turn_end_statuses(owner_side: String) -> void:
	if pve_status_runtime == null:
		return
	var targets: Array[String] = []
	if owner_side == "player":
		targets.append(_get_player_target_id())
		for slot_index in range(_slot_count(CardTypes.CHENGDAO)):
			var beast: Dictionary = player_boards[0].get_card(CardTypes.CHENGDAO, slot_index)
			if not beast.is_empty() and str(beast.get("beast_instance_id", "")) != "":
				targets.append(_get_beast_target_id(beast))
	elif owner_side == "enemy":
		targets.append(_get_enemy_target_id())
	for target_id in targets:
		if game_over or not _is_target_alive(target_id):
			continue
		var status: Dictionary = pve_status_runtime.get_status(target_id, "zhuomai")
		if status.is_empty():
			continue
		var stacks := int(status.get("stacks", 0))
		if stacks <= 0:
			continue
		var target_name := _target_display_name(target_id)
		_queue_combat_event("status_tick", {
			"target_id": target_id,
			"status_id": "zhuomai",
			"stacks": stacks,
			"timing": "owner_turn_end"
		})
		var blocked := 0
		var life_damage := stacks
		if target_id == _get_player_target_id():
			var player := game_state.players[0]
			var result := _damage_player_with_result(player, stacks)
			blocked = int(result.get("blocked", 0))
			life_damage = int(result.get("life_damage", 0))
		elif target_id == _get_enemy_target_id():
			var enemy_result := _damage_enemy_with_result(stacks)
			blocked = int(enemy_result.get("blocked", 0))
			life_damage = int(enemy_result.get("life_damage", 0))
		else:
			var slot := _find_beast_slot_by_target_id(target_id)
			if bool(slot.get("ok", false)):
				_damage_pve_beast(int(slot.get("owner_index", 0)), int(slot.get("slot_index", 0)), stacks)
		_log("灼脉结算：%s受到 %d 点灼脉伤害，抵挡 %d，命源伤害 %d。" % [
			target_name,
			stacks,
			blocked,
			life_damage
		])
		_queue_combat_event("status_damage_resolved", {
			"target_id": target_id,
			"status_id": "zhuomai",
			"amount": stacks,
			"blocked": blocked,
			"life_damage": life_damage
		})
		if _is_target_alive(target_id):
			var new_stacks := stacks - 1
			if new_stacks > 0:
				pve_status_runtime.set_stacks(target_id, "zhuomai", new_stacks)
				_log("灼脉衰减：%s当前灼脉 %d。" % [target_name, new_stacks])
			else:
				pve_status_runtime.remove_status(target_id, "zhuomai")
				_queue_combat_event("status_removed", {"target_id": target_id, "status_id": "zhuomai"})
				_log("灼脉消散：%s不再拥有灼脉。" % target_name)
		_check_game_over()
	_drain_combat_events()


func _clear_combat_target_runtime_state(target_id: String) -> void:
	if pve_status_runtime != null:
		pve_status_runtime.clear_target(target_id)
	if pve_pulse_runtime != null:
		pve_pulse_runtime.clear_target(target_id)


func _apply_simple_enter_effect(player: PlayerState, card: Dictionary) -> void:
	var card_type := str(card.get("type", ""))
	if card_type == CardTypes.CHENGDAO:
		Breakthrough.add_dao_progress(player, 20)
		if str(card.get("side", "")) == "chaos" or str(card.get("chengdao_kind", "")) == "chaos_beast":
			_add_return_tide(player, 1)
			_log("混沌侧兽卡登场，回潮值 +1。")
		var dao_tags: Array = card.get("dao_tags", [])
		if dao_tags.has("回潮"):
			_add_return_tide(player, 1)
			_log("该卡含有回潮道脉，额外回潮值 +1。")
		_log("当前回潮值：%d。" % _get_return_tide(player))
	elif card_type == CardTypes.DAO_MARK:
		Breakthrough.add_dao_progress(player, 20)
	elif card_type == CardTypes.DOMAIN:
		_add_return_tide(player, 1)
		_log("当前回潮值增加到 %d" % _get_return_tide(player))
	elif card_type == CardTypes.FORMATION:
		Breakthrough.add_dao_progress(player, 20)


func _card_formation_gain(card: Dictionary) -> int:
	if _is_pve_v1_card(card) and pve_effect_adapter != null:
		return pve_effect_adapter.get_total_value(card, "gain_formation")
	if card.has("formation_gain"):
		return maxi(0, int(card.get("formation_gain", 0)))
	var text := "%s %s" % [str(card.get("text", "")), str(card.get("effect_text", ""))]
	if text.find("获得 1 阵势") >= 0 or text.find("获得 1 点阵势") >= 0:
		return 1
	return 0


func _card_effect_text(card: Dictionary) -> String:
	for field in ["text", "effect_text", "description"]:
		var value := str(card.get(field, ""))
		if value != "":
			return value
	return ""


func _on_basic_attack_pressed() -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段不能攻击。")
		return
	var player := game_state.get_active_player()
	var ready_index := _first_ready_chengdao_index(game_state.active_player_index)
	if ready_index >= 0:
		if game_mode == "pve":
			_basic_attack_with_beast_to_enemy(player, ready_index)
			return
		var target := game_state.get_opponent_of(player)
		_basic_attack_with_beast(player, target, ready_index)
		return
	_show_failure("没有可攻击的承道兽。")


func _on_dao_strike_pressed() -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段不能发动道主道击。")
		return
	var player := game_state.get_active_player()
	var dao_master_name := _dao_master_name(player)
	if bool(dao_strike_used.get(player.id, false)):
		_show_failure("【%s】本回合已经发动过道击。" % dao_master_name)
		return
	var amount := Damage.calculate(Damage.Tier.MICRO, player.combat_realm)
	dao_strike_used[player.id] = true
	if game_mode == "pve":
		var actual := _damage_enemy(amount)
		_log("%s的道主【%s】发动道击，造成 %d 点微额伤害。" % [player.display_name, dao_master_name, actual])
		_log("伤害修正参考道主【%s】的道脉与侧性。" % dao_master_name)
	else:
		var target := game_state.get_opponent_of(player)
		var result := BattleEngine.apply_damage_tier(player, target, Damage.Tier.MICRO)
		_log("%s的道主【%s】发动道击，造成 %d 点微额伤害。" % [player.display_name, dao_master_name, int(result.get("actual", 0))])
		_log("伤害修正参考道主【%s】的道脉与侧性。" % _dao_master_name(target))
	_refresh_all()
	_check_game_over()


func _on_end_turn_pressed() -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段中，请先弃置手牌至 7 张。")
		return
	var player := game_state.get_active_player()
	if game_mode != "pve" and player.hand.size() > HAND_LIMIT:
		_start_discard_phase(player)
		return
	_finish_end_turn(player)


func _finish_end_turn(player: PlayerState) -> void:
	_log("%s归息阶段，清理本回合临时状态。" % player.display_name)
	_clear_selection()
	if game_mode == "pve":
		_end_pve_player_turn(player)
		_check_game_over()
		if game_over:
			_refresh_all()
			return
		_run_enemy_turn(player)
		if not game_over:
			_start_pve_player_turn(player, false)
		_refresh_all()
		return
	game_state.advance_turn()
	var next_player := game_state.get_active_player()
	_refresh_turn_resources(next_player)
	_draw_cards(next_player, 1)
	dao_strike_used[next_player.id] = false
	_log("%s结束回合，轮到%s" % [player.display_name, next_player.display_name])
	_log("%s抽 1 张牌。" % next_player.display_name)
	player_boards[game_state.active_player_index].clear_attack_flags()
	_refresh_all()


func _end_pve_player_turn(player: PlayerState) -> void:
	var kept: Array[Dictionary] = []
	var discarded_count := 0
	for card in player.hand:
		if _card_has_retain(card):
			kept.append(card)
		else:
			discard_pile.append((card as Dictionary).duplicate(true))
			discarded_count += 1
	player.hand = kept
	_log("回合结束，弃置 %d 张手牌，保留 %d 张。" % [discarded_count, kept.size()])
	if passive_runtime != null:
		passive_runtime.on_player_turn_end()
	_process_owner_turn_end_statuses("player")
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = 0
	extra_stats[player.id] = stats


func _run_enemy_turn(player: PlayerState) -> void:
	if enemy.is_empty() or game_over:
		return
	_log("敌人回合：%s执行意图【%s】。" % [str(enemy.get("name", "敌人")), _enemy_intent_text()])
	var intent := str(enemy.get("intent", "attack"))
	var value := int(enemy.get("intent_value", 0))
	if intent == "attack" or intent == "fire_attack":
		var damage_result := _damage_player_with_result(player, value)
		_log("%s攻击 %d，阵势抵挡 %d，玩家受到 %d 点伤害。" % [
			str(enemy.get("name", "敌人")),
			value,
			int(damage_result.get("blocked", 0)),
			int(damage_result.get("life_damage", 0))
		])
		if intent == "fire_attack":
			_apply_attack_pulse_from_damage(
				_get_player_target_id(),
				{
					"pulse_id": str(enemy.get("pulse_id", "fire")),
					"pulse_value": int(enemy.get("pulse_value", 0)),
					"conductive": bool(enemy.get("conductive", false))
				},
				damage_result,
				str(enemy.get("id", "enemy"))
			)
	elif intent == "buff":
		enemy["block"] = int(enemy.get("block", 0)) + value
		_log("%s蓄势，获得 %d 点护盾。" % [str(enemy.get("name", "敌人")), value])
	else:
		_log("%s暂时观望。" % str(enemy.get("name", "敌人")))
	_process_owner_turn_end_statuses("enemy")
	if game_over:
		return
	enemy["turn_index"] = int(enemy.get("turn_index", 0)) + 1
	_set_enemy_intent()
	_check_game_over()


func _start_pve_player_turn(player: PlayerState, is_first_turn: bool = false) -> void:
	game_state.active_player_index = 0
	if not is_first_turn:
		game_state.turn_number += 1
	player.formation_value = 0
	_restore_pve_daoxi(player)
	dao_strike_used[player.id] = false
	player_boards[0].reset_beast_actions()
	# PVE turn start order: restore base resources, then passive start rewards, then fixed draw 5.
	if passive_runtime != null:
		passive_runtime.on_player_turn_start()
	_draw_cards(player, 5)
	_log("玩家回合开始：打出手牌、指挥承道兽或使用道主道击。")


func _restore_pve_daoxi(player: PlayerState) -> void:
	var dao_master: Dictionary = active_dao_masters.get(player.id, {})
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = _get_character_int(dao_master, "base_daoxi", "dao_breath", 3)
	extra_stats[player.id] = stats
	_log("%s起势阶段，阵势清空，道息恢复到 %d。" % [player.display_name, int(stats.get("dao_breath", 0))])


func _start_discard_phase(player: PlayerState) -> void:
	discard_phase = true
	discard_phase_player_id = player.id
	need_discard = maxi(0, player.hand.size() - HAND_LIMIT)
	_clear_selection()
	_log("%s手牌 %d / %d，需要弃置 %d 张。" % [player.display_name, player.hand.size(), HAND_LIMIT, need_discard])
	_refresh_all()


func _confirm_discard_selected_card() -> void:
	var player := game_state.get_active_player()
	if not discard_phase or discard_phase_player_id != player.id:
		_show_failure("当前不能弃牌。")
		return
	if selected_card.is_empty():
		_show_failure("请先选择要弃置的手牌。")
		return
	if selected_card_source != "hand":
		_show_failure("只能弃置当前玩家手牌。")
		return
	var card_name := str(selected_card.get("name", "未知卡牌"))
	var index := _find_card_index(player.hand, selected_card)
	if index < 0:
		_show_failure("只能弃置当前玩家手牌。")
		_clear_selection()
		_refresh_all()
		return
	var discarded: Dictionary = player.hand[index]
	player.hand.remove_at(index)
	player.discard_pile.append(discarded)
	_log("%s弃置【%s】。" % [player.display_name, card_name])
	_clear_selection()
	need_discard = maxi(0, player.hand.size() - HAND_LIMIT)
	if need_discard <= 0:
		discard_phase = false
		discard_phase_player_id = ""
		_log("手牌已降至 %d，结束回合。" % HAND_LIMIT)
		_finish_end_turn(player)
		return
	_refresh_all()


func _find_play_slot(board_index: int, slot_type: String) -> int:
	if slot_type == CardTypes.DOMAIN:
		return 0
	for i in range(_slot_count(slot_type)):
		if player_boards[board_index].is_slot_empty(slot_type, i):
			return i
	return -1


func _central_limit_reason(slot_type: String) -> String:
	if slot_type == CardTypes.CHENGDAO:
		if game_mode == "pve" and pve_beast_runtime != null:
			var used_capacity: int = pve_beast_runtime.get_used_capacity(player_boards[game_state.active_player_index].get_cards_in_slots(CardTypes.CHENGDAO))
			return "无法打出：己方承道兽占位已达上限 %d / %d。" % [used_capacity, PveBeastRuntimeScript.MAX_BOARD_CAPACITY]
		return "无法打出：己方承道兽数量已达上限 3。"
	if slot_type == CardTypes.FORMATION:
		return "无法打出：己方法阵已存在。"
	if slot_type == CardTypes.TRAP:
		return "无法打出：己方伏法数量已达上限 2。"
	if slot_type == CardTypes.LIFE_ARTIFACT:
		return "无法打出：己方命器位已有命器。"
	if slot_type == CardTypes.DAO_MARK:
		return "无法打出：己方道痕数量已达上限 3。"
	return "无法打出：目标区域已满。"


func _find_card_index(cards: Array, card: Dictionary) -> int:
	for i in range(cards.size()):
		if is_same(cards[i], card):
			return i
	for i in range(cards.size()):
		if cards[i] == card:
			return i
	return -1


func _can_slot_accept_card(slot_type: String, card_type: String) -> bool:
	if card_type == CardTypes.DAOFA:
		return slot_type == "target"
	return slot_type == _expected_slot_for_card(card_type)


func _discard_selected_if_needed(player: PlayerState, result: Dictionary) -> void:
	if bool(result.get("discarded", false)):
		_remove_selected_from_source(player)


func _get_selected_hand_entry(player: PlayerState) -> Dictionary:
	if selected_card_source != "hand":
		return {"ok": false, "index": -1, "card": {}, "reason": "该牌已不在手牌中。"}
	for i in range(player.hand.size()):
		if is_same(player.hand[i], selected_card):
			return {"ok": true, "index": i, "card": player.hand[i], "reason": ""}
	return {"ok": false, "index": -1, "card": {}, "reason": "该牌已不在手牌中。"}


func _remove_hand_card_at(player: PlayerState, index: int, expected_card: Dictionary) -> Dictionary:
	if index < 0 or index >= player.hand.size():
		return {}
	if not is_same(player.hand[index], expected_card):
		return {}
	var removed: Dictionary = player.hand[index]
	player.hand.remove_at(index)
	return removed


func _restore_card_to_hand(player: PlayerState, index: int, card: Dictionary) -> void:
	if card.is_empty():
		return
	var safe_index := clampi(index, 0, player.hand.size())
	player.hand.insert(safe_index, card)


func _set_current_daoxi(player: PlayerState, value: int) -> void:
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = maxi(0, value)
	extra_stats[player.id] = stats


func _get_current_daoxi(player: PlayerState) -> int:
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	return int(stats.get("dao_breath", 0))


func _remove_selected_from_source(player: PlayerState) -> Dictionary:
	var source := _cards_for_source(player, selected_card_source)
	for i in range(source.size()):
		if source[i] == selected_card:
			var removed: Dictionary = source[i]
			source.remove_at(i)
			return removed
	return {}


func _cards_for_source(player: PlayerState, source: String) -> Array:
	return player.hand


func _source_display_name(source: String) -> String:
	if source == "battlefield":
		return "战场"
	return "手牌"


func _clear_selection() -> void:
	selected_card = {}
	selected_card_view = null
	selected_card_source = ""
	selected_attacker = {"player_index": -1, "slot_index": -1}
	if hand_view != null:
		hand_view.clear_selection()
	_clear_board_highlights()
	_update_operation_hint()
	_update_selected_detail()


func _refresh_all() -> void:
	if game_state == null:
		return
	var active_player := game_state.get_active_player()
	var opponent := game_state.get_opponent_of(active_player)
	active_label.text = _format_pve_status(active_player) if game_mode == "pve" else _format_match_status(active_player)
	if game_mode == "pve":
		_refresh_player_portrait_panel(active_player)
		_refresh_enemy_area()
	else:
		_refresh_portrait_panels(active_player, opponent)
		_refresh_opponent_hand_overview(opponent)
	_refresh_resource_summary(active_player)
	_refresh_hand_category_buttons(active_player)
	_apply_active_player_styles()
	if deck_pile_label != null:
		if game_mode == "pve":
			deck_pile_label.text = "牌堆计数\n抽牌堆：%d\n弃牌堆：%d\n消耗堆：%d\n手牌：%d / %d\n未抽取不可查看" % [
				draw_pile.size(),
				discard_pile.size(),
				exhaust_pile.size(),
				active_player.hand.size(),
				HAND_LIMIT
			]
		else:
			deck_pile_label.text = "主卡组牌堆\n▣\n%d / %d\n未抽取不可查看" % [active_player.deck.size(), MAIN_DECK_SIZE]
	if card_load_error != "":
		hand_view.show_message(card_load_error)
	else:
		var shown_cards := _filtered_active_hand(active_player)
		hand_view.set_cards(shown_cards, _get_unavailable_reasons(shown_cards, active_player), "当前分类暂无卡牌")
	_refresh_central_battlefield()
	breakthrough_button.disabled = game_over or not Breakthrough.can_breakthrough(active_player)
	var manual_discard_active := discard_phase and game_mode != "pve"
	end_turn_button.disabled = game_over or manual_discard_active
	attack_button.disabled = game_over or manual_discard_active
	breakthrough_button.disabled = game_over or manual_discard_active or not Breakthrough.can_breakthrough(active_player)
	dao_strike_button.disabled = game_over or manual_discard_active or bool(dao_strike_used.get(active_player.id, false))
	dao_strike_button.text = "本回合已道击" if bool(dao_strike_used.get(active_player.id, false)) else "道主道击"
	if next_round_button != null:
		if game_mode == "pve":
			next_round_button.disabled = true
			next_round_button.visible = false
		else:
			next_round_button.disabled = (not game_over) or match_over or current_match_round >= 3
			next_round_button.visible = game_over and not match_over and current_match_round < 3
	restart_button.disabled = false
	restart_button.text = "重新开始战斗" if game_mode == "pve" else "重新开始 Match"
	_update_operation_hint()
	_update_selected_detail()
	if selected_card.is_empty():
		_clear_board_highlights()


func _refresh_player_portrait_panel(active_player: PlayerState) -> void:
	if player_portrait_label != null:
		player_portrait_label.text = _format_dao_master_info(active_player)
		player_portrait_label.tooltip_text = _format_dao_master_detail(active_player)
	if player_portrait_art_label != null:
		player_portrait_art_label.text = "◆\n%s\n道主立绘" % _dao_master_name(active_player)


func _refresh_portrait_panels(active_player: PlayerState, opponent: PlayerState) -> void:
	if player_portrait_label != null:
		player_portrait_label.text = _format_dao_master_info(active_player)
		player_portrait_label.tooltip_text = _format_dao_master_detail(active_player)
	if player_portrait_art_label != null:
		player_portrait_art_label.text = "◆\n%s\n道主立绘" % _dao_master_name(active_player)
	if opponent_portrait_label != null:
		opponent_portrait_label.text = _format_dao_master_info(opponent)
		opponent_portrait_label.tooltip_text = _format_dao_master_detail(opponent)
	if opponent_portrait_art_label != null:
		opponent_portrait_art_label.text = "◆\n%s\n道主立绘" % _dao_master_name(opponent)


func _format_pve_status(active_player: PlayerState) -> String:
	var phase_text := "战斗结束" if game_over else "玩家回合"
	return "PVE 战斗｜当前：%s｜道主：%s｜敌人：%s｜敌人意图：%s" % [
		phase_text,
		_dao_master_name(active_player),
		str(enemy.get("name", "敌人")),
		_enemy_intent_text()
	]


func _format_match_status(active_player: PlayerState) -> String:
	return "第 %d 局｜比分 玩家一 %d - %d 玩家二｜当前：%s｜道主 玩家一：%s / 玩家二：%s｜已出战 玩家一：%s；玩家二：%s" % [
		current_match_round,
		player1_match_wins,
		player2_match_wins,
		active_player.display_name,
		_dao_master_name(game_state.players[0]),
		_dao_master_name(game_state.players[1]),
		_array_text(player1_used_characters),
		_array_text(player2_used_characters)
	]


func _refresh_enemy_area() -> void:
	if enemy_info_label == null or enemy.is_empty():
		return
	var state_text := "已结束" if game_over else "进行中"
	enemy_info_label.text = "敌人名：%s\n生命：%d / %d\n意图：%s\n护盾：%d\n%s\n状态：%s" % [
		str(enemy.get("name", "敌人")),
		int(enemy.get("life", 0)),
		int(enemy.get("max_life", 0)),
		_enemy_intent_text(),
		int(enemy.get("block", 0)),
		_format_target_runtime_state(_get_enemy_target_id()),
		state_text
	]
	if enemy_target_button != null:
		enemy_target_button.text = "敌人目标\n%s\n%d / %d\n%s" % [
			str(enemy.get("name", "敌人")),
			int(enemy.get("life", 0)),
			int(enemy.get("max_life", 0)),
			_enemy_intent_text()
		]


func _enemy_intent_text() -> String:
	var intent := str(enemy.get("intent", "attack"))
	var value := int(enemy.get("intent_value", 0))
	if intent == "attack":
		return "攻击 %d" % value
	if intent == "fire_attack":
		return "灼脉攻击 %d｜火脉积蓄 %d｜非传导" % [value, int(enemy.get("pulse_value", 0))]
	if intent == "buff":
		return "蓄势 +%d 护盾" % value
	if intent == "wait":
		return "观望"
	return intent


func _refresh_resource_summary(player: PlayerState) -> void:
	if resource_summary_label == null:
		return
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	var board_capacity := 0
	if game_mode == "pve" and pve_beast_runtime != null:
		board_capacity = pve_beast_runtime.get_used_capacity(player_boards[0].get_cards_in_slots(CardTypes.CHENGDAO))
	resource_summary_label.text = "资源摘要\n道息：%d\n阵势值：%d\n回潮值：%d\n道行值：%d\n%s\n承道占位：%d / 3\n当前回合：%d" % [
		int(stats.get("dao_breath", 0)),
		player.formation_value,
		int(stats.get("return_tide", 0)),
		player.dao_progress,
		_format_target_runtime_state(_get_player_target_id()),
		board_capacity,
		game_state.turn_number
	]


func _refresh_hand_category_buttons(player: PlayerState) -> void:
	for category in hand_category_buttons.keys():
		var count := _count_cards_in_category(player.hand, str(category))
		var button := hand_category_buttons[category] as Button
		if button == null:
			continue
		var is_current := str(category) == current_hand_category
		button.text = "%s\n%d" % [str(category), count]
		var style := gold_button_style if is_current else dim_button_style
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.modulate = Color.WHITE if count > 0 or is_current else Color(0.48, 0.48, 0.54, 1.0)
	for filter in chengdao_filter_buttons.keys():
		var button := chengdao_filter_buttons[filter] as Button
		if button != null:
			button.visible = current_hand_category == "承道"
			var is_filter_current := str(filter) == current_chengdao_filter
			button.add_theme_stylebox_override("normal", gold_button_style if is_filter_current else dim_button_style)
			button.add_theme_stylebox_override("hover", gold_button_style if is_filter_current else dim_button_style)
			button.modulate = Color.WHITE
	if hand_category_label != null:
		hand_category_label.text = "当前分类：%s    手牌 %d / %d" % [current_hand_category, player.hand.size(), HAND_LIMIT]
		hand_category_label.modulate = Color(1.0, 0.44, 0.38, 1.0) if player.hand.size() > HAND_LIMIT else Color.WHITE


func _refresh_opponent_hand_overview(opponent: PlayerState) -> void:
	if opponent_hand_overview == null or opponent_hand_overview_right == null:
		return
	for child in opponent_hand_overview.get_children():
		child.queue_free()
	for child in opponent_hand_overview_right.get_children():
		child.queue_free()
	_add_opponent_category_overview(opponent_hand_overview, opponent, ["命器", "道痕", "承道"])
	_add_opponent_category_overview(opponent_hand_overview_right, opponent, ["道法", "伏法", "域界"])


func _add_opponent_category_overview(container: BoxContainer, opponent: PlayerState, categories: Array) -> void:
	for category in categories:
		var count := _count_cards_in_category(opponent.hand, category)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(82, 42)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", dim_button_style)
		container.add_child(panel)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		panel.add_child(row)
		var label := Label.new()
		label.text = "%s %d" % [category, count]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var back := Label.new()
		back.text = _card_back_marks(count)
		back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(back)


func _card_back_marks(count: int) -> String:
	if count <= 0:
		return "◇"
	if count > 3:
		return "▣ ×%d" % count
	var text := ""
	for i in range(count):
		if text != "":
			text += " "
		text += "▣"
	return text


func _filtered_active_hand(player: PlayerState) -> Array:
	var result: Array = []
	for card in player.hand:
		if _card_category(card) != current_hand_category:
			continue
		if current_hand_category == "承道" and not _chengdao_filter_accepts(card):
			continue
		result.append(card)
	return result


func _count_cards_in_category(cards: Array, category: String) -> int:
	var count := 0
	for card in cards:
		if _card_category(card) == category:
			count += 1
	return count


func _card_category(card: Dictionary) -> String:
	var card_type := str(card.get("type", ""))
	if card_type in [CardTypes.LIFE_ARTIFACT, "weapon", "artifact", "mingqi"]:
		return "命器"
	if card_type in [CardTypes.DAO_MARK, "trace", "daohen"]:
		return "道痕"
	if card_type == CardTypes.CHENGDAO:
		return "承道"
	if card_type == CardTypes.DAOFA:
		return "道法"
	if card_type in [CardTypes.TRAP, "ambush", "fufa"]:
		return "伏法"
	if card_type in [CardTypes.DOMAIN, "yujie"]:
		return "域界"
	if card_type == CardTypes.FORMATION:
		return "道法"
	return "道法"


func _chengdao_filter_accepts(card: Dictionary) -> bool:
	if current_chengdao_filter == "全部":
		return true
	var kind := str(card.get("chengdao_kind", ""))
	if current_chengdao_filter == "秩序侧":
		return kind == "order_beast"
	if current_chengdao_filter == "混沌侧":
		return kind == "chaos_beast"
	return true


func _on_hand_category_pressed(category: String) -> void:
	_clear_selection()
	current_hand_category = category
	if current_hand_category != "承道":
		current_chengdao_filter = "全部"
	_refresh_all()


func _on_chengdao_filter_pressed(filter: String) -> void:
	_clear_selection()
	current_chengdao_filter = filter
	_refresh_all()


func _on_visible_dao_master_target_pressed(is_opponent_target: bool) -> void:
	if game_mode == "pve" and is_opponent_target:
		_on_enemy_target_pressed()
		return
	var active_index := game_state.active_player_index
	var target_index := 1 - active_index if is_opponent_target else active_index
	_on_dao_master_target_pressed(target_index)


func _on_enemy_target_pressed() -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段只能选择手牌并点击中央战场区弃置。")
		return
	var player := game_state.get_active_player()
	if not selected_card.is_empty():
		if _is_pve_v1_card(selected_card):
			_play_v1_selected_card(player, "enemy")
			return
		if str(selected_card.get("type", "")) == CardTypes.DAOFA:
			_play_daofa_against_enemy(player)
			return
		_show_failure("只有道法牌可以选择敌人目标。")
		return
	if _has_selected_attacker():
		_basic_attack_with_beast_to_enemy(player, int(selected_attacker.get("slot_index", -1)))
		return
	_show_failure("请先选择道法牌或己方承道兽。")


func _refresh_battlefield_summary(board_index: int) -> void:
	if board_index < 0 or board_index >= battlefield_summary_containers.size():
		return
	var container := battlefield_summary_containers[board_index]
	for child in container.get_children():
		child.queue_free()
	_add_summary_slot_row(container, board_index, CardTypes.CHENGDAO, "承道位", 3)
	_add_summary_slot_row(container, board_index, CardTypes.TRAP, "伏法位", 2)
	_add_summary_slot_row(container, board_index, CardTypes.FORMATION, "法阵位", 1)
	_add_summary_slot_row(container, board_index, CardTypes.DOMAIN, "域界位", 1)
	_add_summary_slot_row(container, board_index, CardTypes.LIFE_ARTIFACT, "命器位", 1)
	_add_summary_slot_row(container, board_index, CardTypes.DAO_MARK, "道痕区", 3)


func _add_summary_slot_row(container: VBoxContainer, board_index: int, slot_type: String, label_text: String, count: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	container.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(54, 28)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	for i in range(count):
		var slot := Button.new()
		slot.focus_mode = Control.FOCUS_NONE
		slot.custom_minimum_size = Vector2(56, 32)
		var card := player_boards[board_index].get_card(slot_type, i)
		slot.text = "空" if card.is_empty() else _summary_card_name(card)
		slot.tooltip_text = "" if card.is_empty() else _format_battlefield_card(board_index, slot_type, card)
		row.add_child(slot)


func _summary_card_name(card: Dictionary) -> String:
	var card_name := str(card.get("name", "已放置"))
	if card_name.length() > 4:
		return card_name.substr(0, 4)
	return card_name


func _count_placed_cards(board_index: int, slot_type: String) -> int:
	if board_index < 0 or board_index >= player_boards.size():
		return 0
	var count := 0
	for i in range(_slot_count(slot_type)):
		if not player_boards[board_index].is_slot_empty(slot_type, i):
			count += 1
	return count


func _refresh_central_battlefield() -> void:
	if central_battlefield_grid == null or game_state == null:
		return
	for child in central_battlefield_grid.get_children():
		child.queue_free()
	var has_cards := false
	for owner_index in range(player_boards.size()):
		for slot_type in [CardTypes.CHENGDAO, CardTypes.TRAP, CardTypes.FORMATION, CardTypes.DOMAIN, CardTypes.LIFE_ARTIFACT, CardTypes.DAO_MARK]:
			for slot_index in range(_slot_count(slot_type)):
				var card := player_boards[owner_index].get_card(slot_type, slot_index)
				if card.is_empty():
					continue
				has_cards = true
				var button := Button.new()
				button.name = "BattlefieldCardView"
				button.custom_minimum_size = Vector2(170, 138)
				button.text = _format_battlefield_card(owner_index, slot_type, card)
				button.tooltip_text = str(card.get("text", ""))
				button.clip_text = true
				button.add_theme_font_size_override("font_size", 13)
				button.pressed.connect(_on_battlefield_card_pressed.bind(owner_index, slot_type, slot_index))
				var owner_style := player_card_style if owner_index == 0 else opponent_card_style
				button.add_theme_stylebox_override("normal", owner_style)
				button.add_theme_stylebox_override("hover", owner_style)
				button.add_theme_stylebox_override("pressed", owner_style)
				central_battlefield_grid.add_child(button)
				if _should_highlight_battlefield_card(owner_index, slot_type):
					button.modulate = Color(1.0, 0.92, 0.62, 1.0)
				elif owner_index != game_state.active_player_index:
					button.modulate = Color(0.86, 0.84, 0.86, 1.0)
	if central_battlefield_button != null:
		if discard_phase and game_mode != "pve":
			central_battlefield_button.text = "弃牌阶段\n选择手牌后点击此处弃置。"
		elif has_cards:
			central_battlefield_button.text = "中央战场区\n选择持续牌后点击这里打出。"
		else:
			central_battlefield_button.text = "中央战场区\n选择手牌后点击这里打出。"
		if not selected_card.is_empty() and str(selected_card.get("type", "")) != CardTypes.DAOFA:
			central_battlefield_button.modulate = Color(1.0, 0.92, 0.62, 1.0)
		else:
			central_battlefield_button.modulate = Color.WHITE
	for i in range(dao_master_target_buttons.size()):
		var button := dao_master_target_buttons[i]
		if button == null:
			continue
		var should_highlight := i != game_state.active_player_index and ((not selected_card.is_empty() and str(selected_card.get("type", "")) == CardTypes.DAOFA) or _has_selected_attacker())
		button.modulate = Color(1.0, 0.92, 0.62, 1.0) if should_highlight else Color.WHITE
	if opponent_target_button != null:
		var highlight_opponent := (not selected_card.is_empty() and str(selected_card.get("type", "")) == CardTypes.DAOFA) or _has_selected_attacker()
		opponent_target_button.modulate = Color(1.0, 0.92, 0.62, 1.0) if highlight_opponent else Color.WHITE
	if player_target_button != null:
		player_target_button.modulate = Color.WHITE


func _format_battlefield_card(owner_index: int, slot_type: String, card: Dictionary) -> String:
	var owner_name := game_state.players[owner_index].display_name
	var card_name := str(card.get("name", "未知卡牌"))
	if card_name.length() > 8:
		card_name = card_name.substr(0, 8) + "..."
	var lines: Array[String] = [
		owner_name,
		card_name,
		CardTypes.get_display_name(str(card.get("type", slot_type)))
	]
	var kind := _display_chengdao_kind(str(card.get("chengdao_kind", "")))
	var side := _display_side(str(card.get("side", "")))
	var identity_line := ""
	if kind != "":
		identity_line = kind
	if side != "":
		identity_line = side if identity_line == "" else "%s / %s" % [identity_line, side]
	if identity_line != "":
		lines.append(identity_line)
	var dao_tags := _dao_tags_text(card)
	if dao_tags != "无":
		if dao_tags.length() > 8:
			dao_tags = dao_tags.substr(0, 8) + "..."
		lines.append(dao_tags)
	if slot_type == CardTypes.CHENGDAO:
		lines.append("%s / 占位 %d" % [
			_beast_rank_display(str(card.get("beast_rank", "ordinary"))),
			int(card.get("board_cost", 1))
		])
		lines.append("攻 %d / 命 %d" % [
			int(card.get("attack_value", card.get("attack", card.get("power", card.get("offense", 0))))),
			int(card.get("current_life", 0))
		])
		lines.append("行动 %d/%d" % [
			int(card.get("action_points_remaining", 1)),
			int(card.get("action_points", 1))
		])
		if bool(card.get("has_attacked", false)):
			lines.append("已行动")
		var runtime_state := _format_target_runtime_state(_get_beast_target_id(card))
		if runtime_state != "状态：无":
			lines.append(runtime_state.replace("状态：", ""))
	return _array_text_with_separator(lines, "\n")


func _should_highlight_battlefield_card(owner_index: int, slot_type: String) -> bool:
	var active_index := game_state.active_player_index
	if owner_index == active_index:
		return false
	if slot_type != CardTypes.CHENGDAO:
		return false
	if not selected_card.is_empty() and str(selected_card.get("type", "")) == CardTypes.DAOFA:
		return true
	return _has_selected_attacker()


func _log(message: String) -> void:
	if log_view != null:
		log_view.append_text(message + "\n")
	print(message)


func _on_help_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "操作说明"
	var label := Label.new()
	label.custom_minimum_size = Vector2(420, 220)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "1. 道主牌不是手牌。\n2. 道主牌不进入承道位。\n3. 点击底部分类手牌选择卡牌。\n4. 持续牌点击中央战场区打出。\n5. 道法牌点击顶部敌人目标。\n6. 点击中央战场区己方承道兽选择攻击者，再点击敌人目标。\n7. 玩家回合开始固定抽 5 张，手牌上限 10。\n8. 结束回合会自动弃置非凝梦 / 保留手牌。"
	dialog.add_child(label)
	add_child(dialog)
	dialog.popup_centered(Vector2(460, 300))


func _on_tutorial_pressed() -> void:
	var message := tutorial_steps[tutorial_step]
	tutorial_step = (tutorial_step + 1) % tutorial_steps.size()
	operation_hint_label.text = message
	_log("新手演示：%s" % message)


func _on_breakthrough_pressed() -> void:
	if game_over:
		_show_failure(_game_over_action_message())
		return
	if discard_phase and game_mode != "pve":
		_show_failure("弃牌阶段不能突破。")
		return
	var player := game_state.get_active_player()
	if not Breakthrough.can_breakthrough(player):
		_show_failure("道行值不足，暂不能突破。")
		return
	var old_realm := player.combat_realm
	var old_max := player.max_life_source
	var cost := Breakthrough.get_cost_to_next(player.combat_realm)
	player.dao_progress -= cost
	player.combat_realm = Realm.clamp_rank(player.combat_realm + 1)
	player.max_life_source = Realm.get_life_source(player.combat_realm)
	var recovered := int(ceil(float(player.max_life_source - old_max) * 0.5))
	player.life_source = clampi(player.life_source + recovered, 0, player.max_life_source)
	_log("%s 临战突破：%s -> %s，扣除道行 %d，恢复命源 %d。" % [
		player.display_name,
		Realm.get_realm_name(old_realm),
		Realm.get_realm_name(player.combat_realm),
		cost,
		recovered
	])
	_refresh_all()


func _on_restart_pressed() -> void:
	if game_mode == "pve":
		_start_pve_battle()
	else:
		_start_match()
	_refresh_all()


func _on_next_round_pressed() -> void:
	if game_mode == "pve":
		_show_failure("PVE 模式没有下一局，请重新开始战斗。")
		return
	if not game_over or match_over:
		_show_failure("当前不能进入下一局。")
		return
	current_match_round += 1
	if current_match_round > 3:
		_show_failure("Match 已无下一局。")
		return
	if log_view != null:
		log_view.clear()
	_start_local_battle()
	_refresh_all()


func _get_unavailable_reasons(cards: Array, player: PlayerState) -> Dictionary:
	var reasons := {}
	for card in cards:
		var reason := _get_unavailable_reason(card, player)
		if reason != "":
			reasons[str(card.get("id", card.get("name", "")))] = reason
	return reasons


func _get_unavailable_reason(card: Dictionary, player: PlayerState) -> String:
	if _is_pve_v1_card(card):
		if pve_effect_adapter == null:
			return "v1 效果适配器未初始化。"
		var errors: Array = pve_effect_adapter.get_validation_errors(card)
		if not errors.is_empty():
			return "v1 效果数据不合法：%s" % str(errors)
		var unsupported: Array = pve_effect_adapter.get_unsupported_effect_types(card)
		if not unsupported.is_empty():
			return "暂未支持该 v1 效果：%s" % str(unsupported)
	var realm_requirement := _card_realm_requirement(card)
	if player.combat_realm < realm_requirement:
		return "境界不足：需要 %s，当前 %s。" % [
			Realm.get_realm_name(realm_requirement),
			Realm.get_realm_name(player.combat_realm)
		]
	var cost := int(card.get("cost", 0))
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	var dao_breath := int(stats.get("dao_breath", 0))
	if cost > dao_breath:
		return "费用不足：需要 %d，当前 %d。" % [cost, dao_breath]
	if str(card.get("type", "")) == CardTypes.DAOFA:
		var dao_lock_reason := _get_explicit_dao_lock_reason(card, player)
		if dao_lock_reason != "":
			return dao_lock_reason
	if str(card.get("type", "")) == CardTypes.FORMATION:
		var formation_cost := int(card.get("formation_cost", 0))
		if player.formation_value < formation_cost:
			return "阵势值不足：需要 %d，当前 %d。" % [formation_cost, player.formation_value]
		var life_requirement := int(card.get("life_requirement", 0))
		if player.life_source < life_requirement:
			return "命源不足：需要 %d，当前 %d。" % [life_requirement, player.life_source]
	return ""


func _get_explicit_dao_lock_reason(card: Dictionary, player: PlayerState) -> String:
	var required_tags: Array = card.get("required_dao_tags", [])
	for tag in required_tags:
		if not player.has_dao_path(str(tag)):
			return "无法发动：该道法需要 %s 道脉。" % _array_text_with_separator(required_tags, " / ")
	var exclusive_tags: Array = card.get("exclusive_dao_tags", [])
	if not exclusive_tags.is_empty():
		for tag in exclusive_tags:
			if player.has_dao_path(str(tag)):
				return ""
		return "无法发动：该道法需要 %s 道脉。" % _array_text_with_separator(exclusive_tags, " / ")
	return ""


func _update_operation_hint() -> void:
	if operation_hint_label == null:
		return
	if game_over:
		return
	if discard_phase and game_mode != "pve":
		if selected_card.is_empty():
			operation_hint_label.text = "弃牌阶段：手牌超过上限，请选择 %d 张手牌并点击中央战场区弃置。" % need_discard
		else:
			operation_hint_label.text = "已选择要弃置的牌【%s】，请点击中央战场区确认弃置。" % str(selected_card.get("name", "未知卡牌"))
		return
	if _has_selected_attacker():
		var beast := player_boards[game_state.active_player_index].get_card(CardTypes.CHENGDAO, int(selected_attacker.get("slot_index", -1)))
		operation_hint_label.text = "已选择承道兽【%s】，请选择敌人目标。" % str(beast.get("name", "承道兽")) if game_mode == "pve" else "已选择承道兽【%s】，请选择敌方道主或敌方承道兽。" % str(beast.get("name", "承道兽"))
		return
	if selected_card.is_empty():
		operation_hint_label.text = "请选择手牌出牌，或选择己方承道兽攻击。"
		return
	var card_type := str(selected_card.get("type", ""))
	if card_type == CardTypes.CHENGDAO:
		operation_hint_label.text = "请选择己方承道位。"
	elif card_type == CardTypes.DAOFA:
		operation_hint_label.text = "请选择敌人目标。" if game_mode == "pve" else "请选择敌方道主或敌方承道兽。"
	elif card_type == CardTypes.FORMATION:
		operation_hint_label.text = "请选择己方法阵位。"
	elif card_type == CardTypes.DAO_MARK:
		operation_hint_label.text = "请选择己方道痕区。"
	elif card_type == CardTypes.DOMAIN:
		operation_hint_label.text = "请选择己方域界位。"
	elif card_type == CardTypes.LIFE_ARTIFACT:
		operation_hint_label.text = "请选择己方命器位。"
	elif card_type == CardTypes.TRAP:
		operation_hint_label.text = "请选择己方伏法位。"
	else:
		operation_hint_label.text = "请选择合法区域。"


func _update_selected_detail() -> void:
	if selected_detail_label == null:
		return
	if _has_selected_attacker():
		var beast := player_boards[game_state.active_player_index].get_card(CardTypes.CHENGDAO, int(selected_attacker.get("slot_index", -1)))
		selected_detail_label.text = "卡名：%s\n来源：战场\n类型：%s\n承道分类：%s\n费用：0\n道脉：%s\n攻伐：%d\n命源：%d / %d\n效果：%s" % [
			str(beast.get("name", "承道兽")),
			CardTypes.get_display_name(str(beast.get("type", CardTypes.CHENGDAO))),
			_display_chengdao_kind(str(beast.get("chengdao_kind", ""))),
			_dao_tags_text(beast),
			int(beast.get("attack_value", beast.get("attack", beast.get("power", beast.get("offense", 0))))),
			int(beast.get("current_life", 0)),
			int(beast.get("max_life", beast.get("life", 0))),
			str(beast.get("text", ""))
		]
		return
	if selected_card.is_empty():
		selected_detail_label.text = "尚未选择手牌。"
		return
	var dao_text := _dao_tags_text(selected_card)
	var kind_text := _display_chengdao_kind(str(selected_card.get("chengdao_kind", "")))
	if kind_text == "":
		kind_text = "无"
	var unavailable_reason := _get_unavailable_reason(selected_card, game_state.get_active_player())
	var unavailable_line := ""
	if unavailable_reason != "":
		unavailable_line = "\n当前不可用：%s" % unavailable_reason
	selected_detail_label.text = "卡名：%s\n来源：%s\n类型：%s\n承道分类：%s\n费用：%d\n道脉：%s\n可放置区域：%s\n效果：%s%s" % [
		str(selected_card.get("name", "")),
		_source_display_name(selected_card_source),
		CardTypes.get_display_name(str(selected_card.get("type", ""))),
		kind_text,
		int(selected_card.get("cost", 0)),
		dao_text,
		_slot_display_name(_expected_slot_for_card(str(selected_card.get("type", "")))),
		_card_effect_text(selected_card),
		unavailable_line
	]


func _highlight_legal_targets() -> void:
	_clear_board_highlights()
	if selected_card.is_empty() or game_state == null:
		return
	var active_index := game_state.active_player_index
	var card_type := str(selected_card.get("type", ""))
	if card_type == CardTypes.DAOFA:
		var enemy_index := 1 - active_index
		player_boards[enemy_index].highlight_target_keep(true)
		player_boards[enemy_index].highlight_occupied_slots(CardTypes.CHENGDAO, false)
		return
	var expected_slot := _expected_slot_for_card(card_type)
	if expected_slot != "":
		player_boards[active_index].highlight_slots(expected_slot, true)


func _play_non_daofa_card(player: PlayerState, card: Dictionary) -> Dictionary:
	var card_type := str(card.get("type", ""))
	if card_type == "character":
		return {"ok": false, "reason": "人物牌只能作为道主，不能进入承道位。", "card": card}
	if card_type == CardTypes.CHENGDAO and not _is_chengdao_beast(card):
		return {"ok": false, "reason": "承道位只允许秩序兽或混沌兽。", "card": card}
	if card_type == CardTypes.FORMATION:
		return Formation.play(player, card)
	if card_type == CardTypes.LIFE_ARTIFACT:
		if not _is_artifact_eligible(player, card):
			return {"ok": false, "reason": "命器不适格，触发命契反噬。", "card": card}
		return {"ok": true, "reason": "命器装备成功", "card": card}
	return {"ok": true, "reason": "卡牌使用成功", "card": card}


func _friendly_failure_reason(result: Dictionary) -> String:
	var reason := str(result.get("reason", ""))
	if reason == "命契反噬":
		return "命器不适格，触发命契反噬。"
	if reason == "境界不足":
		return "境界不足。"
	if reason == "阵势值不足":
		return "阵势值不足。"
	if reason == "命源不足":
		return "命源不足。"
	if reason == "":
		return "目标区域错误。"
	return reason


func _pay_card_cost(player: PlayerState, card: Dictionary) -> void:
	var card_type := str(card.get("type", ""))
	if card_type == CardTypes.FORMATION:
		_log("阵势值支付：%d。" % int(card.get("formation_cost", 0)))
		return
	var cost := int(card.get("cost", 0))
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = maxi(0, int(stats.get("dao_breath", 0)) - cost)
	extra_stats[player.id] = stats
	_log("费用扣除：%s 支付 %d 点道息，当前道息 %d。" % [player.display_name, cost, int(stats.get("dao_breath", 0))])


func _prepare_chengdao_beast_card(card: Dictionary) -> Dictionary:
	if _is_pve_v1_card(card) and pve_effect_adapter != null:
		var summon_spec: Dictionary = pve_effect_adapter.get_summon_spec(card)
		if not summon_spec.is_empty():
			card["type"] = CardTypes.CHENGDAO
			card["summon_id"] = str(summon_spec.get("summon_id", card.get("id", "")))
			card["attack_value"] = int(summon_spec.get("attack", 0))
			card["attack"] = int(summon_spec.get("attack", 0))
			card["current_life"] = int(summon_spec.get("life", 1))
			card["max_life"] = int(summon_spec.get("life", 1))
			card["life"] = int(summon_spec.get("life", 1))
			card["side"] = str(summon_spec.get("side", "neutral"))
			card["chengdao_kind"] = str(summon_spec.get("chengdao_kind", ""))
			card["death_destination"] = str(summon_spec.get("death_destination", "discard"))
			card["is_special"] = bool(summon_spec.get("is_special", false))
			card["dao_tags"] = summon_spec.get("dao_tags", []).duplicate(true)
			return card
	if not card.has("attack") and not card.has("power") and not card.has("offense"):
		push_warning("%s 缺少 attack / power / offense，使用默认攻伐 10。" % str(card.get("name", "承道兽")))
		card["attack_value"] = 10
	else:
		card["attack_value"] = int(card.get("attack", card.get("power", card.get("offense", 10))))
	if not card.has("life") and not card.has("base_life"):
		push_warning("%s 缺少 life / base_life，使用默认命源 30。" % str(card.get("name", "承道兽")))
		card["current_life"] = 30
		card["max_life"] = 30
	else:
		card["current_life"] = int(card.get("life", card.get("base_life", 30)))
		card["max_life"] = int(card.get("current_life", 30))
	return card


func _beast_can_act(beast: Dictionary) -> bool:
	if beast.has("action_points_remaining"):
		return int(beast.get("action_points_remaining", 0)) > 0
	return not bool(beast.get("has_attacked", false))


func _consume_beast_action(board: BoardView, chengdao_index: int, beast: Dictionary) -> void:
	var action_points := maxi(1, int(beast.get("action_points", 1)))
	var remaining := maxi(0, int(beast.get("action_points_remaining", action_points)) - 1)
	beast["action_points"] = action_points
	beast["action_points_remaining"] = remaining
	beast["has_attacked"] = remaining <= 0
	beast["has_acted"] = remaining <= 0
	board.update_card(CardTypes.CHENGDAO, chengdao_index, beast)


func _basic_attack_with_beast(player: PlayerState, target: PlayerState, chengdao_index: int) -> void:
	var board := player_boards[game_state.active_player_index]
	var beast := board.get_card(CardTypes.CHENGDAO, chengdao_index)
	if beast.is_empty():
		_show_failure("请选择己方承道兽进行攻击。")
		return
	if not _beast_can_act(beast):
		_show_failure("【%s】本回合已攻击。" % str(beast.get("name", "")))
		return
	var damage := int(beast.get("attack_value", beast.get("attack", beast.get("power", beast.get("offense", 10)))))
	var actual := target.take_damage(damage)
	_consume_beast_action(board, chengdao_index, beast)
	_log("【%s】攻击敌方道主，造成 %d 点伤害。" % [str(beast.get("name", "")), actual])
	_log("伤害修正参考道主【%s】的道脉与侧性。" % _dao_master_name(target))
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _basic_attack_with_beast_to_enemy(player: PlayerState, chengdao_index: int) -> void:
	var board := player_boards[game_state.active_player_index]
	var beast := board.get_card(CardTypes.CHENGDAO, chengdao_index)
	if beast.is_empty():
		_show_failure("请选择己方承道兽进行攻击。")
		return
	if not _beast_can_act(beast):
		_show_failure("【%s】本回合已攻击。" % str(beast.get("name", "")))
		return
	var damage := int(beast.get("attack_value", beast.get("attack", beast.get("power", beast.get("offense", 10)))))
	var actual := _damage_enemy(damage)
	_consume_beast_action(board, chengdao_index, beast)
	_log("【%s】攻击%s，造成 %d 点伤害。" % [str(beast.get("name", "")), str(enemy.get("name", "敌人")), actual])
	_log("伤害修正参考道主【%s】的道脉与侧性。" % _dao_master_name(player))
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _basic_attack_with_beast_to_beast(player: PlayerState, target: PlayerState, attacker_index: int, target_index: int) -> void:
	var attacker_board := player_boards[game_state.active_player_index]
	var target_board := player_boards[1 - game_state.active_player_index]
	var beast := attacker_board.get_card(CardTypes.CHENGDAO, attacker_index)
	if beast.is_empty():
		_show_failure("请选择己方承道兽进行攻击。")
		return
	if not _beast_can_act(beast):
		_show_failure("【%s】本回合已攻击。" % str(beast.get("name", "")))
		return
	var target_beast := target_board.get_card(CardTypes.CHENGDAO, target_index)
	if target_beast.is_empty():
		_show_failure("目标区域错误。")
		return
	var damage := int(beast.get("attack_value", beast.get("attack", beast.get("power", beast.get("offense", 10)))))
	var damage_result := target_board.damage_card(CardTypes.CHENGDAO, target_index, damage)
	_consume_beast_action(attacker_board, attacker_index, beast)
	_log("【%s】攻击敌方承道兽【%s】，造成 %d 点伤害。" % [
		str(beast.get("name", "")),
		str(target_beast.get("name", "")),
		damage
	])
	if bool(damage_result.get("defeated", false)):
		var defeated_card: Dictionary = damage_result.get("card", {})
		if game_mode == "pve":
			_resolve_pve_beast_defeat(1 - game_state.active_player_index, defeated_card)
		else:
			target.discard_pile.append(defeated_card)
			_notify_chengdao_beast_died(1 - game_state.active_player_index, defeated_card)
		Breakthrough.add_dao_progress(player, 30)
		_log("【%s】命源归零，进入弃牌区。" % str(defeated_card.get("name", "")))
	_log("伤害修正参考道主【%s】的道脉与侧性。" % _dao_master_name(target))
	_clear_selection()
	_refresh_all()
	_check_game_over()


func _damage_pve_beast(owner_index: int, slot_index: int, amount: int) -> Dictionary:
	if owner_index < 0 or owner_index >= player_boards.size():
		return {"ok": false, "defeated": false, "reason": "承道兽归属无效。"}
	var damage_result := player_boards[owner_index].damage_card(CardTypes.CHENGDAO, slot_index, amount)
	if bool(damage_result.get("defeated", false)):
		var defeated_card: Dictionary = damage_result.get("card", {})
		_resolve_pve_beast_defeat(owner_index, defeated_card)
	return damage_result


func _resolve_pve_beast_defeat(owner_index: int, beast_data: Dictionary) -> void:
	if beast_data.is_empty():
		return
	var beast_target_id := _get_beast_target_id(beast_data)
	if beast_target_id != "beast:":
		_clear_combat_target_runtime_state(beast_target_id)
	var beast_name := str(beast_data.get("name", "承道兽"))
	_queue_combat_event("unit_defeated", {
		"target_id": beast_target_id,
		"owner_index": owner_index,
		"name": beast_name,
		"unit_type": "beast"
	})
	var rank := str(beast_data.get("beast_rank", "ordinary"))
	var destination := str(beast_data.get("death_destination", "discard"))
	var should_notify := false
	var source_card: Dictionary = {}
	if pve_beast_runtime != null and not bool(beast_data.get("is_token", false)):
		source_card = pve_beast_runtime.release_source_card(str(beast_data.get("beast_instance_id", "")))
	if rank == "token" or bool(beast_data.get("is_token", false)) or destination == "vanish":
		_log("【%s】命源归零，衍生承道兽消失。" % beast_name)
		should_notify = true
	elif source_card.is_empty():
		var missing_message := "承道兽死亡一致性错误：未找到来源卡。beast_instance_id=%s expected_source=%s rank=%s" % [
			str(beast_data.get("beast_instance_id", "")),
			str(beast_data.get("source_card_instance_id", "")),
			rank
		]
		push_error("[BattleScene] %s" % missing_message)
		_log(missing_message)
	elif str(source_card.get("instance_id", "")) != str(beast_data.get("source_card_instance_id", "")):
		var mismatch_message := "承道兽死亡一致性错误：来源卡实例不匹配。beast_instance_id=%s expected_source=%s actual_source=%s rank=%s" % [
			str(beast_data.get("beast_instance_id", "")),
			str(beast_data.get("source_card_instance_id", "")),
			str(source_card.get("instance_id", "")),
			rank
		]
		push_error("[BattleScene] %s" % mismatch_message)
		_log(mismatch_message)
	elif destination == "exhaust" or rank == "advanced":
		exhaust_pile.append(source_card)
		_log("【%s】命源归零，来源卡【%s】进入消耗堆。" % [beast_name, str(source_card.get("name", beast_name))])
		should_notify = true
	else:
		discard_pile.append(source_card)
		_log("【%s】命源归零，来源卡【%s】进入弃牌堆。" % [beast_name, str(source_card.get("name", beast_name))])
		should_notify = true
	if should_notify:
		_notify_chengdao_beast_died(owner_index, beast_data)
	_drain_combat_events()


func _notify_chengdao_beast_died(owner_index: int, beast_data: Dictionary) -> void:
	if game_mode != "pve" or owner_index != 0 or passive_runtime == null:
		return
	passive_runtime.on_chengdao_beast_died(beast_data)


func _select_attacker(chengdao_index: int) -> void:
	var board := player_boards[game_state.active_player_index]
	var beast := board.get_card(CardTypes.CHENGDAO, chengdao_index)
	if beast.is_empty():
		_show_failure("请选择己方承道兽进行攻击。")
		return
	if not _beast_can_act(beast):
		_show_failure("【%s】本回合已攻击。" % str(beast.get("name", "")))
		return
	selected_card = {}
	selected_card_view = null
	selected_card_source = ""
	selected_attacker = {"player_index": game_state.active_player_index, "slot_index": chengdao_index}
	_log("已选择承道兽【%s】作为攻击者。" % str(beast.get("name", "")))
	_update_operation_hint()
	_update_selected_detail()
	_refresh_central_battlefield()


func _has_selected_attacker() -> bool:
	return int(selected_attacker.get("player_index", -1)) == game_state.active_player_index and int(selected_attacker.get("slot_index", -1)) >= 0


func _first_ready_chengdao_index(board_index: int) -> int:
	for i in range(3):
		var beast := player_boards[board_index].get_card(CardTypes.CHENGDAO, i)
		if not beast.is_empty() and _beast_can_act(beast):
			return i
	return -1


func _refresh_turn_resources(player: PlayerState) -> void:
	var dao_master: Dictionary = active_dao_masters.get(player.id, {})
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["dao_breath"] = _get_character_int(dao_master, "base_daoxi", "dao_breath", 2)
	extra_stats[player.id] = stats
	player.formation_value = _get_character_int(dao_master, "base_formation", "formation_value", 3)
	_log("%s起势阶段，恢复基础道息和阵势值。" % player.display_name)


func _add_return_tide(player: PlayerState, amount: int) -> void:
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	stats["return_tide"] = maxi(0, int(stats.get("return_tide", 0)) + amount)
	extra_stats[player.id] = stats
	_sync_run_state_resources(player)


func _get_return_tide(player: PlayerState) -> int:
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	return int(stats.get("return_tide", 0))


func _sync_run_state_resources(player: PlayerState) -> void:
	if game_mode != "pve" or player == null or player.id != "p1":
		return
	var run_state = RunStateScript.get_current()
	if run_state == null or not bool(run_state.run_started):
		return
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	run_state.current_life = int(player.life_source)
	run_state.current_daoxi = int(stats.get("dao_breath", 0))
	run_state.formation = int(player.formation_value)
	run_state.reflux = int(stats.get("return_tide", 0))
	run_state.daoxing = int(player.dao_progress)


func _is_artifact_eligible(player: PlayerState, card: Dictionary) -> bool:
	var dao_master: Dictionary = active_dao_masters.get(player.id, {})
	var master_id := str(dao_master.get("id", ""))
	var required_character := str(card.get("required_character", ""))
	if required_character != "" and required_character != master_id:
		return false
	var compatible_characters: Array = card.get("compatible_characters", [])
	if not compatible_characters.is_empty() and not compatible_characters.has(master_id):
		return false
	var pact: Dictionary = card.get("fate_pact", {})
	var pact_owner := str(pact.get("required_owner_id", ""))
	if pact_owner != "" and pact_owner != master_id:
		return false
	var card_weapons: Array = card.get("compatible_weapons", [])
	if not card_weapons.is_empty():
		var master_weapons: Array = dao_master.get("compatible_weapons", [])
		for weapon in card_weapons:
			if master_weapons.has(str(weapon)):
				return true
		return false
	return true


func _check_game_over() -> void:
	if game_state == null or game_over:
		return
	if game_mode == "pve":
		var player := game_state.players[0]
		if int(enemy.get("life", 0)) <= 0:
			_clear_combat_target_runtime_state(_get_enemy_target_id())
			game_over = true
			discard_phase = false
			need_discard = 0
			discard_phase_player_id = ""
			_clear_selection()
			operation_hint_label.text = "战斗胜利：击败%s。" % str(enemy.get("name", "敌人"))
			_log("战斗胜利：击败%s。" % str(enemy.get("name", "敌人")))
			_refresh_all()
			return
		if player.life_source <= 0:
			_clear_combat_target_runtime_state(_get_player_target_id())
			game_over = true
			discard_phase = false
			need_discard = 0
			discard_phase_player_id = ""
			_clear_selection()
			operation_hint_label.text = "战斗失败：道主命源归零。"
			_log("战斗失败：道主命源归零。")
			_refresh_all()
			return
	for player in game_state.players:
		if player.life_source <= 0:
			var winner := game_state.get_opponent_of(player)
			game_over = true
			discard_phase = false
			need_discard = 0
			discard_phase_player_id = ""
			if winner.id == "p1":
				player1_match_wins += 1
			else:
				player2_match_wins += 1
			var round_message := "第 %d 局结束：%s胜利。" % [current_match_round, winner.display_name]
			_clear_selection()
			_log("%s 命源归零，%s" % [player.display_name, round_message])
			if player1_match_wins >= 2 or player2_match_wins >= 2 or current_match_round >= 3:
				match_over = true
				match_winner = winner.display_name
				operation_hint_label.text = "Match 结束：%s获胜。" % winner.display_name
				_log("Match 结束：%s获胜。" % winner.display_name)
			else:
				operation_hint_label.text = "%s 请点击进入下一局。" % round_message
			_refresh_all()
			return


func _resonance_message(card: Dictionary, player: PlayerState, is_entering_board: bool) -> String:
	var card_type := str(card.get("type", ""))
	if card_type != CardTypes.CHENGDAO and card_type != CardTypes.DAOFA:
		return ""
	var card_name := str(card.get("name", ""))
	if _has_dao_resonance(card, player):
		return "【%s】与道主【%s】道脉共鸣。" % [card_name, _dao_master_name(player)]
	if card_type == CardTypes.DAOFA:
		return "未触发道主道脉共鸣，按基础效果结算。"
	if is_entering_board:
		return "【%s】登场。未触发道主道脉共鸣。" % card_name
	return ""


func _has_dao_resonance(card: Dictionary, player: PlayerState) -> bool:
	var dao_tags: Array = card.get("dao_tags", [])
	for tag in dao_tags:
		if player.has_dao_path(str(tag)):
			return true
	return false


func _clear_board_highlights() -> void:
	for board in player_boards:
		board.clear_highlights()


func _show_failure(reason: String) -> void:
	operation_hint_label.text = reason
	_log(reason)


func _game_over_action_message() -> String:
	if game_mode == "pve":
		return "战斗已结束，请重新开始战斗。"
	if match_over:
		return "Match 已结束，请重新开始 Match。"
	return "本局已结束，请点击进入下一局或重新开始 Match。"


func _wrong_slot_reason(card_type: String) -> String:
	if card_type == "character":
		return "人物牌只能作为道主，不能进入承道位。"
	if card_type == CardTypes.CHENGDAO:
		return "承道牌只能放入己方承道位。"
	if card_type == CardTypes.DAOFA:
		return "道法牌需要选择敌方目标。"
	if card_type == CardTypes.FORMATION:
		return "法阵牌只能放入己方法阵位。"
	if card_type == CardTypes.DAO_MARK:
		return "道痕牌只能放入己方道痕区。"
	if card_type == CardTypes.DOMAIN:
		return "域界牌只能放入己方域界位。"
	if card_type == CardTypes.LIFE_ARTIFACT:
		return "命器牌只能放入己方命器位。"
	if card_type == CardTypes.TRAP:
		return "伏法牌只能放入己方伏法位。"
	return "该牌不能放入所选区域。"


func _occupied_slot_reason(slot_type: String) -> String:
	if slot_type == CardTypes.CHENGDAO:
		return "该承道位已有承道者。"
	if slot_type == CardTypes.FORMATION:
		return "法阵位已有法阵。"
	if slot_type == CardTypes.DAO_MARK:
		return "道痕区已满。" if not _board_has_empty(game_state.active_player_index, CardTypes.DAO_MARK) else "请选择空的道痕区。"
	if slot_type == CardTypes.TRAP:
		return "伏法位已满。" if not _board_has_empty(game_state.active_player_index, CardTypes.TRAP) else "请选择空的伏法位。"
	if slot_type == CardTypes.LIFE_ARTIFACT:
		return "命器位已有命器。"
	if slot_type == CardTypes.DOMAIN:
		return "域界位已有域界。"
	return "该位置已经有牌。"


func _board_has_empty(board_index: int, slot_type: String) -> bool:
	var count := _slot_count(slot_type)
	for i in range(count):
		if player_boards[board_index].is_slot_empty(slot_type, i):
			return true
	return false


func _slot_count(slot_type: String) -> int:
	if slot_type == CardTypes.CHENGDAO:
		return 3
	if slot_type == CardTypes.TRAP:
		return 2
	if slot_type == CardTypes.DAO_MARK:
		return 3
	return 1


func _expected_slot_for_card(card_type: String) -> String:
	if card_type == "character":
		return "道主位"
	if card_type == CardTypes.CHENGDAO:
		return CardTypes.CHENGDAO
	if card_type == CardTypes.FORMATION:
		return CardTypes.FORMATION
	if card_type == CardTypes.DAO_MARK:
		return CardTypes.DAO_MARK
	if card_type == CardTypes.DOMAIN:
		return CardTypes.DOMAIN
	if card_type == CardTypes.LIFE_ARTIFACT:
		return CardTypes.LIFE_ARTIFACT
	if card_type == CardTypes.TRAP:
		return CardTypes.TRAP
	if card_type == CardTypes.DAOFA:
		return "敌方目标"
	return ""


func _slot_display_name(slot_type: String) -> String:
	if slot_type == CardTypes.CHENGDAO:
		return "承道位"
	if slot_type == CardTypes.FORMATION:
		return "法阵位"
	if slot_type == CardTypes.DAO_MARK:
		return "道痕区"
	if slot_type == CardTypes.DOMAIN:
		return "域界位"
	if slot_type == CardTypes.LIFE_ARTIFACT:
		return "命器位"
	if slot_type == CardTypes.TRAP:
		return "伏法位"
	if slot_type == "敌方目标":
		return "敌方本体或敌方承道者"
	if slot_type == "target":
		return "敌方本体"
	if slot_type == "道主位":
		return "道主位"
	return "未知区域"


func _dao_tags_text(card: Dictionary) -> String:
	var dao_tags: Array = card.get("dao_tags", [])
	if dao_tags.is_empty():
		return "无"
	return _array_text(dao_tags)


func _array_text(values: Array) -> String:
	return _array_text_with_separator(values, "、")


func _array_text_with_separator(values: Array, separator: String) -> String:
	var text := ""
	for tag in values:
		if text != "":
			text += separator
		text += str(tag)
	return text


func _format_dao_master_info(player: PlayerState) -> String:
	var dao_master: Dictionary = active_dao_masters.get(player.id, {})
	if dao_master.is_empty():
		return "道主位：未设置"
	var stats: Dictionary = extra_stats.get(player.id, {"dao_breath": 0, "return_tide": 0})
	var strike_text := "已使用" if bool(dao_strike_used.get(player.id, false)) else "可用"
	var passive_name := str(dao_master.get("passive_name", ""))
	if passive_name == "" and passive_runtime != null:
		passive_name = passive_runtime.get_passive_name()
	return "%s｜%s\n命源 %d/%d｜道脉 %s\n道息 %d｜阵势 %d｜回潮 %d\n道行 %d｜道击 %s\n被动：%s" % [
		str(dao_master.get("name", "未知道主")),
		Realm.get_realm_name(player.combat_realm),
		player.life_source,
		player.max_life_source,
		_array_text(dao_master.get("dao_tags", [])),
		int(stats.get("dao_breath", 0)),
		player.formation_value,
		int(stats.get("return_tide", 0)),
		player.dao_progress,
		strike_text,
		passive_name if passive_name != "" else "无"
	]


func _format_dao_master_detail(player: PlayerState) -> String:
	var dao_master: Dictionary = active_dao_masters.get(player.id, {})
	if dao_master.is_empty():
		return ""
	var traits: Array = dao_master.get("traits", [])
	var compatible: Array = dao_master.get("compatible_weapons", dao_master.get("artifact_eligibility", []))
	var passive_desc := str(dao_master.get("passive_desc", ""))
	if passive_desc == "" and passive_runtime != null:
		passive_desc = passive_runtime.get_passive_description()
	return "侧性：%s\n特性：%s\n命器适格：%s\n被动说明：%s" % [
		_display_side(str(dao_master.get("side", "neutral"))),
		_array_text(traits),
		_array_text(compatible),
		passive_desc
	]


func _dao_master_name(player: PlayerState) -> String:
	var dao_master: Dictionary = active_dao_masters.get(player.id, {})
	return str(dao_master.get("name", "未设置"))


func _display_chengdao_kind(value: String) -> String:
	if value == "order_beast":
		return "秩序侧兽"
	if value == "chaos_beast":
		return "混沌侧兽"
	if value == "character":
		return "人物"
	return value


func _display_side(value: String) -> String:
	if value == "order":
		return "秩序"
	if value == "chaos":
		return "混沌"
	if value == "neutral":
		return "中立"
	return value


func _is_chengdao_beast(card: Dictionary) -> bool:
	var kind := str(card.get("chengdao_kind", ""))
	return kind == "order_beast" or kind == "chaos_beast"


func _apply_active_player_styles() -> void:
	var active_index := game_state.active_player_index
	var active_player := game_state.get_active_player()
	active_label.text = _format_pve_status(active_player) if game_mode == "pve" else _format_match_status(active_player)
	if player_portrait_panel != null:
		player_portrait_panel.add_theme_stylebox_override("panel", active_panel_style)
	if opponent_portrait_panel != null:
		opponent_portrait_panel.add_theme_stylebox_override("panel", inactive_panel_style)
	for i in range(player_info_panels.size()):
		var is_active := i == active_index
		player_info_panels[i].add_theme_stylebox_override("panel", active_panel_style if is_active else inactive_panel_style)
		player_info_panels[i].modulate = Color.WHITE if is_active else Color(0.66, 0.66, 0.70, 1.0)
	for i in range(board_panels.size()):
		var is_active := i == active_index
		board_panels[i].add_theme_stylebox_override("panel", active_panel_style if is_active else inactive_panel_style)
		board_panels[i].modulate = Color.WHITE if is_active else Color(0.66, 0.66, 0.70, 1.0)
		dao_master_panels[i].add_theme_stylebox_override("panel", active_panel_style if is_active else inactive_panel_style)
		player_boards[i].set_active_visual(is_active)
