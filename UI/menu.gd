extends Control

@onready var settingsPanel: Panel = $Settings
@onready var creditsPanel: Panel = $Credits


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	TransitionBlink.transition()
	await TransitionBlink.transition_finished
	get_tree().change_scene_to_file("res://Scenes/Outside/outside_scene.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	settingsPanel.show()

func _on_close_settings_pressed() -> void:
	settingsPanel.hide()

func _on_close_credits_pressed() -> void:
	creditsPanel.hide()

func _on_credits_pressed() -> void:
	creditsPanel.show()
