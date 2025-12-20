class_name Enemy
extends Entity

@export var frequency : Array[int]
var prob : Array[float]

func get_attack() -> Attack:
	var off = randf()
	for i in range(prob.size()):
		if prob[i] >= off:
			return attacks[i]
	return null

func get_target(entities : Array[Entity]) -> Entity:
	return null if entities.is_empty() else entities.pick_random()

func _ready() -> void:
	var tot := 0.0
	prob.resize(frequency.size())
	attacks.resize(frequency.size())
	for f in frequency:
		tot += f
	for i in range(frequency.size()):
		prob[i] = frequency[i] / tot
	for i in range(1, frequency.size()):
		prob[i] += prob[i-1]
		
	print(health, " ", max_health)
