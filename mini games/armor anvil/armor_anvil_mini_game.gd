# armor_anvil_mini_game.gd
extends AnvilMiniGame
class_name ArmorAnvilMiniGame

# Можливі напрямки
enum DIRECTION_TYPE { DOWN = 0, LEFT = 1, RIGHT = 2 }

# Поточний тип напрямку
var current_direction_type: int = DIRECTION_TYPE.DOWN
# Історія напрямків для відстеження чергування
var direction_history = []

func _ready():
	# Викликаємо _ready() з базового класу
	super._ready()
	# Оновлюємо рівні майстерності та налаштування для брони
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			target_ring_size = 0.30
			reaction_time = 2.2
			cooling_rate = 0.25
		SKILL_LEVEL.JOURNEYMAN:  
			target_ring_size = 0.35
			reaction_time = 2.4
			cooling_rate = 0.35
		SKILL_LEVEL.BLACKSMITH: 
			target_ring_size = 0.40
			reaction_time = 2.6
			cooling_rate = 0.45
		SKILL_LEVEL.MASTER: 
			target_ring_size = 0.45
			reaction_time = 3.0
			cooling_rate = 0.55
	
	# Для бронярського ковадла не використовуємо функціонал перевертання
	flip_half_done = true

# Перевизначаємо функцію для обробки введення
func _input(event):
	if not visible:
		return
	
	# Обробка натискання для фази удару
	if current_phase == GAME_PHASE.HIT:
		if event.is_action_pressed(current_hit_button):
			ring_timer.stop()
			
			# Визначаємо якість удару на основі поточного розміру шейдера
			if has_node("%HitIndicator") and %HitIndicator.material:
				var current_shader_size = %HitIndicator.material.get_shader_parameter("current_size")
				var target_shader_size = %HitIndicator.material.get_shader_parameter("target_size")
				var good_zone_outer = %HitIndicator.material.get_shader_parameter("good_zone_outer")
				var satisfactory_zone_outer = %HitIndicator.material.get_shader_parameter("satisfactory_zone_outer")
				var ring_thickness = %HitIndicator.material.get_shader_parameter("ring_thickness")
				
				var hit_quality
				
				# Обчислюємо внутрішню і зовнішню межу зеленої зони
				var perfect_inner = target_shader_size - ring_thickness/2.0
				var perfect_outer = target_shader_size + ring_thickness/2.0
				
				if current_shader_size < perfect_inner:
					# Сіре коло пройшло повз зелене і стало меншим - це промах
					hit_quality = 0
				elif current_shader_size >= perfect_inner and current_shader_size <= perfect_outer:
					# В межах ідеальної зеленої зони
					var diff = abs(current_shader_size - target_shader_size)
					if diff < 0.01:
						hit_quality = 3  # Ідеальний удар
					else:
						hit_quality = 2  # Хороший удар всередині зеленої зони
				elif current_shader_size <= good_zone_outer:
					# В межах хорошої зони (салатової)
					hit_quality = 2  # Хороший удар
				elif current_shader_size <= satisfactory_zone_outer:
					# В межах задовільної зони (жовтої)
					hit_quality = 1  # Задовільний удар
				else:
					# Поза всіма зонами
					hit_quality = 0  # Промах
				
				handle_hit(hit_quality)
			else:
				# Резервний варіант, якщо шейдер недоступний
				handle_hit(0)
		elif event.is_action_pressed("hit_button_a") or event.is_action_pressed("hit_button_b") or \
			 event.is_action_pressed("hit_button_x") or event.is_action_pressed("hit_button_y"):
			# Натиснута неправильна кнопка
			ring_timer.stop()
			handle_hit(0)  # Промах
	
	# Обробка натискання для фази вибору напрямку
	elif current_phase == GAME_PHASE.DIRECTION:
		var direction_quality = 0
		var correct_action = get_correct_direction_action()
		
		if event.is_action_pressed(correct_action):
			# Визначаємо якість вибору напрямку на основі часу реакції
			var wait_time = direction_timer.wait_time
			var elapsed_time = wait_time - direction_timer.time_left
			var time_percentage = elapsed_time / wait_time * 100
			
			# Зупиняємо таймер ПІСЛЯ отримання часу, що залишився
			direction_timer.stop()
			
			# Перевіряємо час реакції
			if time_percentage < 20:  # Перша частина доступного часу
				direction_quality = 2  # Точний вибір
			else:
				direction_quality = 1  # Запізнілий вибір
				
			handle_direction(direction_quality)
			
			# Додаємо напрямок в історію
			direction_history.append(current_direction_type)
			
			# Вибираємо наступний напрямок, який відрізняється від поточного
			set_next_direction_type()
		elif event.is_action_pressed(UP_ACTION) or event.is_action_pressed(DOWN_ACTION) or \
			  event.is_action_pressed(LEFT_ACTION) or event.is_action_pressed(RIGHT_ACTION):
			# Неправильний напрямок натиснуто
			direction_timer.stop()
			handle_direction(0)  # Неправильний вибір
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

