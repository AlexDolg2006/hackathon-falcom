extends Control
## Мини-игра: лови монетки. Корзина — маленький кот с шапкой,
## которого можно двигать пальцем/мышью/стрелками.
## Монеты — процедурные, с бликом и символом.

const GAME_TIME := 20.0
const SPAWN_INTERVAL := 0.65
const FALL_SPEED := 260.0
const BASKET_SPEED := 620.0

const COIN_COLORS := [
	Color(1.00, 0.85, 0.25), # золотая
	Color(0.95, 0.95, 0.98), # серебряная
	Color(1.00, 0.70, 0.20), # бронзовая
]

var play_area: Control
var basket: Control         # теперь Control, а не ColorRect
var coins_layer: Control
var time_label: Label
var score_label: Label
var status_label: Label
var start_button: Button

var time_left := 0.0
var spawn_timer := 0.0
var score := 0
var playing := false
var basket_target_x := 0.0
var active_coins: Array = []
var key_left := false
var key_right := false


# ============================================================
#  МИНИ-КОТ (рисуется процедурно прямо в MiniGamePanel)
# ============================================================
class MiniPet extends Control:
	const BODY_COLORS := [
		Color(0.95, 0.65, 0.35),
		Color(0.55, 0.55, 0.6),
		Color(0.97, 0.94, 0.88),
	]

	func _ready() -> void:
		custom_minimum_size = Vector2(90, 80)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cx := w * 0.5
		var cy := h * 0.55

		var color_idx: int = GameData.body_color_index % BODY_COLORS.size()
		var base: Color = BODY_COLORS[color_idx]
		var pattern: int = GameData.pattern_index

		# тело — овал
		_draw_ellipse(Vector2(cx, cy + h * 0.18), Vector2(w * 0.36, h * 0.30), base)
		# голова — овал
		var head_pos := Vector2(cx, cy - h * 0.05)
		_draw_ellipse(head_pos, Vector2(w * 0.32, h * 0.28), base)

		# уши — треугольники
		var ear_l := PackedVector2Array([
			head_pos + Vector2(-w * 0.24, -h * 0.18),
			head_pos + Vector2(-w * 0.06, -h * 0.40),
			head_pos + Vector2(w * 0.02, -h * 0.14),
		])
		var ear_r := PackedVector2Array([
			head_pos + Vector2(w * 0.24, -h * 0.18),
			head_pos + Vector2(w * 0.06, -h * 0.40),
			head_pos + Vector2(-w * 0.02, -h * 0.14),
		])
		draw_colored_polygon(ear_l, base)
		draw_colored_polygon(ear_r, base)

		# узор — пятно
		if pattern == 1:
			_draw_ellipse(head_pos + Vector2(w * 0.12, -h * 0.06),
				Vector2(w * 0.08, h * 0.06), base.darkened(0.18))
		elif pattern == 2:
			for i in range(2):
				var sx := head_pos.x - w * 0.18 + i * w * 0.20
				draw_rect(Rect2(sx, head_pos.y + h * 0.02, w * 0.04, h * 0.16), base.darkened(0.18))

		# глаза
		draw_circle(head_pos + Vector2(-w * 0.10, -h * 0.02), w * 0.035, Color(0.15, 0.1, 0.1))
		draw_circle(head_pos + Vector2(w * 0.10, -h * 0.02), w * 0.035, Color(0.15, 0.1, 0.1))
		draw_circle(head_pos + Vector2(-w * 0.09, -h * 0.03), w * 0.012, Color(1, 1, 1))
		draw_circle(head_pos + Vector2(w * 0.11, -h * 0.03), w * 0.012, Color(1, 1, 1))

		# нос
		draw_colored_polygon(PackedVector2Array([
			head_pos + Vector2(-w * 0.02, h * 0.06),
			head_pos + Vector2(w * 0.02, h * 0.06),
			head_pos + Vector2(0, h * 0.10),
		]), Color(0.85, 0.45, 0.5))

		# рот-«корзина» — широкая улыбка, в неё падают монетки
		draw_arc(head_pos + Vector2(0, h * 0.10), w * 0.16,
			0.15, PI - 0.15, 18, Color(0.35, 0.2, 0.2), 3.0)
		# «лапки» — две точки внизу
		draw_circle(Vector2(cx - w * 0.18, h - h * 0.12), w * 0.06, base.darkened(0.05))
		draw_circle(Vector2(cx + w * 0.18, h - h * 0.12), w * 0.06, base.darkened(0.05))

		# шапка (если надета)
		_draw_hat(head_pos, w, h)

	func _draw_hat(head_pos: Vector2, w: float, h: float) -> void:
		var hat: String = GameData.equipped_hat
		if hat == "":
			return
		match hat:
			"hat_cap":
				draw_colored_polygon(PackedVector2Array([
					head_pos + Vector2(-w * 0.26, -h * 0.22),
					head_pos + Vector2(w * 0.26, -h * 0.22),
					head_pos + Vector2(w * 0.20, -h * 0.40),
					head_pos + Vector2(-w * 0.20, -h * 0.40),
				]), Color(0.25, 0.45, 0.85))
				draw_colored_polygon(PackedVector2Array([
					head_pos + Vector2(w * 0.04, -h * 0.24),
					head_pos + Vector2(w * 0.36, -h * 0.20),
					head_pos + Vector2(w * 0.30, -h * 0.14),
					head_pos + Vector2(w * 0.02, -h * 0.18),
				]), Color(0.2, 0.35, 0.7))
			"hat_crown":
				var by := head_pos.y - h * 0.26
				var pts := PackedVector2Array([
					head_pos + Vector2(-w * 0.24, by + h * 0.12),
					head_pos + Vector2(-w * 0.24, by),
					head_pos + Vector2(-w * 0.14, by + h * 0.08),
					head_pos + Vector2(0, by - h * 0.08),
					head_pos + Vector2(w * 0.14, by + h * 0.08),
					head_pos + Vector2(w * 0.24, by),
					head_pos + Vector2(w * 0.24, by + h * 0.12),
				])
				draw_colored_polygon(pts, Color(0.95, 0.8, 0.2))
				draw_circle(head_pos + Vector2(0, by - h * 0.04), w * 0.025, Color(0.8, 0.2, 0.3))
			"hat_bow":
				var by2 := head_pos.y - h * 0.32
				draw_colored_polygon(PackedVector2Array([
					head_pos + Vector2(-w * 0.14, by2 - h * 0.06),
					head_pos + Vector2(-w * 0.02, by2),
					head_pos + Vector2(-w * 0.14, by2 + h * 0.06),
				]), Color(0.85, 0.3, 0.45))
				draw_colored_polygon(PackedVector2Array([
					head_pos + Vector2(w * 0.14, by2 - h * 0.06),
					head_pos + Vector2(w * 0.02, by2),
					head_pos + Vector2(w * 0.14, by2 + h * 0.06),
				]), Color(0.85, 0.3, 0.45))
				draw_circle(head_pos + Vector2(0, by2), w * 0.035, Color(0.7, 0.2, 0.35))

	func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		var steps := 28
		for i in range(steps):
			var a := TAU * i / steps
			pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
		draw_colored_polygon(pts, color)


