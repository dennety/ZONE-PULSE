extends Node3D
class_name LockedDoor

signal door_opened

@export var is_open: bool = false
@export var open_height: float = 4.0

@onready var door_body: StaticBody3D = $DoorBody
@onready var collision_shape: CollisionShape3D = $DoorBody/CollisionShape3D
@onready var status_light: OmniLight3D = $StatusLight
@onready var door_mesh: MeshInstance3D = $DoorBody/MeshInstance3D

func _ready() -> void:
	update_visuals()

func open() -> void:
	if is_open:
		return
	is_open = true
	emit_signal("door_opened")
	update_visuals()
	
	# Animação suave de elevação da porta
	var tween := create_tween()
	tween.tween_property(door_body, "position:y", open_height, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	if collision_shape:
		collision_shape.disabled = true

func update_visuals() -> void:
	if status_light:
		status_light.light_color = Color(0.2, 1.0, 0.4) if is_open else Color(1.0, 0.2, 0.1)
