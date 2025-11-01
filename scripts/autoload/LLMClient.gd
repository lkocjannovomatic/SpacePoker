extends Node

# LLMClient.gd - Centralized wrapper for godot-llm addon
# This autoload singleton provides a simple API for LLM communication
# with async handling and error management.
# Supports two model configurations: NPC_GENERATION and CHAT

signal response_received(response_text: String)
signal error_occurred(error_message: String)

# Model configuration enum
enum ModelConfig {
	NPC_GENERATION,  # Phi-3-mini-4k-instruct-q4 for generating NPC backstories and personalities
	CHAT             # Phi-3-mini-4k-instruct-q4 optimized for fast in-game chat responses
}

var gdllama: GDLlama
var is_llm_processing: bool = false
var current_model: ModelConfig = ModelConfig.NPC_GENERATION

# Model configurations
const MODEL_CONFIGS = {
	ModelConfig.NPC_GENERATION: {
		"path": "res://llms/Phi-3-mini-4k-instruct-q4.gguf",
		"context_size": 4096,      # Phi-3 max context window (4K tokens)
		"n_predict": 512,          # Longer generation for detailed backstories and personality analysis
		"temperature": 0.7,        # Balanced creativity for character generation
		"top_p": 0.9,              # Nucleus sampling for diverse but coherent output
		"description": "Phi-3-mini-4k-instruct-q4 (3.8B params, Q4_K_M quantization, 2.2GB) - NPC Generation"
	},
	ModelConfig.CHAT: {
		"path": "res://llms/Phi-3-mini-4k-instruct-q4.gguf",
		"context_size": 2048,      # Reduced context for faster chat responses
		"n_predict": 100,          # Shorter responses for quick chat interactions
		"temperature": 0.8,        # Slightly higher creativity for engaging conversation
		"top_p": 0.95,             # Higher diversity for more natural chat responses
		"description": "Phi-3-mini-4k-instruct-q4 (3.8B params, Q4_K_M quantization, 2.2GB) - Chat"
	}
}

func _ready():
	print("LLMClient: Initializing...")
	_initialize_llm()

func _initialize_llm():
	"""Initialize the GDLlama node with default settings (NPC_GENERATION model)."""
	# Check if GDLlama class exists (extension might not be loaded in headless/export mode)
	if not ClassDB.class_exists("GDLlama"):
		var error_msg = "GDLlama extension not available. LLM features will be disabled."
		print("LLMClient Warning: ", error_msg)
		error_occurred.emit(error_msg)
		return
	
	# Verify model file exists
	var phi3_path = "res://llms/Phi-3-mini-4k-instruct-q4.gguf"
	
	if not FileAccess.file_exists(phi3_path):
		var error_msg = "LLM model file not found at %s. Please ensure the Phi-3 model is properly installed." % phi3_path
		print("LLMClient Error: ", error_msg)
		error_occurred.emit(error_msg)
		return
	
	gdllama = GDLlama.new()
	
	if not gdllama:
		var error_msg = "Failed to create GDLlama node. Check if godot-llm addon is properly installed."
		print("LLMClient Error: ", error_msg)
		error_occurred.emit(error_msg)
		return
	
	# Connect signals for async handling
	gdllama.generate_text_finished.connect(_on_text_generated)
	
	# Load default model (NPC_GENERATION)
	_load_model(ModelConfig.NPC_GENERATION)
	
	print("LLMClient: GDLlama initialized successfully with Phi-3 model for both NPC generation and chat")

