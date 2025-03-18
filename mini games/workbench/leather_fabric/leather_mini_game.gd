# leather_mini_game.gd
extends MiniGame
class_name LeatherMiniGame

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Стани гри
enum GAME_STATE { IDLE = 0, CUTTING = 1, COMPLETE = 2 }

# Кнопки для зміни напрямку
const DIRECTION_BUTTONS = {
	"up": "ui_up",
	"down": "ui_down",
	"left": "ui_left",
	"right": "ui_right"
}

# Налаштування гри
@export var skill_level: int = SKILL_LEVEL.APPRENTICE
@export var arrow_speed_factor: float = 1.0

# Параметри, що залежать від рівня майстерності
var reaction_window: float
var perfect_timing_window: float
var arrow_speed: float

# Змінні для відстеження прогресу
var current_state: int = GAME_STATE.IDLE
var current_score: int = 100
var current_path_index: int = 0
var current_segment_progress: float = 0.0
var next_direction: String = "right"
var is_turning_point: bool = false
var current_hits: int = 0
var processed_segments: Array = []

var turn_processed: bool = false
var missed_turns: int = 0

# Візуальні елементи
var cutting_path: Array = []
var current_position: Vector2 = Vector2.ZERO
var direction_arrow: Polygon2D
var cut_line: Line2D
var next_button_texture: TextureRect

# Таймери і твіни
var game_timer: Timer
var reaction_timer: Timer
var arrow_tween: Tween = null

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			reaction_window = 1.5
			perfect_timing_window = 0.5
			arrow_speed = 40.0
		SKILL_LEVEL.JOURNEYMAN:
			reaction_window = 1.2
			perfect_timing_window = 0.4
			arrow_speed = 50.0
		SKILL_LEVEL.BLACKSMITH:
			reaction_window = 1.0
			perfect_timing_window = 0.3
			arrow_speed = 60.0
		SKILL_LEVEL.MASTER:
			reaction_window = 1.0
			perfect_timing_window = 1.0
			arrow_speed = 150.0
	
	# Генеруємо шлях для вирізання
	generate_cutting_path(6)
			
	# Створюємо і налаштовуємо таймери
	game_timer = Timer.new()
	game_timer.one_shot = false
	game_timer.wait_time = 0.05
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	reaction_timer = Timer.new()
	reaction_timer.one_shot = true
	reaction_timer.timeout.connect(_on_reaction_timer_timeout)
	add_child(reaction_timer)
	
	InputManager.input_type_changed.connect(_on_input_type_changed)
	
	# Налаштовуємо UI елементи
	setup_ui()
	
	# Приховуємо на початку
	visible = false
	
	# Запускаємо гру
	start_game()

func generate_cutting_path(num_points: int):
	cutting_path.clear()
	
	var workpiece_width = 380
	var workpiece_height = 300
	var margin = 40
	
	var center_x = workpiece_width / 2
	var center_y = workpiece_height / 2
	
	var radius_x = (workpiece_width / 2) - margin
	var radius_y = (workpiece_height / 2) - margin
	
	# Генеруємо випадковий шаблон
	var pattern_type = randi() % 4
	var points = []
	
	match pattern_type:
		0:  # Шестикутник
			for i in range(6):
				var angle = 2 * PI * i / 6
				var variation = randf_range(0.8, 1.2)
				
				var r_x = radius_x * variation
				var r_y = radius_y * variation
				
				var x = center_x + cos(angle) * r_x
				var y = center_y + sin(angle) * r_y
				
				points.append(Vector2(x, y))
			
			# Закриваємо контур
			points.append(points[0])
			
		1:  # Зигзаг
			# Верхня ліва точка
			points.append(Vector2(center_x - radius_x, center_y - radius_y))
			
			# Верхня права через середину
			points.append(Vector2(center_x, center_y - radius_y * 0.7))
			points.append(Vector2(center_x + radius_x, center_y - radius_y))
			
			# Нижня права через середину
			points.append(Vector2(center_x + radius_x * 0.7, center_y + radius_y * 0.5))
			
			# Нижня ліва
			points.append(Vector2(center_x - radius_x * 0.5, center_y + radius_y))
			
			# Замикаємо контур
			points.append(Vector2(center_x - radius_x, center_y - radius_y))
			
		2:  # Складна форма
			points.append(Vector2(center_x - radius_x, center_y))
			points.append(Vector2(center_x - radius_x * 0.5, center_y - radius_y))
			points.append(Vector2(center_x + radius_x * 0.5, center_y - radius_y * 0.7))
			points.append(Vector2(center_x + radius_x, center_y))
			points.append(Vector2(center_x, center_y + radius_y))
			points.append(Vector2(center_x - radius_x, center_y))
			
		3:  # Форма щита
			points.append(Vector2(center_x - radius_x * 0.7, center_y - radius_y))
			points.append(Vector2(center_x + radius_x * 0.7, center_y - radius_y))
			points.append(Vector2(center_x + radius_x, center_y))
			points.append(Vector2(center_x, center_y + radius_y))
			points.append(Vector2(center_x - radius_x, center_y))
			points.append(Vector2(center_x - radius_x * 0.7, center_y - radius_y))
	
	cutting_path = points
	
	# Встановлюємо початкову позицію
	current_position = cutting_path[0]
	
	# Обчислюємо перший напрямок
	calculate_next_direction()

