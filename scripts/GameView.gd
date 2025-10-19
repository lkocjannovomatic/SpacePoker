extends Control

# GameView.gd - Main poker game view controller
# Orchestrates communication between Board and Chat components
# Manages match initialization, NPC data, and game flow

# Child component references
@onready var board = $HBoxContainer/Board
@onready var chat = $HBoxContainer/Chat

# Current match data
var current_npc: Dictionary = {}
var npc_ai_timer: Timer = null

# Constants
const NPC_ACTION_MIN_DELAY = 0.5  # Minimum seconds before NPC acts
const NPC_ACTION_MAX_DELAY = 1.5  # Maximum seconds before NPC acts

func _ready():
	print("GameView: Initializing...")
	
	# Create NPC AI timer
	npc_ai_timer = Timer.new()
	npc_ai_timer.one_shot = true
	npc_ai_timer.timeout.connect(_on_npc_ai_timer_timeout)
	add_child(npc_ai_timer)
	
	# Connect to Board signals
	if board:
		board.player_action_taken.connect(_on_player_action_taken)
	
	# Connect to GameState signals
	if GameState:
		GameState.state_changed.connect(_on_game_state_changed)
	
	# Initialize match
	_initialize_match()

# ============================================================================
# MATCH INITIALIZATION
# ============================================================================

func _initialize_match() -> void:
	"""
	Initialize the match with the selected NPC.
	Called automatically when GameView loads.
	"""
	print("GameView: Initializing match")
	
	# Get current NPC data from GameManager
	if GameManager.current_npc_index < 0:
		print("GameView Error: No NPC selected")
		GameManager.return_to_start_screen()
		return
	
	current_npc = GameManager.get_npc_data(GameManager.current_npc_index)
	
	if current_npc.is_empty() or current_npc.get("name", "") == "":
		print("GameView Error: Invalid NPC data")
		GameManager.return_to_start_screen()
		return
	
	print("GameView: Starting match against ", current_npc["name"])
	
	# Initialize Board
	if board:
		board.init()
	
	# Initialize Chat with NPC data
	if chat:
		chat.init(current_npc)
		
		# Load chat history
		var history = _load_chat_history()
		chat.set_history_text(history)
		
		# Request opening line from NPC
		chat.request_opening_line()
	
	# Start the match in GameState
	GameState.start_new_match(GameManager.STARTING_CREDITS)

func _load_chat_history() -> String:
	"""
	Load conversation history for this NPC from save file.
	Returns formatted string for display in History tab.
	"""
	var npc_index = GameManager.current_npc_index
	var history_path = "res://" + GameManager.SAVE_DIR + "chat_history_slot_" + str(npc_index) + ".json"
	
	if not FileAccess.file_exists(history_path):
		print("GameView: No chat history found for this NPC")
		return ""
	
	var file = FileAccess.open(history_path, FileAccess.READ)
	if file == null:
		print("GameView Error: Could not open chat history file")
		return ""
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("GameView Error: Failed to parse chat history JSON")
		return ""
	
	var data = json.data
	
	# Format history for display
	return _format_chat_history(data)

func _format_chat_history(history_data: Variant) -> String:
	"""
	Format chat history data into readable text.
	Expected format: { "conversations": [ { "messages": [...] }, ... ] }
	"""
	if not history_data is Dictionary:
		return ""
	
	if not history_data.has("conversations"):
		return ""
	
	var conversations = history_data["conversations"]
	if not conversations is Array or conversations.is_empty():
		return ""
	
	var formatted = ""
	
	for conversation in conversations:
		if not conversation is Dictionary:
			continue
		
		var timestamp = conversation.get("match_timestamp", "Unknown date")
		formatted += "[b]Match on " + timestamp + "[/b]\n"
		
		var messages = conversation.get("messages", [])
		for message in messages:
			if not message is Dictionary:
				continue
			
			var speaker = message.get("speaker", "Unknown")
			var text = message.get("text", "")
			
			if speaker == "Player":
				formatted += "[color=cyan]Player: " + text + "[/color]\n"
			else:
				formatted += "[color=orange]" + speaker + ": " + text + "[/color]\n"
		
		formatted += "\n"
	
	return formatted