func _load_model(model_config: ModelConfig):
	"""Load and configure a specific model based on the ModelConfig enum."""
	if not gdllama:
		print("LLMClient Error: GDLlama not initialized")
		return
	
	var config = MODEL_CONFIGS[model_config]
	
	print("LLMClient: Loading model configuration - ", config["description"])
	
	# Configure the LLM with model-specific settings
	gdllama.model_path = config["path"]
	gdllama.context_size = config["context_size"]
	gdllama.n_predict = config["n_predict"]
	gdllama.temperature = config["temperature"]
	gdllama.top_p = config["top_p"]
	
	current_model = model_config
	
	print("LLMClient: Model configured successfully")
	print("  - Context size: ", config["context_size"])
	print("  - Max predict tokens: ", config["n_predict"])
	print("  - Temperature: ", config["temperature"])
	print("  - Top-p: ", config["top_p"])

func send_prompt(prompt: String, json_schema: String = "", model_config: ModelConfig = ModelConfig.NPC_GENERATION) -> bool:
	"""
	Send a prompt to the LLM asynchronously.
	
	Parameters:
	- prompt: The text prompt to send to the LLM
	- json_schema: Optional JSON schema for structured output (uses generate_text_json)
	- model_config: Which model to use (NPC_GENERATION or CHAT). Defaults to NPC_GENERATION.
	
	Returns true if the request was initiated successfully, false otherwise.
	"""
	if is_llm_processing:
		error_occurred.emit("LLM is already processing a request. Please wait.")
		return false
	
	if not gdllama:
		error_occurred.emit("LLM not initialized. Please restart the application.")
		return false
	
	if prompt.length() == 0:
		error_occurred.emit("Cannot send empty prompt.")
		return false
	
	# Switch model if needed
	if model_config != current_model:
		print("LLMClient: Switching model configuration...")
		_load_model(model_config)
	
	print("LLMClient: Sending prompt using ", MODEL_CONFIGS[model_config]["description"])
	print("LLMClient: Prompt preview: ", prompt.substr(0, 80), "...")
	if json_schema != "":
		print("LLMClient: Using JSON schema for structured output")
	
	is_llm_processing = true
	
	# Use run_generate_text for async processing
	# If json_schema is provided, it will be used for structured output
	var result = gdllama.run_generate_text(prompt, "", json_schema)
	
	if result != OK:
		is_llm_processing = false
		error_occurred.emit("Failed to start text generation. Error code: " + str(result))
		return false
	
	return true

func _on_text_generated(generated_text: String):
	print("LLMClient: Text generation completed")
	is_llm_processing = false
	response_received.emit(generated_text)

func stop_generation():
	if gdllama and is_llm_processing:
		gdllama.stop_generate_text()
		is_llm_processing = false
		print("LLMClient: Text generation stopped")

func is_ready() -> bool:
	return gdllama != null and not is_llm_processing

func get_status() -> String:
	if not gdllama:
		return "Not initialized"
	elif is_llm_processing:
		return "Processing with " + MODEL_CONFIGS[current_model]["description"]
	else:
		return "Ready (" + MODEL_CONFIGS[current_model]["description"] + ")"

func get_current_model() -> ModelConfig:
	return current_model

func get_model_info(model_config: ModelConfig) -> Dictionary:
	return MODEL_CONFIGS[model_config]

# ============================================================================
# UTILITY FUNCTIONS - Phi-3 Response Processing
# ============================================================================

