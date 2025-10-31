extends RefCounted
class_name PokerEngine

# PokerEngine.gd - Authoritative Poker State Machine
# 
# This class is the single source of truth for poker game logic.
# It operates as a state machine that:
# - Drives game progression through well-defined states
# - Emits signals when UI action is required
# - Pauses execution waiting for UI to complete
# - Resumes when UI calls resume() method
# 
# The engine is completely UI-agnostic. All visual display and timing
# is handled by GameView through a handshake protocol.
#
# State Flow:
# PRE_HAND → DEALING → BETTING → AWAITING_INPUT (pause) → BETTING → ...
# → EVALUATING → POST_HAND → PRE_HAND (next hand) or GAME_OVER

# Preload dependencies
const DeckClass = preload("res://scripts/game_view/Deck.gd")
const HandEvaluatorClass = preload("res://scripts/game_view/HandEvaluator.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal hand_started(player_stack: int, npc_stack: int)
signal pot_updated(new_total: int)
signal player_turn(valid_actions: Dictionary)
signal npc_turn(decision_context: Dictionary)
signal community_cards_dealt(phase: String, cards: Array)
signal player_cards_dealt(cards: Array)
signal showdown(player_hand: Array, npc_hand: Array, result: Dictionary)
signal hand_ended(winner_is_player: bool, pot_amount: int)

# ============================================================================
# ENUMS
# ============================================================================

enum EngineState {
	PRE_HAND,        # Check for match end, post blinds, prepare dealing
	DEALING,         # Deal cards (hole cards, flop, turn, or river)
	BETTING,         # Process betting round logic
	AWAITING_INPUT,  # Paused, waiting for player/NPC action
	EVALUATING,      # Showdown or fold - determine winner
	POST_HAND,       # Award pot, clean up, prepare next hand
	GAME_OVER        # Terminal state - match ended
}

enum HandPhase {
	PRE_FLOP,
	FLOP,
	TURN,
	RIVER,
	SHOWDOWN
}

# ============================================================================
# STATE PROPERTIES
# ============================================================================

# State machine control
var current_state: EngineState = EngineState.PRE_HAND
var is_paused: bool = false

var deck: DeckClass = null
var pot: int = 0
var current_bet: int = 0
var hand_phase: HandPhase = HandPhase.PRE_FLOP

var community_cards: Array = []

# Player state
var player_stack: int = 0
var player_hand: Array = []
var player_bet_this_round: int = 0
var player_has_acted: bool = false

# NPC state
var npc_stack: int = 0
var npc_hand: Array = []
var npc_bet_this_round: int = 0
var npc_has_acted: bool = false

# Dealer tracking (alternates each hand)
var dealer_is_player: bool = false

# Blinds
const SMALL_BLIND = 10
const BIG_BLIND = 20

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(p_stack: int, n_stack: int, p_is_dealer: bool = false):
	"""
	Constructor - initialize a new poker engine for a match.
	
	Args:
		p_stack: Player's starting stack
		n_stack: NPC's starting stack
		p_is_dealer: Whether player is dealer (for blind positioning)
	"""
	player_stack = p_stack
	npc_stack = n_stack
	dealer_is_player = p_is_dealer
	
	print("PokerEngine: Initialized with stacks - Player: ", player_stack, ", NPC: ", npc_stack)

func start_new_hand() -> void:
	"""
	Start a new hand - initialize state machine.
	This is the main entry point to begin a hand.
	"""
	print("PokerEngine: Starting new hand")
	
	# Reset state machine
	current_state = EngineState.PRE_HAND
	is_paused = false
	
	# Reset hand-specific state
	pot = 0
	current_bet = 0
	player_bet_this_round = 0
	npc_bet_this_round = 0
	player_has_acted = false
	npc_has_acted = false
	hand_phase = HandPhase.PRE_FLOP
	community_cards.clear()
	player_hand.clear()
	npc_hand.clear()
	
	# Create and shuffle deck
	deck = DeckClass.new()
	deck.reset_and_shuffle()
	
	# Start state machine
	_advance_state_machine()

# ============================================================================
# STATE MACHINE CONTROL
# ============================================================================

func resume() -> void:
	"""
	Resume state machine execution after UI pause.
	Called by GameView after UI animations/timing complete.
	
	This is the core of the handshake protocol. The engine will pause
	after emitting certain signals (like cards_dealt), and GameView must
	call resume() after displaying the UI to continue the game flow.
	"""
	if not is_paused:
		print("PokerEngine Warning: resume() called but not paused")
		return
	
	print("PokerEngine: Resuming from pause")
	is_paused = false
	_advance_state_machine()

func _pause_for_ui() -> void:
	"""
	Pause state machine to wait for UI.
	State machine will not advance until resume() is called.
	"""
	print("PokerEngine: Pausing for UI")
	is_paused = true

func _advance_state_machine() -> void:
	"""
	Main state machine loop.
	Continues executing states until paused or game over.
	
	This loop is the heart of the state machine. It will keep transitioning
	between states automatically until:
	1. It reaches a pause point (waiting for UI)
	2. It reaches AWAITING_INPUT (waiting for player/NPC action)
	3. It reaches POST_HAND (hand ended, waiting for start_new_hand())
	4. It reaches GAME_OVER (match ended)
	"""
	while not is_paused and current_state != EngineState.GAME_OVER and current_state != EngineState.AWAITING_INPUT and current_state != EngineState.POST_HAND:
		match current_state:
			EngineState.PRE_HAND:
				_state_pre_hand()
			EngineState.DEALING:
				_state_dealing()
			EngineState.BETTING:
				_state_betting()
			EngineState.AWAITING_INPUT:
				# This state should not be reached in the loop anymore
				# The loop condition now prevents this
				print("PokerEngine Error: Should not reach AWAITING_INPUT in loop")
				break
			EngineState.EVALUATING:
				_state_evaluating()
			EngineState.POST_HAND:
				_state_post_hand()
			EngineState.GAME_OVER:
				# Terminal state
				break
				break

# ============================================================================
# STATE IMPLEMENTATIONS
# ============================================================================

func _state_pre_hand() -> void:
	"""
	PRE_HAND state: Post blinds, check for match end, prepare dealing.
	"""
	print("PokerEngine: State PRE_HAND")
	
	# Post blinds first
	_post_blinds()
	
	# Emit hand started signal
	hand_started.emit(player_stack, npc_stack)
	
	# Check for game over AFTER blinds (in case someone went all-in on blinds and lost)
	if player_stack <= 0:
		print("PokerEngine: Player eliminated - Game Over")
		current_state = EngineState.GAME_OVER
		hand_ended.emit(false, pot)  # NPC won - award pot
		npc_stack += pot
		pot = 0
		return
	
	if npc_stack <= 0:
		print("PokerEngine: NPC eliminated - Game Over")
		current_state = EngineState.GAME_OVER
		hand_ended.emit(true, pot)  # Player won - award pot
		player_stack += pot
		pot = 0
		return
	
	# Transition to dealing
	current_state = EngineState.DEALING

func _state_dealing() -> void:
	"""
	DEALING state: Deal appropriate cards based on hand phase.
	"""
	print("PokerEngine: State DEALING - Phase: ", HandPhase.keys()[hand_phase])
	
	match hand_phase:
		HandPhase.PRE_FLOP:
			# Deal hole cards
			player_hand = deck.deal(2)
			npc_hand = deck.deal(2)
			print("PokerEngine: Dealt hole cards")
			player_cards_dealt.emit(player_hand)
			# Pause for UI to display cards
			_pause_for_ui()
		
		HandPhase.FLOP:
			# Deal flop
			deck.deal_one()  # Burn card
			var flop = deck.deal(3)
			community_cards.append_array(flop)
			print("PokerEngine: Dealt flop")
			community_cards_dealt.emit("flop", community_cards)
			_pause_for_ui()
		
		HandPhase.TURN:
			# Deal turn
			deck.deal_one()  # Burn card
			var turn = deck.deal_one()
			community_cards.append(turn)
			print("PokerEngine: Dealt turn")
			community_cards_dealt.emit("turn", community_cards)
			_pause_for_ui()
		
		HandPhase.RIVER:
			# Deal river
			deck.deal_one()  # Burn card
			var river = deck.deal_one()
			community_cards.append(river)
			print("PokerEngine: Dealt river")
			community_cards_dealt.emit("river", community_cards)
			_pause_for_ui()
		
		HandPhase.SHOWDOWN:
			# Should not deal in showdown
			print("PokerEngine Error: DEALING state in SHOWDOWN phase")
			current_state = EngineState.EVALUATING
			return
	
	# After dealing, move to betting (will execute after resume)
	current_state = EngineState.BETTING

func _state_betting() -> void:
	"""
	BETTING state: Check if betting round is complete, otherwise trigger next action.
	
	This state determines:
	1. Is the betting round complete? (both acted, bets match, or all-in)
	2. If not, whose turn is it?
	3. Emit appropriate signal and pause for input
	
	Special handling for all-in scenarios where remaining cards auto-deal.
	"""
	print("PokerEngine: State BETTING")
	
	# Check if both players are all-in
	if player_stack == 0 and npc_stack == 0:
		print("PokerEngine: Both all-in, auto-dealing to showdown")
		_auto_deal_to_showdown()
		return
	
	# Check if one player is all-in and action is complete
	if (player_stack == 0 or npc_stack == 0) and _both_players_acted():
		print("PokerEngine: All-in with action complete, advancing")
		_complete_betting_round()
		return
	
	# Check if betting round is complete (both acted and bets match)
	if _both_players_acted() and player_bet_this_round == npc_bet_this_round:
		print("PokerEngine: Betting round complete")
		_complete_betting_round()
		return
	
	# Check if player is all-in and has already acted - other player can't extract more chips
	if player_stack == 0 and player_has_acted:
		print("PokerEngine: Player all-in and acted, completing round")
		_complete_betting_round()
		return
	
	# Check if NPC is all-in and has already acted - other player can't extract more chips
	if npc_stack == 0 and npc_has_acted:
		print("PokerEngine: NPC all-in and acted, completing round")
		_complete_betting_round()
		return
	
	# Determine whose turn it is
	var player_should_act = _player_should_act()
	
	if player_should_act:
		# Player's turn
		var valid_actions = get_valid_actions()
		print("PokerEngine: Player's turn - ", valid_actions)
		player_turn.emit(valid_actions)
		current_state = EngineState.AWAITING_INPUT
		# Don't pause - we're waiting for submit_action() to be called
		return
	else:
		# NPC's turn
		var context = get_decision_context()
		print("PokerEngine: NPC's turn")
		npc_turn.emit(context)
		current_state = EngineState.AWAITING_INPUT
		# Don't pause - we're waiting for submit_action() to be called
		return

func _state_evaluating() -> void:
	"""
	EVALUATING state: Determine winner (showdown or fold).
	"""
	print("PokerEngine: State EVALUATING")
	
	# This should only be reached via showdown
	# (folds are handled immediately in submit_action)
	_showdown()
	
	# Move to post-hand
	current_state = EngineState.POST_HAND

func _state_post_hand() -> void:
	"""
	POST_HAND state: Clean up, prepare for next hand.
	This is a terminal state - GameView will call start_new_hand() when ready.
	"""
	print("PokerEngine: State POST_HAND - waiting for start_new_hand()")
	
	# Alternate dealer
	var old_dealer = "Player" if dealer_is_player else "NPC"
	dealer_is_player = not dealer_is_player
	var new_dealer = "Player" if dealer_is_player else "NPC"
	print("PokerEngine: Dealer alternated from ", old_dealer, " to ", new_dealer)
	
	# Don't auto-transition - wait for start_new_hand() to be called
	# This allows GameView to control timing (show messages, delays, etc.)

func _player_should_act() -> bool:
	"""
	Determine if player should act next.
	Pre-flop: small blind (dealer) acts first.
	Post-flop: non-dealer acts first.
	"""
	if hand_phase == HandPhase.PRE_FLOP:
		# Small blind (dealer) acts first
		if dealer_is_player:
			return not player_has_acted or (npc_has_acted and player_bet_this_round != npc_bet_this_round)
		else:
			return npc_has_acted and player_bet_this_round != npc_bet_this_round
	else:
		# Post-flop: non-dealer acts first
		if dealer_is_player:
			# NPC is first to act post-flop
			return npc_has_acted and player_bet_this_round != npc_bet_this_round
		else:
			# Player is first to act post-flop
			return not player_has_acted or (npc_has_acted and player_bet_this_round != npc_bet_this_round)

func _auto_deal_to_showdown() -> void:
	"""
	Auto-deal remaining community cards when both players are all-in.
	"""
	print("PokerEngine: Auto-dealing to showdown")
	
	while hand_phase < HandPhase.RIVER:
		match hand_phase:
			HandPhase.PRE_FLOP:
				# Deal flop
				deck.deal_one()
				var flop = deck.deal(3)
				community_cards.append_array(flop)
				community_cards_dealt.emit("flop", community_cards)
				hand_phase = HandPhase.FLOP
			
			HandPhase.FLOP:
				# Deal turn
				deck.deal_one()
				var turn = deck.deal_one()
				community_cards.append(turn)
				community_cards_dealt.emit("turn", community_cards)
				hand_phase = HandPhase.TURN
			
			HandPhase.TURN:
				# Deal river
				deck.deal_one()
				var river = deck.deal_one()
				community_cards.append(river)
				community_cards_dealt.emit("river", community_cards)
				hand_phase = HandPhase.RIVER
	
	# Go to showdown
	current_state = EngineState.EVALUATING

func _complete_betting_round() -> void:
	"""
	Complete the current betting round and advance to next phase.
	"""
	print("PokerEngine: Completing betting round")
	
	# Reset per-round tracking
	player_bet_this_round = 0
	npc_bet_this_round = 0
	current_bet = 0
	player_has_acted = false
	npc_has_acted = false
	
	# Advance phase
	match hand_phase:
		HandPhase.PRE_FLOP:
			hand_phase = HandPhase.FLOP
			current_state = EngineState.DEALING
		
		HandPhase.FLOP:
			hand_phase = HandPhase.TURN
			current_state = EngineState.DEALING
		
		HandPhase.TURN:
			hand_phase = HandPhase.RIVER
			current_state = EngineState.DEALING
		
		HandPhase.RIVER:
			# Go to showdown
			hand_phase = HandPhase.SHOWDOWN
			current_state = EngineState.EVALUATING

# ============================================================================
# BLIND POSTING
# ============================================================================

func _post_blinds() -> void:
	"""
	Post small blind and big blind.
	In heads-up: dealer posts small blind, other player posts big blind.
	"""
	if dealer_is_player:
		# Player is dealer/small blind
		var sb = min(SMALL_BLIND, player_stack)
		var bb = min(BIG_BLIND, npc_stack)
		
		player_stack -= sb
		player_bet_this_round = sb
		
		npc_stack -= bb
		npc_bet_this_round = bb
		
		pot = sb + bb
		current_bet = bb
		
		print("PokerEngine: Blinds posted - Player (SB): ", sb, ", NPC (BB): ", bb)
	else:
		# NPC is dealer/small blind
		var sb = min(SMALL_BLIND, npc_stack)
		var bb = min(BIG_BLIND, player_stack)
		
		npc_stack -= sb
		npc_bet_this_round = sb
		
		player_stack -= bb
		player_bet_this_round = bb
		
		pot = sb + bb
		current_bet = bb
		
		print("PokerEngine: Blinds posted - NPC (SB): ", sb, ", Player (BB): ", bb)
	
	pot_updated.emit(pot)



# ============================================================================
# PLAYER ACTIONS
# ============================================================================

func submit_action(is_player: bool, action: String, amount: int = 0) -> void:
	"""
	Primary input method for submitting player or NPC actions.
	Processes the action, updates state, and resumes state machine.
	
	This is called by GameView when:
	- Player clicks a betting button
	- NPC_AI makes a decision
	
	The function validates the state, processes the action, and resumes
	the state machine to continue game flow.
	
	Args:
		is_player: true if player action, false if NPC
		action: "fold", "check", "call", "raise", "bet"
		amount: bet/raise amount (only used for raise/bet)
	"""
	print("PokerEngine: Action submitted - ", "Player" if is_player else "NPC", ": ", action, " (", amount, ")")
	
	# Validate state
	if current_state != EngineState.AWAITING_INPUT:
		print("PokerEngine Error: submit_action called in wrong state: ", EngineState.keys()[current_state])
		return
	
	# Process action
	match action:
		"fold":
			_handle_fold(is_player)
			# Fold ends the hand immediately - state is now POST_HAND
			# POST_HAND is a terminal state, no need to call resume()
			return
		"check":
			_handle_check(is_player)
		"call":
			_handle_call(is_player)
		"raise", "bet":
			_handle_raise(is_player, amount)
		_:
			print("PokerEngine Error: Unknown action - ", action)
			return
	
	# Return to betting state and resume
	current_state = EngineState.BETTING
	_advance_state_machine()  # Continue state machine to process BETTING state

func _handle_fold(is_player: bool) -> void:
	"""Handle a fold action - immediately ends hand."""
	if is_player:
		print("PokerEngine: Player folds")
		player_has_acted = true
		# NPC wins pot
		npc_stack += pot
		var pot_amount = pot
		pot = 0
		pot_updated.emit(pot)
		
		# Emit fold win signal and end hand
		hand_ended.emit(false, pot_amount)
		
		# Go to post-hand and execute it
		current_state = EngineState.POST_HAND
		_state_post_hand()  # Directly call to alternate dealer
	else:
		print("PokerEngine: NPC folds")
		npc_has_acted = true
		# Player wins pot
		player_stack += pot
		var pot_amount = pot
		pot = 0
		pot_updated.emit(pot)
		
		# Emit fold win signal and end hand
		hand_ended.emit(true, pot_amount)
		
		# Go to post-hand and execute it
		current_state = EngineState.POST_HAND
		_state_post_hand()  # Directly call to alternate dealer

func _handle_check(is_player: bool) -> void:
	"""Handle a check action."""
	print("PokerEngine: ", "Player" if is_player else "NPC", " checks")
	
	# Mark player as having acted
	if is_player:
		player_has_acted = true
	else:
		npc_has_acted = true

func _handle_call(is_player: bool) -> void:
	"""Handle a call action."""
	if is_player:
		var amount_to_call = current_bet - player_bet_this_round
		amount_to_call = min(amount_to_call, player_stack)
		
		player_stack -= amount_to_call
		player_bet_this_round += amount_to_call
		pot += amount_to_call
		player_has_acted = true
		
		print("PokerEngine: Player calls ", amount_to_call)
		
		# Check if player is all-in
		if player_stack == 0:
			print("PokerEngine: Player is all-in!")
	else:
		var amount_to_call = current_bet - npc_bet_this_round
		amount_to_call = min(amount_to_call, npc_stack)
		
		npc_stack -= amount_to_call
		npc_bet_this_round += amount_to_call
		pot += amount_to_call
		npc_has_acted = true
		
		print("PokerEngine: NPC calls ", amount_to_call)
		
		# Check if NPC is all-in
		if npc_stack == 0:
			print("PokerEngine: NPC is all-in!")
	
	pot_updated.emit(pot)

func _handle_raise(is_player: bool, total_bet: int) -> void:
	"""Handle a raise/bet action."""
	if is_player:
		var additional = total_bet - player_bet_this_round
		additional = min(additional, player_stack)
		
		player_stack -= additional
		player_bet_this_round = player_bet_this_round + additional
		pot += additional
		current_bet = player_bet_this_round
		player_has_acted = true
		
		# Reset NPC acted flag since they need to respond to the raise
		npc_has_acted = false
		
		print("PokerEngine: Player raises to ", player_bet_this_round, " (additional: ", additional, ")")
		
		# Check if player is all-in
		if player_stack == 0:
			print("PokerEngine: Player is all-in!")
	else:
		var additional = total_bet - npc_bet_this_round
		additional = min(additional, npc_stack)
		
		npc_stack -= additional
		npc_bet_this_round = npc_bet_this_round + additional
		pot += additional
		current_bet = npc_bet_this_round
		npc_has_acted = true
		
		# Reset player acted flag since they need to respond to the raise
		player_has_acted = false
		
		print("PokerEngine: NPC raises to ", npc_bet_this_round, " (additional: ", additional, ")")
		
		# Check if NPC is all-in
		if npc_stack == 0:
			print("PokerEngine: NPC is all-in!")
	
	pot_updated.emit(pot)

# ============================================================================
# SHOWDOWN
# ============================================================================

func _showdown() -> void:
	"""
	Evaluate hands and determine winner.
	Emit showdown signal and pause for UI.
	"""
	print("PokerEngine: Showdown!")
	hand_phase = HandPhase.SHOWDOWN
	
	# Evaluate both hands
	var player_result = HandEvaluatorClass.evaluate_hand(player_hand, community_cards)
	var npc_result = HandEvaluatorClass.evaluate_hand(npc_hand, community_cards)
	
	print("PokerEngine: Player has ", player_result.description)
	print("PokerEngine: NPC has ", npc_result.description)
	
	# Compare hands
	var comparison = HandEvaluatorClass.compare_hands(player_result, npc_result)
	
	var result = {
		"player_hand_description": player_result.description,
		"npc_hand_description": npc_result.description,
		"player_won": false,
		"tied": false,
		"pot_amount": pot
	}
	
	if comparison > 0:
		# Player wins
		print("PokerEngine: Player wins with ", player_result.description)
		player_stack += pot
		result.player_won = true
	elif comparison < 0:
		# NPC wins
		print("PokerEngine: NPC wins with ", npc_result.description)
		npc_stack += pot
		result.player_won = false
	else:
		# Tie - split pot
		print("PokerEngine: Tie - pot split")
		var half_pot = floori(pot / 2.0)  # Integer division with floor
		player_stack += half_pot
		npc_stack += (pot - half_pot)  # Give odd chip to NPC
		result.tied = true
	
	# Clear pot
	var pot_amount = pot
	pot = 0
	pot_updated.emit(pot)
	
	# Emit showdown signal
	showdown.emit(player_hand, npc_hand, result)
	
	# Emit hand ended
	hand_ended.emit(result.player_won, pot_amount)
	
	# Pause for UI
	_pause_for_ui()

# ============================================================================
# BLIND POSTING (Moved from earlier in file)
# ============================================================================

func get_valid_actions() -> Dictionary:
	"""
	Returns dictionary of valid actions for the current player.
	Used to configure UI controls.
	"""
	var can_check = (current_bet == player_bet_this_round)
	var call_amount = current_bet - player_bet_this_round
	var min_raise = current_bet + BIG_BLIND
	var max_raise = player_bet_this_round + player_stack
	
	return {
		"can_check": can_check,
		"call_amount": call_amount,
		"min_raise": min_raise,
		"max_raise": max_raise,
		"can_raise": (player_stack > call_amount)
	}

func get_decision_context() -> Dictionary:
	"""
	Package all non-secret game state for NPC AI decision-making.
	Does not include NPC's hole cards (AI doesn't cheat).
	"""
	return {
		"pot": pot,
		"current_bet": current_bet,
		"npc_bet_this_round": npc_bet_this_round,
		"npc_stack": npc_stack,
		"player_bet_this_round": player_bet_this_round,
		"hand_phase": hand_phase,
		"community_cards": community_cards,
		"npc_hand": npc_hand,  # AI needs its own cards
		"call_amount": current_bet - npc_bet_this_round,
		"min_raise": current_bet + BIG_BLIND,
		"max_raise": npc_bet_this_round + npc_stack
	}

func _both_players_acted() -> bool:
	"""
	Check if both players have acted and bets are matched.
	This determines if the betting round is complete.
	"""
	return player_has_acted and npc_has_acted and (player_bet_this_round == npc_bet_this_round)

func get_player_stack() -> int:
	"""Get current player stack."""
	return player_stack

func get_npc_stack() -> int:
	"""Get current NPC stack."""
	return npc_stack

func get_pot() -> int:
	"""Get current pot size."""
	return pot
