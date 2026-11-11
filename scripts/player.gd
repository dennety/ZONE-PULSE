extends CharacterBody3D

signal health_changed(new_health: int, max_health: int)
signal player_died

@export var speed: float = 7.5
@export var jump_velocity: float = 13.0
@export var fall_gravity_multiplier: float = 1.6
@export var short_hop_multiplier: float = 2.2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var max_health: int = 3
@export var projectile_scene: PackedScene = preload("res://scenes/combat/projectile.tscn")

var current_health: int = 3
var facing_direction: float = 1.0 # 1.0 = Direita, -1.0 = Esquerda
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_invulnerable: bool = false
var default_gravity: float = 28.0

@onready var visual_mesh: Node3D = $Visual
@onready var muzzle: Marker3D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer
@onready var invulnerable_timer: Timer = $InvulnerableTimer

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta: float) -> void:
	# Trava absoluta no eixo Z (jogabilidade 2.5D estrita)
	global_position.z = 0.0

	# Tratamento do temporizador de pulo (Jump Buffer)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	# Lógica de chão e Coyote Time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
		
		# Gravidade adaptativa (queda mais rápida para sensação ágil de plataforma)
		var grav = default_gravity
		if velocity.y < 0.0:
			grav *= fall_gravity_multiplier
		elif not Input.is_action_pressed("jump"):
			# Salto com altura variável: soltar o botão cedo corta a subida
			grav *= short_hop_multiplier
		velocity.y -= grav * delta

	# Execução do Salto (se buffer ativo e coyote ativo)
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Leitura de movimento lateral no eixo X
	var input_axis := Input.get_axis("move_left", "move_right")
	if input_axis != 0.0:
		velocity.x = input_axis * speed
		facing_direction = sign(input_axis)
		# Rotaciona apenas a representação visual, sem girar o corpo físico
		if visual_mesh:
			visual_mesh.rotation.y = 0.0 if facing_direction > 0 else PI
		if muzzle:
			muzzle.position.x = 0.5 * facing_direction
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)

	# Z não recebe velocidade física
	velocity.z = 0.0

	move_and_slide()

	# Disparo contínuo ou simples
	if Input.is_action_pressed("shoot") and shoot_timer.is_stopped():
		shoot()

	# Reinício rápido de teste
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func shoot() -> void:
	shoot_timer.start(0.2) # Intervalo de cadência
	if projectile_scene:
		var p = projectile_scene.instantiate()
		get_parent().add_child(p)
		p.global_position = muzzle.global_position
		p.direction = facing_direction

func take_damage(amount: int = 1) -> void:
	if is_invulnerable:
		return
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		die()
	else:
		start_invulnerability()

func start_invulnerability(duration: float = 1.0) -> void:
	is_invulnerable = true
	invulnerable_timer.start(duration)

func _on_invulnerable_timer_timeout() -> void:
	is_invulnerable = false

func die() -> void:
	emit_signal("player_died")
	# Reinício rápido sem demora
	get_tree().reload_current_scene()
