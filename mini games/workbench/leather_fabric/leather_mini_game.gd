# leather_mini_game.gd
extends MiniGame
class_name LeatherMiniGame

# Рівні майстерності
enum SKILL_LEVEL { APPRENTICE = 0, JOURNEYMAN = 1, BLACKSMITH = 2, MASTER = 3 }

# Типи виробів
enum ITEM_TYPE { SHEATH = 0, BELT = 1, ARMOR_PIECE = 2 }

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
@export var item_type: int = ITEM_TYPE.SHEATH
@export var arrow_speed_factor: float = 1.0  # Базова швидкість руху стрілки

# Параметри, що залежать від рівня майстерності
var reaction_window: float     # Час на реакцію в секундах
var perfect_timing_window: float  # Час ідеального натискання
var arrow_speed: float         # Швидкість руху стрілки

# Змінні для відстеження прогресу
var current_state: int = GAME_STATE.IDLE
var current_score: int = 100  # Починаємо з максимальної оцінки, віднімаємо за помилки
var current_path_index: int = 0  # Індекс поточного сегмента шляху
var current_segment_progress: float = 0.0  # Прогрес по поточному сегменту (0.0-1.0)
var next_direction: String = "right"  # Напрямок наступного повороту
var is_turning_point: bool = false  # Чи знаходимося в зоні повороту
var current_hits: int = 0  # Лічильник успішних поворотів
var processed_segments: Array = []  # Масив для відстеження оброблених сегментів

# Візуальні елементи
var cutting_path: Array = []  # Масив точок для ліній різання
var current_position: Vector2 = Vector2.ZERO  # Поточна позиція стрілки
var direction_arrow: Polygon2D  # Вузол стрілки напрямку
var cut_line: Line2D  # Лінія для відображення вже вирізаної частини
var next_button_texture: TextureRect  # Вузол текстури для підказки наступної кнопки

# Таймери і твіни
var game_timer: Timer
var reaction_timer: Timer  # Таймер для відстеження часу реакції
var arrow_tween: Tween = null  # Tween для анімації руху стрілки

