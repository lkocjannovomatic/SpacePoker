extends Control

# Board.gd - Poker table interface for GameView
# Displays cards, stacks, pot, and betting controls
# Manages player betting actions and state-based UI updates

# Signals
signal player_action_taken(action: String, amount: int)

# UI References - Information Display
@onready var player_stack_label = $PlayerStackPanel/VBoxContainer/StackLabel
@onready var npc_stack_label = $NPCStackPanel/VBoxContainer/StackLabel
@onready var pot_label = $PotPanel/PotLabel
var game_phase_label = null  # Not in current Board.tscn structure

# UI References - Card Display
@onready var player_card_1 = $PlayerHand/Card1
@onready var player_card_2 = $PlayerHand/Card2
@onready var npc_card_1 = $NPCHand/Card1
@onready var npc_card_2 = $NPCHand/Card2
@onready var community_cards_container = $CommunityCards

# UI References - Betting Controls (these are in GameView.tscn, not Board.tscn)
var fold_button = null
var check_call_button = null
var raise_button = null
var bet_slider = null

func _ready():
	print("Board: Initializing...")
	
	# Betting controls are in GameView, will be set via init_betting_controls()
	# Don't connect them here

# ============================================================================
# INITIALIZATION
# ============================================================================

func init() -> void:
	"""Initialize the board for a new match."""
	print("Board: Initializing for new match")
	
	# Clear card displays
	_clear_cards()
	
	# Reset labels
	player_stack_label.text = "1000"
	npc_stack_label.text = "1000"
	pot_label.text = "POT: 0"
	
	# Disable controls initially
	_set_betting_controls_enabled(false)

func init_betting_controls(fold_btn, check_call_btn, raise_btn, slider) -> void:
	"""Initialize betting control references from GameView."""
	fold_button = fold_btn
	check_call_button = check_call_btn
	raise_button = raise_btn
	bet_slider = slider
	
	# Connect signals
	if fold_button:
		fold_button.pressed.connect(_on_fold_pressed)
	if check_call_button:
		check_call_button.pressed.connect(_on_check_call_pressed)
	if raise_button:
		raise_button.pressed.connect(_on_raise_pressed)
	
	_set_betting_controls_enabled(false)

# ============================================================================
# PUBLIC INTERFACE (Called by GameView)
# ============================================================================

func update_controls(valid_actions: Dictionary) -> void:
	"""
	Enable/disable betting controls based on valid actions from PokerEngine.
	"""
	if not check_call_button or not raise_button or not bet_slider:
		return
	
	_set_betting_controls_enabled(true)
	
	# Update check/call button
	if valid_actions.get("can_check", false):
		check_call_button.text = "CHECK"
	else:
		var call_amount = valid_actions.get("call_amount", 0)
		check_call_button.text = "CALL (" + str(call_amount) + ")"
	
	# Update raise button and slider
	var can_raise = valid_actions.get("can_raise", false)
	var min_raise = valid_actions.get("min_raise", 0)
	var max_raise = valid_actions.get("max_raise", 0)
	
	raise_button.disabled = not can_raise
	bet_slider.editable = can_raise
	
	if can_raise:
		bet_slider.min_value = min_raise
		bet_slider.max_value = max_raise
		bet_slider.value = min_raise

func update_pot_label(amount: int) -> void:
	"""Update pot display."""
	pot_label.text = "POT: " + str(amount)

func update_stack_labels(player_stack_val: int, npc_stack_val: int) -> void:
	"""Update player and NPC stack displays."""
	player_stack_label.text = str(player_stack_val)
	npc_stack_label.text = str(npc_stack_val)

func display_community_cards(cards: Array) -> void:
	"""Display community cards."""
	print("Board: Displaying ", cards.size(), " community cards")
	
	# Clear existing community cards
	for child in community_cards_container.get_children():
		child.queue_free()
	
	# Display new cards
	for card in cards:
		var card_label = Label.new()
		card_label.text = card.to_short_string() if card.has_method("to_short_string") else str(card)
		card_label.add_theme_font_size_override("font_size", 16)
		community_cards_container.add_child(card_label)

func display_player_cards(cards: Array) -> void:
	"""Display player's hole cards."""
	print("Board: Displaying player cards")
	
	if cards.size() >= 1 and player_card_1 and cards[0] is CardData:
		var card_data: CardData = cards[0]
		var suit_str = _get_suit_string(card_data.suit)
		var rank_str = _get_rank_string(card_data.rank)
		player_card_1.set_card(suit_str, rank_str)
		player_card_1.show_face()
	
	if cards.size() >= 2 and player_card_2 and cards[1] is CardData:
		var card_data: CardData = cards[1]
		var suit_str = _get_suit_string(card_data.suit)
		var rank_str = _get_rank_string(card_data.rank)
		player_card_2.set_card(suit_str, rank_str)
		player_card_2.show_face()

