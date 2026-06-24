# ConquestCartes

An original, single-player Godot 4 deck-building prototype with placeholder tabletop UI.

## Open and Run

1. Install Godot 4.
2. Open Godot's Project Manager.
3. Select **Import**, then choose this folder's `project.godot`.
4. Open the project and press **F6** or the Play button.

The project targets a 1280x720 desktop window.

## Asset Organization

- `assets/raw/` stores original downloaded packs and source artifacts.
- `assets/imported/` stores usable imported visual assets.
- `assets/audio/` stores sound and music files.
- `assets/fonts/` stores font files.
- `assets/licenses/` stores license, source, credit, and attribution notes.

Asset provenance is tracked in `assets/licenses/ASSET_SOURCES.md`.

## Current Prototype

- Starts with seven Pebble Coin cards and three Homestead cards
- Shuffles and draws a five-card hand
- Plays resource and action cards from the hand
- Tracks coins, actions, buys, deck size, discard size, and turn number
- Buys affordable cards from a fixed shared market
- Includes a 24-card data-driven catalog and random six-card market
- Starts a fresh shuffled deck and market from the New Game button
- Discards the hand and play area at end of turn
- Reshuffles the discard pile when the draw pile is empty
- Ends after turn 15 and shows the total victory-point score
- Loads all card definitions and numerical effects from JSON
- Uses imported Kenney UI borders, board-game icons, and UI sound effects
- Uses Cinzel for card titles and Inter for body text, with built-in fallbacks
- Animates card play, purchases, cleanup, drawing, and final scoring
- Prints game events to the Godot output for debugging
- Includes a headless rules smoke test in `tests/smoke_test.gd`

## Known Limitations

- The market has unlimited copies of each card.
- There is no opponent, campaign, multiplayer, save system, music, or finished card art.
- Card effects are limited to the numerical fields in the starter data schema.
- There are no settings or accessibility options yet.
- The smoke test covers the main loop, but detailed unit tests are not included yet.

## Suggested Next Steps

1. Expand the smoke test into focused tests for edge cases and invalid moves.
2. Add finite market pile counts and an additional end condition.
3. Add more original cards using the existing JSON fields.
4. Add card art and audio with license records under `assets/licenses/`.
5. Add animation and input polish after the rules are stable.
