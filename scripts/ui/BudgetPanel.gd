extends Control

const UIUtils = preload("res://scripts/ui/UIUtils.gd")

var wallet_label: Label
var mandatory_slider: HSlider
var optional_slider: HSlider
var savings_slider: HSlider
var mandatory_value: Label
var optional_value: Label
var savings_value: Label
var remaining_label: Label
var confirm_button: Button
var day_advance: Button
var status_box: VBoxContainer


func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	scroll.add_child(vb)

	# --- 1. Верхняя информационная карточка ---
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
	title.text = "📊 План бюджета на 5 дней"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	top_vb.add_child(title)

	wallet_label = Label.new()
	wallet_label.add_theme_font_size_override("font_size", 17)
	wallet_label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.35))
	wallet_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(wallet_label)

	status_box = VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 4)
	top_vb.add_child(status_box)

	# --- 2. Карточка со слайдерами ---
	var form_card := PanelContainer.new()
	var form_style := StyleBoxFlat.new()
	form_style.bg_color = Color(0.95, 0.95, 0.98)
	form_style.set_corner_radius_all(16)
	form_style.content_margin_left = 14
	form_style.content_margin_right = 14
	form_style.content_margin_top = 12
	form_style.content_margin_bottom = 12
	form_style.shadow_size = 2
	form_style.shadow_color = Color(0, 0, 0, 0.06)
	form_card.add_theme_stylebox_override("panel", form_style)
	vb.add_child(form_card)

	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	form_card.add_child(form)

	form.add_child(_row_title("🍎 Обязательное (еда, уход)"))
	mandatory_slider = _create_styled_slider()
	mandatory_slider.value = GameData.plan_pct_mandatory
	mandatory_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(mandatory_slider)
	mandatory_value = _create_val_label()
	form.add_child(mandatory_value)

	form.add_child(_row_title("🧸 Желаемое (шапки, игрушки)"))
	optional_slider = _create_styled_slider()
	optional_slider.value = GameData.plan_pct_optional
	optional_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(optional_slider)
	optional_value = _create_val_label()
	form.add_child(optional_value)

	form.add_child(_row_title("🎯 Накопления (+%d%% за период)" % int(GameData.SAVINGS_RATE * 100)))
	savings_slider = _create_styled_slider()
	savings_slider.value = GameData.plan_pct_savings
	savings_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(savings_slider)
	savings_value = _create_val_label()
	form.add_child(savings_value)

	remaining_label = Label.new()
	remaining_label.add_theme_font_size_override("font_size", 18)
	form.add_child(remaining_label)

	# --- 3. Кнопки действий ---
	confirm_button = _create_pill_button("Подтвердить план", Color(0.42, 0.35, 0.82), 60)
	confirm_button.pressed.connect(_on_confirm)
	vb.add_child(confirm_button)

	day_advance = _create_pill_button("Завершить день (+%d монет)" % GameData.DAILY_INCOME, Color(0.22, 0.65, 0.35), 60)
	day_advance.pressed.connect(_on_advance_day)
	vb.add_child(day_advance)


func _row_title(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.18, 0.18, 0.28))
	return l


func _create_val_label() -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.3, 0.3, 0.45))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


func _create_styled_slider() -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.custom_minimum_size = Vector2(0, 48)
	return slider


func _create_pill_button(text: String, bg_color: Color, height: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, height)
	UIUtils.style_pill_button(btn, bg_color, height, 20)
	return btn


