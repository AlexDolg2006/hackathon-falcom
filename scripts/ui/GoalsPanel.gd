extends Control

var current_goal_card: PanelContainer
var goals_list_box: VBoxContainer
var savings_label: Label


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
	title.text = "🎯 Накопления и цели"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	top_vb.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Выбирай мечту и копи монеты! Накопления пополняются автоматически из плана бюджета."
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(subtitle)

	# Общий счётчик накоплений (из второго файла)
	savings_label = Label.new()
	savings_label.add_theme_font_size_override("font_size", 19)
	savings_label.add_theme_color_override("font_color", Color(0.2, 0.45, 0.25))
	top_vb.add_child(savings_label)

	# --- Карточка активной цели ---
	current_goal_card = PanelContainer.new()
	vb.add_child(current_goal_card)

	# --- Заголовок списка ---
	var list_title := Label.new()
	list_title.text = "Все финансовые цели:"
	list_title.add_theme_font_size_override("font_size", 20)
	list_title.add_theme_color_override("font_color", Color(1, 1, 1))
	vb.add_child(list_title)

	goals_list_box = VBoxContainer.new()
	goals_list_box.add_theme_constant_override("separation", 10)
	goals_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(goals_list_box)


# ---------- ОБНОВЛЕНИЕ ----------

func _refresh() -> void:
	savings_label.text = "Всего в накоплениях: %d монет" % GameData.savings

	_refresh_current_goal_card()
	_refresh_goals_list()


func _refresh_current_goal_card() -> void:
	for c in current_goal_card.get_children():
		c.queue_free()

	var active_style := StyleBoxFlat.new()
	active_style.bg_color = Color(0.88, 0.92, 0.98)
	active_style.set_corner_radius_all(16)
	active_style.content_margin_left = 14
	active_style.content_margin_right = 14
	active_style.content_margin_top = 12
	active_style.content_margin_bottom = 12
	active_style.shadow_size = 2
	active_style.shadow_color = Color(0, 0, 0, 0.08)
	current_goal_card.add_theme_stylebox_override("panel", active_style)

	var active_vb := VBoxContainer.new()
	active_vb.add_theme_constant_override("separation", 6)
	current_goal_card.add_child(active_vb)

	var g: Dictionary = _get_goal_by_id(GameData.current_goal_id)
	if g.is_empty():
		var no_goal := Label.new()
		no_goal.text = "Цель ещё не выбрана. Выбери из списка ниже!"
		no_goal.add_theme_font_size_override("font_size", 18)
		no_goal.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		active_vb.add_child(no_goal)
		return

	var cost: int = g.get("cost", 1)
	var progress: int = min(GameData.savings, cost)
	var pct: float = minf(float(progress) / float(cost) * 100.0, 100.0)

	var head := Label.new()
	head.text = "Текущая цель: %s %s" % [g.get("icon", "🎯"), g.get("name")]
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	active_vb.add_child(head)

	var bar := ProgressBar.new()
	bar.max_value = cost
	bar.value = progress
	bar.custom_minimum_size = Vector2(0, 26)
	active_vb.add_child(bar)

	var stat := Label.new()
	stat.text = "Накоплено: %d из %d монет (%.1f%%)" % [progress, cost, pct]
	stat.add_theme_font_size_override("font_size", 18)
	stat.add_theme_color_override("font_color", Color(0.2, 0.45, 0.25))
	active_vb.add_child(stat)

	# Прогноз сроков достижения цели (из второго файла)
	active_vb.add_child(_build_estimate_label(g))

	# Кнопка «Снять часть накоплений» (из второго файла)
	var btn_row := HBoxContainer.new()
	active_vb.add_child(btn_row)

	var withdraw_btn := _create_pill_button(
		"Снять часть накоплений", Color(0.75, 0.45, 0.35), 46
	)
	withdraw_btn.disabled = GameData.savings <= 0
	withdraw_btn.custom_minimum_size = Vector2(240, 46)
	withdraw_btn.pressed.connect(_open_withdraw_dialog)
	btn_row.add_child(withdraw_btn)


func _build_estimate_label(g: Dictionary) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	if GameData.has_method("estimate_periods_to_goal"):
		var est = GameData.estimate_periods_to_goal(g.get("id"))
		if est == null:
			lbl.text = "Начни откладывать в план бюджета, чтобы увидеть срок достижения цели."
		elif est == 0:
			lbl.text = "Цель уже накоплена! 🎉"
		else:
			lbl.text = "Примерно ещё %d период(ов) при среднем темпе накоплений." % est
	else:
		lbl.text = ""
	return lbl


func _refresh_goals_list() -> void:
	for c in goals_list_box.get_children():
		c.queue_free()
	for item in _get_goals_catalog():
		goals_list_box.add_child(_build_goal_item(item))


# ---------- КАРТОЧКА ЦЕЛИ В СПИСКЕ ----------

