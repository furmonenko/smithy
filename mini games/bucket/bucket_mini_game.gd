# bucket_mini_game.gd
extends MiniGame
class_name BucketMiniGame

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Типи зброї для загартовування
enum WEAPON_TYPE { DAGGER = 0, SHORT_SWORD = 1, LONG_SWORD = 2 }

# Стани гри
enum GAME_STATE { IDLE = 0, QUENCHING = 1, COMPLETE = 2 }

# Кнопка для загартовування
const QUENCH_ACTION = "hit_button_a"

# Налаштування гри
@export var skill_level: int = SKILL_LEVEL.APPRENTICE
@export var weapon_type: int = WEAPON_TYPE.DAGGER
@export var initial_heat_amount: float = 1.0  # Початковий рівень нагріву (0.0-1.0)
@export var cooling_speed: float = 0.2  # Базова швидкість охолодження (0-1 на секунду)
@export var steam_duration: float = 6.0  # Скільки секунд буде йти пара

# Параметри, що залежать від рівня майстерності
var perfect_timing_min: float  # Мінімальний ідеальний час загартовування
var perfect_timing_max: float  # Максимальний ідеальний час загартовування
var quenching_difficulty: float  # Множник складності (впливає на швидкість охолодження)

# Змінні для відстеження прогресу
var current_heat_level: float = 1.0  # Поточний рівень нагріву (0-1)
var current_state: int = GAME_STATE.IDLE
var quenching_time: float = 0.0  # Час, протягом якого виріб загартовується
var current_score: int = 0  # Рахунок гравця
var is_button_pressed: bool = false  # Чи натиснута кнопка загартовування
var steam_active: bool = false  # Чи йде пара

# Таймери
var game_timer: Timer
var feedback_timer: Timer

# Змінні для анімації
var steam_particles: CPUParticles2D
var workpiece_tween: Tween = null

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			perfect_timing_min = steam_duration * 0.75
			perfect_timing_max = steam_duration * 0.95
			quenching_difficulty = 0.8
		SKILL_LEVEL.JOURNEYMAN:
			perfect_timing_min = steam_duration * 0.80
			perfect_timing_max = steam_duration * 0.93
			quenching_difficulty = 1.0
		SKILL_LEVEL.BLACKSMITH:
			perfect_timing_min = steam_duration * 0.85
			perfect_timing_max = steam_duration * 0.92
			quenching_difficulty = 1.2
		SKILL_LEVEL.MASTER:
			perfect_timing_min = steam_duration * 0.90
			perfect_timing_max = steam_duration * 0.95
			quenching_difficulty = 1.5
	
	# Налаштовуємо параметри залежно від типу зброї
	match weapon_type:
		WEAPON_TYPE.DAGGER:
			cooling_speed *= 1.2  # Маленькі вироби охолоджуються швидше
		WEAPON_TYPE.SHORT_SWORD:
			cooling_speed *= 1.0  # Стандартна швидкість
		WEAPON_TYPE.LONG_SWORD:
			cooling_speed *= 0.8  # Більші вироби охолоджуються повільніше
	
	# Створюємо і налаштовуємо таймери
	game_timer = Timer.new()
	game_timer.one_shot = false
	game_timer.wait_time = 0.1  # Оновлюємо стан кожні 0.1 секунди
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	feedback_timer = Timer.new()
	feedback_timer.one_shot = true
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	add_child(feedback_timer)
	
	InputManager.input_type_changed.connect(_on_input_type_changed)
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	# Встановлюємо початковий рівень нагріву
	current_heat_level = initial_heat_amount
	
	# Налаштовуємо шейдер для відображення заготовки
	setup_shader_for_workpiece()
	
	# Приховуємо на початку
	visible = false
	
	# Запускаємо гру
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
	if has_node("%WorkpieceIndicator") and %WorkpieceIndicator.material:
		var material = %WorkpieceIndicator.material
		
		# Встановлюємо текстуру заготовки
		%WorkpieceIndicator.texture = billet_texture
		
		# Налаштовуємо параметри шейдера для відображення нагріву
		material.set_shader_parameter("heat_amount", initial_heat_amount)
		material.set_shader_parameter("heat_glow_intensity", 0.6)
		material.set_shader_parameter("heat_color_intensity", 0.85)
		material.set_shader_parameter("displacement_noise", noise_texture)
		
		# Налаштовуємо параметри деформації
		match weapon_type:
			WEAPON_TYPE.DAGGER:
				material.set_shader_parameter("initial_deform", Vector2(1.0, 1.0))
			WEAPON_TYPE.SHORT_SWORD:
				material.set_shader_parameter("initial_deform", Vector2(0.9, 0.9))
			WEAPON_TYPE.LONG_SWORD:
				material.set_shader_parameter("initial_deform", Vector2(0.8, 0.8))

