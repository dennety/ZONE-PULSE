extends CharacterBody3D
class_name CaptureDrone

signal drone_fell
signal drone_destroyed(drone: CaptureDrone)

enum State {
	PATROL,
	PREPARE,
	SHOOT_NET,
	FALLING,
	VULNERABLE,
	RECOVERING
}

@export var patrol_min_x: float = 4.0
@export var patrol_max_x: float = 12.0
@export var patrol_height: float = 4.5
@export var attack_height: float = 0.9 # Altura na linha do tiro horizontal da Lia
@export var floor_y: float = 0.4
@export var fly_speed: float = 3.0
@export var net_scene: PackedScene = preload("res://scenes/combat/capture_net.tscn")

var state: State = State.PATROL
var move_direction: float = 1.0
var flight_stability: int = 2
var core_health: int = 2
var target_player: Node3D = null

@onready var visual: Node3D = $Visual
@onready var core_mesh: MeshInstance3D = $Visual/CoreMesh
@onready var alert_light: OmniLight3D = $Visual/AlertLight
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	add_to_group("enemies")
	global_position.y = patrol_height
	global_position.z = 0.0
	state_timer.timeout.connect(_on_state_timer_timeout)
	# Inicia o ciclo de patrulha
	state_timer.start(2.5)

func _physics_process(delta: float) -> void:
	global_position.z = 0.0
	
	match state:
		State.PATROL:
			global_position.x += move_direction * fly_speed * delta
			global_position.y = move_toward(global_position.y, patrol_height, 3.0 * delta)
			if global_position.x >= patrol_max_x:
				move_direction = -1.0
			elif global_position.x <= patrol_min_x:
				move_direction = 1.0
				
		State.PREPARE:
			# Desce até a linha de tiro da Lia
			global_position.y = move_toward(global_position.y, attack_height, 4.0 * delta)
			# Efeito de alerta piscando
			if alert_light:
				alert_light.visible = int(Time.get_ticks_msec() / 150) % 2 == 0
				
		State.FALLING:
			global_position.y = move_toward(global_position.y, floor_y, 10.0 * delta)
			if abs(global_position.y - floor_y) < 0.05:
				enter_vulnerable_state()
				
		State.RECOVERING:
			global_position.y = move_toward(global_position.y, patrol_height, 3.5 * delta)
			if abs(global_position.y - patrol_height) < 0.1:
				state = State.PATROL
				flight_stability = 2
				state_timer.start(3.0)

func _on_state_timer_timeout() -> void:
	match state:
		State.PATROL:
			start_prepare()
		State.PREPARE:
			execute_shoot_net()
		State.VULNERABLE:
			start_recovery()

func start_prepare() -> void:
	state = State.PREPARE
	flight_stability = 2
	if alert_light:
		alert_light.visible = true
	# Tempo para Lia reagir e atirar nele antes da rede
	state_timer.start(1.8)

func execute_shoot_net() -> void:
	if state != State.PREPARE:
		return
		
	state = State.SHOOT_NET
	if alert_light:
		alert_light.visible = false
		
	# Dispara a rede em direção ao jogador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		
	if net_scene:
		var net := net_scene.instantiate() as Node3D
		get_parent().add_child(net)
		net.global_position = global_position
		if target_player:
			if net.has_method("setup_target"):
				net.setup_target(target_player.global_position)
	
	# Após lançar a rede, se não caiu, sobe de volta
	state_timer.start(0.4)
	await state_timer.timeout
	if state == State.SHOOT_NET:
		state = State.RECOVERING

func take_damage(amount: int) -> void:
	# Se for atingido durante preparação ou ataque: perde sustentação
	if state == State.PREPARE or state == State.SHOOT_NET:
		flight_stability -= amount
		flash_visual(Color(1, 0.6, 0.1))
		if flight_stability <= 0:
			trigger_fall()
	elif state == State.VULNERABLE:
		# No chão, recebe dano real no núcleo
		core_health -= amount
		flash_visual(Color(1, 0.1, 0.1))
		if core_health <= 0:
			destroy_drone()

func trigger_fall() -> void:
	state = State.FALLING
	state_timer.stop()
	if alert_light:
		alert_light.visible = false
	emit_signal("drone_fell")

func enter_vulnerable_state() -> void:
	state = State.VULNERABLE
	# Expõe o núcleo no chão por 4 segundos
	if core_mesh:
		core_mesh.scale = Vector3(1.4, 1.4, 1.4)
	state_timer.start(4.0)

func start_recovery() -> void:
	if state == State.VULNERABLE:
		state = State.RECOVERING
		if core_mesh:
			core_mesh.scale = Vector3.ONE

func destroy_drone() -> void:
	emit_signal("drone_destroyed", self)
	queue_free()

func flash_visual(color: Color) -> void:
	if core_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
		core_mesh.set_surface_override_material(0, mat)
		get_tree().create_timer(0.12).timeout.connect(func():
			if is_instance_valid(core_mesh):
				core_mesh.set_surface_override_material(0, null)
		)
