extends Control

const UIUtils = preload("res://scripts/ui/UIUtils.gd")

var tasks_container: VBoxContainer


func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


# ---------- ПОСТРОЕНИЕ UI ----------

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	scroll.add_child(vb)

	# --- Верхняя карточка-заголовок ---
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
	title.text = "📋 Финансовые задания"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(title)

	var desc := Label.new()
	desc.text = "Выполняй задания по управлению бюджетом и получай награды!"
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(desc)

	tasks_container = VBoxContainer.new()
	tasks_container.add_theme_constant_override("separation", 10)
	tasks_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(tasks_container)


# ---------- ОБНОВЛЕНИЕ ----------

func _refresh() -> void:
	for c in tasks_container.get_children():
		c.queue_free()

	var by_topic := _group_tasks_by_topic()
	for topic in by_topic.keys():
		tasks_container.add_child(_build_topic_header(by_topic[topic]))
		for t in by_topic[topic]:
			tasks_container.add_child(_build_task_card(t))


func _group_tasks_by_topic() -> Dictionary:
	var by_topic := {}
	for t in GameData.tasks:
		var topic = t.get("topic", "")
		if not by_topic.has(topic):
			by_topic[topic] = []
		by_topic[topic].append(t)
	return by_topic


func _build_topic_header(topic_tasks: Array) -> Control:
	var header := Label.new()
	if topic_tasks.size() > 0 and topic_tasks[0].get("topic_name") != null:
		header.text = str(topic_tasks[0].get("topic_name"))
	else:
		header.text = "Задания"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1, 1, 1))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD
	return header


# ---------- КАРТОЧКА ЗАДАНИЯ ----------

func _build_task_card(task: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Не задаем custom_minimum_size.y!

	var is_completed: bool = _is_task_completed(task)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.92, 0.96, 0.93) if is_completed else Color(0.95, 0.95, 0.98)
	card_style.set_corner_radius_all(16)
	
	# Отступы внутри карточки сами зададут нужную высоту в зависимости от объема текста:
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", card_style)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL # Позволяет контейнеру расти вниз
	info.add_theme_constant_override("separation", 4)
	hb.add_child(info)

	var title_lbl := Label.new()
	title_lbl.text = str(task.get("title", "")) + ("  ✓ выполнено" if is_completed else "")
	title_lbl.add_theme_font_size_override("font_size", 19)
	title_lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(task.get("desc", task.get("scenario", "")))
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD # Обязательно для переноса текста
	info.add_child(desc_lbl)

	var reward_lbl := Label.new()
	reward_lbl.text = "Награда: +%d монет 💰" % int(task.get("reward", 0))
	reward_lbl.add_theme_font_size_override("font_size", 16)
	reward_lbl.add_theme_color_override("font_color", Color(0.15, 0.55, 0.25))
	reward_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(reward_lbl)

	var open_btn := _create_pill_button(
		"Пройти ещё раз" if is_completed else "Открыть задание",
		Color(0.3, 0.65, 0.4) if is_completed else Color(0.42, 0.35, 0.82),
		46
	)
	open_btn.custom_minimum_size = Vector2(130, 46)
	open_btn.pressed.connect(func(): _open_task(task))
	hb.add_child(open_btn)

	return panel


func _is_task_completed(task: Dictionary) -> bool:
	if GameData.has_method("is_task_completed"):
		return GameData.is_task_completed(task.get("id"))
	return bool(task.get("completed", false))


func _complete_task(id) -> void:
	GameData.complete_task(id)
	GameData.state_changed.emit()


# ---------- ДИАЛОГ ЗАДАНИЯ ----------

