extends PanelContainer

# NPCSlot.gd - Reusable component for displaying NPC slot states
# Manages three visual states: Empty, Generating, and Occupied

signal generate_requested(slot_index: int)
signal play_requested(slot_index: int)
signal delete_requested(slot_index: int)

@onready var empty_state = $EmptyStateContainer
@onready var generating_state = $GeneratingStateContainer
@onready var occupied_state = $OccupiedStateContainer
@onready var npc_name_label = $OccupiedStateContainer/VBoxContainer/NPCNameLabel
@onready var generate_button = $EmptyStateContainer/GenerateButton
@onready var play_button = $OccupiedStateContainer/VBoxContainer/ButtonsContainer/PlayButton
@onready var delete_button = $OccupiedStateContainer/VBoxContainer/ButtonsContainer/DeleteButton

var slot_index: int = -1
var slot_is_processing: bool = false

func _ready():
	generate_button.pressed.connect(_on_generate_pressed)
	play_button.pressed.connect(_on_play_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	
	_set_state("empty")

func initialize(index: int):
	slot_index = index
	refresh_display()

func refresh_display():
	if slot_index < 0:
		return
	
	var npc_data = GameManager.get_npc_data(slot_index)
	
	if slot_is_processing:
		_set_state("generating")
	elif GameManager.is_slot_empty(slot_index):
		_set_state("empty")
	else:
		_set_state("occupied")
		npc_name_label.text = npc_data["name"]

func _set_state(state: String):
	empty_state.visible = (state == "empty")
	generating_state.visible = (state == "generating")
	occupied_state.visible = (state == "occupied")

func set_processing_state(processing: bool):
	slot_is_processing = processing
	refresh_display()

func set_interactive(interactive: bool):
	generate_button.disabled = not interactive
	play_button.disabled = not interactive
	delete_button.disabled = not interactive

func _on_generate_pressed():
	generate_requested.emit(slot_index)

func _on_play_pressed():
	play_requested.emit(slot_index)

func _on_delete_pressed():
	delete_requested.emit(slot_index)