func _ready():
	# Налаштовуємо параметри залежно від рівня майстерності
	match skill_level:
		SKILL_LEVEL.APPRENTICE:
			reaction_window = 1.5     # Збільшено час реакції з 0.8 до 1.5
			perfect_timing_window = 0.5  # Збільшено вікно ідеального натискання з 0.3 до 0.5
			arrow_speed = 40.0  # Зменшено швидкість з 60 до 40 для більш комфортної гри
		SKILL_LEVEL.JOURNEYMAN:
			reaction_window = 1.2     # Збільшено з 0.6 до 1.2
			perfect_timing_window = 0.4  # Збільшено з 0.2 до 0.4
			arrow_speed = 50.0        # Зменшено з 80.0 до 50.0
		SKILL_LEVEL.BLACKSMITH:
			reaction_window = 1.0     # Збільшено з 0.5 до 1.0
			perfect_timing_window = 0.3  # Збільшено з 0.15 до 0.3
			arrow_speed = 60.0        # Зменшено з 100.0 до 60.0
		SKILL_LEVEL.MASTER:
			# Для майстра - автоматичне виконання
			reaction_window = 1.0
			perfect_timing_window = 1.0
			arrow_speed = 150.0
	
	# Налаштовуємо параметри залежно від типу виробу
	# Всі типи виробів тепер матимуть менше поворотів для уникнення зайвих штрафів
	match item_type:
		ITEM_TYPE.SHEATH:
			# Шаблон для піхов з меншою кількістю поворотів
			generate_cutting_path(8)  # 8 точок замість 10
		ITEM_TYPE.BELT:
			# Середній виріб з меншою кількістю поворотів
			generate_cutting_path(7)  # 7 точок замість 10
		ITEM_TYPE.ARMOR_PIECE:
			# Складний виріб з меншою кількістю поворотів
			generate_cutting_path(8)  # 8 точок замість 12
			
	# Створюємо і налаштовуємо таймери
	game_timer = Timer.new()
	game_timer.one_shot = false
	game_timer.wait_time = 0.05  # Оновлюємо стан кожні 0.05 секунди
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
	
	# Отримуємо розміри ігрового поля (заготовки)
	var workpiece_width = 380  # Збільшено розмір
	var workpiece_height = 300  # Збільшено розмір
	var margin = 50  # Збільшений відступ від країв для кращої видимості
	
	# Обчислюємо центр
	var center_x = workpiece_width / 2
	var center_y = workpiece_height / 2
	
	# Визначаємо радіус для генерації точок
	var radius_x = (workpiece_width / 2) - margin
	var radius_y = (workpiece_height / 2) - margin
	
	# ВИПРАВЛЕНО: Зменшена кількість точок для уникнення надмірних штрафів
	# за велику кількість поворотів
	match item_type:
		ITEM_TYPE.SHEATH:
			# Для піхов генеруємо спрощений контур із зигзагами (8 точок, 7 поворотів)
			var points = []
			
			# Починаємо з верхнього лівого кута
			points.append(Vector2(center_x - radius_x, center_y - radius_y))
			
			# Верхня сторона
			points.append(Vector2(center_x, center_y - radius_y))
			points.append(Vector2(center_x + radius_x, center_y - radius_y))
			
			# Права сторона
			points.append(Vector2(center_x + radius_x, center_y))
			points.append(Vector2(center_x + radius_x, center_y + radius_y))
			
			# Нижня сторона
			points.append(Vector2(center_x, center_y + radius_y))
			points.append(Vector2(center_x - radius_x, center_y + radius_y))
			
			# Ліва сторона
			points.append(Vector2(center_x - radius_x, center_y))
			
			# Закриваємо контур
			points.append(Vector2(center_x - radius_x, center_y - radius_y))
			
			cutting_path = points
		
		ITEM_TYPE.BELT:
			# Для пояса генеруємо подовжений контур (8 точок)
			var points = []
			
			# Початкова точка (верхній лівий кут)
			points.append(Vector2(center_x - radius_x, center_y - radius_y/3))
			
			# Верхня частина
			points.append(Vector2(center_x, center_y - radius_y/2))
			points.append(Vector2(center_x + radius_x, center_y - radius_y/3))
			
			# Права сторона
			points.append(Vector2(center_x + radius_x, center_y + radius_y/3))
			
			# Нижня частина
			points.append(Vector2(center_x, center_y + radius_y/2))
			points.append(Vector2(center_x - radius_x, center_y + radius_y/3))
			
			# Закриваємо контур
			points.append(Vector2(center_x - radius_x, center_y - radius_y/3))
			
			cutting_path = points
		
		ITEM_TYPE.ARMOR_PIECE:
			# Для частини обладунку генеруємо спрощений контур (8 точок)
			var points = []
			
			# Генеруємо 8 точок рівномірно розподілених по колу
			for i in range(8):
				var angle = 2 * PI * i / 8
				
				var r = radius_x if i % 2 == 0 else radius_x * 0.8
				
				var x = center_x + cos(angle) * r
				var y = center_y + sin(angle) * r
				
				points.append(Vector2(x, y))
			
			# Закриваємо контур
			points.append(points[0])
			
			cutting_path = points
	
	# Встановлюємо початкову позицію
	current_position = cutting_path[0]
	
	# Обчислюємо перший напрямок
	calculate_next_direction()

