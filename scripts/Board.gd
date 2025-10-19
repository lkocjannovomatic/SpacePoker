extends Control

# Board.gd - Poker table interface for GameView
# Displays cards, stacks, pot, and betting controls
# Manages player betting actions and state-based UI updates

# Signals
signal player_action_taken(action: String, amount: int)

# UI References - Information Display
@onready var player_stack_label = $VBoxContainer/InfoPanel/PlayerStack
@onready var npc_stack_label = $VBoxContainer/InfoPanel/NPCStack
@onready var pot_label = $VBoxContainer/InfoPanel/Pot
@onready var game_phase_label = $VBoxContainer/InfoPanel/GamePhase

# UI References - Card Display
@onready var player_card_1 = $VBoxContainer/CardsPanel/PlayerCards/Card1
@onready var player_card_2 = $VBoxContainer/CardsPanel/PlayerCards/Card2
@onready var npc_card_1 = $VBoxContainer/CardsPanel/NPCCards/Card1
@onready var npc_card_2 = $VBoxContainer/CardsPanel/NPCCards/Card2
@onready var community_cards_container = $VBoxContainer/CardsPanel/CommunityCards

# UI References - Betting Controls
@onready var fold_button = $VBoxContainer/BettingPanel/FoldButton
@onready var check_call_button = $VBoxContainer/BettingPanel/CheckCallButton
@onready var raise_button = $VBoxContainer/BettingPanel/RaiseButton
@onready var bet_slider = $VBoxContainer/BettingPanel/BetSlider

func _ready():
	print("Board: Initializing...")
	
	# Connect betting buttons
	fold_button.pressed.connect(_on_fold_pressed)
	check_call_button.pressed.connect(_on_check_call_pressed)
	raise_button.pressed.connect(_on_raise_pressed)
	
	# Initialize UI
	_set_betting_controls_enabled(false)

# ============================================================================
# INITIALIZATION
# ============================================================================

func init() -> void:
	"""Initialize the board for a new match."""
	print("Board: Initializing for new match")
	
	# Clear card displays
	_clear_cards()
	
	# Reset labels
	player_stack_label.text = "Player: 0"
	npc_stack_label.text = "NPC: 0"
	pot_label.text = "Pot: 0"
	game_phase_label.text = "Pre-Flop"
	
	# Disable controls initially
	_set_betting_controls_enabled(false)

# ============================================================================
# PUBLIC INTERFACE (Called by GameView)
# ============================================================================

func update_controls(valid_actions: Dictionary) -> void:
	"""
	Enable/disable betting controls based on valid actions from PokerEngine.
	"""
	_set_betting_controls_enabled(true)
	
	# Update check/call button
	if valid_actions.get("can_check", false):
		check_call_button.text = "Check"
	else:
		var call_amount = valid_actions.get("call_amount", 0)
		check_call_button.text = "Call (" + str(call_amount) + ")"
	
	# Update raise button and slider
	var can_raise = valid_actions.get("can_raise", false)
	var min_raise = valid_actions.get("min_raise", 0)
	var max_raise = valid_actions.get("max_raise", 0)
	
	raise_button.disabled = not can_raise
	bet_slider.editable = can_raise
	
	if can_raise:
		bet_slider.min_value = min_raise
		bet_slider.max_value = max_raise
		bet_slider.value = min_raise

func update_pot_label(amount: int) -> void:
	"""Update pot display."""
	pot_label.text = "Pot: " + str(amount)

func update_stack_labels(player_stack_val: int, npc_stack_val: int) -> void:
	"""Update player and NPC stack displays."""
	player_stack_label.text = "Player: " + str(player_stack_val)
	npc_stack_label.text = "NPC: " + str(npc_stack_val)

