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
		"description": "Your end-turn cooldown is 1 second shorter for the rest of the conquest.",
		"timed_only": true,
	},
	"victory_levy": {
		"name": "Victory Levy",
		"glyph": "V",
		"description": "Once each turn, when no card in your hand can be played, gain 1 coin for each victory card in your hand.",
		"timed_only": false,
	},
	"seekers_compass": {
		"name": "Seeker's Compass",
		"glyph": "C",
		"description": "Whenever your discard pile is shuffled into your deck while drawing, choose up to 2 cards to draw first.",
		"timed_only": false,
	},
	"dawn_banner": {
		"name": "Dawn Banner",
		"glyph": "D",
		"description": "Draw 1 extra card at the start of each turn.",
		"timed_only": false,
	},
	"gilded_purse": {
		"name": "Gilded Purse",
		"glyph": "G",
		"description": "Start each turn with 1 extra coin.",
		"timed_only": false,
	},
	"marching_orders": {
		"name": "Marching Orders",
		"glyph": "M",
		"description": "Start each turn with 1 extra action.",
		"timed_only": false,
	},
	"ashen_urn": {
		"name": "Ashen Urn",
		"glyph": "A",
		"description": "Whenever one of your cards is trashed, gain 1 coin.",
		"timed_only": false,
	},
	"sunflower_metronome": {
		"name": "Sunflower Metronome",
		"glyph": "N",
		"description": "The first action card you play from your hand each turn is played twice.",
		"timed_only": false,
	},
	"thumbed_ledger": {
		"name": "Thumbed Ledger",
		"glyph": "L",
		"description": "The first time you buy a card each turn, gain 1 coin.",
		"timed_only": false,
	},
	"hex_ward": {
		"name": "Hex Ward",
		"glyph": "H",
		"description": "The first Briar Hex you would gain each turn is trashed instead.",
		"timed_only": false,
	},
	"tricksters_die": {
		"name": "Trickster's Die",
		"glyph": "T",
		"description": "At the start of each turn, one random market pile costs you 1 less that turn.",
		"timed_only": false,
	},
	"moonwake_mirror": {
		"name": "Moonwake Mirror",
		"glyph": "W",
		"description": "Your start-of-turn duration effects resolve twice.",
		"timed_only": false,
	},
	"patient_spider": {
		"name": "Patient Spider",
		"glyph": "P",
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


static func get_relic_description(relic_id: String) -> String:
	return str(get_relic(relic_id).get("description", ""))


static func get_pool(include_timed: bool) -> Array[String]:
	var pool: Array[String] = []
	for relic_id in RELICS:
		if not include_timed and bool(RELICS[relic_id].get("timed_only", false)):
			continue
		pool.append(relic_id)
	return pool
