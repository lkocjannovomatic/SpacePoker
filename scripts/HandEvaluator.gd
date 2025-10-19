extends RefCounted
class_name HandEvaluator

# HandEvaluator.gd - Static utility for poker hand evaluation
# Evaluates poker hands and compares them according to Texas Hold'em rules

const CardDataClass = preload("res://scripts/CardData.gd")

# Hand rank enumeration (ordered from worst to best)
enum HandRank {
	HIGH_CARD = 0,
	ONE_PAIR = 1,
	TWO_PAIR = 2,
	THREE_OF_A_KIND = 3,
	STRAIGHT = 4,
	FLUSH = 5,
	FULL_HOUSE = 6,
	FOUR_OF_A_KIND = 7,
	STRAIGHT_FLUSH = 8,
	ROYAL_FLUSH = 9
}

# ============================================================================
# HAND EVALUATION
# ============================================================================

static func evaluate_hand(hole_cards: Array, community_cards: Array) -> Dictionary:
	"""
	Evaluates the best possible 5-card poker hand from 7 cards (2 hole + 5 community).
	
	Args:
		hole_cards: Array of 2 CardData (player's private cards)
		community_cards: Array of 5 CardData (shared board cards)
	
	Returns:
		Dictionary with:
			- rank_enum: HandRank enum value
			- rank_name: String description (e.g., "Full House")
			- value: int for comparing hands of same rank
			- cards: Array of 5 CardData making up the best hand
			- description: String like "Full House, Kings over Tens"
	"""
	# Combine all 7 cards
	var all_cards: Array = hole_cards + community_cards
	
	if all_cards.size() != 7:
		print("HandEvaluator Error: Expected 7 cards, got ", all_cards.size())
		return _create_result(HandRank.HIGH_CARD, "Invalid Hand", 0, [], "Error")
	
	# Check all hand types from best to worst
	var result = _check_royal_flush(all_cards)
	if result != null:
		return result
	
	result = _check_straight_flush(all_cards)
	if result != null:
		return result
	
	result = _check_four_of_a_kind(all_cards)
	if result != null:
		return result
	
	result = _check_full_house(all_cards)
	if result != null:
		return result
	
	result = _check_flush(all_cards)
	if result != null:
		return result
	
	result = _check_straight(all_cards)
	if result != null:
		return result
	
	result = _check_three_of_a_kind(all_cards)
	if result != null:
		return result
	
	result = _check_two_pair(all_cards)
	if result != null:
		return result
	
	result = _check_one_pair(all_cards)
	if result != null:
		return result
	
	# If nothing else, it's high card
	return _check_high_card(all_cards)

# ============================================================================
# PRE-FLOP HAND STRENGTH
# ============================================================================

static func get_preflop_strength(hole_cards: Array) -> float:
	"""
	Returns a normalized strength value (0.0 to 1.0) for a 2-card starting hand.
	Uses a simplified ranking system based on common poker strategy.
	
	Args:
		hole_cards: Array of 2 CardData
	
	Returns:
		float between 0.0 (worst) and 1.0 (best)
	"""
	if hole_cards.size() != 2:
		print("HandEvaluator Error: Expected 2 cards for preflop evaluation")
		return 0.0
	
	var card1 = hole_cards[0]
	var card2 = hole_cards[1]
	
	var rank1 = int(card1.rank)
	var rank2 = int(card2.rank)
	var suited = (card1.suit == card2.suit)
	
	# Get higher and lower ranks
	var high = max(rank1, rank2)
	var low = min(rank1, rank2)
	var is_pair = (rank1 == rank2)
	
	# Simplified strength calculation
	var strength = 0.0
	
	# Pairs are strong (especially high pairs)
	if is_pair:
		# Pairs range from 0.5 (deuces) to 1.0 (aces)
		strength = 0.5 + (high - 2) / 24.0  # 2 to 14 maps to 0.5 to 1.0
		return strength
	
	# High cards are valuable
	var high_card_value = (high - 2) / 12.0  # Normalize to 0-1
	strength += high_card_value * 0.4
	
	# Connected cards (for straight potential)
	var gap = high - low - 1
	if gap == 0:  # Connected
		strength += 0.15
	elif gap == 1:  # One gap
		strength += 0.1
	elif gap == 2:  # Two gap
		strength += 0.05
	
	# Suited bonus (for flush potential)
	if suited:
		strength += 0.15
	
	# Broadway cards (Ten or higher) bonus
	if high >= 10 and low >= 10:
		strength += 0.1
	
	# Clamp to 0.0-1.0 range
	return clampf(strength, 0.0, 1.0)

