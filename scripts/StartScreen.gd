extends Control

# StartScreen.gd - Main menu screen for NPC management and navigation
# Manages 8 NPCSlot instances and handles user interactions

@onready var npc_slots_container = $VBoxContainer/MarginContainer/NPCSlotsContainer
@onready var statistics_button = $VBoxContainer/NavigationContainer/StatisticsButton
@onready var dialog = $Dialog

var npc_slot_scenes: Array = []
var pending_delete_index: int = -1

func _ready():
	print("StartScreen: Initializing...")
	
	# Connect to GameManager signals
	GameManager.processing_started.connect(_on_processing_started)
	GameManager.processing_finished.connect(_on_processing_finished)
	GameManager.npc_data_changed.connect(_on_npc_data_changed)
	
	# Connect navigation button
	statistics_button.pressed.connect(_on_statistics_pressed)
	
	# Connect dialog signals
	dialog.dialog_confirmed.connect(_on_dialog_confirmed)
	dialog.dialog_cancelled.connect(_on_dialog_cancelled)
	
	# Initialize NPC slots
	_initialize_npc_slots()
	
	# Initial data load
	_refresh_all_slots()

func _initialize_npc_slots():
	"""Instantiate 8 NPCSlot scenes and add them to the grid."""
	var npc_slot_scene = preload("res://scenes/NPCSlot.tscn")
	
	for i in range(GameManager.MAX_NPC_SLOTS):
		var slot_instance = npc_slot_scene.instantiate()
		npc_slots_container.add_child(slot_instance)
		npc_slot_scenes.append(slot_instance)
		
		# Initialize and connect signals
		slot_instance.initialize(i)
		slot_instance.generate_requested.connect(_on_generate_requested)
		slot_instance.play_requested.connect(_on_play_requested)
		slot_instance.delete_requested.connect(_on_delete_requested)

func _refresh_all_slots():
	"""Refresh the display of all NPC slots."""
	for slot in npc_slot_scenes:
		slot.refresh_display()

func _on_npc_data_changed():
	"""Handle NPC data changes from GameManager."""
	_refresh_all_slots()

func _on_generate_requested(slot_index: int):
	"""Handle Generate button press from an NPCSlot."""
	print("StartScreen: Generate requested for slot ", slot_index)
	GameManager.generate_npc(slot_index)
	
	# Set the specific slot to generating state
	npc_slot_scenes[slot_index].set_processing_state(true)

func _on_play_requested(slot_index: int):
	"""Handle Play button press from an NPCSlot."""
	print("StartScreen: Play requested for slot ", slot_index)
	GameManager.start_match(slot_index)

func _on_delete_requested(slot_index: int):
	"""Handle Delete button press from an NPCSlot."""
	print("StartScreen: Delete requested for slot ", slot_index)
	
	var npc_data = GameManager.get_npc_data(slot_index)
	var npc_name = npc_data.get("name", "Unknown")
	
	pending_delete_index = slot_index
	dialog.show_confirmation(
		"Delete NPC",
		"Are you sure you want to delete " + npc_name + "?\nThis will also delete all statistics for this NPC.",
		slot_index
	)

func _on_dialog_confirmed(_data: Variant):
	"""Handle dialog confirmation."""
	if pending_delete_index >= 0:
		print("StartScreen: Confirmed deletion of slot ", pending_delete_index)
		GameManager.delete_npc(pending_delete_index)
		pending_delete_index = -1

func _on_dialog_cancelled():
	"""Handle dialog cancellation."""
	print("StartScreen: Deletion cancelled")
	pending_delete_index = -1

func _on_statistics_pressed():
	"""Handle Statistics button press."""
	print("StartScreen: Navigating to Statistics screen")
	GameManager.change_scene("res://scenes/StatisticsScreen.tscn")

func _on_processing_started():
	"""Disable all interactive elements during processing."""
	print("StartScreen: Processing started, disabling UI")
	_set_all_interactive(false)
	statistics_button.disabled = true

func _on_processing_finished():
	"""Re-enable all interactive elements after processing."""
	print("StartScreen: Processing finished, enabling UI")
	_set_all_interactive(true)
	statistics_button.disabled = false
	
	# Reset any slots that were in generating state
	for slot in npc_slot_scenes:
		slot.set_processing_state(false)

func _set_all_interactive(interactive: bool):
	"""Set all slots to interactive or non-interactive."""
	for slot in npc_slot_scenes:
		slot.set_interactive(interactive)
