extends Control

var wallet_label: Label
var mandatory_slider: HSlider
var optional_slider: HSlider
var savings_slider: HSlider
var mandatory_value: Label
var optional_value: Label
var savings_value: Label
var remaining_label: Label
var confirm_button: Button
var status_box: VBoxContainer

func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	var title := Label.new()
	title.text = "План бюджета на 5 игровых дней"
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)

	wallet_label = Label.new()
	wallet_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(wallet_label)

	status_box = VBoxContainer.new()
	vb.add_child(status_box)

	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 6)
	vb.add_child(form)

	# Обязательное
	form.add_child(_row_title("Обязательное — %% от дохода (еда, мыло)"))
	mandatory_slider = HSlider.new()
	mandatory_slider.min_value = 0
	mandatory_slider.max_value = 100
	mandatory_slider.step = 1
	mandatory_slider.value = GameData.plan_pct_mandatory
	mandatory_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(mandatory_slider)
	mandatory_value = Label.new()
	form.add_child(mandatory_value)

	# Желаемое
	form.add_child(_row_title("Желаемое — %% от дохода (шапки, игрушки)"))
	optional_slider = HSlider.new()
	optional_slider.min_value = 0
	optional_slider.max_value = 100
	optional_slider.step = 1
	optional_slider.value = GameData.plan_pct_optional
	optional_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(optional_slider)
	optional_value = Label.new()
	form.add_child(optional_value)

	# Накопления
	form.add_child(_row_title("Накопления — %% от дохода (процент %d%% за период)" % int(GameData.SAVINGS_RATE * 100)))
	savings_slider = HSlider.new()
	savings_slider.min_value = 0
	savings_slider.max_value = 100
	savings_slider.step = 1
	savings_slider.value = GameData.plan_pct_savings
	savings_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(savings_slider)
	savings_value = Label.new()
	form.add_child(savings_value)

	remaining_label = Label.new()
	remaining_label.add_theme_font_size_override("font_size", 18)
	vb.add_child(remaining_label)

	confirm_button = Button.new()
	confirm_button.text = "Подтвердить план"
	confirm_button.custom_minimum_size = Vector2(0, 64)
	confirm_button.pressed.connect(_on_confirm)
	vb.add_child(confirm_button)

	var day_advance := Button.new()
	day_advance.text = "Завершить текущий день (+%d монет)" % GameData.DAILY_INCOME
	day_advance.custom_minimum_size = Vector2(0, 56)
	day_advance.pressed.connect(_on_advance_day)
	vb.add_child(day_advance)


func _row_title(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _refresh() -> void:
	for c in status_box.get_children():
		c.queue_free()

	if GameData.period_active:
		wallet_label.text = "Период %d, день %d из %d.\nТекущие проценты: обяз. %d%%, желаем. %d%%, накопл. %d%%." % [
			GameData.period_number, GameData.day_in_period, GameData.PERIOD_LENGTH,
			GameData.plan_pct_mandatory, GameData.plan_pct_optional, GameData.plan_pct_savings]
		var s1 := Label.new()
		s1.text = "Кошельки: обязательное %d | желаемое %d | накопления %d | кошелёк %d" % [
			GameData.mandatory_budget, GameData.optional_budget, GameData.savings, GameData.wallet]
		s1.autowrap_mode = TextServer.AUTOWRAP_WORD
		status_box.add_child(s1)
		var s2 := Label.new()
		s2.text = "Потрачено по факту: обязательное %d | желаемое %d" % [GameData.fact_mandatory, GameData.fact_optional]
		status_box.add_child(s2)
		mandatory_slider.editable = false
		optional_slider.editable = false
		savings_slider.editable = false
		confirm_button.disabled = true
		confirm_button.text = "План уже действует"
		mandatory_slider.value = GameData.plan_pct_mandatory
		optional_slider.value = GameData.plan_pct_optional
		savings_slider.value = GameData.plan_pct_savings
	else:
		wallet_label.text = "В кошельке: %d монет.\nЗадай проценты, по которым доход будет делиться между тремя направлениями. Сумма должна быть ровно 100%%." % GameData.wallet
		mandatory_slider.editable = true
		optional_slider.editable = true
		savings_slider.editable = true
		confirm_button.disabled = false
		confirm_button.text = "Подтвердить план"
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
	mandatory_value.text = "%d %%" % m
	optional_value.text = "%d %%" % o
	savings_value.text = "%d %%" % s
	var total := m + o + s
	if total == 100:
		remaining_label.text = "Сумма: 100 %% — можно подтверждать."
		if not GameData.period_active:
			confirm_button.disabled = false
	else:
		remaining_label.text = "Сумма: %d %% (нужно ровно 100)" % total
		if not GameData.period_active:
			confirm_button.disabled = true


func _on_confirm() -> void:
	var m := int(mandatory_slider.value)
	var o := int(optional_slider.value)
	var s := int(savings_slider.value)
	if m + o + s != 100:
		_show_message("Проверь проценты", "Сумма процентов должна быть ровно 100.")
		return
	if m == 0:
		_show_message("Подожди", "Обязательное направление стоит заполнить хотя бы немного — иначе не на что будет кормить котика.")
		return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Подтвердить план?\nОбязательное: %d %%\nЖелаемое: %d %%\nНакопления: %d %%\nПлан нельзя менять до конца периода." % [m, o, s]
	add_child(confirm)
	confirm.confirmed.connect(func():
		GameData.confirm_plan(m, o, s)
	)
	confirm.popup_centered()


func _on_advance_day() -> void:
	var summary := GameData.advance_day()
	if summary.is_empty():
		_show_message("День завершён", "Наступил новый день. Пришло %d монет — не забудь покормить и помыть котика!" % GameData.DAILY_INCOME)
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
		_show_message("Итоги периода", txt)


func _show_message(title: String, text: String) -> void:
	var d := AcceptDialog.new()
	d.title = title
	d.dialog_text = text
	add_child(d)
	d.popup_centered()
