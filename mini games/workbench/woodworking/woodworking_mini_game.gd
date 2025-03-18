# woodworking_mini_game.gd
extends MiniGame
class_name WoodworkingMiniGame

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Типи виробів
enum TOOL_TYPE { DAGGER_HANDLE = 0, SHORT_SWORD_HANDLE = 1, LONG_SWORD_HANDLE = 2, AXE_HANDLE = 3, HAMMER_HANDLE = 4 }

# Стани гри
enum GAME_STATE { SELECTING = 0, CUTTING = 1, COMPLETE = 2 }

# Кнопки для вибору полоси
const LEFT_ACTION = "ui_left"
const RIGHT_ACTION = "ui_right"
const CUT_ACTION = "hit_button_a"  # Кнопка E або A для геймпада

# Налаштування гри
@export var skill_level: int = SKILL_LEVEL.APPRENTICE
@export var tool_type: int = TOOL_TYPE.AXE_HANDLE
@export var strips_count: int = 6  # Кількість полос для вирізання
@export var cutting_speed_base: float = 1.0  # Базова швидкість вирізання
@export var cutting_acceleration: float = 0.5  # Прискорення вирізання

# Параметри, що залежать від рівня майстерності
var error_tolerance: float  # Допустима похибка при досягненні кінця полоси (0-1)
var cutting_speed_modifier: float  # Множник швидкості вирізання

# Змінні для відстеження прогресу
var current_state: int = GAME_STATE.SELECTING
var current_strip: int = 0  # Поточна полоса (0 - strips_count-1)
var marker_position: float = 0.0  # Позиція маркера при вирізанні (0 - 1)
var cutting_speed: float = 0.0  # Поточна швидкість вирізання
var cut_strips: Array = []  # Масив успішно вирізаних полос
var current_score: int = 100  # Початковий рахунок (віднімаємо за помилки)
var is_cutting_button_pressed: bool = false  # Чи натиснута кнопка вирізання

# Таймери
var game_timer: Timer
var feedback_timer: Timer

# Вивід тексту та підказок
var tooltip_text: String = ""
var tooltip_color: Color = Color.WHITE

# Змінні для анімації
var marker_tween: Tween = null

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			error_tolerance = 0.075
			cutting_speed_modifier = 1.0
		SKILL_LEVEL.JOURNEYMAN:
			error_tolerance = 0.1 
			cutting_speed_modifier = 0.9
		SKILL_LEVEL.BLACKSMITH:
			error_tolerance = 0.15 
			cutting_speed_modifier = 0.8
		SKILL_LEVEL.MASTER:
			error_tolerance = 0.2 
			cutting_speed_modifier = 0.7
	
	# Налаштовуємо параметри залежно від типу виробу
	match tool_type:
		TOOL_TYPE.DAGGER_HANDLE:
			strips_count = 4
			cutting_speed_base = 0.9
		TOOL_TYPE.SHORT_SWORD_HANDLE:
			strips_count = 5
			cutting_speed_base = 1.0
		TOOL_TYPE.LONG_SWORD_HANDLE:
			strips_count = 6
			cutting_speed_base = 1.1
		TOOL_TYPE.AXE_HANDLE:
			strips_count = 5
			cutting_speed_base = 1.2
		TOOL_TYPE.HAMMER_HANDLE:
			strips_count = 4
			cutting_speed_base = 1.3
	
	# Створюємо і налаштовуємо таймери
	game_timer = Timer.new()
	game_timer.one_shot = false
	game_timer.wait_time = 0.02  # Оновлюємо стан кожні 0.02 секунди (50 FPS)
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	feedback_timer = Timer.new()
	feedback_timer.one_shot = true
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	add_child(feedback_timer)
	
	InputManager.input_type_changed.connect(_on_input_type_changed)
	
	# Ініціалізуємо масив вирізаних полос
	cut_strips.resize(strips_count)
	for i in range(strips_count):
		cut_strips[i] = false
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	# Приховуємо на початку
	visible = false
	
	# Запускаємо гру
	start_game()

func setup_ui():
	# Створюємо та налаштовуємо полоси та маркер
	setup_woodwork_ui()
	
	# Налаштовуємо кнопки
	setup_buttons()