func display_community_cards(cards: Array) -> void:
	"""Display community cards."""
	print("Board: Displaying ", cards.size(), " community cards")
	
	# Clear existing community cards
	for child in community_cards_container.get_children():
		child.queue_free()
	
	# Display new cards
	for card in cards:
		var card_label = Label.new()
		card_label.text = card.to_short_string() if card.has_method("to_short_string") else str(card)
		card_label.add_theme_font_size_override("font_size", 16)
		community_cards_container.add_child(card_label)

func display_player_cards(cards: Array) -> void:
	"""Display player's hole cards."""
	print("Board: Displaying player cards")
	
	if cards.size() >= 1:
		player_card_1.text = cards[0].to_short_string() if cards[0].has_method("to_short_string") else str(cards[0])
	if cards.size() >= 2:
		player_card_2.text = cards[1].to_short_string() if cards[1].has_method("to_short_string") else str(cards[1])

func display_showdown(_player_hand: Array, npc_hand: Array, result: Dictionary) -> void:
	"""Display showdown results."""
	print("Board: Displaying showdown")
	
	# Show NPC cards
	if npc_hand.size() >= 1:
		npc_card_1.text = npc_hand[0].to_short_string() if npc_hand[0].has_method("to_short_string") else str(npc_hand[0])
	if npc_hand.size() >= 2:
		npc_card_2.text = npc_hand[1].to_short_string() if npc_hand[1].has_method("to_short_string") else str(npc_hand[1])
	
	# Update phase label with result
	var message = ""
	if result.get("tied", false):
		message = "Tie! Pot split"
	elif result.get("player_won", false):
		message = "You win! " + result.get("player_hand_description", "")
	else:
		message = "NPC wins! " + result.get("npc_hand_description", "")
	
	game_phase_label.text = message

# ============================================================================
# GAMESTATE SIGNAL HANDLERS (REMOVED - Now controlled by GameView)
# ============================================================================

# The following functions have been removed as they're no longer needed:
# - _on_game_state_changed
# - _on_player_stack_changed
# - _on_npc_stack_changed
# - _on_pot_changed
# - _on_community_cards_dealt
# - _on_player_cards_dealt
# These are now replaced by the public interface functions above

# ============================================================================
# BETTING CONTROLS
# ============================================================================

func _set_betting_controls_enabled(enabled: bool) -> void:
	"""Enable or disable all betting controls."""
	fold_button.disabled = not enabled
	check_call_button.disabled = not enabled
	raise_button.disabled = not enabled
	bet_slider.editable = enabled

func _on_fold_pressed() -> void:
	"""Handle fold button press."""
	print("Board: Player clicked Fold")
	player_action_taken.emit("fold", 0)

func _on_check_call_pressed() -> void:
	"""Handle check/call button press."""
	# Determine action based on button text
	if check_call_button.text.begins_with("Check"):
		print("Board: Player clicked Check")
		player_action_taken.emit("check", 0)
	else:
		# Extract call amount from button text (format: "Call (amount)")
		var amount_text = check_call_button.text.replace("Call (", "").replace(")", "")
		var call_amount = int(amount_text)
		print("Board: Player clicked Call (", call_amount, ")")
		player_action_taken.emit("call", call_amount)

func _on_raise_pressed() -> void:
	"""Handle raise button press."""
	var raise_amount = int(bet_slider.value)
	print("Board: Player clicked Raise to ", raise_amount)
	player_action_taken.emit("raise", raise_amount)

# ============================================================================
# UI HELPERS (Removed GameState-dependent functions)
# ============================================================================

func _clear_cards() -> void:
	"""Clear all card displays."""
	player_card_1.text = "?"
	player_card_2.text = "?"
	npc_card_1.text = "?"
	npc_card_2.text = "?"
	
	for child in community_cards_container.get_children():
		child.queue_free()

func reset() -> void:
	"""Reset board state (for cleanup when leaving match)."""
	print("Board: Resetting state")
	_clear_cards()
	_set_betting_controls_enabled(false)
	player_stack_label.text = "Player: 0"
	npc_stack_label.text = "NPC: 0"
	pot_label.text = "Pot: 0"
	game_phase_label.text = "Pre-Flop"
