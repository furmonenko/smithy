# anvil_mini_game.gd
extends CanvasLayer
class_name AnvilMiniGame

signal mini_game_completed(success, score)
signal mini_game_cancelled

# Типи зброї, що можна кувати
enum WEAPON_TYPE { DAGGER = 0, SHORT_SWORD = 1, LONG_SWORD = 2 }

# Стани температури
enum TEMPERATURE_STATE { PERFECT = 0, GOOD = 1, SATISFACTORY = 2, COLD = 3 }

# Фази гри
enum GAME_PHASE { HIT = 0, DIRECTION = 1, FLIP = 2 }

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Кнопки для ударів
const HIT_ACTIONS = ["hit_button_a", "hit_button_b", "hit_button_x", "hit_button_y"]
# Стрілки для напрямку
const UP_ACTION = "ui_up"
const DOWN_ACTION = "ui_down"
# Кнопки для перевертання
const LEFT_ACTION = "ui_left"
const RIGHT_ACTION = "ui_right"

# Налаштування гри
@export var skill_level: int = SKILL_LEVEL.APPRENTICE
@export var weapon_type: int = WEAPON_TYPE.LONG_SWORD
@export var shrinking_speed_factor: float = 2.0  # Множник швидкості зменшення кола

# Параметри, що залежать від рівня майстерності
var target_ring_size: float  # % від загального радіусу
var reaction_time: float     # час на реакцію в секундах
var cooling_rate: float      # % ударів для охолодження на один рівень

# Параметри, що залежать від типу зброї
var total_hits_required: int

# Змінні для відстеження прогресу
var current_temperature: int = TEMPERATURE_STATE.PERFECT  # Початкова температура ідеальна
var current_hits: int = 0
var current_phase: int = GAME_PHASE.HIT
var current_score: int = 0
var perfect_hits_streak: int = 0
var last_hit_quality: int = 0  # 0 = промах, 1 = задовільно, 2 = добре, 3 = ідеально
var flip_half_done: bool = false  # Чи був зроблений переворот на половині
var current_direction: String = "up"  # Поточний напрямок (вгору/вниз)
var current_hit_button: String = ""   # Поточна кнопка для удару
var starting_shringing_circe_scale: Vector2
var starting_target_ring_scale: Vector2

# Таймери
var ring_timer: Timer
var direction_timer: Timer
var flip_timer: Timer

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			target_ring_size = 0.28
			reaction_time = 2
			cooling_rate = 0.2  # Охолодження кожні 20% ударів
		SKILL_LEVEL.JOURNEYMAN:  
			target_ring_size = 0.32
			reaction_time = 2.2
			cooling_rate = 0.3 
		SKILL_LEVEL.BLACKSMITH: 
			target_ring_size = 0.35 
			reaction_time = 2.4
			cooling_rate = 0.4 
		SKILL_LEVEL.MASTER: 
			target_ring_size = 0.4
			reaction_time = 2.8
			cooling_rate = 0.5
	
	# Налаштовуємо параметри залежно від типу зброї
	match weapon_type:
		WEAPON_TYPE.DAGGER:
			total_hits_required = 10
		WEAPON_TYPE.SHORT_SWORD:
			total_hits_required = 10
		WEAPON_TYPE.LONG_SWORD:
			total_hits_required = 10
	
# Створюємо і налаштовуємо таймери
	ring_timer = Timer.new()
	ring_timer.one_shot = true
	ring_timer.timeout.connect(_on_ring_timer_timeout)
	add_child(ring_timer)
	
	direction_timer = Timer.new()
	direction_timer.one_shot = true
	direction_timer.timeout.connect(_on_direction_timer_timeout)
	add_child(direction_timer)
	
	flip_timer = Timer.new()
	flip_timer.one_shot = true
	flip_timer.timeout.connect(_on_flip_timer_timeout)
	add_child(flip_timer)
	
	InputManager.input_type_changed.connect(_on_input_type_changed)
	
	starting_shringing_circe_scale = %ShrinkingCircle.scale
	starting_target_ring_scale = %ShrinkingCircle.scale
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	# Приховуємо на початку
	visible = false
	start_game()

