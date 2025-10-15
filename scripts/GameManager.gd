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
	Uses a single-phase approach: generates name, backstory, and personality traits in one LLM call.
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
	
	# Send to LLM
	var success = LLMClient.send_prompt(prompt)
	
	if not success:
		_on_generation_failed("Failed to initiate NPC generation")

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
	"""Handle LLM response for NPC generation."""
	print("GameManager: LLM response received, parsing...")
	
	var parsed_data = _parse_npc_response(response_text)
	
	if parsed_data.is_empty():
		_on_generation_failed("Failed to parse NPC data from LLM response")
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

func _parse_npc_response(response: String) -> Dictionary:
	"""Parse NPC generation response: name, backstory, and all personality traits."""
	var data = {}
	
	# Clean response and handle Phi-3 prompt echo (ends at <|assistant|>)
	var cleaned = _extract_response_content(response)
	var lines = cleaned.split("\n")
	
	# Parse all fields
	for line in lines:
		line = line.strip_edges()
		if line == "":
			continue
		
		var upper_line = line.to_upper()
		
		if upper_line.begins_with("NAME:"):
			var name_value = line.substr(5).strip_edges()
			name_value = name_value.replace("\"", "").replace("'", "")
			if name_value != "" and not name_value.contains("["):
				data["name"] = name_value
		
		elif upper_line.begins_with("BACKSTORY:"):
			var backstory_value = line.substr(10).strip_edges()
			if not backstory_value.contains("["):
				data["backstory"] = backstory_value
		
		elif upper_line.begins_with("AGGRESSION:"):
			data["aggression"] = _extract_trait_value_from_line(line, "AGGRESSION:")
		
		elif upper_line.begins_with("BLUFFING:"):
			data["bluffing"] = _extract_trait_value_from_line(line, "BLUFFING:")
		
		elif upper_line.begins_with("RISK_AVERSION:") or upper_line.begins_with("RISK AVERSION:"):
			data["risk_aversion"] = _extract_trait_value_from_line(line, "RISK")
		
		# Continue backstory if it's a continuation line (not a field marker)
		elif data.has("backstory") and not data.has("aggression") and not upper_line.contains(":"):
			if line.length() > 10 and not line.contains("["):
				data["backstory"] += " " + line
	
	# Validate all required fields
	if not data.has("name") or data["name"] == "":
		print("GameManager Error: Could not parse name from response")
		print("Raw response (first 300 chars): ", response.substr(0, 300))
		return {}
	
	if not data.has("backstory") or data["backstory"] == "":
		print("GameManager Error: Could not parse backstory from response")
		return {}
	
	if not data.has("aggression") or data["aggression"] < 0.0:
		print("GameManager Error: Could not parse aggression trait")
		return {}
	
	if not data.has("bluffing") or data["bluffing"] < 0.0:
		print("GameManager Error: Could not parse bluffing trait")
		return {}
	
	if not data.has("risk_aversion") or data["risk_aversion"] < 0.0:
		print("GameManager Error: Could not parse risk_aversion trait")
		return {}
	
	# Trim backstory to reasonable length
	if data["backstory"].length() > 1000:
		data["backstory"] = data["backstory"].substr(0, 997) + "..."
	
	# Clamp trait values to valid range
	data["aggression"] = clamp(data["aggression"], 0.0, 1.0)
	data["bluffing"] = clamp(data["bluffing"], 0.0, 1.0)
	data["risk_aversion"] = clamp(data["risk_aversion"], 0.0, 1.0)
	
	return data

func _extract_trait_value_from_line(line: String, _keyword: String) -> float:
	"""Extract a single trait value from a line containing 'KEYWORD: value'."""
	var colon_pos = line.find(":")
	if colon_pos == -1:
		return -1.0
	
	var value_str = line.substr(colon_pos + 1).strip_edges()
	return _extract_first_float(value_str)