func _open_task(t: Dictionary) -> void:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Карточка сценария
	var scen_card := PanelContainer.new()
	scen_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scen_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	var scen_style := StyleBoxFlat.new()
	scen_style.bg_color = Color(0.94, 0.94, 0.98)
	scen_style.set_corner_radius_all(14)
	# Отступы сами растолкают границы карточки под размер текста:
	scen_style.content_margin_left = 12
	scen_style.content_margin_right = 12
	scen_style.content_margin_top = 12
	scen_style.content_margin_bottom = 12
	scen_card.add_theme_stylebox_override("panel", scen_style)
	content.add_child(scen_card)

	var scenario := Label.new()
	scenario.text = str(t.get("scenario", ""))
	scenario.autowrap_mode = TextServer.AUTOWRAP_WORD
	scenario.add_theme_font_size_override("font_size", 16)
	scenario.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	scenario.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scen_card.add_child(scenario)

	# Карточка фидбэка (появляется после ответа)
	var fb_card := PanelContainer.new()
	fb_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fb_style := StyleBoxFlat.new()
	fb_style.bg_color = Color(0.92, 0.96, 0.93)
	fb_style.set_corner_radius_all(14)
	fb_style.content_margin_left = 12
	fb_style.content_margin_right = 12
	fb_style.content_margin_top = 10
	fb_style.content_margin_bottom = 10
	fb_card.add_theme_stylebox_override("panel", fb_style)
	fb_card.visible = false
	content.add_child(fb_card)

	var feedback_lbl := Label.new()
	feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	feedback_lbl.add_theme_font_size_override("font_size", 15)
	feedback_lbl.add_theme_color_override("font_color", Color(0.15, 0.45, 0.2))
	feedback_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fb_card.add_child(feedback_lbl)

	# Кнопки
	var buttons: Array = []
	var task_type: String = str(t.get("type", ""))

	if task_type == "choice":
		for opt in t.get("options", []):
			var text := str(opt.get("text", ""))
			buttons.append({
				"text": text,
				"color": UIUtils.ACCENT,
				"close": false,
				"on_press": func():
					fb_card.visible = true
					feedback_lbl.text = str(opt.get("feedback", ""))
					_complete_task(t.get("id"))
			})
		buttons.append({ "text": "Закрыть", "color": UIUtils.NEUTRAL })

	elif task_type == "input":
		var input_ctx := _build_input_fields(content, t)
		var fb_lbl_local := feedback_lbl
		var fb_card_local := fb_card

		buttons.append({
			"text": "Проверить",
			"color": UIUtils.ACCENT,
			"close": false,
			"on_press": func():
				_validate_input(t, input_ctx, fb_card_local, fb_lbl_local)
		})
		buttons.append({ "text": "Закрыть", "color": UIUtils.NEUTRAL })

	else:
		buttons.append({
			"text": "Забрать",
			"color": UIUtils.SUCCESS,
			"close": false,
			"on_press": func():
				fb_card.visible = true
				feedback_lbl.text = "Задание засчитано! +%d монет 💰" % int(t.get("reward", 0))
				_complete_task(t.get("id"))
		})
		buttons.append({ "text": "Закрыть", "color": UIUtils.NEUTRAL })

	UIUtils.show_custom(self, str(t.get("title", "Задание")), content, buttons)


func _build_input_fields(content: VBoxContainer, t: Dictionary) -> Dictionary:
	var total_hint: int = int(t.get("total_hint", 60))
	var min_mandatory: int = int(t.get("min_mandatory", 20))

	var hint := Label.new()
	hint.text = "Всего монет: %d (обязательное — не менее %d)" % [total_hint, min_mandatory]
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(hint)

	var mand_spin := SpinBox.new()
	mand_spin.min_value = 0
	mand_spin.max_value = total_hint
	mand_spin.value = min_mandatory
	content.add_child(_labeled(mand_spin, "Обязательное"))

	var opt_spin := SpinBox.new()
	opt_spin.min_value = 0
	opt_spin.max_value = total_hint
	content.add_child(_labeled(opt_spin, "Желаемое"))

	var sav_spin := SpinBox.new()
	sav_spin.min_value = 0
	sav_spin.max_value = total_hint
	content.add_child(_labeled(sav_spin, "Накопления"))

	return {
		"mand": mand_spin,
		"opt": opt_spin,
		"sav": sav_spin,
		"total_hint": total_hint,
		"min_mandatory": min_mandatory,
	}


func _validate_input(t: Dictionary, ctx: Dictionary,
		fb_card: PanelContainer, feedback_lbl: Label) -> void:
	var mand_spin: SpinBox = ctx["mand"]
	var opt_spin: SpinBox = ctx["opt"]
	var sav_spin: SpinBox = ctx["sav"]
	var total_hint: int = ctx["total_hint"]
	var min_mandatory: int = ctx["min_mandatory"]

	fb_card.visible = true
	var total := int(mand_spin.value + opt_spin.value + sav_spin.value)

	if total > total_hint:
		feedback_lbl.add_theme_color_override("font_color", Color(0.7, 0.25, 0.25))
		feedback_lbl.text = "Сумма превышает доступные монеты. Попробуй ещё раз."
	elif int(mand_spin.value) < min_mandatory:
		feedback_lbl.add_theme_color_override("font_color", Color(0.75, 0.5, 0.1))
		feedback_lbl.text = "На обязательное отложено меньше %d монет — может не хватить на еду. %s" % [
			min_mandatory, str(t.get("explanation", ""))
		]
	else:
		feedback_lbl.add_theme_color_override("font_color", Color(0.15, 0.45, 0.2))
		feedback_lbl.text = "Отлично! План устойчивый. %s" % str(t.get("explanation", ""))
		_complete_task(t.get("id"))
		mand_spin.editable = false
		opt_spin.editable = false
		sav_spin.editable = false


func _labeled(control: Control, label_text: String) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	control.custom_minimum_size.y = 40
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	vb.add_child(l)
	vb.add_child(control)
	return vb


# ---------- СТИЛИЗОВАННАЯ КНОПКА ----------

func _create_pill_button(text: String, bg_color: Color, height: int) -> Button:
	var btn := Button.new()
	btn.text = text
	UIUtils.style_pill_button(btn, bg_color, height, 16)
	return btn
