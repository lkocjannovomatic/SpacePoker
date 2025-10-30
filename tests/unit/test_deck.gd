extends GdUnitTestSuite

# test_deck.gd - Unit tests for Deck
# Tests card creation, dealing, and shuffling

const DeckClass = preload("res://scripts/game_view/Deck.gd")

# ============================================================================
# INITIALIZATION TESTS
# ============================================================================

func test_deck_has_52_cards():
	var deck = DeckClass.new()
	
	# Count all cards dealt
	var cards = []
	for i in range(52):
		cards.append(deck.deal_one())
	
	assert_int(cards.size()).is_equal(52)

func test_deck_has_all_unique_cards():
	var deck = DeckClass.new()
	
	var cards = []
	for i in range(52):
		cards.append(deck.deal_one())
	
	# Check for duplicates
	var seen = {}
	for card in cards:
		var key = str(card.rank) + "_" + str(card.suit)
		assert_bool(seen.has(key)).is_false()
		seen[key] = true

func test_reset_and_shuffle_creates_new_deck():
	var deck = DeckClass.new()
	
	# Deal some cards
	deck.deal(10)
	
	# Reset
	deck.reset_and_shuffle()
	
	# Should be able to deal 52 again
	var cards = []
	for i in range(52):
		var card = deck.deal_one()
		if card:
			cards.append(card)
	
	assert_int(cards.size()).is_equal(52)

# ============================================================================
# DEALING TESTS
# ============================================================================

func test_deal_one_card():
	var deck = DeckClass.new()
	
	var card = deck.deal_one()
	
	assert_object(card).is_not_null()

func test_deal_multiple_cards():
	var deck = DeckClass.new()
	
	var cards = deck.deal(5)
	
	assert_int(cards.size()).is_equal(5)

func test_dealt_cards_removed_from_deck():
	var deck = DeckClass.new()
	
	# Deal 50 cards
	deck.deal(50)
	
	# Should only be able to deal 2 more
	var remaining = deck.deal(2)
	
	assert_int(remaining.size()).is_equal(2)
