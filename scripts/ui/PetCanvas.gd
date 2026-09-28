extends Control
## Рисует котика процедурно: цвет/паттерн, стадия роста, настроение, шапка,
## слой грязи (по уровню гигиены) и пузырьки при мытье.

const BODY_COLORS := [
	Color(0.95, 0.65, 0.35),
	Color(0.55, 0.55, 0.6),
	Color(0.97, 0.94, 0.88),
]

var wash_active: bool = false
var bubbles: Array = []
var _redraw_queued: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(320, 320)
	# Подключаемся к сигналу через именованный метод, а не лямбду —
	# так безопаснее и не создаёт циклических ссылок.
	if not GameData.state_changed.is_connected(_on_state_changed):
		GameData.state_changed.connect(_on_state_changed)
	queue_redraw()


func _exit_tree() -> void:
	if GameData.state_changed.is_connected(_on_state_changed):
		GameData.state_changed.disconnect(_on_state_changed)


func _on_state_changed() -> void:
	# Защита от повторного вызова, если сигнал прилетит несколько раз за кадр.
	if _redraw_queued:
		return
	_redraw_queued = true
	call_deferred("_deferred_redraw")


func _deferred_redraw() -> void:
	_redraw_queued = false
	queue_redraw()


func set_wash_state(active: bool) -> void:
	wash_active = active
	if not active:
		bubbles.clear()
	queue_redraw()


func add_bubble(local_pos: Vector2, radius: float = 14.0) -> void:
	bubbles.append({
		"pos": local_pos,
		"r": radius,
		"life": 1.2,
		"max_life": 1.2,
		"phase": randf() * TAU,
	})
	queue_redraw()


func _process(delta: float) -> void:
	if bubbles.is_empty():
		return
	var alive: Array = []
	for b in bubbles:
		b.life -= delta
		b.pos.y -= 18.0 * delta
		b.pos.x += sin(b.phase + b.life * 4.0) * 12.0 * delta
		if b.life > 0.0:
			alive.append(b)
	bubbles = alive
	queue_redraw()


## Возвращает true, если точка в локальных координатах PetCanvas
## попадает в силуэт кота (тело, голова, уши, хвост).
func is_point_on_pet(local_pos: Vector2) -> bool:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var cy := h * 0.58
	var stage: int = GameData.pet_stage
	var scale_mul := 0.8 + stage * 0.12
	var body_r := 92.0 * scale_mul
	var head_r := 78.0 * scale_mul
	var head_pos := Vector2(cx, cy - head_r * 0.35)

	if _point_in_ellipse(local_pos, Vector2(cx, cy + body_r * 0.35), Vector2(body_r * 0.72, body_r * 0.62)):
		return true
	if _point_in_ellipse(local_pos, head_pos, Vector2(head_r * 0.72, head_r * 0.66)):
		return true
	if local_pos.distance_to(head_pos + Vector2(-head_r * 0.35, -head_r * 0.6)) < head_r * 0.35:
		return true
	if local_pos.distance_to(head_pos + Vector2(head_r * 0.35, -head_r * 0.6)) < head_r * 0.35:
		return true
	if local_pos.distance_to(Vector2(cx + body_r * 1.0, cy + body_r * 0.2)) < body_r * 0.35:
		return true
	return false


