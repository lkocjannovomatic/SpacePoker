# UI Implementation Plan - SpacePoker

## Overview
This document provides a step-by-step implementation plan for the UI/UX layer of SpacePoker, assuming all required visual and audio assets are already available. The implementation follows the "Retro-Futuristic Casino" theme established in the UI planning sessions.

## Asset Dependencies
Before implementation begins, the following assets must be available:

### Visual Assets
- **Backgrounds:**
  - `bg_space_casino.png` - Main background for all screens
  - `table_holographic.png` - Poker table surface texture
  
- **UI Panels:**
  - `panel_metallic.png` - NPC slot occupied state
  - `panel_console.png` - Info readout panels
  - `panel_crt.png` - Chat interface background
  - `panel_terminal.png` - Statistics screen background
  - `panel_modal.png` - Winner announcement overlay
  - `panel_dialog.png` - Confirmation dialog background

- **Buttons:**
  - `btn_console_normal.png` - Default button state
  - `btn_console_hover.png` - Hover state
  - `btn_console_pressed.png` - Pressed state
  - `btn_console_disabled.png` - Disabled state
  - `btn_glow.png` - Turn indicator glow effect

- **Cards:**
  - 52 card face textures (e.g., `card_spades_ace.png`, `card_hearts_2.png`, etc.)
  - `card_back.png` - Card back design
  - `card_slot_empty.png` - Empty card slot indicator
  - `card_slot_active.png` - Active/illuminated card slot

- **Slider:**
  - `slider_track.png` - Bet slider track
  - `slider_grabber.png` - Bet slider handle

- **Spinner:**
  - `spinner.png` - Loading/generating indicator animation frames or animated texture

### Font Assets
- `Orbitron-Regular.ttf` - Futuristic font for titles and headers
- `RobotoMono-Regular.ttf` - Monospaced font for body text, chat, and data readouts

### Audio Assets
- **UI Sounds:**
  - `sfx_button_click.wav` - Button press feedback
  - `sfx_button_hover.wav` - Button hover feedback
  - `sfx_npc_generate.wav` - NPC generation complete
  - `sfx_npc_delete.wav` - NPC deletion
  
- **Game Sounds:**
  - `sfx_card_deal.wav` - Card dealing
  - `sfx_card_flip.wav` - Card reveal at showdown
  - `sfx_chips_bet.wav` - Placing a bet
  - `sfx_chips_collect.wav` - Winning pot
  - `sfx_fold.wav` - Player folds
  - `sfx_turn_notify.wav` - Player's turn begins
  - `sfx_winner.wav` - Match winner announcement

- **Background Music:**
  - `music_ambient_casino.ogg` - Looping background music

## Implementation Phases

### Phase 1: Theme Setup
**Goal:** Create reusable theme resource and configure fonts

#### Steps:
1. **Import Fonts**
   - Copy `Orbitron-Regular.ttf` and `RobotoMono-Regular.ttf` to `assets/fonts/`
   - Ensure Godot imports them as dynamic fonts

2. **Create Theme Resource** (`themes/main_theme.tres`)
   - Create new Theme resource if not exists
   - Configure default fonts:
     - Set `Orbitron` as default font for: Label (large), Button, WindowDialog titles
     - Set `RobotoMono` as default font for: Label (small), LineEdit, TextEdit, RichTextLabel
   - Configure font sizes:
     - Title: 24px (Orbitron)
     - Subtitle: 18px (Orbitron)
     - Body: 14px (RobotoMono)
     - Small: 12px (RobotoMono)

3. **Configure Theme Styles**
   - **Panel StyleBox:**
     - Create StyleBoxTexture using `panel_console.png`
     - Set appropriate margins and expansion settings
   - **Button StyleBox:**
     - Normal: `btn_console_normal.png`
     - Hover: `btn_console_hover.png`
     - Pressed: `btn_console_pressed.png`
     - Disabled: `btn_console_disabled.png`
   - **Dialog StyleBox:**
     - Create StyleBoxTexture using `panel_dialog.png`

4. **Apply Theme Globally**
   - In Project Settings → GUI → Theme, set `themes/main_theme.tres` as the default theme

---

### Phase 2: Reusable Components

#### Component 1: Card Scene (`scenes/Card.tscn`)
**Purpose:** Reusable playing card with dynamic texture and state management

**Scene Structure:**
```
Card (TextureRect)
└── Script: Card.gd
```

