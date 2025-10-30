# Game Flow Reimplementation Plan

## Overview
This document outlines the comprehensive plan for reimplementing SpacePoker's game flow using an authoritative state machine architecture. The current implementation has several issues:
- PokerEngine signals events reactively rather than driving the flow
- UI components directly manage timing and state progression
- No clear separation between engine state and UI visualization timing
- No unit test coverage for core poker logic

## Goals
1. **Authoritative State Machine**: PokerEngine becomes the single source of truth, actively driving game progression
2. **UI/Engine Decoupling**: Implement a formal "handshake" protocol to decouple engine logic from UI timing
3. **Clear Component Responsibilities**: Each component has a single, well-defined role
4. **Comprehensive Testing**: Full gdUnit4 test coverage for PokerEngine logic
5. **Maintainability**: Sequential state flow that's easy to understand and debug

## Architecture Principles

### Core Design Pattern: State Machine + Handshake Protocol
The engine operates as a state machine that:
- Advances sequentially through well-defined states
- Emits signals when UI action is required
- **Pauses** execution waiting for UI to complete
- **Resumes** when UI calls `resume()` method
- Never relies on timers or assumptions about UI timing

### Component Role Definitions

| Component | Role | Responsibilities | Dependencies |
|-----------|------|-----------------|--------------|
| **PokerEngine** | Authoritative State Machine | Game rules, state transitions, hand evaluation, pot management | HandEvaluator, Deck, CardData |
| **GameView** | Mediator/Router | Signal routing, UI timing management, match initialization | PokerEngine, Board, Chat, NPC_AI |
| **Board** | Dumb View | Display data, emit input signals | None (purely reactive) |
| **NPC_AI** | Stateless Decider | Decision calculation based on personality | HandEvaluator |
| **Chat** | Independent UI | LLM conversation management | LLMClient |

## State Machine Design

### State Enumeration
```gdscript
enum EngineState {
    PRE_HAND,        # Check for match end, post blinds, prepare dealing
    DEALING,         # Deal cards (hole cards, flop, turn, or river)
    BETTING,         # Process betting round logic
    AWAITING_INPUT,  # Paused, waiting for player/NPC action
    EVALUATING,      # Showdown or fold - determine winner
    POST_HAND,       # Award pot, clean up, prepare next hand
    GAME_OVER        # Terminal state - match ended
}
```

### State Transition Flow
```
PRE_HAND
    ├─> GAME_OVER (if player stack = 0 or NPC stack = 0)
    └─> DEALING (post blinds, start hand)

DEALING
    ├─> emit cards_dealt → PAUSE → resume() → BETTING
    
BETTING
    ├─> emit action_required → AWAITING_INPUT
    └─> (both acted + bets matched) → next phase
        ├─> PRE_FLOP → DEALING (flop)
        ├─> FLOP → DEALING (turn)  
        ├─> TURN → DEALING (river)
        └─> RIVER → EVALUATING

AWAITING_INPUT
    └─> submit_action() → BETTING

EVALUATING
    ├─> emit showdown → PAUSE → resume() → POST_HAND
    └─> emit fold_win → PAUSE → resume() → POST_HAND

POST_HAND
    ├─> emit preparing_new_hand → PAUSE → resume() → PRE_HAND
```

## Implementation Phases

### Phase 1: Testing Infrastructure Setup
**Duration**: 1 session  
**Dependencies**: None

#### Tasks
1. **Create test directory structure**
   ```
   tests/
   ├── unit/
   │   ├── test_poker_engine.gd
   │   ├── test_hand_evaluator.gd
   │   └── test_deck.gd
   └── integration/
       └── test_game_flow.gd
   ```

2. **Setup gdUnit4 test runner**
   - Verify gdUnit4 addon is properly configured
   - Create test execution script for CI/CD
   - Test basic test discovery and execution

3. **Create test utilities**
   ```gdscript
   # tests/utils/TestHelpers.gd
   class_name TestHelpers
   
   static func create_card(rank: int, suit: int) -> CardData
   static func create_test_deck() -> Array[CardData]
   static func create_poker_engine_with_stacks(p: int, n: int) -> PokerEngine
   ```

