extends Node

@onready var hud: CanvasLayer = $HUD
@onready var test_room: Node3D = $TestRoom
@onready var dialogue_controller: Node = $DialogueController

func _ready() -> void:
	if not test_room or not hud:
		return

	# Conecta controlador de diálogos ao HUD
	if dialogue_controller and dialogue_controller.has_signal("dialogue_message"):
		dialogue_controller.dialogue_message.connect(hud.show_dialogue)

	var player := test_room.get_node_or_null("Player")
	if player:
		if player.has_signal("health_changed") and hud.has_method("update_health"):
			player.health_changed.connect(hud.update_health)
		if player.has_signal("capture_state_changed") and hud.has_method("on_capture_state_changed"):
			player.capture_state_changed.connect(func(is_captured: bool, remaining: int):
				hud.on_capture_state_changed(is_captured, remaining)
				if is_captured and dialogue_controller:
					dialogue_controller.trigger_event("net_warning")
			)
			
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
			hud.wire_puzzle_completed.connect(func():
				rescue_sector.on_wire_puzzle_completed()
				if dialogue_controller:
					dialogue_controller.trigger_event("wires_connected")
			)
		if hud.has_signal("panel_puzzle_completed"):
			hud.panel_puzzle_completed.connect(func():
				rescue_sector.on_panel_puzzle_completed()
				if dialogue_controller:
					dialogue_controller.trigger_event("shelter_opened")
			)

		# Evento de queda do drone dentro do setor
		var drone = rescue_sector.get_node_or_null("CaptureDrone")
		if drone:
			if drone.has_signal("drone_fell") and dialogue_controller:
				drone.drone_fell.connect(func(): dialogue_controller.trigger_event("drone_down"))

	# Conecta a Arena do Chefe B-04
	var boss_arena := test_room.get_node_or_null("BossArena")
	if boss_arena:
		if boss_arena.has_signal("boss_fight_started"):
			boss_arena.boss_fight_started.connect(func():
				if hud.has_method("show_boss_bar"):
					hud.show_boss_bar(true)
				if dialogue_controller:
					dialogue_controller.trigger_event("boss_encounter")
			)
		if boss_arena.has_signal("boss_health_updated") and hud.has_method("update_boss_health"):
			boss_arena.boss_health_updated.connect(hud.update_boss_health)
		if boss_arena.has_signal("objective_updated") and hud.has_method("update_objective"):
			boss_arena.objective_updated.connect(hud.update_objective)
		if boss_arena.has_signal("boss_defeated_signal"):
			boss_arena.boss_defeated_signal.connect(func():
				if hud.has_method("show_victory"):
					hud.show_victory()
				if dialogue_controller:
					dialogue_controller.trigger_event("boss_victory")
			)

	# Diálogo inicial ao iniciar a fase
	if dialogue_controller:
		get_tree().create_timer(1.2).timeout.connect(func():
			dialogue_controller.trigger_event("drone_encounter")
		)
