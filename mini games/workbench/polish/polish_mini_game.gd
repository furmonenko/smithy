# polishing_mini_game.gd
extends MiniGame
class_name PolishingMiniGame

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Типи виробів для полірування
enum ITEM_TYPE { DAGGER = 0, SHORT_SWORD = 1, LONG_SWORD = 2 }

# Стани гри
enum GAME_STATE { POLISHING = 0, COMPLETE = 1 }

# Кнопки для полірування
const POLISH_LEFT_ACTION = "ui_left"  # Можна змінити на "q"
const POLISH_RIGHT_ACTION = "ui_right" # Можна змінити на "e"
const NEXT_REGION_ACTION = "ui_down"   # Кнопка для переходу до наступної полоси

# Налаштування гри
@export var skill_level: int = SKILL_LEVEL.APPRENTICE
@export var item_type: int = ITEM_TYPE.DAGGER
@export var polish_speed: float = 1.0  # Швидкість полірування при кожному русі

# Параметри, що залежать від рівня майстерності
var required_polish_amount: float  # Скільки рухів потрібно для повного полірування секції

# Параметри, що залежать від типу виробу
var total_polish_regions: int      # Кількість смуг/регіонів для полірування

# Змінні для відстеження прогресу
var current_state: int = GAME_STATE.POLISHING
var current_region: int = 0             # Поточна смуга для полірування (індекс)
var polish_progress: Array[float] = []  # Прогрес полірування для кожної смуги (0-100%)
var current_polish_direction: String = "none"  # Поточний напрямок руху (для анімації)
var last_polish_direction: String = "none"     # Останній напрямок руху (для почергового руху)
var current_score: int = 0              # Загальний рахунок

# Змінні для анімації
var cloth_position: float = 0.5    # Положення тряпки від 0.0 (лівий край) до 1.0 (правий край)
var cloth_tween: Tween = null

# Змінні для таймінгу кнопок
var last_polish_time: float = 0.0
var polish_cooldown: float = 0.1  # Мінімальний час між натисканнями

# Змінні для шейдера
var polish_texture: ImageTexture
var noise_texture: NoiseTexture2D

# Таймери
var feedback_timer: Timer
var completion_check_timer: Timer  # Таймер для перевірки завершення гри

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			required_polish_amount = 20.0  # Багато рухів
		SKILL_LEVEL.JOURNEYMAN:
			required_polish_amount = 15.0  # Середня кількість рухів
		SKILL_LEVEL.BLACKSMITH:
			required_polish_amount = 10.0  # Мала кількість рухів
		SKILL_LEVEL.MASTER:
			required_polish_amount = 5.0   # Дуже мала кількість рухів
	
	# Налаштовуємо параметри залежно від типу виробу
	match item_type:
		ITEM_TYPE.DAGGER:
			total_polish_regions = 3  # Маленький виріб, менше смуг
		ITEM_TYPE.SHORT_SWORD:
			total_polish_regions = 4  # Середній виріб
		ITEM_TYPE.LONG_SWORD:
			total_polish_regions = 5  # Великий виріб, більше смуг
	
	# Ініціалізуємо масив прогресу для кожної смуги
	for i in range(total_polish_regions):
		polish_progress.append(0.0)  # 0% на початку
	
	# Створюємо таймер для зворотного зв'язку
	feedback_timer = Timer.new()
	feedback_timer.one_shot = true
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	add_child(feedback_timer)
	
	# Створюємо таймер для перевірки завершення гри
	completion_check_timer = Timer.new()
	completion_check_timer.wait_time = 0.5
	completion_check_timer.one_shot = false
	completion_check_timer.timeout.connect(_on_completion_check_timer_timeout)
	add_child(completion_check_timer)
	
	InputManager.input_type_changed.connect(_on_input_type_changed)
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	# Налаштовуємо шейдер для відображення дефектів на виробі
	setup_shader_for_workpiece()
	
	# Приховуємо на початку
	visible = false
	start_game()