func setup_steam_particles():
	# Використовуємо вже існуючі частинки на сцені замість створення у коді
	steam_particles = %SteamParticles
	steam_particles.emitting = false
	
	# Початкові налаштування вже встановлені в редакторі сцени

func setup_ui():
	# Налаштовуємо кнопки
	setup_buttons()
	
	# Налаштовуємо частинки пари
	setup_steam_particles()

func setup_buttons():
	# Оновлюємо текстуру відповідно до поточного пристрою вводу
	%QuenchButton.texture = InputManager.get_button_texture(QUENCH_ACTION)
	
	# Підказки для гравця
	var button_name = InputManager.get_button_display_name(QUENCH_ACTION)
	%InstructionsLabel.text = "Зажміть %s щоб занурити виріб у воду\nВідпустіть коли пара майже зникне" % button_name

func start_game():
	visible = true
	current_heat_level = initial_heat_amount
	current_state = GAME_STATE.IDLE
	quenching_time = 0.0
	is_button_pressed = false
	steam_active = false
	
	# Оновлюємо візуальне відображення нагріву
	update_heat_indicator()
	
	# Запускаємо таймер гри
	game_timer.start()
	
	# Встановлюємо початкову позицію заготовки (над відром)
	if %WorkpieceIndicator:
		%WorkpieceIndicator.position.y = -100  # Над відром
	
	# Показуємо підказку
	show_feedback("Загартуйте виріб у воді", Color(1, 1, 1))

func _input(event):
	if not visible or current_state == GAME_STATE.COMPLETE:
		return
	
	# Обробка натискання/відпускання кнопки загартовування
	if event.is_action_pressed(QUENCH_ACTION) and current_state == GAME_STATE.IDLE:
		start_quenching()
	elif event.is_action_released(QUENCH_ACTION) and current_state == GAME_STATE.QUENCHING:
		finish_quenching()
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func start_quenching():
	current_state = GAME_STATE.QUENCHING
	is_button_pressed = true
	
	# Анімуємо занурення заготовки у воду
	if %WorkpieceIndicator:
		if workpiece_tween and workpiece_tween.is_valid():
			workpiece_tween.kill()
		
		workpiece_tween = create_tween()
		workpiece_tween.tween_property(%WorkpieceIndicator, "position:y", 50, 0.5)  # Опускаємо у відро
	
	# Запускаємо частинки пари - додаємо невелику затримку для синхронізації з зануренням
	if steam_particles:
		await get_tree().create_timer(0.2).timeout
		
		# Запускаємо нові частинки
		steam_particles.restart()
		steam_particles.emitting = true
		steam_active = true
	
	# Запускаємо звук занурення
	play_quench_sound()
	
	# Показуємо підказку
	show_feedback("Йде процес загартовування...", Color(0.5, 0.8, 1.0))

func finish_quenching():
	# Зупиняємо таймер
	game_timer.stop()
	
	# Для частинок пари - НЕ ЗУПИНЯЄМО ЕМІСІЮ ОДРАЗУ
	# Натомість дозволяємо вже випущеним частинкам завершити своє життя
	if steam_particles:
		# Встановлюємо фінальний стан - частинки тільки зникають, нові не з'являються
		steam_particles.emitting = false
		steam_active = false
		
		# Переконуємося, що існуючі частинки будуть видно ще деякий час
		# Не потрібно встановлювати таймер, оскільки вони зникнуть природним чином
	
	# Анімуємо підняття заготовки з води
	if %WorkpieceIndicator:
		if workpiece_tween and workpiece_tween.is_valid():
			workpiece_tween.kill()
		
		workpiece_tween = create_tween()
		workpiece_tween.tween_property(%WorkpieceIndicator, "position:y", -100, 0.5)  # Піднімаємо з відра
	
	# Обчислюємо результат
	calculate_result()

