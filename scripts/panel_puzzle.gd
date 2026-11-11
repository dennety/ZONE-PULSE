extends Control
class_name PanelPuzzle

signal puzzle_completed
signal puzzle_cancelled

var target_sequence: Array[String] = ["ALFA", "BETA", "GAMA"]
var current_input: Array[String] = []

@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var sequence_display: Label = $Panel/VBoxContainer/SequenceDisplay
@onready var input_display: Label = $Panel/VBoxContainer/InputDisplay
@onready var btn_close: Button = $Panel/BtnClose

@onready var btn_alfa: Button = $Panel/GridContainer/BtnAlfa
@onready var btn_beta: Button = $Panel/GridContainer/BtnBeta
@onready var btn_gama: Button = $Panel/GridContainer/BtnGama
@onready var btn_delta: Button = $Panel/GridContainer/BtnDelta

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(_on_cancel)
	
	btn_alfa.pressed.connect(func(): _press_symbol("ALFA"))
	btn_beta.pressed.connect(func(): _press_symbol("BETA"))
	btn_gama.pressed.connect(func(): _press_symbol("GAMA"))
	btn_delta.pressed.connect(func(): _press_symbol("DELTA"))

func open_puzzle() -> void:
	visible = true
	current_input.clear()
	update_displays()
	status_label.text = "Digite os símbolos na ordem indicada pela sequência de bypass."
	enable_buttons(true)

func update_displays() -> void:
	sequence_display.text = "CÓDIGO DE BYPASS REQUERIDO:\n[ ▲ ALFA ]  ➔  [ ■ BETA ]  ➔  [ ◆ GAMA ]"
	
	var entered_text = ""
	for i in range(3):
		if i < current_input.size():
			entered_text += "[ %s ]  " % current_input[i]
		else:
			entered_text += "[ ___ ]  "
	input_display.text = "ENTRADA ATUAL: " + entered_text

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_on_cancel()

func _press_symbol(symbol: String) -> void:
	current_input.append(symbol)
	update_displays()
	
	var idx = current_input.size() - 1
	if current_input[idx] != target_sequence[idx]:
		status_label.text = "⚠️ Símbolo incorreto! Sequência reiniciada."
		current_input.clear()
		await get_tree().create_timer(0.5).timeout
		update_displays()
		return

	if current_input.size() == target_sequence.size():
		status_label.text = "🔓 ACESSO AUTORIZADO! DESTRAVANDO PORTA DO ABRIGO 07..."
		enable_buttons(false)
		await get_tree().create_timer(1.0).timeout
		visible = false
		emit_signal("puzzle_completed")
	else:
		status_label.text = "Símbolo correto. Continue a sequência (%d/3)..." % current_input.size()

func enable_buttons(enabled: bool) -> void:
	btn_alfa.disabled = not enabled
	btn_beta.disabled = not enabled
	btn_gama.disabled = not enabled
	btn_delta.disabled = not enabled

func _on_cancel() -> void:
	visible = false
	emit_signal("puzzle_cancelled")
