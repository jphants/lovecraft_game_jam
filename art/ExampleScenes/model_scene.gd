extends Node3D

@onready var animation_player: AnimationPlayer = $Camera3D/AnimationPlayer
const ENDING_DIALOGUE = preload("uid://dod8kw75pxlh3")

func _ready() -> void:
	animation_player.play("wake up")

	DialogueManager.show_dialogue_balloon(ENDING_DIALOGUE)

	# Espera a que termine el diálogo
	await DialogueManager.dialogue_ended

	# Cierra el juego
	get_tree().quit()
