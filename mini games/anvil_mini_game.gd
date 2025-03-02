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
@export var starting_shringing_circe_scale: Vector2
@export var starting_target_ring_scale: Vector2

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

# Таймери
var ring_timer: Timer
var direction_timer: Timer
var flip_timer: Timer

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:  # Учень
			target_ring_size = 0.28  # 7% від радіусу
			reaction_time = 2
			cooling_rate = 0.2  # Охолодження кожні 20% ударів
		SKILL_LEVEL.JOURNEYMAN:  # Підмайстер
			target_ring_size = 0.32  # 12% від радіусу
			reaction_time = 2.5
			cooling_rate = 0.3  # Охолодження кожні 30% ударів
		SKILL_LEVEL.BLACKSMITH:  # Коваль
			target_ring_size = 0.35  # 18% від радіусу
			reaction_time = 3
			cooling_rate = 0.4  # Охолодження кожні 40% ударів
		SKILL_LEVEL.MASTER:  # Майстер-коваль
			target_ring_size = 0.4  # 28% від радіусу
			reaction_time = 5
			cooling_rate = 0.5  # Охолодження кожні 50% ударів
	
	# Налаштовуємо параметри залежно від типу зброї
	match weapon_type:
		WEAPON_TYPE.DAGGER:
			total_hits_required = 6
		WEAPON_TYPE.SHORT_SWORD:
			total_hits_required = 8
		WEAPON_TYPE.LONG_SWORD:
			total_hits_required = 10
	
# Створюємо і налаштовуємо таймери
	ring_timer = Timer.new()
	ring_timer.one_shot = true
	ring_timer.connect("timeout", Callable(self, "_on_ring_timer_timeout"))
	add_child(ring_timer)
	
	direction_timer = Timer.new()
	direction_timer.one_shot = true
	direction_timer.connect("timeout", Callable(self, "_on_direction_timer_timeout"))
	add_child(direction_timer)
	
	flip_timer = Timer.new()
	flip_timer.one_shot = true
	flip_timer.connect("timeout", Callable(self, "_on_flip_timer_timeout"))
	add_child(flip_timer)
	
	starting_shringing_circe_scale = %ShrinkingCircle.scale
	starting_target_ring_scale = %ShrinkingCircle.scale
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	# Приховуємо на початку
	visible = false
	start_game()

func setup_ui():
	# Налаштовуємо розмір цільового кільця відповідно до рівня майстерності
	%TargetRing.scale = starting_target_ring_scale * target_ring_size

	# Оновлюємо лічильник ударів
	update_hit_counter()
	
	# Оновлюємо температурний індикатор
	update_temperature_indicator()
	
	# Налаштовуємо кнопки удару
	setup_hit_buttons()

func setup_hit_buttons():
	# Приховуємо всі кнопки спочатку
	%HitButtonA.visible = false
	%HitButtonB.visible = false
	%HitButtonX.visible = false
	%HitButtonY.visible = false

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
	
	# Вибираємо випадкову кнопку для удару
	current_hit_button = HIT_ACTIONS[randi() % HIT_ACTIONS.size()]
	
	# Приховуємо всі кнопки
	%HitButtonA.visible = false
	%HitButtonB.visible = false
	%HitButtonX.visible = false
	%HitButtonY.visible = false
	
	# Показуємо поточну кнопку
	match current_hit_button:
		"hit_button_a":
			%HitButtonA.visible = true
		"hit_button_b":
			%HitButtonB.visible = true
		"hit_button_x":
			%HitButtonX.visible = true
		"hit_button_y":
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
	
	# Запускаємо анімацію кола
	var tween = create_tween()
	tween.tween_property(%ShrinkingCircle, "scale", Vector2(0, 0), reaction_time)
	
	# Встановлюємо таймер для автоматичного завершення фази
	ring_timer.wait_time = reaction_time
	ring_timer.start()
	
	# Показуємо підказку для гравця
	var button_name = get_button_display_name(current_hit_button)
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
	match quality:
		3:  # Ідеальний удар
			hit_points = 6
			perfect_hits_streak += 1
			show_hit_feedback("Ідеально!", Color(0, 1, 0))
		2:  # Хороший удар
			hit_points = 4
			perfect_hits_streak = 0
			show_hit_feedback("Добре", Color(0.5, 1, 0))
		1:  # Задовільний удар
			hit_points = 2
			perfect_hits_streak = 0
			show_hit_feedback("Задовільно", Color(1, 1, 0))
		0:  # Промах
			hit_points = 0
			perfect_hits_streak = 0
			show_hit_feedback("Промах!", Color(1, 0, 0))
	
	# Застосовуємо множник температури
	match current_temperature:
		TEMPERATURE_STATE.PERFECT:
			hit_points = hit_points * 1.0
		TEMPERATURE_STATE.GOOD:
			hit_points = hit_points * 0.75
		TEMPERATURE_STATE.SATISFACTORY:
			hit_points = hit_points * 0.5
		TEMPERATURE_STATE.COLD:
			hit_points = hit_points * 0.25
	
	# Застосовуємо комбо-множники
	if perfect_hits_streak >= 5:
		hit_points *= 2  # x2 за 5+ послідовних ідеальних ударів
	elif perfect_hits_streak >= 3:
		hit_points *= 1.5  # x1.5 за 3-4 послідовні ідеальні удари
	
	# Додаємо очки
	current_score += hit_points
	
	# Переходимо до фази вибору напрямку
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
	
	# Визначаємо новий напрямок (протилежний поточному)
	current_direction = "down" if current_direction == "up" else "up"
	
	# Показуємо стрілку для напрямку
	%DirectionArrow.visible = true
	%DirectionArrow.rotation = PI if current_direction == "down" else 0  # Повертаємо стрілку вниз або вгору
	
	# Встановлюємо таймер для автоматичного завершення фази
	direction_timer.wait_time = reaction_time * 0.7  # Менше часу на вибір напрямку
	direction_timer.start()
	
	# Показуємо підказку для гравця
	%InstructionsLabel.text = "Натисніть стрілку " + ("↓" if current_direction == "down" else "↑")

