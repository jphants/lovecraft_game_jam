@abstract class_name Attack
extends Resource

@export var animation : String
var affects : int
var name : String

@abstract func execute(caster : Entity, target : Entity)
