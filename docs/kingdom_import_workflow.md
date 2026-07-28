# Separate kingdom/import workflow (preparation only)

This document prepares future, user-supplied kingdom catalogs. It does not
govern the authorized official Dominion: Adventures implementation, whose
reviewed cards, events, journeys, Tavern mat, tokens, and Traveller piles may
already be loaded by the normal Adventures selection flow. A separate
user-supplied catalog remains opt-in and must not silently change the current
market.

## Authorized Adventures boundary

Adventures is the one approved exception to the non-Adventures originality
rules in this document. Its official identities and wording may be used when the task is
explicitly scoped to the authorized Adventures implementation. Keep Adventures
entries in the Adventures group and preserve their expansion-specific zones and
state contracts; do not copy this exception to another Dominion expansion.

## Originality and source-list checkpoint

- Every imported card outside Adventures must receive a new Conquest Cartes
  name, description, illustration identity, and stable snake-case `id`. Do not
  copy a commercial card name, exact rules sentence, recognizable terminology,
  or artwork into those catalogs. Adventures follows its approved official
  identity and wording contract instead.
- For catalogs other than Adventures, treat the requested reference expansion as
  research input only. Before any import, manually verify the source list and
  record that removed entries were excluded; record only this checkpoint, never
  the source card names or text.
- Preserve the project's voice and effect ordering in
  `docs/card_wording_conventions.md`; for non-Adventures catalogs, mechanical
  inspiration is not player-facing copy. Adventures may use its approved text.

## Catalog shape and art

Add user-authored definitions to `data/cards/kingdom_catalog.json` only after
review. The catalog may remain empty until a non-Adventures import is approved;
that preparation state is not a requirement for the active Adventures data.
Each entry should follow the fields and `special_effects` contract in
`docs/card_design_rules.md` and should remain independent of UI or rules code.

Use an existing Conquest Cartes image as temporary/placeholder art while a
dedicated illustration is unavailable. Set `art_id` to the image filename stem
under `assets/cards/`; choose an image whose visible subject fits the new name,
and document the temporary reuse in the entry's review notes. Do not add source
art or alter existing art to imitate a commercial card.

## Mechanical translation and engine gap check

For each user card, first write a short private intent summary, then translate
that intent into the closest generic `special_effects[].kind` already supported
by the engine (for example, draw, gain, discard, trash, choice, attack, or
duration families). Keep effects ordered exactly as the description.

If no generic kind expresses the intent, mark the entry `status: "blocked"` in
the review notes and list the missing capability (choice source, zone, trigger,
targeting, or timing). Do not add an ID-specific branch. A future implementer
must add a reusable effect kind, rules tests, and wording before unblocking the
card.

## Verification and eventual enablement

1. Validate JSON and schema fields; check unique IDs, costs, types, art files,
   and original wording. Re-run the manual source-list checkpoint above.
2. Add focused rules tests for each new effect family and card, then run the
   existing headless rules/UI smoke suites and a Web export.
3. Only after tests pass, make catalog loading explicit in the kingdom-selection
   flow. Keep this catalog opt-in and separate from starter definitions; selecting
   it must not silently add cards to random markets. Enable a card by setting its
   reviewed status and `market_enabled` deliberately, then verify supply counts,
   sold-out behavior, saves, and multiplayer serialization.

Until those steps are complete, keep any non-Adventures catalog opt-in and the
current game behavior unchanged. Do not disable or remove the separately
authorized Adventures implementation while preparing another catalog.
