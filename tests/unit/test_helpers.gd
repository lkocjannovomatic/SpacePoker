extends GdUnitTestSuite

# test_helpers.gd - Unit tests for TestHelpers utility
# Verifies that test helper functions work correctly

const TestHelpersClass = preload("res://tests/utils/TestHelpers.gd")
const CardDataClass = preload("res://scripts/game_view/CardData.gd")

# ============================================================================
# CARD CREATION TESTS
# ============================================================================

func test_create_card():
	var card = TestHelpersClass.create_card(CardDataClass.Rank.ACE, CardDataClass.Suit.SPADES)
	
	assert_object(card).is_not_null()
	assert_int(card.rank).is_equal(CardDataClass.Rank.ACE)
	assert_int(card.suit).is_equal(CardDataClass.Suit.SPADES)

func test_create_cards_from_string_single_card():
	var cards = TestHelpersClass.create_cards_from_string("AS")
	
	assert_int(cards.size()).is_equal(1)
	assert_int(cards[0].rank).is_equal(CardDataClass.Rank.ACE)
	assert_int(cards[0].suit).is_equal(CardDataClass.Suit.SPADES)

func test_create_cards_from_string_multiple_cards():
	var cards = TestHelpersClass.create_cards_from_string("AS KH QD")
	
	assert_int(cards.size()).is_equal(3)
	# Ace of Spades
	assert_int(cards[0].rank).is_equal(CardDataClass.Rank.ACE)
	assert_int(cards[0].suit).is_equal(CardDataClass.Suit.SPADES)
	# King of Hearts
	assert_int(cards[1].rank).is_equal(CardDataClass.Rank.KING)
	assert_int(cards[1].suit).is_equal(CardDataClass.Suit.HEARTS)
	# Queen of Diamonds
	assert_int(cards[2].rank).is_equal(CardDataClass.Rank.QUEEN)
	assert_int(cards[2].suit).is_equal(CardDataClass.Suit.DIAMONDS)

func test_create_cards_from_string_all_ranks():
	var cards = TestHelpersClass.create_cards_from_string("AS KS QS JS TS 9S 8S 7S 6S 5S 4S 3S 2S")
	
	assert_int(cards.size()).is_equal(13)
	assert_int(cards[0].rank).is_equal(CardDataClass.Rank.ACE)
	assert_int(cards[12].rank).is_equal(CardDataClass.Rank.TWO)

func test_create_cards_from_string_all_suits():
	var cards = TestHelpersClass.create_cards_from_string("AS AH AD AC")
	
	assert_int(cards.size()).is_equal(4)
	assert_int(cards[0].suit).is_equal(CardDataClass.Suit.SPADES)
	assert_int(cards[1].suit).is_equal(CardDataClass.Suit.HEARTS)
	assert_int(cards[2].suit).is_equal(CardDataClass.Suit.DIAMONDS)
	assert_int(cards[3].suit).is_equal(CardDataClass.Suit.CLUBS)
