extends HBoxContainer
class_name HandView

signal card_selected(card: Dictionary, view: CardView)

const CARD_VIEW_SCENE := preload("res://scenes/battle/CardView.tscn")

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func set_cards(cards: Array, unavailable_reasons: Dictionary = {}, empty_message: String = "当前无手牌", max_slots: int = 0) -> void:
	for child in get_children():
		child.queue_free()
	if cards.is_empty():
		if max_slots <= 0:
			show_message(empty_message)
			return
	for card in cards:
		var card_view := CARD_VIEW_SCENE.instantiate() as CardView
		add_child(card_view)
		card_view.configure(card)
		var reason := str(unavailable_reasons.get(_card_key(card), ""))
		if reason != "":
			card_view.set_unavailable(reason)
		card_view.card_selected.connect(_on_card_selected)
	if max_slots > 0:
		for i in range(maxi(0, max_slots - cards.size())):
			var slot := Button.new()
			slot.text = "空手牌槽"
			slot.disabled = true
			slot.custom_minimum_size = Vector2(132, 158)
			add_child(slot)


func show_message(message: String) -> void:
	for child in get_children():
		child.queue_free()
	var label := Label.new()
	label.text = message
	label.custom_minimum_size = Vector2(160, 112)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)


func clear_selection() -> void:
	for child in get_children():
		if child is CardView:
			child.set_selected(false)


func mark_selected(view: CardView) -> void:
	clear_selection()
	if view != null:
		view.set_selected(true)


func _on_card_selected(card: Dictionary, view: CardView) -> void:
	mark_selected(view)
	card_selected.emit(card, view)


func _card_key(card: Dictionary) -> String:
	return str(card.get("id", card.get("name", "")))
