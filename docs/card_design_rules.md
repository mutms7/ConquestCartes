# Card Design Rules

Working guidelines for authoring cards in `data/cards/starter_cards.json`. Cards are
pure data: each one is a combination of the numeric fields `draw_cards`,
`gain_actions`, `gain_coins`, `gain_buys`, plus `coin_value` (resources) and
`victory_points` (victory cards). Rules logic lives in `scripts/core/`, so balance
is tuned entirely through this data file.

## The cantrip caveat

Because action cards cost 1 action to play, a card that only gives +1 action and
draws 1 card is neutral. It refunds the action it cost and replaces itself in hand,
so it nets to zero. It may be useful for cycling later (in a deck with payload worth
digging for, a free cantrip thins toward it), but early prototype cards should
usually provide an additional benefit so that every market card feels obviously
worth buying.

For now: avoid action cards whose only effect is +1 card and +1 action.

## Good "cantrip-plus" patterns

A `+1 card / +1 action` base is already worth roughly 3 cost on its own, so adding a
real benefit on top generally lands the card around cost 4. Useful starting points:

- `+1 card / +2 actions` (cost ~3-4)
- `+2 cards / +1 action` (cost ~4)
- `+1 card / +1 action / +1 coin` (cost ~3-4)
- `+1 card / +1 action / +1 buy` (cost ~3-4)
- `+1 card / +1 action` plus a small unique bonus

When picking a pattern, check the existing set first. Several of these lines are
already in use, and shipping a duplicate stat line (or a cheaper, strictly-better
copy of an existing card) hurts the prototype more than it helps. The current set
already covers `+1c/+1a/+1coin` (Hearthsong), `+1c/+1a/+1buy` (Orchard Map), and
`+1c/+2a` (Tinker Wren), so new cantrip-plus cards should fill a different gap.

## Victory cards with a benefit (hybrids)

The rules engine only "plays" cards whose type is `action` or `resource`
(`CardDefinition.is_playable()`), but `calculate_score()` counts `victory_points`
on *every* owned card regardless of type. So a victory card that also does
something useful is authored as a playable card that carries victory points:

- Action-victory (e.g. Scholar's Hall): `type` is `action`, gives a small play
  effect, and has `victory_points`. It costs an action to play like any action.
- Treasure-victory (e.g. Gilded Reliquary): `type` is `resource`, gives coins
  when played, and has `victory_points`.

These score at the end of the game while still earning their keep during it, so
they avoid the "dead card in hand" feel of a pure victory card. Keep the bonus
slight and the cost a little above a plain version, since the victory points are
real value on their own. Pure `victory`-type cards remain non-playable and exist
only for end-game points.

## Cost guidance

- Keep costs aligned with the rest of the set rather than to an absolute formula.
- A simple `+1 card / +2 actions` card should cost around 3.
- A `+1 card / +1 action / +1 coin` or `+1 card / +1 action / +1 buy` card should
  cost around 3 or 4.
- A `+2 cards / +1 action` card is a strong non-terminal draw engine; price the
  bare pattern around 5, and add roughly 1 cost per extra effect. Anything that
  draws 2+ and is non-terminal (e.g. Weaver's Loom at `+2 cards / +2 actions`,
  cost 6) should sit at the top of the curve.
- Plain victory cards scale up the curve: higher cost buys more points per coin
  (cost 7 ≈ 7 points, cost 8 ≈ 9, cost 9 ≈ 11), so expensive scoring cards are a
  real late-game payoff.

## Market composition

Every market is drawn to a fixed makeup, defined by the `MARKET_*` constants in
`scripts/core/game_state.gd`:

- 2 resource / coin cards (`MARKET_RESOURCE_COUNT`)
- 6 action cards (`MARKET_ACTION_COUNT`)
- 4 victory cards total (`MARKET_VICTORY_TOTAL`), made up of a random 1-2 hybrid
  victory cards (`MARKET_HYBRID_VICTORY_MIN`/`MAX`) and the remaining 2-3 plain
  victory cards

Cards are sorted into categories by `_card_category()`: anything of `type`
`victory` is a plain victory card; any other card with `victory_points > 0` is a
hybrid victory card; the rest fall under their `resource` / `action` type. So a
hybrid fills a victory slot, not an action or resource slot, even though it is
played like one.

Keep enough non-starter cards in every category for the draw to succeed (at least
3 plain victory and 2 hybrid victory, since those are the per-game maximums). When
changing the counts, update the constants; `MARKET_SIZE` is their sum.

## Theming

Use original names, art, and flavor. Do not copy names, card text, or designs from
existing commercial deck-builders.
