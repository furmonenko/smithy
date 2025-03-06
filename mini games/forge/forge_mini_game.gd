# forge_mini_game.gd
extends MiniGame
class_name ForgeMiniGame

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Типи зброї для розігріву
enum WEAPON_TYPE { DAGGER = 0, SHORT_SWORD = 1, LONG_SWORD = 2 }

# Стани гри
enum GAME_STATE { IDLE = 0, HEATING = 1, COMPLETE = 2 }

# Кнопка для активації міхів
const BELLOWS_ACTION = "hit_button_x"
# Кнопка для вилучення заготовки з горна
const EXTRACT_ACTION = "hit_button_b"

# Налаштування гри
@export var skill_level: int = SKILL_LEVEL.APPRENTICE
@export var weapon_type: int = WEAPON_TYPE.DAGGER
@export var heating_power: float = 5.0  # Базова швидкість нагріву при активації міхів (% в секунду)
@export var cooling_power: float = 1.0  # Базова швидкість охолодження (% в секунду)
@export var bellows_duration: float = 3.0  # Тривалість ефекту від одного натискання на міхи

# Параметри, що залежать від рівня майстерності
var target_heat_range_min: float  # Мінімальний цільовий рівень нагріву
var target_heat_range_max: float  # Максимальний цільовий рівень нагріву
var overheat_threshold: float     # Поріг перегріву
var heat_falloff_speed: float     # Швидкість зменшення ефекту нагріву

# Параметри, що залежать від типу зброї
var heating_difficulty: float     # Множник складності (впливає на швидкість нагріву/охолодження)

# Змінні для відстеження прогресу
var current_heat_level: float = 0.0     # Поточний рівень нагріву (0-100%)
var current_state: int = GAME_STATE.IDLE
var bellows_active_time: float = 0.0    # Відлік часу дії міхів
var bellows_power: float = 0.0          # Поточна сила нагріву від міхів
var current_score: int = 0              # Рахунок гравця
var heating_time: float = 0.0           # Загальний час нагріву

# Таймери
var game_timer: Timer
var tooltip_timer: Timer

# Змінні для відстеження анімації міхів
var bellows_tween: Tween = null

# Опис функцій-обробників подій, які викликаються пізніше
func _on_tooltip_timer_timeout():
	%TooltipLabel.visible = false

func _on_input_type_changed(_device_type):
	# Оновлюємо текстури кнопок
	setup_buttons()
	
	# Оновлюємо інструкції відповідно до нового пристрою вводу
	var bellows_button_name = InputManager.get_button_display_name(BELLOWS_ACTION)
	var extract_button_name = InputManager.get_button_display_name(EXTRACT_ACTION)
	%InstructionsLabel.text = "Натисніть %s для активації міхів\nНатисніть %s коли досягнете потрібної температури" % [bellows_button_name, extract_button_name]

func _on_game_timer_timeout():
	# Час гри йде вперед
	var delta = game_timer.wait_time
	heating_time += delta
	
	# Обробляємо поточний стан
	match current_state:
		GAME_STATE.IDLE:
			# В режимі очікування трохи охолоджуємо заготовку
			if current_heat_level > 0:
				current_heat_level = max(0.0, current_heat_level - cooling_power * delta)
				update_heat_indicator()
		
		GAME_STATE.HEATING:
			# Зменшуємо час дії міхів
			bellows_active_time = max(0.0, bellows_active_time - delta)
			
			# Зменшуємо ефект міхів з часом
			var falloff_rate = heat_falloff_speed * delta
			bellows_power = max(0.0, bellows_power - falloff_rate)
			
			# Додаємо невеликі випадкові коливання для реалістичності
			var heat_fluctuation = randf_range(-0.2, 0.5) # Трохи асиметричні коливання, щоб нагрів був сильнішим
			
			# Збільшуємо нагрів з урахуванням коливань
			current_heat_level = min(120.0, current_heat_level + (bellows_power + heat_fluctuation) * delta)
			update_heat_indicator()
	
	# Автоматичне завершення гри при критичному перегріві
	if current_heat_level > overheat_threshold:
		extract_workpiece()

