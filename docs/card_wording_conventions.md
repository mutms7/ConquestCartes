# Card Wording Conventions

Use these conventions for every `description` and every visible special-effect
`label` in `data/cards/starter_cards.json`.

The wording must describe the implemented Conquest Cartes solo effect exactly.
Commercial card-game text may be used as a mechanical reference, but names,
sentences, and rules wording must remain original.

## Voice and structure

- Address the player directly with imperative verbs: `Draw`, `Gain`, `Discard`,
  `Trash`, `Reveal`, `Look at`, `Play`, and `Put`.
- Do not use third-person rules prose such as `Draws`, `Gains`, `Grants`,
  `Produces`, or `Trashes`.
- Put standard outputs first in this order: cards, actions, buys, coins.
- Put conditional or zone-changing instructions after standard outputs.
- Follow the actual resolution order used by `special_effects`.
- Use short complete sentences. End every description with a period.

Example:

`Draw 1 card. Gain 1 action. Put the strongest card in your discard pile on top of your deck.`

## Numbers and labels

- Use numerals for game quantities: `1 card`, `2 actions`, `4 coins`.
- Use singular nouns only for exactly 1.
- Use `VP` for victory points.
- Use `up to N` when fewer than N cards may be affected.
- Use `costing up to N` for an absolute gain limit.
- Use `costing up to N more` for an upgrade relative to another card.

## Zones

Use these zone names consistently:

- `hand`
- `deck`
- `discard pile`

`Gain a card` sends it to the discard pile unless the sentence names another
destination. Say `to your hand` or `on top of your deck` when required.

## Card types

In rules sentences, use lowercase:

- `action card`
- `resource`
- `victory card`

The uppercase type label in the card footer is presentation, not rules wording.

## Automatic solo choices

The current game does not open card-selection dialogs. Text must state the
automatic choice honestly:

- `the strongest card` for automatic gains, recovery, or replay
- `the weakest card` for automatic trashing or top-decking
- the exact filter, such as `the weakest resource in your hand`

Do not write `choose`, `you may`, or similar optional language unless the UI
actually presents that choice. Use `if able` when an effect can fail because no
eligible card exists.

## Special-effect labels

Card faces use compact labels derived from each `special_effects` entry. Labels:

- use title case;
- omit periods;
- stay under roughly 24 characters where practical;
- summarize rather than replace the full description;
- use the same vocabulary as the detailed rules text.

## Card creation checklist

1. Define the numeric fields and ordered `special_effects`.
2. Confirm the effect resolves correctly in the solo rules engine.
3. Write the description using this guide and the actual resolution order.
4. Add concise labels for each special effect.
5. Verify the art-linked name and `art_id`.
6. Add or update rules and UI smoke-test coverage.
7. Search for obsolete wording and run both headless test suites.
