extends Area3D
class_name InteractableArea

signal interacted
signal prompt_visibility_changed(visible: bool, prompt_text: String)

@export var prompt_text: String = "[E] Interagir"
@export var is_active: bool = true

var player_inside: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detecta Player (Layer 2)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if is_active and player_inside and Input.is_action_just_pressed("interact"):
		emit_signal("interacted")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if is_active:
			emit_signal("prompt_visibility_changed", true, prompt_text)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		emit_signal("prompt_visibility_changed", false, "")

func set_active(active: bool) -> void:
	is_active = active
	if player_inside:
		emit_signal("prompt_visibility_changed", is_active, prompt_text if is_active else "")

