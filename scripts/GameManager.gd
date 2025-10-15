extends Node

# GameManager.gd - Global Autoload Singleton
# Manages game state, NPC data persistence, and scene transitions
# Note: NPC generation logic is handled by NPCGenerator

# Signals for UI state management
signal processing_started
signal processing_finished
signal npc_data_changed

# Constants
const MAX_NPC_SLOTS = 8
const SAVE_DIR = "saves/"
const STARTING_CREDITS = 1000
const SMALL_BLIND = 10
const BIG_BLIND = 20

# NPC Data Structure
var npc_slots: Array = []  # Array of 8 dictionaries

# Current game state
var current_npc_index: int = -1  # Index of NPC being played against
var player_stats: Dictionary = {
	"total_wins": 0,
	"total_losses": 0
}

# NPC Generator reference
var _npc_generator: Node = null

func _ready():
	print("GameManager: Initializing...")
	_setup_npc_generator()
	_ensure_save_directory()
	_initialize_npc_slots()
	load_all_data()

func _setup_npc_generator():
	"""Initialize the NPC generator and connect signals."""
	_npc_generator = Node.new()
	_npc_generator.set_script(load("res://scripts/NPCGenerator.gd"))
	add_child(_npc_generator)
	
	_npc_generator.generation_completed.connect(_on_npc_generation_completed)
	_npc_generator.generation_failed.connect(_on_npc_generation_failed)

func _ensure_save_directory():
	"""Create the saves directory if it doesn't exist."""
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(SAVE_DIR):
		var result = dir.make_dir(SAVE_DIR)
		if result == OK:
			print("GameManager: Created saves directory at res://", SAVE_DIR)
		else:
			print("GameManager Error: Failed to create saves directory. Error: ", result)

func _initialize_npc_slots():
	"""Initialize the NPC slots array with 8 empty slots."""
	npc_slots.clear()
	for i in range(MAX_NPC_SLOTS):
		npc_slots.append(_create_empty_slot())

func _create_empty_slot() -> Dictionary:
	"""Create an empty NPC slot structure."""
	return {
		"name": "",
		"backstory": "",
		"aggression": 0.5,
		"bluffing": 0.5,
		"risk_aversion": 0.5,
		"wins_against": 0,
		"losses_against": 0,
		"conversation_history": ""
	}

func load_all_data():
	"""Load all NPC data and player stats from JSON files."""
	print("GameManager: Loading data from saves...")
	
	# Load each NPC slot
	for i in range(MAX_NPC_SLOTS):
		var file_path = "res://" + SAVE_DIR + "slot_" + str(i) + ".json"
		var data = _load_json_file(file_path)
		
		if data != null:
			npc_slots[i] = data
		else:
			# If file doesn't exist, keep the empty slot (no file creation)
			print("GameManager: Slot ", i, " is empty (no save file)")
	
	# Load player stats
	var stats_path = "res://" + SAVE_DIR + "player_stats.json"
	var stats_data = _load_json_file(stats_path)
	
	if stats_data != null:
		player_stats = stats_data
	else:
		# If file doesn't exist, use default stats (no file creation yet)
		print("GameManager: Using default player stats (no save file)")
	
	npc_data_changed.emit()
	print("GameManager: Data loaded successfully")