func calculate_next_direction():
	if current_path_index >= cutting_path.size() - 1:
		return
	
	var current_point = cutting_path[current_path_index]
	var next_point = cutting_path[current_path_index + 1]
	var direction_vector = next_point - current_point
	
	# Визначаємо найбільший компонент напрямку
	var abs_x = abs(direction_vector.x)
	var abs_y = abs(direction_vector.y)
	
	if abs_x > abs_y:
		# Горизонтальний рух переважає
		next_direction = "right" if direction_vector.x > 0 else "left"
	else:
		# Вертикальний рух переважає
		next_direction = "down" if direction_vector.y > 0 else "up"
	
	# Більш помітна анімація кнопки напрямку
	if has_node("%NextDirectionButton"):
		var button = %NextDirectionButton
		button.texture = InputManager.get_button_texture(DIRECTION_BUTTONS[next_direction])
		button.modulate = Color(1, 1, 1, 1)
		button.scale = Vector2(1.5, 1.5)
		
		# Додаємо анімацію пульсації для привернення уваги
		var tween = create_tween().set_loops(2)
		tween.tween_property(button, "scale", Vector2(1.8, 1.8), 0.3)
		tween.tween_property(button, "scale", Vector2(1.5, 1.5), 0.3)
		
		# Показуємо текст підказки
		var button_name = InputManager.get_button_display_name(DIRECTION_BUTTONS[next_direction])
		%InstructionsLabel.text = "Натисніть %s на повороті" % button_name

func create_dotted_line_texture() -> Texture2D:
	var img = Image.create(8, 1, false, Image.FORMAT_RGBA8)
	
	for i in range(5):
		img.set_pixel(i, 0, Color(1, 1, 1, 1))
	
	for i in range(5, 8):
		img.set_pixel(i, 0, Color(1, 1, 1, 0))
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_cutting_lines():
	var existing_lines = get_node_or_null("%CuttingLines")
	if existing_lines:
		existing_lines.queue_free()
	
	var lines_node = Node2D.new()
	lines_node.name = "CuttingLines"
	lines_node.unique_name_in_owner = true
	%WorkpieceRect.add_child(lines_node)
	
	var contour_line = Line2D.new()
	contour_line.name = "ContourLine"
	contour_line.default_color = Color(0.05, 0.05, 0.05, 0.9)
	contour_line.width = 6.0
	contour_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	contour_line.texture = create_dotted_line_texture()
	
	for point in cutting_path:
		contour_line.add_point(point)
	
	lines_node.add_child(contour_line)
	
	for i in range(cutting_path.size()):
		var turn_marker = ColorRect.new()
		turn_marker.size = Vector2(12, 12)
		turn_marker.color = Color(0.9, 0.1, 0.1, 0.9)
		turn_marker.position = cutting_path[i] - Vector2(6, 6)
		lines_node.add_child(turn_marker)

func create_direction_arrow():
	direction_arrow = Polygon2D.new()
	direction_arrow.name = "DirectionArrow"
	direction_arrow.unique_name_in_owner = true
	
	var arrow_points = [
		Vector2(35, 0),
		Vector2(-15, -25),
		Vector2(0, 0),
		Vector2(-15, 25)
	]
	direction_arrow.polygon = arrow_points
	direction_arrow.color = Color(1, 0, 0, 1.0)
	
	%WorkpieceRect.add_child(direction_arrow)
	
	cut_line = Line2D.new()
	cut_line.name = "CutLine"
	cut_line.unique_name_in_owner = true
	cut_line.default_color = Color(0.05, 0.05, 0.05, 1.0)
	cut_line.width = 8.0
	%WorkpieceRect.add_child(cut_line)
	
	cut_line.add_point(cutting_path[0])
	
	update_arrow_position(cutting_path[0])
	update_arrow_orientation()

