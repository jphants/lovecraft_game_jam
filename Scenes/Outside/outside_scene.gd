extends Node3D

const OPENING_DIALOGUE = preload("uid://vdqqnaf8hxo2")

func _ready() -> void:
	DialogueManager.show_dialogue_balloon(OPENING_DIALOGUE)
	pass
