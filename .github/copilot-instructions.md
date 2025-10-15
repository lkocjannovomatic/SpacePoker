# SpacePoker - AI Coding Instructions

## Project Overview
SpacePoker is a single-player desktop poker game (No-Limit Texas Hold'em) built with **Godot Engine**, featuring LLM-powered NPCs with unique personalities. The core innovation is AI opponents that have meaningful conversations and distinct gameplay styles derived from their backstories.

## Architecture & Key Components

### Technology Stack
- **Godot Engine** (GDScript) - Game engine and UI
- **Godot LLM addon** - Local LLM integration 
- **Local LLM** - NPC personality generation and chat responses
- **JSON files** - Unencrypted local persistence in `saves/` folder

### Core Systems Architecture
1. **Poker Engine** - Standard Texas Hold'em logic with betting rounds, hand evaluation, all-in scenarios
2. **NPC System** - Rule-based strategy driven by 3 personality factors: `aggression`, `bluffing`, `risk_aversion` (0.0-1.0)
3. **LLM Integration** - Separate concerns: LLM generates backstories/chat only, NOT game strategy
4. **Persistence Layer** - Portable JSON saves next to executable for NPCs, stats, conversation summaries (optimized for LLM prompting)

### Critical Design Patterns
- **LLM is NOT used for poker strategy** - Rule-based AI uses personality factors to make game decisions
- **Personality-driven gameplay** - NPC backstory → personality factors → strategic behavior
- **Match isolation** - Each game is self-contained (1000 credits, 10/20 blinds, no mid-match saves)
- **State machine architecture** - Clear game states for poker phases and UI transitions

## Development Workflows

### Project Structure (Expected)
```
project.godot           # Godot project file
scenes/                 # .tscn scene files
  ├── StartScreen.tscn  # NPC management (8 slots max)
  ├── GameView.tscn     # Poker table + chat interface  
  └── StatsView.tscn    # Win/loss records
scripts/                # .gd GDScript files
  ├── GameManager.gd    # Main state machine
  ├── PokerEngine.gd    # Core poker logic
  ├── NPC.gd           # NPC behavior & personality
  └── LLMClient.gd     # Local LLM communication
saves/                  # Runtime JSON persistence
assets/                 # Cards, UI elements (Creative Commons)
```

### Key Development Commands
- `godot --headless --quit --script-editor` - Launch Godot editor
- Debug via Godot's built-in debugger and print statements
- Test LLM integration early - this is the highest risk component

### Testing Strategy
- **Manual testing priority** - No automated tests planned for MVP
- **Debug mode** - Hardcode NPC personality values in JSON files for testing specific behaviors
- **LLM validation** - Create technical spike first to validate Godot ↔ local LLM communication

## Project-Specific Conventions

### NPC Personality System
```gdscript
# NPC personality factors influence strategy
var aggression: float    # 0.0-1.0, affects betting frequency/size
var bluffing: float     # 0.0-1.0, affects bluff probability  
var risk_aversion: float # 0.0-1.0, affects fold thresholds
```

### Game State Management
- Fixed match structure: 1000 credits start, 10/20 blinds, play until elimination
- No dynamic blind increases or tournament structure
- State persistence only at match completion and NPC generation/deletion

### LLM Integration Points
1. **NPC Generation** - Generate backstory → extract personality factors
2. **In-game Chat** - Real-time responses using NPC personality context
3. **Opening Lines** - NPC introduces character at match start
4. **Abuse Filtering** - Generic in-character responses to inappropriate input

## Critical Implementation Notes

### Performance Considerations
- Local LLM responses may be slow - implement loading indicators
- Conversation summaries stored per NPC to optimize LLM context and manage memory
- JSON persistence is synchronous - acceptable for desktop single-player

### UI/UX Patterns
- Persistent display of player/NPC stacks and pot size
- Slider-based bet sizing with min/max constraints
- Clear showdown announcements with hand explanations
- Tabbed chat interface (current match vs. history)

### Risk Mitigation
- **Start with LLM integration spike** before building full game
- Rule-based poker strategy reduces LLM dependency
- Fallback responses for LLM failures
- JSON save corruption handling

## Documentation Policy

### Agent Mode Restrictions
- **DO NOT create new documentation files** - All required documentation already exists in `docs/`
- **Updates allowed** - You may modify existing documentation files when:
  - Correcting errors or outdated information
  - Adding clarifications to existing sections
  - Updating implementation details that have changed
- **If new documentation seems needed** - Ask the user first before creating any new `.md` files

### Existing Documentation Structure (DO NOT EXPAND)
- `docs/prd.md` - Product requirements
- `docs/tech-stack.md` - Technology decisions  
- `docs/project_analysis.md` - Risk assessment
- `docs/prd_summary.md` - Design decisions
- `.github/copilot-instructions.md` - This file

## Development Priority
1. **Technical spike** - Validate Godot + local LLM communication
2. **Core poker engine** - Implement standard Texas Hold'em rules
3. **NPC personality system** - Rule-based strategy using personality factors
4. **LLM integration** - Chat and personality generation
5. **UI polish** - Game views and user experience