func setup_woodwork_ui():
	# Оновлюємо кількість полос в UI
	%StripsContainer.columns = strips_count
	
	# Очищуємо контейнер від попередніх полос
	for child in %StripsContainer.get_children():
		child.queue_free()
	
	# Створюємо нові полоси
	for i in range(strips_count):
		var strip = create_strip()
		%StripsContainer.add_child(strip)
	
	# Ініціалізуємо маркер поточної полоси
	update_marker_position()

func create_strip() -> Control:
	# Створюємо контейнер для полоси
	var strip_container = VBoxContainer.new()
	strip_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip_container.custom_minimum_size = Vector2(40, 0)
	
	# Створюємо базову полосу (повна висота)
	var strip = ColorRect.new()
	strip.color = Color("#8B4513")  # Коричневий колір дерева
	strip.size_flags_horizontal = Control.SIZE_FILL
	strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Додаємо маркер на кінці полоси
	var end_marker = ColorRect.new()
	end_marker.color = Color(0.2, 0.9, 0.2, 0.6)  # Напівпрозорий зелений
	end_marker.custom_minimum_size = Vector2(0, 20)
	end_marker.size_flags_horizontal = Control.SIZE_FILL
	
	# Додаємо елементи в контейнер
	strip_container.add_child(end_marker)
	strip_container.add_child(strip)
	
	return strip_container

func setup_buttons():
	# Оновлюємо текстури кнопок відповідно до поточного пристрою вводу
	%LeftButton.texture = InputManager.get_button_texture(LEFT_ACTION)
	%RightButton.texture = InputManager.get_button_texture(RIGHT_ACTION)
	%CutButton.texture = InputManager.get_button_texture(CUT_ACTION)
	
	# Оновлюємо інструкції
	var left_button_name = InputManager.get_button_display_name(LEFT_ACTION)
	var right_button_name = InputManager.get_button_display_name(RIGHT_ACTION)
	var cut_button_name = InputManager.get_button_display_name(CUT_ACTION)
	
	%InstructionsLabel.text = "Оберіть полосу (%s/%s) та зажміть %s щоб вирізати.\nВідпустіть на кінці полоси!" % [left_button_name, right_button_name, cut_button_name]

func start_game():
	visible = true
	current_state = GAME_STATE.SELECTING
	current_strip = 0
	marker_position = 0.0
	cutting_speed = 0.0
	current_score = 100
	is_cutting_button_pressed = false
	
	# Скидаємо масив вирізаних полос
	for i in range(strips_count):
		cut_strips[i] = false
	
	# Оновлюємо UI елементи
	update_marker_position()
	
	# Показуємо підказку
	show_tooltip("Оберіть полосу та почніть вирізання", Color.WHITE)
	
	# Запускаємо таймер гри
	game_timer.start()

func _input(event):
	if not visible or current_state == GAME_STATE.COMPLETE:
		return
	
	# Обробка натискання стрілок для вибору полоси
	if current_state == GAME_STATE.SELECTING:
		if event.is_action_pressed(LEFT_ACTION):
			change_strip(-1)
		elif event.is_action_pressed(RIGHT_ACTION):
			change_strip(1)
		elif event.is_action_pressed(CUT_ACTION):
			start_cutting()
	
	# Обробка відпускання кнопки при вирізанні
	elif current_state == GAME_STATE.CUTTING:
		if event.is_action_released(CUT_ACTION):
			finish_cutting()
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func change_strip(direction: int):
	# Змінюємо індекс поточної полоси
	current_strip = (current_strip + direction) % strips_count
	if current_strip < 0:
		current_strip = strips_count - 1
	
	# Перевіряємо, чи не вирізана вже ця полоса
	if cut_strips[current_strip]:
		# Шукаємо наступну невирізану полосу
		for i in range(strips_count):
			var next_strip = (current_strip + direction * (i + 1)) % strips_count
			if next_strip < 0:
				next_strip = strips_count - 1
			
			if not cut_strips[next_strip]:
				current_strip = next_strip
				break
	
	# Оновлюємо позицію маркера
	update_marker_position()
	
	# Відтворюємо звук переміщення
	play_move_sound()

