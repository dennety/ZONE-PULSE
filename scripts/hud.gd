extends CanvasLayer
class_name HUD

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var hint_label: Label = $MarginContainer/VBoxContainer/HintLabel
@onready var capture_alert: Label = $CenterContainer/CaptureAlert

func _ready() -> void:
	update_health(3, 3)
	if capture_alert:
		capture_alert.visible = false

func update_health(current_hp: int, max_hp: int) -> void:
	if health_label:
		var bars = ""
		for i in range(max_hp):
			bars += "■ " if i < current_hp else "□ "
		health_label.text = "PULSO // LIA HP: " + bars + " (%d/%d)" % [current_hp, max_hp]

func on_capture_state_changed(is_captured: bool, pulses_remaining: int) -> void:
	if capture_alert:
		capture_alert.visible = is_captured
		if is_captured:
			capture_alert.text = "⚠️ PRESA NA REDE! DISPARE PARA ROMPER!\n(Pulsos restantes: %d)" % pulses_remaining
