extends Node
class_name NPC_AI

# NPC_AI.gd - Rule-based NPC decision-making for poker
# Uses personality factors to determine betting actions
# Separate from LLM (which only handles chat, not strategy)

# Preload HandEvaluator for hand strength calculations
const HandEvaluatorClass = preload("res://scripts/game_view/HandEvaluator.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal action_chosen(action: String, amount: int)

# ============================================================================
# PERSONALITY FACTORS (0.0 - 1.0)
# ============================================================================

var aggression: float = 0.5       # Affects betting frequency/size
var bluffing: float = 0.5         # Affects bluff probability
var risk_aversion: float = 0.5    # Affects fold thresholds

# ============================================================================
# INTERNAL STATE
# ============================================================================

var action_timer: Timer = null
const MIN_DELAY = 0.8
const MAX_DELAY = 2.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	# Create action timer
	action_timer = Timer.new()
	action_timer.one_shot = true
	action_timer.timeout.connect(_on_action_timer_timeout)
	add_child(action_timer)
	
	print("NPC_AI: Ready")

func initialize(personality: Dictionary) -> void:
	"""
	Set personality factors from NPC data.
	
	Args:
		personality: Dictionary with keys "aggression", "bluffing", "risk_aversion"
	"""
	aggression = personality.get("aggression", 0.5)
	bluffing = personality.get("bluffing", 0.5)
	risk_aversion = personality.get("risk_aversion", 0.5)
	
	print("NPC_AI: Initialized with personality - Aggression: ", aggression, 
		  ", Bluffing: ", bluffing, ", Risk Aversion: ", risk_aversion)

# ============================================================================
# DECISION MAKING
# ============================================================================

var pending_decision: Dictionary = {}

func make_decision(context: Dictionary) -> void:
	"""
	Main entry point for NPC decision-making.
	Calculates decision based on context and personality, then starts timer.
	
	Args:
		context: Game state from PokerEngine.get_decision_context()
	"""
	print("NPC_AI: Making decision...")
	
	# Store context for timer callback
	pending_decision = _calculate_decision(context)
	
	# Start timer for realistic delay
	var delay = randf_range(MIN_DELAY, MAX_DELAY)
	action_timer.start(delay)

func _calculate_decision(context: Dictionary) -> Dictionary:
	"""
	Calculate the NPC's decision based on context and personality.
	Returns dictionary with "action" and "amount" keys.
	"""
	var hand_phase = context.get("hand_phase", 0)
	var npc_hand = context.get("npc_hand", [])
	var community_cards = context.get("community_cards", [])
	var call_amount = context.get("call_amount", 0)
	var min_raise = context.get("min_raise", 0)
	var max_raise = context.get("max_raise", 0)
	var npc_stack = context.get("npc_stack", 0)
	var pot = context.get("pot", 0)
	
	# Calculate hand strength
	var hand_strength = _calculate_hand_strength(npc_hand, community_cards, hand_phase)
	
	print("NPC_AI: Hand strength = ", hand_strength)
	
	# Determine action based on personality and hand strength
	var decision = _determine_action(hand_strength, call_amount, min_raise, max_raise, npc_stack, pot)
	
	print("NPC_AI: Decision = ", decision.action, " (", decision.amount, ")")
	
	return decision

func _calculate_hand_strength(npc_hand: Array, community_cards: Array, phase: int) -> float:
	"""
	Calculate normalized hand strength (0.0 to 1.0).
	Pre-flop uses preflop strength, post-flop evaluates actual hand.
	"""
	if phase == 0:  # PRE_FLOP
		return HandEvaluatorClass.get_preflop_strength(npc_hand)
	else:
		# Post-flop: evaluate actual hand
		if community_cards.size() >= 3:
			var result = HandEvaluatorClass.evaluate_hand(npc_hand, community_cards)
			# Normalize hand rank (0-9) to 0.0-1.0
			var rank_enum = result.get("rank_enum", 0)
			return rank_enum / 9.0
		else:
			# Fallback to preflop if community cards not ready
			return HandEvaluatorClass.get_preflop_strength(npc_hand)

func _determine_action(hand_strength: float, call_amount: int, min_raise: int, 
					   max_raise: int, _npc_stack: int, pot: int) -> Dictionary:
	"""
	Determine action based on hand strength and personality factors.
	Returns: {"action": String, "amount": int}
	"""
	# Check for bluff opportunity (small chance to bet/raise with weak hand)
	var is_bluffing = false
	if randf() < (bluffing * 0.3):  # Max 30% bluff chance with max bluffing
		is_bluffing = true
		print("NPC_AI: Attempting bluff!")
	
	# Calculate fold threshold based on risk aversion
	# High risk aversion = fold more often (higher threshold)
	var fold_threshold = 0.2 + (risk_aversion * 0.4)  # Range: 0.2 to 0.6
	
	# If bluffing, treat hand as stronger
	var effective_strength = hand_strength
	if is_bluffing:
		effective_strength = min(1.0, hand_strength + 0.3)
	
	# Decision logic
	if call_amount == 0:
		# No bet to call - can check or bet
		if effective_strength < fold_threshold:
			# Weak hand - usually check
			if randf() < (aggression * 0.3):  # Occasionally bet weak
				return _make_bet_decision(min_raise, max_raise, pot, effective_strength)
			else:
				return {"action": "check", "amount": 0}
		else:
			# Strong hand - bet based on aggression
			if randf() < (aggression * 0.7 + 0.2):  # 20-90% bet chance
				return _make_bet_decision(min_raise, max_raise, pot, effective_strength)
			else:
				return {"action": "check", "amount": 0}
	else:
		# There's a bet to call
		if effective_strength < fold_threshold:
			# Weak hand - usually fold
			if is_bluffing and randf() < 0.5:
				# Bluff call/raise
				if randf() < (aggression * 0.5):
					return _make_raise_decision(min_raise, max_raise, pot, effective_strength, call_amount)
				else:
					return {"action": "call", "amount": call_amount}
			else:
				return {"action": "fold", "amount": 0}
		elif effective_strength < 0.6:
			# Medium hand - usually call, sometimes raise
			if randf() < (aggression * 0.4):
				return _make_raise_decision(min_raise, max_raise, pot, effective_strength, call_amount)
			else:
				return {"action": "call", "amount": call_amount}
		else:
			# Strong hand - usually raise
			if randf() < (aggression * 0.6 + 0.3):  # 30-90% raise chance
				return _make_raise_decision(min_raise, max_raise, pot, effective_strength, call_amount)
			else:
				return {"action": "call", "amount": call_amount}

func _make_bet_decision(min_raise: int, max_raise: int, pot: int, strength: float) -> Dictionary:
	"""Determine bet sizing based on aggression and hand strength."""
	# Can we bet?
	if max_raise <= 0:
		return {"action": "check", "amount": 0}
	
	# Calculate bet size
	# Aggressive players bet bigger
	var size_factor = 0.3 + (aggression * 0.5)  # 0.3 to 0.8 of pot
	size_factor *= strength  # Scale by hand strength
	
	var bet_amount = int(pot * size_factor)
	bet_amount = clampi(bet_amount, min_raise, max_raise)
	
	return {"action": "raise", "amount": bet_amount}

func _make_raise_decision(min_raise: int, max_raise: int, pot: int, 
						  strength: float, call_amount: int) -> Dictionary:
	"""Determine raise sizing based on aggression and hand strength."""
	# Can we raise?
	if max_raise <= min_raise or max_raise <= call_amount:
		return {"action": "call", "amount": call_amount}
	
	# Calculate raise size
	var size_factor = 0.5 + (aggression * 0.8)  # 0.5 to 1.3x pot
	size_factor *= strength  # Scale by hand strength
	
	var raise_amount = int(pot * size_factor)
	raise_amount = clampi(raise_amount, min_raise, max_raise)
	
	return {"action": "raise", "amount": raise_amount}

# ============================================================================
# TIMER CALLBACK
# ============================================================================

func _on_action_timer_timeout() -> void:
	"""
	Emit the calculated decision after timer delay.
	"""
	if pending_decision.is_empty():
		print("NPC_AI Error: No pending decision")
		# Fallback: fold
		action_chosen.emit("fold", 0)
		return
	
	action_chosen.emit(pending_decision.action, pending_decision.amount)
	pending_decision.clear()
