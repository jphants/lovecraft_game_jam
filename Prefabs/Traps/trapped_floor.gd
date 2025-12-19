extends Node3D

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

const EERIE_SLOW_MOTION_EFFECT_31536 = preload("uid://c0g3bp3onsk6u")
const EERIE_SCRAPE_220190 = preload("uid://caju2iv28n4t3")

var wasUsed: bool = false

var eerie_sounds: Array[AudioStream] = [
	EERIE_SLOW_MOTION_EFFECT_31536,
	EERIE_SCRAPE_220190
]

func _ready() -> void:
	randomize()

	# Elegir audio al azar
	var random_sound: AudioStream = eerie_sounds.pick_random()
	audio_stream_player_3d.stream = random_sound

func _on_area_3d_body_entered(body: Node3D) -> void:
	if wasUsed:
		return

	wasUsed = true
	audio_stream_player_3d.play()
	print("Something lurks in the dark")