func display_showdown(_player_hand: Array, npc_hand: Array, _result: Dictionary) -> void:
	"""Display showdown results."""
	print("Board: Displaying showdown")
	
	# Show NPC cards
	if npc_hand.size() >= 1 and npc_card_1 and npc_hand[0] is CardData:
		var card_data: CardData = npc_hand[0]
		var suit_str = _get_suit_string(card_data.suit)
		var rank_str = _get_rank_string(card_data.rank)
		npc_card_1.set_card(suit_str, rank_str)
		npc_card_1.show_face()
	
	if npc_hand.size() >= 2 and npc_card_2 and npc_hand[1] is CardData:
		var card_data: CardData = npc_hand[1]
		var suit_str = _get_suit_string(card_data.suit)
		var rank_str = _get_rank_string(card_data.rank)
		npc_card_2.set_card(suit_str, rank_str)
		npc_card_2.show_face()
	
	# Update result display (game_phase_label doesn't exist in current scene)
	# GameView will handle winner display via its WinnerOverlay

# ============================================================================
# GAMESTATE SIGNAL HANDLERS (REMOVED - Now controlled by GameView)
# ============================================================================

# The following functions have been removed as they're no longer needed:
# - _on_game_state_changed
# - _on_player_stack_changed
# - _on_npc_stack_changed
# - _on_pot_changed
# - _on_community_cards_dealt
# - _on_player_cards_dealt
# These are now replaced by the public interface functions above

# ============================================================================
# BETTING CONTROLS
# ============================================================================

func _set_betting_controls_enabled(enabled: bool) -> void:
	"""Enable or disable all betting controls."""
	if fold_button:
		fold_button.disabled = not enabled
	if check_call_button:
		check_call_button.disabled = not enabled
	if raise_button:
		raise_button.disabled = not enabled
	if bet_slider:
		bet_slider.editable = enabled

func _on_fold_pressed() -> void:
	"""Handle fold button press."""
	print("Board: Player clicked Fold")
	player_action_taken.emit("fold", 0)

func _on_check_call_pressed() -> void:
	"""Handle check/call button press."""
	if not check_call_button:
		return
	
	# Determine action based on button text
	if check_call_button.text.begins_with("CHECK"):
		print("Board: Player clicked Check")
		player_action_taken.emit("check", 0)
	else:
		# Extract call amount from button text (format: "CALL (amount)")
		var amount_text = check_call_button.text.replace("CALL (", "").replace(")", "")
		var call_amount = int(amount_text)
		print("Board: Player clicked Call (", call_amount, ")")
		player_action_taken.emit("call", call_amount)

func _on_raise_pressed() -> void:
	"""Handle raise button press."""
	if not bet_slider:
		return
	
	var raise_amount = int(bet_slider.value)
	print("Board: Player clicked Raise to ", raise_amount)
	player_action_taken.emit("raise", raise_amount)

# ============================================================================
# UI HELPERS (Removed GameState-dependent functions)
# ============================================================================

func _clear_cards() -> void:
	"""Clear all card displays."""
	if player_card_1:
		player_card_1.show_back()
	if player_card_2:
		player_card_2.show_back()
	if npc_card_1:
		npc_card_1.show_back()
	if npc_card_2:
		npc_card_2.show_back()
	
	for child in community_cards_container.get_children():
		child.queue_free()

func reset() -> void:
	"""Reset board state (for cleanup when leaving match)."""
	print("Board: Resetting state")
	_clear_cards()
	_set_betting_controls_enabled(false)
	player_stack_label.text = "1000"
	npc_stack_label.text = "1000"
	pot_label.text = "POT: 0"

# ============================================================================
# CARDDATA CONVERSION HELPERS
# ============================================================================

func _get_suit_string(suit_enum) -> String:
	"""Convert CardData.Suit enum to string for Card component."""
	match suit_enum:
		CardData.Suit.HEARTS: return "hearts"
		CardData.Suit.DIAMONDS: return "diamonds"
		CardData.Suit.CLUBS: return "clubs"
		CardData.Suit.SPADES: return "spades"
		_: return "hearts"

func _get_rank_string(rank_enum) -> String:
	"""Convert CardData.Rank enum to string for Card component."""
	match rank_enum:
		CardData.Rank.TWO: return "2"
		CardData.Rank.THREE: return "3"
		CardData.Rank.FOUR: return "4"
		CardData.Rank.FIVE: return "5"
		CardData.Rank.SIX: return "6"
		CardData.Rank.SEVEN: return "7"
		CardData.Rank.EIGHT: return "8"
		CardData.Rank.NINE: return "9"
		CardData.Rank.TEN: return "10"
		CardData.Rank.JACK: return "J"
		CardData.Rank.QUEEN: return "Q"
		CardData.Rank.KING: return "K"
		CardData.Rank.ACE: return "A"
		_: return "2"
