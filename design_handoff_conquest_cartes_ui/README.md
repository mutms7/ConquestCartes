# Handoff: Conquest Cartes — game table + menu screens

## Overview
This package specifies a visual + UX redesign for the Godot 4 deck‑builder **Conquest Cartes**:
the in‑game **table** (market board, hand, docks, draw/discard piles, live card preview, per‑player
turn tracker) plus four **menu screens** (Settings, Kingdom selection, Multiplayer, Multiplayer lobby).

The look is "grand & regal medieval": deep walnut + brass/parchment chrome, painterly card art,
Cinzel display type, the established card‑type colors (resource = golden umber, action = midnight blue,
victory = deep plum). It is a polished, Dominion‑style supply grid where the cards are the hero.

## About the design files
The files in `design_files/` are **design references created in HTML** (a streaming "Design Component"
prototype). They show the intended look and behavior. **They are NOT code to ship.** Your job is to
**recreate these designs in the existing Godot 4 / GDScript codebase**, using its established patterns:
UI is built in code (not `.tscn` scenes) in `scripts/ui/main_ui.gd` with `Control` nodes,
`StyleBoxFlat`, and `add_theme_*_override`. **Do not touch rules/gameplay logic** in
`scripts/core/game_state.gd` — this is presentation only. Keep all current ordering, supply, animation,
sound, preview, choice, and end‑game behavior intact, and update `tests/ui_smoke_test.gd` for any
renamed/added nodes.

### How to view the HTML reference
`design_files/Conquest Cartes UI.dc.html` references card art at `assets/cards/<art_id>.png` — the
**same filenames already in your repo** (`res://assets/cards/`). To render it, place the repo at the
web root (or open it in the design environment it came from). It needs `support.js` (included). The
HTML is a layered comparison page: scroll to the **`2a`** section for the current table, and `2b`/`2c`/
`2d`/`2e` for the menu screens. Earlier turns (`1a`–`1c`) are superseded — ignore them except as history.

## Fidelity
**High‑fidelity.** Exact colors, sizes, spacing, and interactions are given below. Recreate them as
closely as Godot theming allows. Note: the HTML uses CSS gradients/shadows; in Godot use `StyleBoxFlat`
(bg color, `corner_radius_*`, `border_*`, `shadow_*`) and `GradientTexture2D`/`TextureRect` where a true
gradient is needed. Pixel‑exact gradients are not required — match the tone and hierarchy.

---

## Target codebase map (where each piece goes)
All line refs are `scripts/ui/main_ui.gd` at time of writing.

| Design piece | Existing function / node to modify |
|---|---|
| Bottom docks, hand row, ledgers | `_build_bottom_docks()` (~935); `left_ledger`, `right_ledger`, `hand_column` |
| Market board (2 res + 10 act + 2 vic) | `_build_market_board()` (~1741); `market_resource/action/victory_container` |
| Card faces (market + hand) | `_create_card_button(...)` (~2252); `_make_card_style(...)` (~2850); `CARD_FACE_SIZE` (172×214 → 184×248) |
| Hover preview | existing preview path near `PREVIEW_SIZE` (340×480) and the clamp logic (~2725) |
| Per‑player turn tracker | `_refresh_player_status()` (~2008), `_refresh_end_turn_button()` (~2032); render into the new right panel |
| Home / menu | `_build_home_screen()` (~1045) |
| Kingdom browser + preview | `_build_kingdom_browser()` (~1256) and `_refresh_kingdom_*()` (~1555–1740) |
| Settings, Multiplayer, Lobby | new builders alongside `_build_home_screen()`; reuse its overlay/panel scaffolding |

Existing color constants (`COLOR_ACTION_CARD` etc., ~33–56) are close to the target palette — replace
their hex values with the **Design Tokens** below rather than inventing new ones.

---

## Design tokens

### Fonts
- **Display / headings / card names / numerals:** **Cinzel** (you already ship `Cinzel-SemiBold.ttf`;
  add **Cinzel‑Bold/Black** for numerals and `END TURN`). Weights used: 600 (names/labels), 700–800
  (titles, coin numbers, stat values). Header letter‑spacing ≈ +0.1em on small caps labels.
- **Body / flavor / card descriptions:** the prototype uses **EB Garamond** (warm serif). Your repo
  currently uses **Inter** for body. Either is acceptable — recommend EB Garamond for flavor/description
  text and Inter only if you prefer to avoid adding a font. Pick one and apply consistently.

