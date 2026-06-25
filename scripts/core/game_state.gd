class_name GameState
extends RefCounted

const STARTING_CARD_COUNTS := {
	"pebble_coin": 7,
	"homestead": 3,
}

# Target market makeup. The replacement set keeps two economy cards, a broad
# action row, and three scoring cards visible each game.
const MARKET_RESOURCE_COUNT := 2
const MARKET_ACTION_COUNT := 7
const MARKET_VICTORY_TOTAL := 3
const MARKET_HYBRID_VICTORY_MIN := 0
const MARKET_HYBRID_VICTORY_MAX := 0

# Total cards in a market (sum of the counts above).
const MARKET_SIZE := MARKET_RESOURCE_COUNT + MARKET_ACTION_COUNT + MARKET_VICTORY_TOTAL

var player := PlayerState.new()
var card_catalog: Dictionary = {}
var market: Array[CardDefinition] = []
var turn_flags: Dictionary = {}


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
		var card: CardDefinition = card_catalog[card_id]
		if card.market_enabled:
			candidates.append(card)
	return candidates


func _setup_random_market(previous_market_ids: Array[String]) -> bool:
	var pools := _categorize_candidates()

	# Pick how many of the victory cards are hybrids this game; the rest are plain.
	var hybrid_count := MARKET_HYBRID_VICTORY_MIN
	var hybrid_span := MARKET_HYBRID_VICTORY_MAX - MARKET_HYBRID_VICTORY_MIN
	if hybrid_span > 0:
		hybrid_count += randi() % (hybrid_span + 1)
	hybrid_count = mini(hybrid_count, pools["hybrid_victory"].size())
	var normal_victory_count := MARKET_VICTORY_TOTAL - hybrid_count

	var requirements := [
		["resource", MARKET_RESOURCE_COUNT],
		["action", MARKET_ACTION_COUNT],
		["normal_victory", normal_victory_count],
		["hybrid_victory", hybrid_count],
	]

	var selected: Array[CardDefinition] = []
	for requirement in requirements:
		var pool_key: String = requirement[0]
		var needed: int = requirement[1]
		var pool: Array = pools[pool_key]
		if pool.size() < needed:
			push_error(
				"Not enough '%s' cards for the market (need %d, have %d)."
				% [pool_key, needed, pool.size()]
			)
			return false

		pool.shuffle()
		for index in range(needed):
			selected.append(pool[index])

	if _has_same_card_ids(selected, previous_market_ids):
		_swap_one_card(selected, pools, previous_market_ids)

	market.assign(selected)
	print("[Game] Market setup: %s" % ", ".join(get_market_card_ids()))
	return true


func _card_category(card: CardDefinition) -> String:
	# Victory cards (plain or playable hybrids) are grouped apart from pure
	# economy and action cards so the market can balance scoring options.
	if card.card_type == "victory":
		return "normal_victory"
	if card.victory_points > 0:
		return "hybrid_victory"
	return card.card_type


func _categorize_candidates() -> Dictionary:
	var pools := {
		"resource": [],
		"action": [],
		"normal_victory": [],
		"hybrid_victory": [],
	}
	for card in get_market_candidates():
		var category := _card_category(card)
		if pools.has(category):
			pools[category].append(card)
	return pools


func _swap_one_card(
	selected: Array[CardDefinition],
	pools: Dictionary,
	previous_market_ids: Array[String]
) -> void:
	# Replace a single card with a same-category alternative so a fresh game shows
	# a different market while keeping the configured composition intact.
	for category in pools:
		var pool: Array = pools[category]
		for candidate in pool:
			if previous_market_ids.has(candidate.id):
				continue
			if _selection_has_id(selected, candidate.id):
				continue
			for index in range(selected.size()):
				if _card_category(selected[index]) == category:
					selected[index] = candidate
					return


func _selection_has_id(cards: Array[CardDefinition], card_id: String) -> bool:
	for card in cards:
		if card.id == card_id:
			return true
	return false


func _has_same_card_ids(cards: Array[CardDefinition], card_ids: Array[String]) -> bool:
	if cards.size() != card_ids.size():
		return false
	for card in cards:
		if not card_ids.has(card.id):
			return false
	return true


func reset_turn_resources() -> void:
	player.reset_turn_resources()
	turn_flags.clear()


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
	return _play_card_internal(card, true)


func _play_card_internal(card: CardDefinition, spend_action: bool) -> bool:
	if card == null or not card.is_playable():
		return false

	var hand_index := player.hand.find(card)
	if hand_index == -1:
		return false

	if card.card_type == "action" and spend_action:
		if player.actions <= 0:
			return false
		player.actions -= 1

	player.hand.remove_at(hand_index)
	player.play_area.append(card)
	_apply_card_output(card)
	print("[Game] Play card: %s" % card.card_name)
	return true


