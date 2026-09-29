extends RefCounted
class_name UIUtils

static var _dialog_theme: Theme = null

static func _get_dialog_theme() -> Theme:
	if _dialog_theme != null:
		return _dialog_theme

	# Копируем встроенную тему Godot, чтобы унаследовать
	# иконки (включая «крестик»), фокус-рамки и прочие элементы,
	# которые мы не переопределяем.
	var theme := ThemeDB.get_default_theme().duplicate() as Theme
	theme.default_font_size = 16

	var dark := Color(0.15, 0.15, 0.25)

	theme.set_color("font_color", "Label", dark)
	theme.set_color("font_color", "RichTextLabel", dark)
	theme.set_color("default_color", "RichTextLabel", dark)
	theme.set_color("font_color", "CheckBox", dark)
	theme.set_color("font_color", "CheckButton", dark)
	theme.set_color("font_color", "OptionButton", dark)
	theme.set_color("font_color", "MenuButton", dark)
	theme.set_color("font_color", "LinkButton", dark)
	theme.set_color("font_color", "LineEdit", dark)
	theme.set_color("font_color", "TextEdit", dark)
	theme.set_color("caret_color", "LineEdit", dark)
	theme.set_color("selection_color", "LineEdit", Color(0.42, 0.35, 0.82, 0.35))
	theme.set_color("font_color", "Tree", dark)
	theme.set_color("font_color", "ItemList", dark)
	theme.set_color("font_color", "PopupMenu", dark)

	_dialog_theme = theme
	return _dialog_theme

# Pill-кнопка в едином стиле приложения
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
	style.content_margin_left = 16
	style.content_margin_right = 16
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


# Единый стиль панели диалога — теперь с округлым «окном» и видимым заголовком
static func style_dialog(dialog: AcceptDialog,
		ok_color: Color = Color(0.42, 0.35, 0.82),
		cancel_color: Color = Color(0.62, 0.58, 0.72)) -> void:

	var bg := Color(0.96, 0.96, 0.99)
	var dark := Color(0.15, 0.15, 0.25)

	# --- 1. Тёмный текст внутри диалога ---
	dialog.theme = _get_dialog_theme()

	# --- 2. Внешний "корпус" окна (включая полосу заголовка) ---
	# Он должен быть скруглён целиком — тогда и заголовок, и контент
	# окажутся внутри одной округлой карточки.
	var border := StyleBoxFlat.new()
	border.bg_color = bg
	border.set_corner_radius_all(18)
	border.shadow_size = 8
	border.shadow_offset = Vector2(0, 4)
	border.shadow_color = Color(0, 0, 0, 0.28)
	var title_h := 44
	border.content_margin_left = 4
	border.content_margin_right = 4
	border.content_margin_top = title_h       # ← резерв под полосу заголовка
	border.content_margin_bottom = 4
	dialog.add_theme_stylebox_override("embedded_border", border)
	dialog.add_theme_stylebox_override("embedded_unfocused_border", border)

	# --- 3. Внутренняя панель (контент) ---
	# Низ скруглён, чтобы совпасть с нижними углами корпуса.
	# Верх оставляем прямым — там начинается полоса заголовка.
	var panel := StyleBoxFlat.new()
	panel.bg_color = bg
	panel.set_corner_radius_all(0)
	panel.corner_radius_bottom_left = 18
	panel.corner_radius_bottom_right = 18
	panel.content_margin_left = 18
	panel.content_margin_right = 18
	panel.content_margin_top = 4
	panel.content_margin_bottom = 18
	panel.shadow_size = 0
	dialog.add_theme_stylebox_override("panel", panel)

	# --- 4. Заголовок окна: тёмный текст на светлой полосе ---
	dialog.add_theme_color_override("title_color", dark)
	dialog.add_theme_color_override("title_outline_color", Color(0, 0, 0, 0))
	dialog.add_theme_font_size_override("title_font_size", 20)
	dialog.add_theme_constant_override("title_height", title_h)

	# --- 5. Кнопки OK/Cancel ---
	dialog.add_theme_constant_override("buttons_separation", 10)
	dialog.add_theme_constant_override("margin_bottom", 6)

	var ok: Button = dialog.get_ok_button()
	if ok:
		ok.custom_minimum_size = Vector2(120, 42)
		style_pill_button(ok, ok_color, 42, 17)

	if dialog is ConfirmationDialog:
		var conf := dialog as ConfirmationDialog
		var cancel: Button = conf.get_cancel_button()
		if cancel:
			cancel.custom_minimum_size = Vector2(120, 42)
			style_pill_button(cancel, cancel_color, 42, 17)


# Полупрозрачное затемнение фона под попапом
static func make_dim_overlay(color: Color = Color(0, 0, 0, 0.35)) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	return rect
