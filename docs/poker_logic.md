# Poker Logic and NPC AI Implementation Plan

## 1. Overview
This document details the technical implementation plan for the core poker logic (No-Limit Texas Hold'em) and the rule-based NPC AI for the SpacePoker project. The design is based on the PRD, architectural decisions from the planning session, and Godot best practices.

The core principles of this architecture are:
- **Separation of Concerns**: The internal game state (`PokerEngine`) is decoupled from the UI (`Board.gd`) and the NPC's decision-making (`NPC_AI.gd`).
- **Centralized Mediation**: `GameView.gd` acts as the central hub, orchestrating the flow of data and commands between the different components.
- **Signal-Based Communication**: The `PokerEngine` communicates state changes to the rest of the application via signals, ensuring a reactive and loosely coupled system.
- **Transient Engine**: A new `PokerEngine` instance is created for each match and discarded afterward, simplifying state management.

## 2. New Files & Scripts
The following new scripts will be created in the `scripts/` directory:

| File Path                  | Description                                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------------- |
| `scripts/CardData.gd`      | A custom `Resource` to define a single playing card (rank and suit).                                    |
| `scripts/Deck.gd`          | A class to create, manage, and deal a 52-card deck composed of `CardData` resources.                    |
| `scripts/HandEvaluator.gd` | A static utility script with pure functions to evaluate and compare poker hands.                        |
| `scripts/PokerEngine.gd`   | The non-visual core of the poker logic, managing the hand state, rules, and game flow.                  |
| `scripts/NPC_AI.gd`        | A `Node` that encapsulates the NPC's rule-based decision-making logic, driven by personality factors.   |

## 3. Class Designs

### 3.1. `CardData.gd`
A data-only script to represent a playing card.
- **Type**: `Resource`
- **`class_name`**: `CardData`
- **Properties**:
    - `suit: int` (Enum: `HEARTS`, `DIAMONDS`, `CLUBS`, `SPADES`)
    - `rank: int` (Enum: `TWO`, `THREE`...`ACE`)
- **Purpose**: Allows cards to be treated as data assets, passed easily between components.

### 3.2. `Deck.gd`
Manages the 52-card deck for a hand.
- **Type**: `Object`
- **`class_name`**: `Deck`
- **Properties**:
    - `cards: Array[CardData]`
- **Methods**:
    - `new()`: Constructor. Creates a fresh, ordered 52-card deck.
    - `shuffle()`: Randomizes the `cards` array.
    - `deal(count: int) -> Array[CardData]`: Removes and returns the top `count` cards from the deck.

### 3.3. `HandEvaluator.gd`
A stateless utility for all hand evaluation logic.
- **Type**: `Object` (script with only static methods)
- **`class_name`**: `HandEvaluator`
- **Static Methods**:
    - `evaluate_hand(hand: Array[CardData], board: Array[CardData]) -> Dictionary`: Takes 7 cards (2 from hand, 5 from board) and returns the best 5-card hand combination. The return dictionary will be `{ "rank_enum": HandRank, "rank_name": String, "value": int }`, where `value` allows for comparing hands of the same rank (e.g., King-high flush vs. Queen-high flush).
    - `get_preflop_strength(hand: Array[CardData]) -> float`: Uses a static `PREFLOP_STRENGTHS` dictionary (to be populated) to return a normalized strength value (0.0 to 1.0) for a 2-card starting hand.

### 3.4. `PokerEngine.gd`
The state machine for a poker hand. It knows the rules but has no visual components.
- **Type**: `Object`
- **`class_name`**: `PokerEngine`
- **State Properties**:
    - `deck: Deck`
    - `pot: int`, `current_bet: int`
    - `hand_phase: Enum` (e.g., `PREFLOP`, `FLOP`, `TURN`, `RIVER`, `SHOWDOWN`)
    - `community_cards: Array[CardData]`
    - `player_stack: int`, `npc_stack: int`
    - `player_hand: Array[CardData]`, `npc_hand: Array[CardData]`
    - `player_bet_this_round: int`, `npc_bet_this_round: int`
    - `dealer_is_player: bool` (to alternate blinds)
- **Signals**:
    - `hand_started(player_stack, npc_stack)`
    - `pot_updated(new_total)`
    - `player_turn(valid_actions: Dictionary)`
    - `npc_turn(decision_context: Dictionary)`
    - `community_cards_dealt(phase: Enum, cards: Array[CardData])`
    - `player_cards_dealt(cards: Array[CardData])`
    - `showdown(player_hand, npc_hand, result: Dictionary)`: Result contains winner, winning hand name, etc.
    - `hand_ended(winner_is_player: bool)`
- **Public Methods**:
    - `new(p_stack: int, n_stack: int, p_is_dealer: bool)`: Constructor.
    - `start_new_hand()`: Resets state, shuffles deck, deals cards, posts blinds, and starts the first turn.
    - `submit_action(is_player: bool, action: String, amount: int)`: The primary input method. Processes an action, updates state, and determines the next step (next turn, next phase, or showdown).
    - `get_valid_actions() -> Dictionary`: Returns a dictionary like `{ "can_check": bool, "call_amount": int, "min_raise": int, "max_raise": int }` for the UI.
    - `get_decision_context() -> Dictionary`: Packages all non-secret game state information (`pot`, `community_cards`, `call_amount`, etc.) for the `NPC_AI`.

### 3.5. `NPC_AI.gd`
The NPC's "brain." It receives game state and personality traits, and outputs a decision.
- **Type**: `Node`
- **`class_name`**: `NPC_AI`
- **Properties**:
    - `aggression: float` (0.0-1.0)
    - `bluffing: float` (0.0-1.0)
    - `risk_aversion: float` (0.0-1.0)
    - `action_timer: Timer` (a child node used to delay the action)
- **Signals**:
    - `action_chosen(action: String, amount: int)`
- **Public Methods**:
    - `initialize(personality: Dictionary)`: Sets the three personality factors.
    - `make_decision(context: Dictionary)`: The main entry point. It receives the context from `PokerEngine`, runs its internal logic, starts the `action_timer`, and the timer's timeout signal will trigger the `action_chosen` signal emission.
- **Internal Logic**:
    1.  Calculate current hand strength using `HandEvaluator`.
    2.  Use personality factors as thresholds and probability modifiers.
        -   **Risk Aversion**: Determines the minimum hand strength required to call or raise. A high value means the NPC folds more often.
        -   **Aggression**: Increases the probability of betting or raising instead of checking or calling, and influences the size of the bet.
        -   **Bluffing**: Creates a chance for the NPC to bet or raise even with a very weak hand.
    3.  The `action_timer` introduces a short, variable delay to simulate thought and ensure the "chat-then-act" flow is respected.

## 4. Modifications to Existing Scripts

### 4.1. `GameView.gd`
Acts as the mediator connecting all poker-related components.
- **New Properties**:
    - `poker_engine: PokerEngine`
    - `npc_ai: NPC_AI`
- **Responsibilities**:
    - On match start:
        - Instance a new `PokerEngine`.
        - Instance the `NPC_AI` node and call `initialize()` with the selected NPC's personality.
        - Connect all signals from `PokerEngine` and `NPC_AI` to handler functions within `GameView.gd`.
        - Connect its own signals to `Board.gd` for UI updates.
        - Call `poker_engine.start_new_hand()`.
    - **Signal Handling**:
        - On `poker_engine.player_turn`, call `poker_engine.get_valid_actions()` and pass the result to `Board.gd` to configure the player controls.
        - On `poker_engine.npc_turn`, call `poker_engine.get_decision_context()` and pass the result to `npc_ai.make_decision()`.
        - On `board.player_action_taken`, call `poker_engine.submit_action()`.
        - On `npc_ai.action_chosen`, call `poker_engine.submit_action()`.
        - On `poker_engine.pot_updated`, `community_cards_dealt`, etc., call the relevant UI update functions on `Board.gd`.

### 4.2. `Board.gd`
The UI script for the poker table. It becomes a more passive view, controlled by `GameView`.
- **New Signals**:
    - `player_action_taken(action: String, amount: int)`
- **New Public Functions**:
    - `update_controls(valid_actions: Dictionary)`: Enables/disables Fold, Check/Call, Raise buttons and configures the raise slider's min/max values based on the dictionary from `PokerEngine`.
    - `update_pot_label(amount: int)`
    - `deal_community_card(card_data: CardData, position: int)`
    - `show_player_cards(cards: Array[CardData])`
    - `show_winner(result: Dictionary)`

## 5. Implementation & Data Flow (Example: Player Turn -> NPC Turn)
1.  **`GameState`** is `PLAYER_TURN`.
2.  `PokerEngine` emits `player_turn`.
3.  `GameView` catches this, calls `PokerEngine.get_valid_actions()`, and passes the result to `Board.gd`'s `update_controls` function.
4.  The player clicks the "Raise" button on the `Board`.
5.  `Board.gd` emits `player_action_taken("raise", 100)`.
6.  `GameView` catches this and calls `PokerEngine.submit_action(true, "raise", 100)`.
7.  `PokerEngine` processes the raise. It's now the NPC's turn to act.
8.  `GameView` updates `GameState` to `NPC_TURN`.
9.  `PokerEngine` emits `npc_turn`.
10. `GameView` catches this, calls `PokerEngine.get_decision_context()`, and passes the context dictionary to `NPC_AI.make_decision()`.
11. `NPC_AI` runs its logic, starts its `action_timer`, and on timeout emits `action_chosen("call", 80)`.
12. `GameView` catches this and calls `PokerEngine.submit_action(false, "call", 80)`.
13. The flow continues until the betting round ends or the hand concludes.

## 6. Unresolved Details & Next Steps
This plan provides the architectural blueprint. The immediate next steps will involve filling in the implementation details:
- **`HandEvaluator.gd`**: Write the algorithms to detect pairs, straights, flushes, etc., and rank them. This is a standard, solved problem with many available references.
- **`PREFLOP_STRENGTHS` Map**: Populate the pre-flop hand strength dictionary in `HandEvaluator.gd`. The Chen formula or Sklansky-Chubukov rankings can be used as a starting point.
- **NPC AI Formulas**: Define the specific mathematical formulas within `NPC_AI.gd` that translate the personality factors and hand strength into concrete decisions (e.g., `var fold_threshold = 0.8 * risk_aversion`). This will require iteration and tuning to achieve the desired behaviors.
