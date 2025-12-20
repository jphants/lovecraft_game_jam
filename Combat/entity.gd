@abstract class_name Entity
extends Node3D

@export var health : int
@export var attacks : Array[Attack]

@abstract func get_attack() -> Attack
@abstract func get_target(entities : Array[Entity]) -> Entity
