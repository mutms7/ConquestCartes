class_name CardDefinition
extends RefCounted

var id: String = ""
var card_name: String = ""
var card_type: String = ""
var card_group: String = ""
var art_id: String = ""
var cost: int = 0
var description: String = ""
var coin_value: int = 0
var victory_points: int = 0
var score_per_cards: int = 0
var score_per_trashed: int = 0
var score_card_id: String = ""
var score_card_points: int = 0
var draw_cards: int = 0
var gain_actions: int = 0
var gain_buys: int = 0
var gain_coins: int = 0
var market_enabled: bool = true
var multiplayer_only: bool = false
# Events, Reserve cards, Traveller cards, and Journey cards are deliberately
# represented as data flags rather than hard-coded card ids.  Older card files
# simply leave these at their defaults.
var event_enabled: bool = false
var event_cost: int = -1
var event_group: String = ""
var reserve: bool = false
var traveller: bool = false
var traveller_upgrade_id: String = ""
var journey: bool = false
var tags: Array[String] = []
# Preserve extension fields so clients/tests can inspect an unfamiliar card
# definition without requiring a rules-code change for every cosmetic field.
var metadata: Dictionary = {}
var special_effects: Array[Dictionary] = []


static func from_dict(data: Dictionary) -> CardDefinition:
	var card := CardDefinition.new()
	card.id = str(data.get("id", ""))
	card.card_name = str(data.get("name", "Unnamed Card"))
	card.card_type = str(data.get("type", ""))
	card.card_group = str(data.get("group", ""))
	card.art_id = str(data.get("art_id", card.id))
	card.cost = int(data.get("cost", 0))
	card.description = str(data.get("description", ""))
	card.coin_value = int(data.get("coin_value", 0))
	card.victory_points = int(data.get("victory_points", 0))
	card.score_per_cards = int(data.get("score_per_cards", 0))
	card.score_per_trashed = int(data.get("score_per_trashed", 0))
	card.score_card_id = str(data.get("score_card_id", ""))
	card.score_card_points = int(data.get("score_card_points", 0))
	card.draw_cards = int(data.get("draw_cards", 0))
	card.gain_actions = int(data.get("gain_actions", 0))
	card.gain_buys = int(data.get("gain_buys", 0))
	card.gain_coins = int(data.get("gain_coins", 0))
	card.market_enabled = bool(data.get("market_enabled", true))
	card.multiplayer_only = bool(data.get("multiplayer_only", false))
	card.event_enabled = bool(data.get("event_enabled", data.get("is_event", false)))
	card.event_cost = int(data.get("event_cost", -1))
	card.event_group = str(data.get("event_group", ""))
	card.reserve = bool(data.get("reserve", data.get("is_reserve", false)))
	card.traveller = bool(data.get("traveller", data.get("is_traveller", false)))
	card.traveller_upgrade_id = str(data.get("traveller_upgrade_id", data.get("upgrade_to", "")))
	card.journey = bool(data.get("journey", data.get("is_journey", false)))
	var tags_data = data.get("tags", [])
	if typeof(tags_data) == TYPE_ARRAY:
		for tag in tags_data:
			card.tags.append(str(tag))
	# Keep all source fields available to generic expansion tooling.  Deep-copy
	# avoids retaining references into a parsed JSON value.
	card.metadata = data.duplicate(true)
	var effects_data = data.get("special_effects", data.get("effects", data.get("event_effects", [])))
	if typeof(effects_data) == TYPE_ARRAY:
		for effect in effects_data:
			if typeof(effect) == TYPE_DICTIONARY:
				card.special_effects.append(effect.duplicate(true))
	return card


func is_playable() -> bool:
	return card_type == "resource" or card_type == "action"


func is_event_card() -> bool:
	return event_enabled or card_type == "event"


func is_reserve_card() -> bool:
	return reserve or tags.has("reserve")


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func get_event_cost() -> int:
	return event_cost if event_cost >= 0 else cost
