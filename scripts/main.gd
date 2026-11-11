extends Node

@onready var hud: CanvasLayer = $HUD
@onready var test_room: Node3D = $TestRoom

func _ready() -> void:
	if not test_room or not hud:
		return

	var player := test_room.get_node_or_null("Player")
	if player:
		if player.has_signal("health_changed") and hud.has_method("update_health"):
			player.health_changed.connect(hud.update_health)
		if player.has_signal("capture_state_changed") and hud.has_method("on_capture_state_changed"):
			player.capture_state_changed.connect(hud.on_capture_state_changed)
			
		# Bloqueia/libera controles de Lia durante interação com puzzles
		if hud.has_signal("puzzle_opened"):
			hud.puzzle_opened.connect(func(): player.set_interacting(true))
		if hud.has_signal("puzzle_closed"):
			hud.puzzle_closed.connect(func(): player.set_interacting(false))

	var rescue_sector := test_room.get_node_or_null("RescueSector")
	if rescue_sector:
		if rescue_sector.has_signal("objective_updated") and hud.has_method("update_objective"):
			rescue_sector.objective_updated.connect(hud.update_objective)
		if rescue_sector.has_signal("interaction_prompt") and hud.has_method("set_prompt"):
			rescue_sector.interaction_prompt.connect(hud.set_prompt)
		if rescue_sector.has_signal("request_open_wire_puzzle") and hud.has_method("open_wire_puzzle"):
			rescue_sector.request_open_wire_puzzle.connect(hud.open_wire_puzzle)
		if rescue_sector.has_signal("request_open_panel_puzzle") and hud.has_method("open_panel_puzzle"):
			rescue_sector.request_open_panel_puzzle.connect(hud.open_panel_puzzle)

		if hud.has_signal("wire_puzzle_completed"):
			hud.wire_puzzle_completed.connect(rescue_sector.on_wire_puzzle_completed)
		if hud.has_signal("panel_puzzle_completed"):
			hud.panel_puzzle_completed.connect(rescue_sector.on_panel_puzzle_completed)