func _apply_card_output(card: CardDefinition) -> void:
	player.coins += card.coin_value + card.gain_coins
	player.actions += card.gain_actions
	player.buys += card.gain_buys

	if card.draw_cards > 0:
		draw_cards(card.draw_cards)

	if card.card_type == "resource":
		_apply_resource_bonus(card)

	for effect in card.special_effects:
		_resolve_special_effect(effect, card)


func _apply_resource_bonus(card: CardDefinition) -> void:
	if not turn_flags.has("resource_bonus"):
		return
	var bonus: Dictionary = turn_flags["resource_bonus"]
	if bool(bonus.get("used", false)):
		return
	if str(bonus.get("card_id", "")) != card.id:
		return
	player.coins += int(bonus.get("amount", 0))
	bonus["used"] = true
	turn_flags["resource_bonus"] = bonus


func _resolve_special_effect(effect: Dictionary, source_card: CardDefinition) -> void:
	var kind := str(effect.get("kind", ""))
	match kind:
		"reveal_resources_to_hand":
			_reveal_resources_to_hand(int(effect.get("amount", 1)))
		"gain_best":
			_gain_best_card(
				int(effect.get("max_cost", 99)),
				str(effect.get("destination", "discard")),
				str(effect.get("card_type", ""))
			)
		"gain_card":
			_gain_card_by_id(
				str(effect.get("card_id", "")),
				str(effect.get("destination", "discard"))
			)
		"topdeck_from_hand":
			_move_weakest_hand_card_to_deck(int(effect.get("amount", 1)))
		"cycle_victory_cards":
			_cycle_victory_cards()
		"discard_deck":
			player.discard_pile.append_array(player.draw_pile)
			player.draw_pile.clear()
		"trash_from_hand":
			_trash_weakest_from_hand(int(effect.get("amount", 1)))
		"trash_self":
			_trash_from_play(source_card)
		"topdeck_from_discard":
			_topdeck_best_from_discard()
		"draw_to_size":
			draw_cards(maxi(0, int(effect.get("amount", 0)) - player.hand.size()))
		"resource_bonus":
			turn_flags["resource_bonus"] = {
				"card_id": str(effect.get("card_id", "")),
				"amount": int(effect.get("amount", 0)),
				"used": false,
			}
		"upgrade_resource":
			_upgrade_resource(int(effect.get("cost_delta", 0)))
		"trash_named_for_coins":
			_trash_named_for_coins(
				str(effect.get("card_id", "")),
				int(effect.get("amount", 0))
			)
		"remodel":
			_remodel_hand_card(int(effect.get("cost_delta", 0)))
		"inspect_top":
			_inspect_top_cards(int(effect.get("amount", 1)))
		"inspect_top_one":
			_inspect_top_one()
		"salvage_resource":
			_salvage_revealed_resource(int(effect.get("amount", 2)))
		"replay_action":
			_replay_best_action()
		"vassal":
			_resolve_vassal()
		_:
			push_warning("Unknown card effect kind: %s" % kind)


func _take_top_card() -> CardDefinition:
	if player.draw_pile.is_empty() and not player.discard_pile.is_empty():
		player.draw_pile.append_array(player.discard_pile)
		player.discard_pile.clear()
		player.draw_pile.shuffle()
	if player.draw_pile.is_empty():
		return null
	return player.draw_pile.pop_back()


func _reveal_resources_to_hand(amount: int) -> void:
	var found := 0
	var revealed: Array[CardDefinition] = []
	while found < amount:
		var card := _take_top_card()
		if card == null:
			break
		if card.card_type == "resource":
			player.hand.append(card)
			found += 1
		else:
			revealed.append(card)
	player.discard_pile.append_array(revealed)


func _gain_best_card(max_cost: int, destination: String, card_type: String = "") -> void:
	var best: CardDefinition = null
	for candidate in card_catalog.values():
		if not candidate.market_enabled or candidate.cost > max_cost:
			continue
		if not card_type.is_empty() and candidate.card_type != card_type:
			continue
		if best == null or _card_utility(candidate) > _card_utility(best):
			best = candidate
	if best != null:
		_add_gained_card(best, destination)


func _gain_card_by_id(card_id: String, destination: String) -> void:
	if card_catalog.has(card_id):
		_add_gained_card(card_catalog[card_id], destination)


