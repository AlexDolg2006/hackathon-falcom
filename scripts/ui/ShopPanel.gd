extends Control

const UIUtils = preload("res://scripts/ui/UIUtils.gd")

var list_box: VBoxContainer
var budget_label: Label


func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	# --- Верхняя информационная карточка ---
	var top_card := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.94, 0.94, 0.98)
	top_style.set_corner_radius_all(16)
	top_style.content_margin_left = 14
	top_style.content_margin_right = 14
	top_style.content_margin_top = 10
	top_style.content_margin_bottom = 10
	top_style.shadow_size = 2
	top_style.shadow_color = Color(0, 0, 0, 0.08)
	top_card.add_theme_stylebox_override("panel", top_style)
	vb.add_child(top_card)

	var top_vb := VBoxContainer.new()
	top_vb.add_theme_constant_override("separation", 4)
	top_card.add_child(top_vb)

	var title := Label.new()
	title.text = "🛒 Магазин"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	top_vb.add_child(title)

	budget_label = Label.new()
	budget_label.add_theme_font_size_override("font_size", 17)
	budget_label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.35))
	budget_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(budget_label)

	# --- Список товаров ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 12)
	scroll.add_child(list_box)


func _refresh() -> void:
	if GameData.period_active:
		budget_label.text = "План: обяз. %d%% | желаем. %d%% | накопл. %d%%\nДоступно: обяз. %d монет | желаем. %d монет" % [
			GameData.plan_pct_mandatory, GameData.plan_pct_optional, GameData.plan_pct_savings,
			GameData.mandatory_budget, GameData.optional_budget]
	else:
		budget_label.text = "Сначала составь план бюджета на вкладке «Бюджет».\nВ кошельке: %d монет." % GameData.wallet

	for child in list_box.get_children():
		child.queue_free()

	var mandatory_items := []
	var optional_items := []
	for it in GameData.shop_items:
		if it.get("category") == "mandatory":
			mandatory_items.append(it)
		else:
			optional_items.append(it)

	_add_section("🍎 Обязательные расходы (еда и уход)", mandatory_items)
	_add_section("🧸 Желаемое (шапки и игрушки)", optional_items)


func _add_section(title_text: String, items: Array) -> void:
	var header := Label.new()
	header.text = title_text
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1, 1, 1))
	list_box.add_child(header)

	for it in items:
		list_box.add_child(_build_item_row(it))


func _build_item_row(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.95, 0.95, 0.98)
	card_style.set_corner_radius_all(16)
	card_style.shadow_size = 2
	card_style.shadow_color = Color(0, 0, 0, 0.06)
	panel.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hb)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 4)
	hb.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = "%s — %d монет" % [item.get("name"), item.get("price")]
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(item.get("desc", ""))
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(desc_lbl)

	var effect_txt := ""
	if int(item.get("hunger", 0)) > 0:
		effect_txt += "🍖 Сытость +%d  " % int(item.get("hunger"))
	if int(item.get("mood", 0)) > 0:
		effect_txt += "😊 Настроение +%d  " % int(item.get("mood"))
	if item.get("slot") == "wash":
		effect_txt += "🧼 Появится в ведре для купания"
	if effect_txt != "":
		var effect_lbl := Label.new()
		effect_lbl.text = effect_txt
		effect_lbl.add_theme_font_size_override("font_size", 16)
		effect_lbl.add_theme_color_override("font_color", Color(0.1, 0.55, 0.3))
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		info.add_child(effect_lbl)

	var slot: String = item.get("slot", "")
	var owned: int = int(GameData.inventory.get(item.get("id"), 0))
	if owned > 0:
		var owned_lbl := Label.new()
		owned_lbl.text = "В наличии: %d шт." % owned
		owned_lbl.add_theme_font_size_override("font_size", 16)
		owned_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		info.add_child(owned_lbl)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(buttons)

	if slot == "hat" and owned > 0:
		var is_worn: bool = GameData.equipped_hat == item.get("id")
		var wear_btn := _create_pill_button("Надеть" if not is_worn else "Снять", Color(0.55, 0.40, 0.80), 42)
		wear_btn.custom_minimum_size = Vector2(130, 42)
		wear_btn.pressed.connect(func():
			if is_worn:
				GameData.unequip_hat()
			else:
				GameData.equip_hat(item.get("id"))
		)
		buttons.add_child(wear_btn)

	if slot == "wash" and owned > 0:
		var is_active: bool = GameData.equipped_wash == item.get("id")
		var use_btn := _create_pill_button("В ведре ✓" if is_active else "В ведро", Color(0.2, 0.6, 0.75), 42)
		use_btn.disabled = is_active
		use_btn.custom_minimum_size = Vector2(130, 42)
		use_btn.pressed.connect(func(): GameData.equip_wash(item.get("id")))
		buttons.add_child(use_btn)

	var buy_btn := _create_pill_button("Купить", Color(0.22, 0.65, 0.35), 48)
	buy_btn.custom_minimum_size = Vector2(130, 48)
	buy_btn.pressed.connect(func(): _on_buy_pressed(item))
	buttons.add_child(buy_btn)

	return panel


func _create_pill_button(text: String, bg_color: Color, height: int) -> Button:
	var btn := Button.new()
	btn.text = text
	UIUtils.style_pill_button(btn, bg_color, height, 18)
	return btn


func _on_buy_pressed(item: Dictionary) -> void:
	var check := GameData.can_afford(item.get("id"))
	if not check.get("ok"):
		UIUtils.show_message(self, "Покупка недоступна", str(check.get("reason")))
		return

	var item_id = item.get("id")
	UIUtils.show_confirm(self, "Покупка",
		"Купить «%s» за %d монет?\nКатегория: %s" % [
			item.get("name"), item.get("price"),
			("обязательное" if item.get("category") == "mandatory" else "желаемое")
		],
		func():
			var res := GameData.buy_item(item_id)
			if not res.get("ok"):
				UIUtils.show_message(self, "Не получилось", str(res.get("reason"))),
		"Купить", "Отмена",
		UIUtils.SUCCESS)
