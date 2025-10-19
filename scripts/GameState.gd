extends Node

# GameState.gd - Autoload Singleton for Poker Game State Management
# Manages the poker state machine and coordinates turn-based gameplay
# This is separate from GameManager which handles persistence and scene transitions

# Game state enum - represents the current phase of gameplay
enum State {
	IDLE,              # No active match
	MATCH_START,       # Match initialization phase
	HAND_START,        # New hand beginning (dealing cards, posting blinds)
	PLAYER_TURN,       # Player's turn to act (betting controls enabled)
	NPC_TURN,          # NPC's turn to act (betting controls disabled)
	BUSY,              # Processing (LLM response, animations, etc.)
	SHOWDOWN,          # Revealing cards and determining winner
	HAND_END,          # Hand complete, awarding pot
	MATCH_END          # Match over (one player out of chips)
}

# Signals
signal state_changed(new_state: State)
signal player_stack_changed(new_stack: int)
signal npc_stack_changed(new_stack: int)
signal pot_changed(new_pot: int)
signal community_cards_dealt(cards: Array)
signal player_cards_dealt(cards: Array)

# Current state
var current_state: State = State.IDLE

# Match data
var player_stack: int = 0
var npc_stack: int = 0
var pot: int = 0
var current_bet: int = 0  # Current bet to call in this round
var player_bet_this_round: int = 0  # What player has bet in current round
var npc_bet_this_round: int = 0  # What NPC has bet in current round

# Card data (placeholder - will be managed by PokerEngine later)
var community_cards: Array = []
var player_cards: Array = []
var npc_cards: Array = []

# Betting round tracking
enum BettingRound {
	PRE_FLOP,
	FLOP,
	TURN,
	RIVER
}

var current_betting_round: BettingRound = BettingRound.PRE_FLOP

func _ready():
	print("GameState: Initialized as autoload singleton")

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

func set_state(new_state: State) -> void:
	"""Change the game state and emit signal."""
	if current_state == new_state:
		return
	
	var old_state = current_state
	current_state = new_state
	
	print("GameState: State changed from ", State.keys()[old_state], " to ", State.keys()[new_state])
	state_changed.emit(new_state)

func get_state() -> State:
	"""Get the current game state."""
	return current_state

func is_player_turn() -> bool:
	"""Check if it's currently the player's turn."""
	return current_state == State.PLAYER_TURN

func is_npc_turn() -> bool:
	"""Check if it's currently the NPC's turn."""
	return current_state == State.NPC_TURN

# ============================================================================
# MATCH INITIALIZATION
# ============================================================================

func start_new_match(starting_credits: int = 1000) -> void:
	"""
	Initialize a new match with fresh stacks.
	Called by GameView when a match begins.
	"""
	print("GameState: Starting new match with ", starting_credits, " credits each")
	
	player_stack = starting_credits
	npc_stack = starting_credits
	pot = 0
	current_bet = 0
	player_bet_this_round = 0
	npc_bet_this_round = 0
	
	community_cards.clear()
	player_cards.clear()
	npc_cards.clear()
	
	current_betting_round = BettingRound.PRE_FLOP
	
	# Emit stack updates
	player_stack_changed.emit(player_stack)
	npc_stack_changed.emit(npc_stack)
	pot_changed.emit(pot)
	
	set_state(State.MATCH_START)
	
	# Auto-start first hand
	start_new_hand()

func start_new_hand() -> void:
	"""
	Start a new hand (reset for next round).
	Posts blinds and deals cards.
	"""
	print("GameState: Starting new hand")
	
	pot = 0
	current_bet = 0
	player_bet_this_round = 0
	npc_bet_this_round = 0
	
	community_cards.clear()
	player_cards.clear()
	npc_cards.clear()
	
	current_betting_round = BettingRound.PRE_FLOP
	
	set_state(State.HAND_START)
	
	# Post blinds (placeholder - will be handled by PokerEngine)
	_post_blinds()
	
	# Deal cards (placeholder - will be handled by PokerEngine)
	_deal_hole_cards()
	
	# Start with player's turn (for MVP simplicity)
	# In real poker, big blind acts last pre-flop
	set_state(State.PLAYER_TURN)

func _post_blinds() -> void:
	"""
	Post blinds at the start of a hand.
	For MVP: Player is small blind (10), NPC is big blind (20).
	"""
	var small_blind = 10
	var big_blind = 20
	
	# Player posts small blind
	player_stack -= small_blind
	player_bet_this_round = small_blind
	pot += small_blind
	
	# NPC posts big blind
	npc_stack -= big_blind
	npc_bet_this_round = big_blind
	pot += big_blind
	current_bet = big_blind  # Player needs to call 20 (or raise)
	
	print("GameState: Blinds posted - Player: ", small_blind, " (SB), NPC: ", big_blind, " (BB)")
	print("GameState: Pot is now ", pot)
	
	player_stack_changed.emit(player_stack)
	npc_stack_changed.emit(npc_stack)
	pot_changed.emit(pot)

