# UI Assets List - SpacePoker

## Overview
This document provides detailed specifications and generation prompts for all 88 assets required for the SpacePoker UI implementation. All assets follow the "Retro-Futuristic Casino" theme combining classic poker aesthetics with 1950s sci-fi elements.

## Color Palette
- **Primary Background:** Deep space blues (#0A0E27, #1A1F3A)
- **Accent Colors:** Neon cyan (#00FFFF), bright green (#00FF00), amber (#FFAA00), gold (#FFD700)
- **Metallic:** Brushed steel (#8B90A1), chrome highlights (#C0C5CE)
- **Warning/Error:** Neon red (#FF0055)
- **Panel Backgrounds:** Dark metallic (#2A2D3A) with slight transparency

---

## 1. Background Assets (2 files)

### 1.1 Main Background
- **Filename:** `bg_space_casino.png`
- **Location:** `assets/backgrounds/`
- **Dimensions:** 1920x1080 pixels (16:9 ratio)
- **Format:** PNG with optional transparency
- **Description:** Primary background used across all game screens showing a view from a space casino window

**Generation Prompt:**
```
Create a retro-futuristic space casino background image in 1950s sci-fi style. The scene should show a large panoramic window view from inside a space station casino looking out into deep space. Include:
- Distant stars and nebulae in deep blue and purple hues
- A ringed planet visible in the distance
- Subtle reflections on the window glass
- Interior edge framing suggesting a metallic space station structure
- Soft ambient lighting with cyan and purple undertones
- Overall dark color scheme to not distract from UI elements
- Art style: Retro-futuristic, pulp sci-fi, slightly stylized but not cartoonish
- Resolution: 1920x1080 pixels
- Mood: Mysterious, elegant, slightly ominous but inviting
```

### 1.2 Poker Table Surface
- **Filename:** `table_holographic.png`
- **Location:** `assets/backgrounds/`
- **Dimensions:** 1200x800 pixels
- **Format:** PNG with alpha channel transparency
- **Description:** Holographic poker table surface with semi-transparent glowing edges

**Generation Prompt:**
```
Design a holographic poker table surface for a retro-futuristic card game. The table should feature:
- Dark metallic base surface (#2A2D3A) with subtle texture
- Semi-transparent holographic projection effect with cyan/blue glow (#00FFFF at 40% opacity)
- Subtle grid pattern or circuit-like details embedded in the surface
- Glowing neon edges around the table perimeter
- Slightly curved/beveled edges with chrome-like highlights
- Central area slightly darker for card placement
- Art style: 1950s sci-fi meets modern hologram technology
- Resolution: 1200x800 pixels
- Include alpha transparency around edges
- Surface should have a subtle reflective quality
```

---

## 2. UI Panel Textures (6 files)

### 2.1 Metallic Panel (NPC Slot Occupied)
- **Filename:** `panel_metallic.png`
- **Location:** `assets/ui/panels/`
- **Dimensions:** 300x200 pixels (9-slice compatible)
- **Format:** PNG with alpha channel
- **Description:** Brushed metal ID card appearance for occupied NPC slots

**Generation Prompt:**
```
Create a rectangular metallic panel texture resembling a futuristic ID card or personnel dossier. Include:
- Brushed steel texture with horizontal grain (#8B90A1)
- Rivets or bolts in corners
- Subtle embossed border with beveled edges
- Small holographic strip accent on one edge (cyan glow)
- Worn/weathered details suggesting space station use
- Art style: Retro-futuristic, military-industrial
- Resolution: 300x200 pixels with 20px border suitable for 9-slice scaling
- Lighting: Subtle directional lighting from top-left
- Include alpha channel for clean edges
```

### 2.2 Console Panel (Info Readouts)
- **Filename:** `panel_console.png`
- **Location:** `assets/ui/panels/`
- **Dimensions:** 400x150 pixels (9-slice compatible)
- **Format:** PNG with alpha channel
- **Description:** Control console panel for displaying game information

**Generation Prompt:**
```
Design a spaceship control console panel for displaying information readouts. Features:
- Dark metallic background (#2A2D3A) with subtle panel lines
- Recessed screen area with slight glow effect
- Corner screws or fasteners
- Subtle LED indicator lights (green, amber) along edges
- Slightly worn/used appearance with light scratches
- Thin neon accent lines (cyan #00FFFF) framing the panel
- Art style: 1950s spacecraft instrument panel aesthetic
- Resolution: 400x150 pixels with 25px border for 9-slice
- Include subtle screen scanline texture in center
- Alpha channel for rounded corners
```

### 2.3 CRT Panel (Chat Interface)
- **Filename:** `panel_crt.png`
- **Location:** `assets/ui/panels/`
- **Dimensions:** 400x600 pixels (9-slice compatible)
- **Format:** PNG with alpha channel
- **Description:** Retro CRT monitor panel for chat interface

**Generation Prompt:**
```
Create a vintage CRT computer monitor panel for a retro-futuristic chat interface. Include:
- Thick monitor bezel/frame in aged plastic or metal (#3A3D4A)
- Curved screen glass reflection effect
- Dark screen area with subtle green phosphor glow
- Ventilation grilles or speaker grills on sides
- Small indicator lights (power LED, etc.)
- Subtle wear marks and scratches on bezel
- Corner mounting screws
- Art style: 1970s-1980s computer terminal meets 1950s sci-fi
- Resolution: 400x600 pixels with 30px border for 9-slice
- Include faint horizontal scanlines in screen area
- Alpha channel for clean outline
```

### 2.4 Terminal Panel (Statistics Screen)
- **Filename:** `panel_terminal.png`
- **Location:** `assets/ui/panels/`
- **Dimensions:** 1000x700 pixels (9-slice compatible)
- **Format:** PNG with alpha channel
- **Description:** Large terminal screen for mission log/statistics display

**Generation Prompt:**
```
Design a large retro computer terminal panel for displaying mission logs and statistics. Features:
- Chunky retro monitor frame in dark gray/black (#1A1D2A)
- Large screen area with amber or green monochrome display aesthetic
- Corner reinforcement brackets
- Ventilation slots along top and bottom edges
- Small control buttons or switches on lower bezel
- Worn industrial look with scratches and dents
- Subtle glow bleeding from screen edges
- Art style: 1980s military terminal meets spaceship bridge console
- Resolution: 1000x700 pixels with 40px border for 9-slice
- Dark screen background with faint grid pattern
- Include alpha channel
```

### 2.5 Modal Panel (Winner Overlay)
- **Filename:** `panel_modal.png`
- **Location:** `assets/ui/panels/`
- **Dimensions:** 600x400 pixels (9-slice compatible)
- **Format:** PNG with alpha channel
- **Description:** Prominent announcement panel for winner display

**Generation Prompt:**
```
Create a dramatic modal overlay panel for announcing game winners. Include:
- Metallic frame with chrome/gold highlights (#FFD700 accents)
- Thick decorative border with art deco geometric patterns
- Dark semi-transparent center (#000000 at 85% opacity)
- Corner decorations or emblems (retro-futuristic insignia)
- Subtle holographic shimmer effect along edges
- Neon accent lines (gold or cyan) framing the content area
- Art style: Art deco meets 1950s sci-fi, prestigious and eye-catching
- Resolution: 600x400 pixels with 50px ornate border
- Should feel important and celebratory
- Alpha channel with semi-transparent background
```

### 2.6 Dialog Panel (Confirmation Dialog)
- **Filename:** `panel_dialog.png`
- **Location:** `assets/ui/panels/`
- **Dimensions:** 400x250 pixels (9-slice compatible)
- **Format:** PNG with alpha channel
- **Description:** Warning/confirmation dialog styled as spaceship OS popup

**Generation Prompt:**
```
Design a warning/confirmation dialog box for a spaceship's operating system. Features:
- Squared-off alert panel with yellow/orange warning stripes on border
- Dark background (#1F2233) with slight transparency
- Corner caution chevrons or hazard markings
- Small warning icon space in top corner
- Thick border with industrial fastener details
- Subtle red or amber alert glow along edges (#FFAA00)
- Art style: Spaceship computer alert system, utilitarian but retro
- Resolution: 400x250 pixels with 30px border for 9-slice
- Should convey importance without being alarming
- Include alpha channel for overlay effect
```

---

## 3. Button Assets (4 files)

### 3.1 Button Normal State
- **Filename:** `btn_console_normal.png`
- **Location:** `assets/ui/buttons/`
- **Dimensions:** 200x60 pixels
- **Format:** PNG with alpha channel
- **Description:** Default state for console-style buttons

**Generation Prompt:**
```
Create a retro-futuristic console button in its normal/default state. Include:
- Raised rectangular button with beveled edges
- Dark metallic surface (#3A4150) with slight gradient
- Subtle panel lines or texture suggesting mechanical button
- Small rivets or screws on corners
- Thin cyan outline glow (#00FFFF at 20% opacity)
- Slight highlight on top edge suggesting light source
- Art style: Spaceship console button, tactile and mechanical
- Resolution: 200x60 pixels
- Should look pressable but not currently active
- Alpha channel for clean edges
```

### 3.2 Button Hover State
- **Filename:** `btn_console_hover.png`
- **Location:** `assets/ui/buttons/`
- **Dimensions:** 200x60 pixels
- **Format:** PNG with alpha channel
- **Description:** Hover state showing button interactivity

**Generation Prompt:**
```
Create the hover state for a retro-futuristic console button. Include:
- Same button base as normal state but with enhanced glow
- Brighter cyan outline (#00FFFF at 60% opacity)
- Subtle internal glow or backlight effect
- Slightly brighter metallic surface (#4A5160)
- Enhanced edge highlights
- Small light indicators "activating" (LEDs turning on)
- Art style: Spaceship console button responding to interaction
- Resolution: 200x60 pixels (match normal state exactly)
- Should feel more energized and responsive
- Alpha channel with slightly stronger glow extending beyond edges
```

### 3.3 Button Pressed State
- **Filename:** `btn_console_pressed.png`
- **Location:** `assets/ui/buttons/`
- **Dimensions:** 200x60 pixels
- **Format:** PNG with alpha channel
- **Description:** Pressed/active state showing button depression

**Generation Prompt:**
```
Create the pressed/clicked state for a retro-futuristic console button. Include:
- Button appears depressed/pushed in with inverted bevel
- Darker surface (#2A3040) suggesting shadow when pressed
- Bright cyan activation glow inside button
- Reduced outer glow as light is focused inward
- Edge highlights reversed to show depression
- Small spark or energy effect at contact points
- Art style: Mechanical button being physically pressed
- Resolution: 200x60 pixels (match other states exactly)
- Should clearly communicate button activation
- Alpha channel with focused internal glow
```

### 3.4 Button Disabled State
- **Filename:** `btn_console_disabled.png`
- **Location:** `assets/ui/buttons/`
- **Dimensions:** 200x60 pixels
- **Format:** PNG with alpha channel
- **Description:** Disabled/inactive state for unavailable buttons

**Generation Prompt:**
```
Create the disabled/inactive state for a retro-futuristic console button. Include:
- Desaturated, dark button surface (#2A2D35)
- No glow or energy effects
- Muted, gray appearance suggesting inactivity
- Possible "offline" indicators or dimmed LEDs
- Subtle diagonal hazard stripes or "locked" overlay
- Reduced contrast and detail visibility
- Art style: Powered-down or locked-out console button
- Resolution: 200x60 pixels (match other states exactly)
- Should clearly communicate unavailability
- Alpha channel with reduced overall opacity (70%)
```

---

## 4. Playing Card Assets (54 files)

### Card Design Specifications
- **Dimensions:** 160x240 pixels (2:3 ratio)
- **Format:** PNG with alpha channel
- **Style:** Retro-futuristic with standard suits maintained
- **Border:** Thin glowing edge suitable for sci-fi theme

### 4.1 Card Back
- **Filename:** `card_back.png`
- **Location:** `assets/cards/`

**Generation Prompt:**
```
Design a retro-futuristic playing card back. Include:
- Dark metallic background (#1A2030)
- Centered geometric pattern with art deco/sci-fi motifs
- Symmetrical design incorporating stars, circuits, or atomic symbols
- Cyan and purple accent colors (#00FFFF, #9D4EDD)
- Subtle holographic shimmer effect
- Thin glowing border (#00FFFF at 40% opacity)
- Art style: 1950s pulp sci-fi meets art deco playing cards
- Resolution: 160x240 pixels
- Pattern should be elegant but not too busy
- Include alpha channel for rounded corners
```

### 4.2 Card Faces - Spades (13 files)
**Filenames:** `card_spades_A.png`, `card_spades_2.png` through `card_spades_K.png`
**Location:** `assets/cards/spades/`

**Generation Prompt (Template - adjust rank for each card):**
```
Design the [RANK] of Spades playing card in retro-futuristic style. Include:
- White/light background (#F5F5FF) with subtle texture
- Standard spade symbol(s) in black with cyan holographic outline
- [RANK] index in corners (e.g., "A", "2", "K")
- Spade symbols rendered with slight metallic sheen
- For face cards (J, Q, K): Character in retro space suit or sci-fi attire
  - Stylized, simplified art deco-inspired figure design
  - Maintain symmetrical composition (mirror top/bottom)
  - Incorporate technological elements (helmets, ray guns, etc.)
- Thin cyan glowing border (#00FFFF)
- Art style: 1950s pulp sci-fi meets traditional playing card design
- Resolution: 160x240 pixels
- Maintain clear readability and traditional card hierarchy
- Alpha channel for rounded corners
```

### 4.3 Card Faces - Hearts (13 files)
**Filenames:** `card_hearts_A.png`, `card_hearts_2.png` through `card_hearts_K.png`
**Location:** `assets/cards/hearts/`

**Generation Prompt (Template):**
```
Design the [RANK] of Hearts playing card in retro-futuristic style. Include:
- White/light background (#F5F5FF) with subtle texture
- Standard heart symbol(s) in red with pink holographic outline
- [RANK] index in corners
- Heart symbols with gentle glow effect suggesting energy/power
- For face cards: Character in retro space attire with romantic/noble theme
  - Art deco-inspired figure design
  - Maintain symmetrical composition
  - Incorporate elegant technological elements
- Thin pink glowing border (#FF69B4)
- Art style: 1950s sci-fi romance comics meets playing cards
- Resolution: 160x240 pixels
- Red suit should be clearly distinguishable from black suits
- Alpha channel for rounded corners
```

### 4.4 Card Faces - Clubs (13 files)
**Filenames:** `card_clubs_A.png`, `card_clubs_2.png` through `card_clubs_K.png`
**Location:** `assets/cards/clubs/`

**Generation Prompt (Template):**
```
Design the [RANK] of Clubs playing card in retro-futuristic style. Include:
- White/light background (#F5F5FF) with subtle texture
- Standard club/clover symbol(s) in black with green holographic outline
- [RANK] index in corners
- Club symbols with slight atomic/radiation glow effect (green)
- For face cards: Character in retro space gear with military/utilitarian theme
  - Industrial art deco design
  - Maintain symmetrical composition
  - Incorporate rugged tech elements (armor, tools)
- Thin green glowing border (#00FF00)
- Art style: 1950s military sci-fi meets traditional playing cards
- Resolution: 160x240 pixels
- Clubs should have strong, bold appearance
- Alpha channel for rounded corners
```

### 4.5 Card Faces - Diamonds (13 files)
**Filenames:** `card_diamonds_A.png`, `card_diamonds_2.png` through `card_diamonds_K.png`
**Location:** `assets/cards/diamonds/`

**Generation Prompt (Template):**
```
Design the [RANK] of Diamonds playing card in retro-futuristic style. Include:
- White/light background (#F5F5FF) with subtle texture
- Standard diamond symbol(s) in red with amber holographic outline
- [RANK] index in corners
- Diamond symbols with crystalline/gem-like quality and golden glow
- For face cards: Character in ornate space attire with merchant/wealthy theme
  - Luxurious art deco design
  - Maintain symmetrical composition
  - Incorporate precious metal and jewel technological elements
- Thin amber/gold glowing border (#FFD700)
- Art style: 1950s luxury sci-fi meets playing cards
- Resolution: 160x240 pixels
- Diamonds should appear valuable and prestigious
- Alpha channel for rounded corners
```

### 4.6 Card Slot Empty
- **Filename:** `card_slot_empty.png`
- **Location:** `assets/ui/`
- **Dimensions:** 160x240 pixels
- **Format:** PNG with alpha channel

**Generation Prompt:**
```
Create an empty card slot placeholder for a holographic poker table. Include:
- Dark semi-transparent background (#000000 at 30% opacity)
- Dashed or dotted outline in cyan (#00FFFF at 50%)
- Subtle card-shaped recess or depression
- Very faint grid pattern or circuit traces inside
- Corner markers suggesting card placement area
- Art style: Holographic interface placeholder
- Resolution: 160x240 pixels
- Should be visible but not distracting
- Clearly indicates where a card will appear
- Alpha channel for transparency
```

### 4.7 Card Slot Active
- **Filename:** `card_slot_active.png`
- **Location:** `assets/ui/`
- **Dimensions:** 160x240 pixels
- **Format:** PNG with alpha channel

**Generation Prompt:**
```
Create an illuminated/active card slot for a holographic poker table. Include:
- Same base as empty slot but with enhanced glow
- Bright cyan outline (#00FFFF at 90% opacity) with pulsing effect
- Stronger internal holographic grid pattern
- Glowing corner markers
- Suggestion of energy or light emanating from edges
- Art style: Activated holographic interface element
- Resolution: 160x240 pixels
- Should draw attention during game phase transitions
- Convey active/ready state clearly
- Alpha channel with glow extending slightly beyond edges
```

---

## 5. Slider Assets (2 files)

### 5.1 Slider Track
- **Filename:** `slider_track.png`
- **Location:** `assets/ui/slider/`
- **Dimensions:** 300x20 pixels (horizontally tileable)
- **Format:** PNG with alpha channel
- **Description:** Bet slider track/rail

**Generation Prompt:**
```
Design a retro-futuristic slider track for bet amount control. Include:
- Metallic rail/channel with recessed center (#3A4150)
- Subtle graduated markings or tick marks along length
- Thin cyan glow line running through center groove
- Industrial fasteners or support brackets at intervals
- Worn metal texture suggesting mechanical use
- End caps with slight beveling
- Art style: Spaceship control slider, mechanical and precise
- Resolution: 300x20 pixels (should tile horizontally if needed)
- Track should clearly show path of slider movement
- Alpha channel for clean integration
```

### 5.2 Slider Grabber
- **Filename:** `slider_grabber.png`
- **Location:** `assets/ui/slider/`
- **Dimensions:** 30x40 pixels
- **Format:** PNG with alpha channel
- **Description:** Slider handle/grabber

**Generation Prompt:**
```
Create a slider handle/grabber for a retro-futuristic bet control. Include:
- Cylindrical or rectangular handle with grip texture
- Metallic surface with chrome highlights (#C0C5CE)
- Small LED indicator showing active state (cyan glow)
- Raised ridges or grip patterns
- Subtle shadow underneath suggesting hover above track
- Small position indicator marker
- Art style: Spaceship throttle or volume control handle
- Resolution: 30x40 pixels
- Should look graspable and precise
- Include alpha channel and subtle drop shadow
```

---

## 6. Spinner/Loading Indicator (1 file)

### 6.1 Loading Spinner
- **Filename:** `spinner.png`
- **Location:** `assets/ui/`
- **Dimensions:** 64x64 pixels (if single frame) or 512x64 pixels (if 8-frame sprite sheet)
- **Format:** PNG with alpha channel
- **Description:** Rotating loading indicator for NPC generation and LLM processing

**Generation Prompt:**
```
Design a retro-futuristic loading spinner animation. Create as an 8-frame horizontal sprite sheet. Include:
- Circular design with rotating arc or segmented ring
- Cyan and white color scheme (#00FFFF, #FFFFFF)
- Art deco-inspired geometric segments rotating clockwise
- Subtle glow trail behind moving elements
- Central hub or core element that remains stationary
- Each frame should show 45-degree rotation progression
- Art style: 1950s radar screen or atomic symbol meets loading indicator
- Resolution: 512x64 pixels (8 frames of 64x64 each)
- Should be smooth when animated at 8 FPS
- Include alpha channel for transparency
- Can include small particle effects or energy trails
```

---

## 7. Additional UI Elements (1 file)

### 7.1 Turn Indicator Glow
- **Filename:** `btn_glow.png`
- **Location:** `assets/ui/`
- **Dimensions:** 200x200 pixels (radial glow)
- **Format:** PNG with alpha channel
- **Description:** Radial glow overlay for player turn indication

**Generation Prompt:**
```
Create a radial glow effect for indicating the active player's turn. Include:
- Soft radial gradient from bright center to transparent edges
- Cyan or bright blue color (#00FFFF)
- Smooth falloff with no hard edges
- Bright enough to be noticeable but not overwhelming
- Suggestion of energy or holographic projection
- Art style: Holographic selection indicator
- Resolution: 200x200 pixels
- Center should be most opaque (60%), fading to 0% at edges
- Should work well when placed behind/around UI elements
- Full alpha channel with smooth gradient
```

---

## 8. Font Assets (2 files)

### 8.1 Title/Header Font
- **Filename:** `Orbitron-Regular.ttf`
- **Location:** `assets/fonts/`
- **Format:** TrueFont (TTF)
- **License:** SIL Open Font License
- **Source:** Google Fonts
- **Description:** Geometric sans-serif with futuristic feel for titles and headers

**Acquisition Instructions:**
```
Download Orbitron font from Google Fonts:
1. Visit https://fonts.google.com/specimen/Orbitron
2. Download font family
3. Extract Orbitron-Regular.ttf
4. Verify license compatibility (SIL OFL allows free use)
5. Place in assets/fonts/ directory
```

### 8.2 Body/Monospace Font
- **Filename:** `RobotoMono-Regular.ttf`
- **Location:** `assets/fonts/`
- **Format:** TrueFont (TTF)
- **License:** Apache License 2.0
- **Source:** Google Fonts
- **Description:** Monospaced font for readability in chat, stats, and data displays

**Acquisition Instructions:**
```
Download Roboto Mono font from Google Fonts:
1. Visit https://fonts.google.com/specimen/Roboto+Mono
2. Download font family
3. Extract RobotoMono-Regular.ttf
4. Verify license compatibility (Apache 2.0 allows free use)
5. Place in assets/fonts/ directory
```

---

## 9. Audio Assets - UI Sounds (4 files)

### 9.1 Button Click
- **Filename:** `sfx_button_click.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.1-0.2 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Satisfying mechanical button press sound

**Generation Prompt:**
```
Create a retro-futuristic button click sound effect. Characteristics:
- Mechanical "clunk" with slight electronic tone
- Sharp attack, quick decay
- Frequency: Mid-range (500-2000 Hz primary)
- Include subtle metallic resonance
- Slight electrical "beep" layered underneath
- Style: 1970s computer terminal button meets spaceship console
- Should feel tactile and responsive
- Duration: ~150ms
- No reverb or echo (dry sound)
- Peak normalized to -3dB
```

### 9.2 Button Hover
- **Filename:** `sfx_button_hover.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.05-0.1 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Subtle electronic chirp for button hover

**Generation Prompt:**
```
Create a subtle button hover sound effect. Characteristics:
- Soft electronic chirp or beep
- Quick, non-intrusive
- Frequency: High-mid range (1000-3000 Hz)
- Gentle attack and decay
- Slight pitch rise (sweep up)
- Style: Friendly computer interface feedback
- Should not be annoying with repeated triggers
- Duration: ~80ms
- Very short reverb tail
- Peak normalized to -6dB (quieter than click)
```

### 9.3 NPC Generation Complete
- **Filename:** `sfx_npc_generate.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.5-1.0 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Achievement/completion sound for NPC generation

**Generation Prompt:**
```
Create a completion/success sound for NPC generation finishing. Characteristics:
- Triumphant but not overwhelming
- Ascending tone sequence or flourish
- Frequency: Full range with emphasis on mid-high
- Slight digital/synthesized quality
- Suggestion of "data transfer complete" or "materialization"
- Style: Retro computer success chime meets sci-fi transporter
- Include subtle whoosh or shimmer
- Duration: ~700ms
- Light reverb suggesting space
- Peak normalized to -3dB
```

### 9.4 NPC Deletion
- **Filename:** `sfx_npc_delete.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.3-0.5 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Descending tone for NPC deletion

**Generation Prompt:**
```
Create a deletion/removal sound effect. Characteristics:
- Descending pitch sweep
- Frequency: High to mid (2000Hz to 400Hz)
- Slight distortion or "dematerialization" quality
- Not aggressive or alarming
- Style: Sci-fi data erasure or beam-out effect
- Include subtle static or particle dispersion
- Duration: ~400ms
- Minimal reverb
- Peak normalized to -3dB
```

---

## 10. Audio Assets - Game Sounds (7 files)

### 10.1 Card Deal
- **Filename:** `sfx_card_deal.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.2-0.3 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Card sliding/dealing sound

**Generation Prompt:**
```
Create a card dealing sound effect. Characteristics:
- Quick card slide or snap
- Paper/plastic friction sound
- Slight "whoosh" of air
- Can layer multiple card sounds for subtle variation
- Frequency: Broadband with emphasis on mid-high frequencies
- Style: Real card handling with subtle holographic shimmer added
- Duration: ~250ms
- Dry sound (no reverb)
- Peak normalized to -3dB
- Should stack well when multiple cards dealt rapidly
```

### 10.2 Card Flip
- **Filename:** `sfx_card_flip.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.3-0.4 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Card reveal/flip at showdown

**Generation Prompt:**
```
Create a dramatic card flip/reveal sound. Characteristics:
- Card snapping or flipping motion
- Slight buildup to flip moment
- Clean "snap" at peak
- Subtle holographic shimmer or energy reveal
- Frequency: Full range with punchy mid
- Style: Physical card flip enhanced with sci-fi reveal tone
- Should feel satisfying and conclusive
- Duration: ~350ms
- Minimal reverb
- Peak normalized to -3dB
```

### 10.3 Chips/Bet Placed
- **Filename:** `sfx_chips_bet.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.3-0.5 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Poker chips placed/bet made

**Generation Prompt:**
```
Create a poker chip betting sound. Characteristics:
- Stack of chips being placed or slid
- Clink and clatter of plastic/clay chips
- Slight metallic ring (futuristic credits)
- Multiple chip impacts with slight delay spread
- Frequency: Mid-range with bright overtones
- Style: Real poker chips with subtle holographic/energy layer
- Should convey confidence and decision
- Duration: ~400ms
- Minimal room reverb
- Peak normalized to -3dB
```

### 10.4 Chips Collected (Pot Win)
- **Filename:** `sfx_chips_collect.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.5-0.8 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Collecting/winning pot chips

**Generation Prompt:**
```
Create a pot collection/winning sound. Characteristics:
- Chips being raked or gathered
- Multiple chip clinks in succession
- Satisfying, rewarding quality
- Slight ascending pitch to suggest accumulation
- Frequency: Full range, bright and cheerful
- Style: Poker chips being collected with subtle "credits acquired" tone
- Include gentle whoosh suggesting holographic transfer
- Duration: ~600ms
- Light reverb for sense of space
- Peak normalized to -3dB
```

### 10.5 Fold Action
- **Filename:** `sfx_fold.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.2-0.3 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Folding hand sound

**Generation Prompt:**
```
Create a folding/giving up sound effect. Characteristics:
- Cards being pushed away or mucked
- Slight descending tone suggesting defeat/withdrawal
- Not too negative or harsh
- Paper slide with subtle electronic "deactivate" tone
- Frequency: Mid-range, slightly muted
- Style: Cards discarded with holographic interface disengaging
- Should be clear but not dramatic
- Duration: ~250ms
- Dry sound
- Peak normalized to -6dB (subtle)
```

### 10.6 Turn Notification
- **Filename:** `sfx_turn_notify.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 0.3-0.5 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Player's turn begins alert

**Generation Prompt:**
```
Create an attention-getting turn notification sound. Characteristics:
- Clear, distinct chime or beep
- Friendly but urgent
- Two-tone or three-tone sequence
- Frequency: Mid-high range (800-2000 Hz)
- Style: Spacecraft alert system, informative not alarming
- Should cut through background ambience
- Slight rise in pitch for attention
- Duration: ~400ms
- Minimal reverb
- Peak normalized to -3dB
```

### 10.7 Winner Announcement
- **Filename:** `sfx_winner.wav`
- **Location:** `assets/audio/sfx/`
- **Duration:** 1.0-1.5 seconds
- **Format:** WAV, 44.1kHz, 16-bit
- **Description:** Hand/match winner fanfare

**Generation Prompt:**
```
Create a triumphant winner announcement sound. Characteristics:
- Celebratory fanfare or flourish
- Rising then resolving tone sequence
- Can include multiple layers (chime, shimmer, bass hit)
- Frequency: Full range, emphasis on bright highs and solid low end
- Style: Retro game show meets sci-fi achievement unlock
- Should feel rewarding and conclusive
- Include subtle energy/hologram shimmer
- Duration: ~1200ms
- Light reverb for grandeur
- Peak normalized to -3dB
```

---

## 11. Audio Assets - Background Music (1 file)

### 11.1 Ambient Casino Music
- **Filename:** `music_ambient_casino.ogg`
- **Location:** `assets/audio/music/`
- **Duration:** 2-3 minutes (loopable)
- **Format:** OGG Vorbis, 44.1kHz, stereo
- **Description:** Atmospheric background music for all game screens

**Generation Prompt:**
```
Create looping ambient background music for a retro-futuristic space casino. Characteristics:
- Tempo: 80-100 BPM, slow to moderate
- Instrumentation: Vintage synthesizers, electric piano, subtle bass
- Mood: Mysterious, sophisticated, slightly jazzy
- Style: 1950s lounge jazz meets Blade Runner ambient
- Structure: Minimal melodic movement, focus on atmosphere
- Include subtle space-themed sound design (distant stars, cosmic ambience)
- Low-pass filtered elements creating depth
- Occasional synthetic horn or saxophone phrases (very subtle)
- Should not be distracting or repetitive
- Perfect loop point at 2-3 minutes
- Frequency: Avoid crowding mid-range where UI sounds occur
- Emphasis on low-end warmth and high-end shimmer
- Dynamic range: Compressed for consistent background level
- Peak normalized to -12dB (background music, not foreground)
- Export as OGG Vorbis with quality setting 6-8
```

---

## Asset Organization Structure

```
SpacePoker/
└── assets/
    ├── backgrounds/
    │   ├── bg_space_casino.png
    │   └── table_holographic.png
    ├── ui/
    │   ├── panels/
    │   │   ├── panel_metallic.png
    │   │   ├── panel_console.png
    │   │   ├── panel_crt.png
    │   │   ├── panel_terminal.png
    │   │   ├── panel_modal.png
    │   │   └── panel_dialog.png
    │   ├── buttons/
    │   │   ├── btn_console_normal.png
    │   │   ├── btn_console_hover.png
    │   │   ├── btn_console_pressed.png
    │   │   └── btn_console_disabled.png
    │   ├── slider/
    │   │   ├── slider_track.png
    │   │   └── slider_grabber.png
    │   ├── btn_glow.png
    │   ├── spinner.png
    │   ├── card_slot_empty.png
    │   └── card_slot_active.png
    ├── cards/
    │   ├── card_back.png
    │   ├── spades/
    │   │   ├── card_spades_A.png
    │   │   ├── card_spades_2.png
    │   │   └── ... (through K)
    │   ├── hearts/
    │   │   └── ... (A through K)
    │   ├── clubs/
    │   │   └── ... (A through K)
    │   └── diamonds/
    │       └── ... (A through K)
    ├── fonts/
    │   ├── Orbitron-Regular.ttf
    │   └── RobotoMono-Regular.ttf
    └── audio/
        ├── sfx/
        │   ├── sfx_button_click.wav
        │   ├── sfx_button_hover.wav
        │   ├── sfx_npc_generate.wav
        │   ├── sfx_npc_delete.wav
        │   ├── sfx_card_deal.wav
        │   ├── sfx_card_flip.wav
        │   ├── sfx_chips_bet.wav
        │   ├── sfx_chips_collect.wav
        │   ├── sfx_fold.wav
        │   ├── sfx_turn_notify.wav
        │   └── sfx_winner.wav
        └── music/
            └── music_ambient_casino.ogg
```

---

## Asset Generation Checklist

### Visual Assets (79 files)
- [ ] Backgrounds (2)
  - [ ] bg_space_casino.png
  - [ ] table_holographic.png
- [ ] UI Panels (6)
  - [ ] panel_metallic.png
  - [ ] panel_console.png
  - [ ] panel_crt.png
  - [ ] panel_terminal.png
  - [ ] panel_modal.png
  - [ ] panel_dialog.png
- [ ] Buttons (4)
  - [ ] btn_console_normal.png
  - [ ] btn_console_hover.png
  - [ ] btn_console_pressed.png
  - [ ] btn_console_disabled.png
- [ ] Cards (54)
  - [ ] card_back.png
  - [ ] Spades A-K (13)
  - [ ] Hearts A-K (13)
  - [ ] Clubs A-K (13)
  - [ ] Diamonds A-K (13)
  - [ ] card_slot_empty.png
  - [ ] card_slot_active.png
- [ ] Slider (2)
  - [ ] slider_track.png
  - [ ] slider_grabber.png
- [ ] Other UI (2)
  - [ ] spinner.png
  - [ ] btn_glow.png

### Font Assets (2 files)
- [ ] Orbitron-Regular.ttf
- [ ] RobotoMono-Regular.ttf

### Audio Assets (15 files)
- [ ] UI Sounds (4)
  - [ ] sfx_button_click.wav
  - [ ] sfx_button_hover.wav
  - [ ] sfx_npc_generate.wav
  - [ ] sfx_npc_delete.wav
- [ ] Game Sounds (7)
  - [ ] sfx_card_deal.wav
  - [ ] sfx_card_flip.wav
  - [ ] sfx_chips_bet.wav
  - [ ] sfx_chips_collect.wav
  - [ ] sfx_fold.wav
  - [ ] sfx_turn_notify.wav
  - [ ] sfx_winner.wav
- [ ] Music (1)
  - [ ] music_ambient_casino.ogg

**Total Assets: 96 files** (including all 52 card faces)

---

## Tools and Resources for Asset Generation

### Visual Assets
- **AI Image Generation:** Midjourney, DALL-E, Stable Diffusion
- **Manual Creation:** Adobe Photoshop, GIMP, Affinity Designer
- **Texture Resources:** Textures.com, FreePBR.com
- **Color Palette Tool:** Coolors.co

### Audio Assets
- **Sound Effects:** Freesound.org, ElevenLabs Sound Effects, JSFXR
- **Music Creation:** Soundtrap, BandLab, LMMS (open-source)
- **Audio Editing:** Audacity (free), Adobe Audition

### Fonts
- **Source:** Google Fonts (free, open-source)
- **License Verification:** Always check SIL OFL or Apache 2.0 compatibility

---

## Quality Standards

### All Visual Assets
- Resolution: Minimum specified, can be higher for downscaling quality
- Format: PNG with alpha channel unless specified otherwise
- Color depth: 32-bit RGBA
- Optimization: Run through TinyPNG or similar before final export
- Naming: Lowercase with underscores, descriptive

### All Audio Assets
- Sample rate: 44.1kHz minimum
- Bit depth: 16-bit minimum
- Normalization: As specified per asset (-3dB to -12dB)
- Format: WAV for SFX, OGG Vorbis for music
- No clipping: Peak levels should not exceed specified normalization

### Fonts
- Format: TrueType (.ttf) or OpenType (.otf)
- License: Must be free for commercial use (SIL OFL, Apache, etc.)
- Complete character set: Latin alphabet, numbers, common symbols

---

## Next Steps

1. **Review and approve** this asset list and specifications
2. **Assign asset generation** tasks (AI generation, download, manual creation)
3. **Generate assets** following prompts and specifications
4. **Review and revise** assets for theme consistency
5. **Organize assets** into directory structure
6. **Import into Godot** and verify proper loading
7. **Begin Phase 1** of UI implementation plan

---

## Notes

- All generation prompts are templates and can be adjusted based on initial results
- Maintain consistent art style across all related assets
- Test assets in-engine early to catch sizing or format issues
- Keep source files (PSD, project files) separate from exported game assets
- Document any deviations from specifications during generation
