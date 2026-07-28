extends RefCounted

# Relics are conquest-long boons drafted between turns (solo) or on a timer
# (networked lobbies). Definitions stay data-like and separate from rules code:
# GameState interprets the ids, the UI only renders name/glyph/description.

const RELIC_CAP := 4
const OFFER_SIZE := 3

const RELICS := {
	"swift_hourglass": {
		"name": "Swift Hourglass",
		"glyph": "S",
		"icon_id": "swift_hourglass",
		"description": "Your end-turn cooldown is 1 second shorter for the rest of the conquest.",
		"timed_only": true,
	},
	"victory_levy": {
		"name": "Victory Levy",
		"glyph": "V",
		"icon_id": "victory_levy",
		"description": "Once each turn, when no card in your hand can be played, gain 1 coin for each victory card in your hand.",
		"timed_only": false,
	},
	"seekers_compass": {
		"name": "Seeker's Compass",
		"glyph": "C",
		"icon_id": "seekers_compass",
		"description": "Whenever your discard pile is shuffled into your deck while drawing, choose up to 2 cards to draw first.",
		"timed_only": false,
	},
	"dawn_banner": {
		"name": "Dawn Banner",
		"glyph": "D",
		"icon_id": "dawn_banner",
		"description": "Draw 1 extra card at the start of each turn.",
		"timed_only": false,
	},
	"gilded_purse": {
		"name": "Gilded Purse",
		"glyph": "G",
		"icon_id": "gilded_purse",
		"description": "Start each turn with 1 extra coin.",
		"timed_only": false,
	},
	"marching_orders": {
		"name": "Marching Orders",
		"glyph": "M",
		"icon_id": "marching_orders",
		"description": "Start each turn with 1 extra action.",
		"timed_only": false,
	},
	"ashen_urn": {
		"name": "Ashen Urn",
		"glyph": "A",
		"icon_id": "ashen_urn",
		"description": "Whenever one of your cards is trashed, gain 1 coin.",
		"timed_only": false,
	},
	"sunflower_metronome": {
		"name": "Sunflower Metronome",
		"glyph": "N",
		"icon_id": "sunflower_metronome",
		"description": "Start each turn with 1 extra action.",
		"timed_only": false,
	},
	"thumbed_ledger": {
		"name": "Thumbed Ledger",
		"glyph": "L",
		"icon_id": "thumbed_ledger",
		"description": "The first time you buy a card each turn, gain 2 coins.",
		"timed_only": false,
	},
	"market_writ": {
		"name": "Market Writ",
		"glyph": "B",
		"icon_id": "market_writ",
		"description": "Start each turn with 1 extra buy.",
		"timed_only": false,
	},
	"culling_reliquary": {
		"name": "Culling Reliquary",
		"glyph": "Q",
		"icon_id": "culling_reliquary",
		"description": "At the start of your next turn, draw your deck, then choose up to 5 cards to trash.",
		"timed_only": false,
	},
	"hex_ward": {
		"name": "Hex Ward",
		"glyph": "H",
		"icon_id": "hex_ward",
		"description": "The first Briar Hex you would gain each turn is trashed instead.",
		"timed_only": false,
	},
	"tricksters_die": {
		"name": "Trickster's Die",
		"glyph": "T",
		"icon_id": "tricksters_die",
		"description": "At the start of each turn, one random market pile costs you 1 less that turn.",
		"timed_only": false,
	},
	"moonwake_mirror": {
		"name": "Moonwake Mirror",
		"glyph": "W",
		"icon_id": "moonwake_mirror",
		"description": "Your start-of-turn duration effects resolve twice.",
		"timed_only": false,
	},
	"patient_spider": {
		"name": "Patient Spider",
		"glyph": "P",
		"icon_id": "patient_spider",
		"description": "Relic drafts offer you 4 choices instead of 3.",
		"timed_only": false,
	},
}