func update_heat_indicator():
	# Оновлюємо шейдер для відображення нагріву
	if has_node("%HeatIndicator") and %HeatIndicator.material:
		var normalized_heat = current_heat_level / 100.0
		%HeatIndicator.material.set_shader_parameter("heat_amount", normalized_heat)
		
# Функції для допоміжних методів, які викликаються в інших місцях
func _update_heat_amount(heat: float):
	if has_node("%HeatIndicator") and %HeatIndicator.material:
		%HeatIndicator.material.set_shader_parameter("heat_amount", heat)

func _update_fire_intensity(intensity: float):
	if has_node("%HeatIndicator") and %HeatIndicator.material:
		%HeatIndicator.material.set_shader_parameter("heat_glow_intensity", intensity)

func animate_heat_indicator_hint():
	# Функція для анімації початкового нагріву як підказки гравцю
	# Показуємо короткочасну анімацію нагріву, щоб гравець розумів, що заготовка може нагріватись
	if has_node("%HeatIndicator") and %HeatIndicator.material:
		var tween = create_tween()
		# Показуємо короткий спалах вогню
		tween.tween_method(Callable(self, "_update_heat_amount"), 0.0, 0.3, 0.5)
		tween.tween_method(Callable(self, "_update_heat_amount"), 0.3, 0.0, 0.7)

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			target_heat_range_min = 95.0
			target_heat_range_max = 105.0
			overheat_threshold = 110.0
			heat_falloff_speed = 0.5
		SKILL_LEVEL.JOURNEYMAN:
			target_heat_range_min = 97.0
			target_heat_range_max = 103.0
			overheat_threshold = 108.0
			heat_falloff_speed = 0.7
		SKILL_LEVEL.BLACKSMITH:
			target_heat_range_min = 98.0
			target_heat_range_max = 102.0
			overheat_threshold = 107.0
			heat_falloff_speed = 0.9
		SKILL_LEVEL.MASTER:
			target_heat_range_min = 99.0
			target_heat_range_max = 101.0
			overheat_threshold = 105.0
			heat_falloff_speed = 1.1
	
	# Налаштовуємо параметри залежно від типу зброї
	match weapon_type:
		WEAPON_TYPE.DAGGER:
			heating_difficulty = 1.0
		WEAPON_TYPE.SHORT_SWORD:
			heating_difficulty = 1.2
		WEAPON_TYPE.LONG_SWORD:
			heating_difficulty = 1.5
	
	# Створюємо і налаштовуємо таймери
	game_timer = Timer.new()
	game_timer.one_shot = false
	game_timer.wait_time =.1  # Оновлюємо стан кожні 0.1 секунди
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = 2.0
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)
	
	InputManager.input_type_changed.connect(_on_input_type_changed)
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	setup_shader_for_workpiece()
	
	# Приховуємо на початку
	visible = false
	start_game()

