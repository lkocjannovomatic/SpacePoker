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
@onready var action_message_panel = $ActionMessagePanel
@onready var action_message_label = $ActionMessagePanel/ActionMessageLabel
var game_phase_label = null  # Not in current Board.tscn structure

# Message timer tracking
var message_hide_timer: SceneTreeTimer = null

# UI References - Card Display
@onready var player_card_1 = $PlayerHand/Card1
@onready var player_card_2 = $PlayerHand/Card2
@onready var npc_card_1 = $NPCHand/Card1
@onready var npc_card_2 = $NPCHand/Card2
@onready var community_cards_container = $CommunityCards

# UI References - Betting Controls (now in Board.tscn)
@onready var betting_controls = $BettingControls
@onready var fold_button = $BettingControls/VBoxContainer/ButtonsRow/FoldButton
@onready var check_call_button = $BettingControls/VBoxContainer/ButtonsRow/CheckCallButton
@onready var raise_button = $BettingControls/VBoxContainer/ButtonsRow/RaiseButton
@onready var bet_slider = $BettingControls/VBoxContainer/SliderContainer/BetSlider
@onready var amount_label = $BettingControls/VBoxContainer/SliderContainer/AmountLabel

func _ready():
	print("Board: Initializing...")
	
	# Connect betting control signals
	if fold_button:
		fold_button.pressed.connect(_on_fold_pressed)
	if check_call_button:
		check_call_button.pressed.connect(_on_check_call_pressed)
	if raise_button:
		raise_button.pressed.connect(_on_raise_pressed)
	if bet_slider:
		bet_slider.value_changed.connect(_on_bet_slider_value_changed)

# ============================================================================
# INITIALIZATION
# ============================================================================

func init() -> void:
	"""Initialize the board for a new match."""
	print("Board: Initializing for new match")
	
	# Clear card displays
	_clear_cards()
	
	# Initialize community card slots with card backs
	_initialize_community_card_backs()
	
	# Reset labels
	player_stack_label.text = "1000"
	npc_stack_label.text = "1000"
	pot_label.text = "POT: 0"
	
	# Hide action message
	hide_action_message()
	
	# Disable controls initially and hide them
	set_betting_controls_enabled(false)
	if betting_controls:
		betting_controls.visible = false

# ============================================================================
# PUBLIC INTERFACE (Called by GameView)
# ============================================================================

func show_betting_controls() -> void:
	"""Show the betting controls panel."""
	if betting_controls:
		betting_controls.visible = true

func hide_betting_controls() -> void:
	"""Hide the betting controls panel."""
	if betting_controls:
		betting_controls.visible = false

func update_controls(valid_actions: Dictionary) -> void:
	"""
	Enable/disable betting controls based on valid actions from PokerEngine.
	"""
	if not check_call_button or not raise_button or not bet_slider:
		return
	
	set_betting_controls_enabled(true)
	
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

func show_action_message(message: String, duration: float = 0.0) -> void:
	"""
	Display an action message on the board.
	If duration > 0, the message will auto-hide after that many seconds.
	If duration = 0, the message stays until manually cleared.
	"""
	# Cancel any pending hide timer to prevent premature hiding
	if message_hide_timer != null:
		# Note: SceneTreeTimer doesn't have a cancel method, so we just clear the reference
		# The old timer will still fire but won't do anything harmful
		message_hide_timer = null
	
	if action_message_label:
		action_message_label.text = message
	
	if action_message_panel:
		action_message_panel.visible = true
	
	# Auto-hide after duration if specified
	if duration > 0.0:
		message_hide_timer = get_tree().create_timer(duration)
		await message_hide_timer.timeout
		# Only hide if this is still the active timer (not replaced by a newer message)
		if message_hide_timer != null:
			hide_action_message()
			message_hide_timer = null

func hide_action_message() -> void:
	"""Hide the action message panel."""
	message_hide_timer = null  # Clear timer reference
	if action_message_panel:
		action_message_panel.visible = false
	if action_message_label:
		action_message_label.text = ""

