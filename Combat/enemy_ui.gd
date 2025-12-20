extends PanelContainer

func update(enemy : Entity):
	$MarginContainer/VBoxContainer/HBoxContainer/Label.text = enemy.name
	$MarginContainer/VBoxContainer/ProgressBar.max_value = enemy.max_health
	$MarginContainer/VBoxContainer/ProgressBar.value = enemy.health