func setup_shader_for_workpiece():
	# Створюємо текстуру шуму для відображення "дефектів"
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	noise.fractal_octaves = 4
	
	noise_texture = NoiseTexture2D.new()
	noise_texture.width = 512
	noise_texture.height = 512
	noise_texture.noise = noise
	
	# Створюємо текстуру для прогресу полірування
	# Текстура повинна мати розмір total_polish_regions x 1 пікселів
	var img = Image.create(total_polish_regions, 1, false, Image.FORMAT_RF)
	for i in range(total_polish_regions):
		img.set_pixel(i, 0, Color(0.0, 0.0, 0.0, 0.0))  # Встановлюємо нульовий прогрес
	
	polish_texture = ImageTexture.create_from_image(img)
	
	# Завантажуємо текстури для виробу відповідно до типу
	var workpiece_texture
	
	match item_type:
		ITEM_TYPE.DAGGER:
			workpiece_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
		ITEM_TYPE.SHORT_SWORD:
			workpiece_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
		ITEM_TYPE.LONG_SWORD:
			workpiece_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
	
	# Якщо текстура не завантажилася, використовуємо заглушку
	if not workpiece_texture:
		workpiece_texture = preload("res://assets/smithing/pngimg.com - sword_PNG5525.png")
	
	# Встановлюємо параметри шейдера
	if has_node("%WorkpieceView") and %WorkpieceView.material:
		var material = %WorkpieceView.material
		
		# Встановлюємо режим на полірування
		material.set_shader_parameter("shader_mode", 2)  # 2 = полірування
		
		# Встановлюємо текстуру виробу
		%WorkpieceView.texture = workpiece_texture
		
		# Налаштовуємо параметри шейдера для відображення дефектів
		material.set_shader_parameter("displacement_noise", noise_texture)
		material.set_shader_parameter("total_regions", total_polish_regions)
		material.set_shader_parameter("current_region", current_region)
		material.set_shader_parameter("cloth_position", cloth_position)
		
		# Встановлюємо текстуру для прогресу полірування
		material.set_shader_parameter("region_polish_texture", polish_texture)

func setup_ui():
	# Налаштовуємо кнопки
	setup_buttons()
	
	# Налаштовуємо прогрес-бар для показу прогресу поточної смуги
	update_progress_bar()
	
	# Налаштовуємо заголовки та інструкції
	%GameTitle.text = "Полірування виробу"
	
	var left_button_name = InputManager.get_button_display_name(POLISH_LEFT_ACTION)
	var right_button_name = InputManager.get_button_display_name(POLISH_RIGHT_ACTION)
	var next_button_name = InputManager.get_button_display_name(NEXT_REGION_ACTION)
	
	%InstructionsLabel.text = "Натискайте %s та %s ПОЧЕРГОВО для руху тряпки\nНатисніть %s щоб перейти до наступної смуги" % [left_button_name, right_button_name, next_button_name]

func setup_buttons():
	# Оновлюємо текстури відповідно до поточного пристрою вводу
	if has_node("%LeftButton"):
		%LeftButton.texture = InputManager.get_button_texture(POLISH_LEFT_ACTION)
	
	if has_node("%RightButton"):
		%RightButton.texture = InputManager.get_button_texture(POLISH_RIGHT_ACTION)
	
	if has_node("%NextButton"):
		%NextButton.texture = InputManager.get_button_texture(NEXT_REGION_ACTION)

func start_game():
	# Показуємо UI
	visible = true
	
	# Ініціалізуємо змінні стану
	current_state = GAME_STATE.POLISHING
	current_region = 0
	polish_progress = []
	last_polish_direction = "none"
	
	# Створюємо новий масив прогресу для кожної смуги
	for i in range(total_polish_regions):
		polish_progress.append(0.0)  # 0% на початку
	
	# Встановлюємо розташування полірувальної тряпки по центру
	cloth_position = 0.5
	
	# Оновлюємо прогрес-бар та індикацію поточної смуги
	update_progress_bar()
	update_region_indicator()
	
	# Оновлюємо шейдер з початковими значеннями
	update_shader_parameters()
	
	# Показуємо початкову підказку
	show_feedback("Почніть полірування ліворуч-праворуч", Color(1, 1, 1))
	
	# Запускаємо таймер для перевірки завершення гри
	completion_check_timer.start()