#### Acceptance Criteria
- [ ] Test directory structure created
- [ ] Can run `godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd`
- [ ] Sample test passes successfully
- [ ] Test helpers created and functional

---

### Phase 2: PokerEngine State Machine Refactor - Core Structure
**Duration**: 2 sessions  
**Dependencies**: Phase 1 complete

#### Tasks

1. **Add state machine infrastructure to PokerEngine.gd**
   ```gdscript
   # New enums
   enum EngineState { PRE_HAND, DEALING, BETTING, AWAITING_INPUT, EVALUATING, POST_HAND, GAME_OVER }
   enum DealingPhase { HOLE_CARDS, FLOP, TURN, RIVER }
   
   # New state variables
   var current_state: EngineState = EngineState.PRE_HAND
   var dealing_phase: DealingPhase = DealingPhase.HOLE_CARDS
   var is_paused: bool = false
   var pending_state: EngineState = EngineState.PRE_HAND
   ```

2. **Implement pause/resume mechanism**
   ```gdscript
   func resume() -> void:
       """Called by GameView when UI processing is complete."""
       if not is_paused:
           print("PokerEngine Warning: resume() called but not paused")
           return
       
       is_paused = false
       _advance_state_machine()
   
   func _pause_for_ui() -> void:
       """Pause state machine execution until resume() is called."""
       is_paused = true
   ```

3. **Create state machine execution loop**
   ```gdscript
   func _advance_state_machine() -> void:
       """Execute state machine logic. Runs until pause or terminal state."""
       while not is_paused and current_state != EngineState.GAME_OVER:
           match current_state:
               EngineState.PRE_HAND:
                   _state_pre_hand()
               EngineState.DEALING:
                   _state_dealing()
               EngineState.BETTING:
                   _state_betting()
               EngineState.AWAITING_INPUT:
                   # This state is passive - wait for submit_action()
                   return
               EngineState.EVALUATING:
                   _state_evaluating()
               EngineState.POST_HAND:
                   _state_post_hand()
   ```

4. **Refactor `start_new_hand()` to use state machine**
   - Change from imperative execution to state initialization
   - Set `current_state = EngineState.PRE_HAND`
   - Call `_advance_state_machine()`

#### Acceptance Criteria
- [ ] State enum and variables added
- [ ] `resume()` and `_pause_for_ui()` implemented
- [ ] `_advance_state_machine()` loop functional
- [ ] `start_new_hand()` refactored
- [ ] Tests: State transitions occur correctly (PRE_HAND → DEALING → BETTING)

---

### Phase 3: PokerEngine State Machine - State Implementations
**Duration**: 3 sessions  
**Dependencies**: Phase 2 complete

#### Tasks

1. **Implement `_state_pre_hand()`**
   ```gdscript
   func _state_pre_hand() -> void:
       """Check for match end, post blinds, reset hand state."""
       # Check for game over
       if player_stack <= 0 or npc_stack <= 0:
           current_state = EngineState.GAME_OVER
           game_over.emit(player_stack > 0)  # New signal
           return
       
       # Reset hand state
       _reset_hand_state()
       
       # Post blinds
       _post_blinds()
       
       # Transition to dealing hole cards
       dealing_phase = DealingPhase.HOLE_CARDS
       current_state = EngineState.DEALING
   ```

2. **Implement `_state_dealing()`**
   ```gdscript
   func _state_dealing() -> void:
       """Deal cards for current phase, emit signal, pause for UI."""
       match dealing_phase:
           DealingPhase.HOLE_CARDS:
               player_hand = deck.deal(2)
               npc_hand = deck.deal(2)
               player_cards_dealt.emit(player_hand)
               _pause_for_ui()
           
           DealingPhase.FLOP:
               deck.deal_one()  # Burn
               var flop = deck.deal(3)
               community_cards.append_array(flop)
               community_cards_dealt.emit("flop", community_cards)
               _pause_for_ui()
           
           # ... similar for TURN and RIVER
       
       # After UI resumes, transition to betting
       pending_state = EngineState.BETTING
   ```