# Визначає дії для поточного типу напрямку
func get_correct_direction_action() -> String:
	match current_direction_type:
		DIRECTION_TYPE.DOWN:
			return DOWN_ACTION
		DIRECTION_TYPE.LEFT:
			return LEFT_ACTION
		DIRECTION_TYPE.RIGHT:
			return RIGHT_ACTION
	return DOWN_ACTION

# Вибирає наступний тип напрямку, що відрізняється від поточного
func set_next_direction_type():
	var available_directions = [DIRECTION_TYPE.DOWN, DIRECTION_TYPE.LEFT, DIRECTION_TYPE.RIGHT]
	var last_direction = current_direction_type
	
	# Видаляємо поточний напрямок зі списку доступних
	available_directions.erase(last_direction)
	
	# Вибираємо випадковий напрямок із тих, що залишилися
	current_direction_type = available_directions[randi() % available_directions.size()]

# Перевизначаємо функцію для початку фази вибору напрямку
func start_direction_phase():
	current_phase = GAME_PHASE.DIRECTION
	
	# Приховуємо всі кнопки ударів спочатку
	%HitButtonA.visible = false
	%HitButtonB.visible = false
	%HitButtonX.visible = false
	%HitButtonY.visible = false
	
	# Визначаємо кнопку, яку покажемо для поточного напрямку
	var button_to_show = null
	
	match current_direction_type:
		DIRECTION_TYPE.DOWN:
			button_to_show = %HitButtonA
			button_to_show.texture = InputManager.get_button_texture(DOWN_ACTION)
		DIRECTION_TYPE.LEFT:
			button_to_show = %HitButtonB
			button_to_show.texture = InputManager.get_button_texture(LEFT_ACTION)
		DIRECTION_TYPE.RIGHT:
			button_to_show = %HitButtonX
			button_to_show.texture = InputManager.get_button_texture(RIGHT_ACTION)
	
	# Показуємо обрану кнопку
	if button_to_show:
		button_to_show.visible = true
		
		# Анімуємо кнопку для привернення уваги
		var tween = create_tween()
		tween.tween_property(button_to_show, "scale", Vector2(1.1, 1.1), 0.2)
		tween.tween_property(button_to_show, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Більше часу на вибір напрямку
	direction_timer.wait_time = reaction_time * 0.9
	direction_timer.start()
	
	var direction_action = get_correct_direction_action()
	var button_name = InputManager.get_button_display_name(direction_action)
	%InstructionsLabel.text = "Натисніть %s" % button_name

# Перевизначаємо обробку сигналу зміни типу введення
func _on_input_type_changed(_device_type):
	# Оновлюємо текстури всіх кнопок
	super._on_input_type_changed(_device_type)

# Перевизначаємо функцію для старту гри
func start_game():
	super.start_game()
	
	# Встановлюємо початковий напрямок як DOWN для першого удару
	current_direction_type = DIRECTION_TYPE.DOWN
	direction_history.clear()
	
	# Для бронярського ковадла не використовуємо функціонал перевертання
	flip_half_done = true

# Оновлюємо функцію setup_hit_buttons для встановлення правильних розмірів:
func setup_hit_buttons():
	# Викликаємо батьківську функцію для налаштування кнопок удару
	super.setup_hit_buttons()
	
	# Переконуємося, що всі кнопки мають однакові розміри та позиції
	if has_node("%HitButtonA") and has_node("%HitButtonB") and has_node("%HitButtonX") and has_node("%HitButtonY"):
		var reference = %HitButtonA
		var buttons = [%HitButtonB, %HitButtonX, %HitButtonY]
		
		for button in buttons:
			button.position = reference.position
			button.size = reference.size
			button.custom_minimum_size = reference.custom_minimum_size
			button.pivot_offset = reference.pivot_offset

# Оновлюємо функцію handle_hit, щоб не переходити до фази перевертання
func handle_hit(quality: int = -1):
	# Зупиняємо всі тайм-лайни та таймери
	ring_timer.stop()
	var existing_tweens = get_tree().get_processed_tweens()
	for tween in existing_tweens:
		if tween.is_valid():
			tween.kill()
	
	# Визначаємо якість удару
	if quality == -1 and has_node("%HitIndicator") and %HitIndicator.material:
		var current_shader_size = %HitIndicator.material.get_shader_parameter("current_size")
		var target_shader_size = %HitIndicator.material.get_shader_parameter("target_size")
		var good_zone_outer = %HitIndicator.material.get_shader_parameter("good_zone_outer")
		var satisfactory_zone_outer = %HitIndicator.material.get_shader_parameter("satisfactory_zone_outer")
		var ring_thickness = %HitIndicator.material.get_shader_parameter("ring_thickness")
		
		var perfect_inner = target_shader_size - ring_thickness/2.0
		var perfect_outer = target_shader_size + ring_thickness/2.0
		
		if current_shader_size < perfect_inner:
			quality = 0  # Промах
		elif current_shader_size >= perfect_inner and current_shader_size <= perfect_outer:
			var diff = abs(current_shader_size - target_shader_size)
			if diff < 0.01:
				quality = 3  # Ідеальний удар
			else:
				quality = 2  # Хороший удар
		elif current_shader_size <= good_zone_outer:
			quality = 2  # Хороший удар
		elif current_shader_size <= satisfactory_zone_outer:
			quality = 1  # Задовільний удар
		else:
			quality = 0  # Промах

	last_hit_quality = quality
	
	# Показуємо візуальний результат удару
	show_hit_result(quality)
	
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
			temp_multiplier = 0.9
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
	
	# Додаємо очки
	current_score += hit_points
	
	# Збільшуємо лічильник ударів
	current_hits += 1
	update_hit_counter()
	
	# Симулюємо удар молотом на заготовці
	hammer_strike()
	
	# Перевіряємо охолодження
	check_cooling()
	
	# Перевіряємо завершення гри
	if current_hits >= total_hits_required:
		end_game(true)
		return
	
	# Затримка перед показом фази вибору напрямку
	start_direction_phase()

# Змінений метод handle_direction для роботи з напрямками
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
	
	# Додаємо очки
	current_score += direction_points
	
	# Переходимо до фази удару
	start_hit_phase(false)

# Додаємо інший звук для удару при куванні броні
func hammer_strike():
	# Викликаємо базову функцію
	super.hammer_strike()
	
	# Можна додати спеціальний звук для кування броні або змінити гучність
	if has_node("%AnvilHit"):
		%AnvilHit.pitch_scale = randf_range(0.9, 1.0)  # Нижчий тон для броні

# Заміняємо текстуру на більш відповідну для броні (опціонально)
func setup_shader_for_workpiece():
	# Викликаємо базову функцію
	super.setup_shader_for_workpiece()
	
	# Змінюємо деякі параметри для броні
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		
		# Змінюємо параметри деформації для броні
		shader_material.set_shader_parameter("initial_deform", Vector2(2.0, 2.0))
		shader_material.set_shader_parameter("bulge_strength", 0.25)
		shader_material.set_shader_parameter("impact_radius", 0.3)
		
		# Встановлюємо початковий параметр flip_done як true для вимкнення фази обертання
		shader_material.set_shader_parameter("flip_done", true)

# Показуємо детальний результат гри з урахуванням особливостей броні
func end_game(success: bool, score: int = 0):
	# Виводимо детальний результат у консоль
	print("==========================================")
	print("РЕЗУЛЬТАТ МІНІ-ГРИ БРОНЯРСЬКЕ КОВАДЛО")
	print("==========================================")
	print("Рівень майстерності: " + ["Учень", "Підмайстер", "Коваль", "Майстер-коваль"][skill_level])
	print("Фінальний рахунок: %d" % current_score)
	
	# Якість броні
	var quality = "звичайна"
	if current_score > 90:
		quality = "легендарна"
	elif current_score > 75:
		quality = "видатна"
	elif current_score > 60:
		quality = "хороша"
	elif current_score > 40:
		quality = "середня"
	
	print("\nЯкість виготовленої броні: %s" % quality)
	print("==========================================")
	
	# Приховуємо UI
	visible = false
	
	# Відправляємо сигнал про завершення з результатом
	mini_game_completed.emit(success, current_score)
