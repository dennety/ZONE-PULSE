extends Area3D
class_name PulseSwitch

signal activated

@export var is_activated: bool = false
@export var target_door_or_platform: Node3D

@onready var light: OmniLight3D = $OmniLight3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	collision_layer = 32 # Layer 6: DanoInteracao (bit 6 = 32)
	collision_mask = 8  # Layer 4: ProjeteisJogador (bit 4 = 8)
	area_entered.connect(_on_area_entered)
	update_visuals()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_projectiles") or area.name.to_lower().contains("projectile"):
		trigger_switch()

func take_damage(_amount: int) -> void:
	trigger_switch()

func trigger_switch() -> void:
	if is_activated:
		return
	is_activated = true
	emit_signal("activated")
	update_visuals()
	
	if target_door_or_platform:
		if target_door_or_platform.has_method("open"):
			target_door_or_platform.open()
		elif target_door_or_platform.has_method("activate"):
			target_door_or_platform.activate()

func update_visuals() -> void:
	if light:
		light.light_color = Color(0.18, 0.9, 1.0) if is_activated else Color(1.0, 0.2, 0.1)
	if mesh_instance:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.9, 1.0) if is_activated else Color(1.0, 0.2, 0.1)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 2.0
		mesh_instance.set_surface_override_material(0, mat)
