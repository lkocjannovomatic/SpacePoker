# GameView Implementation Plan

## Overview
This document provides a detailed implementation plan for the main GameView scene in SpacePoker. The GameView is the primary poker table interface where players engage in No-Limit Texas Hold'em matches against LLM-powered NPCs while having real-time text conversations with them.

## Architecture

### Scene Hierarchy
```
GameView.tscn (Control)
├── Board.tscn (Control) - Left side
└── Chat.tscn (Control) - Right side
```

### Global State Management
- **GameState.gd (Autoload Singleton)**: Manages core poker state machine
  - States: `PLAYER_TURN`, `NPC_TURN`, `BUSY`, etc.
  - Emits: `state_changed(new_state)` signal
  - Connected by: Board.tscn and Chat.tscn to enable/disable controls

## Component Specifications

### 1. GameView.tscn (Main Container)
**Type**: Control node

**Responsibilities**:
- Root container for the poker match interface
- Instances Board.tscn and Chat.tscn as children
- Orchestrates communication between Board and Chat components
- Manages match initialization and NPC data

**Key Functions**:
```gdscript
func init(npc_data: Dictionary) -> void:
    # Store NPC data (backstory, personality factors)
    # Load chat history from JSON and populate History tab
    # Trigger LLM call for NPC opening line (US-006)
    # Store opening line in pending_npc_response
    # Initialize GameState to start first hand
```

**Signal Connections**:
- Connects to `Board.player_action_taken(action, amount)`
- Updates GameState based on player actions

---

### 2. Board.tscn (Poker Table Interface)
**Type**: Control node (Left side of GameView)

**Purpose**: Displays all poker-related elements and player betting controls

#### Visual Components (MVP Placeholders)

**Card Display**:
- **Player Cards**: 2x TextureRect nodes (for hole cards)
- **NPC Cards**: 2x TextureRect nodes (face-down during play)
- **Community Cards**: HBoxContainer with 5x TextureRect nodes (Flop, Turn, River)

**Information Display**:
- **Player Stack Label**: Shows player's current credit count
- **NPC Stack Label**: Shows NPC's current credit count
- **Pot Label**: Shows current pot size
- **Game Phase Label**: Shows current betting round (Pre-Flop, Flop, Turn, River)

**Betting Controls**:
- **Fold Button**: Available during betting rounds
- **Check/Call Button**: Text changes based on context
  - "Check" when no bet to call
  - "Call [amount]" when facing a bet
- **Raise Button**: Initiates a raise action
- **Bet Slider (HSlider)**: 
  - Min value: Minimum legal raise
  - Max value: Player's remaining stack (all-in)
  - Only active when Raise is a valid action

#### State Management
**Listens to**: `GameState.state_changed(new_state)`

**Behavior**:
- `PLAYER_TURN`: Enable betting controls
- `NPC_TURN`: Disable all betting controls
- `BUSY`: Disable all betting controls

**Signals Emitted**:
```gdscript
signal player_action_taken(action: String, amount: int)
# Examples:
# - ("fold", 0)
# - ("check", 0)
# - ("call", bet_amount)
# - ("raise", raise_amount)
```

#### Implementation Notes
- All visual assets (cards, backgrounds) are placeholders for MVP
- Focus on functional layout and signal flow
- Visual polish is post-MVP

---

### 3. Chat.tscn (Conversation Interface)
**Type**: Control node (Right side of GameView)

**Purpose**: Manages real-time text conversations between player and NPC

#### UI Structure
```
Chat.tscn (Control)
└── TabContainer
    ├── "Chat" Tab (Control)
    │   ├── RichTextLabel (chat_display)
    │   └── LineEdit (message_input)
    └── "History" Tab (Control)
        └── RichTextLabel (history_display)
```

#### Chat Tab Specifications

**RichTextLabel (chat_display)**:
- **BBCode Enabled**: Yes
- **Scroll Following**: `true` (auto-scrolls to newest message)
- **Formatting**:
  - Player messages: `[color=cyan]Player: {message}[/color]`
  - NPC messages: `[color=orange]{npc_name}: {message}[/color]`

**LineEdit (message_input)**:
- **Enabled**: Only when `PLAYER_TURN` AND NOT `is_awaiting_response`
- **Placeholder Text** (dynamic):
  - `"Type your message..."` - When input is available
  - `"NPC is thinking..."` - When `is_awaiting_response == true`
  - `"Wait for your turn..."` - When `NPC_TURN`

#### History Tab Specifications

