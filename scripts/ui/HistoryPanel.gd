extends Control

func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()

var content: VBoxContainer

func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vb)
	var title := Label.new()
	title.text = "Прогресс и справка"
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)


func _refresh() -> void:
	for c in content.get_children():
		c.queue_free()

	content.add_child(_section_header("Питомец"))
	var pet_info := Label.new()
	pet_info.text = "%s — стадия «%s», настроение %d/100, сытость %d/100." % [GameData.pet_name, GameData.stage_name(), GameData.mood, GameData.hunger]
	content.add_child(pet_info)

	content.add_child(_section_header("Текущая цель"))
	var g := GameData.get_goal(GameData.current_goal_id)
	if not g.is_empty():
		var goal_lbl := Label.new()
		goal_lbl.text = "%s: накоплено %d из %d" % [g.get("name"), min(GameData.savings, g.get("cost")), g.get("cost")]
		content.add_child(goal_lbl)

	content.add_child(_section_header("Итоги последнего периода"))
	if GameData.history.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "Периоды ещё не завершались."
		content.add_child(none_lbl)
	else:
		var h = GameData.history[GameData.history.size() - 1]
		var l := Label.new()
		l.text = "Период %d — план: обяз. %d / желаем. %d / накопл. %d. Факт: обяз. %d / желаем. %d. Процент: +%d." % [
			h.get("period_number"), h.get("plan_mandatory"), h.get("plan_optional"), h.get("plan_savings"),
			h.get("fact_mandatory"), h.get("fact_optional"), h.get("interest")]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		content.add_child(l)

	content.add_child(_section_header("Завершённые задания (%d из %d)" % [GameData.completed_tasks.size(), GameData.tasks.size()]))
	for t in GameData.tasks:
		var row := Label.new()
		var done: bool = GameData.is_task_completed(t.get("id"))
		row.text = "%s %s" % ["✓" if done else "○", t.get("title")]
		content.add_child(row)

	content.add_child(_section_header("Справочник терминов"))
	for term in GameData.glossary:
		var term_box := VBoxContainer.new()
		var t_lbl := Label.new()
		t_lbl.text = str(term.get("term"))
		t_lbl.add_theme_font_size_override("font_size", 16)
		term_box.add_child(t_lbl)
		var d_lbl := Label.new()
		d_lbl.text = str(term.get("definition"))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		d_lbl.modulate = Color(1,1,1,0.75)
		term_box.add_child(d_lbl)
		content.add_child(term_box)


func _section_header(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 20)
	return l