func _deal_hole_cards() -> void:
	"""
	Deal hole cards to both players (placeholder).
	Real implementation will use PokerEngine.
	"""
	# Placeholder: Just notify that cards were dealt
	# Real cards will be generated by PokerEngine
	player_cards = ["placeholder_card_1", "placeholder_card_2"]
	npc_cards = ["placeholder_card_1", "placeholder_card_2"]
	
	player_cards_dealt.emit(player_cards)
	print("GameState: Hole cards dealt")

# ============================================================================
# PLAYER ACTIONS
# ============================================================================

func player_fold() -> void:
	"""
	Player folds their hand.
	NPC wins the pot immediately.
	"""
	if not is_player_turn():
		print("GameState Warning: player_fold called but not player's turn")
		return
	
	print("GameState: Player folds")
	
	# Award pot to NPC
	npc_stack += pot
	npc_stack_changed.emit(npc_stack)
	pot = 0
	pot_changed.emit(pot)
	
	# End hand
	_end_hand(false)  # Player did not win

func player_check() -> void:
	"""
	Player checks (no bet to call).
	Only valid when current_bet == player_bet_this_round.
	"""
	if not is_player_turn():
		print("GameState Warning: player_check called but not player's turn")
		return
	
	if current_bet != player_bet_this_round:
		print("GameState Warning: Cannot check when there's a bet to call")
		return
	
	print("GameState: Player checks")
	
	# Pass action to NPC
	set_state(State.NPC_TURN)

func player_call() -> void:
	"""
	Player calls the current bet.
	Matches the NPC's bet amount.
	"""
	if not is_player_turn():
		print("GameState Warning: player_call called but not player's turn")
		return
	
	var amount_to_call = current_bet - player_bet_this_round
	
	if amount_to_call <= 0:
		print("GameState Warning: No bet to call")
		return
	
	if amount_to_call > player_stack:
		# All-in situation
		amount_to_call = player_stack
	
	print("GameState: Player calls ", amount_to_call)
	
	player_stack -= amount_to_call
	player_bet_this_round += amount_to_call
	pot += amount_to_call
	
	player_stack_changed.emit(player_stack)
	pot_changed.emit(pot)
	
	# Betting round complete (both matched)
	_complete_betting_round()

func player_raise(amount: int) -> void:
	"""
	Player raises to a specific amount.
	Amount is the total bet, not the raise increment.
	"""
	if not is_player_turn():
		print("GameState Warning: player_raise called but not player's turn")
		return
	
	var total_bet = amount
	var additional_chips = total_bet - player_bet_this_round
	
	if additional_chips > player_stack:
		# All-in
		additional_chips = player_stack
		total_bet = player_bet_this_round + additional_chips
	
	print("GameState: Player raises to ", total_bet, " (additional: ", additional_chips, ")")
	
	player_stack -= additional_chips
	player_bet_this_round = total_bet
	pot += additional_chips
	current_bet = total_bet  # NPC must now call or re-raise
	
	player_stack_changed.emit(player_stack)
	pot_changed.emit(pot)
	
	# Pass action to NPC
	set_state(State.NPC_TURN)

# ============================================================================
# NPC ACTIONS (Placeholder - will be called by NPC AI)
# ============================================================================

func npc_fold() -> void:
	"""
	NPC folds their hand.
	Player wins the pot immediately.
	"""
	if not is_npc_turn():
		print("GameState Warning: npc_fold called but not NPC's turn")
		return
	
	print("GameState: NPC folds")
	
	# Award pot to player
	player_stack += pot
	player_stack_changed.emit(player_stack)
	pot = 0
	pot_changed.emit(pot)
	
	# End hand
	_end_hand(true)  # Player won

func npc_check() -> void:
	"""NPC checks."""
	if not is_npc_turn():
		print("GameState Warning: npc_check called but not NPC's turn")
		return
	
	print("GameState: NPC checks")
	
	# Complete betting round (both checked or called)
	_complete_betting_round()

func npc_call() -> void:
	"""NPC calls the player's bet."""
	if not is_npc_turn():
		print("GameState Warning: npc_call called but not NPC's turn")
		return
	
	var amount_to_call = current_bet - npc_bet_this_round
	
	if amount_to_call > npc_stack:
		amount_to_call = npc_stack
	
	print("GameState: NPC calls ", amount_to_call)
	
	npc_stack -= amount_to_call
	npc_bet_this_round += amount_to_call
	pot += amount_to_call
	
	npc_stack_changed.emit(npc_stack)
	pot_changed.emit(pot)
	
	# Complete betting round
	_complete_betting_round()

