extends Control
## Мини-игра: лови монетки. Корзина — мордочка выбранного котика,
## которую можно двигать пальцем/мышью/стрелками.
## Монеты — процедурные увеличенные, с бликом и символом.

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
var basket: Control         # Control (MiniPet)
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
#  МИНИ-ПИТОМЕЦ (Отображает только мордочку выбранного скина)
# ============================================================
class MiniPet extends Control:
	var face_texture: Texture2D

	func _ready() -> void:
		custom_minimum_size = Vector2(180, 160)
		size = Vector2(180, 160)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if GameData and GameData.has_signal("state_changed"):
			GameData.state_changed.connect(update_face_texture)
			
		update_face_texture()

	func update_face_texture() -> void:
		var skin: String = "cat_One"
		if GameData and "selected_skin" in GameData and GameData.selected_skin != "":
			skin = GameData.selected_skin

		var base_path: String = "res://assets/" + skin + "/"
		var texture_path: String = ""

		# Приоритет: совмещенное лицо с ушами faceandears.png, иначе face.png
		if ResourceLoader.exists(base_path + "faceandears.png"):
			texture_path = base_path + "faceandears.png"
		elif ResourceLoader.exists(base_path + "face.png"):
			texture_path = base_path + "face.png"

		if texture_path != "" and ResourceLoader.exists(texture_path):
			face_texture = load(texture_path)
		else:
			face_texture = null

		queue_redraw()

	func _draw() -> void:
		if face_texture:
			draw_texture_rect(face_texture, Rect2(Vector2.ZERO, size), false)


# ============================================================
#  МОНЕТА (процедурная)
# ============================================================
class Coin extends Control:
	var radius: float = 24.0
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
		draw_arc(c, radius - 1.5, 0, TAU, 28, color.darkened(0.35), 2.5)
		# внутренний круг
		draw_arc(c, radius - 6.0, 0, TAU, 24, color.lightened(0.25), 2.0)
		# блик
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
	for c in get_children():
		c.queue_free()

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	# --- 1. Верхняя информационная карточка ---
	var top_card := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.94, 0.94, 0.98)
	top_style.set_corner_radius_all(16)
	top_style.content_margin_left = 14
	top_style.content_margin_right = 14
	top_style.content_margin_top = 10
	top_style.content_margin_bottom = 10
	top_style.shadow_size = 2
	top_style.shadow_color = Color(0, 0, 0, 0.08)
	top_card.add_theme_stylebox_override("panel", top_style)
	vb.add_child(top_card)

	var top_vb := VBoxContainer.new()
	top_vb.add_theme_constant_override("separation", 4)
	top_card.add_child(top_vb)

	var title := Label.new()
	title.text = "🎮 Лови монетки"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.25))
	top_vb.add_child(title)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	top_vb.add_child(status_label)

	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 20)
	top_vb.add_child(hud)

	time_label = Label.new()
	time_label.text = "Время: %.1f" % GAME_TIME
	time_label.add_theme_font_size_override("font_size", 19)
	time_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.2))
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(time_label)

	score_label = Label.new()
	score_label.text = "Монеты: 0"
	score_label.add_theme_font_size_override("font_size", 19)
	score_label.add_theme_color_override("font_color", Color(0.15, 0.55, 0.25))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(score_label)

	# --- 2. Игровая зона в светлой стилистике ---
	var play_wrap := PanelContainer.new()
	play_wrap.custom_minimum_size = Vector2(0, 400)
	play_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_wrap.clip_contents = true

	var play_bg := StyleBoxFlat.new()
	play_bg.bg_color = Color(0.88, 0.90, 0.96)
	play_bg.set_corner_radius_all(20)
	play_bg.shadow_size = 2
	play_bg.shadow_color = Color(0, 0, 0, 0.06)
	play_wrap.add_theme_stylebox_override("panel", play_bg)
	vb.add_child(play_wrap)

	play_area = Control.new()
	play_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	play_area.mouse_filter = Control.MOUSE_FILTER_PASS
	play_wrap.add_child(play_area)

	# слой монет
	coins_layer = Control.new()
	coins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	coins_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(coins_layer)

	# Кот-корзина (теперь отображает только мордочку)
	basket = MiniPet.new()
	basket.custom_minimum_size = Vector2(180, 160)
	basket.size = Vector2(180, 160)
	basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(basket)

	# --- 3. Овальная кнопка старта ---
	start_button = _create_pill_button("Начать игру", Color(0.42, 0.35, 0.82), 60)
	start_button.pressed.connect(_start_game)
	vb.add_child(start_button)

	play_area.resized.connect(_on_play_area_resized)
	call_deferred("_reset_basket_position")


func _create_pill_button(text: String, bg_color: Color, height: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, height)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(height / 2)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.12)

	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.12)

	var style_disabled := style.duplicate() as StyleBoxFlat
	style_disabled.bg_color = Color(0.7, 0.7, 0.75, 0.7)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)

	return btn


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
	coin.radius = randf_range(44.0, 56.0)
	coin.symbol = ""
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if play_area and basket:
			var pos: Vector2 = event.position
			var xf := play_area.get_global_transform().affine_inverse()
			var local: Vector2 = xf * pos
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