**RichTextLabel (history_display)**:
- **Content**: Raw, unprocessed chat log from all previous matches vs. this NPC
- **Source**: Loaded from JSON save file in `GameView.init()`
- **Load Timing**: Once at initialization (not on-demand per tab click)
- **Scope**: Does NOT include current match's conversation

#### Internal State Management

**Independent State Variable**:
```gdscript
var is_awaiting_response: bool = false
```

**Purpose**: 
- Tracks whether player has sent a message and is waiting for NPC response
- Decoupled from poker turn state (managed by GameState.gd)
- Allows player to make poker moves while waiting for chat response

**State Transitions**:
- `false → true`: Player sends message, LLM call initiated
- `true → false`: NPC displays chat response during its turn

#### Asynchronous Chat Flow

**Step 1: Player Sends Message**
```gdscript
func _on_message_input_text_submitted(text: String) -> void:
    # Requirements:
    # - GameState must be PLAYER_TURN
    # - is_awaiting_response must be false
    
    # Actions:
    1. Display player message in chat_display with BBCode
    2. Set is_awaiting_response = true
    3. Disable message_input, update placeholder to "NPC is thinking..."
    4. Call LLM (non-blocking, no await)
    5. Connect to godot-llm's response_received signal
```

**Step 2: LLM Response Received**
```gdscript
func _on_llm_response_received(response_text: String) -> void:
    # Store response in pending variable
    pending_npc_response = response_text
    
    # Do NOT display yet
    # Do NOT re-enable input
    # Wait for NPC's turn to display
```

**Step 3: NPC Displays Response (During NPC_TURN)**
- Triggered by NPC_AI script checking for `pending_npc_response`
- NPC_AI calls Chat.tscn's `display_npc_message(text)` function
- Function appends message to chat_display with NPC BBCode
- Clears `pending_npc_response`
- Sets `is_awaiting_response = false`
- Updates LineEdit placeholder (will re-enable on next PLAYER_TURN)

#### Signal Connections
**Listens to**: `GameState.state_changed(new_state)`

**Behavior**:
- Updates LineEdit enabled state and placeholder text
- Does NOT modify `is_awaiting_response` (only LLM flow does that)

---

## Key Implementation Flows

### Flow 1: Player Chats Then Makes Poker Move

**Timeline**:
1. **T=0s**: GameState = `PLAYER_TURN`
   - Player types "Nice hand!" and presses Enter
   - Chat.tscn displays message, sets `is_awaiting_response = true`
   - LineEdit disabled, shows "NPC is thinking..."
   - LLM call initiated (non-blocking)

2. **T=1s**: Player clicks "Call" button
   - Board.tscn emits `player_action_taken("call", 50)`
   - GameView catches signal, updates GameState to `NPC_TURN`
   - Board controls disable
   - LineEdit remains disabled (still awaiting response)

3. **T=3s**: LLM response arrives
   - `_on_llm_response_received()` fires
   - Response stored in `pending_npc_response`
   - No UI change yet

4. **T=3.5s**: NPC's turn begins
   - NPC_AI script activates
   - Checks for `pending_npc_response`, finds text
   - Calls `Chat.display_npc_message(text)`
   - Message appears in chat, `is_awaiting_response = false`
   - NPC_AI starts 0.5-1.0s Timer

5. **T=4.5s**: NPC makes poker move
   - Timer expires
   - NPC executes fold/call/raise logic
   - GameState returns to `PLAYER_TURN`
   - LineEdit re-enables with "Type your message..."

### Flow 2: Match Initialization (US-006 - Opening Line)

**Sequence**:
1. StartScreen calls `GameView.init(npc_data)`

2. `init()` function executes:
   ```gdscript
   func init(npc_data: Dictionary) -> void:
       # Store NPC reference
       self.current_npc = npc_data
       
       # Load chat history for "History" tab
       var history_path = "user://saves/chat_history_{npc_id}.json"
       var history_text = load_chat_history(history_path)
       $Chat.set_history_text(history_text)
       
       # Request opening line from LLM
       var prompt = generate_opening_line_prompt(npc_data)
       $Chat.request_opening_line(prompt)  # Stores in pending_npc_response
       
       # Start poker match
       GameState.start_new_hand()
   ```

3. First hand posts blinds, GameState = `NPC_TURN` (if NPC is big blind)

4. NPC_AI activates:
   - Finds `pending_npc_response` with opening line
   - Displays opening line in chat
   - Clears pending response
   - Executes poker action after Timer delay

### Flow 3: Handling Abusive Messages (US-019)