3. **Implement `_state_betting()`**
   ```gdscript
   func _state_betting() -> void:
       """Determine if betting round is complete or who acts next."""
       # Check if round is complete
       if _is_betting_round_complete():
           _complete_betting_round()
           return
       
       # Check if all-in situation (auto-deal remaining cards)
       if _is_all_in_situation():
           _handle_all_in_runout()
           return
       
       # Determine who acts next
       if _should_player_act():
           current_state = EngineState.AWAITING_INPUT
           player_action_required.emit(get_valid_actions())  # New signal name
       else:
           current_state = EngineState.AWAITING_INPUT
           npc_action_required.emit(get_decision_context())  # New signal name
   ```

4. **Implement `_state_evaluating()`**
   ```gdscript
   func _state_evaluating() -> void:
       """Determine winner via showdown or fold."""
       var result = _evaluate_winner()
       
       if result.showdown:
           showdown.emit(player_hand, npc_hand, result)
       else:
           fold_win.emit(result.winner_is_player, pot)  # New signal
       
       _pause_for_ui()
       pending_state = EngineState.POST_HAND
   ```

5. **Implement `_state_post_hand()`**
   ```gdscript
   func _state_post_hand() -> void:
       """Award pot, update stacks, prepare for next hand."""
       # Award pot (already done in evaluating, stacks updated)
       
       # Emit signal for UI cleanup
       preparing_new_hand.emit()
       _pause_for_ui()
       
       # Alternate dealer
       dealer_is_player = not dealer_is_player
       
       # Transition to next hand
       pending_state = EngineState.PRE_HAND
   ```

6. **Refactor `submit_action()` to work with state machine**
   ```gdscript
   func submit_action(is_player: bool, action: String, amount: int = 0) -> void:
       """Process action and resume state machine."""
       if current_state != EngineState.AWAITING_INPUT:
           print("PokerEngine Error: submit_action called in wrong state")
           return
       
       # Process action (existing logic)
       _process_action(is_player, action, amount)
       
       # Return to BETTING state
       current_state = EngineState.BETTING
       _advance_state_machine()
   ```

#### Acceptance Criteria
- [ ] All state functions implemented
- [ ] `submit_action()` refactored for state machine
- [ ] Tests: Full hand completes from start to finish
- [ ] Tests: All-in scenario auto-deals remaining cards
- [ ] Tests: Fold ends hand immediately
- [ ] Tests: Match ends when stack reaches 0

---

### Phase 4: New Signal Interface & UI Handshake
**Duration**: 2 sessions  
**Dependencies**: Phase 3 complete

#### Tasks

1. **Update PokerEngine signal definitions**
   ```gdscript
   # Remove old signals, add new ones
   signal game_over(player_won: bool)  # New
   signal player_action_required(valid_actions: Dictionary)  # Renamed from player_turn
   signal npc_action_required(context: Dictionary)  # Renamed from npc_turn
   signal preparing_new_hand()  # New
   signal fold_win(winner_is_player: bool, pot_amount: int)  # New
   
   # Keep existing: pot_updated, community_cards_dealt, player_cards_dealt, showdown
   ```

2. **Update GameView.gd signal connections**
   - Connect to new signal names
   - Implement `resume()` calls after UI processing
   - Remove direct state management logic

3. **Implement handshake protocol in GameView**
   ```gdscript
   func _on_community_cards_dealt(phase: String, cards: Array) -> void:
       print("GameView: Community cards dealt - ", phase)
       AudioManager.play_card_deal()
       
       if board:
           board.display_community_cards(cards)
       
       # Wait for animation/display, then resume engine
       await get_tree().create_timer(0.5).timeout
       poker_engine.resume()
   
   func _on_showdown(player_hand: Array, npc_hand: Array, result: Dictionary) -> void:
       print("GameView: Showdown")
       AudioManager.play_card_flip()
       
       if board:
           board.display_showdown(player_hand, npc_hand, result)
           # Show message will be moved to board
       
       # Keep showdown visible for 3 seconds
       await get_tree().create_timer(3.0).timeout
       poker_engine.resume()
   
   func _on_preparing_new_hand() -> void:
       print("GameView: Preparing new hand")
       
       if board:
           board.prepare_for_new_hand()
       
       # Brief delay before next hand
       await get_tree().create_timer(1.5).timeout
       poker_engine.resume()
   ```