func calculate_next_direction():
	# Визначаємо напрямок для наступного повороту
	# Спрощуємо цю логіку, щоб було менше помилок
	
	# Вибираємо напрямок випадково з базових напрямків - простіше і зрозуміліше
	var directions = ["up", "down", "left", "right"]
	next_direction = directions[randi() % directions.size()]
	
	# Більш помітна анімація кнопки напрямку
	if has_node("%NextDirectionButton"):
		var button = %NextDirectionButton
		button.texture = InputManager.get_button_texture(DIRECTION_BUTTONS[next_direction])
		button.modulate = Color(1, 1, 1, 1) # Без прозорості
		button.scale = Vector2(1.2, 1.2)    # Збільшений розмір
		
		# Додаємо анімацію пульсації для привернення уваги
		var tween = create_tween().set_loops(2)
		tween.tween_property(button, "scale", Vector2(1.4, 1.4), 0.3)
		tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.3)
		
		# Показуємо текст підказки
		var button_name = InputManager.get_button_display_name(DIRECTION_BUTTONS[next_direction])
		%InstructionsLabel.text = "Натисніть %s на повороті" % button_name

func create_dotted_line_texture() -> Texture2D:
	# Створюємо текстуру для більш помітної пунктирної лінії
	var img = Image.create(8, 1, false, Image.FORMAT_RGBA8)
	
	# Заповнюємо пікселі з чіткішим пунктиром (5 пікселів видимі, 3 невидимих)
	for i in range(5):
		img.set_pixel(i, 0, Color(1, 1, 1, 1))
	
	for i in range(5, 8):
		img.set_pixel(i, 0, Color(1, 1, 1, 0))
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_cutting_lines():
	# Очищаємо попередні лінії
	var existing_lines = get_node_or_null("%CuttingLines")
	if existing_lines:
		existing_lines.queue_free()
	
	# Створюємо новий вузол для ліній
	var lines_node = Node2D.new()
	lines_node.name = "CuttingLines"
	lines_node.unique_name_in_owner = true
	%WorkpieceRect.add_child(lines_node)
	
	# Створюємо єдину Line2D для всього контуру
	var contour_line = Line2D.new()
	contour_line.name = "ContourLine"
	contour_line.default_color = Color(0.05, 0.05, 0.05, 0.9)  # Дуже темний колір для кращої видимості
	contour_line.width = 4.0  # Значно товстіша лінія для кращої видимості
	contour_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	contour_line.texture = create_dotted_line_texture()
	
	# Додаємо всі точки до лінії
	for point in cutting_path:
		contour_line.add_point(point)
	
	lines_node.add_child(contour_line)
	
	# Додаємо більші маркери у точках поворотів для кращої видимості
	for i in range(cutting_path.size()):
		var turn_marker = ColorRect.new()
		turn_marker.size = Vector2(8, 8)  # Більший квадрат
		turn_marker.color = Color(0.9, 0.1, 0.1, 0.9)  # Яскраво-червоний колір
		turn_marker.position = cutting_path[i] - Vector2(4, 4)  # Центруємо відносно точки
		lines_node.add_child(turn_marker)

func create_direction_arrow():
	# Створюємо стрілку напрямку - використовуємо значно більшу і помітнішу стрілку
	direction_arrow = Polygon2D.new()
	direction_arrow.name = "DirectionArrow"
	direction_arrow.unique_name_in_owner = true
	
	# Форма стрілки - значно більший розмір
	var arrow_points = [
		Vector2(0, -25),    # вершина (збільшена)
		Vector2(-18, 10),   # нижній лівий кут
		Vector2(0, 0),      # центральний нижній кут
		Vector2(18, 10)     # нижній правий кут
	]
	direction_arrow.polygon = arrow_points
	direction_arrow.color = Color(1, 0, 0, 1.0)  # Яскраво-червоний колір
	
	# Додаємо до сцени
	%WorkpieceRect.add_child(direction_arrow)
	
	# Додаємо більше світіння для значно кращої помітності
	var glow = ColorRect.new()
	glow.name = "Glow"
	glow.size = Vector2(14, 14)
	glow.color = Color(1, 0.5, 0, 0.7)  # Яскраве оранжеве світіння
	glow.position = Vector2(-7, -7)  # Центруємо
	direction_arrow.add_child(glow)
	
	# Додатковий помітний центр
	var center = ColorRect.new()
	center.name = "Center"
	center.size = Vector2(6, 6)
	center.color = Color(1, 1, 0, 1.0)  # Яскраво-жовтий центр
	center.position = Vector2(-3, -3)  # Центруємо
	direction_arrow.add_child(center)
	
	# Створюємо лінію вирізання (слід від стрілки)
	cut_line = Line2D.new()
	cut_line.name = "CutLine"
	cut_line.unique_name_in_owner = true
	cut_line.default_color = Color(0.05, 0.05, 0.05, 1.0)  # Темніший колір для кращого контрасту
	cut_line.width = 6.0  # Значно товстіша
	%WorkpieceRect.add_child(cut_line)
	
	# Додаємо початкову точку
	cut_line.add_point(cutting_path[0])
	
	# Розміщуємо в початковій позиції
	update_arrow_position(cutting_path[0])
	
	# Орієнтуємо в напрямку руху
	update_arrow_orientation()

