# Interactable.gd (базовий клас)
extends Area2D
class_name Interactable

@export var interaction_text: String = "Press E to interact"
@export var layer: int = 0

func interact() -> void:
	# Базова реалізація, яку перевизначать нащадки
	print("Interacting with %s" % name)

func show_interaction_promt():
	%InteractionLabel.visible = true
	
func hide_interaction_promt():
	%InteractionLabel.visible = false