func setup_shader_for_workpiece():
	# Створюємо текстуру шуму для відображення "тепла"
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	noise.fractal_octaves = 3
	
	var noise_texture = NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.noise = noise
	
	# Завантажуємо текстури для заготовки відповідно до типу зброї
	var billet_texture
	
	match weapon_type:
		WEAPON_TYPE.DAGGER:
			billet_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
		WEAPON_TYPE.SHORT_SWORD:
			billet_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
		WEAPON_TYPE.LONG_SWORD:
			billet_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
	
	# Якщо текстура не завантажилася, використовуємо заглушку
	if not billet_texture:
		billet_texture = preload("res://assets/smithing/pngimg.com - sword_PNG5525.png")
	
	# Встановлюємо параметри шейдера
	if has_node("%HeatIndicator") and %HeatIndicator.material:
		var material = %HeatIndicator.material
		
		# Встановлюємо текстуру заготовки
		%HeatIndicator.texture = billet_texture
		
		# Налаштовуємо параметри шейдера для відображення нагріву
		material.set_shader_parameter("heat_amount", 0.0)
		material.set_shader_parameter("heat_at_top", false) 
		material.set_shader_parameter("heat_spread", 0.5)   
		material.set_shader_parameter("heat_gradient_power", 0.3) 
		material.set_shader_parameter("heat_gradient_smooth", 0.9)
		material.set_shader_parameter("forge_center", Vector2(0.5, 0.5))  # Встановлюємо центр нагріву
		material.set_shader_parameter("heat_min_level", 0.2)
		material.set_shader_parameter("heat_gradient_power", 0.8)
		material.set_shader_parameter("heat_gradient_smooth", 0.7)
		material.set_shader_parameter("heat_glow_threshold", 0.3)
		material.set_shader_parameter("heat_glow_intensity", 0.6)
		material.set_shader_parameter("heat_color_intensity", 0.85)
		
		material.set_shader_parameter("displacement_noise", noise_texture)
		
		# Налаштовуємо додаткові візуальні ефекти в залежності від типу зброї
		match weapon_type:
			WEAPON_TYPE.DAGGER:
				# Маленька заготовка - більша деформація
				material.set_shader_parameter("initial_deform", Vector2(1.5, 1.5))
				material.set_shader_parameter("impact_radius", 0.5)
			WEAPON_TYPE.SHORT_SWORD:
				# Середня заготовка
				material.set_shader_parameter("initial_deform", Vector2(1.2, 1.2))
				material.set_shader_parameter("impact_radius", 0.4)
			WEAPON_TYPE.LONG_SWORD:
				# Довга заготовка - менша деформація
				material.set_shader_parameter("initial_deform", Vector2(1.0, 1.0))
				material.set_shader_parameter("impact_radius", 0.3)
		
		material.set_shader_parameter("forge_progress", 0.0)
		
func setup_ui():
	# Налаштовуємо кнопки
	setup_buttons()

func setup_buttons():
	# Приховуємо всі кнопки спочатку
	%BellowsButton.visible = false
	%ExtractButton.visible = false
	
	# Оновлюємо текстури відповідно до поточного пристрою вводу
	%BellowsButton.texture = InputManager.get_button_texture(BELLOWS_ACTION)
	%ExtractButton.texture = InputManager.get_button_texture(EXTRACT_ACTION)
	
	# Показуємо потрібні кнопки
	%BellowsButton.visible = true
	%ExtractButton.visible = true
	
	# Текст підказки під час нагріву
	var bellows_button_name = InputManager.get_button_display_name(BELLOWS_ACTION)
	var extract_button_name = InputManager.get_button_display_name(EXTRACT_ACTION)
	%InstructionsLabel.text = "Натисніть %s для активації міхів\nНатисніть %s коли досягнете потрібної температури" % [bellows_button_name, extract_button_name]

func start_game():
	visible = true
	current_heat_level = 0.0
	current_state = GAME_STATE.IDLE
	bellows_active_time = 0.0
	bellows_power = 0.0
	current_score = 0
	heating_time = 0.0
	
	# Запускаємо таймер гри
	game_timer.start()
	
	# Показуємо кнопку для активації міхів
	%BellowsButton.visible = true
	%ExtractButton.visible = true
	
	# Встановлюємо початковий текст
	show_tooltip("Розігрійте заготовку до %d-%d%%" % [target_heat_range_min, target_heat_range_max])
	
	# Додаємо анімацію початкового нагріву для підказки
	animate_heat_indicator_hint()

