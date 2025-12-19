extends CharacterBody3D

# =====================================================
# SEÑALES (COMUNICACIÓN CON UI)
# =====================================================
signal battery_changed(value)
signal sanity_changed(value)
signal pause_toggled(value)
signal interact_visible(value)

# =====================================================
# CONFIGURACIÓN GENERAL
# =====================================================
@export var has_gravity := true
@export var cheatLight := false

@export_group("Dungeon Movement")
@export var step_distance := 2.0
@export var move_duration := 0.15
@export var rotate_duration := 0.1

@export_group("Input Actions")
@export var input_left := "ui_left"
@export var input_right := "ui_right"
@export var input_forward := "ui_up"
@export var input_back := "ui_down"
@export var input_flashlight := "flashlight"
@export var input_pause := "ui_pause"

@export_group("Flashlight Mouse")
@export var mouse_sensitivity := 0.002
@export var max_vertical_angle := 45.0

@export_group("Flashlight Wobble")
@export var wobble_strength := 0.02
@export var wobble_speed := 6.0

@export_group("Footsteps")
@export var forward_repeat_delay := 0.18

# =====================================================
# NODOS
# =====================================================
@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var flashlight_root: Node3D = $Head/Camera3D/Flashlight
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight/SpotLight3D
@onready var see_cast: RayCast3D = $Head/Camera3D/Flashlight/RayCast3D

@onready var step_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var heartbeat_player: AudioStreamPlayer3D = $Heartbeat

# =====================================================
# ESTADO PLAYER
# =====================================================
var battery: int = Global.battery
var sanity: int = Global.sanity

var is_moving := false
var target_rotation_y := 0.0
var forward_timer := 0.0

# Grid
var grid_position := Vector2i.ZERO
var fixed_height: float

# Flashlight
var flashlight_on := true
var flashlight_base_position: Vector3
var flashlight_base_rotation: Vector3
var wobble_time := 0.0
var mouse_rotation := Vector2.ZERO

# Pause
var paused := false

# Camera shake
var camera_base_pos: Vector3
var shake_time := 0.0

@export_group("Camera Shake")
@export var max_shake_strength := 0.01
@export var shake_speed := 4.0

# Sanity tick
var sanity_delay := 1.0
var sanity_timer := 0.0

# =====================================================
# READY
# =====================================================
func _ready() -> void:
	randomize()

	fixed_height = global_position.y
	camera_base_pos = camera_3d.position

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	heartbeat_player.stream.loop = true
	heartbeat_player.play()

	see_cast.enabled = true
	flashlight_base_position = flashlight_root.position
	flashlight_base_rotation = flashlight_root.rotation

	_emit_stats()

func set_start_position(world_pos: Vector3) -> void:
	fixed_height = world_pos.y

	grid_position = Vector2i(
		round(world_pos.x / step_distance),
		round(world_pos.z / step_distance)
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
	elif event.is_action_pressed(input_flashlight) and battery > 0:
		switch_flashlight()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(input_pause):
		paused = !paused
		emit_signal("pause_toggled", paused)

		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if paused
			else Input.MOUSE_MODE_CAPTURED
		)

# =====================================================
# PROCESS
# =====================================================
func _physics_process(delta: float) -> void:
	# Interacción
	if see_cast.is_colliding():
		var target := see_cast.get_collider()
		emit_signal("interact_visible", target and target.has_method("interact"))
	else:
		emit_signal("interact_visible", false)

	# Gravedad
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()

	# Movimiento forward continuo
	if not is_moving and Input.is_action_pressed(input_forward):
		forward_timer -= delta
		if forward_timer <= 0.0:
			move_forward()
			forward_timer = forward_repeat_delay
	else:
		forward_timer = 0.0

	update_flashlight_wobble(delta)
	update_flashlight_aim()
	update_camera_shake(delta)

	if not is_moving:
		global_position = grid_to_world(grid_position)

	if battery <= 0 and flashlight_on:
		flashlight_on = false
		flashlight.visible = false

func _process(delta: float) -> void:
	sanity_timer += delta
	if sanity_timer < sanity_delay:
		return

	sanity_timer = 0.0

	if cheatLight:
		_emit_stats()
		return

	if flashlight_on:
		sanity += 1
		battery -= 1
	else:
		sanity -= 1

	battery = clamp(battery, 0, 100)
	sanity = clamp(sanity, 0, 100)

	_emit_stats()
	_update_heartbeat()

# =====================================================
# GRID HELPERS
# =====================================================
func grid_to_world(g: Vector2i) -> Vector3:
	return Vector3(g.x * step_distance, fixed_height, g.y * step_distance)

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

	var tween := create_tween()
	tween.tween_property(self, "global_position", target_world, move_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	tween.tween_property(self, "global_position", target_world, move_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		global_position = grid_to_world(grid_position)
		is_moving = false
	)

func rotate_step(degrees: float) -> void:
	is_moving = true
	target_rotation_y = rotation.y + deg_to_rad(degrees)

	var tween := create_tween()
	tween.tween_property(self, "rotation:y", target_rotation_y, rotate_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func(): is_moving = false)

# =====================================================
# FLASHLIGHT
# =====================================================
func switch_flashlight() -> void:
	flashlight_on = !flashlight_on
	flashlight.visible = flashlight_on

func update_flashlight_aim() -> void:
	flashlight_root.rotation = flashlight_base_rotation + Vector3(
		mouse_rotation.x,
		mouse_rotation.y,
		0
	)

func update_flashlight_wobble(delta: float) -> void:
	if is_moving:
		wobble_time += delta * wobble_speed
		var x : float = sin(wobble_time) * wobble_strength
		var y : float = abs(cos(wobble_time * 2.0)) * wobble_strength * 0.5
		flashlight_root.position = flashlight_base_position + Vector3(x, -y, 0)
	else:
		flashlight_root.position = flashlight_root.position.lerp(
			flashlight_base_position,
			delta * 10.0
		)

# =====================================================
# AUDIO
# =====================================================
func play_variation():
	step_player.stop()
	step_player.pitch_scale = lerp(0.6, 1.1, randf())
	step_player.volume_db = lerp(-8.0, -4.0, randf())
	step_player.play()

func _update_heartbeat() -> void:
	var t := 1.0 - (sanity / 100.0)
	heartbeat_player.pitch_scale = lerp(0.85, 1.6, t)
	heartbeat_player.volume_db = lerp(-20.0, -5.0, t)

# =====================================================
# CAMERA SHAKE
# =====================================================
func update_camera_shake(delta: float) -> void:
	var sanity_ratio : float = clamp(float(sanity) / 100.0, 0.0, 1.0)
	var shake_strength : float = lerp(max_shake_strength, 0.0, sanity_ratio)

	if shake_strength < 0.001:
		camera_3d.position = camera_3d.position.lerp(camera_base_pos, delta * 8.0)
		return

	shake_time += delta * shake_speed
	var offset := Vector3(
		sin(shake_time * 1.3),
		sin(shake_time * 2.1),
		sin(shake_time * 0.9)
	) * shake_strength

	camera_3d.position = camera_base_pos + offset

# =====================================================
# HELPERS
# =====================================================
func _emit_stats():
	emit_signal("battery_changed", battery)
	emit_signal("sanity_changed", sanity)
