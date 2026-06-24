class_name GameState
extends RefCounted

const STARTING_CARD_COUNTS := {
	"pebble_coin": 7,
	"homestead": 3,
}

const MARKET_CARD_IDS := [
	"silver_leaf",
	"village_bell",
	"market_fox",
	"scribe",
	"stone_wall",
	"royal_charter",
]

var player := PlayerState.new()
var card_catalog: Dictionary = {}
var market: Array[CardDefinition] = []


func load_cards(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open card data: %s" % path)
		return false

	var parsed_data = JSON.parse_string(file.get_as_text())
	if typeof(parsed_data) != TYPE_ARRAY:
		push_error("Card data must be a JSON array: %s" % path)
		return false

	card_catalog.clear()
	for entry in parsed_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var card := CardDefinition.from_dict(entry)
		if card.id.is_empty():
			push_warning("Skipped a card with no id.")
			continue
		card_catalog[card.id] = card

	return not card_catalog.is_empty()


func setup_starting_game() -> bool:
	player.clear_all()
	market.clear()
	print("[Game] Game start")

	for card_id in STARTING_CARD_COUNTS:
		if not card_catalog.has(card_id):
			push_error("Missing starting card definition: %s" % card_id)
			return false
		for _copy_index in range(STARTING_CARD_COUNTS[card_id]):
			player.draw_pile.append(card_catalog[card_id])

	player.draw_pile.shuffle()
	print("[Game] Shuffle starting deck (%d cards)" % player.draw_pile.size())

	for card_id in MARKET_CARD_IDS:
		if not card_catalog.has(card_id):
			push_error("Missing market card definition: %s" % card_id)
			return false
		market.append(card_catalog[card_id])

	return true


func reset_turn_resources() -> void:
	player.reset_turn_resources()


func draw_cards(amount: int) -> void:
	for _draw_index in range(amount):
		if player.draw_pile.is_empty():
			if player.discard_pile.is_empty():
				return
			player.draw_pile.append_array(player.discard_pile)
			player.discard_pile.clear()
			player.draw_pile.shuffle()
			print("[Game] Shuffle discard into draw pile (%d cards)" % player.draw_pile.size())

		var card: CardDefinition = player.draw_pile.pop_back()
		player.hand.append(card)
		print("[Game] Draw: %s" % card.card_name)


func play_card(card: CardDefinition) -> bool:
	if card == null or not card.is_playable():
		return false

	var hand_index := player.hand.find(card)
	if hand_index == -1:
		return false

	if card.card_type == "action":
		if player.actions <= 0:
			return false
		player.actions -= 1

	player.hand.remove_at(hand_index)
	player.play_area.append(card)
	player.coins += card.coin_value + card.gain_coins
	player.actions += card.gain_actions
	player.buys += card.gain_buys
	print("[Game] Play card: %s" % card.card_name)

	if card.draw_cards > 0:
		draw_cards(card.draw_cards)

	return true


func buy_card(card: CardDefinition) -> bool:
	if card == null or not market.has(card):
		return false
	if player.buys <= 0 or player.coins < card.cost:
		return false

	player.coins -= card.cost
	player.buys -= 1
	player.discard_pile.append(card)
	print("[Game] Buy card: %s for %d coins" % [card.card_name, card.cost])
	return true


func discard_hand_and_play_area() -> void:
	player.discard_pile.append_array(player.hand)
	player.discard_pile.append_array(player.play_area)
	player.hand.clear()
	player.play_area.clear()


func calculate_score() -> int:
	var score := 0
	for card in player.get_all_cards():
		score += card.victory_points
	print("[Game] Scoring: %d victory points" % score)
	return score
