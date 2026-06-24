class_name GameState
extends RefCounted

const STARTING_CARD_COUNTS := {
	"pebble_coin": 7,
	"homestead": 3,
}

const MARKET_SIZE := 6

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
	var previous_market_ids := get_market_card_ids()
	player.clear_all()
	print("[Game] Game start")

	for card_id in STARTING_CARD_COUNTS:
		if not card_catalog.has(card_id):
			push_error("Missing starting card definition: %s" % card_id)
			return false
		for _copy_index in range(STARTING_CARD_COUNTS[card_id]):
			player.draw_pile.append(card_catalog[card_id])

	player.draw_pile.shuffle()
	print("[Game] Shuffle starting deck (%d cards)" % player.draw_pile.size())

	if not _setup_random_market(previous_market_ids):
		return false

	return true


func get_market_card_ids() -> Array[String]:
	var card_ids: Array[String] = []
	for card in market:
		card_ids.append(card.id)
	return card_ids


func get_market_candidates() -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	for card_id in card_catalog:
		if STARTING_CARD_COUNTS.has(card_id):
			continue
		candidates.append(card_catalog[card_id])
	return candidates


func _setup_random_market(previous_market_ids: Array[String]) -> bool:
	var candidates := get_market_candidates()
	if candidates.size() < MARKET_SIZE:
		push_error(
			"Not enough non-starter cards for a market of %d cards." % MARKET_SIZE
		)
		return false

	candidates.shuffle()
	var selected: Array[CardDefinition] = []
	for index in range(MARKET_SIZE):
		selected.append(candidates[index])

	if _has_same_card_ids(selected, previous_market_ids):
		for candidate in candidates:
			if not previous_market_ids.has(candidate.id):
				selected[MARKET_SIZE - 1] = candidate
				break

	market.assign(selected)
	print("[Game] Market setup: %s" % ", ".join(get_market_card_ids()))
	return true


func _has_same_card_ids(cards: Array[CardDefinition], card_ids: Array[String]) -> bool:
	if cards.size() != card_ids.size():
		return false
	for card in cards:
		if not card_ids.has(card.id):
			return false
	return true


func reset_turn_resources() -> void:
	player.reset_turn_resources()


func draw_cards(amount: int) -> void:
	var drawn_count := 0
	for _draw_index in range(amount):
		if player.draw_pile.is_empty():
			if player.discard_pile.is_empty():
				print("[Game] Draw stopped: no cards available (%d/%d drawn)" % [drawn_count, amount])
				break
			player.draw_pile.append_array(player.discard_pile)
			player.discard_pile.clear()
			player.draw_pile.shuffle()
			print("[Game] Shuffle discard into draw pile (%d cards)" % player.draw_pile.size())

		var card: CardDefinition = player.draw_pile.pop_back()
		player.hand.append(card)
		drawn_count += 1
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
	print(
		"[Game] Buy card: %s for %d coins (discard: %d)"
		% [card.card_name, card.cost, player.discard_pile.size()]
	)
	return true


func discard_hand_and_play_area() -> void:
	var hand_count := player.hand.size()
	var play_count := player.play_area.size()
	player.discard_pile.append_array(player.hand)
	player.discard_pile.append_array(player.play_area)
	player.hand.clear()
	player.play_area.clear()
	print(
		"[Game] Cleanup: discarded %d hand and %d played cards (discard: %d)"
		% [hand_count, play_count, player.discard_pile.size()]
	)


func calculate_score() -> int:
	var score := 0
	for card in player.get_all_cards():
		score += card.victory_points
	print(
		"[Game] Scoring: %d victory points (draw: %d, hand: %d, play: %d, discard: %d)"
		% [
			score,
			player.draw_pile.size(),
			player.hand.size(),
			player.play_area.size(),
			player.discard_pile.size(),
		]
	)
	return score
