import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const cardsPath = path.join(root, "data", "cards", "starter_cards.json");
const assetsDir = path.join(root, "assets", "cards");
const promptsPath = path.join(root, "docs", "card_art_prompts.md");
const outDir = path.join(root, "docs", "generated");
const batchMdPath = path.join(outDir, "dedicated_card_art_batch.md");
const batchJsonPath = path.join(outDir, "dedicated_card_art_batch.json");
const cyclesMdPath = path.join(outDir, "dedicated_card_art_cycles_5_chats.md");

const styleBlock =
  "painterly fantasy illustration, traditional digital oil painting with soft visible brushwork, warm earthy muted palette, parchment and amber tones, gentle golden-hour light, single central subject, simple uncluttered background, subtle vignette, cozy storybook medieval European countryside mood, no text, no lettering, no border, no frame";

const promptPrefix =
  "Generate square or 4:5 portrait at high resolution, then crop in-engine. No text and no border in the image. The card UI already draws the name, cost, and type, so baked-in lettering would just fight the layout.";

const subjectOverrides = {
  briar_hex: "a thorny black briar charm wrapped around a small cracked clay hex token, faint violet curse glow",
  wishing_garden: "a quiet wishing garden with a mossy standing stone, tiny coins in a hollow, and wildflowers at its base",
  starpath_seeker: "a lone traveler beside a covered wagon studying a star map under a clear night sky",
  master_weaver: "an elderly master weaver guiding luminous threads across a large wooden loom in a sunlit workshop",
  roadside_reaver: "a hidden roadside cache with a traveler's biscuit, small coins, and a worn satchel tucked under roots",
  royal_clerk: "a careful royal clerk sealing a parchment decree with red wax on a polished wooden desk",
  root_cellar: "a cozy root cellar with baskets of turnips, apples, and candlelight under a cottage floor",
  river_ward: "a narrow river detour marked by a small wooden sign and a lantern on a misty dawn bank",
  quiet_chapel: "a small candlelit chapel alcove where old records are being gently swept from a stone shelf",
  silver_merchant: "a smiling market merchant weighing shimmering silver leaves on a tiny brass scale",
  echoing_hall: "a warm stone hall where firelight seems to echo in repeating bands along carved arches",
  briar_witch: "a hedge witch's table with briar roses, a little iron gate charm, and a steaming clay cup",
  guild_workshop: "a busy loom workshop with folded cloth, wooden tools, and sunlight across the workbench",
  briar_passage: "a narrow overgrown briar passage with a small iron gate half-hidden by pale roses",
  orchard_acre: "a single golden orchard acre with young apple trees, tilled soil, and a small boundary stone",
  firefly_gold: "a few warm gold coins glowing like fireflies in a shallow wooden supper bowl",
  silverleaf_broker: "a tidy broker's desk with stacked silver leaves, ink ledger, and a small coin scale",
  river_magistrate: "a stern river magistrate's desk with a river map, seal stamp, and folded letters",
  bellfoundry_village: "a village bellfoundry with a freshly cast bronze bell cooling beside warm coals",
  orchard_surveyor: "an orchard surveyor's tripod, parchment plan, and measuring cord between apple trees",
  wishing_crossroads: "a country crossroads with a small wishing stone shrine and paths leading into soft hills",
  tinkers_development: "a tinker's bench showing a small brass device being carefully upgraded with tiny tools",
  lantern_bargainer: "a lantern-lit market stall where two hands trade coins for a small paper lantern",
  starlit_causeway: "a raised stone causeway crossing quiet fields under a bright starlit sky",
  hearthside_lodge: "a welcoming hearthside lodge with boots by the fire and wooden beams glowing amber",
  village_handyman: "a village handyman's workbench with a hammer, bell rope, patched stool, and tidy tools",
  moonwell_rest: "a peaceful moonwell rest stop with a blanket, glowing token, and still water under moonlight",
  quiet_stratagem: "a quiet strategy table in an old archive with cards, candles, and a half-open book",
  acorn_spicebroker: "an acorn-shaped spice purse spilling saffron threads, cloves, and tiny coins",
  mosswood_stable: "a mossy woodland stable with a small wagon wheel, hay, and green light through trees",
  candlecap_kettle: "a blackened kettle simmering among glowing candlecap mushrooms on a forest floor",
  briar_hound: "a loyal hound with a briar-rose collar standing before an overgrown garden gate",
  river_trail: "a winding river trail with stepping stones, reeds, and a small courier satchel on a post",
  moss_weaver: "a moss weaver's loom strung with green luminous thread and tiny leaves caught in the warp",
  stonewall_raider: "a raider's dropped satchel and lantern beside a mossy stone wall at dusk",
  briar_hut: "a small hut woven from briars and branches with warm light glowing from a round window",
  starlit_caravan: "a starlit caravan wagon with hanging lanterns and bundled trade goods on a country road",
  lantern_bazaar: "a bustling lantern bazaar stall with warm paper lanterns and neatly arranged wares",
  tinker_wheelwright: "a wheelwright's bench with a wooden cart wheel, brass fittings, and careful tinker tools",
  sunspire_bell: "a bronze bell mounted before a sunlit golden spire on a grassy hilltop",
  hourglass_reliquary: "a small hourglass set inside a gilded reliquary, golden sand glowing softly",
  twilight_retreat: "a quiet retreat path leading toward a covered wagon under lavender twilight",
  witchs_bargain: "a witch's bargain table with coins, briar thorns, a sealed note, and a small smoking candle",
  hex_eater: "a humble supper bowl where dark briar hex tokens dissolve into warm firefly light",
  hedgewarden: "a hedgewarden's lantern and staff leaning against a mossy stone wall covered in protective herbs",
  thornbinder: "a bundle of thorny briars bound with red thread around a small wooden charm",
  bramble_idol: "a small bramble idol carved from dark wood, surrounded by wishing coins and thorn blossoms",
  cursed_ingot: "a heavy dark ingot stamped with a faint curse mark, glowing from within on a worktable",
  hex_mill: "a tiny hand mill grinding brittle briar hex tokens into harmless gray dust",
  bone_cart: "a small moonlit handcart carrying old bones, reclaimed tools, and a covered lantern",
  bonepicker_crow: "a brass mechanical crow perched on a cart rail beside carefully sorted found objects",
  moth_shrine: "a quiet moth shrine beneath a celestial dome, pale wings gathered around a soft blue flame",
  reliquary_key: "an ornate key lying beside a gilded reliquary, its teeth shaped like tiny arches",
  pilgrim_stone: "a pilgrim's walking staff and small pack resting against a sunlit standing stone",
  stolen_minute: "a carved wooden whistle beside a tiny hourglass with a few grains of glowing stolen time",
  lantern_vigil: "a single lantern kept burning through the night on a village windowsill",
  moonlit_caravan: "a moonlit caravan wagon with blue lanterns and quiet horses on a pale road",
  night_ferry: "a small night ferry crossing dark water with one warm lantern at the bow",
  merchant_barge: "a low merchant barge stacked with crates, apples, and lanterns on a calm river",
  fen_lighthouse: "a squat fen lighthouse glowing through mist with candlecap mushrooms at its base",
  dream_courier: "a dream courier's sealed letter floating above a windowsill in soft dawn light",
  owl_post: "an owl post perch with a sealed letter, moss thread, and a moonlit village roof beyond",
  sowing_moon: "a moonlit seed tray with tiny sprouts, a silver token, and rich dark soil",
  long_causeway: "a long stone causeway stretching over marshland toward warm lights in the distance"
};

