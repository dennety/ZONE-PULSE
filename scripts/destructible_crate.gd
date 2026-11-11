extends StaticBody3D
class_name DestructibleCrate

signal destroyed

@export var max_health: int = 2
var current_health: int = 2

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	current_health = max_health
	global_position.z = 0.0

func take_damage(amount: int) -> void:
	current_health -= amount
	flash_feedback()
	
	if current_health <= 0:
		emit_signal("destroyed")
		# Efeito de quebra simples
		if collision_shape:
			collision_shape.disabled = true
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished
		queue_free()

func flash_feedback() -> void:
	if mesh_instance:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.7, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5, 0.1)
		mat.emission_energy_multiplier = 2.0
		mesh_instance.set_surface_override_material(0, mat)
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(mesh_instance):
				mesh_instance.set_surface_override_material(0, null)
		)

