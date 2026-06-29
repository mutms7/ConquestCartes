# Card Art Library Prompts

Ready-to-paste prompts for the existing illustration library under
`assets/cards/`. Card definitions select these images through `art_id`, and their
player-facing names retain the subject identity of the assigned painting. The
63-card rules catalog can temporarily reuse the 29 finished paintings. It
currently references 28 unique paintings, with Sunspire Monument held in reserve.
The goal
is a warm, painterly storybook look with a consistent style across the whole set.
Each prompt is a fixed **style block** plus a per-image **subject**.

## How to use

1. Pick one generator and stick with it for the whole set (consistency matters
   more than any single image). Midjourney gives the closest painterly look;
   ChatGPT / DALL-E is fine for a prototype.
2. Generate a **hero card first** (Hearthsong or Quiet Archive are good anchors).
   Once you love one, lock the style:
   - **Midjourney:** grab its `--sref` code and append the suffix below to every
     prompt so the set shares one style.
   - **ChatGPT / DALL-E:** upload the hero image with each new prompt and say
     "match this exact painting style, palette, and lighting." This fights drift.
3. Generate **square or 4:5 portrait** at high resolution, then crop in-engine.
4. **No text and no border in the image.** The card UI already draws the name,
   cost, and type, so baked-in lettering would just fight the layout.
5. Save each file by card id: `assets/cards/<id>.png` (e.g.
   `assets/cards/village_bell.png`) so the game can load art by convention.

## Style block (identical for every card)

> painterly fantasy illustration, traditional digital oil painting with soft
> visible brushwork, warm earthy muted palette, parchment and amber tones, gentle
> golden-hour light, single central subject, simple uncluttered background, subtle
> vignette, cozy storybook medieval European countryside mood, no text, no
> lettering, no border, no frame

**Optional Midjourney suffix** (append to every prompt once you have a style code):
`--ar 4:5 --style raw --sref <YOUR_CODE> --sw 80`

A note on the look: do not prompt "in the style of Dominion" or name its artists.
That risks derivative art and cuts against the project's no-copying rule. The style
block above captures the same ingredients (oil-painted, warm, single subject, cozy
medieval) on its own.

---

## Resource cards

**pebble_coin** , a single smooth river pebble carved with a simple coin rune resting in an open palm, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**silver_leaf** , two shimmering silver-veined leaves pinned to a small wooden coin tray, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**acorn_purse** , a small drawstring purse shaped like an acorn spilling a few tiny coins onto moss, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**moonwell_token** , a pale glowing token resting on the mossy stone rim of a moonlit wishing well, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**amber_circlet** , a delicate circlet set with glowing amber gems resting on a velvet cushion, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**gilded_reliquary** *(also worth victory points)* , an ornate gilded reliquary casket studded with gemstones resting on an embroidered altar cloth, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

## Victory cards

**homestead** , a small thatched-roof cottage with a tidy vegetable garden at dusk, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**stone_wall** , a sturdy moss-covered dry-stone wall winding across rolling green hills, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**briar_gate** , an old iron garden gate overgrown with flowering briar roses, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**royal_charter** , an ornate wax-sealed royal charter scroll with trailing ribbons on a wooden desk, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**wishing_stone** , a large smooth standing stone with a worn wishing hollow and a scatter of coins at its base, soft inner glow, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**sunspire_monument** , a tall golden spire monument catching the first sunrise light atop a grassy hill, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**astral_vault** , a domed celestial vault of polished marble open to a starlit sky with softly glowing constellations, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

## Action cards

**village_bell** , a weathered bronze bell hanging in a small wooden village belfry, rope gently swaying, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**candlecap** , a cluster of glowing mushroom caps shaped like candle flames on a dim forest floor, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**trail_biscuit** , a hearty traveler's biscuit and a worn leather satchel resting on a mossy log beside a forest path, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**moss_thread** , several spools of green moss-dyed thread on a rustic weaver's table, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**hearthsong** , a cozy stone hearth with a crackling fire and a copper kettle, warm glow filling the room, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**orchard_map** , a hand-drawn parchment map of an apple orchard with a brass compass and a single fallen apple, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**river_courier** , a courier in a small wooden boat rowing down a misty river at dawn with a satchel of letters, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**tinker_wren** , a tiny mechanical wren of polished brass gears perched among a tinker's small tools, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**lantern_parade** , a row of glowing paper lanterns strung over a festive village street at twilight, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**quiet_archive** , a candlelit shelf of old leather-bound tomes in a hushed stone library, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**starlit_wagon** , a covered merchant wagon resting on a country road beneath a sky full of stars, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**firefly_supper** , an outdoor evening supper table lit by jars of fireflies, warm and inviting, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**weavers_loom** , a large wooden weaver's loom strung with faintly luminous threads in a sunlit workshop, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**dawn_whistle** , a carved wooden whistle on a windowsill catching the first warm light of dawn, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**scholars_hall** *(also worth victory points)* , a grand scholar's hall with tall arched windows and rows of wooden reading desks, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

**orchard_estate** *(also worth victory points)* , a stately manor house overlooking neat rows of fruit trees in golden afternoon light, painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame

---

## Keeping this in sync

When a replacement card receives dedicated art, create a new prompt with the same
style block, save the result as `assets/cards/<new_art_id>.png`, and update the
card's `art_id`. Until then, intentional reuse is preferable to blank card faces.

Every definition must have a valid `art_id`. Multiple cards may point to one
painting when their names share the same visible subject. Market eligibility is
independent of artwork: archived cards remain in the catalog with their art even
when `market_enabled` is `false`.
