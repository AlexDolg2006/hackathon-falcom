extends Control

var list_box: VBoxContainer

func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vb)

	var title := Label.new()
	title.text = "Финансовые задания"
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 12)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)


func _refresh() -> void:
	for c in list_box.get_children():
		c.queue_free()
	var by_topic := {}
	for t in GameData.tasks:
		var topic = t.get("topic")
		if not by_topic.has(topic):
			by_topic[topic] = []
		by_topic[topic].append(t)
	for topic in by_topic.keys():
		var header := Label.new()
		header.text = str(by_topic[topic][0].get("topic_name"))
		header.add_theme_font_size_override("font_size", 20)
		list_box.add_child(header)
		for t in by_topic[topic]:
			list_box.add_child(_build_task_row(t))


func _build_task_row(t: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var vb := VBoxContainer.new()
	panel.add_child(vb)

	var done: bool = GameData.is_task_completed(t.get("id"))
	var title_lbl := Label.new()
	title_lbl.text = "%s%s" % [t.get("title"), "  ✓ выполнено" if done else ""]
	title_lbl.add_theme_font_size_override("font_size", 18)
	vb.add_child(title_lbl)

	var open_btn := Button.new()
	open_btn.text = "Пройти ещё раз" if done else "Открыть задание"
	open_btn.pressed.connect(func(): _open_task(t))
	vb.add_child(open_btn)

	return panel


func _open_task(t: Dictionary) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = t.get("title")
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(460, 0)
	var scenario := Label.new()
	scenario.text = str(t.get("scenario"))
	scenario.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(scenario)

	var feedback_lbl := Label.new()
	feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	feedback_lbl.visible = false
	vb.add_child(feedback_lbl)

	if t.get("type") == "choice":
		for opt in t.get("options", []):
			var btn := Button.new()
			btn.text = str(opt.get("text"))
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD
			vb.add_child(btn)
			btn.pressed.connect(func():
				feedback_lbl.visible = true
				feedback_lbl.text = str(opt.get("feedback"))
				GameData.complete_task(t.get("id"))
				for c in vb.get_children():
					if c is Button:
						c.disabled = true
			)
	elif t.get("type") == "input":
		var hint := Label.new()
		hint.text = "Всего монет для распределения: %d (обязательное — не менее %d)" % [int(t.get("total_hint", 60)), int(t.get("min_mandatory", 20))]
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(hint)
		var mand_spin := SpinBox.new()
		mand_spin.min_value = 0
		mand_spin.max_value = t.get("total_hint", 60)
		mand_spin.value = t.get("min_mandatory", 20)
		vb.add_child(_labeled(mand_spin, "Обязательное"))
		var opt_spin := SpinBox.new()
		opt_spin.min_value = 0
		opt_spin.max_value = t.get("total_hint", 60)
		vb.add_child(_labeled(opt_spin, "Желаемое"))
		var sav_spin := SpinBox.new()
		sav_spin.min_value = 0
		sav_spin.max_value = t.get("total_hint", 60)
		vb.add_child(_labeled(sav_spin, "Накопления"))
		var submit := Button.new()
		submit.text = "Проверить"
		vb.add_child(submit)
		submit.pressed.connect(func():
			feedback_lbl.visible = true
			var total := int(mand_spin.value + opt_spin.value + sav_spin.value)
			var min_m := int(t.get("min_mandatory", 20))
			if total > int(t.get("total_hint", 60)):
				feedback_lbl.text = "Сумма превышает доступные монеты. Попробуй ещё раз."
			elif mand_spin.value < min_m:
				feedback_lbl.text = "На обязательное отложено меньше %d монет — может не хватить на еду. %s" % [min_m, str(t.get("explanation"))]
			else:
				feedback_lbl.text = "Отлично! План устойчивый. %s" % str(t.get("explanation"))
				GameData.complete_task(t.get("id"))
				submit.disabled = true
		)

	dialog.add_child(vb)
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 420))


func _labeled(control: Control, label_text: String) -> Control:
	var hb := HBoxContainer.new()
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(120, 0)
	hb.add_child(l)
	hb.add_child(control)
	return hb
