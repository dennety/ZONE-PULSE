extends Camera3D

@export var target: Node3D
@export var smooth_speed: float = 6.0
@export var offset: Vector3 = Vector3(0, 2.5, 12.0)

func _physics_process(delta: float) -> void:
	if not target:
		return
	var target_x = target.global_position.x + offset.x
	var target_y = target.global_position.y + offset.y
	# Movimento suave acompanhando Lia no plano X/Y mantendo profundidade fixa
	global_position.x = lerp(global_position.x, target_x, smooth_speed * delta)
	global_position.y = lerp(global_position.y, target_y, smooth_speed * delta)
	global_position.z = offset.z

