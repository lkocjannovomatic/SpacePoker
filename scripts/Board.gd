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
	
	# Connect to GameState signals
	if GameState:
		GameState.state_changed.connect(_on_game_state_changed)
		GameState.player_stack_changed.connect(_on_player_stack_changed)
		GameState.npc_stack_changed.connect(_on_npc_stack_changed)
		GameState.pot_changed.connect(_on_pot_changed)
		GameState.community_cards_dealt.connect(_on_community_cards_dealt)
		GameState.player_cards_dealt.connect(_on_player_cards_dealt)
	
	# Connect betting buttons
	fold_button.pressed.connect(_on_fold_pressed)
	check_call_button.pressed.connect(_on_check_call_pressed)
	raise_button.pressed.connect(_on_raise_pressed)
	
	# Initialize UI
	_update_betting_controls()

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
# GAMESTATE SIGNAL HANDLERS
# ============================================================================

func _on_game_state_changed(new_state: GameState.State) -> void:
	"""Handle game state changes to enable/disable controls."""
	print("Board: Game state changed to ", GameState.State.keys()[new_state])
	
	# Update betting controls based on state
	_update_betting_controls()
	
	# Update game phase label
	_update_game_phase_label(new_state)

func _on_player_stack_changed(new_stack: int) -> void:
	"""Update player stack display."""
	player_stack_label.text = "Player: " + str(new_stack)

func _on_npc_stack_changed(new_stack: int) -> void:
	"""Update NPC stack display."""
	npc_stack_label.text = "NPC: " + str(new_stack)

func _on_pot_changed(new_pot: int) -> void:
	"""Update pot display."""
	pot_label.text = "Pot: " + str(new_pot)

func _on_community_cards_dealt(cards: Array) -> void:
	"""Display community cards."""
	print("Board: Displaying ", cards.size(), " community cards")
	
	# Clear existing community cards
	for child in community_cards_container.get_children():
		child.queue_free()
	
	# Display new cards (placeholder text for MVP)
	for card in cards:
		var card_label = Label.new()
		card_label.text = str(card)
		card_label.add_theme_font_size_override("font_size", 16)
		community_cards_container.add_child(card_label)

func _on_player_cards_dealt(cards: Array) -> void:
	"""Display player's hole cards."""
	print("Board: Displaying player cards")
	
	if cards.size() >= 1:
		player_card_1.text = str(cards[0])
	if cards.size() >= 2:
		player_card_2.text = str(cards[1])

# ============================================================================
# BETTING CONTROLS
# ============================================================================

func _update_betting_controls() -> void:
	"""
	Update betting control states based on GameState.
	Enable/disable buttons and update check/call button text.
	"""
	var is_player_turn = GameState.is_player_turn()
	
	# Enable controls only during player's turn
	_set_betting_controls_enabled(is_player_turn)
	
	if is_player_turn:
		# Update check/call button text
		if GameState.can_check():
			check_call_button.text = "Check"
		else:
			var call_amount = GameState.get_call_amount()
			check_call_button.text = "Call (" + str(call_amount) + ")"
		
		# Update raise slider range
		var min_raise = GameState.get_min_raise()
		var max_raise = GameState.get_max_raise()
		
		bet_slider.min_value = min_raise
		bet_slider.max_value = max_raise
		bet_slider.value = min_raise
		
		# Disable raise if player can't raise
		raise_button.disabled = (max_raise <= min_raise or GameState.player_stack <= 0)

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
	if GameState.can_check():
		print("Board: Player clicked Check")
		player_action_taken.emit("check", 0)
	else:
		var call_amount = GameState.get_call_amount()
		print("Board: Player clicked Call (", call_amount, ")")
		player_action_taken.emit("call", call_amount)

func _on_raise_pressed() -> void:
	"""Handle raise button press."""
	var raise_amount = int(bet_slider.value)
	print("Board: Player clicked Raise to ", raise_amount)
	player_action_taken.emit("raise", raise_amount)

# ============================================================================
# UI HELPERS
# ============================================================================

func _update_game_phase_label(state: GameState.State) -> void:
	"""Update the game phase label based on current state."""
	match state:
		GameState.State.IDLE:
			game_phase_label.text = "Waiting..."
		GameState.State.MATCH_START:
			game_phase_label.text = "Match Starting"
		GameState.State.HAND_START:
			game_phase_label.text = "New Hand"
		GameState.State.PLAYER_TURN, GameState.State.NPC_TURN:
			# Show betting round
			match GameState.current_betting_round:
				GameState.BettingRound.PRE_FLOP:
					game_phase_label.text = "Pre-Flop"
				GameState.BettingRound.FLOP:
					game_phase_label.text = "Flop"
				GameState.BettingRound.TURN:
					game_phase_label.text = "Turn"
				GameState.BettingRound.RIVER:
					game_phase_label.text = "River"
		GameState.State.SHOWDOWN:
			game_phase_label.text = "Showdown"
		GameState.State.HAND_END:
			game_phase_label.text = "Hand Complete"
		GameState.State.MATCH_END:
			game_phase_label.text = "Match Over"
		GameState.State.BUSY:
			game_phase_label.text = "Processing..."

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
