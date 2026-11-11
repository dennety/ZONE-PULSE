extends Node

@onready var hud: CanvasLayer = $HUD
@onready var test_room: Node3D = $TestRoom

func _ready() -> void:
	if test_room:
		var player := test_room.get_node_or_null("Player")
		if player and hud:
			if player.has_signal("health_changed") and hud.has_method("update_health"):
				player.health_changed.connect(hud.update_health)
			if player.has_signal("capture_state_changed") and hud.has_method("on_capture_state_changed"):
				player.capture_state_changed.connect(hud.on_capture_state_changed)
