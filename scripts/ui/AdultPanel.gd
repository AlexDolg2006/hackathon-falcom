extends Control

var gate_box: VBoxContainer
var content_box: VBoxContainer
var answer_field: LineEdit
var a: int
var b: int
var gate_status: Label

func _ready() -> void:
	_build_ui()
	_new_gate()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)

	var title := Label.new()
	title.text = "Раздел для взрослого"
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)

	gate_box = VBoxContainer.new()
	vb.add_child(gate_box)

	content_box = VBoxContainer.new()
	content_box.visible = false
	content_box.add_theme_constant_override("separation", 10)
	vb.add_child(content_box)


func _new_gate() -> void:
	for c in gate_box.get_children():
		c.queue_free()
	a = randi_range(3, 9)
	b = randi_range(2, 8)
	var lbl := Label.new()
	lbl.text = "Это раздел для взрослых. Чтобы продолжить, реши пример: %d + %d = ?" % [a, b]
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	gate_box.add_child(lbl)
	answer_field = LineEdit.new()
	answer_field.placeholder_text = "Ответ"
	gate_box.add_child(answer_field)
	var submit := Button.new()
	submit.text = "Войти"
	submit.pressed.connect(_check_answer)
	gate_box.add_child(submit)
	gate_status = Label.new()
	gate_box.add_child(gate_status)


func _check_answer() -> void:
	if answer_field.text.strip_edges() == str(a + b):
		gate_box.visible = false
		content_box.visible = true
		_build_content()
	else:
		gate_status.text = "Неверно, попробуй ещё раз."
		_new_gate()


func _build_content() -> void:
	for c in content_box.get_children():
		c.queue_free()

	var summary := Label.new()
	summary.text = "Питомец: %s (%s)\nПериодов пройдено: %d\nЗаданий выполнено: %d из %d\nНакоплено: %d монет" % [
		GameData.pet_name, GameData.stage_name(), GameData.history.size(),
		GameData.completed_tasks.size(), GameData.tasks.size(), GameData.savings]
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_box.add_child(summary)

	var demo_btn := Button.new()
	demo_btn.text = "Демонстрационный режим: сбросить к тестовому профилю"
	demo_btn.pressed.connect(func():
		var confirm := ConfirmationDialog.new()
		confirm.dialog_text = "Сбросить прогресс и подготовить тестовый профиль для демонстрации обязательного сценария?"
		add_child(confirm)
		confirm.confirmed.connect(func(): GameData.reset_profile(true))
		confirm.popup_centered()
	)
	content_box.add_child(demo_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Удалить локальный профиль"
	reset_btn.pressed.connect(func():
		var confirm := ConfirmationDialog.new()
		confirm.dialog_text = "Точно удалить весь прогресс без возможности отмены?"
		add_child(confirm)
		confirm.confirmed.connect(func(): GameData.reset_profile(false))
		confirm.popup_centered()
	)
	content_box.add_child(reset_btn)

	var back_btn := Button.new()
	back_btn.text = "Выйти из раздела для взрослого"
	back_btn.pressed.connect(func():
		content_box.visible = false
		gate_box.visible = true
		_new_gate()
	)
	content_box.add_child(back_btn)
