\<conversation\_summary\>
\<decisions\>

1.  The Start Screen will feature 8 NPC slots arranged in a 2x4 `GridContainer`.
2.  A single, reusable `NPCSlot` scene will manage its three visual states: "Empty" (with a "Generate" button), "Generating" (with a loading animation), and "Occupied" (with NPC name, "Play," and "Delete" buttons).
3.  A global Autoload script (`GameManager`) will manage game state, data persistence, and scene transitions.
4.  Data will be persisted in 8 predefined JSON files (`slot_0.json` to `slot_7.json`), one for each slot.
5.  Communication between scenes (`NPCSlot`, `StartScreen`, `GameManager`) will be handled using Godot's signals.
6.  A single, reusable `Dialog.tscn` scene will be used for confirmations (like deletion) and error messages.
7.  All navigation buttons on the Start Screen will be disabled during asynchronous operations like NPC generation.
8.  Empty NPC slots will be represented by a JSON file containing default values (e.g., empty string for `name`), not a different structure or `status` field.
9.  Deleting an NPC will overwrite the corresponding JSON file with the default "empty" data structure.
10. Placeholder scenes for the Game View and Statistics Screen will be created with minimal UI (a label and a "Return to Menu" button) to facilitate navigation testing.
11. The asynchronous nature of the LLM addon will be handled using its built-in signals (`generate_text_updated` or `generate_text_finished` signals) rather than `async/await`.
12. For the MVP, the `saves` folder will be located next to the game's executable for portability, overriding the recommendation to use the `user://` path.
13. A global `Theme` resource will be used from the start to manage UI styling for buttons, panels, and labels.

\</decisions\>

\<matched\_recommendations\>

1.  **Singleton for State Management**: Use a global Autoload (Singleton) script named `GameManager` to manage game state, data persistence (loading/saving JSON), LLM generation requests, and scene transitions.
2.  **Signal-Based Communication**: Use Godot's signals for communication between nodes. `NPCSlot` scenes should emit signals like `generate_requested`, which the `StartScreen` catches and uses to call functions in the `GameManager`.
3.  **Reusable Scene Components**: Create self-contained, reusable scenes for key UI elements like `NPCSlot.tscn` (to manage its own visual states) and `Dialog.tscn` (for confirmations and errors).
4.  **Asynchronous Operation Handling**: Manage long operations (LLM generation) by having the `GameManager` emit global signals (`processing_started`, `processing_finished`). Other scenes can listen to these signals to disable/enable their own UI elements, decoupling the logic from the UI.
5.  **Centralized Theming**: Create and apply a single `Theme` resource to the root node of the UI to centralize styling. This makes future visual updates more efficient and scalable.
6.  **Data Structure for Slots**: An empty slot is identified by checking for a default value (e.g., `name == ""`) within a consistent JSON structure for all slots.
7.  **Defensive Programming**: Add a redundant safety check in the `GameManager` to prevent NPC generation on an already occupied slot, even if the UI should prevent this action.
\</matched\_recommendations\>

\<planning\_summary\>

### Main Requirements

The primary goal is to implement the **Start Screen** for the SpacePoker MVP. This screen serves as the main hub for the player. It must allow the user to **manage up to 8 NPC opponents** in predefined slots. Key functionalities include **generating** a new NPC, **deleting** an existing one, and **selecting** an NPC to start a match. The screen must also provide navigation to a placeholder **Statistics Screen**. All NPC data and player stats must persist between sessions.

### Key Implementation Specifications

  * **Scene Architecture**:

      * **`StartScreen.tscn`**: The main scene, using a `VBoxContainer` for vertical layout and a `GridContainer` (4x2) to hold the 8 NPC slots.
      * **`NPCSlot.tscn`**: A reusable component scene. It will contain three distinct `Control` nodes (`EmptyStateContainer`, `GeneratingStateContainer`, `OccupiedStateContainer`) and a script to toggle their visibility based on its data.
      * **`Dialog.tscn`**: A reusable, signal-driven popup for handling delete confirmations and error messages.
      * **`GameView.tscn` / `StatisticsScreen.tscn`**: Placeholder scenes with a label and a "Return to Menu" button to ensure the scene transition logic works correctly.

  * **State and Data Management**:

      * **`GameManager.gd`**: An Autoload singleton will act as the single source of truth. It handles loading/saving files, holds the NPC data in an array, triggers LLM generation, and manages scene changes.
      * **Data Persistence**: Eight JSON files (`slot_0.json`, etc.) will be located in a `saves` folder next to the game executable. Deleting an NPC means overwriting the relevant file with a default "empty" structure (`"name": ""`, etc.).

  * **Logic and Control Flow**:

      * **NPC Generation**: The user clicks "Generate" on an empty `NPCSlot`. The slot emits a signal to the `StartScreen`, which calls the `GameManager`. The `GameManager` emits a `processing_started` signal, connects to the LLM addon's completion/failure signals, and initiates the generation. Upon completion, it saves the data and emits `processing_finished`.
      * **UI State**: The `StartScreen` listens for the `processing_started`/`finished` signals from the `GameManager` to disable/enable all interactive elements globally, preventing conflicts during asynchronous operations.
\</planning\_summary\>

\<unresolved\_issues\>
There are no unresolved issues. All points were clarified and a clear plan has been established for the MVP implementation.
\</unresolved\_issues\>
\</conversation\_summary\>