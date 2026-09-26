extends Control

var list_box: VBoxContainer
var savings_label: Label

func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	var title := Label.new()
	title.text = "Накопления и цели"
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)

	savings_label = Label.new()
	savings_label.add_theme_font_size_override("font_size", 20)
	vb.add_child(savings_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 10)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)


func _refresh() -> void:
	savings_label.text = "Всего в накоплениях: %d монет" % GameData.savings
	for c in list_box.get_children():
		c.queue_free()
	for g in GameData.goals_catalog:
		list_box.add_child(_build_goal_row(g))


func _build_goal_row(g: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var vb := VBoxContainer.new()
	panel.add_child(vb)

	var is_current: bool = GameData.current_goal_id == g.get("id")
	var header := Label.new()
	header.text = "%s%s" % [g.get("name"), "  ★ текущая цель" if is_current else ""]
	header.add_theme_font_size_override("font_size", 18)
	vb.add_child(header)

	var cost: int = g.get("cost", 0)
	var progress := ProgressBar.new()
	progress.max_value = cost
	progress.value = min(GameData.savings, cost)
	vb.add_child(progress)

	var progress_lbl := Label.new()
	progress_lbl.text = "%d из %d монет" % [min(GameData.savings, cost), cost]
	vb.add_child(progress_lbl)

	if is_current:
		var est = GameData.estimate_periods_to_goal(g.get("id"))
		var est_lbl := Label.new()
		if est == null:
			est_lbl.text = "Начни откладывать в план бюджета, чтобы увидеть срок достижения цели."
		elif est == 0:
			est_lbl.text = "Цель уже накоплена!"
		else:
			est_lbl.text = "Примерно ещё %d период(ов) при среднем темпе накоплений." % est
		vb.add_child(est_lbl)

	var hb := HBoxContainer.new()
	vb.add_child(hb)
	if not is_current:
		var select_btn := Button.new()
		select_btn.text = "Выбрать целью"
		select_btn.pressed.connect(func(): GameData.select_goal(g.get("id")))
		hb.add_child(select_btn)
	else:
		var withdraw_btn := Button.new()
		withdraw_btn.text = "Снять часть накоплений"
		withdraw_btn.disabled = GameData.savings <= 0
		withdraw_btn.pressed.connect(func(): _open_withdraw_dialog())
		hb.add_child(withdraw_btn)

	panel.add_child(vb)
	return panel


func _open_withdraw_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	var vb := VBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Сколько монет снять с накоплений? (сейчас: %d)" % GameData.savings
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(lbl)
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = GameData.savings
	spin.step = 1
	vb.add_child(spin)
	var preview := Label.new()
	vb.add_child(preview)
	spin.value_changed.connect(func(v):
		var new_savings := GameData.savings - int(v)
		preview.text = "После снятия останется: %d монет" % new_savings
	)
	dialog.add_child(vb)
	dialog.dialog_text = ""
	add_child(dialog)
	dialog.confirmed.connect(func():
		GameData.withdraw_savings(int(spin.value))
	)
	dialog.popup_centered(Vector2i(400, 220))
