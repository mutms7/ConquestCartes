# Art-First Table UI Rework

Rework the Godot 4 interface in this repository holistically so the card
illustrations and complete rules text are the visual priority at 1280x720.

First read:

- `AGENTS.md`
- `README.md`
- `docs/game_design.md`
- `docs/card_design_rules.md`
- `docs/card_wording_conventions.md`
- `scenes/Main.tscn`
- `scripts/ui/main_ui.gd`
- `tests/ui_smoke_test.gd`

Keep card definitions data-driven, UI separate from rules logic, and all current
gameplay, ordering, supply, animation, sound, preview, choice, and end-game
behavior intact.

## Layout direction

1. Remove the tall top dashboard. Move turn/deck/discard/New Game into a compact
   lower-left dock and coins/actions/buys/End Turn into a compact lower-right
   dock.
2. Place the hand between those docks at the bottom. Keep the played-card strip
   immediately above it.
3. Let the market begin near the top edge and consume most of the remaining
   screen. Keep the logical `2 resource + 10 action + 2 victory` arrangement and
   cost ordering, but remove the three large named carpet headers, subtitles,
   heavy panel padding, and other section chrome.
4. Present the market as one visually continuous field with only small,
   deliberate gaps. Type-colored card surfaces and accents must carry resource,
   action, and victory identity without needing large enclosing mats.
5. Reduce outer margins and all market/hand padding to the smallest values that
   still avoid clipping shadows and hover feedback.

## Card presentation

1. Increase market cards substantially from the old compact format and enlarge
   both market and hand artwork. Use aspect-covered artwork in clipped frames.
2. Preserve obvious type colors, availability borders, names, costs, VP,
   supply counts, disabled states, cursor feedback, tooltips, and hover
   animation.
3. Replace the shorthand mechanical summary on every card face with the full
   `CardDefinition.description`. Do not recreate rules text in UI code.
4. Show the same full description once in previews; do not duplicate it beneath
   a shorthand summary.
5. Keep full rules text readable with wrapping. The preview remains the
   comfortable reading surface for unusually long descriptions.

## Verification

- Update `tests/ui_smoke_test.gd` for the new hierarchy.
- Check that the market has no visible section titles or padded carpets.
- Check that both bottom docks and all cards remain inside 1280x720.
- Check that market artwork is materially taller than before.
- Check that card faces and previews display the exact data-driven description.
- Preserve all existing interaction, ordering, animation, sound, choice,
  scoring, and end-game assertions.
- Run both headless smoke tests and a release Web export.
- Visually inspect the game at 1280x720 if the local runtime permits it.
- Commit and push intended changes, leaving unrelated user edits untouched.