func setup_ui():
	# Налаштовуємо UI елементи
	if has_node("%WorkpieceRect"):
		# Це ColorRect, який представляє шматок шкіри або тканини
		%WorkpieceRect.color = Color(0.6, 0.4, 0.2, 1.0)  # Коричневий колір для шкіри
		
		# Створюємо лінії різання
		draw_cutting_lines()
		
		# Створюємо стрілку напрямку, якщо її ще немає
		if not has_node("%DirectionArrow"):
			create_direction_arrow()
	
	# Оновлюємо текстуру кнопки напрямку
	calculate_next_direction()

func update_arrow_position(position: Vector2):
	if direction_arrow:
		direction_arrow.position = position
		
		# Додаємо точку до лінії вирізання
		if cut_line and cut_line.get_point_count() > 0:
			var last_point = cut_line.get_point_position(cut_line.get_point_count() - 1)
			
			# Додаємо нову точку тільки якщо вона не збігається з останньою
			if position.distance_to(last_point) > 5.0:
				cut_line.add_point(position)
		
		# Оновлюємо звуковий ефект вирізання
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
	
	# Додаємо затримку перед початком руху для підготовки
	show_feedback("Підготуйтесь...", Color(1, 1, 1))
	
	# Більша затримка в 1 секунду перед початком руху
	await get_tree().create_timer(1.0).timeout
	
	# Починаємо рух стрілки по першому сегменту
	move_arrow_along_segment()
	
	# Оновлюємо підказку
	var button_name = InputManager.get_button_display_name(DIRECTION_BUTTONS[next_direction])
	%InstructionsLabel.text = "Натисніть %s на повороті" % button_name
	
	show_feedback("Ріжемо...", Color(0, 0.7, 1))
	
	
func handle_turn(correct_button: bool):
	# Зупиняємо таймер реакції
	reaction_timer.stop()
	
	# Збільшуємо лічильник успішних поворотів
	current_hits += 1
	
	# Додаємо поточний сегмент до масиву оброблених
	if not processed_segments.has(current_path_index):
		processed_segments.append(current_path_index)
	
	# Додаємо відчутний візуальний та звуковий відгук при повороті
	flash_screen_feedback(correct_button)
	
	if correct_button:
		# Правильна кнопка натиснута
		
		# Визначаємо якість натискання на основі прогресу
		var quality = 0
		var turn_threshold = 0.95  # Ідеальний момент повороту
		var diff = abs(current_segment_progress - turn_threshold)
		
		# Сильно спрощена логіка - майже будь-яке натискання в зоні повороту вважається хорошим
		if diff <= 0.2:  # Дуже широка зона "ідеального" натискання 
			quality = 3
			show_feedback("Ідеально!", Color(0, 1, 0))
		else:
			quality = 2
			show_feedback("Добре", Color(0.5, 1, 0))
			# Мінімальний штраф
			current_score = max(0, current_score - 1)
		
		print("ПОВОРОТ: якість = %d" % quality)
	else:
		# Неправильна кнопка натиснута - помірний штраф
		var penalty = 5  # Зменшений штраф для кращого ігрового досвіду
		current_score = max(0, current_score - penalty)
		
		show_feedback("Неправильний напрямок!", Color(1, 0, 0))
		
		print("ПОВОРОТ: неправильна кнопка, штраф = %d" % penalty)
	
	# Виходимо із зони повороту
	is_turning_point = false
	
