extends Control
class_name WirePuzzle

signal puzzle_completed
signal puzzle_cancelled

var selected_source: String = ""
var connected_pairs: Dictionary = {}
var target_pairs: Dictionary = {
	"PWR": "PWR",
	"DATA": "DATA",
	"GND": "GND"
}

@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var btn_close: Button = $Panel/BtnClose

@onready var src_pwr: Button = $Panel/HBoxContainer/SourcesVBox/BtnSrcPWR
@onready var src_data: Button = $Panel/HBoxContainer/SourcesVBox/BtnSrcDATA
@onready var src_gnd: Button = $Panel/HBoxContainer/SourcesVBox/BtnSrcGND

@onready var dst_data: Button = $Panel/HBoxContainer/DestinationsVBox/BtnDstDATA
@onready var dst_gnd: Button = $Panel/HBoxContainer/DestinationsVBox/BtnDstGND
@onready var dst_pwr: Button = $Panel/HBoxContainer/DestinationsVBox/BtnDstPWR

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(_on_cancel)
	
	src_pwr.pressed.connect(func(): _select_source("PWR", src_pwr))
	src_data.pressed.connect(func(): _select_source("DATA", src_data))
	src_gnd.pressed.connect(func(): _select_source("GND", src_gnd))
	
	dst_data.pressed.connect(func(): _connect_destination("DATA", dst_data))
	dst_gnd.pressed.connect(func(): _connect_destination("GND", dst_gnd))
	dst_pwr.pressed.connect(func(): _connect_destination("PWR", dst_pwr))

func open_puzzle() -> void:
	visible = true
	selected_source = ""
	connected_pairs.clear()
	reset_buttons()
	status_label.text = "Selecione uma Origem e conecte ao Destino correspondente."

func reset_buttons() -> void:
	for btn in [src_pwr, src_data, src_gnd, dst_data, dst_gnd, dst_pwr]:
		btn.disabled = false
		btn.modulate = Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_on_cancel()

func _select_source(type: String, btn: Button) -> void:
	if connected_pairs.has(type):
		return
	selected_source = type
	for b in [src_pwr, src_data, src_gnd]:
		if not connected_pairs.has(b.get_meta("type", "")):
			b.modulate = Color.WHITE
	btn.modulate = Color(1.0, 0.9, 0.3)
	status_label.text = "Origem selecionada: [%s]. Agora clique no terminal correspondente." % type

func _connect_destination(type: String, dst_btn: Button) -> void:
	if selected_source == "":
		status_label.text = "Selecione primeiro um terminal de Origem à esquerda!"
		return
	if connected_pairs.has(selected_source) or connected_pairs.values().has(type):
		return

	if target_pairs[selected_source] == type:
		# Conexão correta!
		connected_pairs[selected_source] = type
		dst_btn.modulate = Color(0.2, 1.0, 0.4)
		dst_btn.disabled = true
		var src_btn := get_source_button(selected_source)
		if src_btn:
			src_btn.modulate = Color(0.2, 1.0, 0.4)
			src_btn.disabled = true
		selected_source = ""
		status_label.text = "Terminal conectado com sucesso! (%d/3)" % connected_pairs.size()
		
		if connected_pairs.size() >= 3:
			status_label.text = "⚡ Conexão restabelecida! Painel de controle energizado!"
			await get_tree().create_timer(1.0).timeout
			visible = false
			emit_signal("puzzle_completed")
	else:
		# Incompatível
		status_label.text = "⚠️ Incompatível! Verifique as etiquetas e símbolos correspondentes."
		dst_btn.modulate = Color(1.0, 0.3, 0.3)
		get_tree().create_timer(0.6).timeout.connect(func():
			if not connected_pairs.values().has(type):
				dst_btn.modulate = Color.WHITE
		)

func get_source_button(type: String) -> Button:
	match type:
		"PWR": return src_pwr
		"DATA": return src_data
		"GND": return src_gnd
	return null

func _on_cancel() -> void:
	visible = false
	emit_signal("puzzle_cancelled")
