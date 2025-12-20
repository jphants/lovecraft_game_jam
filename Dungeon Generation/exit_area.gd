extends Area3D

signal player_entered_exit

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		player_entered_exit.emit()