function readCards() {
  return JSON.parse(fs.readFileSync(cardsPath, "utf8"));
}

function pngAssets() {
  return new Set(
    fs
      .readdirSync(assetsDir)
      .filter((file) => file.toLowerCase().endsWith(".png"))
      .map((file) => path.basename(file, ".png"))
  );
}

function promptFor(card) {
  const subject =
    subjectOverrides[card.id] ??
    `a clear fantasy still-life symbol for ${card.name}, using props from a cozy medieval countryside card game`;
  return `${promptPrefix} ${card.id} , ${subject}, ${styleBlock}`;
}

function slugName(name) {
  return name
    .toLowerCase()
    .replace(/['’]/g, "")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function primaryArtOwners(cards) {
  const byArt = new Map();
  for (const card of cards) {
    const artId = card.art_id || card.id;
    if (!byArt.has(artId)) {
      byArt.set(artId, []);
    }
    byArt.get(artId).push(card);
  }

  const owners = new Map();
  for (const [artId, artCards] of byArt.entries()) {
    const owner =
      artCards.find((card) => card.id === artId) ??
      artCards.find((card) => slugName(card.name) === artId) ??
      artCards[0];
    owners.set(owner.id, artId);
  }
  return owners;
}

function dedicatedQueue(cards, assets) {
  const owners = primaryArtOwners(cards);
  return cards
    .filter((card) => !owners.has(card.id))
    .map((card) => ({
      id: card.id,
      name: card.name,
      type: card.type,
      group: card.group ?? "",
      current_art_id: card.art_id,
      target_file: `assets/cards/${card.id}.png`,
      has_dedicated_file: assets.has(card.id),
      prompt: promptFor(card)
    }));
}

function writeBatch(queue) {
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(batchJsonPath, `${JSON.stringify(queue, null, 2)}\n`);
  const lines = [
    "# Dedicated Card Art Batch",
    "",
    "Generated from `data/cards/starter_cards.json`.",
    "Use the attached/reference style image with each prompt and save accepted art to `assets/cards/<card_id>.png`.",
    "",
    `Total queued: ${queue.length}`,
    ""
  ];
  for (const item of queue) {
    const status = item.has_dedicated_file ? "done file exists" : "needs image";
    lines.push(`## ${item.id} - ${item.name}`);
    lines.push("");
    lines.push(`Status: ${status}`);
    lines.push(`Current art reuse: \`${item.current_art_id}\``);
    lines.push(`Save as: \`${item.target_file}\``);
    lines.push("");
    lines.push("```text");
    lines.push(item.prompt);
    lines.push("```");
    lines.push("");
  }
  fs.writeFileSync(batchMdPath, `${lines.join("\n")}\n`);
}

function writeShards(queue, count) {
  fs.mkdirSync(outDir, { recursive: true });
  const pending = queue.filter((item) => !item.has_dedicated_file);
  for (let shardIndex = 0; shardIndex < count; shardIndex += 1) {
    const shardItems = pending.filter((_, index) => index % count === shardIndex);
    const shardPath = path.join(outDir, `dedicated_card_art_chat_${shardIndex + 1}_of_${count}.md`);
    const lines = [
      `# Dedicated Card Art Chat ${shardIndex + 1} of ${count}`,
      "",
      "Use the same reference/style image for every prompt in this file.",
      "After each image is accepted, save it to the exact `Save as` path.",
      "",
      `Total prompts in this chat: ${shardItems.length}`,
      ""
    ];
    for (const item of shardItems) {
      lines.push(`## ${item.id} - ${item.name}`);
      lines.push("");
      lines.push(`Save as: \`${item.target_file}\``);
      lines.push("");
      lines.push("```text");
      lines.push(item.prompt);
      lines.push("```");
      lines.push("");
    }
    fs.writeFileSync(shardPath, `${lines.join("\n")}\n`);
    console.log(`Wrote ${path.relative(root, shardPath)} (${shardItems.length} prompts)`);
  }
}

function writeCycles(queue, count) {
  fs.mkdirSync(outDir, { recursive: true });
  const pending = queue.filter((item) => !item.has_dedicated_file);
  const cycleCount = Math.ceil(pending.length / count);
  const lines = [
    "# Dedicated Card Art Cycles",
    "",
    "Use this for concurrent image generation with five separate image chats.",
    "Each cycle gives one prompt per chat. Finish or skip a whole cycle before moving to the next one.",
    "",
    `Total prompts: ${pending.length}`,
    `Chats per cycle: ${count}`,
    `Total cycles: ${cycleCount}`,
    ""
  ];

  for (let cycleIndex = 0; cycleIndex < cycleCount; cycleIndex += 1) {
    lines.push(`## Cycle ${cycleIndex + 1}`);
    lines.push("");
    for (let chatIndex = 0; chatIndex < count; chatIndex += 1) {
      const item = pending[cycleIndex * count + chatIndex];
      lines.push(`### Chat ${chatIndex + 1}`);
      lines.push("");
      if (!item) {
        lines.push("No prompt for this chat in this cycle.");
        lines.push("");
        continue;
      }
      lines.push(`Card: ${item.id} - ${item.name}`);
      lines.push(`Save as: \`${item.target_file}\``);
      lines.push("");
      lines.push("```text");
      lines.push(item.prompt);
      lines.push("```");
      lines.push("");
    }
  }
  fs.writeFileSync(cyclesMdPath, `${lines.join("\n")}\n`);
  console.log(`Wrote ${path.relative(root, cyclesMdPath)} (${pending.length} prompts, ${cycleCount} cycles)`);
}

function copyToClipboard(text) {
  if (process.platform === "win32") {
    const result = spawnSync("clip.exe", { input: text });
    return result.status === 0;
  }
  if (process.platform === "darwin") {
    const result = spawnSync("pbcopy", { input: text });
    return result.status === 0;
  }
  const result = spawnSync("xclip", ["-selection", "clipboard"], { input: text });
  return result.status === 0;
}

function audit() {
  const cards = readCards();
  const assets = pngAssets();
  const artIds = new Set(cards.map((card) => card.art_id || card.id));
  const owners = primaryArtOwners(cards);
  const missing = [...artIds].filter((id) => !assets.has(id)).sort();
  const queue = dedicatedQueue(cards, assets);
  const stillNeeded = queue.filter((item) => !item.has_dedicated_file);
  console.log(`Cards: ${cards.length}`);
  console.log(`Unique art ids currently referenced: ${artIds.size}`);
  console.log(`PNG files in assets/cards: ${assets.size}`);
  console.log(`Broken art references: ${missing.length}${missing.length ? ` (${missing.join(", ")})` : ""}`);
  console.log(`Primary card-art owners: ${owners.size}`);
  console.log(`Extra cards reusing another card's art: ${queue.length}`);
  console.log(`Dedicated images still to generate: ${stillNeeded.length}`);
}

function next(copy) {
  const queue = dedicatedQueue(readCards(), pngAssets());
  const item = queue.find((entry) => !entry.has_dedicated_file);
  if (!item) {
    console.log("No dedicated art prompts left. Every reused card has assets/cards/<card_id>.png.");
    return;
  }
  console.log(`${item.id} - ${item.name}`);
  console.log(`Save as: ${item.target_file}`);
  console.log("");
  console.log(item.prompt);
  if (copy) {
    console.log("");
    console.log(copyToClipboard(item.prompt) ? "Copied prompt to clipboard." : "Could not copy prompt to clipboard.");
  }
}

function applyDedicatedArt() {
  const cards = readCards();
  const assets = pngAssets();
  let changed = 0;
  for (const card of cards) {
    if (card.art_id !== card.id && assets.has(card.id)) {
      card.art_id = card.id;
      changed += 1;
    }
  }
  if (changed > 0) {
    fs.writeFileSync(cardsPath, `${JSON.stringify(cards, null, 2)}\n`);
  }
  console.log(`Updated ${changed} card art_id value${changed === 1 ? "" : "s"}.`);
}

function usage() {
  console.log(`Usage:
  node tools/card-art-workflow.mjs audit
  node tools/card-art-workflow.mjs batch
  node tools/card-art-workflow.mjs shards [count]
  node tools/card-art-workflow.mjs cycles [count]
  node tools/card-art-workflow.mjs next [--copy]
  node tools/card-art-workflow.mjs apply

Commands:
  audit   Show current art coverage.
  batch   Write docs/generated/dedicated_card_art_batch.{md,json}.
  shards  Write non-overlapping prompt files for concurrent image chats.
  cycles  Write one prompt per chat per cycle for rate-limited image generation.
  next    Print the next prompt whose assets/cards/<card_id>.png does not exist.
  apply   After you add PNGs, update those cards to use their dedicated art_id.
`);
}

const command = process.argv[2] ?? "audit";
if (!fs.existsSync(cardsPath) || !fs.existsSync(assetsDir) || !fs.existsSync(promptsPath)) {
  console.error("Run this from the new-game-project directory.");
  process.exit(1);
}

if (command === "audit") {
  audit();
} else if (command === "batch") {
  const queue = dedicatedQueue(readCards(), pngAssets());
  writeBatch(queue);
  console.log(`Wrote ${path.relative(root, batchMdPath)}`);
  console.log(`Wrote ${path.relative(root, batchJsonPath)}`);
} else if (command === "shards") {
  const count = Number.parseInt(process.argv[3] ?? "5", 10);
  if (!Number.isInteger(count) || count < 2 || count > 20) {
    console.error("Shard count must be an integer from 2 to 20.");
    process.exit(1);
  }
  writeShards(dedicatedQueue(readCards(), pngAssets()), count);
} else if (command === "cycles") {
  const count = Number.parseInt(process.argv[3] ?? "5", 10);
  if (!Number.isInteger(count) || count < 2 || count > 20) {
    console.error("Cycle chat count must be an integer from 2 to 20.");
    process.exit(1);
  }
  writeCycles(dedicatedQueue(readCards(), pngAssets()), count);
} else if (command === "next") {
  next(process.argv.includes("--copy"));
} else if (command === "apply") {
  applyDedicatedArt();
} else {
  usage();
  process.exitCode = 1;
}