func setup_ui():
	if has_node("%WorkpieceRect"):
		%WorkpieceRect.color = Color(0.6, 0.4, 0.2, 1.0)
		
		draw_cutting_lines()
		
		if not has_node("%DirectionArrow"):
			create_direction_arrow()
	
	calculate_next_direction()

func update_arrow_position(position: Vector2):
	if direction_arrow:
		direction_arrow.position = position
		
		if cut_line and cut_line.get_point_count() > 0:
			var last_point = cut_line.get_point_position(cut_line.get_point_count() - 1)
			
			if position.distance_to(last_point) > 5.0:
				cut_line.add_point(position)
		
		play_cutting_sound()

func update_arrow_orientation():
	if direction_arrow and current_path_index < cutting_path.size() - 1:
		var current_point = cutting_path[current_path_index]
		var next_point = cutting_path[current_path_index + 1]
		var direction_vector = next_point - current_point
		
		var angle = direction_vector.angle()
		direction_arrow.rotation = angle

func start_cutting():
	current_state = GAME_STATE.CUTTING
	
	show_feedback("Підготуйтесь...", Color(1, 1, 1))
	
	await get_tree().create_timer(1.0).timeout
	
	move_arrow_along_segment()
	
	var button_name = InputManager.get_button_display_name(DIRECTION_BUTTONS[next_direction])
	%InstructionsLabel.text = "Натисніть %s на повороті" % button_name
	
	show_feedback("Ріжемо...", Color(0, 0.7, 1))
	
func handle_turn(correct_button: bool):
	reaction_timer.stop()
	
	turn_processed = true
	current_hits += 1
	
	if not processed_segments.has(current_path_index):
		processed_segments.append(current_path_index)
	
	flash_screen_feedback(correct_button)
	
	if correct_button:
		var turn_threshold = 0.95
		var diff = abs(current_segment_progress - turn_threshold)
		
		if diff <= 0.2:
			show_feedback("Ідеально!", Color(0, 1, 0))
		else:
			show_feedback("Добре", Color(0.5, 1, 0))
			current_score = max(0, current_score - 1)
	else:
		var penalty = 5
		current_score = max(0, current_score - penalty)
		
		show_feedback("Неправильний напрямок!", Color(1, 0, 0))
	
	is_turning_point = false
	
func show_feedback(text: String, color: Color = Color(1, 1, 1)):
	if has_node("%FeedbackLabel"):
		%FeedbackLabel.text = text
		%FeedbackLabel.add_theme_color_override("font_color", color)
		%FeedbackLabel.visible = true
		
		var tween = create_tween()
		tween.tween_property(%FeedbackLabel, "modulate", Color(1, 1, 1, 0), 3).from(Color(1, 1, 1, 1))
		tween.tween_callback(func(): %FeedbackLabel.visible = false)

func check_turning_point(progress: float):
	var turning_threshold = 0.80
	var perfect_zone = 0.95
	
	if current_path_index > 0 and progress < 0.1:
		return
	
	if progress >= turning_threshold and not is_turning_point and not turn_processed:
		is_turning_point = true
		
		if reaction_timer:
			reaction_timer.wait_time = reaction_window
			reaction_timer.start()
		
		if progress <= perfect_zone - 0.05:
			show_feedback("Готуйся...", Color(1, 0.7, 0))
		else:
			show_feedback("Тисни зараз!", Color(0, 1, 0))
	elif progress >= perfect_zone - 0.05 and is_turning_point and not turn_processed:
		show_feedback("Тисни зараз!", Color(0, 1, 0))
	
	elif progress > perfect_zone + 0.05 and is_turning_point and not turn_processed:
		show_feedback("Швидше!", Color(1, 0, 0))

func end_game(success: bool, score: int = 0):
	game_timer.stop()
	reaction_timer.stop()
	
	if arrow_tween != null and arrow_tween.is_valid():
		arrow_tween.kill()
	
	if has_node("%CuttingSound") and %CuttingSound and %CuttingSound.playing:
		%CuttingSound.stop()
	
	var final_score = 0
	var expected_turns = cutting_path.size() - 2
	
	if skill_level == SKILL_LEVEL.MASTER:
		final_score = score if score > 0 else 100
	else:
		final_score = score if score > 0 else current_score
		
		if missed_turns > expected_turns / 2:
			final_score = max(30, final_score - 20)
			show_feedback("Пропущено багато поворотів!", Color(1, 0, 0))
			await get_tree().create_timer(1.5).timeout
		elif current_hits == 0:
			final_score = 30
			show_feedback("Ви не зробили жодного повороту!", Color(1, 0, 0))
			await get_tree().create_timer(1.5).timeout
	
	var quality = "звичайний"
	if final_score > 90:
		quality = "відмінний"
	elif final_score > 75:
		quality = "хороший"
	elif final_score > 50:
		quality = "задовільний"
	else:
		quality = "низький"
	
	show_feedback("Результат: %d/100 (%s)" % [final_score, quality], Color(0, 0.8, 1))
	
	current_state = GAME_STATE.COMPLETE
	
	# Збільшено час показу результату з 2.0 до 3.5 секунд
	await get_tree().create_timer(3.5).timeout
	
	mini_game_completed.emit(success, final_score)
	queue_free()

