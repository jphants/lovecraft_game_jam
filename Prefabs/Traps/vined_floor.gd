extends Node3D

const VINES_1 = preload("uid://ce6wkaifxk8d6")
const VINES_2 = preload("uid://coud52hpxhy5l")
const CIELING_VINE = preload("uid://ddrtpg53qxg6i")

@onready var deco: Node3D = $Deco

# Guardamos data de cada vine
var vines: Array = []

func _ready() -> void:
	randomize()

	# Spawneamos varios (podés cambiar la cantidad)
	for i in range(3):
		spawn_random_vine()

func spawn_random_vine() -> void:
	var scenes: Array[PackedScene] = [
		VINES_1,
		VINES_2,
		CIELING_VINE
	]

	var vine: Node3D = scenes.pick_random().instantiate()
	deco.add_child(vine)

	# Transformaciones iniciales
	var base_scale := randf_range(0.3, 0.7)
	vine.scale = Vector3.ONE * base_scale
	vine.rotate_y(randf_range(0.0, TAU))

	# Parámetros de palpitar (random)
	var pulse_data = {
		"node": vine,
		"base_scale": base_scale,
		"speed": randf_range(0.8, 2.5),   # velocidad
		"amplitude": randf_range(0.03, 0.08), # intensidad
		"phase": randf_range(0.0, TAU)
	}

	vines.append(pulse_data)

func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0

	for data in vines:
		var pulse : float = sin(time * data.speed + data.phase)
		var scale : float = data.base_scale * (1.0 + pulse * data.amplitude)
		data.node.scale = Vector3.ONE * scale
