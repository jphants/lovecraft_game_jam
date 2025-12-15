extends Node3D

@export var fps := 12
@export var total_frames := 30

var frame := 0
var time := 0.0

func _process(delta):
	time += delta
	if time >= 1.0 / fps:
		time = 0
		frame = (frame + 1) % total_frames
		$MeshInstance3D2.material_override.set_shader_parameter("frame", frame)
		
