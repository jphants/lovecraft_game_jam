extends Area3D

@export var target_scene: PackedScene

const MENU = preload("uid://c3fs75ctbakxx")
const DUNGEON_GENERATOR = preload("uid://ddofrga67pgaf")

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		if Global.floor < Global.level:
			Global.floor += 1
			TransitionBlink.transition()
			await TransitionBlink.transition_finished
			get_tree().change_scene_to_file("uid://ddofrga67pgaf")
		else:
			TransitionBlink.transition()
			await TransitionBlink.transition_finished
			get_tree().change_scene_to_file("uid://c3fs75ctbakxx")
