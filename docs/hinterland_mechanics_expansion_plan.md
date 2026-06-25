# Hinterland Mechanics Expansion Plan

Add an original 26-card mechanics expansion inspired by the supplied reference
list while preserving Conquest Cartes names, wording, artwork, and solo rules.

## Explicit exclusions

Do not add equivalents of Duchess, Oracle, Noble Brigand, Nomad Camp, Silk Road,
Cache, Embassy, Ill-Gotten Gains, or Mandarin.

## Included original cards

| Reference mechanic | Conquest Cartes card | Art |
| --- | --- | --- |
| Tunnel | Briar Passage | `briar_gate` |
| Farmland | Orchard Acre | `orchard_estate` |
| Fool's Gold | Firefly Gold | `firefly_supper` |
| Trader | Silverleaf Broker | `silver_leaf` |
| Margrave | River Magistrate | `river_courier` |
| Border Village | Bellfoundry Village | `village_bell` |
| Cartographer | Orchard Surveyor | `orchard_map` |
| Crossroads | Wishing Crossroads | `wishing_stone` |
| Develop | Tinker's Development | `tinker_wren` |
| Haggler | Lantern Bargainer | `lantern_parade` |
| Highway | Starlit Causeway | `starlit_wagon` |
| Inn | Hearthside Lodge | `hearthsong` |
| Jack of All Trades | Village Handyman | `village_bell` |
| Oasis | Moonwell Rest | `moonwell_token` |
| Scheme | Quiet Stratagem | `quiet_archive` |
| Spice Merchant | Acorn Spicebroker | `acorn_purse` |
| Stables | Mosswood Stable | `moss_thread` |
| Cauldron | Candlecap Kettle | `candlecap` |
| Guard Dog | Briar Hound | `briar_gate` |
| Trail | River Trail | `river_courier` |
| Weaver | Moss Weaver | `weavers_loom` |
| Berserker | Stonewall Raider | `stone_wall` |
| Witch's Hut | Briar Hut | `briar_gate` |
| Nomads | Starlit Caravan | `starlit_wagon` |
| Souk | Lantern Bazaar | `lantern_parade` |
| Wheelwright | Tinker Cartwright | `tinker_wren` |

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
7. Omit rival-only attack and reaction clauses in the single-player ruleset.

## Validation

- Every new definition must use existing artwork and original wording.
- Add focused tests for every new generalized mechanic and ensure all 64 card
  definitions can complete resolution without an endless choice chain.
- Preserve the 2-resource, 10-action, 2-victory market layout.
- Run rules and UI smoke tests plus the Web release export.
