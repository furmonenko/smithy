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

# Поточний етап кування для шейдера
var current_forge_stage: int = 0

# Таймери
var ring_timer: Timer
var direction_timer: Timer
var flip_timer: Timer

# Нові змінні для імпактів
var impact_tween: Tween = null
var hit_positions = []  # Масив позицій ударів

# Налаштування кування меча для шейдера
var forging_stages = [
	{
		"name": "Початкова заготовка",
		"forge_progress": 0.0,
		"initial_deform": Vector2(0.6, 0.6), # більше стискання для явної деформації
		"impact_radius": 0.5,
		"bulge_strength": 0.35, # збільшена сила випучування
		"noise_influence": 0.4, # збільшена нерівність поверхні
		"description": "Холодна заготовка металу"
	},
	{
		"name": "Початок розковування",
		"forge_progress": 0.2,
		"initial_deform": Vector2(0.6, 0.6),
		"impact_radius": 0.45,
		"bulge_strength": 0.3,
		"noise_influence": 0.35,
		"description": "Початкове формування заготовки"
	},
	{
		"name": "Формування стержня",
		"forge_progress": 0.4,
		"initial_deform": Vector2(0.6, 0.6),
		"impact_radius": 0.4,
		"bulge_strength": 0.25,
		"noise_influence": 0.3,
		"description": "Подовження центральної частини"
	},
	{
		"name": "Початок формування леза",
		"forge_progress": 0.6,
		"initial_deform": Vector2(0.6, 0.6),
		"impact_radius": 0.35,
		"bulge_strength": 0.2,
		"noise_influence": 0.2,
		"description": "Загальна форма клинка стає видимою"
	},
	{
		"name": "Формування кромки",
		"forge_progress": 0.8,
		"initial_deform": Vector2(0.6, 0.6),
		"impact_radius": 0.3,
		"bulge_strength": 0.15,
		"noise_influence": 0.1,
		"description": "Клинок набуває чіткої форми, кромка вирівнюється"
	},
	{
		"name": "Фінальна обробка",
		"forge_progress": 1.0,
		"initial_deform": Vector2(0.6, 0.6),
		"impact_radius": 0.2,
		"bulge_strength": 0.0,
		"noise_influence": 0.0,
		"description": "Готовий клинок, всі деформації усунуті"
	}
]

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
	
	# Ініціалізуємо масив позицій ударів
	generate_hit_positions()
	
	# Приховуємо на початку
	visible = false
	setup_shader_for_workpiece()
	start_game()

# Функція для генерації позицій ударів
func generate_hit_positions():
	hit_positions.clear()
	
	# Розраховуємо позиції для обох фаз (до і після перевертання)
	var half_hits = total_hits_required / 2
	
	# Перша половина - зверху донизу (від 0.1 до 0.9, щоб не бити по самому краю)
	for i in range(half_hits):
		var pos = 0.1 + (0.8 * float(i) / float(half_hits - 1))
		hit_positions.append(pos)
	
	# Друга половина - знизу догори
	for i in range(half_hits):
		var pos = 0.9 - (0.8 * float(i) / float(half_hits - 1))
		hit_positions.append(pos)

func hammer_strike():
	var random_pitch: float = randf_range(0.95, 1.05)
	%AnvilHit.pitch_scale = random_pitch
	%AnvilHit.play()
	
	# Показуємо імпакт в конкретній позиції
	show_impact_at_current_position()
	
	# Оновлюємо етап кування і деформацію ПІСЛЯ кожного удару
	update_forge_progression()
	
	# Додаємо ефект тимчасового збільшення нагріву в місці удару
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		var current_heat = 0.0
		
		match current_temperature:
			TEMPERATURE_STATE.PERFECT:
				current_heat = 0.9
			TEMPERATURE_STATE.GOOD:
				current_heat = 0.8
			TEMPERATURE_STATE.SATISFACTORY:
				current_heat = 0.6
			TEMPERATURE_STATE.COLD:
				current_heat = 0.2
		
		shader_material.set_shader_parameter("heat_amount", current_heat)
		
		# Додаємо ефект тимчасового збільшення нагріву в місці удару
		if current_heat > 0.0:
			var tween = create_tween()
			tween.tween_method(Callable(self, "_update_heat_amount"), current_heat, current_heat + 0.1, 0.1)
			tween.tween_method(Callable(self, "_update_heat_amount"), current_heat + 0.1, current_heat, 0.5)

