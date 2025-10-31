extends Control

# Chat.gd - Conversation interface for GameView
# Manages real-time text conversations between player and NPC
# Handles asynchronous LLM responses with independent state tracking

# UI References
@onready var tab_container = $MarginContainer/TabContainer
@onready var chat_display = $MarginContainer/TabContainer/CHAT/VBoxContainer/ScrollContainer/ChatDisplay
@onready var message_input = $MarginContainer/TabContainer/CHAT/VBoxContainer/InputContainer/MessageInput
@onready var history_display = $MarginContainer/TabContainer/HISTORY/ScrollContainer/HistoryDisplay

# State management
var is_awaiting_response: bool = false
var pending_npc_response: String = ""

# NPC data
var current_npc: Dictionary = {}

# Conversation tracking
var current_conversation_messages: Array = []  # Array of {speaker: String, text: String}

# Canned responses for abusive content
const DISMISSAL_RESPONSES = [
	"I'd rather not talk about that.",
	"Let's just play cards.",
	"That's not very sporting.",
	"I'm here to play poker, not chat about that."
]

func _ready():
	print("Chat: Initializing...")
	
	# Connect to GameState for turn management
	if GameState:
		GameState.state_changed.connect(_on_game_state_changed)
	
	# Connect message input
	message_input.text_submitted.connect(_on_message_input_text_submitted)
	
	# Initialize UI
	_update_input_state()

# ============================================================================
# INITIALIZATION
# ============================================================================

func init(npc_data: Dictionary) -> void:
	"""
	Initialize chat with NPC data.
	Called by GameView when match starts.
	"""
	print("Chat: Initializing with NPC data")
	current_npc = npc_data
	
	# Clear current chat display
	chat_display.clear()
	
	# Reset state
	is_awaiting_response = false
	pending_npc_response = ""
	
	# Clear conversation tracking for new match
	current_conversation_messages.clear()

func set_history_text(history: String) -> void:
	"""
	Load conversation history into the History tab.
	Called once during GameView initialization.
	"""
	print("Chat: Loading conversation history")
	history_display.clear()
	
	if history.is_empty():
		history_display.append_text("[i]No previous conversations with this NPC.[/i]")
	else:
		history_display.append_text(history)

# ============================================================================
# MESSAGE HANDLING
# ============================================================================

func _on_message_input_text_submitted(text: String) -> void:
	"""
	Handle player message submission.
	Displays message, checks for abuse, and initiates LLM call.
	"""
	# Validate conditions
	if not GameState.is_player_turn():
		print("Chat Warning: Cannot send message when not player's turn")
		return
	
	if is_awaiting_response:
		print("Chat Warning: Already awaiting NPC response")
		return
	
	if text.strip_edges().is_empty():
		return
	
	var trimmed_message = text.strip_edges()
	
	# Display player message
	append_message("Player", trimmed_message, Color.CYAN)
	
	# Clear input
	message_input.clear()
	
	# Check for abusive content
	if _is_abusive(trimmed_message):
		print("Chat: Abusive content detected, using canned response")
		pending_npc_response = _get_dismissal_response()
		is_awaiting_response = true
		_update_input_state()
		return
	
	# Normal LLM call
	is_awaiting_response = true
	_update_input_state()
	_call_llm_async(trimmed_message)

func append_message(speaker: String, message: String, color: Color) -> void:
	"""
	Append a message to the chat display with BBCode formatting.
	"""
	var formatted_message = "[color=#%s]%s: %s[/color]\n" % [color.to_html(false), speaker, message]
	chat_display.append_text(formatted_message)
	
	# Track message in conversation history
	current_conversation_messages.append({
		"speaker": speaker,
		"text": message
	})
	
	# Auto-scroll to bottom
	chat_display.scroll_to_line(chat_display.get_line_count())

func display_npc_message(message: String) -> void:
	"""
	Display an NPC message in the chat.
	Called externally by NPC AI or GameView during NPC's turn.
	"""
	var npc_name = current_npc.get("name", "NPC")
	append_message(npc_name, message, Color.ORANGE)
	
	# Clear pending response and reset state
	pending_npc_response = ""
	is_awaiting_response = false
	_update_input_state()