func _extract_trait_value(text: String, keywords: Array) -> float:
	"""
	Extract a trait value using multiple strategies.
	Returns -1.0 if no valid value found.
	"""
	var upper_text = text.to_upper()
	
	# Try each keyword variant
	for keyword in keywords:
		var keyword_upper = keyword.to_upper()
		var pos = upper_text.find(keyword_upper)
		
		if pos == -1:
			continue
		
		# Get the rest of the line after the keyword
		var line_start = pos
		var line_end = upper_text.find("\n", pos)
		if line_end == -1:
			line_end = upper_text.length()
		
		var line = text.substr(line_start, line_end - line_start)
		
		# Strategy 1: Look for number after colon
		var colon_pos = line.find(":")
		if colon_pos != -1:
			var after_colon = line.substr(colon_pos + 1).strip_edges()
			var colon_value = _extract_first_float(after_colon)
			if colon_value >= 0.0:
				return colon_value
		
		# Strategy 2: Look for any number in the line
		var line_value = _extract_first_float(line)
		if line_value >= 0.0:
			return line_value
	
	return -1.0

func _extract_first_float(text: String) -> float:
	"""
	Extract the first valid float from a string.
	More aggressive than _extract_float - finds ANY valid number.
	Returns -1.0 if no valid number found.
	"""
	var cleaned = ""
	var found_digit = false
	var has_dot = false
	
	for i in range(text.length()):
		var c = text[i]
		
		# Start collecting when we find a digit or minus
		if c.is_valid_int():
			cleaned += c
			found_digit = true
		elif c == "." and found_digit and not has_dot:
			cleaned += c
			has_dot = true
		elif c == "-" and not found_digit:
			cleaned += c
		elif found_digit:
			# We've found a number and hit a non-numeric character - stop
			break
	
	if not found_digit or cleaned == "" or cleaned == "." or cleaned == "-":
		return -1.0
	
	return float(cleaned)

func _extract_response_content(response: String) -> String:
	"""Extract actual response content, removing Phi-3 prompt echoes."""
	var cleaned = response.strip_edges()
	cleaned = cleaned.replace("\r\n", "\n")
	cleaned = cleaned.replace("\r", "\n")
	
	# Phi-3 format: Response comes after <|assistant|> tag
	var assistant_marker = "<|assistant|>"
	var assistant_pos = cleaned.find(assistant_marker)
	if assistant_pos != -1:
		# Extract everything after <|assistant|>
		cleaned = cleaned.substr(assistant_pos + assistant_marker.length()).strip_edges()
	
	# Remove any trailing <|end|> or <|user|> tags if present
	var end_marker = "<|end|>"
	var end_pos = cleaned.find(end_marker)
	if end_pos != -1:
		cleaned = cleaned.substr(0, end_pos).strip_edges()
	
	var user_marker = "<|user|>"
	var user_pos = cleaned.find(user_marker)
	if user_pos != -1:
		cleaned = cleaned.substr(0, user_pos).strip_edges()
	
	# Fallback: Look for "### Response:" marker (old format)
	var response_marker = "### Response:"
	var response_start = cleaned.find(response_marker)
	if response_start != -1:
		cleaned = cleaned.substr(response_start + response_marker.length()).strip_edges()
	
	# Additional fallback: If we still see instruction markers, find first field marker
	if cleaned.find("### Instruction:") != -1 or cleaned.find("### Input:") != -1 or cleaned.find("<|user|>") != -1:
		var temp_lines = cleaned.split("\n")
		var collecting = false
		var response_lines = []
		
		for temp_line in temp_lines:
			var upper_line = temp_line.strip_edges().to_upper()
			# Start collecting when we find the first field
			if upper_line.begins_with("NAME:") or upper_line.begins_with("AGGRESSION:"):
				collecting = true
			# Stop collecting if we hit another special marker
			if upper_line.begins_with("<|") or upper_line.begins_with("###"):
				if collecting:
					break
			if collecting:
				response_lines.append(temp_line)
		
		if response_lines.size() > 0:
			cleaned = "\n".join(response_lines)
	
	return cleaned

func _extract_float(value_str: String) -> float:
	"""Extract a float value from a string, handling common formatting issues."""
	# Remove any non-numeric characters except dot and minus
	var cleaned = ""
	var has_dot = false
	
	for i in range(value_str.length()):
		var c = value_str[i]
		if c.is_valid_int() or (c == "-" and i == 0):
			cleaned += c
		elif c == "." and not has_dot:
			cleaned += c
			has_dot = true
		elif c == " " or c == "\t":
			continue
		else:
			# Stop at first non-numeric character
			break
	
	if cleaned == "" or cleaned == "." or cleaned == "-":
		return -1.0
	
	return float(cleaned)

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