func _input(event):
	if not visible or current_state != GAME_STATE.POLISHING:
		return
	
	# Отримуємо поточний час для обмеження частоти натискань
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Обробка натискання для руху ліворуч
	if event.is_action_pressed(POLISH_LEFT_ACTION) and current_time - last_polish_time >= polish_cooldown:
		# Перевіряємо, чи був останній рух праворуч або none
		if last_polish_direction == "right" or last_polish_direction == "none":
			move_cloth_left()
			last_polish_time = current_time
			last_polish_direction = "left"
		else:
			# Показуємо підказку, що потрібно рухати в інший бік
			show_feedback("Рухайте тряпку ПОЧЕРГОВО ліворуч-праворуч", Color(1, 0.5, 0))
	
	# Обробка натискання для руху праворуч
	elif event.is_action_pressed(POLISH_RIGHT_ACTION) and current_time - last_polish_time >= polish_cooldown:
		# Перевіряємо, чи був останній рух ліворуч або none
		if last_polish_direction == "left" or last_polish_direction == "none":
			move_cloth_right()
			last_polish_time = current_time
			last_polish_direction = "right"
		else:
			# Показуємо підказку, що потрібно рухати в інший бік
			show_feedback("Рухайте тряпку ПОЧЕРГОВО ліворуч-праворуч", Color(1, 0.5, 0))
	
	# Обробка натискання для переходу до наступної смуги
	elif event.is_action_pressed(NEXT_REGION_ACTION) and current_region < total_polish_regions - 1:
		move_to_next_region()
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func move_cloth_left():
	# Переміщуємо тряпку ліворуч
	var target_position = max(0.0, cloth_position - 0.2)  # Обмежуємо лівий край
	animate_cloth_movement(target_position)
	
	# Додаємо прогрес полірування для поточної смуги
	add_polish_progress()
	
	# Відтворюємо звук полірування
	play_polish_sound()

func move_cloth_right():
	# Переміщуємо тряпку праворуч
	var target_position = min(1.0, cloth_position + 0.2)  # Обмежуємо правий край
	animate_cloth_movement(target_position)
	
	# Додаємо прогрес полірування для поточної смуги
	add_polish_progress()
	
	# Відтворюємо звук полірування
	play_polish_sound()

func animate_cloth_movement(target_position: float):
	# Зупиняємо попередню анімацію, якщо вона існує
	if cloth_tween != null and cloth_tween.is_valid():
		cloth_tween.kill()
	
	# Запам'ятовуємо попередню позицію для визначення напрямку
	var previous_position = cloth_position
	
	# Створюємо нову анімацію руху тряпки
	cloth_tween = create_tween()
	cloth_tween.tween_property(self, "cloth_position", target_position, 0.1)
	cloth_tween.tween_callback(Callable(self, "_update_cloth_position"))
	
	# Визначаємо напрямок руху для оновлення візуальних ефектів
	current_polish_direction = "left" if target_position < previous_position else "right"
	
	# Оновлюємо позицію тряпки в шейдері для візуальних ефектів
	update_shader_parameters()
	
	# Анімуємо кнопку, яка була натиснута
	var button_to_animate = %LeftButton if current_polish_direction == "left" else %RightButton
	var button_tween = create_tween()
	button_tween.tween_property(button_to_animate, "scale", Vector2(1.2, 1.2), 0.05)
	button_tween.tween_property(button_to_animate, "scale", Vector2(1.0, 1.0), 0.1)

func _update_cloth_position():
	# Оновлюємо позицію тряпки в шейдері
	update_shader_parameters()

