extends RefCounted
class_name UIUtils

const BG      := Color(0.96, 0.96, 0.99)
const TEXT    := Color(0.15, 0.15, 0.25)
const SUBTLE  := Color(0.30, 0.30, 0.42)
const ACCENT  := Color(0.42, 0.35, 0.82)
const SUCCESS := Color(0.22, 0.65, 0.35)
const DANGER  := Color(0.75, 0.45, 0.35)
const NEUTRAL := Color(0.62, 0.58, 0.72)


# ---------- Pill-кнопка ----------

static func style_pill_button(btn: Button, bg_color: Color, height: int = 46, font_size: int = 18) -> void:
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.75))

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(height / 2)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg_color.lightened(0.12)

	var disabled := style.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.7, 0.7, 0.75, 0.7)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", disabled)


# ---------- Внутренние хелперы ----------

static func _make_overlay(parent: Control) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.38)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	return overlay


static func _make_card(overlay: Control, min_width: int = 420) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BG
	style.set_corner_radius_all(20)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	style.shadow_color = Color(0, 0, 0, 0.32)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(min_width, 0)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)

	return vb


static func _add_title(vb: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", TEXT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(lbl)

	var sep := HSeparator.new()
	vb.add_child(sep)


static func _make_msg_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", SUBTLE)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	return lbl


# ---------- 1. Информационное окно ----------

static func show_message(parent: Control, title: String, message: String,
		ok_text: String = "OK",
		ok_color: Color = ACCENT) -> Control:

	var overlay := _make_overlay(parent)
	var vb := _make_card(overlay, 420)
	_add_title(vb, title)
	vb.add_child(_make_msg_label(message))

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(btn_row)

	var ok := Button.new()
	ok.text = ok_text
	ok.custom_minimum_size = Vector2(130, 44)
	style_pill_button(ok, ok_color, 44, 17)
	ok.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(ok)

	return overlay


# ---------- 2. Подтверждение ----------

static func show_confirm(parent: Control, title: String, message: String,
		on_confirm: Callable,
		ok_text: String = "Подтвердить",
		cancel_text: String = "Отмена",
		ok_color: Color = ACCENT) -> Control:

	var overlay := _make_overlay(parent)
	var vb := _make_card(overlay, 440)
	_add_title(vb, title)
	vb.add_child(_make_msg_label(message))

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 10)
	vb.add_child(btn_row)

	var cancel := Button.new()
	cancel.text = cancel_text
	cancel.custom_minimum_size = Vector2(130, 44)
	style_pill_button(cancel, NEUTRAL, 44, 17)
	cancel.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(cancel)

	var ok := Button.new()
	ok.text = ok_text
	ok.custom_minimum_size = Vector2(130, 44)
	style_pill_button(ok, ok_color, 44, 17)
	ok.pressed.connect(func():
		overlay.queue_free()
		if on_confirm.is_valid():
			on_confirm.call()
	)
	btn_row.add_child(ok)

	return overlay


# ---------- 3. Произвольное содержимое ----------

# buttons: массив словарей вида
#   { "text": String, "color": Color, "on_press": Callable, "close": bool = true }
# "close": false — оставить окно открытым после нажатия (для кнопки «Проверить»).
static func show_custom(parent: Control, title: String, content: Control,
		buttons: Array) -> Control:

	var overlay := _make_overlay(parent)
	var vb := _make_card(overlay, 480)
	_add_title(vb, title)
	vb.add_child(content)

	if buttons.size() > 0:
		var btn_row := HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_END
		btn_row.add_theme_constant_override("separation", 10)
		vb.add_child(btn_row)

		for b in buttons:
			var btn := Button.new()
			btn.text = str(b.get("text", "OK"))
			btn.custom_minimum_size = Vector2(130, 44)
			style_pill_button(btn, b.get("color", ACCENT), 44, 17)

			var cb: Callable = b.get("on_press", Callable())
			var do_close: bool = b.get("close", true)

			btn.pressed.connect(func():
				if cb.is_valid():
					cb.call()
				if do_close:
					overlay.queue_free()
			)
			btn_row.add_child(btn)

	return overlay
	
	# Полупрозрачное затемнение фона под попапом (используется в Main.gd)
static func make_dim_overlay(color: Color = Color(0, 0, 0, 0.35)) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	return rect
