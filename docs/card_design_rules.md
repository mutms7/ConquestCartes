# Card Design Rules

Cards are authored in `data/cards/starter_cards.json`. Definitions remain pure
data; gameplay resolution belongs in `scripts/core/game_state.gd`, and card UI
belongs in `scripts/ui/main_ui.gd`.

Before writing or revising any card text, read
`docs/card_wording_conventions.md`. Its checklist is part of the card creation
process.

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
- `market_enabled`: optional; defaults to `true`. Set it to `false` to retain a
  complete playable definition while excluding it from random market setup.
- `special_effects`: ordered reusable effect records.

## Special effects

Every special effect has a `kind`, optional parameters, and a short `label` used
by card faces and previews. Add generalized effect kinds to the rules engine; do
not branch on individual card IDs in UI code.

Effects default to `trigger: "play"`. Reactive effects may instead use
`gain`, `buy`, `gain_reaction`, `discard`, or `trash`. Cleanup effects register
turn state during play and resolve through the cleanup choice flow.

Supported kinds:

- `reveal_resources_to_hand`
- `gain_from_supply`
- `gain_card`
- `topdeck_from_hand`
- `discard_from_hand_draw`
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
- `discard_per_empty_supply`
- `progressive_resource`
- `draw_per_type_in_hand`
- `first_play_actions`
- `survey_top`
- `develop`
- `register_buy_bonus`
- `reduce_costs`
- `discard_filtered`
- `trash_filtered`
- `topdeck_action_at_cleanup`
- `trash_resource_choose_bonus`
- `discard_resource_bonus`
- `conditional_draw`
- `choose_named_or_supply`
- `gain_cheaper`
- `gain_coins_trigger`
- `play_self_optional`
- `play_self_if_action_in_play`
- `dynamic_hand_coins`
- `discard_for_action_gain`
- `optional_gain_card`
- `trash_for_copies`
- `replace_gain`
- `shuffle_actions_from_discard`
- `upgrade_exact_nonself`

Effects resolve in array order. Descriptions and compact labels must present that
same order.

## Interactive choices

Choice-like effects create a `CardChoice` in the rules layer. The UI renders that
request generically and returns selected candidate tokens to `GameState`; it does
not decide what the selected cards do.

Use reusable choice sources and resolvers rather than card IDs. Required and
optional selections, supply gains, multi-card selections, revealed cards, and
multi-step continuations all use the same pending-choice/effect-queue system.
Mode choices reuse the same overlay with labeled versions of the source card, so
bonus modes remain data-driven without card-specific UI.

## Card creation process

1. Choose an original art-linked name and `art_id`.
2. Define the numeric fields and ordered reusable special effects.
3. Implement generalized rules support when a new effect kind is required.
4. Write `description` and effect labels using
   `docs/card_wording_conventions.md`.
5. Add rules tests for mechanics and wording, plus UI coverage when presentation
   changes.
6. Run both headless test suites and a Web export.

## Names and illustration identity

The original illustration name should remain the display name when a single card
uses that artwork. If multiple rules cards share an `art_id`, keep one exact
original name and name the variants after the same visible subject plus their
role, such as `Hearthsong Refrain` or `Trail Biscuit Cache`.

Do not give a card a name that contradicts its illustration merely to mirror the
source role that inspired its mechanics. IDs may remain mechanically descriptive;
the player-facing name should describe the actual Conquest Cartes artwork.

## Type surfaces

Card faces and previews use a generic, high-contrast type-based dark surface:

- resources: golden umber with an amber inner accent
- actions: midnight blue with a pale blue inner accent
- victory cards: deep plum with a rose inner accent

Availability and playability remain bright outer-border states. Type styling
uses the card body, art-frame accent, and footer label and must be derived from
`card_type`, never from individual card IDs.

## Market composition

`GameState` builds a fourteen-card market:

- 2 resource cards
- 10 action cards
- 2 victory cards

The UI routes these definitions by `card_type` into the Royal Treasury, Guild
Barracks, and Crown Estates carpets. Market presentation must not branch on
individual card IDs.

Pebble Coin and Homestead are starter cards and do not enter the market. Every
other definition with `market_enabled: true` is eligible. A
`market_enabled: false` card remains loadable, playable in tests or future modes,
and available to preserve its art/name identity.

Each selected market card receives a finite pile. Buying or gaining decrements
that pile; empty piles cannot be bought or gained and count toward effects that
reference empty supply piles.

## Originality

Use original names, descriptions, art, and flavor. Do not copy names, exact rules
wording, terminology, or artwork from an existing commercial deck-builder.
