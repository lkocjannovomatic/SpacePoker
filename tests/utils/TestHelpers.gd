extends RefCounted
class_name TestHelpers

# TestHelpers.gd - Utility functions for testing poker engine
# Provides helper methods to create test data and setup controlled game states

const CardDataClass = preload("res://scripts/game_view/CardData.gd")
const PokerEngineClass = preload("res://scripts/game_view/PokerEngine.gd")

# ============================================================================
# CARD CREATION HELPERS
# ============================================================================

static func create_card(rank: CardDataClass.Rank, suit: CardDataClass.Suit) -> CardDataClass:
	"""Create a CardData instance with specified rank and suit."""
	return CardDataClass.new(rank, suit)  # CardData constructor is (rank, suit)

static func create_cards_from_string(cards_string: String) -> Array:
	"""
	Create array of CardData from string notation.
	Format: "AS KH 2D" (Ace of Spades, King of Hearts, 2 of Diamonds)
	Ranks: A, K, Q, J, T(10), 9-2
	Suits: S(spades), H(hearts), D(diamonds), C(clubs)
	"""
	var cards = []
	var parts = cards_string.split(" ", false)
	
	for part in parts:
		if part.length() < 2:
			continue
		
		var rank_char = part[0]
		var suit_char = part[1]
		
		var rank = _parse_rank_char(rank_char)
		var suit = _parse_suit_char(suit_char)
		
		cards.append(create_card(rank, suit))
	
	return cards

static func _parse_rank_char(c: String) -> CardDataClass.Rank:
	"""Convert character to Rank enum."""
	match c.to_upper():
		"A": return CardDataClass.Rank.ACE
		"K": return CardDataClass.Rank.KING
		"Q": return CardDataClass.Rank.QUEEN
		"J": return CardDataClass.Rank.JACK
		"T": return CardDataClass.Rank.TEN
		"9": return CardDataClass.Rank.NINE
		"8": return CardDataClass.Rank.EIGHT
		"7": return CardDataClass.Rank.SEVEN
		"6": return CardDataClass.Rank.SIX
		"5": return CardDataClass.Rank.FIVE
		"4": return CardDataClass.Rank.FOUR
		"3": return CardDataClass.Rank.THREE
		"2": return CardDataClass.Rank.TWO
		_: return CardDataClass.Rank.TWO

static func _parse_suit_char(c: String) -> CardDataClass.Suit:
	"""Convert character to Suit enum."""
	match c.to_upper():
		"S": return CardDataClass.Suit.SPADES
		"H": return CardDataClass.Suit.HEARTS
		"D": return CardDataClass.Suit.DIAMONDS
		"C": return CardDataClass.Suit.CLUBS
		_: return CardDataClass.Suit.SPADES

# ============================================================================
# ENGINE SETUP HELPERS
# ============================================================================

static func create_engine(player_stack: int = 1000, npc_stack: int = 1000, player_is_dealer: bool = false) -> PokerEngineClass:
	"""Create a PokerEngine instance for testing."""
	return PokerEngineClass.new(player_stack, npc_stack, player_is_dealer)

static func setup_engine_with_cards(engine: PokerEngineClass, player_cards: Array, npc_cards: Array, community: Array) -> void:
	"""
	Manually set cards in an engine for testing (bypasses deck).
	Useful for testing specific scenarios.
	"""
	engine.player_hand = player_cards
	engine.npc_hand = npc_cards
	engine.community_cards = community

# ============================================================================
# ASSERTION HELPERS
# ============================================================================

static func assert_cards_equal(actual: Array, expected: Array, message: String = "") -> bool:
	"""
	Compare two arrays of CardData for equality.
	Returns true if equal, false otherwise.
	"""
	if actual.size() != expected.size():
		print("Card array size mismatch: ", message)
		return false
	
	for i in range(actual.size()):
		var a = actual[i]
		var e = expected[i]
		
		if not a is CardDataClass or not e is CardDataClass:
			print("Invalid card data at index ", i, ": ", message)
			return false
		
		if a.rank != e.rank or a.suit != e.suit:
			print("Card mismatch at index ", i, ": ", message)
			return false
	
	return true
