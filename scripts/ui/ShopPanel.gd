extends Control

var list_box: VBoxContainer
var budget_label: Label

func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vb)

	var title := Label.new()
	title.text = "Магазин"
	title.add_theme_font_size_override("font_size", 28)
	vb.add_child(title)

	budget_label = Label.new()
	budget_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(budget_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(list_box)


func _refresh() -> void:
	if GameData.period_active:
		budget_label.text = "План: обяз. %d%% | желаем. %d%% | накопл. %d%%.\nКошельки: обязательное %d монет, желаемое %d монет." % [
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

	_add_section("Обязательные расходы (еда и уход)", mandatory_items)
	_add_section("Желаемое (шапки и игрушки)", optional_items)

func _add_section(title: String, items: Array) -> void:
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 20)
	list_box.add_child(header)
	for it in items:
		list_box.add_child(_build_item_row(it))


func _build_item_row(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = "%s — %d монет" % [item.get("name"), item.get("price")]
	name_lbl.add_theme_font_size_override("font_size", 18)
	info.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = str(item.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.modulate = Color(1, 1, 1, 0.75)
	info.add_child(desc_lbl)
	var effect_txt := ""
	if int(item.get("hunger", 0)) > 0:
		effect_txt += "Сытость +%d  " % int(item.get("hunger"))
	if int(item.get("mood", 0)) > 0:
		effect_txt += "Настроение +%d" % int(item.get("mood"))
	var effect_lbl := Label.new()
	effect_lbl.text = effect_txt
	info.add_child(effect_lbl)
	hb.add_child(info)

	if item.has("slot") and item.get("slot") == "hat" and int(GameData.inventory.get(item.get("id"), 0)) > 0:
		var owned_lbl := Label.new()
		owned_lbl.text = "В наличии: %d" % int(GameData.inventory.get(item.get("id")))
		info.add_child(owned_lbl)
		var wear_btn := Button.new()
		wear_btn.text = "Надеть" if GameData.equipped_hat != item.get("id") else "Снять"
		wear_btn.pressed.connect(func():
			if GameData.equipped_hat == item.get("id"):
				GameData.unequip_hat()
			else:
				GameData.equip_hat(item.get("id"))
		)
		hb.add_child(wear_btn)

	var buy_btn := Button.new()
	buy_btn.text = "Купить"
	buy_btn.custom_minimum_size = Vector2(130, 56)
	buy_btn.pressed.connect(func(): _on_buy_pressed(item))
	hb.add_child(buy_btn)

	panel.add_child(hb)
	return panel


func _on_buy_pressed(item: Dictionary) -> void:
	var check := GameData.can_afford(item.get("id"))
	if not check.get("ok"):
		_show_message("Покупка недоступна", str(check.get("reason")))
		return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Купить «%s» за %d монет?\nКатегория: %s\nЭффект: сытость +%d, настроение +%d" % [
		item.get("name"), item.get("price"),
		("обязательное" if item.get("category") == "mandatory" else "желаемое"),
		int(item.get("hunger", 0)), int(item.get("mood", 0))
	]
	add_child(confirm)
	confirm.confirmed.connect(func():
		var res := GameData.buy_item(item.get("id"))
		if not res.get("ok"):
			_show_message("Не получилось", str(res.get("reason")))
	)
	confirm.popup_centered()


func _show_message(title: String, text: String) -> void:
	var d := AcceptDialog.new()
	d.title = title
	d.dialog_text = text
	add_child(d)
	d.popup_centered()