func _refresh() -> void:
	for c in status_box.get_children():
		c.queue_free()

	if GameData.period_active:
		wallet_label.text = "Период %d, день %d из %d.\nТекущие проценты: обяз. %d%%, желаем. %d%%, накопл. %d%%." % [
			GameData.period_number, GameData.day_in_period, GameData.PERIOD_LENGTH,
			GameData.plan_pct_mandatory, GameData.plan_pct_optional, GameData.plan_pct_savings]
		var s1 := Label.new()
		s1.text = "Доступно: обязательное %d | желаемое %d | накопления %d | кошелёк %d" % [
			GameData.mandatory_budget, GameData.optional_budget, GameData.savings, GameData.wallet]
		s1.add_theme_font_size_override("font_size", 16)
		s1.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
		s1.autowrap_mode = TextServer.AUTOWRAP_WORD
		status_box.add_child(s1)

		var s2 := Label.new()
		s2.text = "Потрачено за период: обязательное %d | желаемое %d" % [GameData.fact_mandatory, GameData.fact_optional]
		s2.add_theme_font_size_override("font_size", 16)
		s2.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
		s2.autowrap_mode = TextServer.AUTOWRAP_WORD
		status_box.add_child(s2)

		mandatory_slider.editable = false
		optional_slider.editable = false
		savings_slider.editable = false
		confirm_button.disabled = true
		confirm_button.text = "План уже действует"
		day_advance.disabled = false
		day_advance.text = "Завершить текущий день (+%d монет)" % GameData.DAILY_INCOME
		mandatory_slider.value = GameData.plan_pct_mandatory
		optional_slider.value = GameData.plan_pct_optional
		savings_slider.value = GameData.plan_pct_savings
	else:
		if GameData.plan_required:
			wallet_label.text = "Период завершён! Составь новый план на следующие 5 дней.\nВ кошельке: %d монет." % GameData.wallet
		else:
			wallet_label.text = "В кошельке: %d монет.\nЗадай проценты распределения дохода. Сумма должна быть ровно 100%%." % GameData.wallet
		mandatory_slider.editable = true
		optional_slider.editable = true
		savings_slider.editable = true
		confirm_button.disabled = false
		confirm_button.text = "Подтвердить план"
		day_advance.disabled = true
		if GameData.plan_required:
			day_advance.text = "Сначала подтверди новый план"
		else:
			day_advance.text = "Завершить текущий день (+%d монет)" % GameData.DAILY_INCOME
	_update_values()


func _on_slider_changed() -> void:
	var m := int(mandatory_slider.value)
	var o := int(optional_slider.value)
	var s := int(savings_slider.value)
	var total := m + o + s
	if total > 100:
		var over := total - 100
		var new_s: int = max(0, s - over)
		savings_slider.value = new_s
		s = new_s
		total = m + o + s
		if total > 100:
			var over2 := total - 100
			optional_slider.value = max(0, o - over2)
	_update_values()


func _update_values() -> void:
	var m := int(mandatory_slider.value)
	var o := int(optional_slider.value)
	var s := int(savings_slider.value)
	mandatory_value.text = "%d%%" % m
	optional_value.text = "%d%%" % o
	savings_value.text = "%d%%" % s
	var total := m + o + s
	if total == 100:
		remaining_label.text = "Сумма: 100% — всё отлично!"
		remaining_label.add_theme_color_override("font_color", Color(0.1, 0.6, 0.25))
		if not GameData.period_active:
			confirm_button.disabled = false
	else:
		remaining_label.text = "Сумма: %d%% (нужно ровно 100)" % total
		remaining_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.2))
		if not GameData.period_active:
			confirm_button.disabled = true


func _on_confirm() -> void:
	var m := int(mandatory_slider.value)
	var o := int(optional_slider.value)
	var s := int(savings_slider.value)
	if m + o + s != 100:
		UIUtils.show_message(self, "Проверь проценты",
			"Сумма процентов должна быть ровно 100.")
		return
	if m == 0:
		UIUtils.show_message(self, "Подожди",
			"Обязательное направление стоит заполнить хотя бы немного — иначе не на что будет кормить котика.")
		return

	UIUtils.show_confirm(self, "Подтвердить план",
		"Обязательное: %d%%\nЖелаемое: %d%%\nНакопления: %d%%\n\nПлан нельзя менять до конца периода." % [m, o, s],
		func(): GameData.confirm_plan(m, o, s),
		"Подтвердить", "Отмена",
		UIUtils.SUCCESS)


func _on_advance_day() -> void:
	if not GameData.can_advance_day():
		UIUtils.show_message(self, "Сначала план",
			"Период завершён — подтверди новый план бюджета, чтобы продолжить.")
		return
	var summary := GameData.advance_day()
	if summary.is_empty():
		UIUtils.show_message(self, "День завершён",
			"Наступил новый день. Пришло %d монет — не забудь покормить и помыть котика!" % GameData.DAILY_INCOME)
	else:
		var txt := "Период %d завершён!\n\nПлан (за период): обяз. %d / желаем. %d / накопл. %d\nФакт: обяз. %d / желаем. %d\nПроцент на накопления: +%d монет\n" % [
			summary.get("period_number"), summary.get("plan_mandatory"), summary.get("plan_optional"), summary.get("plan_savings"),
			summary.get("fact_mandatory"), summary.get("fact_optional"), summary.get("interest")]
		if summary.get("grew"):
			txt += "\nКотик подрос! Новая стадия: %s" % GameData.stage_name()
		elif summary.get("good_period"):
			txt += "\nОтличный период! Котик доволен."
		else:
			txt += "\nВ следующий раз попробуй лучше обеспечить обязательное и настроение котика."
		txt += "\n\nТеперь составь новый план на вкладке «Бюджет»."
		UIUtils.show_message(self, "Итоги периода", txt)
