extends VBoxContainer
class_name BoardView

signal slot_selected(slot_type: String, index: int)

const SLOT_LAYOUT := [
	{"type": "chengdao", "label": "承道位", "count": 3},
	{"type": "trap", "label": "伏法位", "count": 2},
	{"type": "formation", "label": "法阵位", "count": 1},
	{"type": "domain", "label": "域界位", "count": 1},
	{"type": "life_artifact", "label": "命器位", "count": 1},
	{"type": "dao_mark", "label": "道痕区", "count": 3}
]

var title_label: Label
var slot_buttons: Dictionary = {}
var occupied_slots: Dictionary = {}
var placed_cards: Dictionary = {}
var default_slot_style := StyleBoxFlat.new()
var highlighted_slot_style := StyleBoxFlat.new()
var active_modulate := Color.WHITE
var inactive_modulate := Color(0.58, 0.58, 0.62, 1.0)

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	default_slot_style.bg_color = Color(0.13, 0.12, 0.16, 0.92)
	default_slot_style.border_color = Color(0.40, 0.36, 0.48, 1.0)
	default_slot_style.set_border_width_all(1)
	default_slot_style.set_corner_radius_all(4)
	highlighted_slot_style.bg_color = Color(0.18, 0.31, 0.33, 1.0)
	highlighted_slot_style.border_color = Color(0.18, 0.90, 0.78, 1.0)
	highlighted_slot_style.set_border_width_all(3)
	highlighted_slot_style.set_corner_radius_all(4)


func setup(title: String) -> void:
	for child in get_children():
		child.queue_free()
	slot_buttons.clear()
	occupied_slots.clear()
	placed_cards.clear()

	title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)

	var target_button := Button.new()
	target_button.text = "道主目标"
	target_button.tooltip_text = "选择该玩家道主作为道法或攻击目标"
	target_button.pressed.connect(_on_slot_pressed.bind("target", 0))
	add_child(target_button)
	slot_buttons[_key("target", 0)] = target_button
	_apply_default_style(target_button)

	for row in SLOT_LAYOUT:
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 6)
		add_child(row_box)

		var row_label := Label.new()
		row_label.text = str(row.get("label", "区域"))
		row_label.custom_minimum_size = Vector2(72, 28)
		row_box.add_child(row_label)

		for i in range(int(row.get("count", 0))):
			var button := Button.new()
			button.custom_minimum_size = Vector2(108, 42)
			button.text = "空"
			button.tooltip_text = "点击此区域出牌"
			button.pressed.connect(_on_slot_pressed.bind(str(row.get("type", "")), i))
			row_box.add_child(button)
			slot_buttons[_key(str(row.get("type", "")), i)] = button
			occupied_slots[_key(str(row.get("type", "")), i)] = false
			_apply_default_style(button)


func place_card(slot_type: String, index: int, card: Dictionary) -> void:
	var button := slot_buttons.get(_key(slot_type, index)) as Button
	if button == null:
		return
	var placed_card := card.duplicate(true)
	if slot_type == CardTypes.CHENGDAO:
		if not placed_card.has("current_life"):
			placed_card["current_life"] = int(placed_card.get("life", placed_card.get("base_life", 30)))
		if not placed_card.has("max_life"):
			placed_card["max_life"] = int(placed_card.get("current_life", 30))
		if not placed_card.has("attack_value"):
			placed_card["attack_value"] = int(placed_card.get("attack", placed_card.get("power", placed_card.get("offense", 10))))
		placed_card["has_attacked"] = false
	placed_cards[_key(slot_type, index)] = placed_card
	button.text = _format_slot_text(slot_type, placed_card)
	button.tooltip_text = str(card.get("text", "已放置"))
	occupied_slots[_key(slot_type, index)] = true
	_apply_default_style(button)


func is_slot_empty(slot_type: String, index: int) -> bool:
	return bool(not occupied_slots.get(_key(slot_type, index), false))


func get_card(slot_type: String, index: int) -> Dictionary:
	return placed_cards.get(_key(slot_type, index), {})


func get_cards_in_slots(slot_type: String) -> Array:
	var cards: Array = []
	for i in range(_slot_count_for_type(slot_type)):
		var card: Dictionary = placed_cards.get(_key(slot_type, i), {})
		if not card.is_empty():
			cards.append(card.duplicate(true))
	return cards


func update_card(slot_type: String, index: int, card: Dictionary) -> void:
	var key := _key(slot_type, index)
	if card.is_empty() or not placed_cards.has(key):
		return
	placed_cards[key] = card
	var button := slot_buttons.get(key) as Button
	if button != null:
		button.text = _format_slot_text(slot_type, card)


func damage_card(slot_type: String, index: int, amount: int) -> Dictionary:
	var key := _key(slot_type, index)
	var card: Dictionary = placed_cards.get(key, {})
	if card.is_empty():
		return {"ok": false, "defeated": false}
	card["current_life"] = int(card.get("current_life", 0)) - maxi(0, amount)
	var defeated := int(card.get("current_life", 0)) <= 0
	if defeated:
		remove_card(slot_type, index)
	else:
		placed_cards[key] = card
		var button := slot_buttons.get(key) as Button
		if button != null:
			button.text = _format_slot_text(slot_type, card)
	return {"ok": true, "defeated": defeated, "card": card}


