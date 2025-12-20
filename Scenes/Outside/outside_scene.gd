extends Node3D

@onready var player := $Player
@onready var ui := $PlayerUI

const OPENING_DIALOGUE = preload("uid://vdqqnaf8hxo2")

func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
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
	DialogueManager.show_dialogue_balloon(OPENING_DIALOGUE)
	