func move_arrow_along_segment():
	if current_path_index >= cutting_path.size() - 1:
		end_game(true)
		return
	
	if arrow_tween != null and arrow_tween.is_valid():
		arrow_tween.kill()
	
	var start_point = cutting_path[current_path_index]
	var end_point = cutting_path[current_path_index + 1]
	
	var segment_length = start_point.distance_to(end_point)
	var move_time = segment_length / arrow_speed
	
	if not processed_segments.has(current_path_index):
		processed_segments.append(current_path_index)
	
	if has_node("%CuttingLines/ContourLine"):
		%CuttingLines/ContourLine.visible = true
	
	var direction_vector = end_point - start_point
	if direction_arrow:
		direction_arrow.rotation = direction_vector.angle()
		direction_arrow.visible = true
	
	is_turning_point = false
	turn_processed = false
	
	arrow_tween = create_tween()
	arrow_tween.set_trans(Tween.TRANS_LINEAR)
	
	arrow_tween.tween_method(func(progress):
		current_segment_progress = progress
		
		current_position = start_point.lerp(end_point, progress)
		
		if direction_arrow:
			update_arrow_position(current_position)
		
		check_turning_point(progress)
	, 0.0, 1.0, move_time)
	
	arrow_tween.tween_callback(func():
		current_path_index += 1
		current_segment_progress = 0.0
	
		if reaction_timer.is_stopped() == false:
			reaction_timer.stop()
		
		if is_turning_point and not turn_processed:
			_on_reaction_timer_timeout()
	
		is_turning_point = false
		turn_processed = false
	
		if current_path_index >= cutting_path.size() - 1:
			end_game(true)
			return
	
		calculate_next_direction()
		move_arrow_along_segment()
	)

func play_cutting_sound():
	if has_node("%CuttingSound") and current_state == GAME_STATE.CUTTING:
		if %CuttingSound and not %CuttingSound.playing:
			%CuttingSound.play()
			
	if has_node("%CuttingSound") and %CuttingSound and %CuttingSound.playing:
		var volume_mod = randf_range(-2.0, 0.0)
		var pitch_mod = randf_range(0.95, 1.05)
		
		%CuttingSound.volume_db = -10.0 + volume_mod
		%CuttingSound.pitch_scale = pitch_mod
		
func flash_screen_feedback(correct: bool):
	var flash = ColorRect.new()
	flash.color = Color(0, 1, 0, 0.3) if correct else Color(1, 0, 0, 0.3)
	flash.size = Vector2(380, 300)
	flash.position = Vector2.ZERO
	%WorkpieceRect.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func _input(event):
	if not visible or current_state == GAME_STATE.COMPLETE:
		return
	
	if current_state == GAME_STATE.IDLE:
		for direction in DIRECTION_BUTTONS.values():
			if event.is_action_pressed(direction):
				start_cutting()
				break
	elif current_state == GAME_STATE.CUTTING:
		if is_turning_point:
			var pressed_correct = false
			var pressed_wrong = false
			
			if event.is_action_pressed(DIRECTION_BUTTONS[next_direction]):
				pressed_correct = true
			elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or \
				 event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				pressed_wrong = true
			
			if pressed_correct or pressed_wrong:
				handle_turn(pressed_correct)
	
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func _on_reaction_timer_timeout():
	if not is_turning_point or turn_processed:
		return
	
	is_turning_point = false
	turn_processed = true
	missed_turns += 1
	
	if not processed_segments.has(current_path_index):
		processed_segments.append(current_path_index)
	
	var penalty = 5
	current_score = max(0, current_score - penalty)
	
	show_feedback("Поворот пропущено!", Color(1, 0, 0))

func _on_game_timer_timeout():
	match current_state:
		GAME_STATE.IDLE:
			pass
		
		GAME_STATE.CUTTING:
			if has_node("%ProgressBar"):
				var total_segments = cutting_path.size() - 1
				var completed_segments = current_path_index
				var current_progress = (completed_segments + current_segment_progress) / total_segments * 100
				%ProgressBar.value = current_progress

func _on_input_type_changed(_device_type):
	calculate_next_direction()