# ============================================================================
# HAND CHECKING FUNCTIONS (Private)
# ============================================================================

static func _check_royal_flush(cards: Array):
	"""Check for Royal Flush (A-K-Q-J-10 of same suit). Returns Dictionary or null."""
	var straight_flush = _check_straight_flush(cards)
	if straight_flush != null:
		# Check if it's ace-high (royal)
		if straight_flush.value >= 140000:  # Ace-high straight flush
			return _create_result(
				HandRank.ROYAL_FLUSH,
				"Royal Flush",
				150000,
				straight_flush.cards,
				"Royal Flush"
			)
	return null

static func _check_straight_flush(cards: Array):
	"""Check for Straight Flush (5 cards in sequence, same suit). Returns Dictionary or null."""
	# Get all flushes
	var flush_cards = _get_flush_cards(cards)
	if flush_cards.size() < 5:
		return null
	
	# Check if the flush contains a straight
	var straight = _find_straight_in_cards(flush_cards)
	if straight != null:
		return _create_result(
			HandRank.STRAIGHT_FLUSH,
			"Straight Flush",
			140000 + _get_high_card_value(straight),
			straight,
			"Straight Flush, " + straight[0].get_rank_name() + " high"
		)
	
	return null

static func _check_four_of_a_kind(cards: Array):
	"""Check for Four of a Kind (4 cards of same rank). Returns Dictionary or null."""
	var rank_groups = _group_by_rank(cards)
	
	for rank in rank_groups:
		if rank_groups[rank].size() == 4:
			var quads = rank_groups[rank]
			var kicker = _get_highest_kicker(cards, quads, 1)
			var hand_cards = quads + kicker
			
			var value = 130000 + (rank * 100) + _get_high_card_value(kicker)
			return _create_result(
				HandRank.FOUR_OF_A_KIND,
				"Four of a Kind",
				value,
				hand_cards,
				"Four " + quads[0].get_rank_name() + "s"
			)
	
	return null

static func _check_full_house(cards: Array):
	"""Check for Full House (3 of a kind + pair). Returns Dictionary or null."""
	var rank_groups = _group_by_rank(cards)
	
	var trips_rank = -1
	var pair_rank = -1
	
	# Find highest three of a kind
	for rank in rank_groups:
		if rank_groups[rank].size() >= 3:
			if rank > trips_rank:
				trips_rank = rank
	
	if trips_rank == -1:
		return null
	
	# Find highest pair (excluding the trips)
	for rank in rank_groups:
		if rank != trips_rank and rank_groups[rank].size() >= 2:
			if rank > pair_rank:
				pair_rank = rank
	
	if pair_rank == -1:
		return null
	
	var hand_cards = rank_groups[trips_rank].slice(0, 3) + rank_groups[pair_rank].slice(0, 2)
	var value = 120000 + (trips_rank * 100) + pair_rank
	
	return _create_result(
		HandRank.FULL_HOUSE,
		"Full House",
		value,
		hand_cards,
		"Full House, " + rank_groups[trips_rank][0].get_rank_name() + "s over " + rank_groups[pair_rank][0].get_rank_name() + "s"
	)

