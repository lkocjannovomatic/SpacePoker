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
@onready var animation_player = $GeneratingStateContainer/AnimationPlayer

var slot_index: int = -1
var slot_is_processing: bool = false

func _ready():
	# Connect button signals
	generate_button.pressed.connect(_on_generate_pressed)
	play_button.pressed.connect(_on_play_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	
	# Initialize to empty state
	_set_state("empty")

func initialize(index: int):
	"""Initialize the slot with its index."""
	slot_index = index
	refresh_display()

func refresh_display():
	"""Update the display based on current GameManager data."""
	if slot_index < 0:
		return
	
	# GameManager is an autoload singleton, safe to access directly
	var npc_data = GameManager.get_npc_data(slot_index)
	
	if slot_is_processing:
		_set_state("generating")
	elif GameManager.is_slot_empty(slot_index):
		_set_state("empty")
	else:
		_set_state("occupied")
		npc_name_label.text = npc_data["name"]

func _set_state(state: String):
	"""Set the visual state of the slot."""
	empty_state.visible = (state == "empty")
	generating_state.visible = (state == "generating")
	occupied_state.visible = (state == "occupied")

func set_processing_state(processing: bool):
	"""Set whether the slot is in a processing state."""
	slot_is_processing = processing
	refresh_display()

func set_interactive(interactive: bool):
	"""Enable or disable interactive elements."""
	generate_button.disabled = not interactive
	play_button.disabled = not interactive
	delete_button.disabled = not interactive

func _on_generate_pressed():
	"""Handle Generate button press."""
	generate_requested.emit(slot_index)

func _on_play_pressed():
	"""Handle Play button press."""
	play_requested.emit(slot_index)

func _on_delete_pressed():
	"""Handle Delete button press."""
	delete_requested.emit(slot_index)
