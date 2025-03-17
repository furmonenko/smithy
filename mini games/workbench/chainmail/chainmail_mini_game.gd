# chainmail_mini_game.gd
extends MiniGame
class_name ChainmailMiniGame

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Стани гри
enum GAME_STATE { IDLE = 0, RIVETING = 1, COMPLETE = 2 }

# Константи
const TOTAL_RINGS = 6  # Загальна кількість кілець для клепання
const RIVET_ACTION = "hit_button_a"  # Кнопка для клепання (може бути змінена через InputManager)

# Змінні для зберігання оптимальних позицій кілець
var optimal_positions = []  # Зберігає оптимальні позиції для кілець (кути в радіанах)

# Налаштування гри
@export var skill_level: int = SKILL_LEVEL.APPRENTICE
@export var marker_speed_min: float = 1.0  # Мінімальна базова швидкість маркера (радіан/сек)
@export var marker_speed_max: float = 4.0  # Максимальна базова швидкість маркера
@export var tolerance_angle_min: float = 0.1  # Мінімальна допустима похибка кута (в радіанах)
@export var tolerance_angle_max: float = 0.5  # Максимальна допустима похибка кута

# Параметри, залежні від рівня майстерності
var marker_speed: float  # Поточна швидкість маркера (радіан/сек)
var tolerance_angle: float  # Поточна допустима похибка кута

# Змінні для відстеження прогресу
var current_state: int = GAME_STATE.IDLE
var current_angle: float = 0.0  # Поточний кут маркера
var placed_rings: int = 0  # Кількість розміщених кілець
var current_score: int = 100  # Початковий рахунок (максимум)
var ring_positions = []  # Позиції розміщених кілець (кути в радіанах)
var next_optimal_position: float = 0.0  # Наступна оптимальна позиція

# Візуальні елементи
var marker_tween: Tween = null

# Таймери
var game_timer: Timer
var feedback_timer: Timer

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			marker_speed = marker_speed_max
			tolerance_angle = tolerance_angle_min
		SKILL_LEVEL.JOURNEYMAN:
			marker_speed = marker_speed_max * 0.8
			tolerance_angle = tolerance_angle_min * 2
		SKILL_LEVEL.BLACKSMITH:
			marker_speed = marker_speed_min * 2
			tolerance_angle = tolerance_angle_min * 3
		SKILL_LEVEL.MASTER:
			marker_speed = marker_speed_min
			tolerance_angle = tolerance_angle_max
	
	# Створюємо і налаштовуємо таймери
	game_timer = Timer.new()
	game_timer.one_shot = false
	game_timer.wait_time = 0.05  # Оновлюємо стан кожні 0.05 секунди
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	feedback_timer = Timer.new()
	feedback_timer.one_shot = true
	feedback_timer.wait_time = 2.0
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	add_child(feedback_timer)
	
	InputManager.input_type_changed.connect(_on_input_type_changed)
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	# Розраховуємо оптимальні позиції для кілець (рівномірно розподілені кути)
	calculate_optimal_positions()
	
	# Приховуємо на початку
	visible = false
	
	# Запускаємо гру
	start_game()

func setup_ui():
	# Налаштовуємо UI елементи
	setup_rivet_button()
	
	# Оновлюємо лічильник кілець
	update_rings_counter()
	
	# Оновлюємо інструкції
	var button_name = InputManager.get_button_display_name(RIVET_ACTION)
	%InstructionsLabel.text = "Натисніть %s коли маркер буде на правильній позиції" % button_name

func setup_rivet_button():
	# Оновлюємо текстуру кнопки клепання
	%RivetButton.texture = InputManager.get_button_texture(RIVET_ACTION)
	%RivetButton.visible = true

func update_rings_counter():
	# Оновлюємо лічильник кілець
	%RingsCounter.text = "Кільця: %d/%d" % [placed_rings, TOTAL_RINGS]
	
	# Оновлюємо візуальний лічильник кілець (робимо невидимими використані кільця)
	var rings_container = %RingsLeft
	if rings_container:
		for i in range(TOTAL_RINGS):
			var ring_node = rings_container.get_node_or_null("Ring" + str(i + 1))
			if ring_node:
				ring_node.visible = i >= placed_rings
				
	# Оновлюємо індикатор якості
	var quality_meter = get_node_or_null("UI/RightPanel/QualityMeter")
	if quality_meter:
		quality_meter.value = current_score

func start_marker_rotation():
	# Зупиняємо попередній tween, якщо він існує
	if marker_tween != null and marker_tween.is_valid():
		marker_tween.kill()
	
	# Починаємо нову анімацію обертання маркера
	marker_tween = create_tween()
	marker_tween.set_loops()  # Нескінченні повторення
	marker_tween.tween_method(Callable(self, "_update_marker_position"), 0.0, TAU, TAU / marker_speed)

