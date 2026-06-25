# Complete Card Mechanics Implementation Brief

Complete the Conquest Cartes rules and UI so every one of the 38 card definitions
can resolve its stated solo effect faithfully.

## Rules architecture

- Replace automatic strongest/weakest heuristics with player choices wherever
  card text implies a choice.
- Add a reusable pending-choice and effect-queue system in the rules layer.
- Keep card definitions data-driven and keep card-specific behavior out of UI
  nodes.
- Continue omitting opponent-only attack and reaction clauses in this
  single-player game.

## Required mechanics

- Finite supply pile counts, sold-out handling, and empty-pile tracking.
- Gain a card by maximum cost and optional type, to discard, hand, or deck.
- Select cards from hand to discard, trash, or put on the deck.
- Select a card from discard to recover to the deck.
- Upgrade a selected resource and remodel a selected hand card.
- Select an action to play twice.
- Draw to a hand-size target while optionally setting action cards aside.
- Reveal cards, choose which to trash or discard, and choose top-deck order.
- Optionally play a revealed action card.
- Discard cards based on the number of empty supply piles.

## UI

- Add a generic medieval choice overlay that supports zero-to-many selection,
  required selection, skip/confirm states, supply cards, hand cards, discard
  cards, and revealed cards.
- Prevent playing, buying, or ending the turn while a choice is unresolved.
- Show supply pile counts on market cards and disable sold-out piles.
- Display full detailed rules text in card previews while retaining concise bold
  summaries on card faces.
- Preserve existing artwork, type colors, hover feedback, animations, sounds,
  HUD updates, and end-game flow.

## Verification

- Add focused rules tests for every special-effect family and every card
  definition.
- Add UI tests for the choice overlay, selection confirmation, supply counts,
  sold-out states, and detailed preview wording.
- Update design and wording documentation to describe interactive choices and
  finite supply piles.
- Run the Godot rules smoke test, UI smoke test, and Web export.
- Commit and push the completed implementation.
