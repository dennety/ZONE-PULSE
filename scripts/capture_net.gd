extends Area3D
class_name CaptureNet

@export var speed: float = 11.0
@export var lifetime: float = 3.5

var velocity_dir: Vector3 = Vector3(-1, -0.3, 0).normalized()

func _ready() -> void:
	global_position.z = 0.0
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup_target(target_pos: Vector3) -> void:
	velocity_dir = (target_pos - global_position).normalized()
	velocity_dir.z = 0.0

func _physics_process(delta: float) -> void:
	global_position += velocity_dir * speed * delta
	global_position.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("apply_capture"):
		body.apply_capture()
		queue_free()
	elif not body.is_in_group("enemies"):
		queue_free()