# ============================================================================
# LLM INTEGRATION
# ============================================================================

func _call_llm_async(player_message: String) -> void:
	"""
	Initiate non-blocking LLM call for chat response.
	Stores response in pending_npc_response when received.
	Uses JSON schema for structured output.
	"""
	print("Chat: Initiating LLM call for chat response")
	
	# Connect to LLM signals if not already connected
	if not LLMClient.response_received.is_connected(_on_llm_response_received):
		LLMClient.response_received.connect(_on_llm_response_received)
	
	if not LLMClient.error_occurred.is_connected(_on_llm_error):
		LLMClient.error_occurred.connect(_on_llm_error)
	
	# Create chat prompt
	var prompt = _create_chat_prompt(player_message)
	
	# Define JSON schema for structured response
	var json_schema = _get_chat_response_json_schema()
	
	# Send prompt using CHAT model with JSON schema (non-blocking)
	var success = LLMClient.send_prompt(prompt, json_schema, LLMClient.ModelConfig.CHAT)
	
	if not success:
		print("Chat Error: Failed to initiate LLM call")
		pending_npc_response = "..."
		is_awaiting_response = true

func _on_llm_response_received(response_text: String) -> void:
	"""
	Handle LLM response.
	Store in pending variable, don't display yet.
	Parses JSON response if schema was used.
	"""
	print("Chat: LLM response received, storing in pending")
	
	# Parse JSON response
	var cleaned_response = _parse_chat_json_response(response_text)
	
	if cleaned_response == "":
		# Fallback to raw response cleaning if JSON parsing fails
		cleaned_response = response_text.strip_edges()
		cleaned_response = _clean_llm_response(cleaned_response)
	
	# Limit response length
	if cleaned_response.length() > 300:
		cleaned_response = cleaned_response.substr(0, 297) + "..."
	
	pending_npc_response = cleaned_response
	
	# Disconnect signals (will reconnect on next message)
	if LLMClient.response_received.is_connected(_on_llm_response_received):
		LLMClient.response_received.disconnect(_on_llm_response_received)
	
	if LLMClient.error_occurred.is_connected(_on_llm_error):
		LLMClient.error_occurred.disconnect(_on_llm_error)
	
	print("Chat: Response stored, waiting for NPC turn to display")

func _on_llm_error(error_message: String) -> void:
	"""Handle LLM error during chat."""
	print("Chat Error: LLM error - ", error_message)
	
	# Use fallback response
	pending_npc_response = "..."
	
	# Disconnect signals
	if LLMClient.response_received.is_connected(_on_llm_response_received):
		LLMClient.response_received.disconnect(_on_llm_response_received)
	
	if LLMClient.error_occurred.is_connected(_on_llm_error):
		LLMClient.error_occurred.disconnect(_on_llm_error)

func _create_chat_prompt(player_message: String) -> String:
	"""
	Create a prompt for chat response generation.
	Uses NPC personality and backstory.
	Loads template from prompts/chat_response.txt
	"""
	var npc_name = current_npc.get("name", "NPC")
	var backstory = current_npc.get("backstory", "")
	var conversation_history = current_npc.get("conversation_history", "")
	
	# Load prompt template using centralized utility
	var template = LLMClient.load_prompt_file("chat_response.txt")
	
	if template == "":
		print("Chat Error: Could not load chat_response.txt")
		return ""
	
	# Format conversation history for prompt
	var history_text = ""
	if not conversation_history.is_empty():
		history_text = "Previous conversations with this player:\n" + conversation_history
	
	# Replace placeholders
	var prompt = template.replace("{npc_name}", npc_name)
	prompt = prompt.replace("{backstory}", backstory)
	prompt = prompt.replace("{conversation_history}", history_text)
	prompt = prompt.replace("{player_message}", player_message)
	
	return prompt

