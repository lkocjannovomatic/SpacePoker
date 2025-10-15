extends Node

# GameManager.gd - Global Autoload Singleton
# Manages game state, NPC data persistence, LLM generation requests, and scene transitions

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

func _ready():
	print("GameManager: Initializing...")
	_ensure_save_directory()
	_initialize_npc_slots()
	load_all_data()

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
			# If file doesn't exist, create it with empty data
			save_npc_slot(i)
	
	# Load player stats
	var stats_path = "res://" + SAVE_DIR + "player_stats.json"
	var stats_data = _load_json_file(stats_path)
	
	if stats_data != null:
		player_stats = stats_data
	else:
		save_player_stats()
	
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
	"""Save data to a JSON file."""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("GameManager Error: Could not open file for writing: ", file_path)
		return
	
	var json_string = JSON.stringify(data, "\t")
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
	This function triggers the LLM to generate a backstory and personality.
	"""
	# Defensive check: prevent generation on occupied slot
	if not is_slot_empty(slot_index):
		print("GameManager Warning: Attempted to generate NPC in occupied slot ", slot_index)
		return
	
	print("GameManager: Starting NPC generation for slot ", slot_index)
	processing_started.emit()
	
	# Connect to LLM signals
	if not LLMClient.response_received.is_connected(_on_npc_generation_complete):
		LLMClient.response_received.connect(_on_npc_generation_complete)
	
	if not LLMClient.error_occurred.is_connected(_on_npc_generation_error):
		LLMClient.error_occurred.connect(_on_npc_generation_error)
	
	# Store the slot index for the callback
	current_npc_index = slot_index
	
	# Create prompt for NPC generation
	var prompt = _create_npc_generation_prompt()
	
	# Send to LLM
	var success = LLMClient.send_prompt(prompt)
	
	if not success:
		_on_npc_generation_error("Failed to initiate LLM request")

func _create_npc_generation_prompt() -> String:
	"""Create a structured prompt for generating an NPC character."""
	return """Generate a unique poker player character with a brief backstory (2-3 sentences).
After the backstory, provide personality ratings on a scale of 0.0 to 1.0 for these traits:
- Aggression: How often they bet/raise vs. check/call
- Bluffing: How likely they are to bluff
- Risk Aversion: How conservative they are with their chips

Format your response exactly like this:
NAME: [Character name]
BACKSTORY: [2-3 sentence backstory]
AGGRESSION: [0.0-1.0]
BLUFFING: [0.0-1.0]
RISK_AVERSION: [0.0-1.0]

Example:
NAME: Captain Sarah Chen
BACKSTORY: A former space freighter pilot who learned poker during long hauls between star systems. She's seen fortunes won and lost at trading posts across the galaxy. Now retired, she plays for the thrill of reading people.
AGGRESSION: 0.7
BLUFFING: 0.6
RISK_AVERSION: 0.4"""

func _on_npc_generation_complete(response_text: String):
	"""Handle successful NPC generation from LLM."""
	print("GameManager: NPC generation complete. Parsing response...")
	
	# Disconnect signals
	if LLMClient.response_received.is_connected(_on_npc_generation_complete):
		LLMClient.response_received.disconnect(_on_npc_generation_complete)
	if LLMClient.error_occurred.is_connected(_on_npc_generation_error):
		LLMClient.error_occurred.disconnect(_on_npc_generation_error)
	
	# Parse the LLM response
	var npc_data = _parse_npc_response(response_text)
	
	if npc_data.is_empty():
		_on_npc_generation_error("Failed to parse NPC data from LLM response")
		return
	
	# Store the generated NPC
	npc_slots[current_npc_index] = npc_data
	save_npc_slot(current_npc_index)
	
	current_npc_index = -1
	processing_finished.emit()
	npc_data_changed.emit()
	
	print("GameManager: NPC successfully generated and saved")

func _parse_npc_response(response: String) -> Dictionary:
	"""Parse the LLM response to extract NPC data."""
	var data = _create_empty_slot()
	
	# Simple regex-based parsing
	var name_regex = RegEx.new()
	name_regex.compile("NAME:\\s*(.+)")
	var name_match = name_regex.search(response)
	if name_match:
		data["name"] = name_match.get_string(1).strip_edges()
	
	var backstory_regex = RegEx.new()
	backstory_regex.compile("BACKSTORY:\\s*(.+?)(?=AGGRESSION:|$)")
	var backstory_match = backstory_regex.search(response)
	if backstory_match:
		data["backstory"] = backstory_match.get_string(1).strip_edges()
	
	var aggression_regex = RegEx.new()
	aggression_regex.compile("AGGRESSION:\\s*([0-9.]+)")
	var aggression_match = aggression_regex.search(response)
	if aggression_match:
		data["aggression"] = float(aggression_match.get_string(1))
	
	var bluffing_regex = RegEx.new()
	bluffing_regex.compile("BLUFFING:\\s*([0-9.]+)")
	var bluffing_match = bluffing_regex.search(response)
	if bluffing_match:
		data["bluffing"] = float(bluffing_match.get_string(1))
	
	var risk_regex = RegEx.new()
	risk_regex.compile("RISK_AVERSION:\\s*([0-9.]+)")
	var risk_match = risk_regex.search(response)
	if risk_match:
		data["risk_aversion"] = float(risk_match.get_string(1))
	
	# Validate that we at least got a name
	if data["name"] == "":
		print("GameManager Error: Could not parse name from LLM response")
		return {}
	
	return data

func _on_npc_generation_error(error_message: String):
	"""Handle NPC generation errors."""
	print("GameManager Error: NPC generation failed - ", error_message)
	
	# Disconnect signals
	if LLMClient.response_received.is_connected(_on_npc_generation_complete):
		LLMClient.response_received.disconnect(_on_npc_generation_complete)
	if LLMClient.error_occurred.is_connected(_on_npc_generation_error):
		LLMClient.error_occurred.disconnect(_on_npc_generation_error)
	
	current_npc_index = -1
	processing_finished.emit()
	
	# TODO: Show error dialog to user

func delete_npc(slot_index: int):
	"""Delete an NPC by resetting their slot to empty state."""
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		print("GameManager Error: Invalid slot index for deletion: ", slot_index)
		return
	
	if is_slot_empty(slot_index):
		print("GameManager Warning: Attempted to delete already empty slot ", slot_index)
		return
	
	print("GameManager: Deleting NPC in slot ", slot_index)
	
	npc_slots[slot_index] = _create_empty_slot()
	save_npc_slot(slot_index)
	npc_data_changed.emit()

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