func _update_marker_position(angle: float):
	current_angle = angle
	
	if has_node("%Marker"):
		# Get the center ring size to calculate proper radius
		var center_ring = %CenterRing
		var ring_size = center_ring.size
		var radius = min(ring_size.x, ring_size.y) / 2  # Use actual size of the center ring
		
		# Calculate center point properly accounting for the UI layout
		var center = center_ring.global_position + center_ring.pivot_offset
		
		# Calculate marker position along the circle
		var marker_pos = center + Vector2(cos(angle), sin(angle)) * radius
		%Marker.global_position = marker_pos
		
		# Rotate marker to point inward
		%Marker.rotation = angle + PI/2
		
		# Check proximity to optimal position for visual feedback
		if placed_rings < TOTAL_RINGS:
			var optimal_position = next_optimal_position
			var diff = abs(angle_distance(angle, optimal_position))
			
			# Change marker color based on proximity to optimal position
			if diff < tolerance_angle * 0.5:
				# Very close - green
				%Marker.modulate = Color(0, 1, 0, 1)
			elif diff < tolerance_angle:
				# Close enough - yellow
				%Marker.modulate = Color(1, 1, 0, 1)
			else:
				# Far - white
				%Marker.modulate = Color(1, 1, 1, 1)

func calculate_optimal_positions():
	# Розраховуємо оптимальні позиції для кілець (рівномірно розподілені кути)
	var angle_step = TAU / TOTAL_RINGS  # Кут між кільцями у радіанах
	
	# Випадковий початковий зсув, щоб кожна гра була унікальною
	var random_offset = randf_range(0, TAU)
	
	# Очищаємо масив перед заповненням
	optimal_positions.clear()
	
	for i in range(TOTAL_RINGS):
		# Додаємо випадковий зсув до кожної оптимальної позиції
		var optimal_angle = random_offset + i * angle_step
		# Нормалізуємо кут, щоб він був у межах [0, TAU)
		optimal_angle = fmod(optimal_angle, TAU)
		optimal_positions.append(optimal_angle)
	
	# Перша оптимальна позиція
	next_optimal_position = optimal_positions[0]

func start_game():
	visible = true
	current_state = GAME_STATE.RIVETING
	placed_rings = 0
	current_score = 100
	ring_positions.clear()
	
	# Розраховуємо оптимальні позиції для кілець
	calculate_optimal_positions()
	
	# Показуємо центральне кільце і маркер
	%CenterRing.visible = true
	%Marker.visible = true
	
	# Приховуємо всі кільця на початку
	for i in range(TOTAL_RINGS):
		var ring_node = get_node_or_null("%PlacedRing" + str(i))
		if ring_node:
			ring_node.visible = false
	
	# Оновлюємо лічильник кілець
	update_rings_counter()
	
	# Запускаємо таймер гри
	game_timer.start()
	
	# Запускаємо обертання маркера
	start_marker_rotation()
	
	# Показуємо початкову підказку
	show_feedback("Заклепайте кільце", Color(1, 1, 1))

func _input(event):
	if not visible or current_state != GAME_STATE.RIVETING:
		return
	
	# Обробляємо натискання кнопки клепання
	if event.is_action_pressed(RIVET_ACTION):
		place_ring()
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func place_ring():
	# Check if we can still place rings
	if placed_rings >= TOTAL_RINGS:
		return
	
	# Store the angle of placement
	ring_positions.append(current_angle)
	
	# Show the corresponding ring at the marker's exact position
	var ring_node = get_node_or_null("%PlacedRing" + str(placed_rings))
	if ring_node:
		# First make sure the ring is visible before setting position
		ring_node.visible = true
		
		# Set the size and appearance
		ring_node.custom_minimum_size = Vector2(30, 30)  # Smaller than default 95x95
		
		# Use the marker's exact position
		# The problem is likely that the texturerect has different positioning 
		# properties than the marker colorRect
		var marker_center = %Marker.global_position + %Marker.pivot_offset
		
		# We need to account for the ring's own pivot offset
		ring_node.global_position = marker_center - ring_node.pivot_offset
		
		# Debug prints
		print("Marker position: ", %Marker.global_position)
		print("Ring position (before): ", ring_node.global_position)
		
		# Debug print after update
		print("Ring position (after): ", ring_node.global_position)
	
	# Increase placed rings counter
	placed_rings += 1
	
	# Evaluate placement quality
	evaluate_placement()
	
	# Update rings counter
	update_rings_counter()
	
	# If all rings are placed, finish the game
	if placed_rings >= TOTAL_RINGS:
		finish_game()
	else:
		# Calculate next optimal position
		next_optimal_position = optimal_positions[placed_rings]

