extends Control

var content_area: Control
var wallet_label: Label
var current_panel: Control
var nav_buttons: Dictionary = {}
var more_popup_overlay: Control

const PANEL_HOME := "home"
const PANEL_SHOP := "shop"
const PANEL_GAME := "game"
const PANEL_BUDGET := "budget"
const PANEL_GOALS := "goals"
const PANEL_TASKS := "tasks"
const PANEL_HISTORY := "history"
const PANEL_ADULT := "adult"
const PANEL_WASH := "wash"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if GameData.first_launch or not GameData.pet_created:
		_show_onboarding()
	else:
		_build_shell()
		_show_panel(PANEL_HOME)
	GameData.state_changed.connect(_update_wallet_label)


func _show_onboarding() -> void:
	for c in get_children():
		c.queue_free()
	var onboarding := Control.new()
	onboarding.set_anchors_preset(Control.PRESET_FULL_RECT)
	onboarding.set_script(load("res://scripts/ui/OnboardingPanel.gd"))
	add_child(onboarding)
	onboarding.finished.connect(func():
		onboarding.queue_free()
		_build_shell()
		_show_panel(PANEL_HOME)
	)


func _build_shell() -> void:
	for c in get_children():
		c.queue_free()

	var root_vb := VBoxContainer.new()
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.add_theme_constant_override("separation", 6)
	add_child(root_vb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vb)

	# 1. Верхняя панель кошелька
	var top_card := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.94, 0.94, 0.98)
	top_style.set_corner_radius_all(16)
	top_style.content_margin_left = 14
	top_style.content_margin_right = 14
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_style.shadow_size = 2
	top_style.shadow_color = Color(0, 0, 0, 0.08)
	top_card.add_theme_stylebox_override("panel", top_style)
	vb.add_child(top_card)

	var top_bar := HBoxContainer.new()
	top_card.add_child(top_bar)

	wallet_label = Label.new()
	wallet_label.add_theme_font_size_override("font_size", 23)
	wallet_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	top_bar.add_child(wallet_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	var more_btn := Button.new()
	more_btn.text = "Ещё ▾"
	more_btn.custom_minimum_size = Vector2(104, 46)
	more_btn.add_theme_font_size_override("font_size", 20)
	_apply_button_style(more_btn, Color(0.84, 0.82, 0.94), 22)
	more_btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.32))
	more_btn.pressed.connect(_open_more_menu)
	top_bar.add_child(more_btn)

	# 2. Область экрана
	content_area = Control.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.clip_contents = true
	vb.add_child(content_area)

	# 3. Нижняя карточка с кнопками навигации
	var nav_card := PanelContainer.new()
	var nav_style := StyleBoxFlat.new()
	nav_style.bg_color = Color(0.92, 0.93, 0.97)
	nav_style.set_corner_radius_all(18)
	nav_style.content_margin_left = 8
	nav_style.content_margin_right = 8
	nav_style.content_margin_top = 8
	nav_style.content_margin_bottom = 8
	nav_style.shadow_size = 2
	nav_style.shadow_color = Color(0, 0, 0, 0.08)
	nav_card.add_theme_stylebox_override("panel", nav_style)
	vb.add_child(nav_card)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	nav_card.add_child(nav)

	nav_buttons.clear()
	_add_nav_button(nav, PANEL_HOME, "🏠 Дом")
	_add_nav_button(nav, PANEL_SHOP, "🛒 Магазин")
	_add_nav_button(nav, PANEL_GAME, "🎮 Игра")
	_add_nav_button(nav, PANEL_BUDGET, "📊 Бюджет")

	_update_wallet_label()


func _add_nav_button(nav: HBoxContainer, key: String, text: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 62)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 20)
	b.toggle_mode = true
	b.pressed.connect(func(): _show_panel(key))
	nav.add_child(b)
	nav_buttons[key] = b


func _apply_button_style(btn: Button, bg_color: Color, corner_radius: int) -> void:
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.set_corner_radius_all(corner_radius)
	
	var style_hover := style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.12)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)


const UIUtils = preload("res://scripts/ui/UIUtils.gd")

