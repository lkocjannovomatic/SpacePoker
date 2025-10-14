# Game - SpacePoker (MVP)

### Main problem
Poker games are boring. Usually, AI is implemented to try to win statistically and the player can only rely on luck. In real poker, we can adjust our strategy depending on who we are playing with and what mood they are in. Conversation is also key, as is what we can deduce about our opponent from it. In SpacePoker, opponents will have an AI-generated history, character, and game strategy. In addition, the player will be able to have a text conversation with their opponent, which will also be supported by a response generator.

### Minimum set of features
- Start view, 8 slots where you can generate, remove or select an NPC opponent. You can also go to the statistics.
- Statistics view, total number of games won and lost, percentage of wins to losses. The same for each generated opponent.
- Poker game view, table with cards, player's cards visible, opponent's cards not visible. Text input field for conversation. Field for reading the opponent's response. Field for storing the amount of available credits. Each game starts with the same amount of credits and ends when one of the players cannot start another game. After the game, a summary of the match and a button to return to the start screen.
- Persistence in the form of local unencrypted json files.

### What is NOT included in the MVP
- Web implementation.
- Image generation

### Success criteria
- none, the project is intended to develop AI programming skills