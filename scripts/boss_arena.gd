extends Node3D
class_name BossArena

signal boss_fight_started
signal boss_health_updated(current_hp: int, max_hp: int)
signal boss_defeated_signal
signal objective_updated(text: String)

var is_fight_active: bool = false

@onready var boss: Node3D = $Boss
@onready var entry_door: Node3D = $EntryDoor
@onready var exit_door: Node3D = $ExitDoor
@onready var trigger_area: Area3D = $ArenaTrigger
@onready var floor_hazard: Area3D = $FloorHazardArea
@onready var floor_warning_mesh: MeshInstance3D = $FloorHazardArea/FloorWarningMesh
@onready var floor_light: OmniLight3D = $FloorHazardArea/FloorLight

func _ready() -> void:
	trigger_area.body_entered.connect(_on_trigger_entered)
	floor_hazard.body_entered.connect(_on_floor_hazard_entered)
	floor_hazard.monitoring = false
	floor_warning_mesh.visible = false
	floor_light.visible = false
	
	if boss:
		if boss.has_signal("boss_health_changed"):
			boss.boss_health_changed.connect(_on_boss_health_changed)
		if boss.has_signal("boss_defeated"):
			boss.boss_defeated.connect(_on_boss_defeated)
		if boss.has_signal("floor_hazard_state"):
			boss.floor_hazard_state.connect(_on_floor_hazard_state)

func _physics_process(_delta: float) -> void:
	if floor_hazard.monitoring:
		for body in floor_hazard.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(1)

func _on_trigger_entered(body: Node3D) -> void:
	if not is_fight_active and body.is_in_group("player"):
		start_boss_fight()

func start_boss_fight() -> void:
	is_fight_active = true
	trigger_area.set_deferred("monitoring", false)
	
	# Fecha o portão de entrada para bloquear o recuo
	if entry_door and entry_door.has_method("close"):
		entry_door.close()
	elif entry_door:
		entry_door.position.y = 0.0 # Baixa a porta
		
	emit_signal("objective_updated", "Arena Principal: Destrua a Unidade de Bombeamento B-04!")
	emit_signal("boss_fight_started")
	
	if boss and boss.has_method("activate_boss"):
		boss.activate_boss()

func _on_boss_health_changed(current_hp: int, max_hp: int) -> void:
	emit_signal("boss_health_updated", current_hp, max_hp)

func _on_floor_hazard_state(state_name: String) -> void:
	match state_name:
		"safe":
			floor_hazard.monitoring = false
			floor_warning_mesh.visible = false
			floor_light.visible = false
		"warning":
			floor_hazard.monitoring = false
			floor_warning_mesh.visible = true
			floor_light.visible = true
			floor_light.light_color = Color(1.0, 0.8, 0.1)
		"active":
			floor_hazard.monitoring = true
			floor_warning_mesh.visible = true
			floor_light.visible = true
			floor_light.light_color = Color(0.2, 0.9, 1.0)

func _on_floor_hazard_entered(body: Node3D) -> void:
	if floor_hazard.monitoring and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)

func _on_boss_defeated() -> void:
	emit_signal("objective_updated", "Vitória! B-04 neutralizada e o bairro está a salvo!")
	emit_signal("boss_defeated_signal")
	
	_on_floor_hazard_state("safe")
	
	# Abre a porta final de vitória
	if exit_door and exit_door.has_method("open"):
		exit_door.open()