func _load_json_file(file_path: String) -> Variant:
	"""Load and parse a JSON file. Returns null if file doesn't exist or is invalid."""
	if not FileAccess.file_exists(file_path):
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("GameManager Error: Could not open file: ", file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("GameManager Error: JSON parse error in ", file_path, " at line ", json.get_error_line(), ": ", json.get_error_message())
		return null
	
	return json.data

func save_npc_slot(slot_index: int):
	"""Save a specific NPC slot to its JSON file."""
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		print("GameManager Error: Invalid slot index: ", slot_index)
		return
	
	var file_path = "res://" + SAVE_DIR + "slot_" + str(slot_index) + ".json"
	_save_json_file(file_path, npc_slots[slot_index])

func save_player_stats():
	"""Save player statistics to JSON file."""
	var stats_path = "res://" + SAVE_DIR + "player_stats.json"
	_save_json_file(stats_path, player_stats)

func _save_json_file(file_path: String, data: Variant):
	"""Save data to a JSON file with consistent field ordering."""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("GameManager Error: Could not open file for writing: ", file_path)
		return
	
	var json_string = ""
	
	# For NPC data, manually construct JSON with proper field order
	if data is Dictionary and data.has("name"):
		json_string = "{\n"
		json_string += '\t"name": ' + JSON.stringify(data.get("name", "")) + ",\n"
		json_string += '\t"backstory": ' + JSON.stringify(data.get("backstory", "")) + ",\n"
		json_string += '\t"aggression": ' + str(data.get("aggression", 0.5)) + ",\n"
		json_string += '\t"bluffing": ' + str(data.get("bluffing", 0.5)) + ",\n"
		json_string += '\t"risk_aversion": ' + str(data.get("risk_aversion", 0.5)) + ",\n"
		json_string += '\t"wins_against": ' + str(data.get("wins_against", 0)) + ",\n"
		json_string += '\t"losses_against": ' + str(data.get("losses_against", 0)) + ",\n"
		json_string += '\t"conversation_history": ' + JSON.stringify(data.get("conversation_history", "")) + "\n"
		json_string += "}"
	else:
		# For other data (like player stats), use standard JSON
		json_string = JSON.stringify(data, "\t")
	
	file.store_string(json_string)
	file.close()
	print("GameManager: Saved data to ", file_path)

func is_slot_empty(slot_index: int) -> bool:
	"""Check if a slot is empty (identified by empty name field)."""
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		return true
	
	return npc_slots[slot_index]["name"] == ""

func get_npc_data(slot_index: int) -> Dictionary:
	"""Get NPC data for a specific slot."""
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		return {}
	
	return npc_slots[slot_index]

func generate_npc(slot_index: int):
	"""
	Initiate NPC generation for a specific slot.
	Delegates to NPCGenerator for actual generation logic.
	"""
	# Defensive check: prevent generation on occupied slot
	if not is_slot_empty(slot_index):
		print("GameManager Warning: Attempted to generate NPC in occupied slot ", slot_index)
		return
	
	print("GameManager: Starting NPC generation for slot ", slot_index)
	processing_started.emit()
	
	# Store the slot index for tracking
	current_npc_index = slot_index
	
	# Delegate to NPCGenerator
	_npc_generator.generate_npc(slot_index, _create_empty_slot())

func _on_npc_generation_completed(slot_index: int, npc_data: Dictionary):
	"""Handle successful NPC generation from NPCGenerator."""
	print("GameManager: NPC generation completed for slot ", slot_index)
	
	# Store the generated NPC data
	npc_slots[slot_index] = npc_data
	save_npc_slot(slot_index)
	
	# Reset tracking
	current_npc_index = -1
	
	# Notify UI
	processing_finished.emit()
	npc_data_changed.emit()

func _on_npc_generation_failed(error_message: String):
	"""Handle NPC generation failure from NPCGenerator."""
	print("GameManager: NPC generation failed - ", error_message)
	
	# Reset tracking
	current_npc_index = -1
	
	# Notify UI
	processing_finished.emit()
	# TODO: Show error dialog to user

func delete_npc(slot_index: int):
	"""Delete an NPC by resetting their slot to empty state and removing the save file."""
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		print("GameManager Error: Invalid slot index for deletion: ", slot_index)
		return
	
	if is_slot_empty(slot_index):
		print("GameManager Warning: Attempted to delete already empty slot ", slot_index)
		return
	
	print("GameManager: Deleting NPC in slot ", slot_index)
	
	npc_slots[slot_index] = _create_empty_slot()
	
	# Delete the save file instead of saving an empty slot
	_delete_save_file(slot_index)
	
	npc_data_changed.emit()

func _delete_save_file(slot_index: int):
	"""Delete the save file for a specific NPC slot."""
	var file_path = "res://" + SAVE_DIR + "slot_" + str(slot_index) + ".json"
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("res://" + SAVE_DIR)
		if dir:
			var result = dir.remove("slot_" + str(slot_index) + ".json")
			if result == OK:
				print("GameManager: Deleted save file for slot ", slot_index)
			else:
				print("GameManager Error: Failed to delete save file for slot ", slot_index, ". Error: ", result)
		else:
			print("GameManager Error: Could not open saves directory for file deletion")
	else:
		print("GameManager: No save file to delete for slot ", slot_index)

func start_match(slot_index: int):
	"""Start a poker match against the NPC in the specified slot."""
	if is_slot_empty(slot_index):
		print("GameManager Error: Cannot start match with empty slot ", slot_index)
		return
	
	current_npc_index = slot_index
	print("GameManager: Starting match against ", npc_slots[slot_index]["name"])
	
	# TODO: Initialize match state (credits, blinds, etc.)
	
	change_scene("res://scenes/GameView.tscn")

func record_match_result(player_won: bool):
	"""Record the result of a completed match."""
	if current_npc_index < 0:
		print("GameManager Error: No active match to record")
		return
	
	if player_won:
		player_stats["total_wins"] += 1
		npc_slots[current_npc_index]["losses_against"] += 1
	else:
		player_stats["total_losses"] += 1
		npc_slots[current_npc_index]["wins_against"] += 1
	
	save_player_stats()
	save_npc_slot(current_npc_index)
	npc_data_changed.emit()
	
	print("GameManager: Match result recorded")

func change_scene(scene_path: String):
	"""Change to a different scene."""
	print("GameManager: Changing scene to ", scene_path)
	get_tree().change_scene_to_file(scene_path)

func return_to_start_screen():
	"""Return to the start screen."""
	current_npc_index = -1
	change_scene("res://scenes/StartScreen.tscn")
