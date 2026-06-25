# Card Design Rules

Cards are authored in `data/cards/starter_cards.json`. Definitions remain pure
data; gameplay resolution belongs in `scripts/core/game_state.gd`, and card UI
belongs in `scripts/ui/main_ui.gd`.

## Core fields

- `id`: stable snake-case identifier used by rules and saves.
- `name`: original display name.
- `type`: `resource`, `action`, or `victory`.
- `art_id`: filename stem under `assets/cards/`; cards may share art temporarily.
- `cost`: coin cost.
- `description`: detailed tooltip explanation written for this solo ruleset.
- `coin_value`: resource output.
- `victory_points`: fixed final score.
- `score_per_cards`: awards 1 VP per this many owned cards.
- `draw_cards`, `gain_actions`, `gain_buys`, `gain_coins`: standard outputs.
- `market_enabled`: optional; defaults to `true`.
- `special_effects`: ordered reusable effect records.

## Special effects

Every special effect has a `kind`, optional parameters, and a short `label` used
by card faces and previews. Add generalized effect kinds to the rules engine; do
not branch on individual card IDs in UI code.

Supported kinds:

- `reveal_resources_to_hand`
- `gain_best`
- `gain_card`
- `topdeck_from_hand`
- `cycle_victory_cards`
- `discard_deck`
- `trash_from_hand`
- `trash_self`
- `topdeck_from_discard`
- `draw_to_size`
- `resource_bonus`
- `upgrade_resource`
- `trash_named_for_coins`
- `remodel`
- `inspect_top`
- `inspect_top_one`
- `salvage_resource`
- `replay_action`
- `vassal`

Effects resolve in array order. For example, Harvest Feast trashes itself before
gaining a card because `trash_self` appears before `gain_best`.

## Automatic choices

Conquest Cartes currently has no selection modal. Choice-like effects therefore
use deterministic solo heuristics:

- Gain and recovery effects choose the strongest eligible card.
- Trash, remodel, and hand-to-deck effects choose the weakest eligible card.
- Inspection effects discard pure victory cards.
- Replay effects choose the strongest action in hand.

Descriptions must state what the automatic rule does. Do not imply that the player
will receive a choice that the interface does not provide.

## Market composition

`GameState` builds a twelve-card market:

- 2 resource cards
- 7 action cards
- 3 victory cards

Pebble Coin and Homestead are starter cards and do not enter the market. Every
other definition with `market_enabled: true` is eligible.

## Originality

Use original names, descriptions, art, and flavor. Do not copy names, exact rules
wording, terminology, or artwork from an existing commercial deck-builder.