func evaluate_placement():
	# Якщо це перше кільце, воно завжди розміщується правильно
	if placed_rings <= 1:
		show_feedback("Кільце заклепано!", Color(0, 1, 0))
		return
	
	# Перевіряємо відстань до найближчого кільця
	var current_position = ring_positions[placed_rings - 1]
	var too_close = false
	var closest_distance = TAU  # Ініціалізуємо максимально можливим значенням
	
	for i in range(placed_rings - 1):
		var other_position = ring_positions[i]
		var angle_diff = abs(angle_distance(current_position, other_position))
		
		# Оновлюємо найменшу відстань
		closest_distance = min(closest_distance, angle_diff)
		
		# Перевіряємо, чи кільце не занадто близько до іншого
		# Очікувана відстань - рівномірно розподілені кільця на колі (TAU / TOTAL_RINGS)
		var expected_distance = TAU / TOTAL_RINGS
		if angle_diff < expected_distance - tolerance_angle:
			too_close = true
			break
	
	if too_close:
		# Кільце розміщено занадто близько до іншого
		current_score = max(25, current_score - 15)  # Знімаємо 15 очок, але не менше 25
		
		# Додаємо візуальне відображення помилки
		var ring_node = get_node_or_null("%PlacedRing" + str(placed_rings - 1))
		if ring_node:
			# Змінюємо колір кільця на червоний для позначення помилки
			ring_node.modulate = Color(1, 0.5, 0.5)
			
		show_feedback("Кільце занадто близько!", Color(1, 0.5, 0))
	else:
		# Перевіряємо, наскільки точно розміщено
		var ideal_distance = TAU / TOTAL_RINGS
		var precision = abs(closest_distance - ideal_distance) / ideal_distance
		
		var feedback_text = "Правильно розміщено!"
		var feedback_color = Color(0, 1, 0)
		
		# Додаємо оцінку точності розміщення
		if precision < 0.1:  # Дуже точно
			feedback_text = "Ідеальне розміщення!"
			feedback_color = Color(0, 1, 0.5)
		elif precision < 0.2:  # Досить точно
			feedback_text = "Хороше розміщення!"
			feedback_color = Color(0.5, 1, 0)
		
		show_feedback(feedback_text, feedback_color)

func angle_distance(angle1: float, angle2: float) -> float:
	# Розраховує найкоротшу відстань між двома кутами
	var diff = fmod(abs(angle1 - angle2), TAU)
	return min(diff, TAU - diff)

func finish_game():
	# Зупиняємо таймер і tween
	game_timer.stop()
	
	if marker_tween and marker_tween.is_valid():
		marker_tween.kill()
	
	current_state = GAME_STATE.COMPLETE
	
	# Приховуємо маркер
	%Marker.visible = false
	
	# Показуємо результат
	show_final_result()
	
	# Очікуємо 2 секунди перед завершенням гри
	await get_tree().create_timer(2.0).timeout
	
	# Завершуємо гру
	end_game(true, current_score)

func show_final_result():
	var quality_text = ""
	var color = Color.WHITE
	
	if current_score >= 90:
		quality_text = "Ідеальна кульчуга!"
		color = Color(0, 1, 0)
	elif current_score >= 75:
		quality_text = "Якісна кульчуга!"
		color = Color(0.5, 1, 0)
	elif current_score >= 50:
		quality_text = "Нормальна кульчуга"
		color = Color(1, 1, 0)
	else:
		quality_text = "Слабка кульчуга"
		color = Color(1, 0.5, 0)
	
	show_feedback(quality_text + "\nОцінка: " + str(current_score), color)

func show_feedback(text: String, color: Color = Color(1, 1, 1)):
	%FeedbackLabel.text = text
	%FeedbackLabel.add_theme_color_override("font_color", color)
	%FeedbackLabel.visible = true
	
	# Запускаємо таймер для приховування підказки
	feedback_timer.start()

func _on_feedback_timer_timeout():
	%FeedbackLabel.visible = false

func _on_game_timer_timeout():
	# Оновлюємо стан гри
	pass  # Більшість логіки вже в _update_marker_position

func _on_input_type_changed(_device_type):
	# Оновлюємо текстури кнопок
	setup_rivet_button()
	
	# Оновлюємо інструкції
	var button_name = InputManager.get_button_display_name(RIVET_ACTION)
	%InstructionsLabel.text = "Натисніть %s коли маркер буде на правильній позиції" % button_name