func display_community_cards(cards: Array) -> void:
	"""Display community cards."""
	print("Board: Displaying ", cards.size(), " community cards")
	
	# Get the card slot positions from the scene
	var card_slots = community_cards_container.get_children()
	
	# Load Card scene for instantiation
	var card_scene = preload("res://scenes/Card.tscn")
	
	# Display cards in the slots
	for i in range(cards.size()):
		if i >= card_slots.size():
			break
		
		var card_data = cards[i]
		if not card_data is CardData:
			continue
		
		# Check if there's already a Card instance in this slot
		var existing_card = null
		for child in card_slots[i].get_children():
			if child.has_method("set_card"):
				existing_card = child
				break
		
		# Create or reuse card instance
		var card_instance = null
		if existing_card:
			card_instance = existing_card
		else:
			card_instance = card_scene.instantiate()
			card_slots[i].add_child(card_instance)
			# Position card to fill the slot
			card_instance.position = Vector2(0, 0)
		
		# Set card data and show
		var suit_str = _get_suit_string(card_data.suit)
		var rank_str = _get_rank_string(card_data.rank)
		card_instance.set_card(suit_str, rank_str)
		card_instance.show_face()

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

func set_betting_controls_enabled(enabled: bool) -> void:
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
	AudioManager.play_button_click()
	AudioManager.play_fold()
	player_action_taken.emit("fold", 0)

func _on_check_call_pressed() -> void:
	"""Handle check/call button press."""
	if not check_call_button:
		return
	
	AudioManager.play_button_click()
	
	# Determine action based on button text
	if check_call_button.text.begins_with("CHECK"):
		print("Board: Player clicked Check")
		player_action_taken.emit("check", 0)
	else:
		# Extract call amount from button text (format: "CALL (amount)")
		var amount_text = check_call_button.text.replace("CALL (", "").replace(")", "")
		var call_amount = int(amount_text)
		print("Board: Player clicked Call (", call_amount, ")")
		AudioManager.play_chips_bet()
		player_action_taken.emit("call", call_amount)

func _on_raise_pressed() -> void:
	"""Handle raise button press."""
	if not bet_slider:
		return
	
	var raise_amount = int(bet_slider.value)
	print("Board: Player clicked Raise to ", raise_amount)
	AudioManager.play_button_click()
	AudioManager.play_chips_bet()
	player_action_taken.emit("raise", raise_amount)

func _on_bet_slider_value_changed(value: float) -> void:
	"""Update the amount label when slider value changes."""
	if amount_label:
		amount_label.text = "Raise Amount: " + str(int(value))

# ============================================================================
# UI HELPERS (Removed GameState-dependent functions)
# ============================================================================

func _clear_cards() -> void:
	"""Clear all card displays."""
	# Note: Player cards are NOT flipped back here - they stay visible to the player
	# Only NPC cards are hidden between hands
	if npc_card_1:
		npc_card_1.show_back()
	if npc_card_2:
		npc_card_2.show_back()
	
	# Clear community cards (remove Card instances from slots, not the slots themselves)
	var card_slots = community_cards_container.get_children()
	for slot in card_slots:
		for child in slot.get_children():
			if child.has_method("set_card"):
				# Use free() instead of queue_free() for immediate cleanup
				child.free()

func _initialize_community_card_backs() -> void:
	"""Initialize community card slots with card backs at match start."""
	var card_slots = community_cards_container.get_children()
	var card_scene = preload("res://scenes/Card.tscn")
	
	# Create a Card instance showing the back in each slot
	for slot in card_slots:
		var card_instance = card_scene.instantiate()
		slot.add_child(card_instance)
		card_instance.position = Vector2(0, 0)
		# Card shows back by default, so no need to call show_back()
		# But we can explicitly call it for clarity
		card_instance.show_back()

func reset() -> void:
	"""Reset board state (for cleanup when leaving match)."""
	print("Board: Resetting state")
	
	# Hide all cards when leaving match
	if player_card_1:
		player_card_1.show_back()
	if player_card_2:
		player_card_2.show_back()
	
	_clear_cards()
	set_betting_controls_enabled(false)
	player_stack_label.text = "1000"
	npc_stack_label.text = "1000"
	pot_label.text = "POT: 0"

func prepare_for_new_hand() -> void:
	"""Prepare board for a new hand within the same match."""
	print("Board: Preparing for new hand")
	_clear_cards()
	_initialize_community_card_backs()
	# Controls will be shown/hidden by GameView based on turn
	set_betting_controls_enabled(false)
	if betting_controls:
		betting_controls.visible = false
	# Hide previous hand's action messages
	hide_action_message()

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
