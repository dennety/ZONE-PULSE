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

@onready var boss_container: VBoxContainer = $MarginContainer/VBoxContainer/BossContainer
@onready var boss_name_label: Label = $MarginContainer/VBoxContainer/BossContainer/BossNameLabel
@onready var boss_health_bar: ProgressBar = $MarginContainer/VBoxContainer/BossContainer/BossProgressBar

@onready var victory_panel: Control = $VictoryPanel
@onready var btn_restart_victory: Button = $VictoryPanel/Panel/BtnRestart

@onready var dialogue_box: PanelContainer = $TopRightContainer/DialogueBox
@onready var speaker_label: Label = $TopRightContainer/DialogueBox/MarginContainer/VBoxContainer/SpeakerLabel
@onready var message_label: Label = $TopRightContainer/DialogueBox/MarginContainer/VBoxContainer/MessageLabel

@onready var wire_puzzle: Control = $WirePuzzle
@onready var panel_puzzle: Control = $PanelPuzzle

func _ready() -> void:
	update_health(3, 3)
	if capture_alert:
		capture_alert.visible = false
	if prompt_label:
		prompt_label.visible = false
	if dialogue_box:
		dialogue_box.visible = false
	if boss_container:
		boss_container.visible = false
	if victory_panel:
		victory_panel.visible = false
		if btn_restart_victory:
			btn_restart_victory.pressed.connect(func(): get_tree().reload_current_scene())
		
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

func show_boss_bar(visible_state: bool) -> void:
	if boss_container:
		boss_container.visible = visible_state

func update_boss_health(current_hp: int, max_hp: int) -> void:
	if boss_container:
		boss_container.visible = true
	if boss_health_bar:
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = current_hp
	if boss_name_label:
		boss_name_label.text = "CHEFE // UNIDADE B-04 [SISTEMA DE BOMBEAMENTO] - %d/%d" % [current_hp, max_hp]

func show_victory() -> void:
	if boss_container:
		boss_container.visible = false
	if victory_panel:
		victory_panel.visible = true

func on_capture_state_changed(is_captured: bool, pulses_remaining: int) -> void:
	if capture_alert:
		capture_alert.visible = is_captured
		if is_captured:
			capture_alert.text = "⚠️ PRESA NA REDE! DISPARE PARA ROMPER!\n(Pulsos restantes: %d)" % pulses_remaining

func show_dialogue(speaker: String, text: String) -> void:
	if not dialogue_box:
		return
	dialogue_box.visible = true
	speaker_label.text = speaker
	if speaker.begins_with("Lia"):
		speaker_label.set("theme_override_colors/font_color", Color(0.18, 0.9, 1.0))
	elif speaker.begins_with("Nilo"):
		speaker_label.set("theme_override_colors/font_color", Color(1.0, 0.65, 0.1))
	else:
		speaker_label.set("theme_override_colors/font_color", Color(0.3, 1.0, 0.5))
	
	message_label.text = "“" + text + "”"
	
	var current_time := Time.get_ticks_msec()
	dialogue_box.set_meta("timestamp", current_time)
	get_tree().create_timer(3.2).timeout.connect(func():
		if is_instance_valid(dialogue_box) and dialogue_box.get_meta("timestamp", 0) == current_time:
			dialogue_box.visible = false
	)

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