**Implementation Location**: Chat.tscn `_on_message_input_text_submitted()`

**Logic**:
```gdscript
func _on_message_input_text_submitted(text: String) -> void:
    # Display player message
    append_message("Player", text, Color.CYAN)
    
    # Check for abusive content (simple keyword filter for MVP)
    if is_abusive(text):
        # Immediate canned response (no LLM call)
        pending_npc_response = get_dismissal_response()
        # Still set awaiting flag for consistency
        is_awaiting_response = true
    else:
        # Normal LLM call
        is_awaiting_response = true
        call_llm_async(text, current_npc)
```

**Canned Responses** (rotate randomly):
- "I'd rather not talk about that."
- "Let's just play cards."
- "That's not very sporting."

---

## Data Flow Architecture

### Signal Chain: Player Action → State Update
```
[Player clicks "Call" in Board.tscn]
    ↓
Board emits: player_action_taken("call", 50)
    ↓
GameView._on_player_action_taken() catches signal
    ↓
GameView calls: GameState.set_state(GameState.NPC_TURN)
    ↓
GameState emits: state_changed(NPC_TURN)
    ↓
Board._on_state_changed(NPC_TURN) → disables controls
Chat._on_state_changed(NPC_TURN) → updates placeholder
```

### LLM Integration: Non-Blocking Chat
```
[Player sends chat message]
    ↓
Chat.tscn: Display message in RichTextLabel
    ↓
Chat.tscn: Set is_awaiting_response = true
    ↓
Chat.tscn: Disable LineEdit, update placeholder
    ↓
Chat.tscn: Call godot-llm addon (NO await)
    ↓
Chat.tscn: Connect to response_received signal
    ↓
[Player can still make poker moves]
    ↓
[Later: LLM response arrives]
    ↓
_on_llm_response_received() fires
    ↓
Store in pending_npc_response variable
    ↓
[Wait for NPC's turn]
    ↓
NPC_AI: Check pending_npc_response
    ↓
NPC_AI: Display message via Chat.display_npc_message()
    ↓
Chat.tscn: Set is_awaiting_response = false
```

---

## File Structure

### New Files to Create
```
scripts/
├── GameView.gd          # Main GameView controller
├── Board.gd             # Board component logic
├── Chat.gd              # Chat component logic
└── GameState.gd         # Autoload singleton (poker state machine)

scenes/
├── GameView.tscn        # Main match scene
├── Board.tscn           # Poker table UI (already exists, needs update)
└── Chat.tscn            # Chat interface (needs creation)
```

### Existing Files to Modify
- `StartScreen.gd`: Add logic to instance GameView and call `init(npc_data)`
- `project.godot`: Register GameState.gd as Autoload singleton

---

## Implementation Checklist

### Phase 1: Core Structure
- [ ] Create GameState.gd autoload singleton
  - [ ] Define state enum (PLAYER_TURN, NPC_TURN, BUSY)
  - [ ] Implement state_changed signal
  - [ ] Add state transition functions
- [ ] Create Chat.tscn scene
  - [ ] Add TabContainer with "Chat" and "History" tabs
  - [ ] Add RichTextLabel and LineEdit to Chat tab
  - [ ] Add RichTextLabel to History tab
- [ ] Create Chat.gd script
  - [ ] Implement is_awaiting_response state variable
  - [ ] Connect to GameState.state_changed
  - [ ] Implement placeholder text updates
- [ ] Update Board.tscn with placeholder components
  - [ ] Add card TextureRects
  - [ ] Add stack/pot Labels
  - [ ] Add betting Buttons and HSlider
- [ ] Create Board.gd script
  - [ ] Implement player_action_taken signal
  - [ ] Connect to GameState.state_changed
  - [ ] Implement control enable/disable logic

### Phase 2: GameView Integration
- [ ] Create GameView.tscn
  - [ ] Instance Board.tscn as left child
  - [ ] Instance Chat.tscn as right child
- [ ] Create GameView.gd script
  - [ ] Implement init(npc_data) function
  - [ ] Add chat history loading logic
  - [ ] Connect to Board.player_action_taken signal
  - [ ] Implement GameState update logic

### Phase 3: LLM Chat Integration
- [ ] Implement non-blocking LLM calls in Chat.gd
  - [ ] Connect to godot-llm response_received signal
  - [ ] Implement pending_npc_response storage
  - [ ] Add message display functions with BBCode
- [ ] Implement opening line flow (US-006)
  - [ ] Create opening line prompt template
  - [ ] Trigger LLM call in GameView.init()
