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
const PROMPTS_DIR = "prompts/"
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

# NPC generation state
var _is_generating: bool = false
var _temp_npc_data: Dictionary = {}  # Temporary storage during generation

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
	Uses JSON schema for structured output from LLM.
	"""
	# Defensive check: prevent generation on occupied slot
	if not is_slot_empty(slot_index):
		print("GameManager Warning: Attempted to generate NPC in occupied slot ", slot_index)
		return
	
	print("GameManager: Starting NPC generation for slot ", slot_index)
	processing_started.emit()
	
	# Store the slot index for the callback
	current_npc_index = slot_index
	_is_generating = true
	_temp_npc_data = _create_empty_slot()
	
	# Connect to LLM signals
	if not LLMClient.response_received.is_connected(_on_llm_response):
		LLMClient.response_received.connect(_on_llm_response)
	
	if not LLMClient.error_occurred.is_connected(_on_llm_error):
		LLMClient.error_occurred.connect(_on_llm_error)
	
	# Create prompt for NPC generation
	var prompt = _load_prompt_file("npc_generation.txt")
	
	# Define JSON schema for structured NPC output
	var json_schema = _get_npc_json_schema()
	
	# Send to LLM with JSON schema
	var success = LLMClient.send_prompt(prompt, json_schema)
	
	if not success:
		_on_generation_failed("Failed to initiate NPC generation")

func _get_npc_json_schema() -> String:
	"""
	Returns the JSON schema for NPC generation.
	This ensures the LLM outputs valid JSON matching our NPC data structure.
	"""
	var schema = {
		"type": "object",
		"properties": {
			"name": {
				"type": "string",
				"description": "Character name (e.g., Commander, Captain, Salvager, etc.)"
			},
			"backstory": {
				"type": "string",
				"description": "3-4 sentence backstory including profession, how they learned poker, defining characteristic, and current situation"
			},
			"aggression": {
				"type": "number",
				"minimum": 0.0,
				"maximum": 1.0,
				"description": "How often they bet/raise aggressively (0.0-1.0)"
			},
			"bluffing": {
				"type": "number",
				"minimum": 0.0,
				"maximum": 1.0,
				"description": "How likely they are to bluff (0.0-1.0)"
			},
			"risk_aversion": {
				"type": "number",
				"minimum": 0.0,
				"maximum": 1.0,
				"description": "How cautious they are with chips (0.0-1.0)"
			}
		},
		"required": ["name", "backstory", "aggression", "bluffing", "risk_aversion"]
	}
	
	return JSON.stringify(schema)

func _load_prompt_file(filename: String) -> String:
	"""Load a prompt file from the prompts directory."""
	var prompt_path = "res://" + PROMPTS_DIR + filename
	
	if not FileAccess.file_exists(prompt_path):
		print("GameManager Error: Prompt file not found at ", prompt_path)
		return ""
	
	var file = FileAccess.open(prompt_path, FileAccess.READ)
	if file == null:
		print("GameManager Error: Could not open prompt file: ", prompt_path)
		return ""
	
	var prompt = file.get_as_text()
	file.close()
	
	return prompt

func _on_llm_response(response_text: String):
	"""Handle LLM response for NPC generation (JSON format)."""
	print("GameManager: LLM response received, parsing JSON...")
	
	var parsed_data = _parse_npc_json_response(response_text)
	
	if parsed_data.is_empty():
		_on_generation_failed("Failed to parse NPC data from LLM JSON response")
		return
	
	# Store all parsed data
	_temp_npc_data["name"] = parsed_data["name"]
	_temp_npc_data["backstory"] = parsed_data["backstory"]
	_temp_npc_data["aggression"] = parsed_data["aggression"]
	_temp_npc_data["bluffing"] = parsed_data["bluffing"]
	_temp_npc_data["risk_aversion"] = parsed_data["risk_aversion"]
	
	# Save the completed NPC
	npc_slots[current_npc_index] = _temp_npc_data
	save_npc_slot(current_npc_index)
	
	print("GameManager: NPC generation complete!")
	print("  Name: ", _temp_npc_data["name"])
	print("  Backstory: ", _temp_npc_data["backstory"].substr(0, 100), "...")
	print("  Aggression: ", _temp_npc_data["aggression"])
	print("  Bluffing: ", _temp_npc_data["bluffing"])
	print("  Risk Aversion: ", _temp_npc_data["risk_aversion"])
	
	# Cleanup
	_cleanup_generation()
	
	# Notify UI
	processing_finished.emit()
	npc_data_changed.emit()

func _parse_npc_json_response(response: String) -> Dictionary:
	"""Parse JSON response from LLM into NPC data structure."""
	# Clean the response by extracting JSON between Phi-3 special tokens
	var cleaned_response = _extract_json_from_response(response)
	
	var json = JSON.new()
	var parse_result = json.parse(cleaned_response)
	
	if parse_result != OK:
		print("GameManager Error: JSON parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		print("Raw response: ", response)
		print("Cleaned response: ", cleaned_response)
		return {}
	
	var data = json.data
	
	# Validate all required fields are present
	if not data is Dictionary:
		print("GameManager Error: LLM response is not a JSON object")
		return {}
	
	if not data.has("name") or data["name"] == "":
		print("GameManager Error: Missing or empty 'name' field")
		return {}
	
	if not data.has("backstory") or data["backstory"] == "":
		print("GameManager Error: Missing or empty 'backstory' field")
		return {}
	
	if not data.has("aggression"):
		print("GameManager Error: Missing 'aggression' field")
		return {}
	
	if not data.has("bluffing"):
		print("GameManager Error: Missing 'bluffing' field")
		return {}
	
	if not data.has("risk_aversion"):
		print("GameManager Error: Missing 'risk_aversion' field")
		return {}
	
	# Validate and clamp trait values
	var result = {}
	result["name"] = str(data["name"])
	result["backstory"] = str(data["backstory"])
	
	# Ensure numeric values and clamp to valid range
	result["aggression"] = clamp(float(data["aggression"]), 0.0, 1.0)
	result["bluffing"] = clamp(float(data["bluffing"]), 0.0, 1.0)
	result["risk_aversion"] = clamp(float(data["risk_aversion"]), 0.0, 1.0)
	
	# Trim backstory to reasonable length
	if result["backstory"].length() > 1000:
		result["backstory"] = result["backstory"].substr(0, 997) + "..."
	
	return result

func _extract_json_from_response(response: String) -> String:
	"""
	Extract JSON content from LLM response by removing Phi-3 prompt echoes.
	JSON result is between the last <|assistant|> and last <|end|> tags.
	"""
	var cleaned = response.strip_edges()
	
	# Normalize line endings
	cleaned = cleaned.replace("\r\n", "\n")
	cleaned = cleaned.replace("\r", "\n")
	
	# Find the last occurrence of <|assistant|> marker
	var assistant_marker = "<|assistant|>"
	var last_assistant_pos = cleaned.rfind(assistant_marker)
	
	if last_assistant_pos != -1:
		# Extract everything after the last <|assistant|>
		cleaned = cleaned.substr(last_assistant_pos + assistant_marker.length())
	
	# Find the last occurrence of <|end|> marker
	var end_marker = "<|end|>"
	var last_end_pos = cleaned.rfind(end_marker)
	
	if last_end_pos != -1:
		# Extract everything before the last <|end|>
		cleaned = cleaned.substr(0, last_end_pos)
	
	# Strip any remaining whitespace
	cleaned = cleaned.strip_edges()
	
	# Log for debugging
	if last_assistant_pos != -1 or last_end_pos != -1:
		print("GameManager: Cleaned LLM response (removed prompt echo)")
		print("  Original length: ", response.length(), " chars")
		print("  Cleaned length: ", cleaned.length(), " chars")
	
	return cleaned

func _on_llm_error(error_message: String):
	"""Handle LLM errors during generation."""
	print("GameManager Error: LLM error - ", error_message)
	_on_generation_failed(error_message)

func _on_generation_failed(error_message: String):
	"""Handle generation failure and cleanup."""
	print("GameManager Error: NPC generation failed - ", error_message)
	_cleanup_generation()
	processing_finished.emit()
	# TODO: Show error dialog to user

func _cleanup_generation():
	"""Clean up generation state and disconnect signals."""
	_is_generating = false
	_temp_npc_data = {}
	current_npc_index = -1
	
	# Disconnect signals
	if LLMClient.response_received.is_connected(_on_llm_response):
		LLMClient.response_received.disconnect(_on_llm_response)
	if LLMClient.error_occurred.is_connected(_on_llm_error):
		LLMClient.error_occurred.disconnect(_on_llm_error)

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
