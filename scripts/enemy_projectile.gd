extends Area3D
class_name EnemyProjectile

@export var speed: float = 14.0
@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: float = -1.0 # -1.0 = Esquerda, 1.0 = Direita

func _ready() -> void:
	global_position.z = 0.0
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	global_position.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("enemies"):
		queue_free()
