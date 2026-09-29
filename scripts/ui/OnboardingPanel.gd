extends Control
## Экран первого запуска (Onboarding) в светлом дизайне с выбором узора и читаемым полем ввода.

signal finished

var current_step: int = 0

# Элементы интерфейса
var step_card: PanelContainer
var content_vb: VBoxContainer
var dots_hb: HBoxContainer
var back_button: Button
var next_button: Button

# Данные первого запуска
var name_input: LineEdit
var selected_color_index: int = 0
var pet_preview_canvas: Control


func _ready() -> void:
	_build_ui()
	_show_step(0)


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	# Главный светлый фон экрана
	var bg_panel := Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.92, 0.93, 0.97)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var main_vb := VBoxContainer.new()
	main_vb.add_theme_constant_override("separation", 14)
	margin.add_child(main_vb)

	# Индикатор шагов (точки)
	dots_hb = HBoxContainer.new()
	dots_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_hb.add_theme_constant_override("separation", 8)
	main_vb.add_child(dots_hb)

	# Центральная светлая карточка контента
	step_card = PanelContainer.new()
	step_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	step_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.96, 0.96, 0.99)
	card_style.set_corner_radius_all(20)
	card_style.content_margin_left = 18
	card_style.content_margin_right = 18
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	card_style.shadow_size = 3
	card_style.shadow_offset = Vector2(0, 3)
	card_style.shadow_color = Color(0, 0, 0, 0.08)
	step_card.add_theme_stylebox_override("panel", card_style)
	main_vb.add_child(step_card)

	content_vb = VBoxContainer.new()
	content_vb.add_theme_constant_override("separation", 10)
	content_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	step_card.add_child(content_vb)

	# Нижняя панель навигации по шагам
	var nav_hb := HBoxContainer.new()
	nav_hb.add_theme_constant_override("separation", 10)
	nav_hb.custom_minimum_size = Vector2(0, 60)
	main_vb.add_child(nav_hb)

	back_button = _create_pill_button("← Назад", Color(0.82, 0.83, 0.90), Color(0.2, 0.2, 0.3))
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_on_back_pressed)
	nav_hb.add_child(back_button)

	next_button = _create_pill_button("Далее →", Color(0.42, 0.35, 0.82), Color(1, 1, 1))
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(_on_next_pressed)
	nav_hb.add_child(next_button)


func _show_step(step_idx: int) -> void:
	current_step = step_idx
	_update_dots()

	for c in content_vb.get_children():
		c.queue_free()

	back_button.visible = (current_step > 0)

	match current_step:
		0: _build_step_welcome()
		1: _build_step_pet_creation()
		2: _build_step_rules()
		3: _build_step_ready()


# --- ШАГ 0: Приветствие ---
func _build_step_welcome() -> void:
	next_button.text = "Далее →"

	var title := _create_title("👋 Привет! Я — Финни")
	content_vb.add_child(title)

	var desc := _create_body("Добро пожаловать в игру! Вместе мы научимся копить деньги, правильно планировать покупки и ухаживать за твоим новым виртуальным питомцем.")
	content_vb.add_child(desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vb.add_child(spacer)

	var icon_lbl := Label.new()
	icon_lbl.text = "🐱 💰 📊"
	icon_lbl.add_theme_font_size_override("font_size", 84)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vb.add_child(icon_lbl)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vb.add_child(spacer2)


# --- ШАГ 1: Имя, цвет и узор питомца ---
# --- ШАГ 1: Имя и выбор скина питомца ---
func _build_step_pet_creation() -> void:
	next_button.text = "Далее →"

	var title := _create_title("🐾 Выбери питомца")
	content_vb.add_child(title)

	var label_name := _create_body("Как будут звать твоего котика?")
	content_vb.add_child(label_name)

	# Поле ввода имени[cite: 10]
	name_input = LineEdit.new()
	name_input.placeholder_text = "Введи имя (например, Финни)"
	name_input.text = GameData.pet_name if GameData.pet_name != "" else "Финни"
	name_input.custom_minimum_size = Vector2(0, 52)
	name_input.add_theme_font_size_override("font_size", 40)
	name_input.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	name_input.add_theme_color_override("placeholder_color", Color(0.5, 0.5, 0.6))

	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.88, 0.89, 0.95)
	input_style.set_corner_radius_all(16)
	input_style.content_margin_left = 14
	input_style.content_margin_right = 14
	name_input.add_theme_stylebox_override("normal", input_style)
	name_input.add_theme_stylebox_override("focus", input_style)
	content_vb.add_child(name_input)

	# Заголовок выбора внешности
	var label_skin := _create_body("Выбери внешность:")
	content_vb.add_child(label_skin)

	var skins_hb := HBoxContainer.new()
	skins_hb.add_theme_constant_override("separation", 12)
	skins_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vb.add_child(skins_hb)

	# Список ваших папок со скинами в res://assets/
	var skins_data := [
		{"name": "Рыжий кот", "folder": "cat_One"},
		{"name": "Серый кот", "folder": "cat_Two"},
		# При появлении новых скинов просто добавьте строку:
		# {"name": "Белый кот", "folder": "cat_Three"}
	]

	for s_info in skins_data:
		var folder_name: String = s_info.get("folder")
		var display_name: String = s_info.get("name")

		var btn := _create_pill_button(display_name, Color(0.82, 0.83, 0.90), Color(0.2, 0.2, 0.3))
		btn.custom_minimum_size = Vector2(200, 70)
		btn.add_theme_font_size_override("font_size", 28)

		btn.pressed.connect(func():
			GameData.selected_skin = folder_name
			if pet_preview_canvas and pet_preview_canvas.has_method("load_cat_skin"):
				pet_preview_canvas.load_cat_skin(folder_name)
			GameData.state_changed.emit()
		)
		skins_hb.add_child(btn)

	# Область превью питомца[cite: 10]
	var preview_wrap := PanelContainer.new()
	preview_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.88, 0.91, 0.97, 0.5)
	p_style.set_corner_radius_all(16)
	preview_wrap.add_theme_stylebox_override("panel", p_style)
	content_vb.add_child(preview_wrap)

	# Нода CatView для показа выбранного кота[cite: 4, 10]
	pet_preview_canvas = Control.new()
	pet_preview_canvas.set_script(load("res://scripts/ui/CatView.gd"))
	pet_preview_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pet_preview_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pet_preview_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_wrap.add_child(pet_preview_canvas)

	# Показываем текущий сохраненный скин[cite: 4]
	if pet_preview_canvas.has_method("load_cat_skin"):
		var current_skin = GameData.selected_skin if "selected_skin" in GameData else "cat_One"
		pet_preview_canvas.load_cat_skin(current_skin)