4. **Update Board.gd to remove timer logic**
   ```gdscript
   # Split show_action_message into:
   func show_message(text: String) -> void:
       """Display a message (no auto-hide)."""
       if action_message_label:
           action_message_label.text = text
       if action_message_panel:
           action_message_panel.visible = true
   
   func hide_message() -> void:
       """Hide the message panel."""
       if action_message_panel:
           action_message_panel.visible = false
       if action_message_label:
           action_message_label.text = ""
   
   # Remove: message_hide_timer logic
   ```

5. **Update GameView to manage Board message timing**
   ```gdscript
   func _on_npc_action_chosen(action: String, amount: int) -> void:
       print("GameView: NPC chose action - ", action)
       
       if board and current_npc:
           var message = _format_action_message(action, amount, false)
           board.show_message(message)
       
       # Show NPC action for 2 seconds before submitting
       await get_tree().create_timer(2.0).timeout
       
       if poker_engine:
           poker_engine.submit_action(false, action, amount)
   ```

#### Acceptance Criteria
- [ ] All signal renames completed
- [ ] GameView implements handshake with `resume()` calls
- [ ] Board.gd timer logic removed
- [ ] GameView manages all UI timing
- [ ] Tests: Manual verification that UI timing feels natural
- [ ] Tests: Verify no race conditions or premature state advancement

---

### Phase 5: Board.gd Refactoring - Pure View Component
**Duration**: 1 session  
**Dependencies**: Phase 4 complete

#### Tasks

1. **Remove all GameState dependencies from Board.gd**
   - Delete `_on_game_state_changed()` and related signal connections
   - Remove any direct `GameState` references

2. **Simplify Board to pure display functions**
   - All functions should only update display
   - No timers, no state logic, no automatic reactions
   - Only emit `player_action_taken` signal

3. **Verify Board public interface**
   ```gdscript
   # Display updates (called by GameView)
   func init() -> void
   func update_pot_label(amount: int) -> void
   func update_stack_labels(player_stack: int, npc_stack: int) -> void
   func display_player_cards(cards: Array) -> void
   func display_community_cards(cards: Array) -> void
   func display_showdown(p_hand: Array, n_hand: Array, result: Dictionary) -> void
   
   # Message display (GameView manages timing)
   func show_message(text: String) -> void
   func hide_message() -> void
   
   # Control updates
   func show_betting_controls() -> void
   func hide_betting_controls() -> void
   func update_controls(valid_actions: Dictionary) -> void
   func set_betting_controls_enabled(enabled: bool) -> void
   
   # Lifecycle
   func reset() -> void
   func prepare_for_new_hand() -> void
   
   # Signal emitted
   signal player_action_taken(action: String, amount: int)
   ```

#### Acceptance Criteria
- [ ] All GameState dependencies removed from Board.gd
- [ ] All timer logic removed from Board.gd
- [ ] Board only contains display and input emission code
- [ ] Tests: Manual testing confirms Board displays update correctly

---

### Phase 6: NPC_AI Integration with New Signals
**Duration**: 1 session  
**Dependencies**: Phase 4 complete

#### Tasks

1. **Update GameView NPC_AI signal handling**
   ```gdscript
   func _on_npc_action_required(context: Dictionary) -> void:
       """Handle NPC turn from PokerEngine."""
       print("GameView: NPC's turn - delegating to NPC_AI")
       
       # Update GameState for UI components (like Chat)
       GameState.set_state(GameState.State.NPC_TURN)
       
       # Hide betting controls during NPC's turn
       if board:
           board.hide_betting_controls()
       
       # Check if chat has pending response
       if chat and chat.has_pending_response():
           var response = chat.get_pending_response()
           chat.display_npc_message(response)
           await get_tree().create_timer(0.3).timeout
       
       # Trigger NPC AI decision
       if npc_ai:
           npc_ai.make_decision(context)
   ```