func npc_raise(amount: int) -> void:
	"""NPC raises to a specific amount."""
	if not is_npc_turn():
		print("GameState Warning: npc_raise called but not NPC's turn")
		return
	
	var total_bet = amount
	var additional_chips = total_bet - npc_bet_this_round
	
	if additional_chips > npc_stack:
		additional_chips = npc_stack
		total_bet = npc_bet_this_round + additional_chips
	
	print("GameState: NPC raises to ", total_bet, " (additional: ", additional_chips, ")")
	
	npc_stack -= additional_chips
	npc_bet_this_round = total_bet
	pot += additional_chips
	current_bet = total_bet
	
	npc_stack_changed.emit(npc_stack)
	pot_changed.emit(pot)
	
	# Pass back to player
	set_state(State.PLAYER_TURN)

# ============================================================================
# BETTING ROUND PROGRESSION
# ============================================================================

func _complete_betting_round() -> void:
	"""
	Complete the current betting round and advance to the next.
	Called when both players have matched bets or checked.
	"""
	print("GameState: Betting round complete")
	
	# Reset per-round bet tracking
	player_bet_this_round = 0
	npc_bet_this_round = 0
	current_bet = 0
	
	# Advance to next betting round
	match current_betting_round:
		BettingRound.PRE_FLOP:
			_deal_flop()
			current_betting_round = BettingRound.FLOP
			set_state(State.PLAYER_TURN)
		
		BettingRound.FLOP:
			_deal_turn()
			current_betting_round = BettingRound.TURN
			set_state(State.PLAYER_TURN)
		
		BettingRound.TURN:
			_deal_river()
			current_betting_round = BettingRound.RIVER
			set_state(State.PLAYER_TURN)
		
		BettingRound.RIVER:
			# Go to showdown
			_showdown()

func _deal_flop() -> void:
	"""Deal the flop (3 community cards)."""
	print("GameState: Dealing flop")
	community_cards = ["flop1", "flop2", "flop3"]
	community_cards_dealt.emit(community_cards)

func _deal_turn() -> void:
	"""Deal the turn (4th community card)."""
	print("GameState: Dealing turn")
	community_cards.append("turn")
	community_cards_dealt.emit(community_cards)

func _deal_river() -> void:
	"""Deal the river (5th community card)."""
	print("GameState: Dealing river")
	community_cards.append("river")
	community_cards_dealt.emit(community_cards)

func _showdown() -> void:
	"""
	Showdown: Reveal cards and determine winner.
	Placeholder - will use PokerEngine for hand evaluation.
	"""
	print("GameState: Showdown!")
	set_state(State.SHOWDOWN)
	
	# Placeholder: Randomly determine winner for now
	var player_won = randi() % 2 == 0
	
	if player_won:
		print("GameState: Player wins the hand!")
		player_stack += pot
		player_stack_changed.emit(player_stack)
	else:
		print("GameState: NPC wins the hand!")
		npc_stack += pot
		npc_stack_changed.emit(npc_stack)
	
	pot = 0
	pot_changed.emit(pot)
	
	# End hand
	_end_hand(player_won)

func _end_hand(player_won: bool) -> void:
	"""
	End the current hand and check for match completion.
	"""
	print("GameState: Hand ended. Player won: ", player_won)
	set_state(State.HAND_END)
	
	# Check if either player is eliminated
	if player_stack <= 0:
		_end_match(false)  # Player lost the match
	elif npc_stack <= 0:
		_end_match(true)   # Player won the match
	else:
		# Start next hand after a brief delay
		await get_tree().create_timer(2.0).timeout
		start_new_hand()

func _end_match(player_won: bool) -> void:
	"""
	End the match when one player runs out of chips.
	"""
	print("GameState: Match ended. Player won: ", player_won)
	set_state(State.MATCH_END)
	
	# Record result in GameManager
	GameManager.record_match_result(player_won)
	
	# TODO: Show match summary screen
	# For now, just return to start screen after delay
	await get_tree().create_timer(3.0).timeout
	GameManager.return_to_start_screen()

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_min_raise() -> int:
	"""
	Get the minimum legal raise amount.
	Minimum raise is current_bet + big_blind (for MVP).
	"""
	var big_blind = 20
	return current_bet + big_blind

func get_max_raise() -> int:
	"""
	Get the maximum raise amount (all-in).
	Player can raise up to their full stack.
	"""
	return player_bet_this_round + player_stack

func can_check() -> bool:
	"""Check if player can check (no bet to call)."""
	return current_bet == player_bet_this_round

func get_call_amount() -> int:
	"""Get the amount needed to call."""
	return max(0, current_bet - player_bet_this_round)

func reset() -> void:
	"""Reset all state (for cleanup when leaving GameView)."""
	print("GameState: Resetting all state")
	current_state = State.IDLE
	player_stack = 0
	npc_stack = 0
	pot = 0
	current_bet = 0
	player_bet_this_round = 0
	npc_bet_this_round = 0
	community_cards.clear()
	player_cards.clear()
	npc_cards.clear()
	current_betting_round = BettingRound.PRE_FLOP
