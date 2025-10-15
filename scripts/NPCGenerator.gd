extends Node

# NPCGenerator.gd - Handles NPC generation using LLM

# Signals
signal generation_completed(slot_index: int, npc_data: Dictionary)
signal generation_failed(error_message: String)

# Constants
const PROMPTS_DIR = "prompts/"

# Generation state
var _is_generating: bool = false
var _current_slot_index: int = -1
var _temp_npc_data: Dictionary = {}

func _ready():
	print("NPCGenerator: Ready")

func is_generating() -> bool:
	"""Check if generation is currently in progress."""
	return _is_generating

func generate_npc(slot_index: int, empty_slot_template: Dictionary):
	"""
	Initiate NPC generation for a specific slot.
	Uses JSON schema for structured output from LLM.
	
	Args:
		slot_index: The slot index to generate for
		empty_slot_template: Empty slot structure to use as base
	"""
	if _is_generating:
		print("NPCGenerator Warning: Generation already in progress")
		return
	
	print("NPCGenerator: Starting NPC generation for slot ", slot_index)
	
	# Store the slot index and initialize temp data
	_current_slot_index = slot_index
	_is_generating = true
	_temp_npc_data = empty_slot_template.duplicate(true)
	
	# Connect to LLM signals
	if not LLMClient.response_received.is_connected(_on_llm_response):
		LLMClient.response_received.connect(_on_llm_response)
	
	if not LLMClient.error_occurred.is_connected(_on_llm_error):
		LLMClient.error_occurred.connect(_on_llm_error)
	
	# Create prompt for NPC generation
	var prompt = _load_prompt_file("npc_generation.txt")
	
	# Define JSON schema for structured NPC output
	var json_schema = _get_npc_json_schema()
	
	# Send to LLM with JSON schema, using NPC_GENERATION model (Phi-3)
	var success = LLMClient.send_prompt(prompt, json_schema, LLMClient.ModelConfig.NPC_GENERATION)
	
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
		print("NPCGenerator Error: Prompt file not found at ", prompt_path)
		return ""
	
	var file = FileAccess.open(prompt_path, FileAccess.READ)
	if file == null:
		print("NPCGenerator Error: Could not open prompt file: ", prompt_path)
		return ""
	
	var prompt = file.get_as_text()
	file.close()
	
	return prompt

func _on_llm_response(response_text: String):
	"""Handle LLM response for NPC generation (JSON format)."""
	print("NPCGenerator: LLM response received, parsing JSON...")
	
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
	
	print("NPCGenerator: NPC generation complete!")
	print("  Name: ", _temp_npc_data["name"])
	print("  Backstory: ", _temp_npc_data["backstory"].substr(0, 100), "...")
	print("  Aggression: ", _temp_npc_data["aggression"])
	print("  Bluffing: ", _temp_npc_data["bluffing"])
	print("  Risk Aversion: ", _temp_npc_data["risk_aversion"])
	
	# Emit success signal with generated data
	var slot_index = _current_slot_index
	var npc_data = _temp_npc_data.duplicate(true)
	
	# Cleanup before emitting signal
	_cleanup_generation()
	
	# Notify completion
	generation_completed.emit(slot_index, npc_data)

func _parse_npc_json_response(response: String) -> Dictionary:
	"""Parse JSON response from LLM into NPC data structure."""
	# Clean the response by extracting JSON between Phi-3 special tokens
	var cleaned_response = _extract_json_from_response(response)
	
	var json = JSON.new()
	var parse_result = json.parse(cleaned_response)
	
	if parse_result != OK:
		print("NPCGenerator Error: JSON parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		print("Raw response: ", response)
		print("Cleaned response: ", cleaned_response)
		return {}
	
	var data = json.data
	
	# Validate all required fields are present
	if not data is Dictionary:
		print("NPCGenerator Error: LLM response is not a JSON object")
		return {}
	
	if not data.has("name") or data["name"] == "":
		print("NPCGenerator Error: Missing or empty 'name' field")
		return {}
	
	if not data.has("backstory") or data["backstory"] == "":
		print("NPCGenerator Error: Missing or empty 'backstory' field")
		return {}
	
	if not data.has("aggression"):
		print("NPCGenerator Error: Missing 'aggression' field")
		return {}
	
	if not data.has("bluffing"):
		print("NPCGenerator Error: Missing 'bluffing' field")
		return {}
	
	if not data.has("risk_aversion"):
		print("NPCGenerator Error: Missing 'risk_aversion' field")
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
		print("NPCGenerator: Cleaned LLM response (removed prompt echo)")
		print("  Original length: ", response.length(), " chars")
		print("  Cleaned length: ", cleaned.length(), " chars")
	
	return cleaned

func _on_llm_error(error_message: String):
	"""Handle LLM errors during generation."""
	print("NPCGenerator Error: LLM error - ", error_message)
	_on_generation_failed(error_message)

func _on_generation_failed(error_message: String):
	"""Handle generation failure and cleanup."""
	print("NPCGenerator Error: NPC generation failed - ", error_message)
	_cleanup_generation()
	generation_failed.emit(error_message)

func _cleanup_generation():
	"""Clean up generation state and disconnect signals."""
	_is_generating = false
	_temp_npc_data = {}
	_current_slot_index = -1
	
	# Disconnect signals
	if LLMClient.response_received.is_connected(_on_llm_response):
		LLMClient.response_received.disconnect(_on_llm_response)
	if LLMClient.error_occurred.is_connected(_on_llm_error):
		LLMClient.error_occurred.disconnect(_on_llm_error)