2. **Verify NPC_AI remains stateless**
   - Confirm it receives all needed context in `make_decision()`
   - No internal game state tracking
   - Only personality factors stored

#### Acceptance Criteria
- [ ] GameView correctly handles `npc_action_required` signal
- [ ] NPC_AI receives complete context
- [ ] NPC decisions work correctly with new state machine
- [ ] Tests: NPC makes valid decisions in all game phases

---

### Phase 7: Comprehensive Unit Testing
**Duration**: 3 sessions  
**Dependencies**: Phases 1-6 complete

#### Test Coverage Requirements

##### 7.1 PokerEngine Core Logic Tests
**File**: `tests/unit/test_poker_engine.gd`

```gdscript
# Test categories:

## Initialization & Setup
- test_engine_initializes_with_correct_stacks()
- test_start_new_hand_resets_state()
- test_blinds_posted_correctly_player_dealer()
- test_blinds_posted_correctly_npc_dealer()

## State Machine Flow
- test_state_transitions_pre_hand_to_dealing()
- test_state_transitions_dealing_to_betting()
- test_state_transitions_betting_to_awaiting_input()
- test_state_pauses_for_ui_after_card_dealing()
- test_resume_advances_state_machine()
- test_multiple_resume_calls_ignored()

## Betting Round Logic
- test_betting_round_complete_when_bets_matched()
- test_betting_round_continues_after_raise()
- test_check_check_completes_betting_round()
- test_bet_call_completes_betting_round()
- test_raise_resets_opponent_acted_flag()

## Player Actions
- test_player_fold_awards_pot_to_npc()
- test_player_check_when_no_bet()
- test_player_call_matches_bet()
- test_player_raise_increases_current_bet()
- test_player_all_in_bet()
- test_invalid_action_in_wrong_state_rejected()

## NPC Actions
- test_npc_fold_awards_pot_to_player()
- test_npc_check_when_no_bet()
- test_npc_call_matches_bet()
- test_npc_raise_increases_current_bet()
- test_npc_all_in_bet()

## Hand Progression
- test_preflop_to_flop_transition()
- test_flop_to_turn_transition()
- test_turn_to_river_transition()
- test_river_to_showdown_transition()

## All-In Scenarios
- test_all_in_situation_detected()
- test_all_in_auto_deals_remaining_cards()
- test_all_in_skips_betting_rounds()
- test_side_pot_not_created_in_heads_up()

## Showdown & Evaluation
- test_showdown_player_wins_with_better_hand()
- test_showdown_npc_wins_with_better_hand()
- test_showdown_tie_splits_pot()
- test_fold_before_showdown_no_reveal()

## Pot & Stack Management
- test_pot_updates_correctly_after_bets()
- test_stacks_decrease_after_bets()
- test_stacks_increase_after_winning()
- test_pot_awarded_correctly_to_winner()

## Match End Conditions
- test_game_over_when_player_stack_zero()
- test_game_over_when_npc_stack_zero()
- test_game_over_signal_emitted()
- test_multiple_hands_until_elimination()

## Edge Cases
- test_minimum_bet_sizing()
- test_maximum_bet_sizing()
- test_cannot_bet_more_than_stack()
- test_dealer_alternates_each_hand()
- test_small_blind_acts_first_preflop()
- test_non_dealer_acts_first_postflop()
```

##### 7.2 HandEvaluator Tests
**File**: `tests/unit/test_hand_evaluator.gd`