- [ ] Implement abusive message filtering (US-019)
  - [ ] Add keyword detection function
  - [ ] Add canned response system

### Phase 4: NPC Turn Logic (Placeholder)
- [ ] Create NPC_AI.gd script (basic structure)
  - [ ] Add pending_npc_response check
  - [ ] Add Timer for delay after chat response
  - [ ] Add placeholder poker decision logic
- [ ] Connect NPC_AI to GameState.state_changed(NPC_TURN)

### Phase 5: Testing & Polish
- [ ] Test player chat → poker move flow
- [ ] Test LLM response display during NPC turn
- [ ] Test opening line on match start
- [ ] Test History tab loading
- [ ] Test state transitions and control enabling
- [ ] Validate BBCode formatting in chat display
- [ ] Test abusive message handling

---

## Technical Considerations

### Performance
- **Chat history loading**: Load once at init, not per tab click
- **LLM calls**: Non-blocking to prevent UI freezing
- **Signal-based architecture**: Loose coupling between components

### User Experience
- **Visual feedback**: LineEdit placeholder text provides clear status
- **Non-blocking chat**: Player can make poker moves while waiting for NPC
- **Sequential NPC actions**: Chat response shown before poker move for natural feel

### Extensibility
- Board.tscn uses placeholders, easily replaced with polished assets post-MVP
- Chat.gd's abusive filter can be upgraded to LLM-based detection later
- GameState.gd can be extended with additional states (e.g., SHOWDOWN, HAND_END)

---

## Dependencies

### Godot LLM Addon Integration
**Required Functions** (to be confirmed with addon documentation):
- `LLMClient.generate_async(prompt, callback_function)` or similar
- Signal: `response_received(response_text: String)`

**Prompt Templates Needed**:
1. **Opening Line Prompt**:
   ```
   You are {npc_name}. {backstory}
   You are about to start a poker game. Say a brief opening line in character.
   ```

2. **Chat Response Prompt**:
   ```
   You are {npc_name}. {backstory}
   You are playing poker. The player said: "{player_message}"
   Respond in character, briefly.
   ```

### Save File Format
**Chat History JSON** (`saves/chat_history_{npc_id}.json`):
```json
{
  "npc_id": "slot_1",
  "npc_name": "Captain Zara",
  "conversations": [
    {
      "match_timestamp": "2025-10-15T14:30:00",
      "messages": [
        {"speaker": "Player", "text": "Good luck!"},
        {"speaker": "Captain Zara", "text": "Luck is for amateurs."}
      ]
    }
  ]
}
```

---

## User Stories Addressed

This implementation directly fulfills:
- **US-005**: Start a match against an NPC
- **US-006**: NPC delivers an opening line
- **US-007 to US-010**: Player poker actions (Fold, Check, Call, Raise)
- **US-011**: View hand progression (placeholder card displays)
- **US-016**: Send a message to the NPC
- **US-017**: Receive a response from the NPC
- **US-018**: View conversation history
- **US-019**: Handle abusive player messages

Partially supports:
- **US-012 to US-015**: Showdown and match end (requires PokerEngine.gd, out of scope for this feature)

---

## Next Steps

After GameView implementation:
1. **PokerEngine.gd**: Implement actual Texas Hold'em logic
2. **NPC_AI.gd**: Build rule-based strategy using personality factors
3. **Integration**: Connect PokerEngine to Board.tscn for real gameplay
4. **Asset Creation**: Replace placeholder TextureRects with card graphics
5. **Testing**: End-to-end match playthrough with LLM-powered NPC

---

## Notes for Implementation

### Critical Success Factors
1. **State isolation**: Chat's `is_awaiting_response` must be independent of GameState poker turns
2. **Non-blocking LLM**: Player poker actions must never wait for chat responses
3. **Sequential NPC behavior**: Always show chat response before poker action
4. **Clear UI feedback**: Placeholder text must always reflect current state accurately

### Common Pitfalls to Avoid
- ❌ Using `await` on LLM calls (blocks player poker actions)
- ❌ Displaying NPC chat response immediately when received (should wait for NPC turn)
- ❌ Loading chat history every time History tab is clicked (load once at init)
- ❌ Coupling chat input enabled state directly to GameState (use independent `is_awaiting_response`)

### Debug Aids
- Add debug prints for all state transitions
- Log all signal emissions and connections
- Display current GameState and `is_awaiting_response` in debug overlay
- Add manual LLM response injection for testing without slow LLM calls