func _input(event):
	if not visible or current_state == GAME_STATE.COMPLETE:
		return
	
	# Обробка натискання для активації міхів
	if event.is_action_pressed(BELLOWS_ACTION):
		activate_bellows()
	
	# Обробка натискання для вилучення заготовки
	elif event.is_action_pressed(EXTRACT_ACTION):
		extract_workpiece()
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func activate_bellows():
	current_state = GAME_STATE.HEATING
	
	# Встановлюємо потужність міхів на максимум з урахуванням складності
	var adjusted_power = heating_power * heating_difficulty
	
	# Додатково коригуємо потужність залежно від поточної температури
	# При високій температурі кожна активація міхів дає менший ефект
	if current_heat_level > 85:
		adjusted_power *= 0.7  # 70% ефективності при наближенні до цільової температури
	elif current_heat_level > 60:
		adjusted_power *= 0.85  # 85% ефективності при середній температурі
	
	bellows_power = adjusted_power
	bellows_active_time = bellows_duration
	
	# Запускаємо анімацію міхів
	animate_bellows()
	
	# Показуємо підказку з оцінкою поточної температури
	if current_heat_level < target_heat_range_min * 0.5:
		show_tooltip("Потрібно більше нагрівати!", Color(1, 0.5, 0))
	elif current_heat_level < target_heat_range_min * 0.8:
		show_tooltip("Заготовка нагрівається...", Color(1, 0.7, 0))
	elif current_heat_level < target_heat_range_min:
		show_tooltip("Майже досягнуто потрібної температури!", Color(1, 0.9, 0))
	elif current_heat_level <= target_heat_range_max:
		show_tooltip("Ідеальна температура! Можна витягувати!", Color(0, 1, 0))
	else:
		show_tooltip("Обережно! Можливий перегрів!", Color(1, 0, 0))

func extract_workpiece():
	# Зупиняємо таймер
	game_timer.stop()
	
	# Зупиняємо всі tween анімації
	var existing_tweens = get_tree().get_processed_tweens()
	for tween in existing_tweens:
		if tween.is_valid():
			tween.kill()
	
	# Визначаємо успішність завершення
	var success = false
	var final_score = 0
	var quality_message = ""
	var color = Color.WHITE
	
	# Якщо мало часу нагріву (менше 3 секунд), знижуємо оцінку
	var time_penalty = 0
	if heating_time < 3.0:
		time_penalty = 10
	
	if current_heat_level >= target_heat_range_min and current_heat_level <= target_heat_range_max:
		# Ідеальний нагрів - максимальні очки
		success = true
		final_score = 100 - time_penalty
		quality_message = "Ідеальний нагрів!"
		color = Color(0, 1, 0)
		
		# Додаємо бонус за точність (якщо майже в центрі цільового діапазону)
		var perfect_center = (target_heat_range_min + target_heat_range_max) / 2
		var center_diff = abs(current_heat_level - perfect_center)
		var center_tolerance = (target_heat_range_max - target_heat_range_min) / 4
		
		if center_diff < center_tolerance:
			final_score = min(100, final_score + 5)
			quality_message = "Бездоганний нагрів! +5 очок за точність"
		
	elif current_heat_level > target_heat_range_max and current_heat_level <= overheat_threshold:
		# Перегрів, але в межах допустимого
		success = true
		
		# Чим ближче до ідеального, тим більше очок
		var score_percentage = 1.0 - (current_heat_level - target_heat_range_max) / (overheat_threshold - target_heat_range_max)
		final_score = int(65 + score_percentage * 30) - time_penalty
		
		quality_message = "Заготовка трохи перегріта!"
		color = Color(1, 0.8, 0)
		
	elif current_heat_level < target_heat_range_min:
		# Недостатній нагрів
		success = true
		
		# Чим ближче до ідеального, тим більше очок
		var score_percentage = current_heat_level / target_heat_range_min
		final_score = int(score_percentage * 65) - time_penalty
		
		quality_message = "Заготовка недостатньо нагріта!"
		color = Color(1, 0.5, 0)
		
	else:
		# Критичний перегрів - гра програна
		success = false
		final_score = 0
		quality_message = "Заготовка згоріла від перегріву!"
		color = Color(1, 0, 0)
	
	# Показуємо детальний результат гравцеві
	show_detailed_result(quality_message, final_score, color)
	
	# Коригуємо повернення температури до 100% для подальшої обробки
	if current_heat_level > target_heat_range_max and current_heat_level <= overheat_threshold:
		current_heat_level = 100.0
	
	current_state = GAME_STATE.COMPLETE
	current_score = final_score
	
	# Приховуємо кнопки
	%BellowsButton.visible = false
	%ExtractButton.visible = false
	
	# Очікуємо 2 секунди перед завершенням гри
	await get_tree().create_timer(2.0).timeout
	
	# Завершуємо гру
	end_game(success, final_score)

