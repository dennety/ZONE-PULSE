extends StaticBody3D

@export var max_health: int = 3
var current_health: int = 3

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	print("Alvo recebeu dano! Vida restante: ", current_health)
	
	# Feedback visual de impacto (piscar branco/laranja)
	if mesh_instance and mesh_instance.get_active_material(0):
		var mat = mesh_instance.get_active_material(0).duplicate() as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(1.0, 0.4, 0.1, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.1, 1.0)
			mat.emission_energy_multiplier = 2.0
			mesh_instance.set_surface_override_material(0, mat)
			
			get_tree().create_timer(0.1).timeout.connect(func():
				mesh_instance.set_surface_override_material(0, null)
			)

	if current_health <= 0:
		print("Alvo destruído! Reiniciando alvo para novos testes...")
		current_health = max_health

