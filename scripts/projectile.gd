extends Area3D

@export var speed: float = 22.0
@export var damage: int = 1
@export var lifetime: float = 1.8

var direction: float = 1.0 # 1.0 = Direita, -1.0 = Esquerda

func _ready() -> void:
	global_position.z = 0.0
	# Destrói automaticamente após expirar o tempo de vida
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	global_position.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
