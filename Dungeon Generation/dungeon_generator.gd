@tool
extends Node3D

# =========================
# PLAYER
# =========================
@export_group("Player")
@export var player: CharacterBody3D

@export var generate_map := false : set = _set_generate
@export var clear_map := false : set = _set_clear

# =========================
# GRID
# =========================
@export_group("Grid")
@export var width := 30
@export var height := 30
@export var cell_size := 2.0

# =========================
# ROOMS
# =========================
@export_group("Rooms")
@export var room_count := 6
@export var min_room_size := 3
@export var max_room_size := 7

# =========================
# PREFABS (PAIRED)
# =========================
@export_group("Floors")
@export var floors: Array[WeightedPrefab] = []

@export_group("Fillers")
@export var fillers: Array[WeightedPrefab] = []

@export_group("Room Items")
@export var room_items: Array[WeightedPrefab] = []

@export_group("Start")
@export var starts: Array[WeightedPrefab] = []

@export_group("End")
@export var ends: Array[WeightedPrefab] = []

@export_group("Borders")
@export var borders: Array[WeightedPrefab] = []

# =========================
# INTERNAL DATA
# =========================
var grid := []
var room_centers := []

func _ready():
	generate_map = true


# =========================
# TOOL BUTTONS
# =========================
func _set_generate(value: bool) -> void:
	if value:
		generate()
		generate_map = false


func _set_clear(value: bool) -> void:
	if Engine.is_editor_hint() and value:
		clear()
		clear_map = false

# =========================
# GENERATION
# =========================
func generate() -> void:
	clear()
	init_grid()
	generate_rooms()
	build_all()
	build_border()

func init_grid() -> void:
	grid.clear()
	room_centers.clear()
	for z in range(height):
		var row := []
		for x in range(width):
			row.append(0)
		grid.append(row)

# =========================
# ROOMS
# =========================
func generate_rooms() -> void:
	var attempts := room_count * 5

	while room_centers.size() < room_count and attempts > 0:
		attempts -= 1

		var w := randi_range(min_room_size, max_room_size)
		var h := randi_range(min_room_size, max_room_size)
		var x := randi_range(1, width - w - 1)
		var z := randi_range(1, height - h - 1)

		if can_place_room(x, z, w, h):
			place_room(x, z, w, h)
			room_centers.append(Vector2i(x + w / 2, z + h / 2))

	connect_rooms()

func can_place_room(x:int, z:int, w:int, h:int) -> bool:
	for dz in range(-1, h + 1):
		for dx in range(-1, w + 1):
			if grid[z + dz][x + dx] != 0:
				return false
	return true

func place_room(x:int, z:int, w:int, h:int) -> void:
	for dz in range(h):
		for dx in range(w):
			grid[z + dz][x + dx] = 2

# =========================
# HALLWAYS
# =========================
func connect_rooms() -> void:
	for i in range(room_centers.size() - 1):
		dig_corridor(room_centers[i], room_centers[i + 1])

func dig_corridor(a:Vector2i, b:Vector2i) -> void:
	var x := a.x
	var z := a.y

	while x != b.x:
		grid[z][x] = 1
		x += sign(b.x - x)

	while z != b.y:
		grid[z][x] = 1
		z += sign(b.y - z)

	grid[z][x] = 1

# =========================
# BUILD
# =========================
func build_all() -> void:
	for z in range(height):
		for x in range(width):
			var pos := Vector3(x * cell_size, 0, z * cell_size)

			if grid[z][x] == 1 or grid[z][x] == 2:
				spawn(pick_weighted(floors), pos)

			if grid[z][x] == 2:
				spawn(pick_weighted(room_items), pos)

			if grid[z][x] == 0 and has_floor_neighbor(x, z):
				spawn(pick_weighted(fillers), pos)

	build_start_end()

func has_floor_neighbor(x:int, z:int) -> bool:
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var nx: int = x + dx
			var nz: int = z + dz
			if nx >= 0 and nz >= 0 and nx < width and nz < height:
				if grid[nz][nx] > 0:
					return true
	return false

func build_start_end() -> void:
	if room_centers.is_empty():
		return

	var start_pos := grid_to_world(room_centers[0])
	var end_pos := grid_to_world(room_centers[-1])

	spawn(pick_weighted(starts), start_pos)
	spawn(pick_weighted(ends), end_pos)

	if player:
		player.global_position = start_pos + Vector3(0, cell_size * 0.5, 0)

func build_border() -> void:
	var scene := pick_weighted(borders)
	if scene == null:
		return

	var border := scene.instantiate()
	border.scale = Vector3(width * cell_size, cell_size, height * cell_size)
	border.position = Vector3(
		(width * cell_size) / 2.0 - cell_size / 2.0,
		-cell_size / 2.0,
		(height * cell_size) / 2.0 - cell_size / 2.0
	)
	add_child(border)
	border.owner = get_tree().edited_scene_root

# =========================
# HELPERS
# =========================
func pick_weighted(prefabs: Array[WeightedPrefab]) -> PackedScene:
	if prefabs.is_empty():
		return null

	var total := 0.0
	for p in prefabs:
		if p and p.scene:
			total += max(p.weight, 0.0)

	if total <= 0.0:
		return prefabs.pick_random().scene

	var r := randf() * total
	var acc := 0.0

	for p in prefabs:
		if not p or not p.scene:
			continue
		acc += max(p.weight, 0.0)
		if r <= acc:
			return p.scene

	return prefabs[-1].scene

func grid_to_world(p:Vector2i) -> Vector3:
	return Vector3(p.x * cell_size, 0, p.y * cell_size)

func spawn(scene: PackedScene, pos: Vector3) -> Node3D:
	if scene == null:
		return null

	var n := scene.instantiate()
	n.position = pos
	add_child(n)
	n.owner = get_tree().edited_scene_root
	return n

# =========================
# CLEAR
# =========================
func clear() -> void:
	for c in get_children():
		c.queue_free()
