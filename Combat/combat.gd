extends Node3D

@export var enemy_scenes : Array[PackedScene]
@export var dist : float

var enemies : Array[Entity]

var queue : Array[int]
var curr := 0

@onready var player := $Player

func _ready() -> void:
	for i in range(4):
		if i < enemy_scenes.size() and enemy_scenes[i]:
			enemies.append(enemy_scenes[i].instantiate())
			if i % 2 == 0:
				enemies[i].position.z = -dist if i == 0 else dist
			else:
				enemies[i].position.x = -dist if i == 1 else dist
			add_child(enemies[i])
			queue.append(i)
		else:
			enemies.append(null)
	queue.insert(randi_range(0, queue.size()), -1)
	print(queue)
	
	battle_loop()

func display(lines : Array[String]):
	var txt := ""
	for l in lines:
		txt += l
		txt += '\n'
	var resource = DialogueManager.create_resource_from_text(txt)
	DialogueManager.show_dialogue_balloon(resource)
	await DialogueManager.dialogue_ended
	

func battle_loop():
	await display(["Battle Start"])
	
	while true:
		var e : Entity = player if queue[curr] == -1 else enemies[queue[curr]]
		var all = [[player] as Array[Entity], enemies]
		
		var a := await e.get_attack()
		if a:
			var t : Entity = await e.get_target(all[int(queue[curr] == -1) ^ int(a.affects)])
			if t:
				var txt = str(e.name) + " used " + str(a.name) + " on " + str(t.name)
				await display([txt])
				a.execute(e, t)
			else:
				await display(["No target..."])
		else:
			await display([str(e.name) + " did nothing..."])
		
		curr = (curr + 1) % queue.size()
		
		var cond := true
		for q in queue:
			cond = cond && q == -1
		
		if cond:
			break