func update_marker_position():
	# Оновлюємо підсвічування поточної полоси
	for i in range(%StripsContainer.get_child_count()):
		var strip_container = %StripsContainer.get_child(i)
		if strip_container is Control:
			if i == current_strip:
				strip_container.modulate = Color(1.0, 1.0, 1.0)  # Звичайна яскравість для поточної полоси
			else:
				strip_container.modulate = Color(0.6, 0.6, 0.6)  # Затемнення для неактивних полос
	
	# Оновлюємо видимість покажчика (видаленої частини)
	for i in range(%StripsContainer.get_child_count()):
		var strip_container = %StripsContainer.get_child(i)
		if strip_container is Control and strip_container.get_child_count() >= 2:
			var strip = strip_container.get_child(1)  # Полоса
			
			if cut_strips[i]:
				# Якщо полоса вже вирізана, змінюємо її колір
				strip.color = Color(0.4, 0.4, 0.4, 0.5)  # Напівпрозорий сірий
			else:
				strip.color = Color("#8B4513")  # Оригінальний колір дерева
	
	# Оновлюємо маркер ріжучого інструмента
	%CutterMarker.visible = false  # Скидаємо видимість
	
	if current_state == GAME_STATE.SELECTING and not cut_strips[current_strip]:
		# У режимі вибору показуємо маркер на початку поточної полоси
		%CutterMarker.visible = true
		
		var strip_container = %StripsContainer.get_child(current_strip)
		if strip_container is Control:
			var strip_global_pos = strip_container.global_position
			var strip_size = strip_container.size
			
			# Розміщуємо маркер біля початку полоси
			%CutterMarker.global_position = Vector2(
				strip_global_pos.x + strip_size.x / 2,
				strip_global_pos.y + strip_size.y - 20  # Біля нижньої частини полоси
			)
	
	elif current_state == GAME_STATE.CUTTING:
		# У режимі вирізання показуємо маркер на поточній позиції вздовж полоси
		%CutterMarker.visible = true
		
		var strip_container = %StripsContainer.get_child(current_strip)
		if strip_container is Control:
			var strip_global_pos = strip_container.global_position
			var strip_size = strip_container.size
			
			# Розміщуємо маркер на поточній висоті вздовж полоси
			%CutterMarker.global_position = Vector2(
				strip_global_pos.x + strip_size.x / 2,
				strip_global_pos.y + strip_size.y * (1.0 - marker_position)  # Inverse position (0=bottom, 1=top)
			)

func start_cutting():
	if cut_strips[current_strip]:
		return  # Ця полоса вже вирізана
	
	current_state = GAME_STATE.CUTTING
	marker_position = 0.0  # Початкова позиція (внизу)
	cutting_speed = cutting_speed_base * cutting_speed_modifier  # Початкова швидкість руху
	is_cutting_button_pressed = true
	
	# Починаємо відтворювати звук вирізання
	play_cutting_sound(true)
	
	# Оновлюємо інструкції
	var cut_button_name = InputManager.get_button_display_name(CUT_ACTION)
	show_tooltip("Відпустіть %s на кінці полоси!" % cut_button_name, Color(0.2, 0.9, 0.2))