func _on_direction_timer_timeout():
	# Якщо гравець не вибрав напрямок вчасно
	if current_phase == GAME_PHASE.DIRECTION:
		handle_direction(0)  # 0 = не вибрано

func handle_direction(quality: int):
	# Додаємо очки за вибір напрямку
	match quality:
		2:  # Точний вибір
			current_score += 2
			show_hit_feedback("Точний напрямок!", Color(0, 1, 0))
		1:  # Запізнілий вибір
			current_score += 1
			show_hit_feedback("Запізнілий напрямок", Color(1, 1, 0))
		0:  # Неправильний або не вибрано
			current_score += 0
			show_hit_feedback("Пропущено напрямок", Color(1, 0, 0))
	
	# Збільшуємо лічильник ударів
	current_hits += 1
	update_hit_counter()
	
	# Перевіряємо необхідність перевертання
	var need_flip = false
	if current_hits == total_hits_required / 2 and not flip_half_done:
		need_flip = true
		flip_half_done = true
	
	# Перевіряємо охолодження
	check_cooling()
	
	# Перевіряємо завершення гри
	if current_hits >= total_hits_required:
		end_game(true)
		return
	
	# Переходимо до наступної фази
	if need_flip:
		start_flip_phase()
	else:
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
	
	# Показуємо кнопку перевертання
	%FlipButton.visible = true
	
	# Встановлюємо таймер для автоматичного завершення фази
	flip_timer.wait_time = reaction_time * 1.3  # Більше часу на перевертання
	flip_timer.start()
	
	# Показуємо підказку для гравця
	%InstructionsLabel.text = "Переверніть заготовку (стрілки ← →)"

func _on_flip_timer_timeout():
	# Якщо гравець не перевернув вчасно
	if current_phase == GAME_PHASE.FLIP:
		handle_flip(0)  # 0 = не перевернуто

func handle_flip(quality: int):
	# Додаємо очки за перевертання
	match quality:
		2:  # Ідеальне перевертання
			current_score += 10
			show_hit_feedback("Ідеальне перевертання!", Color(0, 1, 0))
		1:  # Хороше перевертання
			current_score += 7
			show_hit_feedback("Хороше перевертання", Color(0.5, 1, 0))
		0:  # Запізніле або не перевернуто
			current_score += 3
			show_hit_feedback("Запізніле перевертання", Color(1, 1, 0))
	
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
			direction_timer.stop()
			
			# Визначаємо якість вибору напрямку на основі часу реакції
			var elapsed_time = reaction_time * 0.7 - direction_timer.time_left
			if elapsed_time < reaction_time * 0.3:
				direction_quality = 2  # Точний вибір
			else:
				direction_quality = 1  # Запізнілий вибір
		elif event.is_action_pressed(UP_ACTION) or event.is_action_pressed(DOWN_ACTION):
			direction_timer.stop()
			direction_quality = 0  # Неправильний вибір
		
		if direction_quality > 0:
			handle_direction(direction_quality)
	
	# Обробка натискання для фази перевертання
	elif current_phase == GAME_PHASE.FLIP:
		if event.is_action_pressed(LEFT_ACTION) or event.is_action_pressed(RIGHT_ACTION):
			flip_timer.stop()
			
			# Визначаємо якість перевертання на основі часу реакції
			var elapsed_time = reaction_time * 1.3 - flip_timer.time_left
			var flip_quality
			
			if elapsed_time < reaction_time * 0.4:
				flip_quality = 2  # Ідеальне перевертання
			elif elapsed_time < reaction_time * 0.8:
				flip_quality = 1  # Хороше перевертання
			else:
				flip_quality = 0  # Запізніле перевертання
			
			handle_flip(flip_quality)
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func end_game(success: bool):
	visible = false
	mini_game_completed.emit(success, current_score)

func cancel_game():
	visible = false
	mini_game_cancelled.emit()