### Colors (hex)
**Dark table chrome**
- Table background (radial, light center → dark edge): `#241813` → `#160E09` → `#0C0806`
- Top‑bar band: `#1C130E` (≈80% over the table), bottom border `#9C6F28` @ ~20% (`rgba(213,170,80,.2)`)
- Dock / panel fill (vertical): `#271C12` → `#150E08`; border `#9C6F28` @ ~32%, radius **15px**
- Text — primary parchment `#ECDCB6`; bright `#F4E6C4`; brass accent `#E8C879`; muted `#ECDCB6` @ ~78%
- Hairline separators: `#D5AA50` @ ~16% (`rgba(213,170,80,.16)`)
- Brass (buttons/rules): base `#9C6F28`, light `#B9882F`; primary button gradient `#F0CF80` → `#BC8A2D`, text on brass `#3A2410`

**Card type palettes** (body gradient · accent line · chip text · name text · footer label)
- **Resource:** `#3C2A14`→`#231507` · `#F0BD58` · `#F4CD72` · `#F4E6C4` · `#F0BD58` @72%
- **Action:** `#1C2D48`→`#0D1626` · `#7DB6E8` · `#BFDDF8` · `#EEF5FC` · `#7DB6E8` @74%
- **Victory:** `#36182D`→`#1F0D19` · `#E08AA2` · `#F3C4D2` · `#FDEBF1` · `#E08AA2` @74%
- **Curse** (existing): keep `#32263F` body, `#B49AD9` accent.

**Parchment menu panels** (Settings/Kingdom/Multiplayer/Lobby sit on a dark vignette backdrop with a parchment panel)
- Backdrop: radial `#241813`→`#130C08`→`#0A0705`, plus a soft brass glow top‑center (`#D5AA50` @14%).
- Panel fill (gradient): `#F5E6C0` → `#E3CB94`; outer border `#B89A5E`, radius **22px**; inner gold rule `#9C6F28` @40% inset 11px.
- Ink text on parchment: headings `#2C1D0C`, body `#3A2A16`, muted `#6E4F24`, brass label `#9C6F28`.