**Implementation Steps:**
1. Create new scene with TextureRect as root
2. Set default texture to `card_back.png`
3. Configure rect_min_size: Vector2(80, 120) (or appropriate card size)
4. Add script `scripts/Card.gd` with properties:
   - `suit: String` (spades, hearts, clubs, diamonds)
   - `rank: String` (A, 2-10, J, Q, K)
   - `is_face_up: bool = false`
   - `card_back_texture: Texture` (preload card_back.png)
   - Dictionary mapping suit+rank to texture paths

5. Implement methods:
   - `set_card(suit: String, rank: String)` - Sets card identity
   - `flip_to_face()` - Shows card face with animation
   - `flip_to_back()` - Shows card back with animation
   - `_update_texture()` - Internal method to load correct texture

6. Add flip animation:
   - Use Tween to scale X from 1.0 → 0.0 → 1.0
   - Switch texture at scale 0.0 (card edge-on)
   - Duration: 0.3 seconds

**Testing Checklist:**
- [ ] Card displays back texture by default
- [ ] `set_card()` correctly loads all 52 card textures
- [ ] Flip animation plays smoothly
- [ ] Multiple cards can exist simultaneously

---

#### Component 2: NPCSlot Scene (`scenes/NPCSlot.tscn`)
**Purpose:** Displays NPC state (empty, generating, occupied) on start screen

**Current Structure (to be modified):**
```
NPCSlot (Panel)
├── VBoxContainer
│   ├── NameLabel
│   ├── GenerateButton
│   ├── PlayButton
│   └── DeleteButton
└── Script: NPCSlot.gd
```

**Implementation Steps:**
1. **Replace Panel Background:**
   - Set Panel's custom StyleBox to `panel_console.png` for empty state
   - Set to `panel_metallic.png` when occupied

2. **Add Loading State:**
   - Add TextureRect node for spinner: `LoadingSpinner`
   - Initially hidden
   - Position centered in panel
   - Connect AnimationPlayer for rotation or use AnimatedSprite if spinner has frames

3. **Style Buttons:**
   - Buttons will automatically use theme styles (already configured in Phase 1)
   - Verify visibility states:
     - Empty: Show `GenerateButton` only
     - Generating: Hide all buttons, show `LoadingSpinner`
     - Occupied: Show `NameLabel`, `PlayButton`, `DeleteButton`

4. **Update Script Logic:**
   - Add `state: int` enum (EMPTY, GENERATING, OCCUPIED)
   - Method `set_state(new_state: int)` to manage visibility
   - Signal `generate_requested` when GenerateButton clicked
   - Signal `play_requested(npc_data)` when PlayButton clicked
   - Signal `delete_requested(npc_data)` when DeleteButton clicked

5. **Visual Polish:**
   - Add subtle glow shader to occupied slots (optional)
   - Ensure text contrast is readable on metallic background

**Testing Checklist:**
- [ ] Empty state shows only Generate button
- [ ] Clicking Generate triggers loading spinner
- [ ] Occupied state shows name and action buttons
- [ ] Delete confirmation dialog appears
- [ ] All buttons have hover/click feedback

---

#### Component 3: Dialog Scene (`scenes/Dialog.tscn`)
**Purpose:** Reusable confirmation dialog with custom theme

**Current Structure (to be modified):**
```
Dialog (WindowDialog or AcceptDialog)
├── VBoxContainer
│   ├── MessageLabel
│   └── HBoxContainer
│       ├── ConfirmButton
│       └── CancelButton
└── Script: Dialog.gd
```

**Implementation Steps:**
1. **Apply Custom Background:**
   - Override dialog's Panel StyleBox with `panel_dialog.png`
   - Ensure padding allows for sci-fi border decoration

