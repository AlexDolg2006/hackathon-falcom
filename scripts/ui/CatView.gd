class_name CatView
extends Control

var texture_rect: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Создаем единственный узел для картинки
	texture_rect = TextureRect.new()
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(texture_rect)

	update_cat_image()

	if GameData and GameData.has_signal("state_changed"):
		GameData.state_changed.connect(_on_state_changed)


# Загрузка единой картинки кота из папки скина
func update_cat_image() -> void:
	var skin: String = "cat_One"
	if GameData and "selected_skin" in GameData and GameData.selected_skin != "":
		skin = GameData.selected_skin

	var base_path: String = "res://assets/" + skin + "/"
	
	# Список названий файла по приоритету
	var possible_files := ["full.png", "cat.png", "body.png"]
	var loaded_tex: Texture2D = null

	for file_name in possible_files:
		var full_path :String = base_path + file_name
		if ResourceLoader.exists(full_path):
			loaded_tex = load(full_path)
			break

	if texture_rect:
		texture_rect.texture = loaded_tex


func _on_state_changed() -> void:
	update_cat_image()

	# Реакция на статус питомца (слегка меняем оттенок, если кот грустен)
	if GameData and (GameData.mood < 30 or GameData.hunger < 30):
		modulate = Color(0.85, 0.85, 0.95)
	else:
		modulate = Color(1.0, 1.0, 1.0)
