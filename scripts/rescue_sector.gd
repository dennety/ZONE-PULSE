extends Node3D

signal objective_updated(new_objective: String)
signal interaction_prompt(visible: bool, text: String)
signal request_open_wire_puzzle
signal request_open_panel_puzzle
signal sector_completed

enum Phase {
	ELIMINATE_GUARDS,
	RESTORE_WIRES,
	HACK_PANEL,
	COMPLETED
}

var current_phase: Phase = Phase.ELIMINATE_GUARDS
var remaining_guards: int = 0

@onready var wire_interactable: Area3D = $WireBoxInteractable
@onready var panel_interactable: Area3D = $PanelInteractable
@onready var locked_door: Node3D = $LockedDoor
@onready var survivors: Node3D = $SurvivorGroup
@onready var wire_box_light: OmniLight3D = $WireBox/OmniLight3D
@onready var panel_light: OmniLight3D = $ControlPanel/OmniLight3D

func _ready() -> void:
	# Contagem inicial dos guardas filhos
	remaining_guards = 0
	for child in get_children():
		if child.has_signal("defeated"):
			remaining_guards += 1
			child.defeated.connect(_on_guard_defeated)
		elif child.has_signal("drone_destroyed"):
			remaining_guards += 1
			child.drone_destroyed.connect(_on_guard_defeated)

	# Configura as áreas de interação
	if wire_interactable:
		if wire_interactable.has_method("set_active"):
			wire_interactable.set_active(false)
		wire_interactable.prompt_text = "[E] Conectar Fios de Manutenção"
		if wire_interactable.has_signal("prompt_visibility_changed"):
			wire_interactable.prompt_visibility_changed.connect(_on_prompt_changed)
		if wire_interactable.has_signal("interacted"):
			wire_interactable.interacted.connect(_on_wire_interacted)

	if panel_interactable:
		if panel_interactable.has_method("set_active"):
			panel_interactable.set_active(false)
		panel_interactable.prompt_text = "[E] Hackear Painel do Abrigo 07"
		if panel_interactable.has_signal("prompt_visibility_changed"):
			panel_interactable.prompt_visibility_changed.connect(_on_prompt_changed)
		if panel_interactable.has_signal("interacted"):
			panel_interactable.interacted.connect(_on_panel_interacted)

	emit_signal("objective_updated", "Abrigo 07: Neutralize os guardas restantes (%d)" % remaining_guards)

func _on_guard_defeated(_enemy) -> void:
	remaining_guards = max(0, remaining_guards - 1)
	if remaining_guards > 0:
		emit_signal("objective_updated", "Abrigo 07: Neutralize os guardas restantes (%d)" % remaining_guards)
	else:
		start_wire_phase()

func start_wire_phase() -> void:
	current_phase = Phase.RESTORE_WIRES
	emit_signal("objective_updated", "Abrigo 07: Restabeleça a conexão de energia na caixa de manutenção")
	if wire_interactable and wire_interactable.has_method("set_active"):
		wire_interactable.set_active(true)
	if wire_box_light:
		wire_box_light.light_color = Color(1.0, 0.8, 0.2)

func _on_wire_interacted() -> void:
	if current_phase == Phase.RESTORE_WIRES:
		emit_signal("request_open_wire_puzzle")

func on_wire_puzzle_completed() -> void:
	if current_phase != Phase.RESTORE_WIRES:
		return
	if wire_interactable and wire_interactable.has_method("set_active"):
		wire_interactable.set_active(false)
	if wire_box_light:
		wire_box_light.light_color = Color(0.2, 1.0, 0.4)
	
	start_panel_phase()

func start_panel_phase() -> void:
	current_phase = Phase.HACK_PANEL
	emit_signal("objective_updated", "Abrigo 07: Insira a sequência de bypass no painel de segurança")
	if panel_interactable and panel_interactable.has_method("set_active"):
		panel_interactable.set_active(true)
	if panel_light:
		panel_light.light_color = Color(0.2, 0.9, 1.0)

func _on_panel_interacted() -> void:
	if current_phase == Phase.HACK_PANEL:
		emit_signal("request_open_panel_puzzle")

func on_panel_puzzle_completed() -> void:
	if current_phase != Phase.HACK_PANEL:
		return
	current_phase = Phase.COMPLETED
	if panel_interactable and panel_interactable.has_method("set_active"):
		panel_interactable.set_active(false)
	if panel_light:
		panel_light.light_color = Color(0.2, 1.0, 0.4)
		
	emit_signal("objective_updated", "Abrigo 07: Porta liberada! Sobreviventes a salvo!")
	
	# Destranca e abre a porta
	if locked_door and locked_door.has_method("open"):
		locked_door.open()
		
	# Sobreviventes evacuam
	if survivors and survivors.has_method("evacuate"):
		survivors.evacuate()
		
	emit_signal("sector_completed")

func _on_prompt_changed(visible_state: bool, prompt_text: String) -> void:
	emit_signal("interaction_prompt", visible_state, prompt_text)
