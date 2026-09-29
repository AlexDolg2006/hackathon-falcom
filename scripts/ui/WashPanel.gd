extends Control
## Интерактивное мытьё кота в светлой стилистике.

signal wash_finished

var pet_canvas: Control
var bucket: Control
var bucket_icon: Control
var progress_label: Label
var status_label: Label
var tool_label: Label

var dragging := false
var drag_offset := Vector2.ZERO
var last_pet_hit := Vector2.ZERO
var touching_pet := false
var wash_power := 12.0

const BUCKET_SIZE := Vector2(80, 80)
const INITIAL_BUCKET_POS := Vector2(16, 16)

const RUB_PER_HYGIENE := 60.0
const MAX_HYGIENE_PER_FRAME := 1
const MIN_RUB_STEP := 1.0
const MAX_MOVE_PER_FRAME := 8.0
const HYGIENE_PER_MOOD := 8

const PASSIVE_REGEN_INTERVAL := 5.0
const PASSIVE_REGEN_AMOUNT := 1

var _rub_buffer := 0.0
var _hygiene_accum := 0
var _regen_timer := 0.0


func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	# --- 1. Верхняя информационная карточка ---
	var top_card := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.94, 0.94, 0.98)
	top_style.set_corner_radius_all(16)
	top_style.content_margin_left = 12
	top_style.content_margin_right = 12
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_style.shadow_size = 2
	top_style.shadow_color = Color(0, 0, 0, 0.08)
	top_card.add_theme_stylebox_override("panel", top_style)
	vb.add_child(top_card)

	var top_vb := VBoxContainer.new()
	top_vb.add_theme_constant_override("separation", 4)
	top_card.add_child(top_vb)

	var title := Label.new()
	title.text = "🧼 Купание кота"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_vb.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.35))
	top_vb.add_child(status_label)

	var progress_box := HBoxContainer.new()
	progress_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_vb.add_child(progress_box)

	var pl := Label.new()
	pl.text = "Текущая гигиена: "
	pl.add_theme_font_size_override("font_size", 18)
	pl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
	progress_box.add_child(pl)

	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 20)
	progress_label.add_theme_color_override("font_color", Color(0.1, 0.55, 0.8))
	progress_box.add_child(progress_label)

	# --- 2. Центральная зона питомца ---
	var pet_wrap := PanelContainer.new()
	pet_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pet_wrap.clip_contents = true
	var pet_style := StyleBoxFlat.new()
	pet_style.bg_color = Color(0.88, 0.91, 0.97, 0.8)
	pet_style.set_corner_radius_all(20)
	pet_wrap.add_theme_stylebox_override("panel", pet_style)
	vb.add_child(pet_wrap)

	pet_canvas = Control.new()
	pet_canvas.set_script(load("res://scripts/ui/PetCanvas.gd"))
	pet_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	pet_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pet_wrap.add_child(pet_canvas)

	# Ведро с мылом/мочалкой
	bucket = Control.new()
	bucket.custom_minimum_size = BUCKET_SIZE
	bucket.size = BUCKET_SIZE
	# Отключаем автоматическое растягивание контейнером
	bucket.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bucket.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bucket.position = INITIAL_BUCKET_POS
	bucket.mouse_filter = Control.MOUSE_FILTER_STOP
	pet_wrap.add_child(bucket)

	var bucket_bg := StyleBoxFlat.new()
	bucket_bg.bg_color = Color(0.45, 0.60, 0.75)
	bucket_bg.set_corner_radius_all(12)
	bucket_bg.shadow_size = 2
	bucket_bg.shadow_offset = Vector2(0, 2)
	
	var bucket_panel := Panel.new()
	bucket_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bucket_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bucket_panel.add_theme_stylebox_override("panel", bucket_bg)
	bucket.add_child(bucket_panel)

	bucket_icon = Control.new()
	bucket_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	bucket_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bucket_icon.draw.connect(_draw_bucket_icon)
	bucket.add_child(bucket_icon)

	tool_label = Label.new()
	tool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tool_label.add_theme_font_size_override("font_size", 13)
	tool_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tool_label.position.y = 58
	tool_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bucket.add_child(tool_label)

	# --- 3. Нижняя карточка с кнопкой завершения ---
	var bottom_card := PanelContainer.new()
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color(0.92, 0.93, 0.97)
	bottom_style.set_corner_radius_all(18)
	bottom_style.content_margin_left = 10
	bottom_style.content_margin_right = 10
	bottom_style.content_margin_top = 10
	bottom_style.content_margin_bottom = 10
	bottom_card.add_theme_stylebox_override("panel", bottom_style)
	vb.add_child(bottom_card)

	var done_btn := Button.new()
	done_btn.text = "✓ Закончить купание"
	done_btn.custom_minimum_size = Vector2(0, 58)
	done_btn.add_theme_font_size_override("font_size", 20)
	done_btn.add_theme_color_override("font_color", Color(1, 1, 1))

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.22, 0.60, 0.82)
	btn_style.set_corner_radius_all(29)
	btn_style.shadow_size = 2
	btn_style.shadow_offset = Vector2(0, 2)
	btn_style.shadow_color = Color(0, 0, 0, 0.15)

	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.32, 0.70, 0.92)

	done_btn.add_theme_stylebox_override("normal", btn_style)
	done_btn.add_theme_stylebox_override("hover", btn_hover)
	done_btn.add_theme_stylebox_override("focus", btn_hover)
	done_btn.add_theme_stylebox_override("pressed", btn_hover)

	done_btn.pressed.connect(_finish_wash)
	bottom_card.add_child(done_btn)