func _open_more_menu() -> void:
	if more_popup_overlay and is_instance_valid(more_popup_overlay):
		more_popup_overlay.queue_free()
		more_popup_overlay = null
		return

	more_popup_overlay = Control.new()
	more_popup_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(more_popup_overlay)

	# --- 1. Затемняющая подложка (новое) ---
	var dim := UIUtils.make_dim_overlay(Color(0, 0, 0, 0.28))
	more_popup_overlay.add_child(dim)

	var bg_btn := Button.new()
	bg_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_btn.flat = true
	bg_btn.pressed.connect(func():
		if more_popup_overlay:
			more_popup_overlay.queue_free()
			more_popup_overlay = null
	)
	more_popup_overlay.add_child(bg_btn)

	# --- 2. Выпадающая карточка в стиле панелей ---
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.96, 0.96, 0.99)
	card_style.set_corner_radius_all(18)
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	card_style.shadow_size = 6
	card_style.shadow_offset = Vector2(0, 6)
	card_style.shadow_color = Color(0, 0, 0, 0.22)
	card.add_theme_stylebox_override("panel", card_style)

	card.custom_minimum_size = Vector2(280, 0)
	card.position = Vector2(get_viewport_rect().size.x - 290, 70)
	more_popup_overlay.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	# Небольшой заголовок карточки
	var hdr := Label.new()
	hdr.text = "Дополнительно"
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vb.add_child(hdr)

	var items := [
		{"text": "🧼 Купание кота", "key": PANEL_WASH},
		{"text": "🎯 Накопления и цели", "key": PANEL_GOALS},
		{"text": "📋 Финансовые задания", "key": PANEL_TASKS},
		{"text": "📈 Прогресс и справка", "key": PANEL_HISTORY},
		{"text": "🔒 Раздел для родителей", "key": PANEL_ADULT}
	]

	for item in items:
		var btn := Button.new()
		btn.text = item.get("text")
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Мягкая кнопка-строка в стиле приложения
		var b_style := StyleBoxFlat.new()
		b_style.bg_color = Color(0.91, 0.92, 0.97)
		b_style.set_corner_radius_all(14)
		b_style.content_margin_left = 14
		b_style.content_margin_right = 14

		var b_hover := b_style.duplicate() as StyleBoxFlat
		b_hover.bg_color = Color(0.42, 0.35, 0.82)

		btn.add_theme_stylebox_override("normal", b_style)
		btn.add_theme_stylebox_override("hover", b_hover)
		btn.add_theme_stylebox_override("focus", b_hover)
		btn.add_theme_stylebox_override("pressed", b_hover)
		btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

		var k: String = item.get("key")
		btn.pressed.connect(func():
			if more_popup_overlay:
				more_popup_overlay.queue_free()
				more_popup_overlay = null
			_show_panel(k)
		)
		vb.add_child(btn)


func _update_wallet_label() -> void:
	if wallet_label:
		wallet_label.text = "💰 %d   🎯 %d" % [GameData.wallet, GameData.savings]


func _show_panel(key: String) -> void:
	if current_panel:
		current_panel.queue_free()

	for k in nav_buttons.keys():
		var btn: Button = nav_buttons[k]
		var is_active :bool= (k == key)
		btn.button_pressed = is_active
		
		var style_normal := StyleBoxFlat.new()
		style_normal.set_corner_radius_all(16)
		
		if is_active:
			style_normal.bg_color = Color(0.42, 0.35, 0.82)
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			style_normal.shadow_size = 2
			style_normal.shadow_offset = Vector2(0, 2)
		else:
			style_normal.bg_color = Color(0.84, 0.85, 0.92)
			btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
		
		var style_hover := style_normal.duplicate() as StyleBoxFlat
		if is_active:
			style_hover.bg_color = Color(0.48, 0.40, 0.88)
		else:
			style_hover.bg_color = Color(0.76, 0.78, 0.88)

		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("focus", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)

	var panel: Control
	match key:
		PANEL_HOME:
			panel = Control.new()
			panel.set_script(load("res://scripts/ui/HomePanel.gd"))
			panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			content_area.add_child(panel)
			panel.go_to_shop.connect(func(): _show_panel(PANEL_SHOP))
			panel.go_to_minigame.connect(func(): _show_panel(PANEL_GAME))
			panel.go_to_budget.connect(func(): _show_panel(PANEL_BUDGET))
			panel.go_to_wash.connect(func(): _show_panel(PANEL_WASH))
		PANEL_SHOP:
			panel = _make(load("res://scripts/ui/ShopPanel.gd"))
		PANEL_GAME:
			panel = _make(load("res://scripts/ui/MiniGamePanel.gd"))
		PANEL_BUDGET:
			panel = _make(load("res://scripts/ui/BudgetPanel.gd"))
		PANEL_GOALS:
			panel = _make(load("res://scripts/ui/GoalsPanel.gd"))
		PANEL_TASKS:
			panel = _make(load("res://scripts/ui/TasksPanel.gd"))
		PANEL_HISTORY:
			panel = _make(load("res://scripts/ui/HistoryPanel.gd"))
		PANEL_ADULT:
			panel = _make(load("res://scripts/ui/AdultPanel.gd"))
		PANEL_WASH:
			panel = _make(load("res://scripts/ui/WashPanel.gd"))
			if panel.has_signal("wash_finished"):
				panel.connect("wash_finished", func(): _show_panel(PANEL_HOME))
	current_panel = panel
	_update_wallet_label()


func _make(script: Script) -> Control:
	var c := Control.new()
	c.set_script(script)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_area.add_child(c)
	return c
