# Hinterland Mechanics Expansion Plan

Add an original 26-card mechanics expansion, grouped as **Hinterlands**,
inspired by the supplied reference list while preserving Conquest Cartes names,
wording, artwork, and solo rules.

## Explicit exclusions

Do not add equivalents of Duchess, Oracle, Noble Brigand, Nomad Camp, Silk Road,
Cache, Embassy, Ill-Gotten Gains, or Mandarin.

## Included original cards

| Reference mechanic | Conquest Cartes card | Art |
| --- | --- | --- |
| Tunnel | Briar Passage | `briar_gate` |
| Farmland | Orchard Acre | `orchard_estate` |
| Fool's Gold | Firefly Gold | `firefly_supper` |
| Trader | Leaf Broker | `silver_leaf` |
| Margrave | Magistrate | `river_courier` |
| Border Village | Bellfoundry | `village_bell` |
| Cartographer | Orchard Survey | `orchard_map` |
| Crossroads | Wish Crossroads | `wishing_stone` |
| Develop | Tinker Dev | `tinker_wren` |
| Haggler | Lantern Trade | `lantern_parade` |
| Highway | Star Causeway | `starlit_wagon` |
| Inn | Hearth Lodge | `hearthsong` |
| Jack of All Trades | Handyman | `village_bell` |
| Oasis | Moonwell Rest | `moonwell_token` |
| Scheme | Quiet Stratagem | `quiet_archive` |
| Spice Merchant | Spicebroker | `acorn_purse` |
| Stables | Mosswood Stable | `moss_thread` |
| Cauldron | Cap Kettle | `candlecap` |
| Guard Dog | Briar Hound | `briar_gate` |
| Trail | River Trail | `river_courier` |
| Weaver | Moss Weaver | `weavers_loom` |
| Berserker | Stone Raider | `stone_wall` |
| Witch's Hut | Briar Hut | `briar_gate` |
| Nomads | Star Caravan | `starlit_wagon` |
| Souk | Lantern Bazaar | `lantern_parade` |
| Wheelwright | Cartwright | `tinker_wren` |

## Generalized systems

1. Add data-driven effect triggers for play, gain, buy, discard, trash, and
   cleanup.
2. Centralize non-cleanup discard/trash movement so reaction effects can queue
   consistently.
3. Add temporary turn cost reductions and use effective cost for purchases and
   supply-gain restrictions.
4. Add reusable choices for exact-cost gains, gain replacement, mode selection,
   revealed-card ordering, filtered hand choices, and action recovery.
5. Add gain/buy watchers for cheaper bonus gains and Silver Leaf replacement.
6. Allow cleanup to pause for a card choice and resume the turn afterward.
7. Resolve attack clauses as solo pressure while omitting rival-only reactions.

## Validation

- Every new definition must use existing artwork and original wording.
- Add focused tests for every new generalized mechanic and ensure all 63 card
  definitions can complete resolution without an endless choice chain.
- Preserve the 2-resource, 10-action, 2-victory market layout.
- Run rules and UI smoke tests plus the Web release export.