func remove_card(slot_type: String, index: int) -> Dictionary:
	var key := _key(slot_type, index)
	var card: Dictionary = placed_cards.get(key, {})
	placed_cards.erase(key)
	occupied_slots[key] = false
	var button := slot_buttons.get(key) as Button
	if button != null:
		button.text = "空"
		button.tooltip_text = "点击此区域出牌"
		_apply_default_style(button)
	return card


func set_card_attacked(slot_type: String, index: int, has_attacked: bool) -> void:
	var key := _key(slot_type, index)
	var card: Dictionary = placed_cards.get(key, {})
	if card.is_empty():
		return
	card["has_attacked"] = has_attacked
	card["has_acted"] = has_attacked
	card["action_points_remaining"] = 0 if has_attacked else int(card.get("action_points", 1))
	placed_cards[key] = card
	var button := slot_buttons.get(key) as Button
	if button != null:
		button.text = _format_slot_text(slot_type, card)


func reset_beast_actions() -> void:
	for key in placed_cards.keys():
		var card: Dictionary = placed_cards[key]
		if str(card.get("type", "")) == CardTypes.CHENGDAO:
			var action_points := maxi(1, int(card.get("action_points", 1)))
			card["action_points"] = action_points
			card["action_points_remaining"] = action_points
			card["has_attacked"] = false
			card["has_acted"] = false
			placed_cards[key] = card
			var parts := str(key).split(":")
			var button := slot_buttons.get(key) as Button
			if button != null:
				button.text = _format_slot_text(str(parts[0]), card)


func clear_attack_flags() -> void:
	reset_beast_actions()


func highlight_slots(slot_type: String, only_empty: bool = true, clear_first: bool = true) -> void:
	if clear_first:
		clear_highlights()
	for key in slot_buttons.keys():
		if not str(key).begins_with("%s:" % slot_type):
			continue
		var parts := str(key).split(":")
		var index := int(parts[1])
		if only_empty and not is_slot_empty(slot_type, index):
			continue
		var button := slot_buttons.get(key) as Button
		if button != null:
			button.add_theme_stylebox_override("normal", highlighted_slot_style)
			button.add_theme_stylebox_override("hover", highlighted_slot_style)
			button.add_theme_stylebox_override("pressed", highlighted_slot_style)


func highlight_occupied_slots(slot_type: String, clear_first: bool = true) -> void:
	if clear_first:
		clear_highlights()
	for key in slot_buttons.keys():
		if not str(key).begins_with("%s:" % slot_type):
			continue
		var parts := str(key).split(":")
		var index := int(parts[1])
		if is_slot_empty(slot_type, index):
			continue
		var button := slot_buttons.get(key) as Button
		if button != null:
			button.add_theme_stylebox_override("normal", highlighted_slot_style)
			button.add_theme_stylebox_override("hover", highlighted_slot_style)
			button.add_theme_stylebox_override("pressed", highlighted_slot_style)


func highlight_target() -> void:
	highlight_target_keep(true)


func highlight_target_keep(clear_first: bool = true) -> void:
	if clear_first:
		clear_highlights()
	var button := slot_buttons.get(_key("target", 0)) as Button
	if button != null:
		button.add_theme_stylebox_override("normal", highlighted_slot_style)
		button.add_theme_stylebox_override("hover", highlighted_slot_style)
		button.add_theme_stylebox_override("pressed", highlighted_slot_style)


func clear_highlights() -> void:
	for button in slot_buttons.values():
		if button is Button:
			_apply_default_style(button)


func set_active_visual(is_active: bool) -> void:
	modulate = active_modulate if is_active else inactive_modulate
	if title_label != null:
		title_label.text = title_label.text.replace("（当前行动）", "")
		if is_active:
			title_label.text += "（当前行动）"


func reset_board() -> void:
	for button in slot_buttons.values():
		if button is Button:
			button.text = "空"
			_apply_default_style(button)
	for key in occupied_slots.keys():
		occupied_slots[key] = false
	placed_cards.clear()


func _apply_default_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", default_slot_style)
	button.add_theme_stylebox_override("hover", default_slot_style)
	button.add_theme_stylebox_override("pressed", default_slot_style)


func _key(slot_type: String, index: int) -> String:
	return "%s:%d" % [slot_type, index]


func _slot_count_for_type(slot_type: String) -> int:
	for row in SLOT_LAYOUT:
		if str(row.get("type", "")) == slot_type:
			return int(row.get("count", 0))
	return 0


func _on_slot_pressed(slot_type: String, index: int) -> void:
	slot_selected.emit(slot_type, index)


func _format_slot_text(slot_type: String, card: Dictionary) -> String:
	if slot_type == CardTypes.CHENGDAO:
		var attacked := "\n已攻击" if bool(card.get("has_attacked", false)) else ""
		return "%s\n%s / %s\n%s\n攻伐 %d  命源 %d/%d%s" % [
			str(card.get("name", "承道兽")),
			str(card.get("chengdao_kind", "")),
			str(card.get("side", "")),
			_array_text(card.get("dao_tags", [])),
			int(card.get("attack_value", 0)),
			int(card.get("current_life", 0)),
			int(card.get("max_life", 0)),
			attacked
		]
	return str(card.get("name", "已放置"))


func _array_text(values: Array) -> String:
	if values.is_empty():
		return "无"
	var text := ""
	for value in values:
		if text != "":
			text += "、"
		text += str(value)
	return text