func _add_gained_card(card: CardDefinition, destination: String) -> void:
	match destination:
		"hand":
			player.hand.append(card)
		"deck":
			player.draw_pile.append(card)
		_:
			player.discard_pile.append(card)


func _move_weakest_hand_card_to_deck(amount: int) -> void:
	for _index in range(amount):
		var card := _find_weakest_card(player.hand)
		if card == null:
			return
		player.hand.erase(card)
		player.draw_pile.append(card)


func _cycle_victory_cards() -> void:
	var discarded: Array[CardDefinition] = []
	for card in player.hand.duplicate():
		if card.card_type == "victory":
			player.hand.erase(card)
			discarded.append(card)
	player.discard_pile.append_array(discarded)
	draw_cards(discarded.size())


func _trash_weakest_from_hand(amount: int) -> void:
	for _index in range(amount):
		var card := _find_weakest_card(player.hand)
		if card == null:
			return
		player.hand.erase(card)
		player.trash_pile.append(card)


func _trash_from_play(card: CardDefinition) -> void:
	if not player.play_area.has(card):
		return
	player.play_area.erase(card)
	player.trash_pile.append(card)


func _topdeck_best_from_discard() -> void:
	var card := _find_best_card(player.discard_pile)
	if card == null:
		return
	player.discard_pile.erase(card)
	player.draw_pile.append(card)


func _upgrade_resource(cost_delta: int) -> void:
	var resources: Array[CardDefinition] = []
	for card in player.hand:
		if card.card_type == "resource":
			resources.append(card)
	var trashed := _find_weakest_card(resources)
	if trashed == null:
		return
	player.hand.erase(trashed)
	player.trash_pile.append(trashed)
	_gain_best_card(trashed.cost + cost_delta, "hand", "resource")


func _trash_named_for_coins(card_id: String, amount: int) -> void:
	for card in player.hand:
		if card.id == card_id:
			player.hand.erase(card)
			player.trash_pile.append(card)
			player.coins += amount
			return


func _remodel_hand_card(cost_delta: int) -> void:
	var trashed := _find_weakest_card(player.hand)
	if trashed == null:
		return
	player.hand.erase(trashed)
	player.trash_pile.append(trashed)
	_gain_best_card(trashed.cost + cost_delta, "discard")


func _inspect_top_cards(amount: int) -> void:
	var kept: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card == null:
			break
		if card.card_type == "victory":
			player.discard_pile.append(card)
		else:
			kept.append(card)
	for card in kept:
		player.draw_pile.append(card)


func _inspect_top_one() -> void:
	var card := _take_top_card()
	if card == null:
		return
	if card.card_type == "victory":
		player.discard_pile.append(card)
	else:
		player.draw_pile.append(card)


func _salvage_revealed_resource(amount: int) -> void:
	var revealed: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card != null:
			revealed.append(card)
	var resource: CardDefinition = null
	for card in revealed:
		if card.card_type != "resource":
			continue
		if resource == null or card.coin_value > resource.coin_value:
			resource = card
	if resource != null:
		revealed.erase(resource)
		player.trash_pile.append(resource)
		player.coins += resource.coin_value
	player.discard_pile.append_array(revealed)


func _replay_best_action() -> void:
	var actions: Array[CardDefinition] = []
	for card in player.hand:
		if card.card_type == "action":
			actions.append(card)
	var target := _find_best_card(actions)
	if target == null or not _play_card_internal(target, false):
		return
	_apply_card_output(target)


func _resolve_vassal() -> void:
	var card := _take_top_card()
	if card == null:
		return
	if card.card_type == "action":
		player.hand.append(card)
		_play_card_internal(card, false)
	else:
		player.discard_pile.append(card)


func _find_weakest_card(cards: Array[CardDefinition]) -> CardDefinition:
	var weakest: CardDefinition = null
	for card in cards:
		if weakest == null or _card_utility(card) < _card_utility(weakest):
			weakest = card
	return weakest


func _find_best_card(cards: Array[CardDefinition]) -> CardDefinition:
	var best: CardDefinition = null
	for card in cards:
		if best == null or _card_utility(card) > _card_utility(best):
			best = card
	return best


func _card_utility(card: CardDefinition) -> int:
	return (
		card.cost * 10
		+ card.victory_points * 4
		+ card.coin_value * 3
		+ card.draw_cards * 2
		+ card.gain_actions
		+ card.gain_buys
		+ card.gain_coins * 3
	)


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
	var owned_cards := player.get_all_cards()
	for card in owned_cards:
		score += card.victory_points
		if card.score_per_cards > 0:
			score += owned_cards.size() / card.score_per_cards
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