func extract_json_from_response(response: String) -> String:
	"""
	Extract JSON content from Phi-3 LLM response by removing prompt echo.
	JSON result is between the last <|assistant|> marker and any trailing markers.
	
	This is a centralized utility to avoid code duplication across Chat.gd and NPCGenerator.gd.
	"""
	var cleaned = response.strip_edges()
	
	# Normalize line endings
	cleaned = cleaned.replace("\r\n", "\n")
	cleaned = cleaned.replace("\r", "\n")
	
	# Find the LAST occurrence of <|assistant|> marker
	var assistant_marker = "<|assistant|>"
	var last_assistant_pos = cleaned.rfind(assistant_marker)
	
	if last_assistant_pos != -1:
		# Extract everything after the last <|assistant|>
		cleaned = cleaned.substr(last_assistant_pos + assistant_marker.length())
	
	# Find the last occurrence of <|end|> marker (optional in responses)
	var end_marker = "<|end|>"
	var last_end_pos = cleaned.rfind(end_marker)
	
	if last_end_pos != -1:
		# Extract everything before the last <|end|>
		cleaned = cleaned.substr(0, last_end_pos)
	
	# Remove any remaining Phi-3 format markers
	cleaned = cleaned.replace("<|user|>", "")
	cleaned = cleaned.replace("<|end|>", "")
	cleaned = cleaned.replace("<|assistant|>", "")
	
	# Strip any remaining whitespace
	cleaned = cleaned.strip_edges()
	
	# Try to find JSON object boundaries in the cleaned response
	var json_start = cleaned.find("{")
	var json_end = cleaned.rfind("}")
	
	if json_start != -1 and json_end != -1 and json_end > json_start:
		cleaned = cleaned.substr(json_start, json_end - json_start + 1)
	
	# Remove any remaining whitespace
	cleaned = cleaned.strip_edges()
	
	return cleaned

func parse_json_field(response: String, field_name: String) -> String:
	"""
	Parse a specific field from a JSON response.
	Returns the field value as a string, or empty string if parsing fails.
	
	This centralizes JSON parsing logic used by both Chat.gd and NPCGenerator.gd.
	"""
	# Clean the response by extracting JSON
	var cleaned = extract_json_from_response(response)
	
	var json = JSON.new()
	var parse_result = json.parse(cleaned)
	
	if parse_result != OK:
		print("LLMClient Warning: JSON parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		print("LLMClient Warning: Attempted to parse: ", cleaned)
		return ""
	
	var data = json.data
	
	# Validate response structure
	if not data is Dictionary:
		print("LLMClient Warning: LLM response is not a JSON object")
		return ""
	
	if not data.has(field_name):
		print("LLMClient Warning: Missing '", field_name, "' field in JSON")
		print("LLMClient Warning: Available keys: ", data.keys())
		return ""
	
	return str(data[field_name]).strip_edges()

func parse_json_object(response: String, required_fields: Array = []) -> Dictionary:
	"""
	Parse a complete JSON object from LLM response.
	Optionally validates that required fields are present and non-empty.
	Returns the parsed dictionary, or empty dictionary if parsing fails.
	
	This centralizes JSON parsing logic used by NPCGenerator.gd.
	"""
	# Clean the response by extracting JSON
	var cleaned = extract_json_from_response(response)
	
	var json = JSON.new()
	var parse_result = json.parse(cleaned)
	
	if parse_result != OK:
		print("LLMClient Error: JSON parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		print("LLMClient Error: Raw response: ", response)
		print("LLMClient Error: Cleaned response: ", cleaned)
		return {}
	
	var data = json.data
	
	# Validate response structure
	if not data is Dictionary:
		print("LLMClient Error: LLM response is not a JSON object")
		return {}
	
	# Validate required fields if specified
	for field in required_fields:
		if not data.has(field) or str(data[field]).strip_edges() == "":
			print("LLMClient Error: Missing or empty '", field, "' field")
			return {}
	
	return data

func load_prompt_file(filename: String) -> String:
	"""
	Load a prompt template file from the prompts/ directory.
	Returns empty string if file not found.
	
	This centralizes prompt file loading used by both Chat.gd and NPCGenerator.gd.
	"""
	var prompt_path = "res://prompts/" + filename
	
	if not FileAccess.file_exists(prompt_path):
		print("LLMClient Error: Prompt file not found at ", prompt_path)
		return ""
	
	var file = FileAccess.open(prompt_path, FileAccess.READ)
	if file == null:
		print("LLMClient Error: Could not open prompt file: ", prompt_path)
		return ""
	
	var prompt = file.get_as_text()
	file.close()
	
	return prompt

# Clean up resources when the node is freed
func _exit_tree():
	if gdllama and is_llm_processing:
		stop_generation()