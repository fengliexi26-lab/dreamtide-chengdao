extends Button
class_name CardView

signal card_selected(card: Dictionary, view: CardView)

var card_data: Dictionary = {}
var unavailable_reason := ""
var normal_style := StyleBoxFlat.new()
var selected_style := StyleBoxFlat.new()
var unavailable_style := StyleBoxFlat.new()

func _ready() -> void:
	custom_minimum_size = Vector2(132, 158)
	focus_mode = Control.FOCUS_NONE
	clip_text = false
	add_theme_font_size_override("font_size", 13)
	normal_style = _make_card_style(Color.html("#1c1a2a"), Color.html("#4c465a"), 1)
	selected_style = _make_card_style(Color.html("#242033"), Color.html("#d6ad52"), 2)
	unavailable_style = _make_card_style(Color.html("#151720"), Color.html("#343241"), 1)
	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", selected_style)
	add_theme_stylebox_override("pressed", selected_style)
	pressed.connect(_on_pressed)


func _make_card_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func configure(card: Dictionary) -> void:
	card_data = card
	var card_name := str(card.get("name", "未命名"))
	var card_type := CardTypes.get_display_name(str(card.get("type", "")))
	var chengdao_kind := _display_chengdao_kind(str(card.get("chengdao_kind", "")))
	var cost := int(card.get("cost", 0))
	var dao_tags: Array = card.get("dao_tags", [])
	var dao_text := "无"
	if not dao_tags.is_empty():
		dao_text = ""
		for tag in dao_tags:
			if dao_text != "":
				dao_text += "、"
			dao_text += str(tag)
	var effect_text := _effect_text(card)
	if effect_text.length() > 14:
		effect_text = effect_text.substr(0, 14) + "..."
	if card_name.length() > 7:
		card_name = card_name.substr(0, 7) + "..."
	if dao_text.length() > 8:
		dao_text = dao_text.substr(0, 8) + "..."
	var kind_line := ""
	if str(card.get("type", "")) == CardTypes.CHENGDAO:
		kind_line = "\n%s" % chengdao_kind
	var stat_line := ""
	if str(card.get("type", "")) == CardTypes.CHENGDAO:
		stat_line = "\n攻 %d / 命 %d" % [
			int(card.get("attack", card.get("power", card.get("offense", 0)))),
			int(card.get("life", card.get("base_life", 0)))
		]
	text = "费 %d\n%s\n%s%s\n道脉 %s%s\n%s" % [cost, card_name, card_type, kind_line, dao_text, stat_line, effect_text]
	tooltip_text = "%s\n%s%s\n费用 %d\n道脉 %s\n%s" % [card_name, card_type, kind_line, cost, dao_text, _effect_text(card)]


func set_selected(is_selected: bool) -> void:
	if is_selected and unavailable_reason != "":
		add_theme_stylebox_override("normal", selected_style)
		modulate = Color(0.78, 0.68, 0.42, 1.0)
	elif unavailable_reason != "":
		add_theme_stylebox_override("normal", unavailable_style)
		modulate = Color(0.45, 0.45, 0.48, 1.0)
	elif is_selected:
		add_theme_stylebox_override("normal", selected_style)
		modulate = Color(1.0, 0.92, 0.72)
	else:
		add_theme_stylebox_override("normal", normal_style)
		modulate = Color.WHITE


func set_unavailable(reason: String) -> void:
	unavailable_reason = reason
	if unavailable_reason != "":
		tooltip_text += "\n不可用：%s" % unavailable_reason
	set_selected(false)


func _on_pressed() -> void:
	card_selected.emit(card_data, self)


func _display_chengdao_kind(value: String) -> String:
	if value == "order_beast":
		return "秩序侧兽"
	if value == "chaos_beast":
		return "混沌侧兽"
	if value == "character":
		return "人物"
	return value


func _effect_text(card: Dictionary) -> String:
	for field in ["text", "effect_text", "description"]:
		var value := str(card.get(field, ""))
		if value != "":
			return value
	return ""