func add_polish_progress():
	# Обчислюємо кількість прогресу на основі рівня майстерності
	var progress_amount = (polish_speed / required_polish_amount) * 100.0
	
	# Додаємо прогрес до поточної смуги
	polish_progress[current_region] = min(100.0, polish_progress[current_region] + progress_amount)
	
	# Оновлюємо візуальний прогрес
	update_progress_bar()
	
	# Оновлюємо шейдер для відображення прогресу
	update_shader_parameters()
	
	# Перевіряємо, чи досягнуто 100% на поточній смузі
	if polish_progress[current_region] >= 100.0:
		show_feedback("Смуга відполірована! Можна рухатись далі", Color(0, 1, 0))
		
		# Додатково перевіряємо завершення гри для останньої смуги
		if current_region == total_polish_regions - 1:
			check_for_game_completion()

func move_to_next_region():
	# Перевіряємо, чи не перевищуємо кількість смуг
	if current_region >= total_polish_regions - 1:
		return
	
	# Збільшуємо номер поточної смуги
	current_region += 1
	
	# Оновлюємо індикацію поточної смуги
	update_region_indicator()
	
	# Оновлюємо шейдер для відображення нової активної смуги
	update_shader_parameters()
	
	# Починаємо з центру для нової смуги
	cloth_position = 0.5
	_update_cloth_position()
	
	# Скидаємо останній напрямок руху для нової смуги
	last_polish_direction = "none"
	
	# Перевіряємо, чи це остання смуга
	if current_region == total_polish_regions - 1:
		show_feedback("Остання смуга! Відполіруйте її ретельно", Color(1, 0.8, 0))
	else:
		show_feedback("Смуга %d з %d" % [current_region + 1, total_polish_regions], Color(1, 1, 1))
	
	# Перевіряємо, чи це була остання смуга і чи завершена гра
	if current_region == total_polish_regions - 1:
		# Якщо це була остання смуга, перевіряємо, чи все відполіровано
		check_for_game_completion()

func update_region_indicator():
	# Оновлюємо текст, що показує поточну смугу
	if has_node("%RegionLabel"):
		%RegionLabel.text = "Смуга %d з %d" % [current_region + 1, total_polish_regions]

func update_progress_bar():
	# Оновлюємо прогрес-бар поточної смуги
	if has_node("%PolishProgressBar"):
		%PolishProgressBar.value = polish_progress[current_region]

func update_shader_parameters():
	# Оновлюємо параметри шейдера для візуалізації поточного стану
	if has_node("%WorkpieceView") and %WorkpieceView.material:
		var material = %WorkpieceView.material
		
		# Оновлюємо поточну смугу
		material.set_shader_parameter("current_region", current_region)
		
		# Оновлюємо позицію тряпки
		material.set_shader_parameter("cloth_position", cloth_position)
		
		# Встановлюємо напрямок руху (0 = немає, 1 = ліворуч, 2 = праворуч)
		var direction_value = 0
		if current_polish_direction == "left":
			direction_value = 1
		elif current_polish_direction == "right":
			direction_value = 2
		material.set_shader_parameter("polish_direction", direction_value)
		
		# Оновлюємо текстуру прогресу полірування
		var img = Image.create(total_polish_regions, 1, false, Image.FORMAT_RF)
		for i in range(total_polish_regions):
			# Використовуємо R-канал для зберігання прогресу (0-1)
			img.set_pixel(i, 0, Color(polish_progress[i] / 100.0, 0.0, 0.0, 1.0))
		
		polish_texture.update(img)
		
		# Переконуємося, що шейдер використовує оновлену текстуру
		material.set_shader_parameter("region_polish_texture", polish_texture)

func _on_completion_check_timer_timeout():
	# Ця функція викликається регулярно для перевірки, чи завершено гру
	if current_state == GAME_STATE.POLISHING:
		if current_region == total_polish_regions - 1 and polish_progress[current_region] >= 100.0:
			check_for_game_completion()

