extends Node3D

const BOOK_1  = preload("uid://dtti3ygptu2bo")
const BOWL    = preload("uid://xr0tbto1wk6")
const PAPER_1 = preload("uid://pf8icrnvl6r6")
const PAPER_2 = preload("uid://bb5ehnlbf6r60")

@onready var deco: Node3D = $Deco

func _ready() -> void:
	randomize()
	spawn_random_prop()

func spawn_random_prop() -> void:
	var scenes: Array[PackedScene] = [
		BOOK_1,
		BOWL,
		PAPER_1,
		PAPER_2
	]

	# 1️⃣ Instanciar
	var prop: Node3D = scenes.pick_random().instantiate()
	deco.add_child(prop)

	# 2️⃣ Offset leve
	var offset := Vector3(
		randf_range(-0.5, 0.5), # X
		0.0,
		randf_range(-0.5, 0.5)  # Z
	)
	prop.position += offset

	# 3️⃣ Rotación Y leve (±10 grados)
	prop.rotate_y(deg_to_rad(randf_range(-10.0, 10.0)))

	# 4️⃣ Snap al suelo (Y = 0)
	prop.position.y = 0.0
