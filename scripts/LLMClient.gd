extends Node

# LLMClient.gd - Centralized wrapper for godot-llm addon
# This autoload singleton provides a simple API for LLM communication
# with async handling and error management.

signal response_received(response_text: String)
signal error_occurred(error_message: String)

var gdllama: GDLlama
var is_llm_processing: bool = false

func _ready():
	print("LLMClient: Initializing...")
	_initialize_llm()

func _initialize_llm():
	"""Initialize the GDLlama node with appropriate settings."""
	# Check if the LLM model file exists
	if not FileAccess.file_exists("res://llms/Phi-3-mini-4k-instruct-q4.gguf"):
		var error_msg = "LLM model file not found at res://llms/Phi-3-mini-4k-instruct-q4.gguf. Please ensure the model is properly installed."
		print("LLMClient Error: ", error_msg)
		error_occurred.emit(error_msg)
		return
	
	gdllama = GDLlama.new()
	
	if not gdllama:
		var error_msg = "Failed to create GDLlama node. Check if godot-llm addon is properly installed."
		print("LLMClient Error: ", error_msg)
		error_occurred.emit(error_msg)
		return
	
	# Configure the LLM with settings appropriate for chat/personality generation
	# Model: Phi-3-mini-4k-instruct-q4 (2.39 GB)
	# Source: https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf
	# Quantization: Q4_K_M - medium, balanced quality (recommended)
	# Architecture: Phi-3, 3.8B parameters
	# Max context window: 4096 tokens (4k)
	gdllama.model_path = "res://llms/Phi-3-mini-4k-instruct-q4.gguf"
	gdllama.context_size = 4096  # Using full 4096 context window (Phi-3 max)
	gdllama.n_predict = 300  # Maximum tokens to generate for backstories and personality analysis
	gdllama.temperature = 0.7  # Balanced creativity for character generation
	gdllama.top_p = 0.9  # Nucleus sampling (0.0-1.0, controls diversity)
	
	# Connect signals for async handling
	gdllama.generate_text_finished.connect(_on_text_generated)
	gdllama.generate_text_updated.connect(_on_text_updated)
	
	print("LLMClient: GDLlama initialized successfully")

func send_prompt(prompt: String, json_schema: String = "") -> bool:
	"""
	Send a prompt to the LLM asynchronously.
	If json_schema is provided, uses generate_text_json for structured output.
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
	
	print("LLMClient: Sending prompt: ", prompt.substr(0, 50), "...")
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
		return "Processing"
	else:
		return "Ready"

# Clean up resources when the node is freed
func _exit_tree():
	if gdllama and is_llm_processing:
		stop_generation()