static func _check_flush(cards: Array):
	"""Check for Flush (5 cards of same suit). Returns Dictionary or null."""
	var flush_cards = _get_flush_cards(cards)
	if flush_cards.size() < 5:
		return null
	
	# Take top 5 cards
	var sorted = _sort_by_rank_desc(flush_cards)
	var hand_cards = sorted.slice(0, 5)
	
	var value = 110000 + _get_high_card_value(hand_cards)
	return _create_result(
		HandRank.FLUSH,
		"Flush",
		value,
		hand_cards,
		"Flush, " + hand_cards[0].get_rank_name() + " high"
	)

static func _check_straight(cards: Array):
	"""Check for Straight (5 cards in sequence, any suit). Returns Dictionary or null."""
	var straight = _find_straight_in_cards(cards)
	if straight != null:
		var value = 100000 + _get_high_card_value([straight[0]])
		return _create_result(
			HandRank.STRAIGHT,
			"Straight",
			value,
			straight,
			"Straight, " + straight[0].get_rank_name() + " high"
		)
	
	return null

static func _check_three_of_a_kind(cards: Array):
	"""Check for Three of a Kind (3 cards of same rank). Returns Dictionary or null."""
	var rank_groups = _group_by_rank(cards)
	
	for rank in rank_groups:
		if rank_groups[rank].size() >= 3:
			var trips = rank_groups[rank].slice(0, 3)
			var kickers = _get_highest_kicker(cards, trips, 2)
			var hand_cards = trips + kickers
			
			var value = 90000 + (rank * 100) + _get_high_card_value(kickers)
			return _create_result(
				HandRank.THREE_OF_A_KIND,
				"Three of a Kind",
				value,
				hand_cards,
				"Three " + trips[0].get_rank_name() + "s"
			)
	
	return null

static func _check_two_pair(cards: Array):
	"""Check for Two Pair (2 pairs of different ranks). Returns Dictionary or null."""
	var rank_groups = _group_by_rank(cards)
	
	var pair_ranks = []
	for rank in rank_groups:
		if rank_groups[rank].size() >= 2:
			pair_ranks.append(rank)
	
	if pair_ranks.size() < 2:
		return null
	
	# Sort pairs by rank descending
	pair_ranks.sort()
	pair_ranks.reverse()
	
	var high_pair = rank_groups[pair_ranks[0]].slice(0, 2)
	var low_pair = rank_groups[pair_ranks[1]].slice(0, 2)
	var kicker = _get_highest_kicker(cards, high_pair + low_pair, 1)
	var hand_cards = high_pair + low_pair + kicker
	
	var value = 80000 + (pair_ranks[0] * 100) + (pair_ranks[1] * 10) + _get_high_card_value(kicker)
	
	return _create_result(
		HandRank.TWO_PAIR,
		"Two Pair",
		value,
		hand_cards,
		"Two Pair, " + high_pair[0].get_rank_name() + "s and " + low_pair[0].get_rank_name() + "s"
	)

static func _check_one_pair(cards: Array):
	"""Check for One Pair (2 cards of same rank). Returns Dictionary or null."""
	var rank_groups = _group_by_rank(cards)
	
	for rank in rank_groups:
		if rank_groups[rank].size() >= 2:
			var pair = rank_groups[rank].slice(0, 2)
			var kickers = _get_highest_kicker(cards, pair, 3)
			var hand_cards = pair + kickers
			
			var value = 70000 + (rank * 100) + _get_high_card_value(kickers)
			return _create_result(
				HandRank.ONE_PAIR,
				"One Pair",
				value,
				hand_cards,
				"Pair of " + pair[0].get_rank_name() + "s"
			)
	
	return null

static func _check_high_card(cards: Array) -> Dictionary:
	"""High Card (no other hand made)."""
	var sorted = _sort_by_rank_desc(cards)
	var hand_cards = sorted.slice(0, 5)
	
	var value = 60000 + _get_high_card_value(hand_cards)
	return _create_result(
		HandRank.HIGH_CARD,
		"High Card",
		value,
		hand_cards,
		hand_cards[0].get_rank_name() + " high"
	)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