func update_forge_progression():
	# Обчислюємо прогрес на основі кількості виконаних ударів і загальної кількості
	var progress_percentage = float(current_hits) / float(total_hits_required)
	
	# Знаходимо відповідний етап кування
	var target_stage_index = int(progress_percentage * (forging_stages.size() - 1))
	
	# Переходимо на новий етап тільки якщо він більший за поточний
	if target_stage_index > current_forge_stage:
		# Запам'ятовуємо попередній етап для налагодження
		var previous_stage = current_forge_stage
		
		# Оновлюємо етап
		current_forge_stage = target_stage_index
		
		# Застосовуємо нові параметри деформації
		apply_forge_stage(current_forge_stage)
		
		print("Оновлення деформації: з етапу %d (%s) до етапу %d (%s)" % [
			previous_stage, 
			forging_stages[previous_stage].name,
			current_forge_stage,
			forging_stages[current_forge_stage].name
		])

func apply_forge_stage(stage_index):
	if stage_index < 0 or stage_index >= forging_stages.size():
		return
	
	var stage = forging_stages[stage_index]
	
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		
		# Оновлюємо параметри шейдера для поточного етапу
		shader_material.set_shader_parameter("forge_progress", stage.forge_progress)
		shader_material.set_shader_parameter("initial_deform", stage.initial_deform)
		shader_material.set_shader_parameter("impact_radius", stage.impact_radius)
		shader_material.set_shader_parameter("bulge_strength", stage.bulge_strength)
		shader_material.set_shader_parameter("noise_influence", stage.noise_influence)
		
		print("Застосовано етап кування: %s (forge_progress = %.2f)" % [stage.name, stage.forge_progress])

func start_game():
	visible = true
	current_temperature = TEMPERATURE_STATE.PERFECT
	current_hits = 0
	current_phase = GAME_PHASE.HIT
	current_score = 0
	perfect_hits_streak = 0
	flip_half_done = false
	current_direction = "up"
	current_forge_stage = 0  # Починаємо з першого етапу
	
	# Скидаємо і оновлюємо UI
	update_hit_counter()
	update_temperature_indicator()
	
	# Скидаємо параметри шейдера
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		shader_material.set_shader_parameter("flip_done", false)
		
		# Застосовуємо початковий етап деформації
		apply_forge_stage(0)
		
		# Встановлюємо початковий рівень нагріву
		shader_material.set_shader_parameter("heat_amount", 0.9)
	
	# Починаємо з фази удару
	start_hit_phase()

func update_forge_stage(stage_index):
	if stage_index < 0 or stage_index >= forging_stages.size():
		return
		
	current_forge_stage = stage_index
	var stage = forging_stages[stage_index]
	
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		
		# Оновлюємо тільки поточну позицію центру кування
		update_forge_position(0.5)
	
	print("Етап кування: ", stage.name)
	print(stage.description)

func start_hit_phase():
	current_phase = GAME_PHASE.HIT
	
	# Визначаємо позицію наступного удару
	var next_hit_position = 0.5 # За замовчуванням середина
	
	if current_hits < hit_positions.size():
		next_hit_position = hit_positions[current_hits]
	
	# Оновлюємо тільки позицію в шейдері для підготовки до наступного удару
	if %TemperatureIndicator and %TemperatureIndicator.material:
		%TemperatureIndicator.material.set_shader_parameter("forge_center", Vector2(0.5, next_hit_position))
		%TemperatureIndicator.material.set_shader_parameter("impact_y_position", next_hit_position)
	
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

# Функція для показу імпакту в поточному положенні
func show_impact_at_current_position():
	# Перевіряємо, чи у нас достатньо позицій
	if current_hits > 0 and current_hits <= hit_positions.size():
		# Визначаємо поточну позицію
		var current_position = hit_positions[current_hits - 1]
		
		print("Показ імпакту в позиції: ", current_position)
		
		# Оновлюємо позицію центру кування та смуги імпакту
		if %TemperatureIndicator and %TemperatureIndicator.material:
			%TemperatureIndicator.material.set_shader_parameter("forge_center", Vector2(0.5, current_position))
			%TemperatureIndicator.material.set_shader_parameter("impact_y_position", current_position)
		
		# Показуємо ефект імпакту
		animate_impact_effect()