func _clean_llm_response(response: String) -> String:
	"""
	Clean LLM response by removing model-specific artifacts.
	Handles Phi-3 format and removes prompt echo.
	"""
	var cleaned = response
	
	# Remove prompt echo FIRST - find the last occurrence of "<|assistant|>" and take everything after
	var assistant_marker_pos = cleaned.rfind("<|assistant|>")
	if assistant_marker_pos != -1:
		cleaned = cleaned.substr(assistant_marker_pos + 13)  # Length of "<|assistant|>" = 13
	
	# Now remove Phi-3 format markers
	cleaned = cleaned.replace("<|user|>", "")
	cleaned = cleaned.replace("<|end|>", "")
	cleaned = cleaned.replace("<|assistant|>", "")
	
	# Remove common artifacts
	cleaned = cleaned.strip_edges()
	
	# Remove quotes if response is entirely quoted
	if cleaned.begins_with('"') and cleaned.ends_with('"'):
		cleaned = cleaned.substr(1, cleaned.length() - 2)
	
	return cleaned

func _get_chat_response_json_schema() -> String:
	"""
	Returns the JSON schema for chat response generation.
	Ensures structured output from Phi-3 model.
	"""
	var schema = {
		"type": "object",
		"properties": {
			"response": {
				"type": "string",
				"description": "NPC's in-character response to the player (1-2 sentences)"
			}
		},
		"required": ["response"]
	}
	
	return JSON.stringify(schema)

func _parse_chat_json_response(response: String) -> String:
	"""
	Parse JSON response from LLM for chat.
	Returns the response text or empty string if parsing fails.
	Uses centralized LLMClient utility for JSON parsing.
	"""
	var result = LLMClient.parse_json_field(response, "response")
	
	if result != "":
		print("Chat Debug: Extracted response field - ", result)
	
	return result

# ============================================================================
# OPENING LINE
# ============================================================================

func request_opening_line() -> void:
	"""
	Request an opening line from the LLM for match start.
	Called by GameView during initialization.
	Uses JSON schema for structured output.
	Displays immediately when received (doesn't wait for NPC turn).
	"""
	print("Chat: Requesting opening line from NPC")
	
	# Disable input while waiting for opening line
	is_awaiting_response = true
	_update_input_state()
	
	# Connect to opening line specific handler
	if not LLMClient.response_received.is_connected(_on_opening_line_received):
		LLMClient.response_received.connect(_on_opening_line_received)
	
	if not LLMClient.error_occurred.is_connected(_on_opening_line_error):
		LLMClient.error_occurred.connect(_on_opening_line_error)
	
	# Create opening line prompt
	var prompt = _create_opening_line_prompt()
	
	# Define JSON schema for structured response
	var json_schema = _get_chat_response_json_schema()  # Same schema as chat response
	
	# Send prompt with JSON schema
	var success = LLMClient.send_prompt(prompt, json_schema, LLMClient.ModelConfig.CHAT)
	
	if not success:
		# Fallback opening line - display immediately
		var npc_name = current_npc.get("name", "NPC")
		append_message(npc_name, "Let's play some poker.", Color.ORANGE)
		# Re-enable input
		is_awaiting_response = false
		_update_input_state()

func _create_opening_line_prompt() -> String:
	"""
	Create a prompt for NPC opening line generation.
	Loads template from prompts/chat_opening_line.txt
	"""
	var npc_name = current_npc.get("name", "NPC")
	var backstory = current_npc.get("backstory", "")
	var conversation_history = current_npc.get("conversation_history", "")
	
	# Load prompt template using centralized utility
	var template = LLMClient.load_prompt_file("chat_opening_line.txt")
	
	if template == "":
		print("Chat Error: Could not load chat_opening_line.txt")
		return ""
	
	# Format conversation history for prompt
	var history_text = ""
	if not conversation_history.is_empty():
		history_text = "Previous conversations with this player:\n" + conversation_history
	
	# Replace placeholders
	var prompt = template.replace("{npc_name}", npc_name)
	prompt = prompt.replace("{backstory}", backstory)
	prompt = prompt.replace("{conversation_history}", history_text)
	
	return prompt

