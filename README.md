# ConquestCartes

An original fantasy deck-builder built with Godot 4.7. Build a compact
engine, buy cards from a rotating merchant market, and turn the final
contents of your deck into victory points.

**Play online:** https://conquest-cartes.vercel.app/

## Current Game

- 63 data-driven cards with original names and painterly artwork
- A 14-card kingdom market: 2 resources, 10 actions, and 2 victory cards
- A named 26-card Hinterlands group within the card catalog
- Seven support or archived cards retained in the catalog but excluded from random markets
- Seven Pebble Coins and three Homesteads in the starting deck
- Five-card hands, reshuffling discard piles, actions, coins, and buys
- Deck searching, trashing, gaining, upgrading, replaying, and variable scoring
- Interactive card choices for discarding, trashing, gaining, upgrading,
  replaying, inspecting, and ordering cards
- Gain, buy, discard, trash, and cleanup triggers for reactive cards
- Temporary cost reductions, progressive resources, and event-driven bonuses
- Direct-IP 2-player lobby tables with shared supplies and attacks that hit rivals
- 0-cost Briar Hex curses worth -1 VP
- Parallel 5-second end-turn cooldowns that still allow card play while they count down
- Finite supply piles with visible counts and sold-out handling
- Art-linked names that preserve the identity of the original illustration library
- High-contrast type surfaces: golden umber resources, midnight-blue actions,
  deep plum victory cards, and violet-black curses
- Final scoring when three supply piles empty or the 6 VP pile empties
- Handcrafted medieval tabletop UI using dark jewel-toned cards, bright brass,
  cool slate, and restrained heraldic ornament
- Startup home screen with Sunspire artwork, New Game, Create Lobby, Continue,
  Settings, and Kingdoms
- Home settings for visual noise and action-animation speed
- A tabbed Kingdoms browser with full card faces and market-pool toggles
- Kingdom and individual-card toggles that filter the random market pool
- An art-first market field with resources on the left, ten actions in the
  center, and victory cards on the right
- Centered card rules with bold shorthand for numeric gains and large hover previews
- Card previews, movement animation, quiet UI audio, layered medieval background music,
  and an end-game score plaque
- Automated rules and UI smoke tests
- Automated Web export and production deployment

## How to Play

1. Play resource cards to gain coins.
2. Spend actions to play action cards for cards, actions, coins, or buys.
3. Spend one buy and enough coins to purchase a card from the shared market.
4. Purchased cards enter the discard pile and reduce that supply pile.
5. End the turn to start a 5-second cooldown; you can still play cards while it
   counts down.
6. When the cooldown ends, discard your hand and played cards, reset turn
   resources, and draw five cards.
7. The game ends when three supply piles are empty or the 6 VP pile empties.
8. Every victory point in your deck, hand, discard pile, and play area
   contributes to the final score.

Card surface color identifies its type. Slate-trimmed hand cards are playable,
forest-trimmed market cards are affordable, and muted trim marks cards that are
currently unavailable.

## Multiplayer

`CREATE LOBBY` hosts a direct-IP desktop lobby on port `27041`. The host is
Player 1. Player 2 enters the host's IP address in the home-screen address field
and presses `JOIN LOBBY`. The host owns the authoritative game state and
broadcasts every play, buy, choice, personal cooldown, cleanup, attack, and
score update to the client. Players act in parallel; pressing End Turn only
starts that player's own cooldown and does not hand control of the table to the
other player.

For internet play outside the same LAN, the host must allow inbound traffic on
port `27041` or use a VPN/tunnel such as Tailscale, ZeroTier, or another private
network. Browser-hosted no-port-forward matchmaking would require a separate
relay/signaling service.

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

- Direct-IP multiplayer requires LAN reachability, port forwarding, or a VPN.
- No save system, relay matchmaking, or full accessibility menu.
- Rival-only reaction clauses are omitted in the solo ruleset.
- The art library contains 29 finished illustrations. The 63-card catalog
  currently references 29 of them; related cards share paintings through the
  data-driven `art_id` field.
- The game is balanced as a compact prototype rather than a finished commercial
  release.

Card authors should follow `docs/card_design_rules.md` and
`docs/card_wording_conventions.md`.
