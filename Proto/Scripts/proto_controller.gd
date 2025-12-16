extends CharacterBody3D

# =====================================================
# CONFIGURACIÓN GENERAL
# =====================================================
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

@export_group("Footsteps")
@export var extra_step_chance := 0.01
@export var extra_step_delay_min := 1.0
@export var extra_step_delay_max := 2.0

@export var forward_repeat_delay := 0.18

# =====================================================
# NODOS
# =====================================================
@onready var head: Node3D = $Head
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight/SpotLight3D
@onready var flashlight_root: Node3D = $Head/Camera3D/Flashlight
@onready var SeeCast: RayCast3D = $Head/Camera3D/Flashlight/RayCast3D
@onready var step_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var step_player_extra: AudioStreamPlayer3D = $AudioStreamPlayer3D2

@onready var battery_label: Label = $CanvasLayer/Battery
@onready var sanity_label: Label = $CanvasLayer/Sanity

@export var battery = Global.battery
@export var sanity = Global.sanity
# =====================================================
# ESTADO
# =====================================================
var is_moving := false
var target_rotation_y := 0.0
var forward_timer := 0.0

# GRID (🔒 CRÍTICO)
var grid_position := Vector2i.ZERO

# Linterna
var flashlight_on := true
var flashlight_base_position: Vector3
var flashlight_base_rotation: Vector3
var wobble_time := 0.0
var mouse_rotation := Vector2.ZERO

func update_battery():
	battery_label.text = "Battery: " + str(battery)
	
func update_sanity():
	sanity_label.text = "Sanity: " + str(sanity)

# =====================================================
# READY
# =====================================================
func _ready() -> void:
	update_battery()
	update_sanity()
	
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	

	SeeCast.enabled = true
	flashlight_base_position = flashlight_root.position
	flashlight_base_rotation = flashlight_root.rotation

	# 🔒 SNAP INICIAL AL GRID
	grid_position = Vector2i(
		round(global_position.x / step_distance),
		round(global_position.z / step_distance)
	)
	global_position = grid_to_world(grid_position)

# =====================================================
# INPUT
# =====================================================
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
	elif event.is_action_pressed(input_flashlight):
		switch_flashlight()

# =====================================================
# PHYSICS
# =====================================================
func _physics_process(delta: float) -> void:

	# Interacción
	if SeeCast.is_colliding():
		var target = SeeCast.get_collider()
		$CanvasLayer/BoxContainer/Label.visible = target and target.has_method("interact")
	else:
		$CanvasLayer/BoxContainer/Label.hide()

	# Gravedad
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

	# 🔒 SNAP DEFENSIVO
	if not is_moving:
		global_position = grid_to_world(grid_position)

# =====================================================
# GRID HELPERS
# =====================================================
func grid_to_world(g: Vector2i) -> Vector3:
	return Vector3(
		g.x * step_distance,
		global_position.y,
		g.y * step_distance
	)

func get_forward_dir() -> Vector2i:
	return Vector2i(
		-round(transform.basis.z.x),
		-round(transform.basis.z.z)
	)

# =====================================================
# MOVIMIENTO
# =====================================================
func move_forward() -> void:
	var dir := get_forward_dir()
	var next_grid := grid_position + dir
	var target_world := grid_to_world(next_grid)

	if test_move(global_transform, target_world - global_position):
		return

	grid_position = next_grid
	is_moving = true

	play_variation()
	if randf() < extra_step_chance:
		_play_extra_step_delayed()

	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		target_world,
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		global_position = grid_to_world(grid_position)
		is_moving = false
	)

func move_backward() -> void:
	var dir := -get_forward_dir()
	var next_grid := grid_position + dir
	var target_world := grid_to_world(next_grid)

	if test_move(global_transform, target_world - global_position):
		return

	grid_position = next_grid
	is_moving = true

	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		target_world,
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		global_position = grid_to_world(grid_position)
		is_moving = false
	)

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

# =====================================================
# AUDIO
# =====================================================
func play_variation():
	step_player.stop()
	step_player.pitch_scale = lerp(0.6, 1.1, randf())
	step_player.volume_db = lerp(-8.0, -4.0, randf())
	step_player.play()

func _play_extra_step_delayed() -> void:
	var delay := randf_range(extra_step_delay_min, extra_step_delay_max)
	await get_tree().create_timer(delay).timeout

	step_player_extra.stop()
	step_player_extra.pitch_scale = lerp(0.2, 0.4, randf())
	step_player_extra.play()
	print("I was hiding")
	

# =====================================================
# FLASHLIGHT
# =====================================================
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
		var x: float = sin(wobble_time) * wobble_strength
		var y: float = abs(cos(wobble_time * 2.0)) * wobble_strength * 0.5

		flashlight_root.position = flashlight_base_position + Vector3(x, -y, 0)
	else:
		flashlight_root.position = flashlight_root.position.lerp(
			flashlight_base_position,
			delta * 10.0
		)

func _process(delta: float) -> void:
	if not flashlight_on:
		print("Crazy?")
		sanity -= 1
		update_sanity()
	pass
