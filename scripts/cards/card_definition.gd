class_name CardDefinition
extends RefCounted

var id: String = ""
var card_name: String = ""
var card_type: String = ""
var art_id: String = ""
var cost: int = 0
var description: String = ""
var coin_value: int = 0
var victory_points: int = 0
var score_per_cards: int = 0
var draw_cards: int = 0
var gain_actions: int = 0
var gain_buys: int = 0
var gain_coins: int = 0
var market_enabled: bool = true
var special_effects: Array[Dictionary] = []


static func from_dict(data: Dictionary) -> CardDefinition:
	var card := CardDefinition.new()
	card.id = str(data.get("id", ""))
	card.card_name = str(data.get("name", "Unnamed Card"))
	card.card_type = str(data.get("type", ""))
	card.art_id = str(data.get("art_id", card.id))
	card.cost = int(data.get("cost", 0))
	card.description = str(data.get("description", ""))
	card.coin_value = int(data.get("coin_value", 0))
	card.victory_points = int(data.get("victory_points", 0))
	card.score_per_cards = int(data.get("score_per_cards", 0))
	card.draw_cards = int(data.get("draw_cards", 0))
	card.gain_actions = int(data.get("gain_actions", 0))
	card.gain_buys = int(data.get("gain_buys", 0))
	card.gain_coins = int(data.get("gain_coins", 0))
	card.market_enabled = bool(data.get("market_enabled", true))
	var effects_data = data.get("special_effects", [])
	if typeof(effects_data) == TYPE_ARRAY:
		for effect in effects_data:
			if typeof(effect) == TYPE_DICTIONARY:
				card.special_effects.append(effect.duplicate(true))
	return card


func is_playable() -> bool:
	return card_type == "resource" or card_type == "action"