# --- ШАГ 2: Как устроена игра ---
func _build_step_rules() -> void:
	next_button.text = "Далее →"

	var title := _create_title("💡 Правила бюджета")
	content_vb.add_child(title)

	var rules_text := [
		"1. Каждые 5 дней ты составляешь план бюджета.",
		"2. Доход делится на 3 части: Обязательное (еда/уход), Желаемое (игрушки/шапки) и Накопления.",
		"3. Чем лучше ты заботишься о котике и соблюдаешь план, тем быстрее он растет!"
	]

	for r in rules_text:
		var item := _create_body(r)
		content_vb.add_child(item)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vb.add_child(spacer)


# --- ШАГ 3: Всё готово ---
func _build_step_ready() -> void:
	next_button.text = "🚀 Начать игру!"

	var title := _create_title("🎉 Всё готово!")
	content_vb.add_child(title)

	var desc := _create_body("Твой питомец с нетерпением ждёт встречи! Забирай первый ежедневный доход и составь свой первый бюджет.")
	content_vb.add_child(desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vb.add_child(spacer)

	var ready_lbl := Label.new()
	ready_lbl.text = "🏡"
	ready_lbl.add_theme_font_size_override("font_size", 128)
	ready_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vb.add_child(ready_lbl)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vb.add_child(spacer2)


# --- ОБРАБОТКА НАВИГАЦИИ ---
func _on_next_pressed() -> void:
	if current_step == 1:
		var input_text := name_input.text.strip_edges()
		if input_text != "":
			GameData.pet_name = input_text
		else:
			GameData.pet_name = "Финни"

	if current_step < 3:
		_show_step(current_step + 1)
	else:
		GameData.first_launch = false
		GameData.pet_created = true
		GameData.save_game()
		finished.emit()


func _on_back_pressed() -> void:
	if current_step > 0:
		_show_step(current_step - 1)


func _update_dots() -> void:
	for c in dots_hb.get_children():
		c.queue_free()

	for i in range(4):
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(14, 14) if i != current_step else Vector2(28, 14)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(7)
		if i == current_step:
			style.bg_color = Color(0.42, 0.35, 0.82)
		else:
			style.bg_color = Color(0.80, 0.82, 0.90)
		dot.add_theme_stylebox_override("panel", style)
		dots_hb.add_child(dot)


# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ СТИЛЕЙ ---
func _create_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 48)
	l.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	return l


func _create_body(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", Color(0.25, 0.25, 0.35))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	return l


func _create_pill_button(text: String, bg_color: Color, font_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 60)
	btn.add_theme_font_size_override("font_size", 42)
	btn.add_theme_color_override("font_color", font_color)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.set_corner_radius_all(30)
	style_normal.shadow_size = 2
	style_normal.shadow_offset = Vector2(0, 2)
	style_normal.shadow_color = Color(0, 0, 0, 0.12)

	var style_hover := style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.12)

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)

	return btn
