extends Control

signal finished

var step := 0
var body_box: VBoxContainer
var name_field: LineEdit
var chosen_color := 0
var chosen_pattern := 0
var color_buttons: Array = []
var pattern_buttons: Array = []

const COLOR_NAMES := ["Рыжий", "Серый", "Белый"]
const PATTERN_NAMES := ["Однотонный", "С пятнами", "Полосатый"]

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 14)
	add_child(vb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(margin)

	body_box = VBoxContainer.new()
	body_box.add_theme_constant_override("separation", 14)
	margin.add_child(body_box)

	_show_intro_step(0)


func _clear_body() -> void:
	for c in body_box.get_children():
		c.queue_free()


func _show_intro_step(i: int) -> void:
	_clear_body()
	var texts := [
		"Привет! Это игра про питомца Финни. Ты будешь заботиться о нём и учиться обращаться с монетками.",
		"Есть три типа решений: потратить на обязательное (еда, уход), потратить на желаемое (шапки, игрушки) или отложить в накопления.",
		"Обязательные расходы — это то, что нужно питомцу регулярно. Желаемые — не обязательны, их можно отложить. Накопления помогают достичь цели.",
	]
	var title := Label.new()
	title.text = "Знакомство (%d/3)" % (i + 1)
	title.add_theme_font_size_override("font_size", 24)
	body_box.add_child(title)

	var lbl := Label.new()
	lbl.text = texts[i]
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_box.add_child(lbl)

	var next_btn := Button.new()
	next_btn.custom_minimum_size = Vector2(0, 64)
	if i < texts.size() - 1:
		next_btn.text = "Дальше"
		next_btn.pressed.connect(func(): _show_intro_step(i + 1))
	else:
		next_btn.text = "Создать питомца"
		next_btn.pressed.connect(_show_creation_step)
	body_box.add_child(next_btn)


func _show_creation_step() -> void:
	_clear_body()
	var title := Label.new()
	title.text = "Создание питомца"
	title.add_theme_font_size_override("font_size", 24)
	body_box.add_child(title)

	var name_lbl := Label.new()
	name_lbl.text = "Придумай имя питомцу:"
	body_box.add_child(name_lbl)
	name_field = LineEdit.new()
	name_field.placeholder_text = "Финни"
	body_box.add_child(name_field)

	var color_lbl := Label.new()
	color_lbl.text = "Выбери цвет:"
	body_box.add_child(color_lbl)
	var color_row := HBoxContainer.new()
	body_box.add_child(color_row)
	color_buttons.clear()
	for idx in range(COLOR_NAMES.size()):
		var b := Button.new()
		b.text = COLOR_NAMES[idx]
		b.toggle_mode = true
		b.button_pressed = idx == chosen_color
		b.pressed.connect(func():
			chosen_color = idx
			for cb in color_buttons:
				cb.button_pressed = false
			b.button_pressed = true
		)
		color_row.add_child(b)
		color_buttons.append(b)

	var pattern_lbl := Label.new()
	pattern_lbl.text = "Выбери узор:"
	body_box.add_child(pattern_lbl)
	var pattern_row := HBoxContainer.new()
	body_box.add_child(pattern_row)
	pattern_buttons.clear()
	for idx in range(PATTERN_NAMES.size()):
		var pb := Button.new()
		pb.text = PATTERN_NAMES[idx]
		pb.toggle_mode = true
		pb.button_pressed = idx == chosen_pattern
		pb.pressed.connect(func():
			chosen_pattern = idx
			for cb in pattern_buttons:
				cb.button_pressed = false
			pb.button_pressed = true
		)
		pattern_row.add_child(pb)
		pattern_buttons.append(pb)

	var create_btn := Button.new()
	create_btn.text = "Готово!"
	create_btn.custom_minimum_size = Vector2(0, 64)
	create_btn.pressed.connect(func():
		GameData.create_pet(name_field.text, chosen_color, chosen_pattern)
		GameData.finish_intro()
		finished.emit()
	)
	body_box.add_child(create_btn)
