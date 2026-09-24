extends Control

@onready var coins_label: Label = $MarginContainer/VBoxContainer/PanelContainer/TopPanel/CoinsLabel

var coins: int = 500

func _ready() -> void:
	load_game_data()
	update_ui()

func update_ui() -> void:
	coins_label.text = "Монеты: %d" % coins

# Сохранение состояния на устройстве[span_3](start_span)[span_3](end_span)
func save_game_data() -> void:
	var save_file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	var data = {"coins": coins}
	save_file.store_string(JSON.stringify(data))

# Загрузка состояния[span_4](start_span)[span_4](end_span)
func load_game_data() -> void:
	if FileAccess.file_exists("user://save_game.json"):
		var save_file = FileAccess.open("user://save_game.json", FileAccess.READ)
		var parsed = JSON.parse_string(save_file.get_as_text())
		if parsed is Dictionary:
			coins = parsed.get("coins", 500)
			
			
# Вызывается при нажатии на кнопку-кликер
func _on_click_button_pressed() -> void:
	coins += 10          # Добавляем 10 монет
	update_ui()          # Обновляем текст на экране
	save_game_data()     # Сразу сохраняем на телефон

# Вызывается при покупке чего-либо
func _on_buy_button_pressed() -> void:
	if coins >= 100:
		coins -= 100     # Списываем 100 монет за покупку
		update_ui()
		save_game_data()
		print("Успешная покупка!")
	else:
		print("Недостаточно монет!")