```gdscript
# Test categories:

## Hand Detection
- test_royal_flush_detection()
- test_straight_flush_detection()
- test_four_of_a_kind_detection()
- test_full_house_detection()
- test_flush_detection()
- test_straight_detection()
- test_three_of_a_kind_detection()
- test_two_pair_detection()
- test_one_pair_detection()
- test_high_card_fallback()

## Hand Comparison
- test_compare_different_hand_ranks()
- test_compare_same_rank_different_kickers()
- test_compare_identical_hands_tie()
- test_compare_full_house_with_different_trips()
- test_compare_two_pair_with_different_high_pair()

## Preflop Strength
- test_preflop_pocket_aces_highest()
- test_preflop_pocket_pairs_ranked()
- test_preflop_suited_connectors_bonus()
- test_preflop_offsuit_trash_low()
- test_preflop_strength_range_0_to_1()

## Edge Cases
- test_wheel_straight_A2345()
- test_ace_high_vs_king_high_straight()
- test_all_seven_cards_same_suit_best_five()
- test_best_five_from_seven_selection()
```

##### 7.3 Deck Tests
**File**: `tests/unit/test_deck.gd`

```gdscript
# Test categories:

## Initialization
- test_deck_has_52_cards()
- test_deck_has_all_unique_cards()
- test_reset_and_shuffle_creates_new_deck()

## Dealing
- test_deal_one_card()
- test_deal_multiple_cards()
- test_dealt_cards_removed_from_deck()
- test_cannot_deal_more_than_52_cards()

## Shuffling
- test_shuffle_changes_order()
- test_shuffle_preserves_all_cards()
```

##### 7.4 Integration Tests
**File**: `tests/integration/test_game_flow.gd`

```gdscript
# Full hand simulation tests:

- test_complete_hand_to_showdown()
- test_complete_hand_with_fold()
- test_complete_hand_with_all_in()
- test_multiple_hands_in_sequence()
- test_match_to_elimination()
- test_preflop_betting_order()
- test_postflop_betting_order()
- test_all_four_betting_rounds()
```

#### Test Execution Plan
1. Write tests incrementally as each phase completes
2. Run tests after every code change
3. Achieve minimum 80% code coverage for PokerEngine
4. Setup CI/CD to run tests automatically

#### Acceptance Criteria
- [ ] All test files created
- [ ] Minimum 80% code coverage for PokerEngine.gd
- [ ] All tests pass successfully
- [ ] No flaky or intermittent test failures
- [ ] Tests run successfully in headless mode (CI/CD ready)

---

### Phase 8: Documentation & Code Cleanup
**Duration**: 1 session  
**Dependencies**: All previous phases complete

#### Tasks

1. **Update code comments and docstrings**
   - Add detailed comments to state machine logic
   - Document handshake protocol expectations
   - Update all function docstrings

2. **Create architecture diagram**
   - Visual representation of state flow
   - Signal flow diagram
   - Component interaction diagram

3. **Update existing documentation**
   - Update `docs/game_view_summary.md` with new architecture
   - Update `docs/poker_logic.md` with state machine details
   - Create `docs/testing_guide.md` with test running instructions

4. **Code cleanup**
   - Remove deprecated code paths
   - Remove commented-out code
   - Ensure consistent code style
   - Run static analysis (if available)

#### Acceptance Criteria
- [ ] All functions have accurate docstrings
- [ ] Architecture diagrams created
- [ ] Documentation files updated
- [ ] No deprecated code remains
- [ ] Code passes style checks

---

## Testing Strategy

### Unit Testing Approach
- **Test-Driven Development**: Write tests before implementing state functions where possible
- **Isolation**: Each test should be independent and not rely on other tests
- **Mocking**: Use test helpers to create controlled game states
- **Assertions**: Use gdUnit4's assertion library for clear test failures

### Test Organization
```
tests/
├── unit/                      # Pure logic tests (no UI)
│   ├── test_poker_engine.gd  # State machine, betting, pot management
│   ├── test_hand_evaluator.gd # Hand rankings and comparison
│   └── test_deck.gd           # Card dealing and shuffling
├── integration/               # Multi-component tests
│   └── test_game_flow.gd      # Full hand simulations
└── utils/                     # Test helpers and utilities
    └── TestHelpers.gd         # Card creation, engine setup
```

