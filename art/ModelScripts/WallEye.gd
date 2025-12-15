extends Node3D

func _ready() -> void:
	$Timer.wait_time = randf_range(.3,5)
	$WallEye/AnimationPlayer.speed_scale = randf_range(.05, .3)
	$Timer.start()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	$Timer.wait_time = randf_range(.3,3.5)
	$Timer.start()


func _on_timer_timeout() -> void:
	$WallEye/AnimationPlayer.play("Squint")