func show_feedback(text: String, color: Color = Color(1, 1, 1)):
	if has_node("%FeedbackLabel"):
		%FeedbackLabel.text = text
		%FeedbackLabel.add_theme_color_override("font_color", color)
		%FeedbackLabel.visible = true
		
		# Створюємо анімацію згасання
		var tween = create_tween()
		tween.tween_property(%FeedbackLabel, "modulate", Color(1, 1, 1, 0), 0.7).from(Color(1, 1, 1, 1))
		tween.tween_callback(func(): %FeedbackLabel.visible = false)
		

func check_turning_point(progress: float):
	# ВИПРАВЛЕНО: Тепер зона повороту починається пізніше в сегменті,
	# щоб не створювати штучні повороти на початку кожного сегмента
	var turning_threshold = 0.80  # Починається в останній п'ятій частині сегмента
	var perfect_zone = 0.95       # Ідеальна зона для натискання
	
	# Якщо ми не на першому сегменті і прогрес менше 10%, перевіряємо логіку повороту
	# (це запобігає помилковим поворотам на початку нових сегментів)
	if current_path_index > 0 and progress < 0.1:
		return
	
	# ВИПРАВЛЕНО: Перевіряємо, чи ми вже були в зоні повороту на цьому сегменті
	# Якщо так, не активуємо її знову
	if progress >= turning_threshold and not is_turning_point:
		# Вхід в зону повороту
		is_turning_point = true
		
		# Запускаємо таймер для відліку часу реакції тільки один раз на сегмент
		if reaction_timer:
			reaction_timer.wait_time = reaction_window
			reaction_timer.start()
		
		# Показуємо підказку
		if progress <= perfect_zone - 0.05:
			# Ще рано для натискання
			show_feedback("Готуйся...", Color(1, 0.7, 0))
		else:
			# Саме час натискати
			show_feedback("Тисни зараз!", Color(0, 1, 0))
	elif progress >= perfect_zone - 0.05 and is_turning_point:
		# Вже наближаємося до ідеальної зони
		show_feedback("Тисни зараз!", Color(0, 1, 0))
	
	elif progress > perfect_zone + 0.05 and is_turning_point:
		# Пізня зона - скоро час реакції скінчиться
		show_feedback("Швидше!", Color(1, 0, 0))