func _on_opening_line_received(response_text: String) -> void:
	"""
	Handle opening line LLM response.
	Displays immediately (doesn't wait for NPC turn).
	"""
	print("Chat: Opening line received, displaying immediately")
	print("Chat: Raw response - ", response_text)
	
	# Parse JSON response
	var cleaned_response = _parse_chat_json_response(response_text)
	
	if cleaned_response == "":
		print("Chat Warning: JSON parsing failed for opening line, using fallback")
		# Fallback - use generic opening line
		cleaned_response = "Let's play some poker."
	
	# Limit response length
	if cleaned_response.length() > 300:
		cleaned_response = cleaned_response.substr(0, 297) + "..."
	
	print("Chat: Cleaned opening line - ", cleaned_response)
	
	# Display immediately
	var npc_name = current_npc.get("name", "NPC")
	append_message(npc_name, cleaned_response, Color.ORANGE)
	
	# Re-enable input now that opening line is displayed
	is_awaiting_response = false
	_update_input_state()
	
	# Disconnect signals
	if LLMClient.response_received.is_connected(_on_opening_line_received):
		LLMClient.response_received.disconnect(_on_opening_line_received)
	
	if LLMClient.error_occurred.is_connected(_on_opening_line_error):
		LLMClient.error_occurred.disconnect(_on_opening_line_error)

func _on_opening_line_error(error_message: String) -> void:
	"""Handle LLM error during opening line generation."""
	print("Chat Error: Opening line LLM error - ", error_message)
	
	# Use fallback and display immediately
	var npc_name = current_npc.get("name", "NPC")
	append_message(npc_name, "Let's play some poker.", Color.ORANGE)
	
	# Re-enable input
	is_awaiting_response = false
	_update_input_state()
	
	# Disconnect signals
	if LLMClient.response_received.is_connected(_on_opening_line_received):
		LLMClient.response_received.disconnect(_on_opening_line_received)
	
	if LLMClient.error_occurred.is_connected(_on_opening_line_error):
		LLMClient.error_occurred.disconnect(_on_opening_line_error)

# ============================================================================
# ABUSIVE CONTENT FILTERING
# ============================================================================

func _is_abusive(message: String) -> bool:
	"""
	Simple keyword-based filter for abusive content.
	Can be upgraded to LLM-based detection post-MVP.
	"""
	var lowercase_message = message.to_lower()
	
	# Basic keyword list (extend as needed)
	var abusive_keywords = [
		"fuck", "shit", "damn", "hell", "bitch", "ass",
		"stupid", "idiot", "moron", "dumb", "loser"
	]
	
	for keyword in abusive_keywords:
		if keyword in lowercase_message:
			return true
	
	return false

func _get_dismissal_response() -> String:
	"""Get a random canned dismissal response."""
	return DISMISSAL_RESPONSES[randi() % DISMISSAL_RESPONSES.size()]

# ============================================================================
# UI STATE MANAGEMENT
# ============================================================================

func _on_game_state_changed(_new_state: GameState.State) -> void:
	"""
	Update UI based on game state changes.
	Independent from is_awaiting_response.
	"""
	_update_input_state()

func _update_input_state() -> void:
	"""
	Update message input enabled state and placeholder text.
	Considers both GameState and is_awaiting_response.
	"""
	var can_send_message = GameState.is_player_turn() and not is_awaiting_response
	
	message_input.editable = can_send_message
	
	# Update placeholder text
	if is_awaiting_response:
		message_input.placeholder_text = "NPC is thinking..."
	elif not GameState.is_player_turn():
		message_input.placeholder_text = "Wait for your turn..."
	else:
		message_input.placeholder_text = "Type your message..."

# ============================================================================
# PUBLIC API
# ============================================================================

func has_pending_response() -> bool:
	"""Check if there's a pending NPC response waiting to be displayed."""
	return not pending_npc_response.is_empty()

func get_pending_response() -> String:
	"""Get and clear the pending NPC response."""
	var response = pending_npc_response
	pending_npc_response = ""
	is_awaiting_response = false
	_update_input_state()
	return response

func clear_chat() -> void:
	"""Clear the current chat display."""
	chat_display.clear()

func get_conversation_messages() -> Array:
	"""Get the current conversation messages for saving to history."""
	return current_conversation_messages.duplicate()

func reset() -> void:
	"""Reset chat state (for cleanup when leaving match)."""
	print("Chat: Resetting state")
	is_awaiting_response = false
	pending_npc_response = ""
	current_npc = {}
	current_conversation_messages.clear()
	chat_display.clear()
	history_display.clear()
	message_input.clear()
	_update_input_state()
