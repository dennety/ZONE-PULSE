extends Node3D
class_name ElectricHazard

@export var safe_time: float = 2.4
@export var warning_time: float = 1.0
@export var active_time: float = 1.4

enum State { SAFE, WARNING, ACTIVE }
var state: State = State.SAFE

@onready var hazard_area: Area3D = $HazardArea
@onready var beam_mesh: MeshInstance3D = $BeamMesh
@onready var spark_light: OmniLight3D = $SparkLight
@onready var timer: Timer = $Timer

func _ready() -> void:
	hazard_area.body_entered.connect(_on_body_entered)
	timer.timeout.connect(_on_timer_timeout)
	set_safe()

func _physics_process(_delta: float) -> void:
	if state == State.WARNING:
		spark_light.visible = int(Time.get_ticks_msec() / 80) % 2 == 0
	elif state == State.ACTIVE:
		# Verifica dano contínuo enquanto Lia estiver na área
		for body in hazard_area.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(1)

func _on_timer_timeout() -> void:
	match state:
		State.SAFE:
			set_warning()
		State.WARNING:
			set_active()
		State.ACTIVE:
			set_safe()

func set_safe() -> void:
	state = State.SAFE
	hazard_area.monitoring = false
	beam_mesh.visible = false
	spark_light.visible = false
	timer.start(safe_time)

func set_warning() -> void:
	state = State.WARNING
	hazard_area.monitoring = false
	beam_mesh.visible = false
	spark_light.visible = true
	spark_light.light_color = Color(1.0, 0.8, 0.1)
	spark_light.light_energy = 2.0
	timer.start(warning_time)

func set_active() -> void:
	state = State.ACTIVE
	hazard_area.monitoring = true
	beam_mesh.visible = true
	spark_light.visible = true
	spark_light.light_color = Color(0.2, 0.8, 1.0)
	spark_light.light_energy = 4.0
	timer.start(active_time)

func _on_body_entered(body: Node3D) -> void:
	if state == State.ACTIVE and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
