extends Node3D
class_name SurvivorGroup

signal evacuated

@export var exit_distance_x: float = 16.0

func evacuate() -> void:
	# Animação curta de fuga/saída pelo percurso liberado
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + exit_distance_x, 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a" if "modulate" in self else "scale", Vector3.ZERO, 0.4)
	await tween.finished
	emit_signal("evacuated")
	visible = false

