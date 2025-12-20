extends Node3D

@export var enemy_scenes : Array[PackedScene]
@export var dist : float

@onready var enemy_ui = [
	$CanvasLayer/GridContainer/EnemyUi,
	$CanvasLayer/GridContainer/HBoxContainer/EnemyUi2,
	$CanvasLayer/GridContainer/EnemyUi4,
	$CanvasLayer/GridContainer/HBoxContainer/EnemyUi3
]

var enemies : Array[Entity]

var queue : Array[int]
var curr := 0

var last_target := 0

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
	
	update_ui(0)
	
	queue.insert(randi_range(0, queue.size()), -1)
	print(queue)
	
	battle_loop()

func update_ui(target : int):
	if target == -1:
		target = last_target
	else:
		last_target = target
	for i in range(4):
		if enemies[i]:
			#enemy_ui[(-target + i + 4) % 4].visible = true
			enemy_ui[(-target + i + 4) % 4].modulate.a = 1.0
			enemy_ui[(-target + i + 4) % 4].update(enemies[i])
		else:
			#enemy_ui[(-target + i + 4) % 4].visible = false
			enemy_ui[(-target + i + 4) % 4].modulate.a = 0.0

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
		
		update_ui(-1)
		
		curr = (curr + 1) % queue.size()
		
		var cond := true
		for q in queue:
			cond = cond && q == -1
		
		if cond:
			break