# ============================================================
#  МОНЕТА (процедурная, с бликом и символом)
# ============================================================
class Coin extends Control:
	var radius: float = 16.0
	var color: Color = Color(1.0, 0.85, 0.25)
	var symbol: String = "₽"
	var _t: float = 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(radius * 2, radius * 2)
		size = Vector2(radius * 2, radius * 2)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		# тень
		draw_circle(c + Vector2(1, 2), radius, Color(0, 0, 0, 0.25))
		# тело монеты
		draw_circle(c, radius, color)
		# тёмный ободок
		draw_arc(c, radius - 1.5, 0, TAU, 28, color.darkened(0.35), 2.0)
		# внутренний круг
		draw_arc(c, radius - 5.0, 0, TAU, 24, color.lightened(0.25), 1.5)
		# блик, который «бегает»
		var blik_a := _t * 2.0
		var blik_pos := c + Vector2(cos(blik_a) * radius * 0.35, sin(blik_a) * radius * 0.35)
		draw_circle(blik_pos, radius * 0.18, Color(1, 1, 1, 0.55))
		# символ по центру
		var font := ThemeDB.fallback_font
		var fs := int(radius * 1.1)
		var text_size := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var pos := c + Vector2(-text_size.x * 0.5, text_size.y * 0.35)
		draw_string(font, pos, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color.darkened(0.5))


# ============================================================
#  ЛОГИКА ПАНЕЛИ
# ============================================================

func _ready() -> void:
	custom_minimum_size = Vector2(0, 560)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	GameData.state_changed.connect(_refresh_availability)
	_refresh_availability()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	var title := Label.new()
	title.text = "Лови монетки"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(status_label)

	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 20)
	vb.add_child(hud)
	time_label = Label.new()
	time_label.text = "Время: %.1f" % GAME_TIME
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(time_label)
	score_label = Label.new()
	score_label.text = "Монеты: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(score_label)

	# Игровая зона
	play_area = Control.new()
	play_area.custom_minimum_size = Vector2(0, 400)
	play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_area.clip_contents = true
	play_area.mouse_filter = Control.MOUSE_FILTER_PASS
	vb.add_child(play_area)

	# слой монет
	coins_layer = Control.new()
	coins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	coins_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(coins_layer)

	# кот-корзина
	basket = MiniPet.new()
	basket.custom_minimum_size = Vector2(90, 80)
	basket.size = Vector2(90, 80)
	basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(basket)

	start_button = Button.new()
	start_button.text = "Начать игру"
	start_button.custom_minimum_size = Vector2(0, 64)
	start_button.pressed.connect(_start_game)
	vb.add_child(start_button)

	play_area.resized.connect(_on_play_area_resized)
	call_deferred("_reset_basket_position")


