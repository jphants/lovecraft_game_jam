extends Node3D

# ===============================
# NODES
# ===============================
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player_2: AudioStreamPlayer = $AudioStreamPlayer2
@onready var dungeon: Node3D = $Dungeon
@onready var player := $ProtoController
@onready var ui := $CanvasLayer
@onready var exit_area := $ExitArea

# ===============================
# AUDIO / SCENES
# ===============================
@export var rain_pause_time := 10.0
const SCARY_RISER_432997 = preload("uid://bt5a427f6bl17")
const OUTSIDE_SCENE = preload("uid://dhhgoa5qvwsv")
const REACTIONS = preload("uid://yr1hgpna3cgw")
const PROTO_COMBAT_1 = preload("uid://dcyhcwi2iva5l")

# ===============================
# PROGRESSION
# ===============================
var level := 2
var floor := 0

# ===============================
# BLINK SYSTEM
# ===============================
@export var blink_min_time := 2.0
@export var blink_max_time := 7.0
@export var blink_chance := 0.3

var blink_enabled := true
var blink_active := false

# ===============================
# TERROR SYSTEM
# ===============================
@export var terror_min_time := 10.0
@export var terror_max_time := 20.0
@export var terror_event_chance := 0.3

var terror_enabled := true
var terror_active := false


# ===============================
# READY
# ===============================
func _ready() -> void:
	audio_stream_player.play()

	exit_area.player_entered_exit.connect(_on_exit_reached)

	# PLAYER → UI
	player.battery_changed.connect(ui.update_battery)
	player.sanity_changed.connect(ui.update_health)
	player.pause_toggled.connect(ui.show_pause)
	player.interact_visible.connect(ui.show_interact)

	# UI INIT
	ui.update_battery(player.battery)
	ui.update_health(player.sanity)
	ui.show_pause(false)
	ui.show_interact(false)

	# Start systems
	schedule_next_blink()
	schedule_next_terror()


# ===============================
# EXIT / FLOOR CHANGE
# ===============================
func _on_exit_reached() -> void:
	blink_enabled = false
	terror_enabled = false

	TransitionBlink.transition()
	await TransitionBlink.transition_finished

	if floor < level and dungeon:
		floor += 1
		dungeon.regenerate()

		blink_enabled = true
		terror_enabled = true
		schedule_next_blink()
		schedule_next_terror()
	else:
		get_tree().call_deferred(
			"change_scene_to_file",
			PROTO_COMBAT_1.resource_path
		)


# ===============================
# BLINK LOOP
# ===============================
func schedule_next_blink() -> void:
	if not blink_enabled:
		return

	var wait_time := randf_range(blink_min_time, blink_max_time)
	await get_tree().create_timer(wait_time).timeout

	if blink_enabled and not blink_active and randf() < blink_chance:
		await do_blink()

	if blink_enabled:
		schedule_next_blink()


func do_blink() -> void:
	blink_active = true
	TransitionBlink.transition()
	await TransitionBlink.transition_finished
	blink_active = false


# ===============================
# TERROR LOOP
# ===============================
func schedule_next_terror() -> void:
	if not terror_enabled:
		return

	var wait_time := randf_range(terror_min_time, terror_max_time)
	await get_tree().create_timer(wait_time).timeout

	if terror_enabled and not terror_active:
		await start_terror_event()

	if terror_enabled:
		schedule_next_terror()


func start_terror_event() -> void:
	terror_active = true
	await terror_phase()
	terror_active = false


# ===============================
# TERROR PHASE
# ===============================
func terror_phase() -> void:
	# 1️⃣ Corte súbito de la lluvia
	audio_stream_player.stop()

	# 2️⃣ Decide si habrá riser
	var trigger_event := randf() < terror_event_chance

	# 3️⃣ Silencio inquietante
	var silence_time := rain_pause_time * 0.85
	await get_tree().create_timer(silence_time).timeout

	# 4️⃣ Evento raro
	if trigger_event:
		audio_stream_player_2.stream = SCARY_RISER_432997
		audio_stream_player_2.play()
		await get_tree().create_timer(0.4).timeout

	# 5️⃣ Retoma la lluvia
	audio_stream_player.play()

	# 6️⃣ REACCIÓN DEL NIÑO
	DialogueManager.show_dialogue_balloon(REACTIONS)