func _on_input_type_changed(_device_type):
	# Оновлюємо текстури всіх кнопок
	setup_hit_buttons()
	
	# Оновлюємо активну фазу
	match current_phase:
		GAME_PHASE.HIT:
			# Оновлюємо активну кнопку удару
			start_hit_phase()
		GAME_PHASE.DIRECTION:
			# Оновлюємо стрілку напрямку
			start_direction_phase()
		GAME_PHASE.FLIP:
			# Оновлюємо кнопку перевертання
			start_flip_phase()
	

func setup_ui():
	# Налаштовуємо розмір цільового кільця відповідно до рівня майстерності
	%TargetRing.scale = starting_target_ring_scale * target_ring_size

	# Оновлюємо лічильник ударів
	update_hit_counter()
	
	# Оновлюємо температурний індикатор
	update_temperature_indicator()
	
	# Налаштовуємо кнопки удару
	setup_hit_buttons()
	
	# Налаштовуємо шейдер для індикатора температури
	setup_temperature_shader()

# Оновлена функція setup_hit_buttons, яка призначає текстури
func setup_hit_buttons():
	# Приховуємо всі кнопки спочатку
	%HitButtonA.visible = false
	%HitButtonB.visible = false
	%HitButtonX.visible = false
	%HitButtonY.visible = false
	
	# Оновлюємо текстури відповідно до поточного пристрою вводу
	%HitButtonA.texture = InputManager.get_button_texture("hit_button_a")
	%HitButtonB.texture = InputManager.get_button_texture("hit_button_b")
	%HitButtonX.texture = InputManager.get_button_texture("hit_button_x")
	%HitButtonY.texture = InputManager.get_button_texture("hit_button_y")
	
	# Налаштовуємо текстури для стрілок і кнопки фліпу
	if %DirectionArrow:
		%DirectionArrow.texture = InputManager.get_button_texture("ui_up")  # Початкова текстура
	
	if %FlipButton:
		%FlipButton.texture = InputManager.get_button_texture("ui_left")  # Початкова текстура для фліпу

func start_game():
	visible = true
	current_temperature = TEMPERATURE_STATE.PERFECT
	current_hits = 0
	current_phase = GAME_PHASE.HIT
	current_score = 0
	perfect_hits_streak = 0
	flip_half_done = false
	current_direction = "up"
	
	# Скидаємо і оновлюємо UI
	update_hit_counter()
	update_temperature_indicator()
	
	# Починаємо з фази удару
	start_hit_phase()

func start_hit_phase():
	current_phase = GAME_PHASE.HIT
	
	# Визначаємо регіон залежно від прогресу
	var region_position
	
	# Розраховуємо скільки ударів у кожній фазі (до і після перевертання)
	var hits_per_phase = total_hits_required / 2
	
	if flip_half_done:
		# Після перевертання:
		# Рахуємо скільки ударів зроблено після перевертання
		var hits_after_flip = current_hits - hits_per_phase
		# Перетворюємо в прогрес від 0.0 до 1.0
		var phase_progress = float(hits_after_flip) / hits_per_phase
		# Починаємо з позиції 0.0 (верх) і рухаємося до 1.0 (низ)
		region_position = phase_progress
	else:
		# До перевертання:
		# Перетворюємо в прогрес від 0.0 до 1.0
		var phase_progress = float(current_hits) / hits_per_phase
		# Починаємо з позиції 1.0 (низ) і рухаємося до 0.0 (верх)
		region_position = 1.0 - phase_progress
	
	# Оновлюємо шейдер
	update_workpiece_region(region_position)
	
	# Вибираємо випадкову кнопку для удару
	current_hit_button = HIT_ACTIONS[randi() % HIT_ACTIONS.size()]
	
	# Приховуємо всі кнопки спочатку
	%HitButtonA.visible = false
	%HitButtonB.visible = false
	%HitButtonX.visible = false
	%HitButtonY.visible = false
	
	# Показуємо поточну кнопку з правильною текстурою
	match current_hit_button:
		"hit_button_a":
			%HitButtonA.texture = InputManager.get_button_texture("hit_button_a")
			%HitButtonA.visible = true
		"hit_button_b":
			%HitButtonB.texture = InputManager.get_button_texture("hit_button_b")
			%HitButtonB.visible = true
		"hit_button_x":
			%HitButtonX.texture = InputManager.get_button_texture("hit_button_x")
			%HitButtonX.visible = true
		"hit_button_y":
			%HitButtonY.texture = InputManager.get_button_texture("hit_button_y")
			%HitButtonY.visible = true
	
	# Обов'язково показуємо елементи
	%ShrinkingCircle.visible = true
	%ShrinkingCircle.scale = starting_shringing_circe_scale
	%TargetRing.visible = true
	
	# Ховаємо елементи інших фаз
	%DirectionArrow.visible = false
	%FlipButton.visible = false
	
	# Скасовуємо попередній tween, якщо він існує
	var existing_tweens = get_tree().get_processed_tweens()
	for tween in existing_tweens:
		if tween.is_valid():
			tween.kill()
	
	# Запускаємо анімацію кола з урахуванням множника швидкості
	var tween = create_tween()
	var adjusted_time = reaction_time / shrinking_speed_factor
	tween.tween_property(%ShrinkingCircle, "scale", Vector2(0, 0), adjusted_time)
	
	# Встановлюємо таймер для автоматичного завершення фази
	ring_timer.wait_time = adjusted_time
	ring_timer.start()
	
	var button_name = InputManager.get_button_display_name(current_hit_button)
	%InstructionsLabel.text = "Натисніть %s коли коло співпадає з цільовою зоною" % button_name

