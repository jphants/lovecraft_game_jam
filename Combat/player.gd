class_name Player
extends Entity

@export var rotate_duration := 0.1

@export_group("Input Actions")
@export var input_left : String = "m_left"
@export var input_right : String = "m_right"

@export_group("Flashlight Mouse")
@export var mouse_sensitivity := 0.002
@export var max_vertical_angle := 45.0

@onready var flashlight_root: Node3D = $Camera3D/Flashlight
@onready var camera: Camera3D = $Camera3D

var player_dialogue = preload("res://Dialogs/PlayerDialogue.dialogue")

var is_rotating := false
var mouse_rotation := Vector2.ZERO

var target := 0 

signal chosen

func _ready() -> void:
	set_process_unhandled_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if is_rotating:
		return

	if event.is_action_pressed(input_left):
		rotate_step(90)
		target = (target+1) % 4
	elif event.is_action_pressed(input_right):
		rotate_step(-90)
		target = (target-1 + 4) % 4
	elif event.is_action_pressed("click"):
		emit_signal("chosen")

func _process(_delta: float) -> void:
	update_flashlight_aim()

func rotate_step(degrees: float) -> void:
	is_rotating = true
	var target_y := rotation.y + deg_to_rad(degrees)

	var tween := create_tween()
	tween.tween_property(
		self,
		"rotation:y",
		target_y,
		rotate_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		is_rotating = false
	)

func update_flashlight_aim() -> void:
	var mouse_pos: Vector2 = camera.get_viewport().get_mouse_position()
	
	var t : Vector3 = camera.project_position(mouse_pos, -1000)

	flashlight_root.look_at(t)
	flashlight_root.rotation_degrees.x += 90

# Entity

func get_attack() -> Attack:
	DialogueManager.show_dialogue_balloon(player_dialogue)
	await  DialogueManager.dialogue_ended
	return attacks.pick_random()

func get_target(entities : Array[Entity]) -> Entity:
	set_process_unhandled_input(true)
	await chosen
	set_process_unhandled_input(false)
	return entities[target]
