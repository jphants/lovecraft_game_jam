extends Control

@export_group("References")
@export var map_generator: Node
@export var player: CharacterBody3D

@export_group("Minimap")
@export var tile_scale := 4        # tamaño visual de cada celda
@export var reveal_radius := 1     # radio de descubrimiento

var grid := []
var discovered := []

var width := 0
var height := 0
var cell_size := 1.0

var image: Image
var texture: ImageTexture

@onready var tex_rect := $TextureRect

# =========================
# SETUP
# =========================
func _ready():
	if map_generator == null:
		push_error("Minimap: map_generator no asignado")
		return

	grid = map_generator.grid
	width = map_generator.width
	height = map_generator.height
	cell_size = map_generator.cell_size

	init_discovered()
	create_texture()

# =========================
# INIT
# =========================
func init_discovered():
	for z in range(height):
		var row := []
		for x in range(width):
			row.append(false)
		discovered.append(row)

func create_texture():
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)

	texture = ImageTexture.create_from_image(image)
	tex_rect.texture = texture
	tex_rect.custom_minimum_size = Vector2(
		width * tile_scale,
		height * tile_scale
	)
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE

# =========================
# UPDATE
# =========================
func _process(_delta):
	if player == null:
		return

	var gp := world_to_grid(player.global_position)
	reveal(gp)
	redraw(gp)

# =========================
# LOGIC
# =========================
func world_to_grid(pos: Vector3) -> Vector2i:
	return Vector2i(
		int(pos.x / cell_size),
		int(pos.z / cell_size)
	)

func reveal(center: Vector2i):
	for dz in range(-reveal_radius, reveal_radius + 1):
		for dx in range(-reveal_radius, reveal_radius + 1):
			var x := center.x + dx
			var z := center.y + dz

			if x >= 0 and z >= 0 and x < width and z < height:
				discovered[z][x] = true

# =========================
# DRAW
# =========================
func redraw(player_cell: Vector2i):
	for z in range(height):
		for x in range(width):
			if not discovered[z][x]:
				image.set_pixel(x, z, Color.BLACK)
			else:
				match grid[z][x]:
					0: image.set_pixel(x, z, Color(0, 0, 0))
					1: image.set_pixel(x, z, Color(0.6, 0.6, 0.6))
					2: image.set_pixel(x, z, Color(1, 1, 1))

	# jugador
	if player_cell.x >= 0 and player_cell.y >= 0 \
	and player_cell.x < width and player_cell.y < height:
		image.set_pixel(player_cell.x, player_cell.y, Color.RED)

	texture.update(image)