static func has_relic(relic_id: String) -> bool:
	return RELICS.has(relic_id)


static func get_relic(relic_id: String) -> Dictionary:
	return RELICS.get(relic_id, {})


static func get_relic_name(relic_id: String) -> String:
	return str(get_relic(relic_id).get("name", relic_id))


static func get_relic_glyph(relic_id: String) -> String:
	return str(get_relic(relic_id).get("glyph", "*"))


static func get_relic_icon_id(relic_id: String) -> String:
	return str(get_relic(relic_id).get("icon_id", relic_id))


static func get_relic_description(relic_id: String) -> String:
	return str(get_relic(relic_id).get("description", ""))


static func get_pool(include_timed: bool) -> Array[String]:
	var pool: Array[String] = []
	for relic_id in RELICS:
		if not include_timed and bool(RELICS[relic_id].get("timed_only", false)):
			continue
		pool.append(relic_id)
	return pool


# Scoring relics are the end-of-game draft in solo play: the conquest ends after
# turn 21 and the player picks one of two to reward whatever playstyle their deck
# leaned into. The bonus math lives in GameState._scoring_relic_bonus so it stays
# next to the score tally; these entries only carry the name/glyph/description.
const SCORING_OFFER_SIZE := 2

const SCORING_RELICS := {
	"warlords_tribute": {
		"name": "Warlord's Tribute",
		"glyph": "W",
		"icon_id": "warlords_tribute",
		"description": "+1 victory point for each action card in your deck.",
	},
	"hoarders_vault": {
		"name": "Hoarder's Vault",
		"glyph": "H",
		"icon_id": "hoarders_vault",
		"description": "+1 victory point for every 2 resource cards in your deck.",
	},
	"crown_of_conquest": {
		"name": "Crown of Conquest",
		"glyph": "C",
		"icon_id": "crown_of_conquest",
		"description": "+1 victory point for each victory card in your deck.",
	},
	"ascetics_reliquary": {
		"name": "Ascetic's Reliquary",
		"glyph": "A",
		"icon_id": "ascetics_reliquary",
		"description": "+2 victory points for each card you trashed this conquest.",
	},
	"merchants_charter": {
		"name": "Merchant's Charter",
		"glyph": "M",
		"icon_id": "merchants_charter",
		"description": "+1 victory point for every 3 cards in your deck.",
	},
	"purists_medallion": {
		"name": "Purist's Medallion",
		"glyph": "P",
		"icon_id": "purists_medallion",
		"description": "+10 victory points if your deck holds 16 cards or fewer.",
	},
	"hexbreakers_idol": {
		"name": "Hexbreaker's Idol",
		"glyph": "X",
		"icon_id": "hexbreakers_idol",
		"description": "+2 victory points for each Briar Hex in your deck.",
	},
	"wanderers_map": {
		"name": "Wanderer's Map",
		"glyph": "R",
		"icon_id": "wanderers_map",
		"description": "+1 victory point for each differently named card in your deck.",
	},
}


static func has_scoring_relic(relic_id: String) -> bool:
	return SCORING_RELICS.has(relic_id)


static func get_scoring_relic(relic_id: String) -> Dictionary:
	return SCORING_RELICS.get(relic_id, {})


static func get_scoring_relic_name(relic_id: String) -> String:
	return str(get_scoring_relic(relic_id).get("name", relic_id))


static func get_scoring_relic_glyph(relic_id: String) -> String:
	return str(get_scoring_relic(relic_id).get("glyph", "*"))


static func get_scoring_relic_icon_id(relic_id: String) -> String:
	return str(get_scoring_relic(relic_id).get("icon_id", relic_id))


static func get_scoring_relic_description(relic_id: String) -> String:
	return str(get_scoring_relic(relic_id).get("description", ""))


static func get_scoring_pool() -> Array[String]:
	var pool: Array[String] = []
	for relic_id in SCORING_RELICS:
		pool.append(relic_id)
	return pool
