extends Node3D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var dungeon: Node3D = $Dungeon

func _ready() -> void:
	audio_stream_player.play()
	pass
