# mini_game.gd
extends CanvasLayer
class_name MiniGame

signal mini_game_completed(success, score)
signal mini_game_cancelled

func _ready():
	# Зробити UI невидимим при створенні
	visible = false

func start_game():
	# Показати UI при старті гри
	visible = true
	
	# Реалізується в дочірніх класах
	pass

func end_game(success: bool, score: int = 0):
	mini_game_completed.emit(success, score)
	queue_free()

func cancel_game():
	mini_game_cancelled.emit()
	queue_free()
	
# Щоб зупиняти інший ігровий процес під час міні-гри
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		cancel_game()
	# Блокуємо події, щоб вони не проходили в основну гру
	get_viewport().set_input_as_handled()
