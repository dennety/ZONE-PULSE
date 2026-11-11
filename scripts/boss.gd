extends StaticBody3D
class_name Boss

signal boss_health_changed(current_hp: int, max_hp: int)
signal boss_defeated
signal floor_hazard_state(state_name: String) # "safe", "warning", "active"

@export var max_health: int = 8
var current_health: int = 8

enum State {
	INACTIVE,
	VULNERABLE,
	ATTACK_PROJECTILES_TELEGRAPH,
	ATTACK_PROJECTILES,
	ATTACK_FLOOR_TELEGRAPH,
	ATTACK_FLOOR,
	DEFEATED
}

var state: State = State.INACTIVE
var next_attack: int = 1 # Alterna entre 1 e 2

@export var projectile_scene: PackedScene = preload("res://scenes/combat/enemy_projectile.tscn")

@onready var core_mesh: MeshInstance3D = $Visual/CoreMesh
@onready var muzzle_upper: Marker3D = $MuzzleUpper
@onready var muzzle_lower: Marker3D = $MuzzleLower
@onready var telegraph_light: OmniLight3D = $TelegraphLight
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	global_position.z = 0.0
	state_timer.timeout.connect(_on_state_timer_timeout)

func activate_boss() -> void:
	if state != State.INACTIVE:
		return
	state = State.VULNERABLE
	emit_signal("boss_health_changed", current_health, max_health)
	enter_vulnerable_state()

func enter_vulnerable_state() -> void:
	state = State.VULNERABLE
	telegraph_light.visible = false
	emit_signal("floor_hazard_state", "safe")
	
	# Núcleo exposto e visivelmente pulsante
	set_core_color(Color(1.0, 0.4, 0.1), 3.0)
	state_timer.start(3.5) # Fica vulnerável por 3.5s

func _on_state_timer_timeout() -> void:
	if state == State.DEFEATED or state == State.INACTIVE:
		return
		
	if state == State.VULNERABLE:
		# Escolhe o próximo ataque alternado
		if next_attack == 1:
			next_attack = 2
			start_projectiles_attack()
		else:
			next_attack = 1
			start_floor_attack()

func start_projectiles_attack() -> void:
	state = State.ATTACK_PROJECTILES_TELEGRAPH
	set_core_color(Color(0.2, 0.2, 0.2), 0.5)
	
	# Aviso prévio de mira
	telegraph_light.light_color = Color(1.0, 0.1, 0.1)
	telegraph_light.visible = true
	
	await get_tree().create_timer(1.2).timeout
	if state == State.DEFEATED: return
	
	state = State.ATTACK_PROJECTILES
	telegraph_light.visible = false
	
	# Sequência curta de 3 disparos horizontais
	for i in range(3):
		if state == State.DEFEATED: return
		fire_projectile()
		await get_tree().create_timer(0.35).timeout
		
	await get_tree().create_timer(0.6).timeout
	if state != State.DEFEATED:
		enter_vulnerable_state()

func fire_projectile() -> void:
	if projectile_scene:
		var p := projectile_scene.instantiate() as Node3D
		get_parent().add_child(p)
		p.global_position = muzzle_upper.global_position
		if "direction" in p:
			p.direction = -1.0 # Atira para a esquerda (onde Lia está)

func start_floor_attack() -> void:
	state = State.ATTACK_FLOOR_TELEGRAPH
	set_core_color(Color(0.2, 0.2, 0.2), 0.5)
	
	# Aviso prévio no chão da arena
	emit_signal("floor_hazard_state", "warning")
	telegraph_light.light_color = Color(1.0, 0.8, 0.1)
	telegraph_light.visible = true
	
	await get_tree().create_timer(1.4).timeout
	if state == State.DEFEATED: return
	
	state = State.ATTACK_FLOOR
	telegraph_light.visible = false
	emit_signal("floor_hazard_state", "active")
	
	# Descarga dura 1.8 segundos
	await get_tree().create_timer(1.8).timeout
	if state == State.DEFEATED: return
	
	emit_signal("floor_hazard_state", "safe")
	enter_vulnerable_state()

func take_damage(amount: int) -> void:
	# Só recebe dano enquanto o núcleo estiver exposto
	if state != State.VULNERABLE or state == State.DEFEATED:
		flash_shield()
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("boss_health_changed", current_health, max_health)
	flash_core_damage()
	
	if current_health <= 0:
		defeat_boss()

func defeat_boss() -> void:
	state = State.DEFEATED
	state_timer.stop()
	emit_signal("floor_hazard_state", "safe")
	emit_signal("boss_defeated")
	
	# Efeito visual de colapso da máquina
	var tween := create_tween()
	tween.tween_property(core_mesh, "scale", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_BACK)
	await tween.finished
	telegraph_light.visible = false

func set_core_color(color: Color, emission_energy: float) -> void:
	if core_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = emission_energy > 0.0
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
		core_mesh.set_surface_override_material(0, mat)

func flash_core_damage() -> void:
	set_core_color(Color.WHITE, 4.0)
	get_tree().create_timer(0.1).timeout.connect(func():
		if state == State.VULNERABLE:
			set_core_color(Color(1.0, 0.4, 0.1), 3.0)
	)

func flash_shield() -> void:
	# Feedback visual indicando que a carcaça blindada repeliu o tiro
	telegraph_light.light_color = Color(0.2, 0.8, 1.0)
	telegraph_light.visible = true
	get_tree().create_timer(0.08).timeout.connect(func():
		if state != State.ATTACK_PROJECTILES_TELEGRAPH and state != State.ATTACK_FLOOR_TELEGRAPH:
			telegraph_light.visible = false
	)
