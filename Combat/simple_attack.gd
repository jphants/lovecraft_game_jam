class_name SimpleAttack
extends Attack

@export var base_damage : int

func _init() -> void:
	name = "Simple Attack"
	affects = 0

func execute(_caster : Entity, target : Entity):
	target.health -= base_damage
	target.health = max(target.health, 0)
	print(target.health, " ", target.max_health)
