extends CharacterBody3D
class_name PatrolBot

signal defeated(bot: PatrolBot)

@export var speed: float = 3.2
@export var max_health: int = 2
@export var damage: int = 1

var current_health: int = 2
var direction: float = 1.0 # 1 = Direita, -1 = Esquerda
var gravity: float = 24.0

@onready var mesh_instance: MeshInstance3D = $Visual/MeshInstance3D
@onready var floor_detector: RayCast3D = $FloorDetector
@onready var hitbox_area: Area3D = $HitboxArea

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	if hitbox_area:
		hitbox_area.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	global_position.z = 0.0

	# Aplica gravidade básica
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Inversão ao atingir borda da plataforma ou parede
	if is_on_wall() or (is_on_floor() and not floor_detector.is_colliding()):
		direction *= -1.0
		# Atualiza a posição do sensor de chão à frente
		floor_detector.position.x = 0.5 * direction

	velocity.x = direction * speed
	velocity.z = 0.0
	move_and_slide()

	# Aplica dano contínuo caso o jogador permaneça em contato
	if is_on_floor():
		for body in hitbox_area.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage)

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

func take_damage(amount: int) -> void:
	current_health -= amount
	flash_feedback()
	
	if current_health <= 0:
		emit_signal("defeated", self)
		queue_free()

func flash_feedback() -> void:
	if mesh_instance:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.1, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.3, 0.0, 1.0)
		mat.emission_energy_multiplier = 2.5
		mesh_instance.set_surface_override_material(0, mat)
		
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(mesh_instance):
				mesh_instance.set_surface_override_material(0, null)
		)
