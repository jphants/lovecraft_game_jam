extends CanvasLayer

@onready var up: ColorRect = $Up
@onready var bottom: ColorRect = $Bottom
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal transition_finished

func _ready() -> void:
	up.visible = false
	bottom.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)

func transition() -> void:
	up.visible = true
	bottom.visible = true
	animation_player.play("close_eyes")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "close_eyes":
		# 👁️ OJOS CERRADOS → AHÍ CAMBIAMOS ESCENA
		transition_finished.emit()
		animation_player.play("open_eyes")
	elif anim_name == "open_eyes":
		up.visible = false
		bottom.visible = false
