extends CharacterBody3D

signal health_changed(new_health: int, max_health: int)
signal player_died
signal capture_state_changed(is_captured: bool, pulses_remaining: int)

enum State {
	NORMAL,
	CAPTURED,
	INTERACTING,
	DEAD
}

@export var speed: float = 7.5
@export var jump_velocity: float = 13.0
@export var fall_gravity_multiplier: float = 1.6
@export var short_hop_multiplier: float = 2.2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var max_health: int = 3
@export var projectile_scene: PackedScene = preload("res://scenes/combat/projectile.tscn")

var state: State = State.NORMAL
var current_health: int = 3
var facing_direction: float = 1.0 # 1.0 = Direita, -1.0 = Esquerda
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_invulnerable: bool = false
var default_gravity: float = 28.0
var net_pulses_remaining: int = 0

@onready var visual_mesh: Node3D = $Visual
@onready var capture_visual: MeshInstance3D = $Visual/CaptureVisual
@onready var muzzle: Marker3D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer
@onready var invulnerable_timer: Timer = $InvulnerableTimer
@onready var capture_auto_release_timer: Timer = $CaptureAutoReleaseTimer

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

	# Movimento e pulo somente disponíveis no estado NORMAL
	if state == State.NORMAL:
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
			if visual_mesh:
				visual_mesh.rotation.y = 0.0 if facing_direction > 0 else PI
			if muzzle:
				muzzle.position.x = 0.5 * facing_direction
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
	elif state == State.CAPTURED:
		# Bloqueia movimento lateral enquanto capturada
		velocity.x = move_toward(velocity.x, 0.0, speed * 12.0 * delta)

	# Z não recebe velocidade física
	velocity.z = 0.0
	move_and_slide()

	# Disparo contínuo ou simples (disponível no estado NORMAL ou CAPTURED)
	if (state == State.NORMAL or state == State.CAPTURED) and Input.is_action_pressed("shoot") and shoot_timer.is_stopped():
		shoot()

	# Reinício rápido de teste
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func shoot() -> void:
	shoot_timer.start(0.2) # Intervalo de cadência
	
	# Se estiver capturada, cada disparo enfraquece a rede com um pulso
	if state == State.CAPTURED:
		net_pulses_remaining -= 1
		emit_signal("capture_state_changed", true, net_pulses_remaining)
		if net_pulses_remaining <= 0:
			release_capture()
	
	if projectile_scene:
		var p = projectile_scene.instantiate()
		get_parent().add_child(p)
		p.global_position = muzzle.global_position
		p.direction = facing_direction

func apply_capture() -> void:
	if state == State.CAPTURED or is_invulnerable:
		return
	
	state = State.CAPTURED
	net_pulses_remaining = 3
	if capture_visual:
		capture_visual.visible = true
	capture_auto_release_timer.start()
	emit_signal("capture_state_changed", true, net_pulses_remaining)

func release_capture() -> void:
	if state != State.CAPTURED:
		return
	state = State.NORMAL
	if capture_visual:
		capture_visual.visible = false
	capture_auto_release_timer.stop()
	start_invulnerability(1.2)
	emit_signal("capture_state_changed", false, 0)

func _on_capture_auto_release_timeout() -> void:
	if state == State.CAPTURED:
		release_capture()

func set_interacting(interacting: bool) -> void:
	if interacting:
		state = State.INTERACTING
		velocity.x = 0.0
	else:
		if state == State.INTERACTING:
			state = State.NORMAL

func take_damage(amount: int = 1) -> void:
	# Enquanto capturada ou invulnerável, Lia fica protegida de outros danos
	if is_invulnerable or state == State.CAPTURED or state == State.DEAD:
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
	state = State.DEAD
	emit_signal("player_died")
	get_tree().reload_current_scene()