func calculate_result():
	var success = true
	var final_score = 0
	var quality_message = ""
	var color = Color.WHITE
	
	# Визначаємо якість загартовування на основі часу
	if quenching_time >= perfect_timing_min and quenching_time <= perfect_timing_max:
		# Ідеальне загартовування
		final_score = 100
		quality_message = "Ідеальне загартовування!"
		color = Color(0, 1, 0)
	elif quenching_time > 0 and quenching_time < perfect_timing_min:
		# Недостатнє загартовування
		var percentage = quenching_time / perfect_timing_min
		final_score = int(percentage * 65)
		quality_message = "Недостатнє загартовування!"
		color = Color(1, 0.7, 0)
	elif quenching_time > perfect_timing_max and quenching_time < steam_duration:
		# Надмірне загартовування, але ще прийнятне
		var overtime = quenching_time - perfect_timing_max
		var max_overtime = steam_duration - perfect_timing_max
		var penalty_percentage = overtime / max_overtime
		final_score = int(85 - (penalty_percentage * 35))
		quality_message = "Надмірне загартовування!"
		color = Color(1, 0.5, 0)
	else:
		# Критичний перегрів або недогрів
		final_score = max(10, int(current_heat_level * 20))
		quality_message = "Виріб зіпсовано!"
		color = Color(1, 0, 0)
	
	# Показуємо детальний результат
	show_result(quality_message, final_score, color)
	
	current_state = GAME_STATE.COMPLETE
	current_score = final_score
	
	# Очікуємо 2 секунди перед завершенням гри
	await get_tree().create_timer(2.0).timeout
	
	# Завершуємо гру
	end_game(success, final_score)

