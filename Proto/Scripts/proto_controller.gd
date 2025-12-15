# Dungeon Player Controller – Horror Jam
# Movimiento por pasos + linterna con mouse
# Godot 4.x

extends CharacterBody3D

# =========================
# CONFIGURACIÓN GENERAL
# =========================
@export var has_gravity := true

@export_group("Dungeon Movement")
@export var step_distance := 2.0
@export var move_duration := 0.15
@export var rotate_duration := 0.1

@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_flashlight : String = "flashlight"

@export_group("Flashlight Mouse")
@export var mouse_sensitivity := 0.002
@export var max_vertical_angle := 45.0

@export_group("Flashlight Wobble")
@export var wobble_strength := 0.02
@export var wobble_speed := 6.0

# =========================
# REFERENCIAS
# =========================
@onready var head: Node3D = $Head
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight/SpotLight3D
@onready var flashlight_root: Node3D = $Head/Camera3D/Flashlight

# =========================
# ESTADO
# =========================
var is_moving := false
var target_position: Vector3
var target_rotation_y: float

var flashlight_on := true
var flashlight_base_position: Vector3
var flashlight_base_rotation: Vector3

var wobble_time := 0.0
var mouse_rotation := Vector2.ZERO
@onready var SeeCast = $Head/Camera3D/Flashlight/RayCast3D
# =========================
# READY
# =========================
func _ready() -> void:
	SeeCast.enabled = true
	flashlight_base_position = flashlight_root.position
	flashlight_base_rotation = flashlight_root.rotation
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

@export var forward_repeat_delay := 0.18
var forward_timer := 0.0


# =========================
# INPUT
# =========================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_rotation.x -= event.relative.y * mouse_sensitivity
		mouse_rotation.y -= event.relative.x * mouse_sensitivity

		mouse_rotation.x = clamp(
			mouse_rotation.x,
			deg_to_rad(-max_vertical_angle),
			deg_to_rad(max_vertical_angle)
		)

	if is_moving:
		return

	if event.is_action_pressed(input_left):
		rotate_step(90)
	elif event.is_action_pressed(input_right):
		rotate_step(-90)
	elif event.is_action_pressed(input_back):
		move_backward()

	if event.is_action_pressed(input_flashlight):
		switch_flashlight()


# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:

	if SeeCast.is_colliding():
		var target = SeeCast.get_collider()
		if target.has_method("interact"):
			$CanvasLayer/BoxContainer/Label.show()
			print("You can interact with this...")
		else:
			$CanvasLayer/BoxContainer/Label.hide()
	else:
		$CanvasLayer/BoxContainer/Label.hide()

	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()

	# Forward continuo por tiles
	if not is_moving and Input.is_action_pressed(input_forward):
		forward_timer -= delta
		if forward_timer <= 0.0:
			move_forward()
			forward_timer = forward_repeat_delay
	else:
		forward_timer = 0.0

	update_flashlight_wobble(delta)
	update_flashlight_aim()

# =========================
# MOVIMIENTO DUNGEON
# =========================
func move_forward() -> void:
	var direction := -transform.basis.z
	var motion := direction * step_distance

	var collision := move_and_collide(motion, true)
	if collision:
		return

	is_moving = true
	target_position = global_position + motion

	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		target_position,
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func(): is_moving = false)
	
func move_backward() -> void:
	var direction := transform.basis.z
	var motion := direction * step_distance

	var collision := move_and_collide(motion, true)
	if collision:
		return

	is_moving = true
	target_position = global_position + motion

	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		target_position,
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func(): is_moving = false)

func rotate_step(degrees: float) -> void:
	is_moving = true
	target_rotation_y = rotation.y + deg_to_rad(degrees)

	var tween := create_tween()
	tween.tween_property(
		self,
		"rotation:y",
		target_rotation_y,
		rotate_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func(): is_moving = false)

# =========================
# FLASHLIGHT
# =========================
func switch_flashlight() -> void:
	flashlight_on = !flashlight_on
	flashlight.visible = flashlight_on

func update_flashlight_aim() -> void:
	if not flashlight_on:
		return

	flashlight_root.rotation = flashlight_base_rotation + Vector3(
		mouse_rotation.x,
		mouse_rotation.y,
		0
	)

func update_flashlight_wobble(delta: float) -> void:
	if is_moving:
		wobble_time += delta * wobble_speed

		var x_offset := sin(wobble_time) * wobble_strength
		var y_offset: float = abs(cos(wobble_time * 2.0)) * wobble_strength * 0.5

		flashlight_root.position = flashlight_base_position + Vector3(
			x_offset,
			-y_offset,
			0
		)
	else:
		flashlight_root.position = flashlight_root.position.lerp(
			flashlight_base_position,
			delta * 10.0
		)