func finish_cutting():
	is_cutting_button_pressed = false
	
	# Зупиняємо звук вирізання
	play_cutting_sound(false)
	
	# Оцінюємо точність вирізання
	var success = false
	var quality = 0
	
	# Визначаємо якість вирізання на основі позиції маркера
	if marker_position >= 1.0 - error_tolerance and marker_position <= 1.0 + error_tolerance:
		# Ідеальний результат (в межах допустимої похибки)
		success = true
		quality = 3
		show_tooltip("Ідеальне вирізання!", Color(0, 1, 0))
	elif marker_position >= 0.9 and marker_position < 1.0 - error_tolerance:
		# Дуже хороший результат, але не ідеальний
		success = true
		quality = 2
		show_tooltip("Хороше вирізання!", Color(0.5, 1, 0))
	elif marker_position >= 0.7 and marker_position < 0.9:
		# Прийнятний результат
		success = true
		quality = 1
		show_tooltip("Прийнятне вирізання", Color(1, 1, 0))
	else:
		# Невдача
		success = false
		quality = 0
		
		if marker_position < 0.7:
			show_tooltip("Недостатньо вирізано!", Color(1, 0.5, 0))
		else:  # marker_position > 1.0 + error_tolerance
			show_tooltip("Перевирізано!", Color(1, 0, 0))
		
		# Застосовуємо штраф за невдачу
		current_score = max(0, current_score - 10)
	
	# Позначаємо полосу як вирізану в будь-якому випадку
	cut_strips[current_strip] = true
	
	# Оновлюємо UI
	update_marker_position()
	
	# Перевіряємо, чи всі полоси вирізані
	var all_strips_cut = true
	for cut in cut_strips:
		if not cut:
			all_strips_cut = false
			break
	
	if all_strips_cut:
		# Завершуємо гру, якщо всі полоси вирізані
		finish_game()
	else:
		# Повертаємося до режиму вибору полоси
		current_state = GAME_STATE.SELECTING
		
		# Шукаємо наступну невирізану полосу
		for i in range(strips_count):
			if not cut_strips[i]:
				current_strip = i
				break
		
		update_marker_position()

func _on_game_timer_timeout():
	# Оновлюємо стан міні-гри
	var delta = game_timer.wait_time
	
	if current_state == GAME_STATE.CUTTING and is_cutting_button_pressed:
		# Оновлюємо позицію маркера
		cutting_speed += cutting_acceleration * delta
		marker_position += cutting_speed * delta
		
		# Оновлюємо візуальне відображення
		update_marker_position()
		
		# Автоматичне закінчення вирізання, якщо маркер вийшов за межі
		if marker_position > 1.0 + error_tolerance * 2:
			finish_cutting()


func finish_game():
	# Зупиняємо таймер
	game_timer.stop()
	
	# Показуємо фінальний результат
	show_final_result()
	
	# Змінюємо стан на "завершено"
	current_state = GAME_STATE.COMPLETE
	
	# Очікуємо 2 секунди перед завершенням гри
	await get_tree().create_timer(2.0).timeout
	
	# Завершуємо гру
	end_game(true, current_score)

func show_final_result():
	var quality_message = ""
	var quality_color = Color.WHITE
	
	# Визначаємо якість кінцевого результату на основі рахунку
	if current_score >= 90:
		quality_message = "Майстерна робота!"
		quality_color = Color(0, 1, 0)
	elif current_score >= 70:
		quality_message = "Хороша робота!"
		quality_color = Color(0.5, 1, 0)
	elif current_score >= 50:
		quality_message = "Прийнятна робота"
		quality_color = Color(1, 1, 0)
	else:
		quality_message = "Посередня робота"
		quality_color = Color(1, 0.5, 0)
	
	# Показуємо повідомлення
	show_tooltip(quality_message + "\nРахунок: " + str(current_score) + "/100", quality_color)
	
	# Анімуємо фінальний рахунок
	%ScoreLabel.modulate = quality_color
	var tween = create_tween()
	tween.tween_property(%ScoreLabel, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(%ScoreLabel, "scale", Vector2(1.0, 1.0), 0.2)

func show_tooltip(text: String, color: Color = Color.WHITE):
	%FeedbackLabel.text = text
	%FeedbackLabel.add_theme_color_override("font_color", color)
	%FeedbackLabel.visible = true
	
	# Запускаємо таймер для приховування підказки через якийсь час
	feedback_timer.start(2.0)

func _on_feedback_timer_timeout():
	%FeedbackLabel.visible = false

func _on_input_type_changed(_device_type):
	# Оновлюємо текстури кнопок
	setup_buttons()

func play_move_sound():
	# Відтворюємо звук переміщення (заглушка, додати реальний звук)
	if has_node("%MoveSound"):
		%MoveSound.play()

func play_cutting_sound(start: bool):
	# Відтворюємо звук вирізання (заглушка, додати реальний звук)
	if has_node("%CuttingSound"):
		if start:
			%CuttingSound.play()
		else:
			%CuttingSound.stop()
