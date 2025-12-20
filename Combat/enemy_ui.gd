extends PanelContainer

func update(enemy : Entity):
	$MarginContainer/VBoxContainer/HBoxContainer/Label.text = enemy.name
	$MarginContainer/VBoxContainer/ProgressBar.value = enemy.health
	$MarginContainer/VBoxContainer/ProgressBar.max_value = enemy.max_health