# Функція для анімації ефекту імпакту
func animate_impact_effect():
	# Зупиняємо попередній tween, якщо він існує
	if impact_tween != null and impact_tween.is_valid():
		impact_tween.kill()
	
	# Налаштовуємо параметри імпакту
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		
		# Встановлюємо інтенсивність імпакту на максимум
		shader_material.set_shader_parameter("impact_intensity", 1.0)
		
		# Анімуємо зменшення інтенсивності
		impact_tween = create_tween()
		impact_tween.tween_method(Callable(self, "_update_impact_intensity"), 1.0, 0.0, 0.7)

# Функція для оновлення інтенсивності імпакту
func _update_impact_intensity(intensity: float):
	if %TemperatureIndicator and %TemperatureIndicator.material:
		%TemperatureIndicator.material.set_shader_parameter("impact_intensity", intensity)

# Оновлена функція update_forge_position
func update_forge_position(vertical_position):
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		
		# Перетворюємо в координати шейдера (0.0-1.0)
		var forge_center = Vector2(0.5, vertical_position)
		shader_material.set_shader_parameter("forge_center", forge_center)

# Оновлена функція handle_flip, яка зберігає зміну напрямку ударів
func handle_flip(quality: int):
	var flip_points = 0
	
	match quality:
		2: 
			flip_points = 10
			show_hit_feedback("Ідеальне перевертання!", Color(0, 1, 0))
		1:  
			flip_points = 7
			show_hit_feedback("Хороше перевертання", Color(0.5, 1, 0))
		0:  
			flip_points = 3
			show_hit_feedback("Запізніле перевертання", Color(1, 1, 0))
	
	print("ПЕРЕВЕРТАННЯ: якість = %d, очки за перевертання = %d" % [quality, flip_points])
	
	current_score += flip_points
	
	# Встановлюємо прапорець перевертання
	flip_half_done = true
	
	# Оновлюємо параметр шейдера
	if %TemperatureIndicator and %TemperatureIndicator.material:
		%TemperatureIndicator.material.set_shader_parameter("flip_done", true)
	
	# Позиція після перевертання
	if current_hits < hit_positions.size():
		var next_hit_position = hit_positions[current_hits]
		update_workpiece_region(next_hit_position)
	
	# Переходимо до фази удару
	start_hit_phase()

# Оновлена функція setup_shader_for_workpiece для налаштування імпакту
func setup_shader_for_workpiece():
	# Створюємо текстуру шуму для деформацій
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	noise.fractal_octaves = 3
	
	var noise_texture = NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.noise = noise
	
	# Завантажуємо текстури для заготовки і фінального вигляду
	var billet_texture
	var final_texture
	
	match weapon_type:
		WEAPON_TYPE.DAGGER:
			billet_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
			final_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
		WEAPON_TYPE.SHORT_SWORD:
			billet_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
			final_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
		WEAPON_TYPE.LONG_SWORD:
			billet_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
			final_texture = load("res://assets/smithing/pngimg.com - sword_PNG5525.png")
	
	# Якщо текстури не завантажилися, використовуємо заглушки
	if not billet_texture:
		billet_texture = preload("res://assets/smithing/pngimg.com - sword_PNG5525.png")
	if not final_texture:
		final_texture = preload("res://assets/smithing/pngimg.com - sword_PNG5525.png")
	 
	%TemperatureIndicator.material.set_shader_parameter("displacement_noise", noise_texture)
	%TemperatureIndicator.material.set_shader_parameter("billet_texture", billet_texture)
	%TemperatureIndicator.material.set_shader_parameter("TEXTURE", final_texture)
	
	# Встановлюємо початкові параметри імпакту
	%TemperatureIndicator.material.set_shader_parameter("impact_intensity", 0.0)
	%TemperatureIndicator.material.set_shader_parameter("impact_band_width", 0.08) # Ширина смуги імпакту
	%TemperatureIndicator.material.set_shader_parameter("impact_color", Color(1.0, 0.8, 0.2, 1.0))
	%TemperatureIndicator.material.set_shader_parameter("impact_y_position", 0.5) # Початкова позиція імпакту
	%TemperatureIndicator.material.set_shader_parameter("flip_done", false)
	
	# Застосовуємо початкові параметри для етапу кування
	update_forge_stage(0)
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

