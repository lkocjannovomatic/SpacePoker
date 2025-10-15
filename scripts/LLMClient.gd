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
	CHAT             # TinyLlama-1.1B-32k-Instruct for in-game chat responses
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
		"description": "Phi-3-mini-4k-instruct-q4 (3.8B params, Q4_K_M quantization, 2.2GB)"
	},
	ModelConfig.CHAT: {
		"path": "res://llms/TinyLlama-1.1B-32k-Instruct-Q4_K_M.gguf",
		"context_size": 4096,      # Use 4096 tokens for chat (TinyLlama supports up to 32K)
		"n_predict": 150,          # Shorter responses for quick chat interactions
		"temperature": 0.8,        # Slightly higher creativity for engaging conversation
		"top_p": 0.95,             # Higher diversity for more natural chat responses
		"description": "TinyLlama-1.1B-32k-Instruct (1.1B params, Q4_K_M quantization, 0.622GB)"
	}
}

func _ready():
	print("LLMClient: Initializing...")
	_initialize_llm()

func _initialize_llm():
	"""Initialize the GDLlama node with default settings (NPC_GENERATION model)."""
	# Verify both model files exist
	var phi3_path = "res://llms/Phi-3-mini-4k-instruct-q4.gguf"
	var tinyllama_path = "res://llms/TinyLlama-1.1B-32k-Instruct-Q4_K_M.gguf"
	
	if not FileAccess.file_exists(phi3_path):
		var error_msg = "LLM model file not found at %s. Please ensure the Phi-3 model is properly installed." % phi3_path
		print("LLMClient Error: ", error_msg)
		error_occurred.emit(error_msg)
		return
	
	if not FileAccess.file_exists(tinyllama_path):
		var error_msg = "LLM model file not found at %s. Please ensure the TinyLlama model is properly installed." % tinyllama_path
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
	gdllama.generate_text_updated.connect(_on_text_updated)
	
	# Load default model (NPC_GENERATION)
	_load_model(ModelConfig.NPC_GENERATION)
	
	print("LLMClient: GDLlama initialized successfully with both model configurations available")

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
	"""Handle the completed text generation."""
	print("LLMClient: Text generation completed")
	is_llm_processing = false
	response_received.emit(generated_text)

func _on_text_updated(_new_text: String):
	"""Handle streaming text updates (optional for this prototype)."""
	# For the prototype, we'll just wait for the complete response
	# This could be used for real-time streaming in the future
	pass

func stop_generation():
	"""Stop the current text generation if running."""
	if gdllama and is_llm_processing:
		gdllama.stop_generate_text()
		is_llm_processing = false
		print("LLMClient: Text generation stopped")

func is_ready() -> bool:
	"""Check if the LLM client is ready to accept requests."""
	return gdllama != null and not is_llm_processing

func get_status() -> String:
	"""Get the current status of the LLM client."""
	if not gdllama:
		return "Not initialized"
	elif is_llm_processing:
		return "Processing with " + MODEL_CONFIGS[current_model]["description"]
	else:
		return "Ready (" + MODEL_CONFIGS[current_model]["description"] + ")"

func get_current_model() -> ModelConfig:
	"""Get the currently loaded model configuration."""
	return current_model

func get_model_info(model_config: ModelConfig) -> Dictionary:
	"""Get information about a specific model configuration."""
	return MODEL_CONFIGS[model_config]

# Clean up resources when the node is freed
func _exit_tree():
	if gdllama and is_llm_processing:
		stop_generation()