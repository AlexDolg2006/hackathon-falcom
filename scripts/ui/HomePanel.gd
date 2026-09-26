extends Control

signal go_to_shop
signal go_to_minigame
signal go_to_budget

var mood_bar: ProgressBar
var hunger_bar: ProgressBar
var name_label: Label
var stage_label: Label
var goal_label: Label
var claim_button: Button
var feedback_label: Label
var period_label: Label

func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	GameData.toast.connect(_show_toast)
	_refresh()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_label)

	stage_label = Label.new()
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stage_label)

	var pet_center := CenterContainer.new()
	pet_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(pet_center)
	var pet_canvas := Control.new()
	pet_canvas.set_script(load("res://scripts/ui/PetCanvas.gd"))
	pet_center.add_child(pet_canvas)

	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	vb.add_child(stats_grid)
	stats_grid.add_child(_mklabel("Настроение"))
	mood_bar = ProgressBar.new()
	mood_bar.max_value = 100
	stats_grid.add_child(mood_bar)
	stats_grid.add_child(_mklabel("Сытость"))
	hunger_bar = ProgressBar.new()
	hunger_bar.max_value = 100
	stats_grid.add_child(hunger_bar)

	goal_label = Label.new()
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(goal_label)

	period_label = Label.new()
	period_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(period_label)

	feedback_label = Label.new()
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	feedback_label.modulate = Color(0.6, 1.0, 0.6)
	vb.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	vb.add_child(actions)

	claim_button = Button.new()
	claim_button.text = "Забрать доход дня"
	claim_button.custom_minimum_size = Vector2(0, 60)
	claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_button.pressed.connect(func(): GameData.claim_daily_income())
	actions.add_child(claim_button)

	var feed_btn := Button.new()
	feed_btn.text = "В магазин: покормить/помыть"
	feed_btn.custom_minimum_size = Vector2(0, 60)
	feed_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_btn.pressed.connect(func(): go_to_shop.emit())
	actions.add_child(feed_btn)

	var actions2 := HBoxContainer.new()
	actions2.add_theme_constant_override("separation", 8)
	vb.add_child(actions2)

	var game_btn := Button.new()
	game_btn.text = "Мини-игра дня"
	game_btn.custom_minimum_size = Vector2(0, 60)
	game_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_btn.pressed.connect(func(): go_to_minigame.emit())
	actions2.add_child(game_btn)

	var budget_btn := Button.new()
	budget_btn.text = "План / День"
	budget_btn.custom_minimum_size = Vector2(0, 60)
	budget_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	budget_btn.pressed.connect(func(): go_to_budget.emit())
	actions2.add_child(budget_btn)


func _mklabel(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _refresh() -> void:
	name_label.text = GameData.pet_name
	stage_label.text = "Стадия: %s" % GameData.stage_name()
	mood_bar.value = GameData.mood
	hunger_bar.value = GameData.hunger

	var g := GameData.get_goal(GameData.current_goal_id)
	if not g.is_empty():
		goal_label.text = "Цель: %s (%d / %d монет)" % [g.get("name"), min(GameData.savings, g.get("cost")), g.get("cost")]
	else:
		goal_label.text = "Цель ещё не выбрана."

	if GameData.period_active:
		period_label.text = "Период %d, день %d из %d. Обязательное: %d, желаемое: %d." % [
			GameData.period_number, GameData.day_in_period, GameData.PERIOD_LENGTH,
			GameData.mandatory_budget, GameData.optional_budget]
	else:
		period_label.text = "Новый период не спланирован. Открой «План / День», чтобы распределить %d монет." % GameData.wallet

	claim_button.disabled = not GameData.can_claim_daily_income()
	claim_button.text = "Доход уже получен сегодня" if claim_button.disabled else "Забрать доход дня (+%d)" % GameData.DAILY_INCOME


func _show_toast(message: String) -> void:
	feedback_label.text = message
