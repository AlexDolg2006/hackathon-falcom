extends Control
## Мини-игра: лови монетки корзиной. Доступна раз в игровой день.

const GAME_TIME := 20.0
const SPAWN_INTERVAL := 0.65
const FALL_SPEED := 260.0
const BASKET_SPEED := 620.0

var play_area: Control
var basket: ColorRect
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

	coins_layer = Control.new()
	coins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	coins_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(coins_layer)

	basket = ColorRect.new()
	basket.color = Color(0.9, 0.6, 0.1)
	basket.size = Vector2(90, 40)
	basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(basket)

	start_button = Button.new()
	start_button.text = "Начать игру"
	start_button.custom_minimum_size = Vector2(0, 64)
	start_button.pressed.connect(_start_game)
	vb.add_child(start_button)

	play_area.resized.connect(_on_play_area_resized)
	# начальная позиция корзины — отложенно, когда play_area получит размер
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
		status_label.text = "Управляй корзиной мышью или стрелками ← →. Поймай как можно больше монет за %.0f секунд!" % GAME_TIME
		start_button.disabled = false
		start_button.text = "Начать игру"
	else:
		status_label.text = "Сегодня мини-игра уже сыграна. Возвращайся в следующий игровой день!"
		start_button.disabled = true
		start_button.text = "Уже сыграно сегодня"


func _start_game() -> void:
	if not GameData.can_play_minigame():
		return
	# очистить поле
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

	# --- Движение корзины к цели ---
	# клавиатура
	if key_left:
		basket_target_x -= BASKET_SPEED * delta
	if key_right:
		basket_target_x += BASKET_SPEED * delta

	var cur_x := basket.position.x
	var new_x := move_toward(cur_x, basket_target_x, BASKET_SPEED * delta)
	new_x = clamp(new_x, 0.0, max(0.0, play_area.size.x - basket.size.x))
	basket.position.x = new_x
	basket.position.y = play_area.size.y - basket.size.y - 8

	# --- Спавн монет ---
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = SPAWN_INTERVAL
		_spawn_coin()

	# --- Падение монет ---
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

	# --- Таймер ---
	time_left -= delta
	time_label.text = "Время: %.1f" % max(time_left, 0.0)
	if time_left <= 0.0:
		_end_game()


func _spawn_coin() -> void:
	var coin := ColorRect.new()
	coin.color = Color(1.0, 0.85, 0.2)
	var r := randf_range(22.0, 30.0)
	coin.size = Vector2(r, r)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