func get_button_display_name(action_name: String) -> String:
	match action_name:
		"hit_button_a": return "A"
		"hit_button_b": return "B"
		"hit_button_x": return "X"
		"hit_button_y": return "Y"
		_: return action_name

func _on_ring_timer_timeout():
	# Якщо гравець не натиснув вчасно - промах
	if current_phase == GAME_PHASE.HIT:
		handle_hit(0)  # 0 = промах

func handle_hit(quality: int):
	last_hit_quality = quality
	
	# Обчислюємо очки за удар залежно від якості і температури
	var hit_points = 0
	var base_points = 0
	var temp_multiplier = 0.0
	var combo_multiplier = 1.0
	
	# Визначаємо базові очки
	match quality:
		3:  # Ідеальний удар
			base_points = 6
			perfect_hits_streak += 1
			show_hit_feedback("Ідеально!", Color(0, 1, 0))
		2:  # Хороший удар
			base_points = 4
			perfect_hits_streak = 0
			show_hit_feedback("Добре", Color(0.5, 1, 0))
		1:  # Задовільний удар
			base_points = 2
			perfect_hits_streak = 0
			show_hit_feedback("Задовільно", Color(1, 1, 0))
		0:  # Промах
			base_points = 0
			perfect_hits_streak = 0
			show_hit_feedback("Промах!", Color(1, 0, 0))
	
	# Визначаємо множник температури
	match current_temperature:
		TEMPERATURE_STATE.PERFECT:
			temp_multiplier = 1.0
		TEMPERATURE_STATE.GOOD:
			temp_multiplier = 0.75
		TEMPERATURE_STATE.SATISFACTORY:
			temp_multiplier = 0.5
		TEMPERATURE_STATE.COLD:
			temp_multiplier = 0.25
	
	# Визначаємо комбо-множник
	if perfect_hits_streak >= 5:
		combo_multiplier = 2.0  # x2 за 5+ послідовних ідеальних ударів
	elif perfect_hits_streak >= 3:
		combo_multiplier = 1.5  # x1.5 за 3-4 послідовні ідеальні удари
	
	# Розраховуємо очки за удар
	hit_points = base_points * temp_multiplier * combo_multiplier
	
	# Виводимо інформацію в консоль
	print("УДАР: базові очки = %d, множник температури = %.2f, комбо-множник = %.1f, очки за удар = %.1f" % [base_points, temp_multiplier, combo_multiplier, hit_points])
	
	# Додаємо очки
	current_score += hit_points
	
	# Збільшуємо лічильник ударів
	current_hits += 1
	update_hit_counter()
	
	# Перевіряємо охолодження (тут, після удару)
	check_cooling()
	
	# Перевіряємо завершення гри
	if current_hits >= total_hits_required:
		end_game(true)
		return
	
	# Визначаємо, чи це був останній удар перед перевертанням
	var hits_per_phase = total_hits_required / 2
	var need_flip = (current_hits == hits_per_phase) and not flip_half_done
	
	# Якщо це був останній удар перед перевертанням, оновлюємо позицію до 0.0 (верх)
	if need_flip:
		update_workpiece_region(0.0)  # Досягаємо верху перед перевертанням
		flip_half_done = true
		start_flip_phase()
		return
	
	# Інакше переходимо до фази вибору напрямку
	start_direction_phase()

