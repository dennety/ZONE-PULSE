extends CanvasLayer
class_name HUD

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var hint_label: Label = $MarginContainer/VBoxContainer/HintLabel

func _ready() -> void:
	update_health(3, 3)

func update_health(current_hp: int, max_hp: int) -> void:
	if health_label:
		var bars = ""
		for i in range(max_hp):
			bars += "■ " if i < current_hp else "□ "
		health_label.text = "PULSO // LIA HP: " + bars + " (%d/%d)" % [current_hp, max_hp]