static func _group_by_rank(cards: Array) -> Dictionary:
	"""Group cards by rank, sorted descending by rank."""
	var groups = {}
	
	for card in cards:
		var rank = int(card.rank)
		if not groups.has(rank):
			groups[rank] = []
		groups[rank].append(card)
	
	# Sort each group
	for rank in groups:
		groups[rank] = _sort_by_rank_desc(groups[rank])
	
	return groups

static func _get_flush_cards(cards: Array) -> Array:
	"""Returns all cards of the most common suit if there are 5+."""
	var suit_counts = {
		CardDataClass.Suit.HEARTS: [],
		CardDataClass.Suit.DIAMONDS: [],
		CardDataClass.Suit.CLUBS: [],
		CardDataClass.Suit.SPADES: []
	}
	
	for card in cards:
		suit_counts[card.suit].append(card)
	
	for suit in suit_counts:
		if suit_counts[suit].size() >= 5:
			return _sort_by_rank_desc(suit_counts[suit])
	
	return []

static func _find_straight_in_cards(cards: Array):
	"""Finds the highest straight in the given cards, or null if none exists."""
	var sorted = _sort_by_rank_desc(cards)
	
	# Remove duplicates
	var unique_ranks = []
	var unique_cards = []
	for card in sorted:
		if not int(card.rank) in unique_ranks:
			unique_ranks.append(int(card.rank))
			unique_cards.append(card)
	
	# Check for standard straights (5 consecutive ranks)
	for i in range(unique_cards.size() - 4):
		var is_straight = true
		for j in range(4):
			if unique_ranks[i + j] - unique_ranks[i + j + 1] != 1:
				is_straight = false
				break
		
		if is_straight:
			return unique_cards.slice(i, i + 5)
	
	# Check for A-2-3-4-5 (wheel) straight
	if unique_ranks.size() >= 5:
		if 14 in unique_ranks and 2 in unique_ranks and 3 in unique_ranks and 4 in unique_ranks and 5 in unique_ranks:
			var wheel = []
			for card in unique_cards:
				if int(card.rank) in [5, 4, 3, 2, 14]:
					wheel.append(card)
					if wheel.size() == 5:
						break
			return wheel
	
	return null

static func _sort_by_rank_desc(cards: Array) -> Array:
	"""Sort cards by rank in descending order."""
	var sorted = cards.duplicate()
	sorted.sort_custom(func(a, b): return int(a.rank) > int(b.rank))
	return sorted

static func _get_highest_kicker(all_cards: Array, used_cards: Array, count: int) -> Array:
	"""Get the highest 'count' kickers that are not in used_cards."""
	var available = []
	
	for card in all_cards:
		var is_used = false
		for used in used_cards:
			if card.equals(used):
				is_used = true
				break
		if not is_used:
			available.append(card)
	
	var sorted = _sort_by_rank_desc(available)
	return sorted.slice(0, min(count, sorted.size()))

static func _get_high_card_value(cards: Array) -> int:
	"""Calculate a value for tie-breaking based on card ranks."""
	var value = 0
	var multiplier = 10000
	
	for card in cards:
		value += int(card.rank) * multiplier
		multiplier = int(multiplier / 100.0)
	
	return value

static func _create_result(rank_enum: HandRank, rank_name: String, value: int, hand_cards: Array, description: String) -> Dictionary:
	"""Create a standardized result dictionary."""
	return {
		"rank_enum": rank_enum,
		"rank_name": rank_name,
		"value": value,
		"cards": hand_cards,
		"description": description
	}

# ============================================================================
# COMPARISON
# ============================================================================

static func compare_hands(hand1: Dictionary, hand2: Dictionary) -> int:
	"""
	Compare two evaluated hands.
	Returns: -1 if hand1 < hand2, 0 if tied, 1 if hand1 > hand2
	"""
	if hand1.value < hand2.value:
		return -1
	elif hand1.value > hand2.value:
		return 1
	else:
		return 0
