extends CanvasLayer

# =====================================================
# CONFIG
# =====================================================
const MAX_BARS := 5
const BLINK_SPEED := 0.3

@export var battery_bar_texture: Texture2D
@export var health_bar_texture: Texture2D

# =====================================================
# NODOS
# =====================================================
@onready var battery_bar_container := $Control/FlashlightBattery
@onready var health_bar_container := $Control/HealthBar
@onready var pause_panel := $Control/PauseMenu
@onready var interact_label := $Label

# =====================================================
# ESTADO UI
# =====================================================
var battery_bars: Array[TextureRect] = []
var health_bars: Array[TextureRect] = []

var blink_time := 0.0
var low_battery := false

# =====================================================
# READY
# =====================================================
func _ready() -> void:
	_setup_bars(
		battery_bar_container,
		battery_bars,
		battery_bar_texture
	)

	_setup_bars(
		health_bar_container,
		health_bars,
		health_bar_texture
	)

	pause_panel.visible = false
	interact_label.visible = false

# =====================================================
# SETUP
# =====================================================
func _setup_bars(container: Control, array: Array, texture: Texture2D) -> void:
	for i in range(MAX_BARS):
		var bar := TextureRect.new()
		bar.texture = texture
		bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bar.stretch_mode = TextureRect.STRETCH_KEEP
		container.add_child(bar)
		array.append(bar)

# =====================================================
# API PÚBLICA (LLAMADA DESDE MAIN)
# =====================================================
func update_battery(value: int) -> void:
	var bars_on : int = clamp(int(ceil(value / 20.0)), 0, MAX_BARS)
	for i in range(MAX_BARS):
		battery_bars[i].visible = i < bars_on

func update_health(value: int) -> void:
	var bars_on : int = clamp(int(ceil(value / 20.0)), 0, MAX_BARS)
	for i in range(MAX_BARS):
		health_bars[i].visible = i < bars_on

func show_pause(value: bool) -> void:
	pause_panel.visible = value

func show_interact(value: bool) -> void:
	interact_label.visible = false

# =====================================================
# EFECTOS VISUALES (SOLO UI)
# =====================================================
func update_battery_blink(delta: float, battery: int) -> void:
	low_battery = battery <= 20 and battery > 0
	if not low_battery:
		return

	blink_time += delta
	if blink_time >= BLINK_SPEED:
		blink_time = 0.0
		battery_bars[0].visible = !battery_bars[0].visible


func _on_quit_game_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