func start_direction_phase():
	current_phase = GAME_PHASE.DIRECTION
	
	# Ховаємо коло і кнопки удару
	%ShrinkingCircle.visible = false
	%TargetRing.visible = false
	%HitButtonA.visible = false
	%HitButtonB.visible = false
	%HitButtonX.visible = false
	%HitButtonY.visible = false
	
	# Визначаємо напрямок на основі стану фліпу
	# До фліпу завжди вгору, після фліпу завжди вниз
	current_direction = "down" if flip_half_done else "up"
	var direction_action = DOWN_ACTION if current_direction == "down" else UP_ACTION
	
	# Оновлюємо текстуру стрілки - завантажуємо відповідну текстуру замість обертання
	%DirectionArrow.texture = InputManager.get_button_texture(direction_action)
	%DirectionArrow.visible = true
	
	# Прибираємо обертання, оскільки використовуємо правильну текстуру
	%DirectionArrow.rotation = 0
	
	# Більше часу на вибір напрямку
	direction_timer.wait_time = reaction_time * 0.9  # Збільшено з 0.7 до 0.9
	direction_timer.start()
	
	var button_name = InputManager.get_button_display_name(direction_action)
	%InstructionsLabel.text = "Натисніть %s" % button_name

func _on_direction_timer_timeout():
	# Якщо гравець не вибрав напрямок вчасно
	if current_phase == GAME_PHASE.DIRECTION:
		handle_direction(0)  # 0 = не вибрано

func handle_direction(quality: int):
	# Визначаємо очки за вибір напрямку
	var direction_points = 0
	
	match quality:
		2:  # Точний вибір
			direction_points = 2
			show_hit_feedback("Точний напрямок!", Color(0, 1, 0))
		1:  # Запізнілий вибір
			direction_points = 1
			show_hit_feedback("Запізнілий напрямок", Color(1, 1, 0))
		0:  # Неправильний або не вибрано
			direction_points = 0
			show_hit_feedback("Пропущено напрямок", Color(1, 0, 0))
	
	# Виводимо інформацію в консоль
	print("НАПРЯМОК: якість = %d, очки за напрямок = %d" % [quality, direction_points])
	
	# Додаємо очки
	current_score += direction_points
	
	# Переходимо до фази удару
	start_hit_phase()

func start_flip_phase():
	current_phase = GAME_PHASE.FLIP
	
	# Ховаємо попередні елементи
	%ShrinkingCircle.visible = false
	%TargetRing.visible = false
	%DirectionArrow.visible = false
	%HitButtonA.visible = false
	%HitButtonB.visible = false
	%HitButtonX.visible = false
	%HitButtonY.visible = false
	
	# Оновлюємо текстуру для кнопки перевертання
	%FlipButton.texture = InputManager.get_button_texture("ui_left")  # Можна вибрати будь-яку з двох
	%FlipButton.visible = true
	
	# Показуємо кнопку перевертання
	%FlipButton.visible = true
	
	# Встановлюємо таймер для автоматичного завершення фази
	flip_timer.wait_time = reaction_time * 1.3  # Більше часу на перевертання
	flip_timer.start()
	
	var left_button = InputManager.get_button_display_name("ui_left")
	var right_button = InputManager.get_button_display_name("ui_right")
	%InstructionsLabel.text = "Переверніть заготовку (%s або %s)" % [left_button, right_button]

func _on_flip_timer_timeout():
	# Якщо гравець не перевернув вчасно
	if current_phase == GAME_PHASE.FLIP:
		handle_flip(0)  # 0 = не перевернуто