### CI/CD Integration
```powershell
# Command to run all tests in headless mode
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd

# Expected output: All tests pass, coverage report generated
```

### Manual Testing Checklist
After all phases complete, perform manual testing:
- [ ] Play through a complete match from start to elimination
- [ ] Verify all UI animations play smoothly
- [ ] Test all-in scenarios (player all-in, NPC all-in)
- [ ] Test fold scenarios (preflop, postflop)
- [ ] Verify stack and pot displays update correctly
- [ ] Test bet slider controls (min, max, intermediate values)
- [ ] Verify NPC chat integration still works
- [ ] Test match end flow (victory and defeat)
- [ ] Verify return to start screen after match

---

## Risk Mitigation

### Known Risks & Mitigation Strategies

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| State machine complexity introduces bugs | Medium | High | Comprehensive unit tests, small incremental changes |
| UI handshake timing feels unnatural | Medium | Medium | Manual testing, adjustable timing constants, playtesting |
| Breaking existing gameplay during refactor | High | High | Keep old code until tests pass, incremental rollout |
| Test coverage gaps | Medium | Medium | Code review of test suite, manual verification |
| Performance regression from state machine overhead | Low | Low | Profile before/after, optimize if needed |
| Signal emission order issues | Medium | Medium | Document signal contracts, integration tests |

### Rollback Plan
If critical issues arise during implementation:
1. **Git branching**: Create `feature/state-machine-refactor` branch
2. **Keep main stable**: Don't merge until all tests pass
3. **Incremental commits**: Can revert individual phases if needed
4. **Backup current working version**: Tag current main as `v0.1-pre-refactor`

---

## Success Criteria

### Phase Completion
Each phase is complete when:
- All tasks are checked off
- All acceptance criteria are met
- All tests pass
- Code review completed (self-review for solo dev)

### Overall Project Success
The reimplementation is successful when:
1. **All unit tests pass** with minimum 80% coverage
2. **Manual testing checklist** fully completed
3. **Performance**: No noticeable lag or timing issues
4. **Maintainability**: Code is more readable and easier to debug than before
5. **Functionality**: All existing features work correctly
6. **Documentation**: Architecture is clearly documented

---

## Timeline Estimate

| Phase | Sessions | Cumulative |
|-------|----------|------------|
| Phase 1: Testing Infrastructure | 1 | 1 |
| Phase 2: State Machine Core | 2 | 3 |
| Phase 3: State Implementations | 3 | 6 |
| Phase 4: Signal Interface & Handshake | 2 | 8 |
| Phase 5: Board Refactoring | 1 | 9 |
| Phase 6: NPC_AI Integration | 1 | 10 |
| Phase 7: Comprehensive Testing | 3 | 13 |
| Phase 8: Documentation & Cleanup | 1 | 14 |

**Total Estimated Duration**: 14 work sessions (approximately 3-4 weeks at 3-4 sessions/week)

---

## Appendix A: State Machine Pseudocode

