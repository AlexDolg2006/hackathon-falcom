extends Control

var stats_container: VBoxContainer


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
	title.text = "📈 Прогресс и справка"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	top_vb.add_child(title)

	var desc := Label.new()
	desc.text = "Статистика твоих успехов и полезные финансовые советы."
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(desc)

	# --- Карточка статистики ---
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 8)
	vb.add_child(stats_container)

	# --- Советы по финансовой грамотности ---
	var tips_title := Label.new()
	tips_title.text = "💡 Финансовая шпаргалка:"
	tips_title.add_theme_font_size_override("font_size", 20)
	tips_title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.32))
	vb.add_child(tips_title)

	var tips := [
		"🍎 Обязательные расходы — это еда и уход. Их нужно планировать в первую очередь!",
		"🧸 Желаемые покупки — это то, что хочется, но без чего можно обойтись.",
		"🎯 Накопления помогают покупать дорогие вещи в будущем."
	]

	for tip in tips:
		var tip_card := PanelContainer.new()
		var t_style := StyleBoxFlat.new()
		t_style.bg_color = Color(0.95, 0.95, 0.98)
		t_style.set_corner_radius_all(14)
		t_style.content_margin_left = 12
		t_style.content_margin_right = 12
		t_style.content_margin_top = 10
		t_style.content_margin_bottom = 10
		tip_card.add_theme_stylebox_override("panel", t_style)
		
		var l := Label.new()
		l.text = tip
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", Color(0.25, 0.25, 0.35))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		tip_card.add_child(l)
		vb.add_child(tip_card)


func _refresh() -> void:
	for c in stats_container.get_children():
		c.queue_free()

	var panel := PanelContainer.new()
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.90, 0.93, 0.98)
	p_style.set_corner_radius_all(16)
	p_style.content_margin_left = 14
	p_style.content_margin_right = 14
	p_style.content_margin_top = 12
	p_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", p_style)
	stats_container.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var items := [
		"🐾 Имя питомца: %s" % GameData.pet_name,
		"🌱 Стадия роста: %s" % GameData.stage_name(),
		"📅 Текущий период: %d" % GameData.period_number,
		"💰 Всего монет в кошельке: %d" % GameData.wallet,
		"🎯 Общие накопления: %d" % GameData.savings
	]

	for item_text in items:
		var l := Label.new()
		l.text = item_text
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
		vb.add_child(l)