# ============================================================================
# PLAYER ACTION HANDLING
# ============================================================================

func _on_player_action_taken(action: String, amount: int) -> void:
	"""
	Handle player actions from the Board.
	Translate to GameState calls.
	"""
	print("GameView: Player action - ", action, " (", amount, ")")
	
	match action:
		"fold":
			GameState.player_fold()
		"check":
			GameState.player_check()
		"call":
			GameState.player_call()
		"raise":
			GameState.player_raise(amount)
		_:
			print("GameView Warning: Unknown player action - ", action)

# ============================================================================
# GAME STATE MONITORING
# ============================================================================

func _on_game_state_changed(new_state: GameState.State) -> void:
	"""
	Monitor game state changes to trigger NPC AI.
	"""
	print("GameView: Game state changed to ", GameState.State.keys()[new_state])
	
	# If it's NPC's turn, trigger NPC AI after a delay
	if new_state == GameState.State.NPC_TURN:
		_trigger_npc_turn()
	
	# If match ended, save chat history and show summary
	if new_state == GameState.State.MATCH_END:
		_on_match_end()

# ============================================================================
# NPC AI (Placeholder)
# ============================================================================

func _trigger_npc_turn() -> void:
	"""
	Trigger NPC's turn with a realistic delay.
	First checks for pending chat response, then makes poker decision.
	"""
	print("GameView: Triggering NPC turn")
	
	# Random delay for realism
	var delay = randf_range(NPC_ACTION_MIN_DELAY, NPC_ACTION_MAX_DELAY)
	npc_ai_timer.start(delay)

func _on_npc_ai_timer_timeout() -> void:
	"""
	Execute NPC's turn after timer delay.
	"""
	# Check for pending chat response first
	if chat and chat.has_pending_response():
		var response = chat.get_pending_response()
		chat.display_npc_message(response)
		
		# Brief delay before poker action
		await get_tree().create_timer(0.3).timeout
	
	# Execute poker action (placeholder - simple random strategy)
	_execute_npc_poker_action()

func _execute_npc_poker_action() -> void:
	"""
	Execute NPC's poker action.
	Placeholder logic - will be replaced by personality-driven AI.
	"""
	if not GameState.is_npc_turn():
		print("GameView Warning: _execute_npc_poker_action called but not NPC's turn")
		return
	
	print("GameView: NPC making poker decision (placeholder logic)")
	
	# Placeholder: Simple random strategy
	var action_roll = randf()
	
	if action_roll < 0.3:
		# 30% fold
		GameState.npc_fold()
	elif action_roll < 0.7:
		# 40% call/check
		if GameState.current_bet == GameState.npc_bet_this_round:
			GameState.npc_check()
		else:
			GameState.npc_call()
	else:
		# 30% raise
		var min_raise = GameState.get_min_raise()
		var npc_max = GameState.npc_bet_this_round + GameState.npc_stack
		
		if npc_max > min_raise:
			var raise_amount = randi_range(min_raise, mini(min_raise * 2, npc_max))
			GameState.npc_raise(raise_amount)
		else:
			# Can't raise, just call
			if GameState.current_bet == GameState.npc_bet_this_round:
				GameState.npc_check()
			else:
				GameState.npc_call()

# ============================================================================
# MATCH END
# ============================================================================

func _on_match_end() -> void:
	"""
	Handle match completion.
	Save chat history and prepare for transition.
	"""
	print("GameView: Match ended")
	
	# TODO: Save current chat conversation to history file
	# TODO: Show match summary screen
	
	# For now, GameState automatically returns to start screen after delay

# ============================================================================
# CLEANUP
# ============================================================================

func _exit_tree() -> void:
	"""Clean up when leaving GameView."""
	print("GameView: Cleaning up")
	
	# Reset GameState
	if GameState:
		GameState.reset()
	
	# Reset components
	if board:
		board.reset()
	
	if chat:
		chat.reset()
	
	# Stop timer
	if npc_ai_timer:
		npc_ai_timer.stop()