func _point_in_ellipse(p: Vector2, center: Vector2, radii: Vector2) -> bool:
	var dx := (p.x - center.x) / radii.x
	var dy := (p.y - center.y) / radii.y
	return dx * dx + dy * dy <= 1.0


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var cy := h * 0.58

	var stage: int = GameData.pet_stage
	var scale_mul := 0.8 + stage * 0.12
	var body_r := 92.0 * scale_mul
	var head_r := 78.0 * scale_mul

	var base_color: Color = BODY_COLORS[GameData.body_color_index % BODY_COLORS.size()]
	var pattern: int = GameData.pattern_index

	var dirt: float = 1.0 - float(GameData.hygiene) / 100.0
	var dirt_color := Color(0.35, 0.28, 0.2, 0.45 * dirt)

	draw_my_ellipse(Vector2(cx, cy + body_r * 0.85), Vector2(body_r * 0.9, body_r * 0.22), Color(0, 0, 0, 0.12))

	draw_my_ellipse(Vector2(cx, cy + body_r * 0.35), Vector2(body_r * 0.72, body_r * 0.62), base_color)
	if dirt > 0.0:
		draw_my_ellipse(Vector2(cx, cy + body_r * 0.35), Vector2(body_r * 0.72, body_r * 0.62), dirt_color)

	var tail_pts := PackedVector2Array([
		Vector2(cx + body_r * 0.55, cy + body_r * 0.35),
		Vector2(cx + body_r * 1.25, cy - body_r * 0.05),
		Vector2(cx + body_r * 1.05, cy + body_r * 0.15),
	])
	draw_colored_polygon(tail_pts, base_color)

	for dx in [-0.35, 0.35]:
		draw_my_ellipse(Vector2(cx + dx * body_r, cy + body_r * 0.85), Vector2(body_r * 0.18, body_r * 0.16), base_color)

	var head_pos := Vector2(cx, cy - head_r * 0.35)
	draw_my_ellipse(head_pos, Vector2(head_r * 0.72, head_r * 0.66), base_color)
	if dirt > 0.0:
		draw_my_ellipse(head_pos, Vector2(head_r * 0.72, head_r * 0.66), dirt_color)

	var pattern_color := base_color.darkened(0.18)
	if pattern == 1:
		draw_my_ellipse(head_pos + Vector2(head_r * 0.35, -head_r * 0.2), Vector2(head_r * 0.16, head_r * 0.13), pattern_color)
		draw_my_ellipse(Vector2(cx - body_r * 0.2, cy + body_r * 0.5), Vector2(body_r * 0.18, body_r * 0.14), pattern_color)
	elif pattern == 2:
		for i in range(3):
			var sx := cx - body_r * 0.3 + i * body_r * 0.28
			draw_rect(Rect2(sx, cy + body_r * 0.05, body_r * 0.12, body_r * 0.55), pattern_color)

	var ear_color := base_color
	var ear_l := PackedVector2Array([
		head_pos + Vector2(-head_r * 0.55, -head_r * 0.35),
		head_pos + Vector2(-head_r * 0.15, -head_r * 0.95),
		head_pos + Vector2(head_r * 0.05, -head_r * 0.35),
	])
	var ear_r := PackedVector2Array([
		head_pos + Vector2(head_r * 0.55, -head_r * 0.35),
		head_pos + Vector2(head_r * 0.15, -head_r * 0.95),
		head_pos + Vector2(-head_r * 0.05, -head_r * 0.35),
	])
	draw_colored_polygon(ear_l, ear_color)
	draw_colored_polygon(ear_r, ear_color)
	draw_colored_polygon(_scale_poly(ear_l, head_pos + Vector2(-head_r*0.2,-head_r*0.5), 0.5), Color(0.95, 0.75, 0.75))
	draw_colored_polygon(_scale_poly(ear_r, head_pos + Vector2(head_r*0.2,-head_r*0.5), 0.5), Color(0.95, 0.75, 0.75))

	var face: String = GameData.mood_face()
	var eye_off := head_r * 0.28
	var eye_y := head_pos.y - head_r * 0.05
	_draw_eye(Vector2(head_pos.x - eye_off, eye_y), face, head_r)
	_draw_eye(Vector2(head_pos.x + eye_off, eye_y), face, head_r)

	draw_colored_polygon(PackedVector2Array([
		head_pos + Vector2(-head_r*0.06, head_r*0.18),
		head_pos + Vector2(head_r*0.06, head_r*0.18),
		head_pos + Vector2(0, head_r*0.28),
	]), Color(0.85, 0.45, 0.5))

	var mouth_y := head_pos.y + head_r * 0.3
	if face == "happy":
		draw_arc(head_pos + Vector2(0, head_r*0.15), head_r * 0.32, 0.2, PI - 0.2, 16, Color(0.35,0.2,0.2), 3.0)
	elif face == "sad":
		draw_arc(head_pos + Vector2(0, head_r*0.5), head_r * 0.28, PI + 0.3, TAU - 0.3, 16, Color(0.35,0.2,0.2), 3.0)
	else:
		draw_line(head_pos + Vector2(-head_r*0.15, mouth_y), head_pos + Vector2(head_r*0.15, mouth_y), Color(0.35,0.2,0.2), 3.0)

	for sign_ in [-1, 1]:
		for i in range(3):
			var yoff := head_r * (0.12 + i * 0.08)
			draw_line(head_pos + Vector2(sign_*head_r*0.35, mouth_y - head_r*0.15 + yoff*0.3),
				head_pos + Vector2(sign_*head_r*0.85, mouth_y - head_r*0.25 + yoff*0.25), Color(0,0,0,0.35), 1.5)

	if GameData.equipped_hat != "" and not wash_active:
		_draw_hat(GameData.equipped_hat, head_pos, head_r)

	if wash_active:
		_draw_foam(cx, cy, body_r, head_pos, head_r)
	for b in bubbles:
		var t: float = clamp(float(b.life) / float(b.max_life), 0.0, 1.0)
		var col := Color(1, 1, 1, 0.55 * t + 0.25)
		draw_circle(b.pos, b.r * (0.6 + 0.4 * t), col)
		draw_arc(b.pos, b.r * (0.6 + 0.4 * t), 0, TAU, 16, Color(0.7, 0.85, 1.0, 0.7 * t), 1.5)
		draw_circle(b.pos + Vector2(-b.r*0.3, -b.r*0.3), b.r * 0.18, Color(1,1,1,0.85 * t))


