extends Node
class_name DialogueController

signal dialogue_message(speaker: String, text: String)

var played_events: Dictionary = {}

var dialogues: Dictionary = {
	"drone_encounter": [
		{"speaker": "Lia", "text": "Esse aí veio entregar problema?"},
		{"speaker": "Nilo [Rádio]", "text": "E sem opção de cancelar."}
	],
	"net_warning": [
		{"speaker": "Nilo [Rádio]", "text": "Cuidado com a rede elétrica!"},
		{"speaker": "Lia", "text": "Vi! Não estou procurando emprego de peixe."}
	],
	"drone_down": [
		{"speaker": "Lia", "text": "Pouso aprovado. Quase!"}
	],
	"wires_connected": [
		{"speaker": "Lia", "text": "Pronto. Agora a energia vai para o lugar certo."},
		{"speaker": "Nilo [Rádio]", "text": "Uma novidade por aqui."}
	],
	"panel_error": [
		{"speaker": "Lia", "text": "Era um teste."},
		{"speaker": "Nilo [Rádio]", "text": "Claro. Do botão errado."}
	],
	"shelter_opened": [
		{"speaker": "Nilo [Rádio]", "text": "Caminho livre!"},
		{"speaker": "Lia", "text": "Finalmente uma porta que coopera."}
	],
	"survivors_free": [
		{"speaker": "Sobrevivente", "text": "Achamos que ninguém vinha..."},
		{"speaker": "Lia", "text": "Vamos tirar vocês daqui. Sigam a rota segura!"}
	]
}

func trigger_event(event_id: String) -> void:
	if played_events.has(event_id):
		return
	if not dialogues.has(event_id):
		return
		
	played_events[event_id] = true
	var lines = dialogues[event_id] as Array
	_play_lines(lines)

func _play_lines(lines: Array) -> void:
	for line in lines:
		emit_signal("dialogue_message", line["speaker"], line["text"])
		await get_tree().create_timer(3.2).timeout