func handle_flip(quality: int):
	# Визначаємо очки за перевертання
	var flip_points = 0
	
	match quality:
		2:  # Ідеальне перевертання
			flip_points = 10
			show_hit_feedback("Ідеальне перевертання!", Color(0, 1, 0))
		1:  # Хороше перевертання
			flip_points = 7
			show_hit_feedback("Хороше перевертання", Color(0.5, 1, 0))
		0:  # Запізніле або не перевернуто
			flip_points = 3
			show_hit_feedback("Запізніле перевертання", Color(1, 1, 0))
	
	# Виводимо інформацію в консоль
	print("ПЕРЕВЕРТАННЯ: якість = %d, очки за перевертання = %d" % [quality, flip_points])
	
	# Додаємо очки
	current_score += flip_points
	
	# Перемикаємо параметр перевертання в шейдері
	var material = %TemperatureIndicator.material
	if material:
		material.set_shader_parameter("flip_done", true)
	
	# Оновлюємо позицію, щоб підготуватись до руху вниз
	# Перший удар після перевертання матиме індекс hits_per_phase + 1
	var region_position = 1.0 / total_hits_required  # Перша позиція після перевертання
	update_workpiece_region(region_position)
	
	# Переходимо до фази удару
	start_hit_phase()

func check_cooling():
	# Розраховуємо кількість ударів для охолодження на одиницю
	var hits_per_cooling = total_hits_required * cooling_rate
	
	# Визначаємо новий рівень температури на основі кількості ударів
	var cooling_stages = floor(current_hits / hits_per_cooling)
	
	if cooling_stages == 0:
		current_temperature = TEMPERATURE_STATE.PERFECT
	elif cooling_stages == 1:
		current_temperature = TEMPERATURE_STATE.GOOD
	elif cooling_stages == 2:
		current_temperature = TEMPERATURE_STATE.SATISFACTORY
	else:
		current_temperature = TEMPERATURE_STATE.COLD
	
	# Оновлюємо індикатор температури
	update_temperature_indicator()

func update_temperature_indicator():
	# Оновлюємо відображення температури
	match current_temperature:
		TEMPERATURE_STATE.PERFECT:
			%TemperatureIndicator.color = Color(1, 0.6, 0)  # Помаранчевий
			%TemperatureLabel.text = "Ідеальна температура (100%)"
		TEMPERATURE_STATE.GOOD:
			%TemperatureIndicator.color = Color(1, 0, 0)  # Червоний
			%TemperatureLabel.text = "Хороша температура (75%)"
		TEMPERATURE_STATE.SATISFACTORY:
			%TemperatureIndicator.color = Color(0.7, 0, 0)  # Темно-червоний
			%TemperatureLabel.text = "Задовільна температура (50%)"
		TEMPERATURE_STATE.COLD:
			%TemperatureIndicator.color = Color(0.5, 0.5, 0.5)  # Сірий
			%TemperatureLabel.text = "Холодна температура (25%)"

func update_hit_counter():
	%HitCounterLabel.text = "Удари: %d/%d" % [current_hits, total_hits_required]
	
	# Оновлюємо індикатор прогресу
	%ProgressBar.value = float(current_hits) / total_hits_required * 100

func show_hit_feedback(text: String, color: Color):
	%FeedbackLabel.text = text
	%FeedbackLabel.add_theme_color_override("font_color", color)
	%FeedbackLabel.visible = true
	
	# Створюємо анімацію згасання
	var tween = create_tween()
	tween.tween_property(%FeedbackLabel, "modulate", Color(1, 1, 1, 0), 0.7).from(Color(1, 1, 1, 1))
	tween.tween_callback(Callable(self, "_hide_feedback").bind())

func _hide_feedback():
	%FeedbackLabel.visible = false

