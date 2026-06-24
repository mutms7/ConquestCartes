# ConquestCartes

An original, single-player Godot 4 deck-building prototype with placeholder tabletop UI.

## Open and Run

1. Install Godot 4.
2. Open Godot's Project Manager.
3. Select **Import**, then choose this folder's `project.godot`.
4. Open the project and press **F6** or the Play button.

The project targets a 1280x720 desktop window.

## Current Prototype

- Starts with seven Pebble Coin cards and three Homestead cards
- Shuffles and draws a five-card hand
- Plays resource and action cards from the hand
- Tracks coins, actions, buys, deck size, discard size, and turn number
- Buys affordable cards from a fixed shared market
- Discards the hand and play area at end of turn
- Reshuffles the discard pile when the draw pile is empty
- Ends after turn 15 and shows the total victory-point score
- Loads all card definitions and numerical effects from JSON
- Prints game events to the Godot output for debugging
- Includes a headless rules smoke test in `tests/smoke_test.gd`

## Known Limitations

- The market has unlimited copies of each card.
- There is no opponent, campaign, multiplayer, save system, audio, or finished art.
- Card effects are limited to the numerical fields in the starter data schema.
- There are no animations, card inspection view, settings, or accessibility options yet.
- The smoke test covers the main loop, but detailed unit tests are not included yet.

## Suggested Next Steps

1. Expand the smoke test into focused tests for edge cases and invalid moves.
2. Add finite market pile counts and an additional end condition.
3. Add more original cards using the existing JSON fields.
4. Add card art and audio with license records under `assets/licenses/`.
5. Add animation and input polish after the rules are stable.
