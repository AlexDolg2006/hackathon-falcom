extends Control

var content_area: Control
var wallet_label: Label
var current_panel: Control
var nav_buttons: Dictionary = {}

const PANEL_HOME := "home"
const PANEL_SHOP := "shop"
const PANEL_GAME := "game"
const PANEL_BUDGET := "budget"
const PANEL_GOALS := "goals"
const PANEL_TASKS := "tasks"
const PANEL_HISTORY := "history"
const PANEL_ADULT := "adult"

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
	add_child(root_vb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)

	var top_bar := HBoxContainer.new()
	vb.add_child(top_bar)
	wallet_label = Label.new()
	wallet_label.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(wallet_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	var more_btn := Button.new()
	more_btn.text = "Ещё ▾"
	more_btn.pressed.connect(_open_more_menu)
	top_bar.add_child(more_btn)

	content_area = Control.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(content_area)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	vb.add_child(nav)

	nav_buttons.clear()
	_add_nav_button(nav, PANEL_HOME, "Дом")
	_add_nav_button(nav, PANEL_SHOP, "Покупки")
	_add_nav_button(nav, PANEL_GAME, "Игра")
	_add_nav_button(nav, PANEL_BUDGET, "Бюджет")

	_update_wallet_label()


func _add_nav_button(nav: HBoxContainer, key: String, text: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.toggle_mode = true
	b.pressed.connect(func(): _show_panel(key))
	nav.add_child(b)
	nav_buttons[key] = b


func _open_more_menu() -> void:
	var popup := PopupMenu.new()
	popup.add_item("Накопления и цели", 0)
	popup.add_item("Финансовые задания", 1)
	popup.add_item("Прогресс и справка", 2)
	popup.add_item("Раздел для взрослого", 3)
	add_child(popup)
	popup.id_pressed.connect(func(id: int):
		match id:
			0: _show_panel(PANEL_GOALS)
			1: _show_panel(PANEL_TASKS)
			2: _show_panel(PANEL_HISTORY)
			3: _show_panel(PANEL_ADULT)
	)
	popup.popup(Rect2i(get_viewport().get_visible_rect().size.x - 260, 90, 250, 160))


func _update_wallet_label() -> void:
	if wallet_label:
		wallet_label.text = "Кошелёк: %d   Накопления: %d" % [GameData.wallet, GameData.savings]


func _show_panel(key: String) -> void:
	if current_panel:
		current_panel.queue_free()
	for k in nav_buttons.keys():
		nav_buttons[k].button_pressed = (k == key)

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
	current_panel = panel
	_update_wallet_label()


func _make(script: Script) -> Control:
	var c := Control.new()
	c.set_script(script)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_area.add_child(c)
	return c