### Complete State Machine Flow
```
function start_new_hand():
    current_state = PRE_HAND
    _advance_state_machine()

function _advance_state_machine():
    while not is_paused and current_state != GAME_OVER:
        match current_state:
            PRE_HAND:
                if player_stack <= 0 or npc_stack <= 0:
                    current_state = GAME_OVER
                    emit game_over(player_stack > 0)
                    return
                
                _reset_hand_state()
                _post_blinds()
                dealing_phase = HOLE_CARDS
                current_state = DEALING
            
            DEALING:
                match dealing_phase:
                    HOLE_CARDS:
                        deal_hole_cards()
                        emit player_cards_dealt
                        _pause_for_ui()
                        pending_state = BETTING
                        return
                    
                    FLOP:
                        deal_flop()
                        emit community_cards_dealt("flop")
                        _pause_for_ui()
                        pending_state = BETTING
                        return
                    
                    # ... similar for TURN, RIVER
            
            BETTING:
                if _is_betting_round_complete():
                    _advance_to_next_phase()  # Updates current_state
                    continue  # Loop to next state
                
                if _is_all_in_situation():
                    _handle_all_in_runout()  # Auto-deals, goes to EVALUATING
                    continue
                
                # Determine who acts
                current_state = AWAITING_INPUT
                if _player_should_act():
                    emit player_action_required(get_valid_actions())
                else:
                    emit npc_action_required(get_decision_context())
                return  # Wait for submit_action()
            
            AWAITING_INPUT:
                # Passive state - wait for submit_action()
                return
            
            EVALUATING:
                result = _evaluate_winner()
                if result.showdown:
                    emit showdown(player_hand, npc_hand, result)
                else:
                    emit fold_win(result.winner_is_player, pot)
                
                _pause_for_ui()
                pending_state = POST_HAND
                return
            
            POST_HAND:
                emit preparing_new_hand()
                _pause_for_ui()
                dealer_is_player = not dealer_is_player
                pending_state = PRE_HAND
                return

function resume():
    if not is_paused:
        return
    
    is_paused = false
    
    if pending_state != current_state:
        current_state = pending_state
    
    _advance_state_machine()

function submit_action(is_player, action, amount):
    if current_state != AWAITING_INPUT:
        print("Error: Wrong state for action")
        return
    
    _process_action(is_player, action, amount)
    current_state = BETTING
    _advance_state_machine()
```

---

## Appendix B: Signal Reference

### PokerEngine Signals (New)

| Signal | Parameters | When Emitted | UI Response |
|--------|-----------|--------------|-------------|
| `game_over` | `(player_won: bool)` | Match ends, stack = 0 | Show match summary, return to menu |
| `player_action_required` | `(valid_actions: Dictionary)` | Player's turn to act | Enable/show betting controls |
| `npc_action_required` | `(context: Dictionary)` | NPC's turn to act | Request NPC_AI decision, hide controls |
| `player_cards_dealt` | `(cards: Array)` | Hole cards dealt | Display player cards, call resume() |
| `community_cards_dealt` | `(phase: String, cards: Array)` | Flop/turn/river dealt | Display cards, play sound, call resume() |
| `pot_updated` | `(new_total: int)` | Pot changes | Update pot label |
| `showdown` | `(p_hand, n_hand, result: Dict)` | Hand goes to showdown | Reveal NPC cards, show winner, call resume() |
| `fold_win` | `(winner_is_player: bool, pot: int)` | Someone folds | Show fold message, call resume() |
| `preparing_new_hand` | `()` | Before next hand starts | Clean board, call resume() |

### Signal Contracts
Each signal that requires a handshake (resume) will **pause** the engine immediately after emission. GameView MUST call `poker_engine.resume()` after UI processing completes.

---

## Appendix C: Helper Functions to Extract

During refactoring, extract these helper functions for better organization:

```gdscript
# Betting round helpers
func _is_betting_round_complete() -> bool
func _advance_to_next_phase() -> void
func _is_all_in_situation() -> bool
func _handle_all_in_runout() -> void

# Action processing
func _process_action(is_player: bool, action: String, amount: int) -> void
func _update_pot_and_stacks(is_player: bool, amount: int) -> void

# Winner evaluation
func _evaluate_winner() -> Dictionary
func _award_pot_to_player() -> void
func _award_pot_to_npc() -> void
func _split_pot() -> void

# State reset
func _reset_hand_state() -> void
func _reset_betting_round_state() -> void

# Turn order
func _player_should_act() -> bool
func _determine_first_actor() -> bool
```

---

## Conclusion

This implementation plan provides a clear, phased approach to reimplementing SpacePoker's game flow using an authoritative state machine with UI handshake protocol. By following this plan:

1. **Code Quality**: The PokerEngine becomes a clear, testable state machine
2. **Maintainability**: Sequential state flow is easier to debug and extend
3. **Separation of Concerns**: UI and game logic are properly decoupled
4. **Testing**: Comprehensive test coverage ensures correctness
5. **Reliability**: Handshake protocol prevents timing-related bugs

The phased approach allows for incremental progress with validation at each step, minimizing risk while making significant architectural improvements.
