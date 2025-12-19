extends Node3D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var dungeon: Node3D = $Dungeon
@onready var player := $ProtoController
@onready var ui := $CanvasLayer

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
	# UI INIT (estado inicial)
	# ===============================
	ui.update_battery(player.battery)
	ui.update_health(player.sanity)
	ui.show_pause(false)
	ui.show_interact(false)
	pass