func _input(event):
	if not visible:
		return
	
	# Обробка натискання для фази удару
	if current_phase == GAME_PHASE.HIT:
		if event.is_action_pressed(current_hit_button):
			ring_timer.stop()
			
			# Визначаємо якість удару на основі порівняння поточного масштабу з цільовим
			var current_scale = %ShrinkingCircle.scale.x / starting_shringing_circe_scale.x  # Нормалізуємо до 0-1
			var target_scale = %TargetRing.scale.x / starting_target_ring_scale.x  # Нормалізуємо цільовий розмір
			
			var hit_quality
			
			# Перевіряємо, наскільки близько поточний масштаб до цільового
			if abs(current_scale - target_scale) < 0.01:
				hit_quality = 3  # Ідеальний удар
			elif abs(current_scale - target_scale) < 0.04:
				hit_quality = 2  # Хороший удар
			elif abs(current_scale - target_scale) < 0.1:
				hit_quality = 1  # Задовільний удар
			else:
				hit_quality = 0  # Промах
			
			var random_pitch :float = randf_range(0.95, 1.05)
			%AnvilHit.pitch_scale = random_pitch
			%AnvilHit.play()
			
			handle_hit(hit_quality)
		elif event.is_action_pressed("hit_button_a") or event.is_action_pressed("hit_button_b") or \
			 event.is_action_pressed("hit_button_x") or event.is_action_pressed("hit_button_y"):
			# Натиснута неправильна кнопка
			ring_timer.stop()
			handle_hit(0)  # Промах
	
	# Обробка натискання для фази вибору напрямку
	elif current_phase == GAME_PHASE.DIRECTION:
		var direction_quality = 0
		
		if (event.is_action_pressed(UP_ACTION) and current_direction == "up") or \
		   (event.is_action_pressed(DOWN_ACTION) and current_direction == "down"):
			# Визначаємо якість вибору напрямку на основі часу реакції
			var wait_time = direction_timer.wait_time
			var elapsed_time = wait_time - direction_timer.time_left
			var time_percentage = elapsed_time / wait_time * 100
			
			print("Час реакції для напрямку: %.2f / %.2f (%.1f%%)" % [elapsed_time, wait_time, time_percentage])
			
			# Зупиняємо таймер ПІСЛЯ отримання часу, що залишився
			direction_timer.stop()
			
			# Перевіряємо час реакції
			if time_percentage < 20:  # Перша частина доступного часу
				direction_quality = 2  # Точний вибір
			else:
				direction_quality = 1  # Запізнілий вибір
				
			handle_direction(direction_quality)
		elif event.is_action_pressed(UP_ACTION) or event.is_action_pressed(DOWN_ACTION):
			# Неправильний напрямок натиснуто
			direction_timer.stop()
			handle_direction(0)  # Неправильний вибір
	
	# Обробка натискання для фази перевертання
	elif current_phase == GAME_PHASE.FLIP:
		if event.is_action_pressed(LEFT_ACTION) or event.is_action_pressed(RIGHT_ACTION):
			# Зберігаємо значення time_left перед зупинкою таймера
			var wait_time = flip_timer.wait_time
			var elapsed_time = wait_time - flip_timer.time_left
			var time_percentage = elapsed_time / wait_time * 100
			
			flip_timer.stop()
			
			var flip_quality
			
			# Перевіряємо за процентним відношенням
			if time_percentage < 30:
				flip_quality = 2  # Ідеальне перевертання
			elif time_percentage < 60:
				flip_quality = 1  # Хороше перевертання
			else:
				flip_quality = 0  # Запізніле перевертання
			
			handle_flip(flip_quality)
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func end_game(success: bool):
	# Виводимо детальний результат у консоль
	print("==========================================")
	print("РЕЗУЛЬТАТ МІНІ-ГРИ КОВАДЛО")
	print("==========================================")
	print("Тип зброї: " + ["Кинджал", "Короткий меч", "Довгий меч"][weapon_type])
	print("Рівень майстерності: " + ["Учень", "Підмайстер", "Коваль", "Майстер-коваль"][skill_level])
	print("Фінальний рахунок: %d" % current_score)
	
	# Якість зброї
	var quality = "звичайний"
	if current_score > 90:
		quality = "легендарний"
	elif current_score > 75:
		quality = "видатний"
	elif current_score > 60:
		quality = "хороший"
	elif current_score > 40:
		quality = "середній"
	
	print("\nЯкість виготовленої зброї: %s" % quality)
	print("==========================================")
	
	# Приховуємо UI
	visible = false
	
	# Відправляємо сигнал про завершення з результатом
	mini_game_completed.emit(success, current_score)

func cancel_game():
	visible = false
	mini_game_cancelled.emit()

func setup_temperature_shader():
	# Створюємо шейдер матеріал
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://shaders/workpiece_shader.gdshader")
	
	%TemperatureIndicator.material = shader_material
	
	# Налаштування шейдера з кращою видимістю
	shader_material.set_shader_parameter("highlight_color", Color(1.0, 0.9, 0.1, 0.9))
	shader_material.set_shader_parameter("highlight_size", 0.5)
	
	# Початкові налаштування шейдера - починаємо з нижньої частини
	update_workpiece_region(1.0, true)

func update_workpiece_region(position: float, active: bool = true):
	var material = %TemperatureIndicator.material
	if material:
		material.set_shader_parameter("highlight_position", position)
		material.set_shader_parameter("highlight_active", active)
		material.set_shader_parameter("flip_done", flip_half_done)