func move_arrow_along_segment():
	if current_path_index >= cutting_path.size() - 1:
		# Дійшли до кінця шляху
		end_game(true)
		return
	
	# Зупиняємо попередній tween, якщо він існує
	if arrow_tween != null and arrow_tween.is_valid():
		arrow_tween.kill()
	
	# Визначаємо початкову і кінцеву точки сегмента
	var start_point = cutting_path[current_path_index]
	var end_point = cutting_path[current_path_index + 1]
	
	# Обчислюємо довжину сегмента для визначення часу руху
	var segment_length = start_point.distance_to(end_point)
	var move_time = segment_length / arrow_speed
	
	# Додаємо поточний сегмент до масиву оброблених, щоб уникнути повторного штрафу
	if not processed_segments.has(current_path_index):
		processed_segments.append(current_path_index)
	
	# Показуємо контур для хорошої видимості напрямку руху
	if has_node("%CuttingLines/ContourLine"):
		%CuttingLines/ContourLine.visible = true
	
	# Оновлюємо орієнтацію стрілки перед початком руху
	var direction_vector = end_point - start_point
	if direction_arrow:
		direction_arrow.rotation = direction_vector.angle()
		direction_arrow.visible = true
	
	# Скидаємо стан повороту на початку кожного сегмента
	is_turning_point = false
	
	# Створюємо новий tween для анімації руху стрілки
	arrow_tween = create_tween()
	arrow_tween.set_trans(Tween.TRANS_LINEAR)
	
	# Налаштовуємо callback для відстеження прогресу
	arrow_tween.tween_method(func(progress):
		current_segment_progress = progress
		
		# Обчислюємо поточну позицію стрілки
		current_position = start_point.lerp(end_point, progress)
		
		# Оновлюємо позицію стрілки
		if direction_arrow:
			update_arrow_position(current_position)
		
		# Визначаємо, чи ми в зоні повороту
		check_turning_point(progress)
	, 0.0, 1.0, move_time)
	
	# Налаштовуємо дію після завершення tween
	arrow_tween.tween_callback(func():
		# Якщо був пропущений поворот, нараховуємо штраф, але тільки якщо цей сегмент ще не був оброблений
		if is_turning_point and not processed_segments.has(current_path_index + 1):
			_on_reaction_timer_timeout()
			is_turning_point = false
			processed_segments.append(current_path_index + 1)
		
		# Переходимо до наступного сегмента
		current_path_index += 1
		current_segment_progress = 0.0
		
		# Якщо це останній сегмент, завершуємо гру
		if current_path_index >= cutting_path.size() - 1:
			end_game(true)
			return
		
		# Рухаємося далі по наступному сегменту
		calculate_next_direction()
		move_arrow_along_segment()
	)

func play_cutting_sound():
	# Відтворюємо звук різання, якщо він доступний
	if has_node("%CuttingSound") and current_state == GAME_STATE.CUTTING:
		if %CuttingSound and not %CuttingSound.playing:
			%CuttingSound.play()
			
	# Варіюємо звук інтенсивності відповідно до швидкості руху
	if has_node("%CuttingSound") and %CuttingSound and %CuttingSound.playing:
		var volume_mod = randf_range(-2.0, 0.0)
		var pitch_mod = randf_range(0.95, 1.05)
		
		%CuttingSound.volume_db = -10.0 + volume_mod
		%CuttingSound.pitch_scale = pitch_mod
		
func flash_screen_feedback(correct: bool):
	# Створюємо тимчасовий ColorRect для ефекту спалаху
	var flash = ColorRect.new()
	flash.color = Color(0, 1, 0, 0.3) if correct else Color(1, 0, 0, 0.3)
	flash.size = Vector2(380, 300)  # Розмір заготовки
	flash.position = Vector2.ZERO
	%WorkpieceRect.add_child(flash)
	
	# Анімація зникнення
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func _input(event):
	if not visible or current_state == GAME_STATE.COMPLETE:
		return
	
	# Обробка кнопок напрямку
	if current_state == GAME_STATE.IDLE:
		# В режимі очікування будь-яка кнопка напрямку почне гру
		for direction in DIRECTION_BUTTONS.values():
			if event.is_action_pressed(direction):
				start_cutting()
				break
	elif current_state == GAME_STATE.CUTTING:
		# В режимі вирізання перевіряємо натискання будь-якої кнопки напрямку
		# Спрощена логіка - тепер можна нажимати будь-яку кнопку напрямку, коли стрілка досягла повороту
		if is_turning_point:
			var pressed_correct = false
			var pressed_wrong = false
			
			# Перевіряємо, чи натиснута правильна кнопка
			if event.is_action_pressed(DIRECTION_BUTTONS[next_direction]):
				pressed_correct = true
			# Перевіряємо, чи натиснута будь-яка інша кнопка напрямку
			elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or \
				 event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				pressed_wrong = true
			
			# Обробляємо натискання кнопки
			if pressed_correct or pressed_wrong:
				handle_turn(pressed_correct)
	
	# Скасування гри за допомогою Escape
	if event.is_action_pressed("ui_cancel"):
		cancel_game()

