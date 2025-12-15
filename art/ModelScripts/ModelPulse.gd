extends Node3D

var bIsGrowing = false
var bIsPaused = false
var MinScale = 1.0
var MaxScale = 1.2
var Progress = 0
var Rate = 1

var TimerRef : Timer

func _ready() -> void:
	TimerRef = Timer.new()
	add_child(TimerRef)
	TimerRef.one_shot = true
	TimerRef.timeout.connect(OnTimeout)
	MinScale = scale * .95
	MaxScale = scale * 1.0
	TimerRef.wait_time = randf_range(.1, 1.4)
	Rate = randf_range(.3, .8)
	
func OnTimeout():
	bIsPaused = false
	Progress = 0
	TimerRef.wait_time = randf_range(.1, 1.4)
	
func _process(delta: float) -> void:
	if bIsPaused:
		return
	Progress += delta * Rate
	if bIsGrowing:
		scale = lerp(MinScale, MaxScale, Progress)
		if Progress >= 1:
			bIsPaused = true
			TimerRef.start()
			bIsGrowing = false
	else:
		scale = lerp(MaxScale, MinScale, Progress)
		if Progress >= 1:
			bIsPaused = true
			TimerRef.start()
			bIsGrowing = true