# Нова функція для оновлення візуалізації заготовки
func update_forge_visualization():
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		
		# Оновлюємо параметр з урахуванням перевертання
		shader_material.set_shader_parameter("flip_done", flip_half_done)
		
		# Визначаємо прогрес для зміни форми заготовки
		var forge_progress = float(current_hits) / float(total_hits_required)
		
		# Знаходимо відповідну стадію кування
		var stage_index = int(forge_progress * (forging_stages.size() - 1))
		if stage_index >= 0 and stage_index < forging_stages.size():
			var stage = forging_stages[stage_index]
			shader_material.set_shader_parameter("forge_progress", stage.forge_progress)

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
	# print("handle_hit викликано з якістю: ", quality)
	# print("Поточна фаза: ", current_phase)
	# print_stack()  # Це покаже стек викликів
	
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
	
	# Виводимо інформацію в консоль
	print("УДАР: базові очки = %d, множник температури = %.2f, комбо-множник = %.1f, очки за удар = %.1f" % [base_points, temp_multiplier, combo_multiplier, hit_points])
	
	# Додаємо очки
	current_score += hit_points
	
	# Збільшуємо лічильник ударів
	current_hits += 1
	update_hit_counter()
	
	# Симулюємо удар молотом на заготовці
	hammer_strike()
	
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

func _update_heat_amount(heat: float):
	if %TemperatureIndicator and %TemperatureIndicator.material:
		%TemperatureIndicator.material.set_shader_parameter("heat_amount", heat)

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
	
	# Оновлюємо шейдер, щоб показати напрямок удару
	var direction_position = 0.0 if current_direction == "up" else 1.0
	update_workpiece_region(direction_position)

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

func check_cooling():
	var hits_per_cooling = total_hits_required * cooling_rate
	
	var cooling_stages = floor(current_hits / hits_per_cooling)
	
	if cooling_stages == 0:
		current_temperature = TEMPERATURE_STATE.PERFECT
	elif cooling_stages == 1:
		current_temperature = TEMPERATURE_STATE.GOOD
	elif cooling_stages == 2:
		current_temperature = TEMPERATURE_STATE.SATISFACTORY
	else:
		current_temperature = TEMPERATURE_STATE.COLD
	
	update_temperature_indicator()
	
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		var heat_amount = 0.0
		
		match current_temperature:
			TEMPERATURE_STATE.PERFECT:
				heat_amount = 0.9     
			TEMPERATURE_STATE.GOOD:
				heat_amount = 0.8  # Це значення було неправильним в hammer_strike()     
			TEMPERATURE_STATE.SATISFACTORY:
				heat_amount = 0.6      
			TEMPERATURE_STATE.COLD:
				heat_amount = 0.2  # Зробив холоднішим для кращого візуального контрасту   
		
		shader_material.set_shader_parameter("heat_amount", heat_amount)

func update_temperature_indicator():
	# Оновлюємо текст температури
	match current_temperature:
		TEMPERATURE_STATE.PERFECT:
			%TemperatureLabel.text = "Ідеальна температура (100%)"
		TEMPERATURE_STATE.GOOD:
			%TemperatureLabel.text = "Хороша температура (75%)"
		TEMPERATURE_STATE.SATISFACTORY:
			%TemperatureLabel.text = "Задовільна температура (50%)"
		TEMPERATURE_STATE.COLD:
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


func update_workpiece_region(position: float, active: bool = true):
	if %TemperatureIndicator and %TemperatureIndicator.material:
		var shader_material = %TemperatureIndicator.material
		
		# Встановлюємо параметр flip_done, але вимикаємо підсвічування
		shader_material.set_shader_parameter("flip_done", flip_half_done)
		
		# Відключаємо підсвічування, встановлюючи highlight_active = false
		shader_material.set_shader_parameter("highlight_active", false)
		
		# Можна також встановити highlight_size = 0 для додаткової гарантії
		shader_material.set_shader_parameter("highlight_size", 0.0)

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
	#visible = false
	mini_game_cancelled.emit()
