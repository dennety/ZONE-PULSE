extends CanvasLayer

signal wire_puzzle_completed
signal panel_puzzle_completed
signal puzzle_opened
signal puzzle_closed

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectiveLabel
@onready var hint_label: Label = $MarginContainer/VBoxContainer/HintLabel
@onready var capture_alert: Label = $CenterContainer/CaptureAlert
@onready var prompt_label: Label = $BottomContainer/PromptLabel

@onready var wire_puzzle: Control = $WirePuzzle
@onready var panel_puzzle: Control = $PanelPuzzle

func _ready() -> void:
	update_health(3, 3)
	if capture_alert:
		capture_alert.visible = false
	if prompt_label:
		prompt_label.visible = false
		
	if wire_puzzle:
		if wire_puzzle.has_signal("puzzle_completed"):
			wire_puzzle.puzzle_completed.connect(_on_wire_completed)
		if wire_puzzle.has_signal("puzzle_cancelled"):
			wire_puzzle.puzzle_cancelled.connect(_on_puzzle_closed)
		
	if panel_puzzle:
		if panel_puzzle.has_signal("puzzle_completed"):
			panel_puzzle.puzzle_completed.connect(_on_panel_completed)
		if panel_puzzle.has_signal("puzzle_cancelled"):
			panel_puzzle.puzzle_cancelled.connect(_on_puzzle_closed)

func update_health(current_hp: int, max_hp: int) -> void:
	if health_label:
		var bars = ""
		for i in range(max_hp):
			bars += "■ " if i < current_hp else "□ "
		health_label.text = "PULSO // LIA HP: " + bars + " (%d/%d)" % [current_hp, max_hp]

func update_objective(new_text: String) -> void:
	if objective_label:
		objective_label.text = "OBJETIVO // " + new_text

func set_prompt(visible_state: bool, prompt_text: String) -> void:
	if prompt_label:
		prompt_label.visible = visible_state
		prompt_label.text = prompt_text

func on_capture_state_changed(is_captured: bool, pulses_remaining: int) -> void:
	if capture_alert:
		capture_alert.visible = is_captured
		if is_captured:
			capture_alert.text = "⚠️ PRESA NA REDE! DISPARE PARA ROMPER!\n(Pulsos restantes: %d)" % pulses_remaining

func open_wire_puzzle() -> void:
	if wire_puzzle and wire_puzzle.has_method("open_puzzle"):
		wire_puzzle.open_puzzle()
		emit_signal("puzzle_opened")

func open_panel_puzzle() -> void:
	if panel_puzzle and panel_puzzle.has_method("open_puzzle"):
		panel_puzzle.open_puzzle()
		emit_signal("puzzle_opened")

func _on_wire_completed() -> void:
	emit_signal("wire_puzzle_completed")
	emit_signal("puzzle_closed")

func _on_panel_completed() -> void:
	emit_signal("panel_puzzle_completed")
	emit_signal("puzzle_closed")

func _on_puzzle_closed() -> void:
	emit_signal("puzzle_closed")