func _draw_bucket_icon() -> void:
	var c: Vector2 = bucket_icon.size * 0.5
	var wash_id: String = GameData.equipped_wash
	if wash_id == "":
		return
	if wash_id == "soap":
		var soap_col := Color(0.55, 0.85, 0.95)
		bucket_icon.draw_rect(Rect2(c - Vector2(22, 14), Vector2(44, 28)), soap_col)
		bucket_icon.draw_rect(Rect2(c - Vector2(22, 14), Vector2(44, 28)), Color(0.3, 0.6, 0.75), false, 2.5)
		bucket_icon.draw_circle(c + Vector2(-8, -5), 3.5, Color(1, 1, 1, 0.8))
		bucket_icon.draw_circle(c + Vector2(8, 5), 3.5, Color(1, 1, 1, 0.8))
	elif wash_id == "sponge":
		var sponge_col := Color(0.95, 0.75, 0.35)
		var pts := PackedVector2Array()
		for i in range(24):
			var a := TAU * i / 24
			pts.append(c + Vector2(cos(a) * 22, sin(a) * 16))
		bucket_icon.draw_colored_polygon(pts, sponge_col)
		bucket_icon.draw_arc(c, 22, 0, TAU, 32, Color(0.7, 0.5, 0.2), 2.5)


func _refresh() -> void:
	var wash_id: String = GameData.equipped_wash
	var inv_count: int = int(GameData.inventory.get(wash_id, 0))
	if wash_id == "" or inv_count <= 0:
		status_label.text = "Купи мыло или мочалку в магазине."
		bucket.visible = false
		wash_power = 12.0
	else:
		bucket.visible = true
		var item: Dictionary = GameData.get_item(wash_id)
		wash_power = float(item.get("wash_power", 12))
		tool_label.text = str(item.get("name"))
		status_label.text = "Средство: %s (сила ×%.0f). Состояние: %s." % [
			item.get("name"), wash_power, GameData.hygiene_stage()]
		_reset_bucket_position()
	_update_progress()
	bucket_icon.queue_redraw()


func _reset_bucket_position() -> void:
	if bucket:
		bucket.position = INITIAL_BUCKET_POS


func _update_progress() -> void:
	progress_label.text = "%d%%" % int(GameData.hygiene)


func _process(delta: float) -> void:
	if dragging or not bucket.visible:
		return
	if GameData.hygiene >= 100:
		return
	_regen_timer += delta
	if _regen_timer >= PASSIVE_REGEN_INTERVAL:
		_regen_timer = 0.0
		GameData.hygiene = clampi(GameData.hygiene + PASSIVE_REGEN_AMOUNT, 0, 100)
		GameData.state_changed.emit()
		_update_progress()


func _input(event: InputEvent) -> void:
	if not bucket.visible:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and bucket.get_global_rect().has_point(mb.position):
				_start_drag(mb.position)
			elif not mb.pressed and dragging:
				_stop_drag()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and bucket.get_global_rect().has_point(st.position):
			_start_drag(st.position)
		elif not st.pressed and dragging:
			_stop_drag()
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and dragging:
		bucket.global_position = event.position + drag_offset
		_check_touch()


func _start_drag(pos: Vector2) -> void:
	dragging = true
	drag_offset = bucket.global_position - pos
	last_pet_hit = Vector2.ZERO
	_rub_buffer = 0.0


func _stop_drag() -> void:
	dragging = false
	last_pet_hit = Vector2.ZERO
	touching_pet = false
	_reset_bucket_position()


func _check_touch() -> void:
	if not pet_canvas:
		return
	var bucket_center: Vector2 = bucket.global_position + bucket.size * 0.5
	var local: Vector2 = pet_canvas.get_global_transform().affine_inverse() * bucket_center
	touching_pet = pet_canvas.is_point_on_pet(local)
	if touching_pet:
		_rub_at(local)
	else:
		last_pet_hit = Vector2.ZERO


func _rub_at(local_pos: Vector2) -> void:
	var moved: float = 0.0
	if last_pet_hit != Vector2.ZERO:
		moved = local_pos.distance_to(last_pet_hit)
	last_pet_hit = local_pos
	if moved < MIN_RUB_STEP:
		return
	moved = min(moved, MAX_MOVE_PER_FRAME)

	var r := randf_range(10.0, 18.0)
	pet_canvas.add_bubble(local_pos, r)

	_rub_buffer += moved * (wash_power / 12.0)

	var gain := int(floor(_rub_buffer / RUB_PER_HYGIENE))
	if gain <= 0:
		return
	gain = min(gain, MAX_HYGIENE_PER_FRAME)
	_rub_buffer -= gain * RUB_PER_HYGIENE

	GameData.hygiene = clampi(GameData.hygiene + gain, 0, 100)
	_hygiene_accum += gain
	while _hygiene_accum >= HYGIENE_PER_MOOD:
		_hygiene_accum -= HYGIENE_PER_MOOD
		GameData.mood = clampi(GameData.mood + 1, 0, 100)

	GameData.state_changed.emit()
	_update_progress()

	var wash_id: String = GameData.equipped_wash
	if wash_id != "":
		var item: Dictionary = GameData.get_item(wash_id)
		status_label.text = "Средство: %s (сила ×%.0f). Состояние: %s." % [
			item.get("name"), wash_power, GameData.hygiene_stage()]


func _finish_wash() -> void:
	pet_canvas.set_wash_state(false)
	wash_finished.emit()
