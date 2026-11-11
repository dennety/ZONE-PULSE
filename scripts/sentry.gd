extends StaticBody3D
class_name Sentry

signal defeated(sentry: Sentry)

@export var max_health: int = 2
@export var shot_cooldown: float = 3.2
@export var warning_duration: float = 1.2
@export var projectile_scene: PackedScene = preload("res://scenes/combat/enemy_projectile.tscn")

var current_health: int = 2
var aim_direction: float = -1.0 # -1.0 = Esquerda, 1.0 = Direita
var is_charging: bool = false

@onready var muzzle: Marker3D = $Muzzle
@onready var warning_light: OmniLight3D = $WarningLight
@onready var laser_mesh: MeshInstance3D = $LaserGuide
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	global_position.z = 0.0
	warning_light.visible = false
	laser_mesh.visible = false
	shoot_timer.timeout.connect(_on_cycle_timer)
	shoot_timer.start(shot_cooldown)

func _physics_process(_delta: float) -> void:
	global_position.z = 0.0
	
	# Detecta a direção da Lia no eixo X
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0] as Node3D
		if p:
			aim_direction = -1.0 if p.global_position.x < global_position.x else 1.0
			muzzle.position.x = 0.6 * aim_direction
			laser_mesh.position.x = (laser_mesh.mesh.get("size").x / 2.0) * aim_direction
			laser_mesh.rotation.y = 0.0 if aim_direction > 0 else PI

	if is_charging:
		warning_light.visible = int(Time.get_ticks_msec() / 100) % 2 == 0

func _on_cycle_timer() -> void:
	# Fase de aviso prévio
	is_charging = true
	laser_mesh.visible = true
	warning_light.visible = true
	
	await get_tree().create_timer(warning_duration).timeout
	if not is_instance_valid(self):
		return
		
	# Disparo horizontal
	is_charging = false
	laser_mesh.visible = false
	warning_light.visible = false
	fire_projectile()
	
	shoot_timer.start(shot_cooldown)

func fire_projectile() -> void:
	if projectile_scene:
		var proj := projectile_scene.instantiate() as Node3D
		get_parent().add_child(proj)
		proj.global_position = muzzle.global_position
		if "direction" in proj:
			proj.direction = aim_direction

func take_damage(amount: int) -> void:
	current_health -= amount
	flash_feedback()
	if current_health <= 0:
		emit_signal("defeated", self)
		queue_free()

func flash_feedback() -> void:
	if mesh_instance:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.1)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.3, 0.0)
		mat.emission_energy_multiplier = 2.5
		mesh_instance.set_surface_override_material(0, mat)
		get_tree().create_timer(0.12).timeout.connect(func():
			if is_instance_valid(mesh_instance):
				mesh_instance.set_surface_override_material(0, null)
		)
