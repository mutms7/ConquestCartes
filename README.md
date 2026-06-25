# ConquestCartes

An original single-player fantasy deck-builder built with Godot 4.7. Build a compact
engine over 15 turns, buy cards from a rotating merchant market, and turn the final
contents of your deck into victory points.

**Play online:** https://conquest-cartes.vercel.app/

## Current Game

- 38 data-driven cards with original names and painterly artwork
- A 14-card kingdom market: 2 resources, 10 actions, and 2 victory cards
- Six archived cards retained in the catalog but excluded from random markets
- Seven Pebble Coins and three Homesteads in the starting deck
- Five-card hands, reshuffling discard piles, actions, coins, and buys
- Deck searching, trashing, gaining, upgrading, replaying, and variable scoring
- Interactive card choices for discarding, trashing, gaining, upgrading,
  replaying, inspecting, and ordering cards
- Finite supply piles with visible counts and sold-out handling
- Art-linked names that preserve the identity of the original illustration library
- High-contrast type surfaces: golden umber resources, midnight-blue actions,
  and deep plum victory cards
- Final scoring after turn 15
- Handcrafted medieval tabletop UI using dark jewel-toned cards, bright brass,
  cool slate, and restrained heraldic ornament
- A three-carpet market board: Royal Treasury resources, Guild Barracks
  actions, and Crown Estates victory cards
- Card previews, movement animation, audio feedback, and an end-game score plaque
- Automated rules and UI smoke tests
- Automated Web export and production deployment

## How to Play

1. Play resource cards to gain coins.
2. Spend actions to play action cards for cards, actions, coins, or buys.
3. Spend one buy and enough coins to purchase a card from the shared market.
4. Purchased cards enter the discard pile and reduce that supply pile.
5. End the turn to discard your hand and played cards, reset turn resources, and
   draw five cards.
6. After turn 15, every victory point in your deck, hand, discard pile, and play
   area contributes to the final score.

Card surface color identifies its type. Slate-trimmed hand cards are playable,
forest-trimmed market cards are affordable, and muted trim marks cards that are
currently unavailable.

## Run Locally

1. Install Godot 4.7 and its matching export templates.
2. Open Godot's Project Manager.
3. Import this directory's `project.godot`.
4. Press **F6** or the Play button.

The project targets a 1280×720 desktop viewport and uses the
`gl_compatibility` renderer so the same project can run on the Web.

## Tests

From the repository root:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/ui_smoke_test.gd
```

The rules smoke test covers the main game loop, every playable card definition,
focused multi-step effects, finite supplies, and market composition. The UI smoke test
checks rendering, artwork, medieval UI assets, interactions, animations, audio,
preview placement, and the final-score overlay.

## Web Export

The committed `export_presets.cfg` contains a single-threaded Web preset. Export
locally with:

```powershell
New-Item -ItemType Directory -Path web -Force
godot --headless --path . --export-release "Web" web/index.html
```

The generated `web/` directory is intentionally ignored by Git.

## Automatic Deployment

Every push to `main` starts `.github/workflows/deploy.yml`. GitHub Actions:

1. Downloads and caches Godot 4.7 and its export templates.
2. Imports the project and builds Godot's script-class cache.
3. Runs both smoke tests.
4. Exports the Web build.
5. Deploys the generated files to Vercel.

The production deployment is available at
https://conquest-cartes.vercel.app/. Repository secrets hold the Vercel token and
project identifiers; no deployment credentials are committed.

## Asset Organization

- `assets/cards/` contains the finished card illustrations.
- `assets/ui/` contains original project-owned medieval interface assets.
- `assets/imported/` contains third-party visual source packs retained for
  provenance; the Kenney fantasy-border pack is no longer used by the active UI.
- `assets/audio/` contains interface sound effects.
- `assets/fonts/` contains Cinzel and Inter.
- `assets/licenses/` records sources, licenses, and attribution.

See `assets/licenses/ASSET_SOURCES.md` for provenance details.

## Current Limitations

- Single-player only; there is no opponent, multiplayer, or campaign.
- No save system, settings menu, music, or accessibility menu.
- Rival-only attack and reaction clauses are omitted in the solo ruleset.
- The art library contains 29 finished illustrations. The 38-card catalog
  currently references 28 of them; related cards share paintings through the
  data-driven `art_id` field, while Sunspire Monument remains reserve art.
- The game is balanced as a compact prototype rather than a finished commercial
  release.

Card authors should follow `docs/card_design_rules.md` and
`docs/card_wording_conventions.md`.
