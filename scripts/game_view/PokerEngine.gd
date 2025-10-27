extends RefCounted
class_name PokerEngine

# PokerEngine.gd - Non-visual core poker logic
# Manages hand state, rules, and game flow via signals
# Separate from UI - emits signals that GameView can connect to

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
	Start a new hand - reset state, shuffle, deal cards, post blinds.
	This is the main entry point to begin a hand.
	"""
	print("PokerEngine: Starting new hand")
	
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
	
	# Deal hole cards
	player_hand = deck.deal(2)
	npc_hand = deck.deal(2)
	
	print("PokerEngine: Dealt hole cards")
	player_cards_dealt.emit(player_hand)
	
	# Post blinds (dealer posts small blind in heads-up)
	_post_blinds()
	
	# Emit hand started signal
	hand_started.emit(player_stack, npc_stack)
	
	# Start first betting round
	_start_betting_round()

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
# BETTING ROUND MANAGEMENT
# ============================================================================

func _start_betting_round() -> void:
	"""
	Start a betting round.
	In pre-flop heads-up, small blind (dealer) acts first.
	In all other rounds, non-dealer acts first.
	"""
	print("PokerEngine: Starting betting round - ", HandPhase.keys()[hand_phase])
	
	# Determine who acts first
	if hand_phase == HandPhase.PRE_FLOP:
		# Pre-flop: Small blind (dealer) acts first
		if dealer_is_player:
			_trigger_player_turn()
		else:
			_trigger_npc_turn()
	else:
		# Post-flop: Non-dealer acts first
		if dealer_is_player:
			_trigger_npc_turn()
		else:
			_trigger_player_turn()

func _trigger_player_turn() -> void:
	"""Emit signal to notify that it's the player's turn."""
	var valid_actions = get_valid_actions()
	print("PokerEngine: Player's turn - ", valid_actions)
	player_turn.emit(valid_actions)

func _trigger_npc_turn() -> void:
	"""Emit signal to notify that it's the NPC's turn."""
	var context = get_decision_context()
	print("PokerEngine: NPC's turn")
	npc_turn.emit(context)

func _complete_betting_round() -> void:
	"""
	Complete the current betting round and advance to next phase.
	Called when both players have acted and bets are matched.
	"""
	print("PokerEngine: Betting round complete")
	
	# Reset per-round bet tracking
	player_bet_this_round = 0
	npc_bet_this_round = 0
	current_bet = 0
	player_has_acted = false
	npc_has_acted = false
	
	# Advance to next phase
	match hand_phase:
		HandPhase.PRE_FLOP:
			_deal_flop()
			hand_phase = HandPhase.FLOP
			_start_betting_round()
		
		HandPhase.FLOP:
			_deal_turn()
			hand_phase = HandPhase.TURN
			_start_betting_round()
		
		HandPhase.TURN:
			_deal_river()
			hand_phase = HandPhase.RIVER
			_start_betting_round()
		
		HandPhase.RIVER:
			# Go to showdown
			_showdown()

# ============================================================================
# COMMUNITY CARD DEALING
# ============================================================================

func _deal_flop() -> void:
	"""Deal the flop (3 community cards)."""
	deck.deal_one()  # Burn card
	var flop = deck.deal(3)
	community_cards.append_array(flop)
	
	print("PokerEngine: Dealt flop")
	community_cards_dealt.emit("flop", community_cards)

func _deal_turn() -> void:
	"""Deal the turn (4th community card)."""
	deck.deal_one()  # Burn card
	var turn = deck.deal_one()
	community_cards.append(turn)
	
	print("PokerEngine: Dealt turn")
	community_cards_dealt.emit("turn", community_cards)

func _deal_river() -> void:
	"""Deal the river (5th community card)."""
	deck.deal_one()  # Burn card
	var river = deck.deal_one()
	community_cards.append(river)
	
	print("PokerEngine: Dealt river")
	community_cards_dealt.emit("river", community_cards)

# ============================================================================
# PLAYER ACTIONS
# ============================================================================

func submit_action(is_player: bool, action: String, amount: int = 0) -> void:
	"""
	Primary input method for submitting player or NPC actions.
	Processes the action, updates state, and determines next step.
	
	Args:
		is_player: true if player action, false if NPC
		action: "fold", "check", "call", "raise", "bet"
		amount: bet/raise amount (only used for raise/bet)
	"""
	print("PokerEngine: Action submitted - ", "Player" if is_player else "NPC", ": ", action, " (", amount, ")")
	
	match action:
		"fold":
			_handle_fold(is_player)
		"check":
			_handle_check(is_player)
		"call":
			_handle_call(is_player)
		"raise", "bet":
			_handle_raise(is_player, amount)
		_:
			print("PokerEngine Error: Unknown action - ", action)

func _handle_fold(is_player: bool) -> void:
	"""Handle a fold action."""
	if is_player:
		print("PokerEngine: Player folds")
		player_has_acted = true
		# NPC wins pot
		npc_stack += pot
		_end_hand(false)
	else:
		print("PokerEngine: NPC folds")
		npc_has_acted = true
		# Player wins pot
		player_stack += pot
		_end_hand(true)

func _handle_check(is_player: bool) -> void:
	"""Handle a check action."""
	print("PokerEngine: ", "Player" if is_player else "NPC", " checks")
	
	# Mark player as having acted
	if is_player:
		player_has_acted = true
	else:
		npc_has_acted = true
	
	# Check if both players have acted
	if _both_players_acted():
		_complete_betting_round()
	else:
		# Pass to other player
		if is_player:
			_trigger_npc_turn()
		else:
			_trigger_player_turn()

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
	else:
		var amount_to_call = current_bet - npc_bet_this_round
		amount_to_call = min(amount_to_call, npc_stack)
		
		npc_stack -= amount_to_call
		npc_bet_this_round += amount_to_call
		pot += amount_to_call
		npc_has_acted = true
		
		print("PokerEngine: NPC calls ", amount_to_call)
	
	pot_updated.emit(pot)
	
	# After a call, betting round is complete
	_complete_betting_round()

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
		
		# Pass to NPC
		pot_updated.emit(pot)
		_trigger_npc_turn()
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
		
		# Pass to player
		pot_updated.emit(pot)
		_trigger_player_turn()

# ============================================================================
# SHOWDOWN
# ============================================================================

func _showdown() -> void:
	"""
	Evaluate hands and determine winner.
	Emit showdown signal with results.
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
		"tied": false
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
	
	result.pot_amount = pot
	
	# Emit showdown signal
	showdown.emit(player_hand, npc_hand, result)
	
	# End hand
	_end_hand(result.player_won)

# ============================================================================
# HAND END
# ============================================================================

func _end_hand(winner_is_player: bool) -> void:
	"""
	End the current hand.
	Emit hand_ended signal with winner information.
	"""
	var pot_amount = pot
	pot = 0
	pot_updated.emit(pot)
	
	print("PokerEngine: Hand ended - Winner: ", "Player" if winner_is_player else "NPC")
	hand_ended.emit(winner_is_player, pot_amount)
	
	# Alternate dealer
	dealer_is_player = not dealer_is_player

# ============================================================================
# UTILITY FUNCTIONS
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
