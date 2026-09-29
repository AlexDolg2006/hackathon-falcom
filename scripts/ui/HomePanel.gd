extends Control

signal go_to_shop
signal go_to_minigame
signal go_to_budget
signal go_to_wash

var mood_bar: ProgressBar
var hunger_bar: ProgressBar
var hygiene_bar: ProgressBar
var name_label: Label
var stage_label: Label
var goal_label: Label
var claim_button: Button
var feedback_label: Label
var period_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	GameData.state_changed.connect(_refresh)
	GameData.toast.connect(_show_toast)
	_refresh()


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var root_vb := VBoxContainer.new()
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.add_theme_constant_override("separation", 6)
	root_vb.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root_vb)

	# --- 1. ВЕРХНЯЯ СВЕТЛАЯ ИНФОРМАЦИОННАЯ КАРТОЧКА ---
	var top_card := PanelContainer.new()
	top_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.94, 0.94, 0.98) # Светлый фон
	top_style.set_corner_radius_all(14)
	top_style.content_margin_left = 12
	top_style.content_margin_right = 12
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_style.shadow_size = 2
	top_style.shadow_color = Color(0, 0, 0, 0.08)
	top_card.add_theme_stylebox_override("panel", top_style)
	root_vb.add_child(top_card)

	var top_vb := VBoxContainer.new()
	top_vb.add_theme_constant_override("separation", 4)
	top_card.add_child(top_vb)

	var name_hb := HBoxContainer.new()
	top_vb.add_child(name_hb)

	name_label = Label.new()
	name_label.text = "Питомец: "
	name_label.add_theme_font_size_override("font_size", 22) # +4 pt
	name_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.22))
	name_hb.add_child(name_label)

	stage_label = Label.new()
	stage_label.add_theme_font_size_override("font_size", 19) # +4 pt
	stage_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.5))
	stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_hb.add_child(stage_label)

	# Шкалы
	var stats_hb := HBoxContainer.new()
	stats_hb.add_theme_constant_override("separation", 8)
	top_vb.add_child(stats_hb)

	mood_bar = ProgressBar.new()
	stats_hb.add_child(_create_mini_stat("😊", mood_bar))

	hunger_bar = ProgressBar.new()
	stats_hb.add_child(_create_mini_stat("🍖", hunger_bar))

	hygiene_bar = ProgressBar.new()
	stats_hb.add_child(_create_mini_stat("🧼", hygiene_bar))

	goal_label = Label.new()
	goal_label.add_theme_font_size_override("font_size", 18) # +4 pt
	goal_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.28))
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(goal_label)

	period_label = Label.new()
	period_label.add_theme_font_size_override("font_size", 17) # +4 pt
	period_label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.32))
	period_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(period_label)

	feedback_label = Label.new()
	feedback_label.add_theme_font_size_override("font_size", 18) # +4 pt
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	feedback_label.modulate = Color(0.1, 0.65, 0.25)
	top_vb.add_child(feedback_label)

	# --- 2. ЦЕНТРАЛЬНАЯ ОБЛАСТЬ ПИТОМЦА ---
	var pet_card := PanelContainer.new()
	pet_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pet_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pet_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pet_card_style := StyleBoxFlat.new()
	pet_card_style.bg_color = Color(0.88, 0.91, 0.97, 0.8) # Мягкий нежно-голубой фон для котика
	pet_card_style.set_corner_radius_all(20)
	pet_card.add_theme_stylebox_override("panel", pet_card_style)
	root_vb.add_child(pet_card)

	var cat_view := Control.new()
	cat_view.set_script(load("res://scripts/ui/CatView.gd"))
	cat_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cat_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pet_card.add_child(cat_view)

	# --- 3. КНОПКИ БЫСТРЫХ ДЕЙСТВИЙ ВНИЗУ ---
	var actions_hb := HBoxContainer.new()
	actions_hb.add_theme_constant_override("separation", 8)
	actions_hb.custom_minimum_size = Vector2(0, 60)
	root_vb.add_child(actions_hb)

	claim_button = _create_rounded_button("💰 Доход дня (+%d)" % GameData.DAILY_INCOME, Color(0.22, 0.68, 0.38))
	claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_button.pressed.connect(func(): GameData.claim_daily_income())
	actions_hb.add_child(claim_button)

	var wash_btn := _create_rounded_button("🧼 Искупать", Color(0.22, 0.60, 0.82))
	wash_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wash_btn.pressed.connect(func(): go_to_wash.emit())
	actions_hb.add_child(wash_btn)


func _create_mini_stat(icon: String, bar: ProgressBar) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var l := Label.new()
	l.text = icon
	l.add_theme_font_size_override("font_size", 23) # +4 pt
	hb.add_child(l)

	bar.max_value = 100
	bar.add_theme_color_override("font_color", Color(0.2, 0.2, 0.28))
	bar.custom_minimum_size = Vector2(0, 22)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(bar)
	return hb


func _create_rounded_button(text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 60)
	btn.add_theme_font_size_override("font_size", 20) # +4 pt
	btn.add_theme_color_override("font_color", Color(1, 1, 1))

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.set_corner_radius_all(30)
	style_normal.shadow_size = 2
	style_normal.shadow_offset = Vector2(0, 2)
	style_normal.shadow_color = Color(0, 0, 0, 0.18)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed := style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = bg_color.darkened(0.18)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	var style_disabled := style_normal.duplicate() as StyleBoxFlat
	style_disabled.bg_color = Color(0.7, 0.7, 0.75, 0.7)
	btn.add_theme_stylebox_override("disabled", style_disabled)

	return btn


func _refresh() -> void:
	name_label.text = GameData.pet_name
	stage_label.text = GameData.stage_name()
	mood_bar.value = GameData.mood
	hunger_bar.value = GameData.hunger
	hygiene_bar.value = GameData.hygiene

	var g := GameData.get_goal(GameData.current_goal_id)
	if not g.is_empty():
		goal_label.text = "🎯 Цель: %s (%d / %d монет)" % [g.get("name"), min(GameData.savings, g.get("cost")), g.get("cost")]
	else:
		goal_label.text = "🎯 Цель не выбрана."

	if GameData.period_active:
		period_label.text = "📅 Период %d (день %d/%d). Кошелек: обяз. %d, желаем. %d." % [
			GameData.period_number, GameData.day_in_period, GameData.PERIOD_LENGTH,
			GameData.mandatory_budget, GameData.optional_budget]
	elif GameData.plan_required:
		period_label.text = "⚠ Период завершен — составь новый план в «📊 Бюджет»."
	else:
		period_label.text = "💡 Составь план бюджета на %d монет в «📊 Бюджет»." % GameData.wallet

	claim_button.disabled = not GameData.can_claim_daily_income()
	claim_button.text = "Доход получен" if claim_button.disabled else "💰 Доход дня (+%d)" % GameData.DAILY_INCOME


func _show_toast(message: String) -> void:
	feedback_label.text = message
