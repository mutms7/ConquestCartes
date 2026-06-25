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

## Names and illustration identity

The original illustration name should remain the display name when a single card
uses that artwork. If multiple rules cards share an `art_id`, keep one exact
original name and name the variants after the same visible subject plus their
role, such as `Hearthsong Refrain` or `Trail Biscuit Cache`.

Do not give a card a name that contradicts its illustration merely to mirror the
source role that inspired its mechanics. IDs may remain mechanically descriptive;
the player-facing name should describe the actual Conquest Cartes artwork.

## Type surfaces

Card faces and previews use a generic type-based dark surface:

- resources: warm umber
- actions: cool smoked walnut
- victory cards: restrained oxblood walnut

Availability and playability remain border states. Type styling must be derived
from `card_type`, never from individual card IDs.

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
