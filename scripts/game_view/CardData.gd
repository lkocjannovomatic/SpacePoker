extends Resource
class_name CardData

# CardData.gd - A resource representing a single playing card
# Used throughout the poker engine to represent cards in hands, decks, and on the board

# Card suit enumeration
enum Suit {
	HEARTS,
	DIAMONDS,
	CLUBS,
	SPADES
}

# Card rank enumeration (values aligned with poker hand evaluation)
enum Rank {
	TWO = 2,
	THREE = 3,
	FOUR = 4,
	FIVE = 5,
	SIX = 6,
	SEVEN = 7,
	EIGHT = 8,
	NINE = 9,
	TEN = 10,
	JACK = 11,
	QUEEN = 12,
	KING = 13,
	ACE = 14  # Ace is high by default; low Ace (value 1) handled in straight detection
}

# Properties
@export var suit: Suit = Suit.HEARTS
@export var rank: Rank = Rank.TWO

# Constructor
func _init(p_rank: Rank = Rank.TWO, p_suit: Suit = Suit.HEARTS):
	rank = p_rank
	suit = p_suit

# ============================================================================
# DISPLAY METHODS
# ============================================================================

func card_to_string() -> String:
	"""
	Returns a human-readable string representation of the card.
	Example: "Ace of Hearts", "Ten of Spades"
	"""
	return get_rank_name() + " of " + get_suit_name()

func to_short_string() -> String:
	"""
	Returns a compact string representation of the card.
	Example: "A♥", "10♠"
	"""
	return get_rank_symbol() + get_suit_symbol()

func get_rank_name() -> String:
	"""Returns the full name of the card's rank."""
	match rank:
		Rank.TWO: return "Two"
		Rank.THREE: return "Three"
		Rank.FOUR: return "Four"
		Rank.FIVE: return "Five"
		Rank.SIX: return "Six"
		Rank.SEVEN: return "Seven"
		Rank.EIGHT: return "Eight"
		Rank.NINE: return "Nine"
		Rank.TEN: return "Ten"
		Rank.JACK: return "Jack"
		Rank.QUEEN: return "Queen"
		Rank.KING: return "King"
		Rank.ACE: return "Ace"
		_: return "Unknown"

func get_rank_symbol() -> String:
	"""Returns the symbol representation of the card's rank."""
	match rank:
		Rank.TWO: return "2"
		Rank.THREE: return "3"
		Rank.FOUR: return "4"
		Rank.FIVE: return "5"
		Rank.SIX: return "6"
		Rank.SEVEN: return "7"
		Rank.EIGHT: return "8"
		Rank.NINE: return "9"
		Rank.TEN: return "10"
		Rank.JACK: return "J"
		Rank.QUEEN: return "Q"
		Rank.KING: return "K"
		Rank.ACE: return "A"
		_: return "?"

func get_suit_name() -> String:
	"""Returns the full name of the card's suit."""
	match suit:
		Suit.HEARTS: return "Hearts"
		Suit.DIAMONDS: return "Diamonds"
		Suit.CLUBS: return "Clubs"
		Suit.SPADES: return "Spades"
		_: return "Unknown"

func get_suit_symbol() -> String:
	"""Returns the Unicode symbol for the card's suit."""
	match suit:
		Suit.HEARTS: return "♥"
		Suit.DIAMONDS: return "♦"
		Suit.CLUBS: return "♣"
		Suit.SPADES: return "♠"
		_: return "?"

# ============================================================================
# COMPARISON METHODS
# ============================================================================

func equals(other: CardData) -> bool:
	"""Check if this card is identical to another card."""
	if other == null:
		return false
	return rank == other.rank and suit == other.suit

func compare_rank(other: CardData) -> int:
	"""
	Compare ranks of two cards.
	Returns: -1 if this < other, 0 if equal, 1 if this > other
	"""
	if other == null:
		return 1
	
	if rank < other.rank:
		return -1
	elif rank > other.rank:
		return 1
	else:
		return 0
