# Слот для компонентів
extends Slot
class_name ComponentSlot

@export var allowed_component: ComponentRecipe

var assigned_components: Array[ComponentRecipe] = []

# Отримати поточну кількість компонентів
func get_current_quantity() -> int:
	return assigned_components.size()

# Очистити слот
func clear() -> void:
	assigned_components.clear()
	super()

# Додати компонент у слот
func assign_component(component: ComponentRecipe) -> bool:
	# Перевірка на відповідність типу
	if is_component_valid(component):
		# Перевірка чи слот не переповнений
		if can_add_more():
			assigned_components.append(component)
			
			# Перерахувати якість
			update_quality()
			
			# Відправити сигнал про додавання компонента
			content_added.emit(component)
			
			# Перевірити чи слот заповнений і відправити сигнал якщо так
			if is_filled() and get_current_quantity() == quantity:
				slot_filled.emit(self)
				
			return true
	return false

# Перевірити чи компонент підходить для цього слота
func is_component_valid(component: ComponentRecipe) -> bool:
	# Якщо не вказано зразка, приймаємо будь-який компонент
	if allowed_component == null:
		return true
	
	# Виклик відповідної функції перевірки залежно від типу компонента
	if component is WeaponComponentRecipe:
		return is_weapon_component_valid(component)
	elif component is BodyArmorComponentRecipe or component is HeadArmorComponentRecipe:
		return is_armor_component_valid(component)
	elif component is ToolComponentRecipe:
		return is_tool_component_valid(component)
	else:
		return false

# Перевірка компонентів зброї
func is_weapon_component_valid(component: ComponentRecipe) -> bool:
	# Компоненти одноручної ріжучої зброї
	if component is OneHandedCutWeaponComponentRecipe and allowed_component is OneHandedCutWeaponComponentRecipe:
		var test_component = component as OneHandedCutWeaponComponentRecipe
		var allowed = allowed_component as OneHandedCutWeaponComponentRecipe
		
		# Перевірити потрібний тип (якщо він вказаний)
		if allowed.one_handed_cut_weapon_type != -1 and test_component.one_handed_cut_weapon_type != allowed.one_handed_cut_weapon_type:
			return false
	
	# Компоненти дворучної ріжучої зброї
	elif component is LongCutWeaponComponentRecipe and allowed_component is LongCutWeaponComponentRecipe:
		var test_component = component as LongCutWeaponComponentRecipe
		var allowed = allowed_component as LongCutWeaponComponentRecipe
		
		if allowed.long_cut_weapon_type != -1 and test_component.long_cut_weapon_type != allowed.long_cut_weapon_type:
			return false
	
	# Компоненти древкової зброї
	elif component is PoleWeaponComponentRecipe and allowed_component is PoleWeaponComponentRecipe:
		var test_component = component as PoleWeaponComponentRecipe
		var allowed = allowed_component as PoleWeaponComponentRecipe
		
		if allowed.pole_weapon_type != -1 and test_component.pole_weapon_type != allowed.pole_weapon_type:
			return false
	
	# Компоненти важкої зброї
	elif component is HeavyWeaponComponentRecipe and allowed_component is HeavyWeaponComponentRecipe:
		var test_component = component as HeavyWeaponComponentRecipe
		var allowed = allowed_component as HeavyWeaponComponentRecipe
		
		if allowed.heavy_weapon_type != -1 and test_component.heavy_weapon_type != allowed.heavy_weapon_type:
			return false
	
	# Компоненти кинджалів
	elif component is DaggerComponentRecipe and allowed_component is DaggerComponentRecipe:
		var test_component = component as DaggerComponentRecipe
		var allowed = allowed_component as DaggerComponentRecipe
		
		if allowed.dagger_type != -1 and test_component.dagger_type != allowed.dagger_type:
			return false
	
	# Якщо дійшли до тут, це означає, що перевірки пройдені успішно або тип не розпізнаний
	return true

# Перевірка компонентів броні
func is_armor_component_valid(component: ComponentRecipe) -> bool:
	# Компоненти захисту голови
	if component is HeadArmorComponentRecipe and allowed_component is HeadArmorComponentRecipe:
		var test_component = component as HeadArmorComponentRecipe
		var allowed = allowed_component as HeadArmorComponentRecipe
		
		if allowed.head_armor_type != -1 and test_component.head_armor_type != allowed.head_armor_type:
			return false
	
	# Компоненти захисту тіла
	elif component is BodyArmorComponentRecipe and allowed_component is BodyArmorComponentRecipe:
		var test_component = component as BodyArmorComponentRecipe
		var allowed = allowed_component as BodyArmorComponentRecipe
		
		if allowed.body_armor_type != -1 and test_component.body_armor_type != allowed.body_armor_type:
			return false
	
	# Якщо дійшли до тут, це означає, що перевірки пройдені успішно або тип не розпізнаний
	return true

# Перевірка компонентів інструментів
func is_tool_component_valid(component: ComponentRecipe) -> bool:
	if component is ToolComponentRecipe and allowed_component is ToolComponentRecipe:
		var test_component = component as ToolComponentRecipe
		var allowed = allowed_component as ToolComponentRecipe
		
		if allowed.tool_type != -1 and test_component.tool_type != allowed.tool_type:
			return false
	
	# Якщо дійшли до тут, це означає, що перевірки пройдені успішно або тип не розпізнаний
	return true