func _on_play_area_resized() -> void:
	_reset_basket_position()


func _reset_basket_position() -> void:
	if not basket or not play_area:
		return
	basket_target_x = play_area.size.x * 0.5 - basket.size.x * 0.5
	basket.position = Vector2(basket_target_x, play_area.size.y - basket.size.y - 8)


func _refresh_availability() -> void:
	if playing:
		return
	if GameData.can_play_minigame():
		status_label.text = "Управляй котиком: мышь или ← →. Поймай как можно больше монеток за %.0f секунд!" % GAME_TIME
		start_button.disabled = false
		start_button.text = "Начать игру"
	else:
		status_label.text = "Сегодня мини-игра уже сыграна. Возвращайся в следующий игровой день!"
		start_button.disabled = true
		start_button.text = "Уже сыграно сегодня"


func _start_game() -> void:
	if not GameData.can_play_minigame():
		return
	for c in active_coins:
		if is_instance_valid(c):
			c.queue_free()
	active_coins.clear()
	score = 0
	time_left = GAME_TIME
	spawn_timer = 0.0
	playing = true
	start_button.disabled = true
	status_label.text = "Лови!"
	score_label.text = "Монеты: 0"
	time_label.text = "Время: %.1f" % GAME_TIME
	_reset_basket_position()


func _process(delta: float) -> void:
	if not playing:
		return

	# движение корзины
	if key_left:
		basket_target_x -= BASKET_SPEED * delta
	if key_right:
		basket_target_x += BASKET_SPEED * delta

	var cur_x := basket.position.x
	var new_x := move_toward(cur_x, basket_target_x, BASKET_SPEED * delta)
	new_x = clamp(new_x, 0.0, max(0.0, play_area.size.x - basket.size.x))
	basket.position.x = new_x
	basket.position.y = play_area.size.y - basket.size.y - 8

	# спавн
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = SPAWN_INTERVAL
		_spawn_coin()

	# падение монет
	for coin in active_coins.duplicate():
		if not is_instance_valid(coin):
			active_coins.erase(coin)
			continue
		coin.position.y += FALL_SPEED * delta
		if coin.position.y > play_area.size.y:
			active_coins.erase(coin)
			coin.queue_free()
		elif coin.get_rect().intersects(basket.get_rect()):
			score += 1
			score_label.text = "Монеты: %d" % score
			active_coins.erase(coin)
			coin.queue_free()

	# таймер
	time_left -= delta
	time_label.text = "Время: %.1f" % max(time_left, 0.0)
	if time_left <= 0.0:
		_end_game()


func _spawn_coin() -> void:
	var coin := Coin.new()
	var idx := randi() % COIN_COLORS.size()
	coin.color = COIN_COLORS[idx]
	coin.radius = randf_range(14.0, 20.0)
	coin.symbol = ""
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# пересчитаем размеры после задания радиуса
	coin.custom_minimum_size = Vector2(coin.radius * 2, coin.radius * 2)
	coin.size = Vector2(coin.radius * 2, coin.radius * 2)
	var max_x: float = max(0.0, play_area.size.x - coin.size.x)
	coin.position = Vector2(randf_range(0.0, max_x), -coin.size.y)
	coins_layer.add_child(coin)
	active_coins.append(coin)


func _end_game() -> void:
	playing = false
	for c in active_coins:
		if is_instance_valid(c):
			c.queue_free()
	active_coins.clear()
	GameData.reward_minigame(score)
	status_label.text = "Игра окончена! Поймано монет: %d" % score
	_refresh_availability()


func _input(event: InputEvent) -> void:
	if not playing:
		return
	if event is InputEventMouseMotion:
		if play_area and basket:
			var mm := event as InputEventMouseMotion
			var xf := play_area.get_global_transform().affine_inverse()
			var local: Vector2 = xf * mm.position
			basket_target_x = local.x - basket.size.x * 0.5
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.keycode == KEY_LEFT or ke.keycode == KEY_A:
			key_left = ke.pressed
		elif ke.keycode == KEY_RIGHT or ke.keycode == KEY_D:
			key_right = ke.pressed


func _exit_tree() -> void:
	if GameData.state_changed.is_connected(_refresh_availability):
		GameData.state_changed.disconnect(_refresh_availability)
