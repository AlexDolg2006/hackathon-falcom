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

	form.add_child(_row_title("Обязательное (еда, мыло)"))
	mandatory_slider = HSlider.new()
	mandatory_slider.min_value = 0
	mandatory_slider.step = 1
	mandatory_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(mandatory_slider)
	mandatory_value = Label.new()
	form.add_child(mandatory_value)

	form.add_child(_row_title("Желаемое (шапки, игрушки)"))
	optional_slider = HSlider.new()
	optional_slider.min_value = 0
	optional_slider.step = 1
	optional_slider.value_changed.connect(func(_v): _on_slider_changed())
	form.add_child(optional_slider)
	optional_value = Label.new()
	form.add_child(optional_value)

	form.add_child(_row_title("Накопления (доход %d%% за период)" % int(GameData.SAVINGS_RATE * 100)))
	savings_slider = HSlider.new()
	savings_slider.min_value = 0
	savings_slider.step = 1
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
	day_advance.text = "Завершить текущий день"
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
		wallet_label.text = "Период %d, день %d из %d уже идёт.\nВ кошельке для нового плана: %d монет." % [
			GameData.period_number, GameData.day_in_period, GameData.PERIOD_LENGTH, GameData.wallet]
		var s := Label.new()
		s.text = "Текущий план: обязательное %d | желаемое %d | накопления %d" % [GameData.plan_mandatory, GameData.plan_optional, GameData.plan_savings]
		status_box.add_child(s)
		var s2 := Label.new()
		s2.text = "Потрачено по факту: обязательное %d | желаемое %d" % [GameData.fact_mandatory, GameData.fact_optional]
		status_box.add_child(s2)
		mandatory_slider.editable = false
		optional_slider.editable = false
		savings_slider.editable = false
		confirm_button.disabled = true
		confirm_button.text = "План уже действует"
	else:
		wallet_label.text = "Доступно для распределения: %d монет.\nРаспредели их по трём направлениям на ближайшие 5 дней." % GameData.wallet
		mandatory_slider.max_value = GameData.wallet
		optional_slider.max_value = GameData.wallet
		savings_slider.max_value = GameData.wallet
		mandatory_slider.editable = true
		optional_slider.editable = true
		savings_slider.editable = true
		confirm_button.disabled = false
		confirm_button.text = "Подтвердить план"
		if mandatory_slider.value == 0 and optional_slider.value == 0 and savings_slider.value == 0 and GameData.wallet > 0:
			mandatory_slider.value = int(GameData.wallet * 0.5)
	_update_values()


func _on_slider_changed() -> void:
	var total := mandatory_slider.value + optional_slider.value + savings_slider.value
	if total > GameData.wallet:
		# сжимаем последний изменённый — просто ограничим желаемое и накопления
		var over := total - GameData.wallet
		savings_slider.value = max(0, savings_slider.value - over)
		total = mandatory_slider.value + optional_slider.value + savings_slider.value
		if total > GameData.wallet:
			var over2 := total - GameData.wallet
			optional_slider.value = max(0, optional_slider.value - over2)
	_update_values()


func _update_values() -> void:
	mandatory_value.text = "%d монет" % int(mandatory_slider.value)
	optional_value.text = "%d монет" % int(optional_slider.value)
	savings_value.text = "%d монет" % int(savings_slider.value)
	var total := int(mandatory_slider.value + optional_slider.value + savings_slider.value)
	var remaining := GameData.wallet - total
	remaining_label.text = "Остаток нераспределённых монет: %d" % remaining


func _on_confirm() -> void:
	var m := int(mandatory_slider.value)
	var o := int(optional_slider.value)
	var s := int(savings_slider.value)
	if m == 0 and o == 0:
		_show_message("Подожди", "Обязательное направление стоит заполнить хотя бы немного — иначе не на что будет кормить котика.")
		return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Подтвердить план на 5 дней?\nОбязательное: %d\nЖелаемое: %d\nНакопления: %d\nПосле подтверждения план нельзя будет изменить до конца периода." % [m, o, s]
	add_child(confirm)
	confirm.confirmed.connect(func():
		var ok := GameData.confirm_plan(m, o, s)
		if ok:
			mandatory_slider.value = 0
			optional_slider.value = 0
			savings_slider.value = 0
	)
	confirm.popup_centered()


func _on_advance_day() -> void:
	var summary := GameData.advance_day()
	if summary.is_empty():
		_show_message("День завершён", "Наступил новый день. Не забудь покормить и помыть котика!")
	else:
		var txt := "Период %d завершён!\n\nПлан: обяз. %d / желаем. %d / накопл. %d\nФакт: обяз. %d / желаем. %d\nПроцент на накопления: +%d монет\n" % [
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
