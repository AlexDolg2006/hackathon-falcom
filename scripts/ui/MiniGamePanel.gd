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

func _ready() -> void:
	custom_minimum_size = Vector2(0, 560)
	_build_ui()
	_refresh_availability()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vb)

	var title := Label.new()
	title.text = "Лови монетки!"
	title.add_theme_font_size_override("font_size", 28)
	vb.add_child(title)

	var info := Label.new()
	info.text = "Двигай корзину и лови падающие монеты. Игра доступна один раз в игровой день."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(info)

	var hb := HBoxContainer.new()
	vb.add_child(hb)
	time_label = Label.new()
	time_label.text = "Время: --"
	hb.add_child(time_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spacer)
	score_label = Label.new()
	score_label.text = "Монет: 0"
	hb.add_child(score_label)

	play_area = Control.new()
	play_area.custom_minimum_size = Vector2(0, 380)
	play_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_area.clip_contents = true
	var bg := ColorRect.new()
	bg.color = Color(0.85, 0.93, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	play_area.add_child(bg)
	coins_layer = Control.new()
	coins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	coins_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(coins_layer)
	basket = ColorRect.new()
	basket.color = Color(0.6, 0.4, 0.2)
	basket.size = Vector2(90, 34)
	play_area.add_child(basket)
	play_area.gui_input.connect(_on_play_area_input)
	vb.add_child(play_area)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(status_label)

	start_button = Button.new()
	start_button.text = "Начать игру"
	start_button.pressed.connect(_start_game)
	vb.add_child(start_button)


func _refresh_availability() -> void:
	if GameData.can_play_minigame():
		start_button.disabled = false
		status_label.text = "Готово! У тебя есть одна попытка на сегодня."
	else:
		start_button.disabled = true
		status_label.text = "На сегодня мини-игра уже сыграна. Приходи в следующий день."


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
	status_label.text = "Лови монетки движением пальца по полю!"
	basket.position = Vector2(play_area.size.x * 0.5 - basket.size.x * 0.5, play_area.size.y - basket.size.y - 6)
	basket_target_x = basket.position.x
	set_process(true)


func _on_play_area_input(event: InputEvent) -> void:
	if not playing:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		basket_target_x = event.position.x - basket.size.x * 0.5
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.position:
			basket_target_x = event.position.x - basket.size.x * 0.5


func _process(delta: float) -> void:
	if not playing:
		return
	time_left -= delta
	time_label.text = "Время: %d" % max(0, int(ceil(time_left)))
	score_label.text = "Монет: %d" % score

	basket_target_x = clampf(basket_target_x, 0, max(0, play_area.size.x - basket.size.x))
	basket.position.x = move_toward(basket.position.x, basket_target_x, BASKET_SPEED * delta)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = SPAWN_INTERVAL
		_spawn_coin()

	for c in active_coins.duplicate():
		if not is_instance_valid(c):
			active_coins.erase(c)
			continue
		c.position.y += FALL_SPEED * delta
		var basket_rect := Rect2(basket.position, basket.size)
		if basket_rect.has_point(c.position + Vector2(10, 10)):
			score += 1
			active_coins.erase(c)
			c.queue_free()
		elif c.position.y > play_area.size.y:
			active_coins.erase(c)
			c.queue_free()

	if time_left <= 0.0:
		_end_game()


func _spawn_coin() -> void:
	var coin := ColorRect.new()
	coin.color = Color(1.0, 0.82, 0.15)
	coin.size = Vector2(24, 24)
	var max_x: float = max(1.0, play_area.size.x - coin.size.x)
	coin.position = Vector2(randf() * max_x, -20)
	coins_layer.add_child(coin)
	active_coins.append(coin)


func _end_game() -> void:
	playing = false
	set_process(false)
	GameData.reward_minigame(score)
	status_label.text = "Игра окончена! Поймано монет: %d. Награда начислена в кошелёк." % score
	_refresh_availability()
