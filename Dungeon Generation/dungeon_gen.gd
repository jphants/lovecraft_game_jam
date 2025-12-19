extends Node3D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var dungeon: Node3D = $Dungeon
@onready var player := $ProtoController
@onready var ui := $CanvasLayer
@export var rain_pause_time := 10.0

func _ready() -> void:
	audio_stream_player.play()

	# ===============================
	# PLAYER → UI
	# ===============================
	player.battery_changed.connect(ui.update_battery)
	player.sanity_changed.connect(ui.update_health)

	player.pause_toggled.connect(ui.show_pause)
	player.interact_visible.connect(ui.show_interact)

	# ===============================
	# UI INIT
	# ===============================
	ui.update_battery(player.battery)
	ui.update_health(player.sanity)
	ui.show_pause(false)
	ui.show_interact(false)

func terror_phase() -> void:
	# 1️⃣ Corte súbito
	audio_stream_player.stop()

	# 2️⃣ Silencio
	await get_tree().create_timer(rain_pause_time).timeout

	# 3️⃣ Retoma la lluvia
	audio_stream_player.play()