func _draw_foam(cx: float, cy: float, body_r: float, head_pos: Vector2, head_r: float) -> void:
	var foam_col := Color(0.9, 0.95, 1.0, 0.35)
	draw_my_ellipse(Vector2(cx, cy + body_r * 0.35), Vector2(body_r * 0.72, body_r * 0.62), foam_col)
	draw_my_ellipse(head_pos, Vector2(head_r * 0.72, head_r * 0.66), foam_col)


func _draw_eye(pos: Vector2, face: String, head_r: float) -> void:
	if face == "sad":
		draw_arc(pos, head_r * 0.09, PI * 1.15, PI * 1.85, 10, Color(0.15, 0.1, 0.1), 2.5)
	else:
		draw_circle(pos, head_r * 0.09, Color(0.15, 0.1, 0.1))
		draw_circle(pos + Vector2(-head_r*0.03, -head_r*0.03), head_r * 0.025, Color(1,1,1))


func _draw_hat(hat_id: String, head_pos: Vector2, head_r: float) -> void:
	match hat_id:
		"hat_cap":
			draw_colored_polygon(PackedVector2Array([
				head_pos + Vector2(-head_r*0.55, -head_r*0.55),
				head_pos + Vector2(head_r*0.55, -head_r*0.55),
				head_pos + Vector2(head_r*0.45, -head_r*0.95),
				head_pos + Vector2(-head_r*0.45, -head_r*0.95),
			]), Color(0.25, 0.45, 0.85))
			draw_colored_polygon(PackedVector2Array([
				head_pos + Vector2(head_r*0.1, -head_r*0.58),
				head_pos + Vector2(head_r*0.75, -head_r*0.5),
				head_pos + Vector2(head_r*0.65, -head_r*0.4),
				head_pos + Vector2(head_r*0.05, -head_r*0.48),
			]), Color(0.2, 0.35, 0.7))
		"hat_crown":
			var base_y := head_pos.y - head_r * 0.62
			var pts := PackedVector2Array([
				head_pos + Vector2(-head_r*0.5, base_y + head_r*0.28),
				head_pos + Vector2(-head_r*0.5, base_y),
				head_pos + Vector2(-head_r*0.28, base_y + head_r*0.18),
				head_pos + Vector2(0, base_y - head_r*0.15),
				head_pos + Vector2(head_r*0.28, base_y + head_r*0.18),
				head_pos + Vector2(head_r*0.5, base_y),
				head_pos + Vector2(head_r*0.5, base_y + head_r*0.28),
			])
			draw_colored_polygon(pts, Color(0.95, 0.8, 0.2))
			draw_circle(head_pos + Vector2(0, base_y - head_r*0.1), head_r*0.06, Color(0.8,0.2,0.3))
		"hat_bow":
			var by := head_pos.y - head_r * 0.75
			draw_colored_polygon(PackedVector2Array([
				head_pos + Vector2(-head_r*0.3, by - head_r*0.15),
				head_pos + Vector2(-head_r*0.05, by),
				head_pos + Vector2(-head_r*0.3, by + head_r*0.15),
			]), Color(0.85, 0.3, 0.45))
			draw_colored_polygon(PackedVector2Array([
				head_pos + Vector2(head_r*0.3, by - head_r*0.15),
				head_pos + Vector2(head_r*0.05, by),
				head_pos + Vector2(head_r*0.3, by + head_r*0.15),
			]), Color(0.85, 0.3, 0.45))
			draw_circle(head_pos + Vector2(0, by), head_r*0.08, Color(0.7, 0.2, 0.35))


func _scale_poly(poly: PackedVector2Array, pivot: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(pivot + (p - pivot) * s)
	return out


func draw_my_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 32
	for i in range(steps):
		var a := TAU * i / steps
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)