func show_result(quality_message: String, score: int, color: Color):
	# Ця функція показує детальний результат
	%FeedbackLabel.text = quality_message
	%FeedbackLabel.add_theme_color_override("font_color", color)
	%FeedbackLabel.visible = true
	
	# Анімуємо збільшення тексту для привернення уваги
	var tween = create_tween()
	tween.tween_property(%FeedbackLabel, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(%FeedbackLabel, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Додаємо другий рядок з оцінкою після короткої паузи
	await get_tree().create_timer(0.5).timeout
	%FeedbackLabel.text = quality_message + "\nОцінка: " + str(score) + " з 100"
	
	# Оновлюємо відображення остаточного рівня нагріву
	update_final_heat_visual(score)

func update_final_heat_visual(score: int):
	# Візуалізуємо кінцевий результат через шейдер
	if has_node("%WorkpieceIndicator") and %WorkpieceIndicator.material:
		var final_heat_level = 0.0
		
		if score > 90:
			final_heat_level = 0.3  # Ідеальне загартовування дає синювато-сталевий відтінок
		elif score > 70:
			final_heat_level = 0.1  # Хороше загартовування
		elif score > 50:
			final_heat_level = 0.5  # Посереднє загартовування залишає червонуватий відтінок
		else:
			final_heat_level = 0.7  # Погане загартовування залишає виріб недостатньо охолодженим
		
		# Створюємо анімацію фінального візуального ефекту
		var tween = create_tween()
		tween.tween_method(Callable(self, "_update_heat_amount"), current_heat_level, final_heat_level, 0.7)

func _on_game_timer_timeout():
	# Час гри йде вперед
	var delta = game_timer.wait_time
	
	if current_state == GAME_STATE.QUENCHING:
		# Збільшуємо час загартовування
		quenching_time += delta
		
		# Зменшуємо нагрів з часом
		var cooling_amount = cooling_speed * delta * quenching_difficulty
		current_heat_level = max(0.0, current_heat_level - cooling_amount)
		
		# Оновлюємо візуальний індикатор
		update_heat_indicator()
		
		# Змінюємо інтенсивність пари залежно від часу
		update_steam_intensity()
		
		# Перевіряємо, чи не закінчився час пари
		if quenching_time >= steam_duration and steam_active:
			steam_active = false
			if steam_particles:
				steam_particles.emitting = false
			show_feedback("Пара зникла! Час діставати виріб", Color(1, 0.3, 0.3))

func update_heat_indicator():
	# Оновлюємо шейдер для відображення нагріву
	if has_node("%WorkpieceIndicator") and %WorkpieceIndicator.material:
		%WorkpieceIndicator.material.set_shader_parameter("heat_amount", current_heat_level)
		
		# Також оновлюємо кольори залежно від рівня нагріву
		if current_heat_level > 0.8:
			# Дуже гарячий (яскраво-помаранчевий/жовтий)
			%WorkpieceIndicator.material.set_shader_parameter("heat_color_intensity", 0.9)
			%WorkpieceIndicator.material.set_shader_parameter("heat_glow_intensity", 0.8)
		elif current_heat_level > 0.5:
			# Середній нагрів (помаранчевий)
			%WorkpieceIndicator.material.set_shader_parameter("heat_color_intensity", 0.7)
			%WorkpieceIndicator.material.set_shader_parameter("heat_glow_intensity", 0.5)
		elif current_heat_level > 0.3:
			# Слабкий нагрів (темно-червоний)
			%WorkpieceIndicator.material.set_shader_parameter("heat_color_intensity", 0.5)
			%WorkpieceIndicator.material.set_shader_parameter("heat_glow_intensity", 0.3)
		else:
			# Охолоджений (синюватий відтінок)
			%WorkpieceIndicator.material.set_shader_parameter("heat_color_intensity", 0.4)
			%WorkpieceIndicator.material.set_shader_parameter("heat_glow_intensity", 0.2)

func _update_heat_amount(heat: float):
	if has_node("%WorkpieceIndicator") and %WorkpieceIndicator.material:
		%WorkpieceIndicator.material.set_shader_parameter("heat_amount", heat)
		current_heat_level = heat

func update_steam_intensity():
	if steam_particles and steam_active:
		var intensity_factor = 1.0
		
		intensity_factor = 1.0 - ((quenching_time - perfect_timing_min) / (steam_duration - perfect_timing_min))
		intensity_factor = max(0.2, intensity_factor)  # Мінімум 20% для видимості

		steam_particles.modulate = Color(1, 1, 1, intensity_factor)
		steam_particles.lifetime = 2.0 * intensity_factor
		
		steam_particles.speed_scale = max(0.4, intensity_factor)
		
		
		# Оновлюємо звук пари (якщо є)
		if has_node("%SteamSound"):
			%SteamSound.volume_db = linear_to_db(0.6 * intensity_factor) - 15.0
		
		# Оновлюємо прогрес-бар - він показує прогрес загартовування
		%SteamProgressBar.value = (quenching_time / steam_duration) * 100
		
		# Візуальні підказки на основі інтенсивності пари
		if intensity_factor < 0.35 and intensity_factor > 0.25:
			show_feedback("Час діставати виріб!", Color(0, 1, 0))
		elif intensity_factor <= 0.25:
			show_feedback("Пара майже зникла!", Color(1, 0.5, 0))
		elif intensity_factor < 0.5 and perfect_timing_min <= quenching_time and quenching_time <= perfect_timing_max:
			show_feedback("Ідеальний час для загартовування!", Color(0, 1, 0))

func play_quench_sound():
	# Відтворюємо звук загартовування, якщо доступний
	if has_node("%QuenchSound"):
		%QuenchSound.play()

func show_feedback(text: String, color: Color = Color(1, 1, 1)):
	%FeedbackLabel.text = text
	%FeedbackLabel.add_theme_color_override("font_color", color)
	%FeedbackLabel.visible = true
	
	# Запускаємо таймер для приховування підказки
	feedback_timer.start(2.0)

func _on_feedback_timer_timeout():
	%FeedbackLabel.visible = false

func _on_input_type_changed(_device_type):
	# Оновлюємо текстури кнопок
	setup_buttons()