func _build_goal_item(goal: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_current: bool = (goal.get("id") == GameData.current_goal_id)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.90, 0.94, 0.99) if is_current else Color(0.96, 0.96, 0.99)
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
	hb.add_theme_constant_override("separation", 10)
	margin.add_child(hb)

	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vb.add_theme_constant_override("separation", 2)
	hb.add_child(info_vb)

	# Заголовок с ★-меткой для текущей цели (из второго файла)
	var star := "  ★ текущая цель" if is_current else ""
	var title_lbl := Label.new()
	title_lbl.text = "%s %s — %d монет%s" % [
		goal.get("icon", "🎯"), goal.get("name"), goal.get("cost", 0), star
	]
	title_lbl.add_theme_font_size_override("font_size", 19)
	title_lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	info_vb.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(goal.get("desc", ""))
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vb.add_child(desc_lbl)

	# Прогресс-бар в каждой карточке (из второго файла, но в стиле первого)
	var cost: int = goal.get("cost", 0)
	if cost > 0:
		var bar := ProgressBar.new()
		bar.max_value = cost
		bar.value = min(GameData.savings, cost)
		bar.custom_minimum_size = Vector2(0, 20)
		info_vb.add_child(bar)

		var progress_lbl := Label.new()
		progress_lbl.text = "%d из %d монет" % [min(GameData.savings, cost), cost]
		progress_lbl.add_theme_font_size_override("font_size", 15)
		progress_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		info_vb.add_child(progress_lbl)

	# Кнопка выбора / метка «Выбрана»
	var select_btn := _create_pill_button(
		"Выбрана" if is_current else "Выбрать",
		Color(0.3, 0.65, 0.4) if is_current else Color(0.42, 0.35, 0.82),
		46
	)
	select_btn.disabled = is_current
	select_btn.custom_minimum_size = Vector2(120, 46)
	select_btn.pressed.connect(func(): _select_goal(goal.get("id")))
	hb.add_child(select_btn)

	return panel


# ---------- ДИАЛОГ СНЯТИЯ НАКОПЛЕНИЙ ----------

const UIUtils = preload("res://scripts/ui/UIUtils.gd")

func _open_withdraw_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Снять накопления"
	dialog.ok_button_text = "Снять"
	dialog.cancel_button_text = "Отмена"

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(380, 0)

	# Стилизованное пояснение в карточке
	var info_card := PanelContainer.new()
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.94, 0.94, 0.98)
	info_style.set_corner_radius_all(14)
	info_style.content_margin_left = 12
	info_style.content_margin_right = 12
	info_style.content_margin_top = 10
	info_style.content_margin_bottom = 10
	info_card.add_theme_stylebox_override("panel", info_style)
	vb.add_child(info_card)

	var lbl := Label.new()
	lbl.text = "Сколько монет снять с накоплений?\nСейчас: %d монет.\nСнятые монеты попадут в кошелёк." % GameData.savings
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.25, 0.25, 0.35))
	info_card.add_child(lbl)

	var spin_row := HBoxContainer.new()
	spin_row.add_theme_constant_override("separation", 10)
	vb.add_child(spin_row)

	var spin_lbl := Label.new()
	spin_lbl.text = "Сумма:"
	spin_lbl.add_theme_font_size_override("font_size", 17)
	spin_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
	spin_row.add_child(spin_lbl)

	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = GameData.savings
	spin.step = 1
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_row.add_child(spin)

	var preview := Label.new()
	preview.add_theme_font_size_override("font_size", 16)
	preview.add_theme_color_override("font_color", Color(0.2, 0.45, 0.25))
	preview.text = "После снятия останется: %d монет" % GameData.savings
	vb.add_child(preview)

	spin.value_changed.connect(func(v):
		preview.text = "После снятия останется: %d монет" % (GameData.savings - int(v))
	)

	dialog.add_child(vb)
	add_child(dialog)
	UIUtils.style_dialog(dialog, Color(0.75, 0.45, 0.35), Color(0.62, 0.58, 0.72))

	dialog.confirmed.connect(func():
		if GameData.has_method("withdraw_savings"):
			GameData.withdraw_savings(int(spin.value))
	)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

	dialog.popup_centered(Vector2i(460, 300))

# ---------- ХЕЛПЕРЫ ДОСТУПА К ДАННЫМ ----------

func _get_goals_catalog() -> Array:
	# Предпочитаем явный каталог из GameData, как во втором файле
	if GameData.get("goals_catalog") != null:
		return GameData.get("goals_catalog")
	if GameData.get("goals") != null:
		return GameData.get("goals")
	if GameData.get("goals_list") != null:
		return GameData.get("goals_list")
	if GameData.get("GOALS") != null:
		return GameData.get("GOALS")
	return []


func _get_goal_by_id(id) -> Dictionary:
	if GameData.has_method("get_goal"):
		return GameData.get_goal(id)
	for item in _get_goals_catalog():
		if item.get("id") == id:
			return item
	return {}


func _select_goal(id) -> void:
	# Предпочитаем инкапсулированный метод select_goal (из второго файла)
	if GameData.has_method("select_goal"):
		GameData.select_goal(id)
	else:
		# Резервный путь, как в первом файле
		GameData.current_goal_id = id
		if GameData.has_method("save_game"):
			GameData.save_game()
		GameData.state_changed.emit()


# ---------- СТИЛИЗОВАННАЯ КНОПКА ----------

func _create_pill_button(text: String, bg_color: Color, height: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(height / 2)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.content_margin_left = 16
	style.content_margin_right = 16

	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.12)

	var style_disabled := style.duplicate() as StyleBoxFlat
	style_disabled.bg_color = Color(0.7, 0.7, 0.75, 0.7)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)

	return btn
