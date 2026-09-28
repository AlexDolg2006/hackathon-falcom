extends Control
## Интерактивное мытьё кота: водишь ведром с мылом/мочалкой по телу кота,
## гигиена растёт постепенно. Можно мыть сколько угодно раз — просто
## гигиена восстанавливается до 100 и потом уже не растёт.

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

var wash_power := 12.0
var wash_done := false

# Сколько гигиены даёт одно "полное" трение (100% полосы).
const WASH_FULL_GAIN := 40
# Насколько близко к коту нужно тереть, чтобы считалось.
const MIN_RUB_STEP := 0.6
# Сглаживание: сколько "единиц трения" надо, чтобы получить WASH_FULL_GAIN.
const RUB_FOR_FULL := 200.0


func _ready() -> void:
	_build_ui()
	GameData.state_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	var title := Label.new()
	title.text = "Купание кота"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(status_label)

	var pet_wrap := Control.new()
	pet_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pet_wrap.custom_minimum_size = Vector2(0, 360)
	pet_wrap.clip_contents = true
	pet_wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	vb.add_child(pet_wrap)

	pet_canvas = Control.new()
	pet_canvas.set_script(load("res://scripts/ui/PetCanvas.gd"))
	pet_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	pet_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pet_wrap.add_child(pet_canvas)

	bucket = Control.new()
	bucket.custom_minimum_size = Vector2(96, 96)
	bucket.size = Vector2(96, 96)
	bucket.mouse_filter = Control.MOUSE_FILTER_STOP
	pet_wrap.add_child(bucket)

	var bucket_bg := ColorRect.new()
	bucket_bg.color = Color(0.45, 0.55, 0.65)
	bucket_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bucket_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bucket.add_child(bucket_bg)

	var handle := ColorRect.new()
	handle.color = Color(0.3, 0.4, 0.5)
	handle.size = Vector2(50, 8)
	handle.position = Vector2(23, -4)
	handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bucket.add_child(handle)

	bucket_icon = Control.new()
	bucket_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	bucket_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bucket_icon.draw.connect(_draw_bucket_icon)
	bucket.add_child(bucket_icon)

	tool_label = Label.new()
	tool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tool_label.add_theme_font_size_override("font_size", 14)
	tool_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tool_label.position.y = 74
	tool_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bucket.add_child(tool_label)

	var progress_box := VBoxContainer.new()
	vb.add_child(progress_box)
	var pl := Label.new()
	pl.text = "Гигиена:"
	progress_box.add_child(pl)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_box.add_child(progress_label)

	var hint := Label.new()
	hint.text = "Перетащи ведро на кота и три его пальцем. Можно возвращаться и мыть снова — гигиена постепенно падает со временем."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.modulate = Color(1, 1, 1, 0.7)
	vb.add_child(hint)

	var done_btn := Button.new()
	done_btn.text = "Закончить купание"
	done_btn.custom_minimum_size = Vector2(0, 60)
	done_btn.pressed.connect(_finish_wash)
	vb.add_child(done_btn)


func _draw_bucket_icon() -> void:
	var c: Vector2 = bucket_icon.size * 0.5
	var wash_id: String = GameData.equipped_wash
	if wash_id == "":
		return
	if wash_id == "soap":
		var soap_col := Color(0.55, 0.85, 0.95)
		bucket_icon.draw_rect(Rect2(c - Vector2(26, 18), Vector2(52, 36)), soap_col)
		bucket_icon.draw_rect(Rect2(c - Vector2(26, 18), Vector2(52, 36)), Color(0.3, 0.6, 0.75), false, 3.0)
		bucket_icon.draw_circle(c + Vector2(-10, -6), 4, Color(1, 1, 1, 0.8))
		bucket_icon.draw_circle(c + Vector2(10, 6), 4, Color(1, 1, 1, 0.8))
	elif wash_id == "sponge":
		var sponge_col := Color(0.95, 0.75, 0.35)
		var pts := PackedVector2Array()
		for i in range(24):
			var a := TAU * i / 24
			pts.append(c + Vector2(cos(a) * 28, sin(a) * 20))
		bucket_icon.draw_colored_polygon(pts, sponge_col)
		bucket_icon.draw_arc(c, 28, 0, TAU, 32, Color(0.7, 0.5, 0.2), 3.0)
		for i in range(5):
			var off := Vector2(-18 + i * 9, 0)
			bucket_icon.draw_line(c + off + Vector2(0, -12), c + off + Vector2(0, 12), Color(0.7, 0.5, 0.2, 0.6), 2.0)


func _refresh() -> void:
	var wash_id: String = GameData.equipped_wash
	var inv_count: int = int(GameData.inventory.get(wash_id, 0))
	if wash_id == "" or inv_count <= 0:
		status_label.text = "Сначала купи мыло или мочалку в магазине (категория «Обязательное»)."
		bucket.visible = false
		wash_power = 12.0
	else:
		bucket.visible = true
		var item: Dictionary = GameData.get_item(wash_id)
		wash_power = float(item.get("wash_power", 12))
		tool_label.text = str(item.get("name"))
		status_label.text = "Средство: %s (сила мытья ×%.0f). Гигиена: %d/100 (%s)." % [
			item.get("name"), wash_power, GameData.hygiene, GameData.hygiene_stage()]
	_update_progress()
	bucket_icon.queue_redraw()


func _update_progress() -> void:
	progress_label.text = "%d%%" % int(GameData.hygiene)


func _input(event: InputEvent) -> void:
	if not bucket.visible:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and bucket.get_global_rect().has_point(mb.position):
				dragging = true
				drag_offset = bucket.global_position - mb.position
			elif not mb.pressed:
				dragging = false
				last_pet_hit = Vector2.ZERO
	elif event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		bucket.global_position = mm.position + drag_offset
		if pet_canvas.get_global_rect().has_point(mm.position):
			_rub_at(mm.position)


func _rub_at(global_pos: Vector2) -> void:
	if GameData.hygiene >= 100:
		# Уже чистый — пузырьки можно, но гигиена не растёт.
		pass

	var local: Vector2 = pet_canvas.get_global_transform().affine_inverse() * global_pos
	var moved: float = 0.0
	if last_pet_hit != Vector2.ZERO:
		moved = local.distance_to(last_pet_hit)
	last_pet_hit = local
	if moved < MIN_RUB_STEP:
		return

	# Пузырёк в точке трения
	var r := randf_range(10.0, 18.0)
	pet_canvas.add_bubble(local, r)

	# Начисляем гигиену пропорционально движению и силе средства.
	var gain_units: float = moved * (wash_power / 12.0)
	var hygiene_gain: int = int(round(gain_units * (float(WASH_FULL_GAIN) / RUB_FOR_FULL)))
	if hygiene_gain > 0:
		GameData.apply_wash_step(hygiene_gain)
	_update_progress()

	# Обновим текст статуса (там показана гигиена)
	var wash_id: String = GameData.equipped_wash
	if wash_id != "":
		var item: Dictionary = GameData.get_item(wash_id)
		status_label.text = "Средство: %s (сила мытья ×%.0f). Гигиена: %d/100 (%s)." % [
			item.get("name"), wash_power, GameData.hygiene, GameData.hygiene_stage()]


func _finish_wash() -> void:
	pet_canvas.set_wash_state(false)
	wash_finished.emit()
