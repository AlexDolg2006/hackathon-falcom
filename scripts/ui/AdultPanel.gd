extends Control

const UIUtils = preload("res://scripts/ui/UIUtils.gd")

var pin_entered := false
var content_box: VBoxContainer


func _ready() -> void:
	_build_ui()


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

	# --- Верхняя карточка ---
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
	title.text = "🔒 Раздел для родителей"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	top_vb.add_child(title)

	var desc := Label.new()
	desc.text = "Здесь можно просмотреть отчёт об успехах ребёнка, выдать бонусные монеты или сбросить прогресс."
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(desc)

	content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 12)
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(content_box)

	if not pin_entered:
		_build_parent_check()
	else:
		_build_adult_settings()


func _build_parent_check() -> void:
	for c in content_box.get_children():
		c.queue_free()

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.98)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)
	content_box.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var num1 := randi_range(12, 25)
	var num2 := randi_range(11, 20)
	var correct_ans := num1 + num2

	var q_lbl := Label.new()
	q_lbl.text = "Решите пример для входа: %d + %d = ?" % [num1, num2]
	q_lbl.add_theme_font_size_override("font_size", 20)
	q_lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	vb.add_child(q_lbl)

	var ans_input := LineEdit.new()
	ans_input.placeholder_text = "Ответ"
	ans_input.custom_minimum_size = Vector2(0, 52)
	ans_input.add_theme_font_size_override("font_size", 20)
	ans_input.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	
	var in_style := StyleBoxFlat.new()
	in_style.bg_color = Color(0.88, 0.89, 0.95)
	in_style.set_corner_radius_all(14)
	in_style.content_margin_left = 12
	in_style.content_margin_right = 12
	ans_input.add_theme_stylebox_override("normal", in_style)
	vb.add_child(ans_input)

	var check_btn := _create_pill_button("Войти", Color(0.42, 0.35, 0.82), 54)
	check_btn.pressed.connect(func():
		if ans_input.text.strip_edges() == str(correct_ans):
			pin_entered = true
			_build_ui()
		else:
			ans_input.text = ""
			q_lbl.text = "Неверно! Попробуйте снова."
			q_lbl.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	)
	vb.add_child(check_btn)


func _build_adult_settings() -> void:
	for c in content_box.get_children():
		c.queue_free()

	# 1. Отчёт о прогрессе
	var report_card := PanelContainer.new()
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color(0.95, 0.95, 0.98)
	r_style.set_corner_radius_all(16)
	r_style.content_margin_left = 14
	r_style.content_margin_right = 14
	r_style.content_margin_top = 12
	r_style.content_margin_bottom = 12
	report_card.add_theme_stylebox_override("panel", r_style)
	content_box.add_child(report_card)

	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 6)
	report_card.add_child(r_vb)

	var r_title := Label.new()
	r_title.text = "📊 Успехи ребёнка:"
	r_title.add_theme_font_size_override("font_size", 20)
	r_title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	r_vb.add_child(r_title)

	var info_list := [
		"• Имя питомца: %s" % GameData.pet_name,
		"• Завершено периодов планирования: %d" % GameData.period_number,
		"• Монет сбережено в накоплениях: %d" % GameData.savings,
		"• Стадия развития питомца: %s" % GameData.stage_name()
	]

	for info in info_list:
		var l := Label.new()
		l.text = info
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", Color(0.25, 0.25, 0.35))
		r_vb.add_child(l)

	# 2. Выдать монеты
	var add_coins_btn := _create_pill_button("➕ Выдать бонусные монеты (+50)", Color(0.22, 0.65, 0.35), 56)
	add_coins_btn.pressed.connect(func():
		GameData.wallet += 50
		GameData.save_game()
		GameData.state_changed.emit()
		_build_adult_settings()
	)
	content_box.add_child(add_coins_btn)

	# 3. Заблокировать / выйти
	var lock_btn := _create_pill_button("🔒 Выйти из режима родителя", Color(0.42, 0.35, 0.82), 56)
	lock_btn.pressed.connect(func():
		pin_entered = false
		_build_ui()
	)
	content_box.add_child(lock_btn)

	# 4. Сброс прогресса с кратким кастомным диалогом
	var reset_btn := _create_pill_button("⚠️ Сбросить весь прогресс (Начало заново)", Color(0.82, 0.3, 0.3), 56)
	reset_btn.pressed.connect(func():
		UIUtils.show_confirm(
			self,
			"⚠️ Сброс игры",
			"Вы уверены, что хотите полностью сбросить весь прогресс и заново пройти первый запуск?",
			Callable(self, "_reset_all_progress"),
			"Сбросить",
			"Отмена",
			Color(0.82, 0.3, 0.3)
		)
	)
	content_box.add_child(reset_btn)

	# Полный сброс всех показателей
func _reset_all_progress() -> void:
	# Вызываем существующий метод сброса в синглтоне
	GameData.reset_profile()
	GameData.save_game()
	get_tree().reload_current_scene()


func _create_pill_button(text: String, bg_color: Color, height: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, height)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(height / 2)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.12)

	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.12)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)

	return btn
