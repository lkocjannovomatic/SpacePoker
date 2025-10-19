extends RefCounted
class_name Deck

# Deck.gd - Manages a 52-card poker deck
# Creates, shuffles, and deals cards for poker hands

const CardDataClass = preload("res://scripts/CardData.gd")

# Array of CardData resources
var cards: Array = []

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init():
	"""
	Constructor - creates a fresh, ordered 52-card deck.
	"""
	_create_deck()

func _create_deck() -> void:
	"""
	Creates a standard 52-card deck with all combinations of ranks and suits.
	Cards are created in a predictable order (all suits for each rank).
	"""
	cards.clear()
	
	# Iterate through all ranks
	for rank_value in CardDataClass.Rank.values():
		# Iterate through all suits
		for suit_value in CardDataClass.Suit.values():
			var card = CardDataClass.new(rank_value, suit_value)
			cards.append(card)
	
	print("Deck: Created fresh deck with ", cards.size(), " cards")

# ============================================================================
# DECK OPERATIONS
# ============================================================================

func shuffle() -> void:
	"""
	Randomizes the order of cards in the deck using Fisher-Yates shuffle.
	"""
	var n = cards.size()
	
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		# Swap cards[i] and cards[j]
		var temp = cards[i]
		cards[i] = cards[j]
		cards[j] = temp
	
	print("Deck: Shuffled")

func deal(count: int = 1) -> Array:
	"""
	Removes and returns the top 'count' cards from the deck.
	Returns an array of CardData.
	
	Args:
		count: Number of cards to deal (default 1)
	
	Returns:
		Array of CardData resources (empty array if not enough cards)
	"""
	if count <= 0:
		print("Deck Warning: Attempted to deal ", count, " cards")
		return []
	
	if count > cards.size():
		print("Deck Warning: Not enough cards to deal ", count, " (only ", cards.size(), " remaining)")
		return []
	
	var dealt_cards: Array = []
	
	for i in range(count):
		dealt_cards.append(cards.pop_back())
	
	print("Deck: Dealt ", count, " card(s). ", cards.size(), " remaining")
	
	return dealt_cards

func deal_one():
	"""
	Convenience method to deal a single card.
	Returns null if no cards remain.
	"""
	var dealt = deal(1)
	if dealt.size() > 0:
		return dealt[0]
	else:
		return null

# ============================================================================
# UTILITY METHODS
# ============================================================================

func cards_remaining() -> int:
	"""Returns the number of cards remaining in the deck."""
	return cards.size()

func is_empty() -> bool:
	"""Returns true if the deck has no cards left."""
	return cards.is_empty()

func reset() -> void:
	"""
	Resets the deck to a fresh, ordered 52-card state.
	Useful for starting a new hand.
	"""
	_create_deck()

func reset_and_shuffle() -> void:
	"""
	Convenience method to reset the deck and shuffle in one call.
	Common operation at the start of each hand.
	"""
	reset()
	shuffle()

# ============================================================================
# DEBUG METHODS
# ============================================================================

func print_deck() -> void:
	"""Prints all cards currently in the deck (for debugging)."""
	print("Deck contents (", cards.size(), " cards):")
	for card in cards:
		print("  - ", card.to_short_string())