func animate_bellows():
	# Анімація кнопки міхів
	if bellows_tween != null and bellows_tween.is_valid():
		bellows_tween.kill()
	
	bellows_tween = create_tween()
	bellows_tween.tween_property(%BellowsButton, "scale", Vector2(1.2, 1.2), 0.1)
	bellows_tween.tween_property(%BellowsButton, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Додаємо інтенсивність вогню в шейдері
	if has_node("%HeatIndicator") and %HeatIndicator.material:
		var current_glow = %HeatIndicator.material.get_shader_parameter("heat_glow_intensity")
		var tween = create_tween()
		tween.tween_method(Callable(self, "_update_fire_intensity"), current_glow, current_glow + 0.3, 0.2)
		tween.tween_method(Callable(self, "_update_fire_intensity"), current_glow + 0.3, current_glow, 0.5)
	
func show_tooltip(text: String, color: Color = Color(1, 1, 1)):
	%TooltipLabel.text = text
	%TooltipLabel.add_theme_color_override("font_color", color)
	%TooltipLabel.visible = true
	
	# Запускаємо таймер для приховування підказки
	tooltip_timer.start()
	
func show_detailed_result(quality_message: String, score: int, color: Color):
	# Ця функція показує детальний результат з анімацією
	%TooltipLabel.text = quality_message
	%TooltipLabel.add_theme_color_override("font_color", color)
	%TooltipLabel.visible = true
	
	# Анімуємо збільшення тексту для привернення уваги
	var tween = create_tween()
	tween.tween_property(%TooltipLabel, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(%TooltipLabel, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Додаємо анімацію фінального ефекту нагріву - спалах
	if has_node("%HeatIndicator") and %HeatIndicator.material:
		var heat_tween = create_tween()
		var current_heat = %HeatIndicator.material.get_shader_parameter("heat_amount")
		
		if score > 90:
			# Ідеальний результат - красивий золотий спалах
			heat_tween.tween_method(Callable(self, "_update_heat_amount"), current_heat, 1.0, 0.3)
			heat_tween.tween_method(Callable(self, "_update_heat_amount"), 1.0, current_heat, 0.5)
			
		elif score > 0:
			# Звичайний результат - невеликий спалах
			heat_tween.tween_method(Callable(self, "_update_heat_amount"), current_heat, current_heat + 0.2, 0.3)
			heat_tween.tween_method(Callable(self, "_update_heat_amount"), current_heat + 0.2, current_heat, 0.5)
			
		else:
			# Провал - ефект згоряння
			heat_tween.tween_method(Callable(self, "_update_heat_amount"), current_heat, 1.2, 0.3)
			heat_tween.tween_method(Callable(self, "_update_heat_amount"), 1.2, 0.1, 0.7)
	
	# Додаємо другий рядок з оцінкою після короткої паузи
	await get_tree().create_timer(0.5).timeout
	%TooltipLabel.text = quality_message + "\nОцінка: " + str(score) + " з 100"

func play_bellows_sound(intensity_factor: float = 1.0):
	# Заглушка для звуку міхів
	# Тут можна додати звуки в майбутньому
	
	# Заглушка для ефекту тряски камери
	# create_camera_shake(0.2, min(current_heat_level / 50.0, 0.5))
	
	# Заглушка для звуку вогню при високій температурі
	# Тут можна додати звуки в майбутньому
	
	# Заглушка для звуку шипіння металу
	# Тут можна додати звуки в майбутньому
	pass

func create_camera_shake(duration: float, intensity: float):
	# Функція для створення ефекту тряски камери
	# Ця функція може бути реалізована, якщо в грі є система камери
	# Як простий варіант, можемо трохи похитати UI
	if has_node("UI"):
		var original_position = $UI.position
		var tween = create_tween()
		
		# Швидка тряска
		for i in range(5):
			var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * 10.0
			tween.tween_property($UI, "position", original_position + random_offset, duration / 5.0)
		
		# Повертаємо на початкову позицію
		tween.tween_property($UI, "position", original_position, duration / 5.0)
