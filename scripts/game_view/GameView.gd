extends Control

# GameView.gd - Main poker game view controller
# Orchestrates communication between PokerEngine, NPC_AI, Board, and Chat components
# Manages match initialization and game flow

# Preload classes
const PokerEngineClass = preload("res://scripts/game_view/PokerEngine.gd")
const NPC_AIClass = preload("res://scripts/game_view/NPC_AI.gd")

# Child component references
@onready var board = $HBoxContainer/BoardContainer/Board
@onready var chat = $HBoxContainer/ChatSidebar/Chat

# Poker components
var poker_engine: PokerEngineClass = null
var npc_ai: NPC_AIClass = null

# Current match data
var current_npc: Dictionary = {}

# Constants
const NPC_CHAT_DELAY = 0.3  # Delay before poker action after chat response
const STARTING_CREDITS = 1000

func _ready():
	print("GameView: Initializing...")
	
	# Connect to Board signals
	if board:
		board.player_action_taken.connect(_on_player_action_taken)
	
	# Initialize match
	_initialize_match()

# ============================================================================
# MATCH INITIALIZATION
# ============================================================================

func _initialize_match() -> void:
	"""
	Initialize the match with the selected NPC.
	Creates PokerEngine and NPC_AI instances.
	"""
	print("GameView: Initializing match")
	
	# Set GameState to IN_MATCH
	GameState.set_state(GameState.State.IN_MATCH)
	
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
	
	# Create PokerEngine
	poker_engine = PokerEngineClass.new(
		STARTING_CREDITS,
		STARTING_CREDITS,
		false  # NPC is dealer first hand
	)
	
	# Connect PokerEngine signals
	poker_engine.hand_started.connect(_on_hand_started)
	poker_engine.pot_updated.connect(_on_pot_updated)
	poker_engine.player_turn.connect(_on_player_turn)
	poker_engine.npc_turn.connect(_on_npc_turn)
	poker_engine.community_cards_dealt.connect(_on_community_cards_dealt)
	poker_engine.player_cards_dealt.connect(_on_player_cards_dealt)
	poker_engine.showdown.connect(_on_showdown)
	poker_engine.hand_ended.connect(_on_hand_ended)
	
	# Create NPC AI
	npc_ai = NPC_AIClass.new()
	add_child(npc_ai)
	
	# Initialize NPC AI with personality
	var personality = {
		"aggression": current_npc.get("aggression", 0.5),
		"bluffing": current_npc.get("bluffing", 0.5),
		"risk_aversion": current_npc.get("risk_aversion", 0.5)
	}
	npc_ai.initialize(personality)
	
	# Connect NPC AI signals
	npc_ai.action_chosen.connect(_on_npc_action_chosen)
	
	# Start background music
	AudioManager.play_background_music()
	
	# Start first hand
	poker_engine.start_new_hand()

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
	Forward to PokerEngine.
	"""
	print("GameView: Player action - ", action, " (", amount, ")")
	
	# Disable controls immediately to prevent double-clicks
	if board:
		board.set_betting_controls_enabled(false)
	
	if poker_engine:
		poker_engine.submit_action(true, action, amount)

# ============================================================================
# POKER ENGINE SIGNAL HANDLERS
# ============================================================================

func _on_hand_started(player_stack_val: int, npc_stack_val: int) -> void:
	"""Handle hand start from PokerEngine."""
	print("GameView: Hand started - Player: ", player_stack_val, ", NPC: ", npc_stack_val)
	
	# Update Board displays
	if board:
		board.update_stack_labels(player_stack_val, npc_stack_val)

func _on_pot_updated(new_pot: int) -> void:
	"""Handle pot update from PokerEngine."""
	if board:
		board.update_pot_label(new_pot)

func _on_player_turn(valid_actions: Dictionary) -> void:
	"""Handle player turn from PokerEngine."""
	print("GameView: Player's turn")
	
	# Play turn notification sound
	AudioManager.play_turn_notify()
	
	# Update GameState for UI components (like Chat)
	GameState.set_state(GameState.State.PLAYER_TURN)
	
	# Show betting controls and update them
	if board:
		board.show_betting_controls()
		board.update_controls(valid_actions)

func _on_npc_turn(decision_context: Dictionary) -> void:
	"""Handle NPC turn from PokerEngine."""
	print("GameView: NPC's turn - delegating to NPC_AI")
	
	# Update GameState for UI components (like Chat)
	GameState.set_state(GameState.State.NPC_TURN)
	
	# Hide betting controls during NPC's turn
	if board:
		board.hide_betting_controls()
	
	# Check if chat has pending response
	if chat and chat.has_pending_response():
		var response = chat.get_pending_response()
		chat.display_npc_message(response)
		
		# Brief delay before poker action
		await get_tree().create_timer(NPC_CHAT_DELAY).timeout
	
	# Trigger NPC AI decision
	if npc_ai:
		npc_ai.make_decision(decision_context)

func _on_community_cards_dealt(phase: String, cards: Array) -> void:
	"""Handle community cards being dealt."""
	print("GameView: Community cards dealt - ", phase)
	
	# Play card deal sound
	AudioManager.play_card_deal()
	
	if board:
		board.display_community_cards(cards)

func _on_player_cards_dealt(cards: Array) -> void:
	"""Handle player cards being dealt."""
	print("GameView: Player cards dealt")
	
	# Play card deal sound
	AudioManager.play_card_deal()
	
	if board:
		board.display_player_cards(cards)

func _on_showdown(player_hand: Array, npc_hand: Array, result: Dictionary) -> void:
	"""Handle showdown."""
	print("GameView: Showdown - ", result)
	
	# Play card flip sound for reveal
	AudioManager.play_card_flip()
	
	if board:
		board.display_showdown(player_hand, npc_hand, result)

func _on_hand_ended(winner_is_player: bool, pot_amount: int) -> void:
	"""Handle hand end."""
	print("GameView: Hand ended - Winner: ", "Player" if winner_is_player else "NPC", " (pot: ", pot_amount, ")")
	
	# Play winner sound and chips collect sound
	AudioManager.play_winner()
	AudioManager.play_chips_collect()
	
	# Update stack displays
	if board and poker_engine:
		board.update_stack_labels(poker_engine.get_player_stack(), poker_engine.get_npc_stack())
	
	# Check if match is over
	if poker_engine:
		if poker_engine.get_player_stack() <= 0:
			_on_match_end(false)
		elif poker_engine.get_npc_stack() <= 0:
			_on_match_end(true)
		else:
			# Start next hand after delay
			await get_tree().create_timer(2.0).timeout
			poker_engine.start_new_hand()

func _on_npc_action_chosen(action: String, amount: int) -> void:
	"""Handle NPC AI action choice."""
	print("GameView: NPC chose action - ", action, " (", amount, ")")
	
	if poker_engine:
		poker_engine.submit_action(false, action, amount)

# ============================================================================
# MATCH END
# ============================================================================

func _on_match_end(player_won: bool) -> void:
	"""
	Handle match completion.
	Save chat history, record result, and return to start screen.
	"""
	print("GameView: Match ended - Player won: ", player_won)
	
	# Record result in GameManager
	GameManager.record_match_result(player_won)
	
	# TODO: Save current chat conversation to history file
	# TODO: Show match summary screen
	
	# Return to start screen after delay
	await get_tree().create_timer(3.0).timeout
	GameManager.return_to_start_screen()

# ============================================================================
# CLEANUP
# ============================================================================

func _exit_tree() -> void:
	"""Clean up when leaving GameView."""
	print("GameView: Cleaning up")
	
	# Reset GameState
	GameState.reset()
	
	# Clean up PokerEngine
	if poker_engine:
		poker_engine = null
	
	# Clean up NPC AI
	if npc_ai:
		npc_ai.queue_free()
		npc_ai = null
	
	# Reset components
	if board:
		board.reset()
	
	if chat:
		chat.reset()
