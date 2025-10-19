<conversation_summary>
<decisions>
1.  The main visual theme is "Retro-Futuristic Casino," combining classic poker aesthetics with 1950s sci-fi elements.
2.  Static background images will be used for the MVP, depicting a view from a space casino window.
3.  `NPCSlot` will be designed as a metallic player card with distinct visual states for "Empty," "Generating," and "Occupied."
4.  Only free-to-use fonts will be used. A square, futuristic font (like "Orbitron") for titles and a clean, monospaced font (like "Roboto Mono") for body text and chat.
5.  The poker table in `Board.tscn` will be a holographic interface projected over a dark, metallic surface.
6.  Playing cards will have a custom retro-futuristic design, but will retain the standard suits (Spades, Hearts, Clubs, Diamonds).
7.  Player action buttons (`Fold`, `Check/Call`, `Raise`) and the bet slider will be styled as physical controls on a spaceship console.
8.  A specific list of sound effects and background music will be created to match the theme.
9.  The layout of `Board.tscn` will be changed from a vertical box to a spatial layout using a `TextureRect` as a base and `Control` nodes for positioning elements to simulate a real table.
10. Key game info (stacks, pot) will be displayed in stylized "data readout" panels.
11. The chat interface will be styled to look like a built-in CRT-style communications console.
12. A central, modal overlay will be used to announce the winner and the winning hand.
13. The statistics screen will be designed to look like a "Captain's Mission Log" terminal.
14. The `NPCSlot`'s "Occupied" state will have a texture resembling a metallic ID card.
15. The confirmation dialog will be custom-styled to look like a spaceship's OS warning pop-up.
16. A reusable `Card.tscn` scene will be created to represent playing cards, replacing the placeholder labels.
17. The player's turn will be clearly indicated with visual cues (glowing buttons/borders) and a sound effect.
18. Visual representation of bets on the table is skipped for the MVP.
19. `GameView.tscn` will have a 3:1 size ratio, with the game board taking 75% of the space and the chat sidebar 25%.
20. The `NPCSlot` grid on the `StartScreen` will be centered vertically with increased spacing between slots.
21. The current game phase will be visually reinforced by illuminating the community card slots on the board as cards are dealt.
22. Player/NPC avatars are skipped for the MVP.
</decisions>

<matched_recommendations>
1.  **Theme:** Adopt a "Retro-Futuristic Casino" theme.
2.  **Backgrounds:** Use a static image of a space casino view for backgrounds.
3.  **Fonts:** Use two distinct, free fonts: a futuristic one for titles and a monospaced one for readability.
4.  **NPCSlot Design:** Design the slot as a stylized console screen with three states (Empty, Generating, Occupied).
5.  **Board Layout:** Replace the root `VBoxContainer` in `Board.tscn` with a `TextureRect` and use anchors for a spatial layout.
6.  **Card Design:** Create a custom-themed card deck.
7.  **UI Styling:** Style buttons, sliders, and info panels as futuristic/holographic console elements.
8.  **Sound Design:** Create a list of specific sound effects for UI feedback and game events.
9.  **Chat UI:** Style the chat window as a communications console with a CRT/terminal aesthetic.
10. **Winner Announcement:** Use a large, central modal overlay to announce the winner and hand.
11. **Statistics Screen:** Style as a "Captain's Mission Log" terminal.
12. **Dialogs:** Create a custom theme for dialog boxes to match the sci-fi OS style.
13. **Card Representation:** Create a reusable `Card.tscn` scene to manage card visuals and state.
14. **Turn Indication:** Use glowing animations on UI elements and sound to notify the player.
15. **Game View Ratio:** Set the `HBoxContainer` stretch ratio to 3:1 for the board and chat.
16. **Start Screen Layout:** Adjust margins and separation in the `GridContainer` for better visual balance.
17. **Game Phase Visuals:** Use the community card slots on the board to visually track the game's progression.
</matched_recommendations>

<planning_summary>
This document summarizes the UI/UX design plan for the SpacePoker MVP. The core directive is to implement a "Retro-Futuristic Casino" theme across all game scenes.

**Main Requirements:**
- The UI must be visually cohesive, immersive, and intuitive for a single-player poker game.
- All assets, including fonts and images, must be free to use.
- The design should be achievable for an MVP, deferring complex features like animated avatars and detailed bet visuals.

**Key Implementation Specifications:**
- **Theme & Aesthetics:** A "Retro-Futuristic Casino" style will be applied. This involves a color palette of deep blues, purples, and neon accents. Backgrounds will be static images of a space scene. Fonts will be a futuristic style for titles and a monospaced style for text.
- **Scene-Specific Designs:**
    - `StartScreen.tscn`: Will feature a vertically centered grid of NPC slots with increased spacing for a cleaner look.
    - `GameView.tscn`: Will be split 75/25 between the game board and a chat sidebar.
    - `Board.tscn`: The layout will be rebuilt for a spatial feel. A `TextureRect` will serve as the table background. Elements like cards and info panels will be positioned using anchors. The table itself will have a holographic look.
    - `StatisticsScreen.tscn`: Will be styled as a retro computer terminal ("Captain's Log").
- **Component-Specific Designs:**
    - `NPCSlot.tscn`: Will be a custom-textured panel with clear visual states for empty, generating, and occupied.
    - `Card.tscn`: A new, reusable scene will be created for playing cards. It will be a `TextureRect` with a script to manage its texture (face/back) and state.
    - `Dialog.tscn`: Will receive a custom theme to look like a sci-fi OS warning.
    - `Chat.tscn`: Will be styled as a CRT-like communications console.
- **User Experience & Feedback:**
    - The player's turn will be signaled by glowing buttons, a highlighted hand area, and a sound effect.
    - The game phase (Flop, Turn, River) will be shown by progressively illuminating card slots on the board.
    - A large modal overlay will announce the winner of each hand.
- **Asset Prompts:** A list of prompts for generating required textures (UI panels, buttons, backgrounds) and sound effects has been defined to guide asset creation.
</planning_summary>

<unresolved_issues>
- There are no unresolved design questions. All open points were clarified, and decisions were made to either implement the recommendations or defer them for the MVP. The next stage is asset generation based on the provided prompts and the implementation of the specified UI layouts and styles.
</unresolved_issues>
</conversation_summary>
