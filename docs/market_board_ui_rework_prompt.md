# Market Board UI Rework

Rework the Godot 4 interface in this repository into a compact medieval market
board that remains fully visible at 1280x720.

First read:

- `AGENTS.md`
- `README.md`
- `docs/game_design.md`
- `docs/card_design_rules.md`
- `scenes/Main.tscn`
- `scripts/ui/main_ui.gd`
- `scripts/core/game_state.gd`
- `tests/ui_smoke_test.gd`

Keep card definitions data-driven, UI separate from rules logic, existing card
interactions intact, and individual card behavior out of UI code.

## Required layout

1. Replace the single horizontal market strip with three themed market carpets:

   - **Royal Treasury** on the left: two resource piles in one column and two rows.
   - **Guild Barracks** in the center: ten action piles in five columns and two rows.
   - **Crown Estates** on the right: two victory piles in one column and two rows.

   The complete market therefore forms a `2x1 + 2x5 + 2x1` board with small,
   deliberate gaps between cards and carpets.

2. Change the market composition to exactly:

   - 2 resources
   - 10 actions
   - 2 victory cards

   Keep random selection, finite pile counts, buying, gaining, empty-pile logic,
   and market refresh behavior working. Do not hardcode card IDs into the layout;
   route cards by their data-driven `card_type`.

3. Give each section its own readable medieval carpet treatment:

   - Treasury: deep burgundy and antique gold, suggesting coin, trade, and royal
     accounts.
   - Barracks: dark desaturated blue/charcoal with steel and brass trim,
     suggesting planning, labor, and military action.
   - Estates: deep forest green with restrained oxblood/gold trim, suggesting
     deeds, land, and prestige.

   Use project-owned UI assets and Godot-native styling. Preserve the existing
   table background and overall walnut/brass visual language.

4. Move the persistent game details to compact panels at the upper sides:

   - Left ledger: turn, deck, discard, and New Game.
   - Center: compact Conquest Cartes title/identity.
   - Right ledger: coins, actions, buys, and End Turn.

   The stats must remain easy to scan, but the top must no longer read as one
   long dashboard bar.

5. Create a compact market-card presentation that fits all fourteen piles
   without scrolling:

   - Preserve artwork, name, concise bold effects, cost/type/VP, pile count,
     disabled states, cursor feedback, hover animation, tooltips, buying
     animation, and previews.
   - Keep hand cards large enough to read and do not regress their enlarged art.
   - Do not shrink text into illegibility; simplify spacing and dimensions for
     market cards separately from hand cards.

6. Keep the play area, hand, choice overlay, preview, and end-game overlay
   functional and inside the viewport. Card previews must remain clamped to the
   viewport when hovering any of the three market carpets.

## Tests and documentation

- Update rules and UI smoke tests for the fourteen-card market.
- Add UI checks for:
  - two resource cards in Royal Treasury;
  - ten action cards in Guild Barracks;
  - two victory cards in Crown Estates;
  - the one-column/two-row and five-column/two-row grid structure;
  - no market scrolling;
  - all panels remaining within 1280x720;
  - existing purchase, preview, sound, animation, choice, hand, and end-game
    behavior.
- Update `README.md` and `docs/game_design.md` to describe the new market
  composition and named board zones.
- Run both headless smoke tests and a release Web export.
- Visually inspect the exported game at 1280x720.
- Search active scene/script code for obsolete `SHARED MARKET` presentation.
- Commit and push all intended changes while leaving unrelated user changes
  untouched.