2. **Configure Text:**
   - Set `MessageLabel` font to RobotoMono, size 14px
   - Center align text
   - Set text color to neon cyan/green (#00FFCC or similar)

3. **Style Buttons:**
   - Use theme console button styles
   - Set button text (Confirm: "CONFIRM", Cancel: "CANCEL")

4. **Add Glow Effect (Optional):**
   - Add Light2D or shader for subtle border glow
   - Animate pulsing effect for urgency

5. **Script Enhancements:**
   - Method `show_dialog(message: String, callback: FuncRef)`
   - Handle both confirm and cancel signals
   - Auto-hide on button press

**Testing Checklist:**
- [ ] Dialog appears centered on screen
- [ ] Message text is readable
- [ ] Confirm/Cancel buttons work correctly
- [ ] Dialog closes on any button press
- [ ] Can be reused for different messages

---

### Phase 3: Start Screen (`scenes/StartScreen.tscn`)

**Current Structure:**
```
StartScreen (Control)
├── Background (ColorRect or TextureRect)
├── VBoxContainer
│   ├── TitleLabel
│   ├── GridContainer (8 NPCSlot instances)
│   └── HBoxContainer
│       └── StatisticsButton
└── Script: StartScreen.gd
```

**Implementation Steps:**
1. **Set Background:**
   - Change `Background` to TextureRect
   - Set texture to `bg_space_casino.png`
   - Set expand mode to "Keep Aspect Covered" or "Scale"
   - Set anchor preset to Full Rect

2. **Style Title:**
   - `TitleLabel` text: "SPACEPOKER"
   - Font: Orbitron, 32px
   - Color: Bright neon (e.g., #00FFFF)
   - Add outline or glow shader for visibility
   - Align center

3. **Configure GridContainer:**
   - Columns: 4 (2 rows of 4 slots)
   - Add separation: 20px horizontal, 20px vertical
   - Center container vertically using VBoxContainer anchors
   - Add top/bottom margins to VBoxContainer (e.g., 50px top, 30px bottom)

4. **Populate NPCSlot Instances:**
   - Ensure 8 NPCSlot instances are children of GridContainer
   - Connect their signals to StartScreen script:
     - `generate_requested` → `_on_npc_generate_requested(slot_index)`
     - `play_requested` → `_on_npc_play_requested(npc_data)`
     - `delete_requested` → `_on_npc_delete_requested(npc_data)`

5. **Style Statistics Button:**
   - Will use theme console button style
   - Text: "MISSION LOG" or "STATISTICS"
   - Position at bottom center
   - Connect `pressed` signal to navigate to StatisticsScreen

6. **Add Audio:**
   - Connect button hover/click signals to play UI sounds
   - Play `sfx_npc_generate.wav` when NPC generation completes

**Testing Checklist:**
- [ ] Background displays correctly at all resolutions
- [ ] Title is prominent and readable
- [ ] 8 NPC slots are evenly spaced
- [ ] All slots can generate/delete/play
- [ ] Statistics button navigates correctly
- [ ] UI sounds play on interaction

---

### Phase 4: Board Scene (`scenes/Board.tscn`)

**Goal:** Rebuild layout from VBoxContainer to spatial design with TextureRect base

**Target Structure:**
```
Board (Control - Full Rect)
├── TableBackground (TextureRect)
├── CommunityCards (Control container)
│   ├── CardSlot1 (TextureRect - empty slot)
│   ├── CardSlot2
│   ├── CardSlot3 (Flop)
│   ├── CardSlot4 (Turn)
│   └── CardSlot5 (River)
├── PlayerHand (Control container)
│   ├── Card1 (Card scene instance)
│   └── Card2
├── NPCHand (Control container)
│   ├── Card1 (Card scene instance - face down)
│   └── Card2
├── PotPanel (Panel)
│   └── PotLabel (Label)
├── PlayerStackPanel (Panel)
│   └── StackLabel
├── NPCStackPanel (Panel)
│   └── StackLabel
└── Script: Board.gd
```

**Implementation Steps:**

1. **Clear Existing Layout:**
   - Remove or backup current VBoxContainer structure
   - Set Board root to Control with Full Rect anchor preset

2. **Add Table Background:**
   - Create TextureRect as child of Board
   - Set texture to `table_holographic.png`
   - Anchor preset: Center
   - Set appropriate size (e.g., 800x600)
   - Layer order: 0 (behind everything)

3. **Position Community Card Slots:**
   - Create Control node `CommunityCards` anchored to center-top of table
   - Add 5 TextureRect children for card slots
   - Set each texture to `card_slot_empty.png`
   - Arrange horizontally with 10px spacing
   - Position: Center of table, slightly above middle
   - Store references to slots in script for illumination

4. **Position Player Hand:**
   - Create Control node `PlayerHand` anchored to bottom-center of table
   - Instance 2 Card scenes as children
   - Position side-by-side with 5px spacing
   - Y position: Near bottom of table
   - Add glow effect container for turn indicator (Panel with custom shader or Light2D)

5. **Position NPC Hand:**
   - Create Control node `NPCHand` anchored to top-center of table
   - Instance 2 Card scenes as children (face down initially)
   - Position: Mirror of player hand at top

6. **Create Info Panels:**
   - **Pot Panel:**
     - Panel with StyleBox: `panel_console.png`
     - Position: Center of table
     - Label text: "POT: $XXX" (RobotoMono, 16px)
   - **Player Stack Panel:**
     - Position: Bottom-right of table
     - Label text: "CREDITS: $XXX"
   - **NPC Stack Panel:**
     - Position: Top-right of table
     - Label text: "[NPC_NAME]: $XXX"

7. **Script Updates (`Board.gd`):**
   - Add references to all card slots and Card instances
   - Method `illuminate_card_slot(index: int)` - Change slot texture to `card_slot_active.png`
   - Method `deal_community_card(index: int, suit: String, rank: String)` - Replace slot with Card instance
   - Method `update_pot(amount: int)` - Update pot label
   - Method `update_stacks(player_stack: int, npc_stack: int)` - Update stack labels
   - Method `show_player_turn_indicator()`/`hide_player_turn_indicator()` - Toggle glow
   - Method `reveal_npc_hand()` - Flip NPC cards to face

8. **Visual Polish:**
   - Add subtle drop shadows to panels
   - Ensure all text has sufficient contrast
   - Test layout at different window sizes (anchors should hold)

**Testing Checklist:**
- [ ] Table background displays correctly
- [ ] Card slots illuminate in sequence (Flop 1-3, Turn, River)
- [ ] Player and NPC hands display cards correctly
- [ ] Info panels update with correct values
- [ ] Turn indicator glows when active
- [ ] NPC cards flip at showdown
- [ ] Layout remains centered at different resolutions

---

### Phase 5: Chat Interface (`scenes/Chat.tscn`)

**Purpose:** CRT-style communications console for NPC interaction

**Target Structure:**
```
Chat (Panel)
├── VBoxContainer
│   ├── TabContainer
│   │   ├── ChatTab (VBoxContainer)
│   │   │   ├── ChatDisplay (RichTextLabel - scroll container)
│   │   │   └── InputContainer (HBoxContainer)
│   │   │       ├── ChatInput (LineEdit)
│   │   │       └── SendButton
│   │   └── HistoryTab (VBoxContainer)
│   │       └── HistoryDisplay (RichTextLabel - scroll container)
│   └── LoadingIndicator (Label or TextureRect)
└── Script: Chat.gd
```

**Implementation Steps:**

1. **Set Chat Panel Background:**
   - Apply StyleBox with `panel_crt.png`
   - Set size: 25% of GameView width (handled by GameView layout)
   - Add scanline shader effect (optional):
     - Create shader with horizontal lines overlay
     - Apply subtle green/cyan tint
     - Add slight flicker animation

2. **Configure TabContainer:**
   - Two tabs: "CHAT" and "HISTORY"
   - Style tabs with console aesthetic
   - Tab font: Orbitron, 14px

3. **Setup Chat Display:**
   - RichTextLabel with BBCode enabled
   - Font: RobotoMono, 12px
   - Background: Transparent or dark with slight transparency
   - Text color: Bright green (#00FF00) or cyan
   - Scroll following enabled
   - Format messages as:
     ```
     [PLAYER]: Message text
     [NPC_NAME]: Response text
     ```

4. **Setup Chat Input:**
   - LineEdit with console styling
   - Placeholder text: "Send message..."
   - Max length: 200 characters
   - Font: RobotoMono, 12px
   - Connect `text_entered` signal to send message

5. **Setup Send Button:**
   - Text: "SEND"
   - Connect `pressed` signal to send message
   - Disable when waiting for LLM response

6. **Setup History Display:**
   - Similar to ChatDisplay but read-only
   - Display conversation summaries from save data
   - Format with timestamps or session markers

7. **Loading Indicator:**
   - Initially hidden
   - Show when waiting for LLM response
   - TextureRect with spinner or Label with "PROCESSING..." text
   - Animate rotation or ellipsis

8. **Script Logic (`Chat.gd`):**
   - Signal `message_sent(message: String)` when player sends message
   - Method `add_player_message(message: String)` - Append to ChatDisplay
   - Method `add_npc_message(message: String)` - Append NPC response
   - Method `show_loading()` / `hide_loading()` - Toggle indicator
   - Method `load_history(history_text: String)` - Populate HistoryDisplay
   - Method `clear_current_chat()` - Clear ChatDisplay at match start

9. **Visual Effects:**
   - Add CRT curvature shader (optional)
   - Glowing text effect
   - Typing sound effect when NPC message appears

**Testing Checklist:**
- [ ] Chat and History tabs switch correctly
- [ ] Player messages display immediately
- [ ] Loading indicator shows while waiting for NPC
- [ ] NPC messages appear with correct formatting
- [ ] Chat scrolls automatically to latest message
- [ ] History tab displays saved conversations
- [ ] CRT aesthetic is consistent with theme

---

### Phase 6: Game View (`scenes/GameView.tscn`)

**Purpose:** Main poker table with 3:1 board-to-chat ratio

**Target Structure:**
```
GameView (Control)
├── Background (TextureRect)
├── HBoxContainer (3:1 ratio)
│   ├── BoardContainer (Board.tscn instance) - Stretch ratio: 3
│   │   └── BettingControls (Panel)
│   │       ├── FoldButton
│   │       ├── CheckCallButton
│   │       ├── RaiseButton
│   │       └── BetSlider (HSlider)
│   └── ChatSidebar (Chat.tscn instance) - Stretch ratio: 1
├── WinnerOverlay (Panel - initially hidden)
│   └── VBoxContainer
│       ├── WinnerLabel
│       ├── HandLabel
│       └── ContinueButton
└── Script: GameView.gd
```

**Implementation Steps:**

1. **Set Background:**
   - TextureRect with `bg_space_casino.png`
   - Full Rect anchor preset
   - Layer: Behind HBoxContainer

2. **Configure HBoxContainer:**
   - Anchor preset: Full Rect
   - Add 2 children:
     - BoardContainer (Container or Panel) - size_flags_stretch_ratio = 3
     - ChatSidebar (Chat instance) - size_flags_stretch_ratio = 1

3. **Instance Board Scene:**
   - Add Board.tscn as child of BoardContainer
   - Ensure it fills available space

4. **Add Betting Controls (on Board):**
   - Create Panel with console styling
   - Position: Bottom-center of board, above player hand
   - Layout: HBoxContainer
   - **Fold Button:**
     - Text: "FOLD"
     - Always enabled during player turn
   - **Check/Call Button:**
     - Text: Dynamic ("CHECK" or "CALL $XX")
     - Enabled based on game state
   - **Raise Button:**
     - Text: "RAISE"
     - Enabled when player can raise
   - **Bet Slider:**
     - HSlider with custom textures
     - Grabber: `slider_grabber.png`
     - Track: `slider_track.png`
     - Min value: Minimum legal raise
     - Max value: Player's remaining stack
     - Step: Blind increment (e.g., 10)
     - Show current value in label above slider

5. **Instance Chat Scene:**
   - Add Chat.tscn as child of HBoxContainer
   - No additional configuration needed

6. **Create Winner Overlay:**
   - Panel with `panel_modal.png` background
   - Anchor: Center
   - Initially `visible = false`
   - Modal layer (z-index above everything)
   - Semi-transparent background (CanvasLayer or ColorRect underneath)
   - **Winner Label:**
     - Text: "[PLAYER_NAME] WINS!" or "YOU WIN!" / "YOU LOSE!"
     - Font: Orbitron, 28px
     - Color: Gold or bright cyan
   - **Hand Label:**
     - Text: Hand description (e.g., "with a Full House")
     - Font: RobotoMono, 18px
   - **Continue Button:**
     - Text: "CONTINUE"
     - Advances to next hand or shows match summary

7. **Script Logic (`GameView.gd`):**
   - Reference to Board, Chat, BettingControls, WinnerOverlay
   - Method `enable_player_actions()` / `disable_player_actions()`
   - Method `update_check_call_button(amount: int)` - Change text dynamically
   - Method `update_bet_slider(min_val: int, max_val: int)`
   - Method `show_winner(winner_name: String, hand_description: String)`
   - Method `hide_winner_overlay()`
   - Connect button signals to PokerEngine actions
   - Connect slider value_changed to update raise amount display

8. **Turn Indicator Integration:**
   - When player turn starts:
     - Call Board's `show_player_turn_indicator()`
     - Enable betting controls
     - Play `sfx_turn_notify.wav`
   - When player turn ends:
     - Call Board's `hide_player_turn_indicator()`
     - Disable betting controls

9. **Visual Polish:**
   - Add glow to betting buttons on hover
   - Smooth transitions when enabling/disabling controls
   - Winner overlay fade-in animation
   - Ensure all elements are visible against background

**Testing Checklist:**
- [ ] Board takes 75% width, chat 25%
- [ ] Betting controls appear when player turn starts
- [ ] Slider range updates correctly based on game state
- [ ] Check/Call button text updates dynamically
- [ ] Winner overlay displays correctly at showdown
- [ ] Turn indicator glows around player hand
- [ ] Chat messages sync with game events
- [ ] All buttons trigger correct game actions

---

### Phase 7: Statistics Screen (`scenes/StatisticsScreen.tscn`)

**Purpose:** Mission log terminal showing win/loss records

**Target Structure:**
```
StatisticsScreen (Control)
├── Background (TextureRect)
├── Panel (terminal style)
│   └── VBoxContainer
│       ├── TitleLabel
│       ├── ScrollContainer
│       │   └── VBoxContainer
│       │       ├── GlobalStatsLabel
│       │       ├── HSeparator
│       │       └── PerNPCStats (VBoxContainer)
│       │           └── [NPCStatLabel x N]
│       └── BackButton
└── Script: StatisticsScreen.gd
```

**Implementation Steps:**

1. **Set Background:**
   - TextureRect with `bg_space_casino.png`
   - Full Rect anchor

2. **Create Terminal Panel:**
   - Panel with `panel_terminal.png` StyleBox
   - Anchor: Center
   - Size: 80% of screen width, 70% of height
   - Add scanline shader or CRT effect (optional)

3. **Style Title:**
   - Text: "CAPTAIN'S MISSION LOG" or "STATISTICS"
   - Font: Orbitron, 24px
   - Color: Bright green or amber (#FFAA00)
   - Align center

4. **Setup Global Stats Display:**
   - RichTextLabel or Label
   - Font: RobotoMono, 14px
   - Text format:
     ```
     TOTAL MISSIONS: [X]
     VICTORIES: [Y]
     DEFEATS: [Z]
     SUCCESS RATE: [W%]
     ```
   - Align left with monospaced formatting

5. **Add Separator:**
   - HSeparator with custom color (neon line)

6. **Setup Per-NPC Stats:**
   - ScrollContainer to handle multiple NPCs
   - For each NPC, create Label with format:
     ```
     vs. [NPC_NAME]
       Matches: [X]  |  Wins: [Y]  |  Losses: [Z]  |  Rate: [W%]
     ```
   - Indent NPC stats
   - Use color coding: Green for high win rate, red for low

7. **Add Back Button:**
   - Text: "RETURN TO BRIDGE" or "BACK"
   - Position: Bottom-center of panel
   - Connect to return to StartScreen

8. **Script Logic (`StatisticsScreen.gd`):**
   - Method `load_statistics()` - Read from save files
   - Method `populate_global_stats(wins: int, losses: int)`
   - Method `add_npc_stats(npc_name: String, wins: int, losses: int)`
   - Method `calculate_win_rate(wins: int, losses: int) -> float`
   - Called in `_ready()` to populate on screen load

9. **Visual Polish:**
   - Add blinking cursor effect at end of text (terminal aesthetic)
   - Typewriter effect when stats appear (optional)
   - Subtle glow on text

**Testing Checklist:**
- [ ] Statistics load from save files correctly
- [ ] Global stats calculate accurately
- [ ] Per-NPC stats display for all generated NPCs
- [ ] Win percentages calculate correctly
- [ ] Scrolling works if many NPCs exist
- [ ] Back button returns to start screen
- [ ] Terminal aesthetic is consistent

---

### Phase 8: Audio Integration

**Goal:** Add sound effects and music throughout the application

**Implementation Steps:**

1. **Create Audio Manager (Optional):**
   - Autoload singleton: `AudioManager.gd`
   - Preload all sound effects
   - Methods:
     - `play_sfx(sfx_name: String)`
     - `play_music(music_name: String, loop: bool)`
     - `stop_music()`
     - `set_sfx_volume(volume: float)`
     - `set_music_volume(volume: float)`

2. **Import Audio Files:**
   - Place all audio files in `assets/audio/sfx/` and `assets/audio/music/`
   - Ensure Godot imports them as AudioStream resources
   - Configure loop points for music

3. **StartScreen Audio:**
   - Play background music on `_ready()`
   - Button hover: `sfx_button_hover.wav`
   - Button click: `sfx_button_click.wav`
   - NPC generation complete: `sfx_npc_generate.wav`
   - NPC deletion: `sfx_npc_delete.wav`

4. **GameView Audio:**
   - Continue background music from start screen
   - Player turn starts: `sfx_turn_notify.wav`
   - Card deal: `sfx_card_deal.wav` (play 2x for hole cards, 3x for flop, etc.)
   - Bet placed: `sfx_chips_bet.wav`
   - Fold: `sfx_fold.wav`
   - Showdown reveal: `sfx_card_flip.wav`
   - Pot collected: `sfx_chips_collect.wav`
   - Winner announcement: `sfx_winner.wav`

5. **Chat Audio:**
   - Message sent: Subtle beep or `sfx_button_click.wav`
   - NPC response appears: Typewriter sound or CRT static (optional)

6. **StatisticsScreen Audio:**
   - Continue background music
   - Button interactions: Standard UI sounds

7. **Audio Bus Configuration:**
   - Create audio buses in Audio settings:
     - Master
       - Music (volume adjustable)
       - SFX (volume adjustable)
   - Assign all AudioStreamPlayers to appropriate buses

**Testing Checklist:**
- [ ] Background music plays continuously
- [ ] Music loops seamlessly
- [ ] All button sounds play on interaction
- [ ] Game event sounds trigger correctly
- [ ] Chat sounds enhance immersion
- [ ] Volume can be adjusted (if settings added)
- [ ] No audio clipping or distortion

---

### Phase 9: Animation and Polish

**Goal:** Add smooth transitions and visual feedback

**Implementation Steps:**

1. **Scene Transitions:**
   - Create transition shader or AnimationPlayer
   - Fade out → switch scene → fade in
   - Duration: 0.5 seconds
   - Apply to:
     - StartScreen ↔ GameView
     - StartScreen ↔ StatisticsScreen
     - GameView → StartScreen (match end)

2. **Card Animations:**
   - Deal animation: Cards slide from deck position to hand
   - Flip animation: Already implemented in Card.gd
   - Collect animation: Cards slide to winner's stack (optional)
   - Use Tween for smooth movement

3. **Button Animations:**
   - Hover: Scale up 1.05x + glow increase
   - Click: Scale down 0.95x + brief flash
   - Disable: Fade to 50% opacity
   - Use AnimationPlayer or Tween

4. **Chip/Bet Animations:**
   - When bet placed: Chip stack visual moves to pot (optional for MVP)
   - Pot value number pop effect when updated

5. **Winner Overlay Animation:**
   - Background fade in from transparent to semi-opaque
   - Panel scale in from 0.0 to 1.0 with bounce easing
   - Text appear with typewriter effect
   - Duration: 1.0 second total

6. **Turn Indicator Animation:**
   - Glow pulse: Brightness 80% → 120% → 80%, cycle every 1.5 seconds
   - Use AnimationPlayer with looping

7. **Loading Spinner Animation:**
   - Rotation: 0° → 360° continuous loop
   - Speed: 1 second per rotation
   - Use AnimationPlayer or script-based rotation

8. **NPC Slot State Transitions:**
   - Background texture swap with brief flash
   - Buttons fade in/out when state changes

**Testing Checklist:**
- [ ] All scene transitions are smooth
- [ ] Card dealing feels natural
- [ ] Button feedback is responsive
- [ ] Winner overlay has impact
- [ ] Turn indicator is noticeable but not distracting
- [ ] Animations don't cause performance issues
- [ ] No animation overlap bugs

---

### Phase 10: Responsive Layout Testing

**Goal:** Ensure UI works at different resolutions

**Implementation Steps:**

1. **Define Target Resolutions:**
   - Minimum: 1280x720 (720p)
   - Recommended: 1920x1080 (1080p)
   - Test at: 1280x720, 1366x768, 1920x1080, 2560x1440

2. **Test StartScreen:**
   - Verify NPC grid remains centered
   - Check button sizes are clickable
   - Ensure title doesn't overlap grid
   - Test at all target resolutions

3. **Test GameView:**
   - Verify 3:1 board-to-chat ratio holds
   - Check betting controls don't overlap cards
   - Ensure text remains readable
   - Test slider usability at different widths

4. **Test Board:**
   - Verify card positions scale proportionally
   - Check info panels remain visible
   - Ensure table background covers area

5. **Test Chat:**
   - Verify text wrapping works
   - Check scrolling behavior
   - Ensure input field is accessible

6. **Test StatisticsScreen:**
   - Verify terminal panel scales appropriately
   - Check text remains readable
   - Ensure scrolling works for many NPCs

7. **Adjust Anchors and Margins:**
   - Fix any layout issues found during testing
   - Use anchor presets and margin containers
   - Test again after fixes

**Testing Checklist:**
- [ ] All screens tested at 4+ resolutions
- [ ] No UI elements overlap
- [ ] All text remains readable
- [ ] All buttons remain clickable
- [ ] Aspect ratio changes don't break layout
- [ ] Fullscreen toggle works

---

## Integration Points with Game Logic

### StartScreen ↔ NPCGenerator
- **Trigger:** User clicks Generate button on empty NPCSlot
- **UI Updates:**
  1. NPCSlot changes to GENERATING state (show spinner)
  2. After LLM generation completes, slot changes to OCCUPIED state
  3. Display NPC name on slot
- **Data Flow:** NPCGenerator → save to JSON → StartScreen reads and displays

### GameView ↔ PokerEngine
- **Match Start:**
  1. GameView initializes Board with player/NPC names and starting stacks
  2. Chat displays NPC's opening line (from LLMClient)
- **Each Hand:**
  1. PokerEngine posts blinds → Board updates stack displays
  2. PokerEngine deals cards → Board shows Card instances
  3. PokerEngine processes bets → Board updates pot, stacks
  4. PokerEngine advances phase → Board illuminates card slots
  5. PokerEngine determines winner → GameView shows winner overlay
- **Match End:**
  1. PokerEngine detects stack = 0 → triggers match summary
  2. Statistics updated in save files
  3. Return to StartScreen

### Chat ↔ LLMClient
- **Player sends message:**
  1. Chat.gd emits `message_sent(message)`
  2. GameView.gd calls LLMClient.generate_response(npc_data, message)
  3. Chat shows loading indicator
  4. LLMClient returns response → Chat displays NPC message
  5. Chat hides loading indicator

### StatisticsScreen ↔ Save Files
- **On screen load:**
  1. StatisticsScreen.gd reads `saves/stats.json`
  2. Populates global and per-NPC statistics
  3. Calculates win rates

---

## Asset Checklist Summary

Before beginning implementation, verify all assets are available:

### Visual Assets Required:
- [ ] 15 UI panel textures
- [ ] 4 button state textures
- [ ] 54 card textures (52 faces + 1 back + 1 slot)
- [ ] 2 slider textures
- [ ] 1 spinner texture
- [ ] 1 background texture
- [ ] 2 slot state textures

### Font Assets Required:
- [ ] Orbitron-Regular.ttf
- [ ] RobotoMono-Regular.ttf

### Audio Assets Required:
- [ ] 7 UI sound effects
- [ ] 6 game sound effects
- [ ] 1 background music track

**Total Asset Count:** 88 files

---

## Implementation Order Recommendation

1. **Phase 1:** Theme Setup (1-2 hours)
2. **Phase 2:** Reusable Components (3-4 hours)
3. **Phase 3:** Start Screen (2-3 hours)
4. **Phase 4:** Board Scene (4-5 hours) - Most complex
5. **Phase 5:** Chat Interface (2-3 hours)
6. **Phase 6:** Game View (3-4 hours)
7. **Phase 7:** Statistics Screen (2 hours)
8. **Phase 8:** Audio Integration (2-3 hours)
9. **Phase 9:** Animation and Polish (3-4 hours)
10. **Phase 10:** Responsive Layout Testing (2-3 hours)

**Estimated Total Implementation Time:** 24-33 hours

---

## Known Risks and Mitigations

### Risk 1: Asset Quality Issues
- **Problem:** Provided assets may not match expected dimensions or formats
- **Mitigation:** Define exact asset specifications before creation. Test with placeholder assets first.

### Risk 2: Performance with Shaders
- **Problem:** CRT effects and glows may impact framerate
- **Mitigation:** Make all shader effects optional. Test on target hardware early.

### Risk 3: Layout Breaking at Extreme Resolutions
- **Problem:** UI may break at very wide or very narrow aspect ratios
- **Mitigation:** Set minimum window size in project settings. Use min_size constraints on controls.

### Risk 4: Audio Overlap
- **Problem:** Multiple sound effects playing simultaneously may cause clipping
- **Mitigation:** Use audio buses with compression. Limit simultaneous SFX instances.

### Risk 5: Theme Inconsistency
- **Problem:** Manual styling may lead to visual inconsistency across scenes
- **Mitigation:** Use shared theme resource. Create style guide document with color codes and fonts.

---

## Post-Implementation Testing Protocol

After completing all phases, perform comprehensive testing:

1. **Functional Tests:**
   - [ ] All 24 user stories from PRD can be executed
   - [ ] No critical bugs or crashes
   - [ ] Save/load functionality works

2. **Visual Tests:**
   - [ ] All assets display correctly
   - [ ] Theme is consistent across all screens
   - [ ] No visual glitches or z-index issues
   - [ ] Text is readable on all backgrounds

3. **Audio Tests:**
   - [ ] All sound effects trigger correctly
   - [ ] Music loops seamlessly
   - [ ] No audio desync or clipping

4. **Responsiveness Tests:**
   - [ ] UI works at all target resolutions
   - [ ] No overflow or clipping at extreme sizes

5. **User Experience Tests:**
   - [ ] Turn indicator is clear
   - [ ] Betting controls are intuitive
   - [ ] Winner announcements are satisfying
   - [ ] Chat is easy to use
   - [ ] Navigation between screens is smooth

---

## Conclusion

This implementation plan provides a structured approach to building the SpacePoker UI layer with the "Retro-Futuristic Casino" theme. By following these phases sequentially and completing the testing checklists, the technical artist can deliver a polished, cohesive, and functional user interface that meets all requirements from the PRD and planning sessions.

The modular approach (reusable components first, then screens) ensures consistency and reduces duplicate work. The clear integration points with game logic provide guidance for backend developers to connect the UI to the poker engine and LLM systems.

**Next Steps:**
1. Gather or create all required assets per the Asset Checklist
2. Begin Phase 1: Theme Setup
3. Track progress using the testing checklists
4. Report blockers or asset issues immediately