func check_for_game_completion():
	# Перевіряємо, чи була оброблена остання смуга
	if current_region == total_polish_regions - 1 and polish_progress[current_region] >= 100.0:
		# Зупиняємо таймер перевірки завершення
		completion_check_timer.stop()
		
		# Обчислюємо загальний прогрес (середнє значення)
		var total_progress = 0.0
		for progress in polish_progress:
			total_progress += progress
		
		var average_progress = total_progress / total_polish_regions
		
		# Встановлюємо остаточний рахунок
		current_score = int(average_progress)
		
		# Затримка перед завершенням, щоб показати фінальний стан
		await get_tree().create_timer(1.0).timeout
		
		# Змінюємо стан гри на COMPLETE, щоб зупинити обробку введення
		current_state = GAME_STATE.COMPLETE
		
		# Показуємо фінальний результат
		show_game_result()
	
	# Якщо користувач перейшов до нової смуги, але не завершив попередню на 100%
	elif current_region > 0 and polish_progress[current_region - 1] < 100.0:
		# Показуємо підказку про незавершену смугу
		show_feedback("Увага! Попередня смуга відполірована лише на %d%%" % polish_progress[current_region - 1], Color(1, 0.7, 0))

func show_game_result():
	# Визначаємо якість результату
	var quality_message = ""
	var color = Color.WHITE
	
	if current_score >= 95:
		quality_message = "Ідеальне полірування!"
		color = Color(0, 1, 0)
	elif current_score >= 85:
		quality_message = "Відмінне полірування!"
		color = Color(0.3, 1, 0.3)
	elif current_score >= 70:
		quality_message = "Хороше полірування!"
		color = Color(0.5, 1, 0.5)
	elif current_score >= 50:
		quality_message = "Задовільне полірування"
		color = Color(1, 1, 0)
	else:
		quality_message = "Потрібно більше полірування"
		color = Color(1, 0.5, 0)
	
	# Показуємо фінальний результат
	%FeedbackLabel.text = quality_message + "\nОцінка: " + str(current_score) + " з 100"
	%FeedbackLabel.add_theme_color_override("font_color", color)
	%FeedbackLabel.visible = true
	
	# Створюємо анімацію для привернення уваги
	var tween = create_tween()
	tween.tween_property(%FeedbackLabel, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(%FeedbackLabel, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Зачекаємо трохи та завершимо гру
	await get_tree().create_timer(2.0).timeout
	
	# Завершуємо гру з результатом
	end_game(true, current_score)

func play_polish_sound():
	# Відтворюємо звук полірування, якщо доступний
	if has_node("%PolishSound"):
		# Додаємо невеликий рандом для природності
		%PolishSound.pitch_scale = randf_range(0.95, 1.05)
		%PolishSound.play()

func show_feedback(text: String, color: Color = Color(1, 1, 1)):
	# Показуємо повідомлення для гравця
	%FeedbackLabel.text = text
	%FeedbackLabel.add_theme_color_override("font_color", color)
	%FeedbackLabel.visible = true
	
	# Запускаємо таймер для приховування підказки
	feedback_timer.start(2.0)

func _on_feedback_timer_timeout():
	# Приховуємо повідомлення після затримки
	%FeedbackLabel.visible = false

func _on_input_type_changed(_device_type):
	# Оновлюємо текстури кнопок для нового типу вводу
	setup_buttons()
	
	# Оновлюємо інструкції
	var left_button_name = InputManager.get_button_display_name(POLISH_LEFT_ACTION)
	var right_button_name = InputManager.get_button_display_name(POLISH_RIGHT_ACTION)
	var next_button_name = InputManager.get_button_display_name(NEXT_REGION_ACTION)
	
	%InstructionsLabel.text = "Натискайте %s та %s ПОЧЕРГОВО для руху тряпки\nНатисніть %s щоб перейти до наступної смуги" % [left_button_name, right_button_name, next_button_name]