func _on_reaction_timer_timeout():
	# Час на реакцію вичерпано - гравець пропустив поворот
	is_turning_point = false
	
	# Менший штраф за пропуск
	var penalty = 5  # Зменшено з 15 до 5
	current_score = max(0, current_score - penalty)
	
	show_feedback("Поворот пропущено!", Color(1, 0, 0))
	
	print("ПОВОРОТ: пропущено, штраф = %d" % penalty)

func _on_game_timer_timeout():
	# Оновлюємо стан гри
	match current_state:
		GAME_STATE.IDLE:
			# В режимі очікування нічого не робимо
			pass
		
		GAME_STATE.CUTTING:
			# В режимі вирізання стрілка рухається автоматично через tween
			
			# Оновлюємо прогрес-бар
			if has_node("%ProgressBar"):
				var total_segments = cutting_path.size() - 1
				var completed_segments = current_path_index
				var current_progress = (completed_segments + current_segment_progress) / total_segments * 100
				%ProgressBar.value = current_progress
			
			# Оновлюємо лічильник рахунку
			if has_node("%ScoreLabel"):
				%ScoreLabel.text = "Рахунок: " + str(current_score)

func _on_input_type_changed(_device_type):
	# Оновлюємо відображення кнопок при зміні типу вводу
	calculate_next_direction()
	# Визначаємо початкову і кінцеву точки сегмента
	var start_point = cutting_path[current_path_index]
	var end_point = cutting_path[current_path_index + 1]
	
	# Обчислюємо довжину сегмента для визначення часу руху
	var segment_length = start_point.distance_to(end_point)
	var move_time = segment_length / arrow_speed
	
	# Додаємо поточний сегмент до масиву оброблених, щоб уникнути повторного штрафу
	if not processed_segments.has(current_path_index):
		processed_segments.append(current_path_index)
	
	# Показуємо контур для хорошої видимості напрямку руху
	if has_node("%CuttingLines/ContourLine"):
		%CuttingLines/ContourLine.visible = true
	
	# Оновлюємо орієнтацію стрілки перед початком руху
	var direction_vector = end_point - start_point
	if direction_arrow:
		direction_arrow.rotation = direction_vector.angle()
		direction_arrow.visible = true
	
	# Скидаємо стан повороту на початку кожного сегмента
	is_turning_point = false
	
	# Створюємо новий tween для анімації руху стрілки
	arrow_tween = create_tween()
	arrow_tween.set_trans(Tween.TRANS_LINEAR)
	
	# Налаштовуємо callback для відстеження прогресу
	arrow_tween.tween_method(func(progress):
		current_segment_progress = progress
		
		# Обчислюємо поточну позицію стрілки
		current_position = start_point.lerp(end_point, progress)
		
		# Оновлюємо позицію стрілки
		if direction_arrow:
			update_arrow_position(current_position)
		
		# Визначаємо, чи ми в зоні повороту
		check_turning_point(progress)
	, 0.0, 1.0, move_time)
	
	# Налаштовуємо дію після завершення tween
	arrow_tween.tween_callback(func():
		# Якщо був пропущений поворот, нараховуємо штраф, але тільки якщо цей сегмент ще не був оброблений
		if is_turning_point and not processed_segments.has(current_path_index + 1):
			_on_reaction_timer_timeout()
			is_turning_point = false
			processed_segments.append(current_path_index + 1)
		
		# Переходимо до наступного сегмента
		current_path_index += 1
		current_segment_progress = 0.0
		
		# Якщо це останній сегмент, завершуємо гру
		if current_path_index >= cutting_path.size() - 1:
			end_game(true)
			return
		
		# Рухаємося далі по наступному сегменту
		calculate_next_direction()
		move_arrow_along_segment()
	)
	
