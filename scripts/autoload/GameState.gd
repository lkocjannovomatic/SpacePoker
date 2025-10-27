extends Node

# GameState.gd - Autoload Singleton for High-Level Game State
# Manages minimal state machine for scene-level flow
# NOTE: Poker game logic is handled by PokerEngine.gd in GameView
# This singleton only tracks high-level state (in match, player's turn, etc.)

# Game state enum - represents the current phase of gameplay
enum State {
	IDLE,              # No active match
	IN_MATCH,          # Currently in a poker match
	PLAYER_TURN,       # Player's turn to act (for UI state like chat input)
	NPC_TURN,          # NPC's turn to act
	BUSY               # Processing (LLM response, animations, etc.)
}

# Signals
signal state_changed(new_state: State)

# Current state
var current_state: State = State.IDLE

func _ready():
	print("GameState: Initialized as autoload singleton")

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	var old_state = current_state
	current_state = new_state
	
	print("GameState: State changed from ", State.keys()[old_state], " to ", State.keys()[new_state])
	state_changed.emit(new_state)

func get_state() -> State:
	return current_state

func is_player_turn() -> bool:
	return current_state == State.PLAYER_TURN

func is_npc_turn() -> bool:
	return current_state == State.NPC_TURN

func reset() -> void:
	"""Reset to idle state (when leaving GameView)."""
	print("GameState: Resetting to IDLE")
	current_state = State.IDLE