### Spacing / radii / sizes
- Frame: **1920×1080** (game ships 1280×720 — scale these down ~0.667, or design at 1080 and let Godot's content‑scale handle it; keep proportions).
- Card radius: market **13px**, hand **14px**, preview **20px**, kingdom tile **11px**, panels **15–22px**.
- **Card face size: 184×248** (was `CARD_FACE_SIZE` 172×214). Art band: market 128px tall, hand 136px tall.
- Market grid gap **18px**; zone gap **36px** with a 1.5px vertical brass hairline between zones.
- Bottom band height **380px**; outer table padding 36px sides.

### Shadows
- Cards at rest: `0 12px 26px rgba(0,0,0,.55)` + 2px inset dark ring. Affordable adds a 2px accent outline + `0 0 16px accent@40%` glow. Hover: lift `translateY(-6px) scale(1.03)` + brighter ring.
- Panels: `0 12px 26px rgba(0,0,0,.5)` + 1px inset dark.

### The coin (cost badge) — detailed, dark, large
- 44px circle. Outer **milled ring** = conic gradient of `#6E4A16 / #CAA044 / #7A5418 / #D8AC4C` repeated (in Godot: a small pre‑rendered coin texture, or a `StyleBoxFlat` circle with a darker border ring — a texture is closest).
- Inner 35px field = radial `#ECD086 → #BF8F37 → #83591F → #56380F` with a bright top‑left highlight and dark bottom inner shadow.
- Number: **Cinzel 800, 21px, `#241405`** with a faint warm highlight. (Recommend baking the ring+field as one `coin.png` and drawing the number as a Label on top.)

---

## Screen 2a — Game table (PRIMARY)

### Layout (top → bottom)
1. **Top bar** (height 82). Left: 28px brass star + `CONQUEST CARTES` (Cinzel 800, 25px, `#F4E6C4`) + a `BASE KINGDOM` pill (1.5px brass border, 14px brass text). Center: **Relics rail** — a rounded `#0C0805`@55% capsule, label `RELICS` (Cinzel 14px brass), then 4 slots: two filled **gilded medallions** (40px, radial brass with a small glyph + soft glow) and two **empty dashed** circles. Right: **The Bazaar** button (1.5px brass border, icon = market stall, title `THE BAZAAR` 16px + italic sub `opens between rounds` 14px brass) and a 44px **settings gear** button.
2. **Market** (fills middle). Header row: `THE MARKET` (Cinzel 15px brass, letter‑spacing .26em) + a fading brass rule + italic helper text `Outlined cards are affordable with your 5 coins. Greyed cards cost more.` (16px, muted). Below: three zones centered, gap 36, hairline separators:
   - **Treasury** (label, brass) → vertical column of **2 resource** cards.
   - **Barracks** (label, action‑blue) → **5×2 grid** of action cards (columns are 184px, gap 18).
   - **Estates** (label, victory‑rose) → vertical column of **2 victory** cards.
3. **Bottom band** (height 380), three columns, `justify: space-between`:
   - **Left dock** (width 240): three stat rows **Coins / Actions / Buys**, each = 26px outline icon + Cinzel 16px small‑caps brass label + right‑aligned **Cinzel 800, 34px** value (`#F4E6C4`). Rows divided by hairlines.
   - **Center**: a **physical Draw pile** at the far left, the **hand fan** in the middle, a **physical Discard pile** at the far right (`space-between`). A small `In play` strip (label + 2 mini face‑up cards 54×74) sits just above the hand.
   - **Right column** (width 300): **players + turns** panel on top, **End Turn** button beneath it.

### Card face (market + hand)
- Body = type gradient; rounded; 2px inset dark ring. **Art band** at top (covered image) with a bottom→up dark scrim and a 2px type‑accent line at the art's base.
- **Coin** badge top‑left (see token). **Pile count** badge top‑right: dark pill `rgba(8,5,3,.75)`, a tiny deck icon + count in the type accent color.
- Below art: **name** (Cinzel 700, 16px, type name color); a **meta chip** (uppercase Cinzel 600, 12px, on type chip bg) e.g. `+1 card · +2 actions`, `+3 coins`, `3 VP`; then the **full rules description** (13.5px, type desc color, clamp ~3 lines on the market face — full text shows in the preview). Footer: tiny type label (`RESOURCE`/`ACTION`/`VICTORY`).
- **Affordability** (drive from player coins vs the card's effective cost):
  - *Affordable*: 2px **type‑accent outline** + soft accent glow; full color; pointer cursor; hover lifts.
  - *Unaffordable*: `grayscale(.85) brightness(.78) opacity(.55)`, no outline/glow, not‑allowed cursor, no hover. (Godot: apply a desaturating `CanvasItem` modulate + dim, disable the buy button.)

### Hand
- 5 cards, **same 184×248 size as market cards**, arranged as a **fan**: rotations ≈ `-8°, -4°, 0°, 4°, 8°`, vertical offsets `16, 5, 0, 5, 16`px, horizontal overlap (margin ≈ -18px). Hover raises a card (`translateY(-32px) scale(1.06)`, bring to front). Playable action cards get a brighter accent ring + glow; non‑playable (resource/victory) get a subtler ring.

### Draw & Discard piles (NEW — make them physical)
- Both ~**158×218**, sitting at the base of the hand row (draw on the **left**, discard on the **right**), each with 2 offset/rotated layers behind to read as a stack, and a **brass count badge** (pill, Cinzel 800 18px) pinned at the top‑center; a small uppercase label below (`DRAW PILE` / `DISCARD`, Cinzel 14px brass).
- **Draw pile** = face‑down **card back**: dark walnut (`#2C1E12→#160D07`), inset gold rule frame, centered brass **sunburst** emblem.
- **Discard pile** = top card **face‑up but darkened** (`brightness ~.52, saturate ~.75`, dark overlay, muted brass accent line) so it reads clearly as spent, distinct from the bright draw deck and live hand. Bind both counts to game state (draw/discard sizes); when the draw pile empties and reshuffles, it visually refills.

### Players + turns tracker (right panel) — multiplayer aware
- Panel header: people icon + `TABLE · N PLAYERS` (Cinzel 14px brass). Then **one row per player** (`game_state.players`):
  - status dot (color by state) + **name** (Cinzel; the local player is bold + `(host)` when hosting) + right‑aligned **`TURN n`** badge (1px brass border) — this **merges the turn counter into the player list** so you can see what turn everyone is on.
  - second line: italic **status** in the dot color (`Your turn` / `Buying` / `Cooldown 3s` / `Ended`) and, when on the end‑turn cooldown, a thin **progress bar** showing remaining cooldown.
- In **solo**, show the single local player row. Drive statuses from the existing per‑player end‑turn cooldown + active‑player logic (`_refresh_player_status`, `_refresh_end_turn_button`). Each player has an independent cooldown (already true in the rules), so the bars tick down per player.
- **End Turn button** sits **below** this panel (full‑width brass primary; `END TURN` Cinzel 800 19px + italic `5 second cooldown` sub). The whole right column = panel (`flex:1`, can shrink) + 10px gap + button; ensure it fits the 380px band (compact rows ~7px vertical padding).

### Live hover preview (like the original)
- On hovering **any** market or hand card (and kingdom tiles, screen 2c), show a large card preview: art ~322px tall + name (Cinzel 800, 26px) + meta chip + **full description** (17px) + footer `TYPE · COST n COINS`. In the prototype it's pinned to the upper‑left of the table; your existing preview already clamps to the viewport edge near the cursor (`PREVIEW_SIZE`, clamp logic ~2725) — keep that behavior, just restyle to this spec and bump `PREVIEW_SIZE` so the bigger art/description fit comfortably.

---

## Screen 2b — Settings
Parchment panel (~700px wide) on the dark backdrop. Crest + title `Settings` (Cinzel 800, 46px ink) + italic subtitle + centered gold rule. Grouped rows (label left in 19px ink, control right in a 260px area), section headers in brass small‑caps:
- **Audio:** `Sound effects` (toggle), `Background music` (slider + value).
- **Gameplay:** `Action animations` (toggle), `Animation speed` (slider, e.g. `1.0×`), **`End‑turn cooldown`** (slider, `5s`).
- **Atmosphere & display:** `Table grain` (slider), `Fullscreen` (toggle).
Footer: ghost `← BACK` + primary `DONE`.
Controls: **toggle** = 58×31 pill (on = brass gradient, knob right; off = `#CDBB95`, knob left). **slider** = `#CDBB95` track, brass fill, 20px brass knob. Map these to the existing settings vars (audio, motion, noise, animation speed) and add a **turn‑cooldown** setting wired into the End Turn cooldown duration.

## Screen 2c — Kingdom selection (+ live preview)
Wide parchment panel (~1280px), three columns:
- **Left (236px):** crest + `Kingdoms`; a vertical **tab list** (`Base Kingdom` [required, selected] / `Hinterlands` 26 cards / `Economy` / `Random draw`) — selected tab = brass gradient; plus a `Random market` summary card (big `10` of `12 enabled`, explanatory italic).
- **Center:** header (`Base Kingdom` + helper text + `REQUIRED SET` pill) and a **6‑column grid of card tiles** (130px). Each tile: art thumb + dark scrim, a small cost coin top‑left, and a top‑right status: **lock** (required), **green check** (enabled), or empty circle (disabled → tile greyed `grayscale .85 / opacity .5`). Footer: `← BACK`, `ENABLE ALL`, primary `START WITH THIS KINGDOM`.
- **Right (268px):** **card preview** column. On hover of any tile, show the large preview (art + name + meta + full rules + `TYPE · COST`). When nothing is hovered, show a dashed placeholder (`Card preview — Hover any card to read its full rules here.`).
Wire to the existing kingdom browser: toggling a non‑required tile removes that card from the random market pool (`_refresh_kingdom_cards`); required (`Base Kingdom`) stays. The preview reuses the same data‑driven `CardDefinition.description`.

## Screen 2d — Multiplayer (lean)
Parchment panel (~820px): crest + `Multiplayer` + subtitle. A **2×2 grid of large buttons**, each = brass icon tile + title + **one short line**:
- `Create local` — "Host a table on your network."
- `Join local` — "Enter a host's IP to join."
- `Create online` — "Open a room with a code." (mark Coming soon if not built)
- `Join online` — "Paste a code to join." (Coming soon)
Footer: centered ghost `← BACK`. Keep copy minimal (no long paragraphs). Wire `Create local` / `Join local` to the existing host/join‑IP flow; route into the Lobby (2e).

## Screen 2e — Multiplayer lobby (NEW)
Two‑column parchment panel (~1180px), styled like the Kingdom screen:
- **Left:** crest + `Lobby` + subtitle. A **seat list** (up to 4): filled seats show avatar (initial), name (`You · host`, others), a sub line (start deck / joined IP), and a **READY / WAITING** pill (green when ready). Empty seats show a dashed `Open seat n`. Below: an **Invite** row = `Host address` field (`127.0.0.1:27041`) + `COPY`.
- **Right (420px):** `Table rules` (host‑editable): **`Turn cooldown`** (slider, `5s`), `Max players` (segmented `2 / 3 / 4`), `Attack cards` (toggle), `Kingdom` (label `Base Kingdom` + `EDIT` → opens 2c). Footer: ghost `← LEAVE` + primary `START GAME`, with italic note `Starts when all seated players are ready.`
Wire seats to `game_state.players` / network peers; host‑set rules (cooldown, max players, attacks, kingdom) configure the game before `setup_starting_game(...)`.

---

## GDScript implementation notes (accelerators)

**Dock / panel StyleBoxFlat**
```gdscript
var sb := StyleBoxFlat.new()
sb.bg_color = Color("#1d140c")            # approximates the #271C12→#150E08 fill
sb.set_corner_radius_all(15)
sb.border_color = Color(0.835, 0.667, 0.314, 0.32)  # brass @32%
sb.set_border_width_all(2)
sb.shadow_color = Color(0, 0, 0, 0.5); sb.shadow_size = 18; sb.shadow_offset = Vector2(0, 8)
panel.add_theme_stylebox_override("panel", sb)
```

**Card face StyleBoxFlat (action example) + affordability**
```gdscript
func card_style(accent: Color, affordable: bool) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#162338")                 # midnight blue body (flatten the gradient)
    s.set_corner_radius_all(13)
    s.set_border_width_all(2)
    s.border_color = affordable ? accent : Color(0,0,0,0.45)
    s.shadow_color = Color(0,0,0, affordable ? 0.55 : 0.5); s.shadow_size = affordable ? 16 : 10
    return s
# Unaffordable: also dim the whole card → card_root.modulate = Color(1,1,1,1); use a desaturation
# shader or set modulate = Color(0.7,0.7,0.66,0.55) and disable the buy button.
```

- Gradients: flatten to the **midpoint color** for `StyleBoxFlat.bg_color`, or lay a `TextureRect` with a `GradientTexture2D` behind the content for a true gradient. Brass/parchment buttons look best as a `GradientTexture2D` panel + Label.
- The **coin** and the **card back sunburst** are best shipped as small PNGs (cleaner than emulating the conic ring with shapes). Generate `coin_blank.png` (ring+field, no number) and `card_back.png`; draw the number/emblem as nodes if you prefer dynamic counts.
- Keep `_create_card_button` data‑driven: it already routes by `card_type` and shows `CardDefinition.description`. Only change sizes (→184×248), styles (tokens above), the coin/pile widgets, and the affordability state.
- Keep the existing preview clamp logic; bump `PREVIEW_SIZE` (e.g. 360×520) so the larger art + full description fit.
- Update `tests/ui_smoke_test.gd` for new/renamed nodes (draw pile, discard pile, players‑turn panel, relics rail, Bazaar button, the new menu screens) and keep the 2‑resource / 10‑action / 2‑victory market assertions.

## Suggested implementation order
1. **2a card faces** (size, coin, pile, affordability, type styles) via `_create_card_button` / `_make_card_style`.
2. **2a docks**: left resources dock, physical **draw/discard** piles flanking the hand, right **players+turns** panel + End Turn (`_build_bottom_docks`, `_refresh_player_status`).
3. **2a top bar**: title, relics rail, Bazaar button, gear.
4. **Hover preview** restyle.
5. **Menus**: 2b Settings (add turn‑cooldown), 2c Kingdom + preview, 2d Multiplayer, 2e Lobby.

## Assets
- Card art already exists in your repo at `res://assets/cards/<art_id>.png` (the HTML uses the same filenames).
- New art to produce: `coin_blank.png` (milled brass coin, no number) and `card_back.png` (walnut + gold rule + brass sunburst). Until then, approximate with StyleBoxFlat + a Label/`TextureRect` emblem.
- Fonts: `Cinzel` (you ship SemiBold; add Bold/Black). Body: EB Garamond (recommended) or keep Inter.

## Files in this bundle
- `design_files/Conquest Cartes UI.dc.html` — the HTML reference (scroll to sections **2a / 2b / 2c / 2d / 2e**; ignore 1a–1c).
- `design_files/support.js` — runtime needed to render the HTML reference.
- `README.md` — this document (self‑sufficient; implement from this alone if you can't render the HTML).
