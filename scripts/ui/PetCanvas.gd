extends Control
## Рисует котика процедурно: цвет/паттерн, стадия роста, настроение, шапка.

const BODY_COLORS := [
	Color(0.95, 0.65, 0.35), # рыжий
	Color(0.55, 0.55, 0.6),  # серый
	Color(0.97, 0.94, 0.88), # белый
]

func _ready() -> void:
	custom_minimum_size = Vector2(320, 320)
	GameData.state_changed.connect(func(): queue_redraw())
	queue_redraw()


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

	# тень
	draw_my_ellipse(Vector2(cx, cy + body_r * 0.85), Vector2(body_r * 0.9, body_r * 0.22), Color(0, 0, 0, 0.12))

	# тело
	draw_my_ellipse(Vector2(cx, cy + body_r * 0.35), Vector2(body_r * 0.72, body_r * 0.62), base_color)

	# хвост
	var tail_pts := PackedVector2Array([
		Vector2(cx + body_r * 0.55, cy + body_r * 0.35),
		Vector2(cx + body_r * 1.25, cy - body_r * 0.05),
		Vector2(cx + body_r * 1.05, cy + body_r * 0.15),
	])
	draw_colored_polygon(tail_pts, base_color)

	# лапки
	for dx in [-0.35, 0.35]:
		draw_my_ellipse(Vector2(cx + dx * body_r, cy + body_r * 0.85), Vector2(body_r * 0.18, body_r * 0.16), base_color)

	# голова
	var head_pos := Vector2(cx, cy - head_r * 0.35)
	draw_my_ellipse(head_pos, Vector2(head_r * 0.72, head_r * 0.66), base_color)

	# паттерн (пятна / полоски)
	var pattern_color := base_color.darkened(0.18)
	if pattern == 1:
		draw_my_ellipse(head_pos + Vector2(head_r * 0.35, -head_r * 0.2), Vector2(head_r * 0.16, head_r * 0.13), pattern_color)
		draw_my_ellipse(Vector2(cx - body_r * 0.2, cy + body_r * 0.5), Vector2(body_r * 0.18, body_r * 0.14), pattern_color)
	elif pattern == 2:
		for i in range(3):
			var sx := cx - body_r * 0.3 + i * body_r * 0.28
			draw_rect(Rect2(sx, cy + body_r * 0.05, body_r * 0.12, body_r * 0.55), pattern_color)

	# уши
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
	# внутренняя часть ушей
	draw_colored_polygon(_scale_poly(ear_l, head_pos + Vector2(-head_r*0.2,-head_r*0.5), 0.5), Color(0.95, 0.75, 0.75))
	draw_colored_polygon(_scale_poly(ear_r, head_pos + Vector2(head_r*0.2,-head_r*0.5), 0.5), Color(0.95, 0.75, 0.75))

	# мордочка: глаза зависят от настроения
	var face := GameData.mood_face()
	var eye_off := head_r * 0.28
	var eye_y := head_pos.y - head_r * 0.05
	_draw_eye(Vector2(head_pos.x - eye_off, eye_y), face, head_r)
	_draw_eye(Vector2(head_pos.x + eye_off, eye_y), face, head_r)

	# нос
	draw_colored_polygon(PackedVector2Array([
		head_pos + Vector2(-head_r*0.06, head_r*0.18),
		head_pos + Vector2(head_r*0.06, head_r*0.18),
		head_pos + Vector2(0, head_r*0.28),
	]), Color(0.85, 0.45, 0.5))

	# рот
	var mouth_y := head_pos.y + head_r * 0.3
	if face == "happy":
		draw_arc(head_pos + Vector2(0, head_r*0.15), head_r * 0.32, 0.2, PI - 0.2, 16, Color(0.35,0.2,0.2), 3.0)
	elif face == "sad":
		draw_arc(head_pos + Vector2(0, head_r*0.5), head_r * 0.28, PI + 0.3, TAU - 0.3, 16, Color(0.35,0.2,0.2), 3.0)
	else:
		draw_line(head_pos + Vector2(-head_r*0.15, mouth_y), head_pos + Vector2(head_r*0.15, mouth_y), Color(0.35,0.2,0.2), 3.0)

	# усы
	for sign_ in [-1, 1]:
		for i in range(3):
			var yoff := head_r * (0.12 + i * 0.08)
			draw_line(head_pos + Vector2(sign_*head_r*0.35, mouth_y - head_r*0.15 + yoff*0.3),
				head_pos + Vector2(sign_*head_r*0.85, mouth_y - head_r*0.25 + yoff*0.25), Color(0,0,0,0.35), 1.5)

	# шапка
	if GameData.equipped_hat != "":
		_draw_hat(GameData.equipped_hat, head_pos, head_r)


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
