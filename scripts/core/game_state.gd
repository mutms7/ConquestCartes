class_name GameState
extends RefCounted

signal choice_requested(choice: CardChoice)
signal choice_resolved(choice_id: int)

const STARTING_CARD_COUNTS := {
	"pebble_coin": 7,
	"homestead": 3,
}

const MARKET_RESOURCE_COUNT := 2
const MARKET_ACTION_COUNT := 10
const MARKET_VICTORY_TOTAL := 2
const MARKET_HYBRID_VICTORY_MIN := 0
const MARKET_HYBRID_VICTORY_MAX := 0
const MARKET_SIZE := MARKET_RESOURCE_COUNT + MARKET_ACTION_COUNT + MARKET_VICTORY_TOTAL

const ACTION_SUPPLY_COUNT := 10
const RESOURCE_SUPPLY_COUNT := 12
const VICTORY_SUPPLY_COUNT := 8

var player := PlayerState.new()
var card_catalog: Dictionary = {}
var market: Array[CardDefinition] = []
var supply_piles: Dictionary = {}
var turn_flags: Dictionary = {}
var pending_choice: CardChoice
var resolution_queue: Array[Dictionary] = []
var next_choice_id: int = 1


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
	turn_flags.clear()
	resolution_queue.clear()
	pending_choice = null
	print("[Game] Game start")

	for card_id in STARTING_CARD_COUNTS:
		if not card_catalog.has(card_id):
			push_error("Missing starting card definition: %s" % card_id)
			return false
		for _copy_index in range(STARTING_CARD_COUNTS[card_id]):
			player.draw_pile.append(card_catalog[card_id])

	player.draw_pile.shuffle()
	print("[Game] Shuffle starting deck (%d cards)" % player.draw_pile.size())
	return _setup_random_market(previous_market_ids)


func has_pending_choice() -> bool:
	return pending_choice != null


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


func get_supply_count(card_id: String) -> int:
	return int(supply_piles.get(card_id, 0))


func set_supply_count(card_id: String, amount: int) -> void:
	if supply_piles.has(card_id):
		supply_piles[card_id] = maxi(0, amount)


func get_empty_supply_pile_count() -> int:
	var empty_count := 0
	for card in market:
		if get_supply_count(card.id) <= 0:
			empty_count += 1
	return empty_count


func get_gain_candidates(max_cost: int, card_type: String = "") -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	for card in market:
		if get_supply_count(card.id) <= 0 or card.cost > max_cost:
			continue
		if not card_type.is_empty() and card.card_type != card_type:
			continue
		candidates.append(card)
	return candidates


func _setup_random_market(previous_market_ids: Array[String]) -> bool:
	var pools := _categorize_candidates()
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
	_initialize_supply_piles()
	print("[Game] Market setup: %s" % ", ".join(get_market_card_ids()))
	return true


func _initialize_supply_piles() -> void:
	supply_piles.clear()
	for card in market:
		match card.card_type:
			"victory":
				supply_piles[card.id] = VICTORY_SUPPLY_COUNT
			"resource":
				supply_piles[card.id] = RESOURCE_SUPPLY_COUNT
			_:
				supply_piles[card.id] = ACTION_SUPPLY_COUNT


func _card_category(card: CardDefinition) -> String:
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
	for category in pools:
		var pool: Array = pools[category]
		for candidate in pool:
			if previous_market_ids.has(candidate.id) or _selection_has_id(selected, candidate.id):
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


func draw_cards(amount: int) -> int:
	var drawn_count := 0
	for _draw_index in range(amount):
		var card := _take_top_card()
		if card == null:
			print("[Game] Draw stopped: no cards available (%d/%d drawn)" % [drawn_count, amount])
			break
		player.hand.append(card)
		drawn_count += 1
		print("[Game] Draw: %s" % card.card_name)
	return drawn_count


func play_card(card: CardDefinition) -> bool:
	return _play_card_internal(card, true, 1)


func _play_card_internal(
	card: CardDefinition,
	spend_action: bool,
	repetitions: int
) -> bool:
	if card == null or not card.is_playable() or has_pending_choice():
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
	_prepend_card_resolutions(card, repetitions)
	_process_resolution_queue()
	print("[Game] Play card: %s" % card.card_name)
	return true


func _prepend_card_resolutions(card: CardDefinition, repetitions: int) -> void:
	var sequence: Array[Dictionary] = []
	for _repeat_index in range(repetitions):
		sequence.append({"kind": "card_base", "card": card})
		for effect in card.special_effects:
			sequence.append({
				"kind": "special",
				"effect": effect.duplicate(true),
				"source_card": card,
			})
	for index in range(sequence.size() - 1, -1, -1):
		resolution_queue.push_front(sequence[index])


func _process_resolution_queue() -> void:
	while not has_pending_choice() and not resolution_queue.is_empty():
		var entry: Dictionary = resolution_queue.pop_front()
		match str(entry.get("kind", "")):
			"card_base":
				_apply_card_base(entry["card"])
			"special":
				_resolve_special_effect(entry["effect"], entry["source_card"])


func _apply_card_base(card: CardDefinition) -> void:
	player.coins += card.coin_value + card.gain_coins
	player.actions += card.gain_actions
	player.buys += card.gain_buys
	if card.draw_cards > 0:
		draw_cards(card.draw_cards)
	if card.card_type == "resource":
		_apply_resource_bonus(card)


func _apply_resource_bonus(card: CardDefinition) -> void:
	if not turn_flags.has("resource_bonus"):
		return
	var bonus: Dictionary = turn_flags["resource_bonus"]
	if bool(bonus.get("used", false)) or str(bonus.get("card_id", "")) != card.id:
		return
	player.coins += int(bonus.get("amount", 0))
	bonus["used"] = true
	turn_flags["resource_bonus"] = bonus


func _resolve_special_effect(effect: Dictionary, source_card: CardDefinition) -> void:
	var kind := str(effect.get("kind", ""))
	match kind:
		"reveal_resources_to_hand":
			_reveal_resources_to_hand(int(effect.get("amount", 1)))
		"gain_from_supply":
			_request_supply_choice(
				int(effect.get("max_cost", 99)),
				str(effect.get("destination", "discard")),
				str(effect.get("card_type", "")),
				str(effect.get("prompt", "Choose a card to gain."))
			)
		"gain_card":
			_gain_card_by_id(
				str(effect.get("card_id", "")),
				str(effect.get("destination", "discard"))
			)
		"topdeck_from_hand":
			_request_zone_choice(
				player.hand,
				"Choose a card from your hand to put on top of your deck.",
				mini(int(effect.get("amount", 1)), player.hand.size()),
				mini(int(effect.get("amount", 1)), player.hand.size()),
				"topdeck_hand",
				"PUT ON DECK"
			)
		"discard_from_hand_draw":
			_request_zone_choice(
				player.hand,
				"Choose any number of cards to discard, then draw that many cards.",
				0,
				player.hand.size(),
				"discard_hand_draw",
				"DISCARD & DRAW"
			)
		"discard_deck":
			player.discard_pile.append_array(player.draw_pile)
			player.draw_pile.clear()
		"trash_from_hand":
			_request_zone_choice(
				player.hand,
				"Choose up to %d cards from your hand to trash."
				% int(effect.get("amount", 1)),
				0,
				mini(int(effect.get("amount", 1)), player.hand.size()),
				"trash_hand",
				"TRASH"
			)
		"trash_self":
			_trash_from_play(source_card)
		"topdeck_from_discard":
			_request_zone_choice(
				player.discard_pile,
				"Choose a card from your discard pile to put on top of your deck.",
				0,
				mini(1, player.discard_pile.size()),
				"topdeck_discard",
				"PUT ON DECK",
				"LEAVE IT"
			)
		"draw_to_size":
			_continue_library_draw(int(effect.get("amount", 7)), [])
		"resource_bonus":
			turn_flags["resource_bonus"] = {
				"card_id": str(effect.get("card_id", "")),
				"amount": int(effect.get("amount", 0)),
				"used": false,
			}
		"upgrade_resource":
			var resources: Array[CardDefinition] = []
			for card in player.hand:
				if card.card_type == "resource":
					resources.append(card)
			_request_zone_choice(
				resources,
				"Choose a resource from your hand to trash.",
				0,
				mini(1, resources.size()),
				"upgrade_resource",
				"TRASH & UPGRADE",
				"SKIP",
				{"cost_delta": int(effect.get("cost_delta", 0))}
			)
		"trash_named_for_coins":
			var matching: Array[CardDefinition] = []
			var card_id := str(effect.get("card_id", ""))
			for card in player.hand:
				if card.id == card_id:
					matching.append(card)
			_request_zone_choice(
				matching,
				"Trash a %s from your hand to gain %d coins."
				% [
					card_catalog[card_id].card_name if card_catalog.has(card_id) else "card",
					int(effect.get("amount", 0)),
				],
				0,
				mini(1, matching.size()),
				"trash_named_coins",
				"TRASH",
				"SKIP",
				{"amount": int(effect.get("amount", 0))}
			)
		"remodel":
			_request_zone_choice(
				player.hand,
				"Choose a card from your hand to trash.",
				mini(1, player.hand.size()),
				mini(1, player.hand.size()),
				"remodel",
				"TRASH",
				"SKIP",
				{"cost_delta": int(effect.get("cost_delta", 0))}
			)
		"inspect_top":
			_begin_inspect_top(int(effect.get("amount", 2)))
		"inspect_top_one":
			_begin_inspect_one()
		"salvage_resource":
			_begin_salvage(int(effect.get("amount", 2)))
		"replay_action":
			var actions: Array[CardDefinition] = []
			for card in player.hand:
				if card.card_type == "action":
					actions.append(card)
			_request_zone_choice(
				actions,
				"Choose an action card from your hand to play twice.",
				0,
				mini(1, actions.size()),
				"replay_action",
				"PLAY TWICE",
				"SKIP"
			)
		"vassal":
			_begin_vassal()
		"discard_per_empty_supply":
			var discard_count := mini(get_empty_supply_pile_count(), player.hand.size())
			_request_zone_choice(
				player.hand,
				"Choose %d card%s to discard for the empty supply piles."
				% [discard_count, "" if discard_count == 1 else "s"],
				discard_count,
				discard_count,
				"discard_hand",
				"DISCARD"
			)
		_:
			push_warning("Unknown card effect kind: %s" % kind)


func resolve_choice(tokens: Array[String]) -> bool:
	if pending_choice == null or not pending_choice.is_valid_selection(tokens):
		return false
	var choice := pending_choice
	var selected := choice.get_selected_entries(tokens)
	pending_choice = null
	_apply_choice_resolution(choice, selected)
	choice_resolved.emit(choice.id)
	_process_resolution_queue()
	return true


func _apply_choice_resolution(
	choice: CardChoice,
	selected: Array[Dictionary]
) -> void:
	var cards := _cards_from_entries(selected)
	match choice.resolver:
		"gain_supply":
			if not cards.is_empty():
				_gain_from_supply(cards[0], str(choice.context.get("destination", "discard")))
		"topdeck_hand":
			_move_cards(player.hand, player.draw_pile, cards)
		"discard_hand_draw":
			_move_cards(player.hand, player.discard_pile, cards)
			draw_cards(cards.size())
		"discard_hand":
			_move_cards(player.hand, player.discard_pile, cards)
		"trash_hand":
			_move_cards(player.hand, player.trash_pile, cards)
		"topdeck_discard":
			_move_cards(player.discard_pile, player.draw_pile, cards)
		"upgrade_resource":
			if cards.is_empty():
				return
			var trashed := cards[0]
			_move_cards(player.hand, player.trash_pile, [trashed])
			_request_supply_choice(
				trashed.cost + int(choice.context.get("cost_delta", 0)),
				"hand",
				"resource",
				"Choose a replacement resource to gain to your hand."
			)
		"trash_named_coins":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.trash_pile, cards)
			player.coins += int(choice.context.get("amount", 0))
		"remodel":
			if cards.is_empty():
				return
			var trashed := cards[0]
			_move_cards(player.hand, player.trash_pile, [trashed])
			_request_supply_choice(
				trashed.cost + int(choice.context.get("cost_delta", 0)),
				"discard",
				"",
				"Choose a card to gain."
			)
		"inspect_trash":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			for card in cards:
				revealed.erase(card)
			player.trash_pile.append_array(cards)
			_request_inspect_discard(revealed)
		"inspect_discard":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			for card in cards:
				revealed.erase(card)
			player.discard_pile.append_array(cards)
			_finish_inspect_order(revealed)
		"inspect_order":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			var top_card: CardDefinition = cards[0] if not cards.is_empty() else null
			if top_card != null:
				revealed.erase(top_card)
			for card in revealed:
				player.draw_pile.append(card)
			if top_card != null:
				player.draw_pile.append(top_card)
		"inspect_one":
			var card: CardDefinition = choice.context.get("card")
			if cards.is_empty():
				player.draw_pile.append(card)
			else:
				player.discard_pile.append(card)
		"salvage_resource":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			if not cards.is_empty():
				var resource := cards[0]
				revealed.erase(resource)
				player.trash_pile.append(resource)
				player.coins += resource.coin_value
			player.discard_pile.append_array(revealed)
		"replay_action":
			if cards.is_empty():
				return
			var action := cards[0]
			player.hand.erase(action)
			player.play_area.append(action)
			_prepend_card_resolutions(action, 2)
		"vassal_play":
			var card: CardDefinition = choice.context.get("card")
			if cards.is_empty():
				player.discard_pile.append(card)
			else:
				player.play_area.append(card)
				_prepend_card_resolutions(card, 1)
		"library_action":
			var card: CardDefinition = choice.context.get("card")
			var set_aside: Array[CardDefinition] = choice.context.get("set_aside", [])
			if cards.is_empty():
				player.hand.append(card)
			else:
				set_aside.append(card)
			_continue_library_draw(int(choice.context.get("target", 7)), set_aside)


func _new_choice(
	prompt: String,
	minimum: int,
	maximum: int,
	resolver: String,
	confirm_text: String = "CONFIRM",
	skip_text: String = "SKIP",
	context: Dictionary = {}
) -> CardChoice:
	var choice := CardChoice.new()
	choice.id = next_choice_id
	next_choice_id += 1
	choice.prompt = prompt
	choice.minimum = minimum
	choice.maximum = maximum
	choice.resolver = resolver
	choice.confirm_text = confirm_text
	choice.skip_text = skip_text
	choice.context = context
	return choice


func _request_choice(choice: CardChoice) -> void:
	if choice.candidates.is_empty():
		return
	pending_choice = choice
	choice_requested.emit(choice)


func _request_zone_choice(
	cards: Array[CardDefinition],
	prompt: String,
	minimum: int,
	maximum: int,
	resolver: String,
	confirm_text: String = "CONFIRM",
	skip_text: String = "SKIP",
	context: Dictionary = {}
) -> void:
	if cards.is_empty() or maximum <= 0:
		return
	var choice := _new_choice(
		prompt,
		mini(minimum, cards.size()),
		mini(maximum, cards.size()),
		resolver,
		confirm_text,
		skip_text,
		context
	)
	for index in range(cards.size()):
		choice.add_candidate("zone:%d:%d" % [choice.id, index], cards[index])
	_request_choice(choice)


func _request_supply_choice(
	max_cost: int,
	destination: String,
	card_type: String,
	prompt: String
) -> void:
	var candidates := get_gain_candidates(max_cost, card_type)
	if candidates.is_empty():
		return
	var choice := _new_choice(
		prompt,
		1,
		1,
		"gain_supply",
		"GAIN",
		"SKIP",
		{"destination": destination}
	)
	for card in candidates:
		choice.add_candidate(
			"supply:%s" % card.id,
			card,
			"Cost %d  •  %d left" % [card.cost, get_supply_count(card.id)]
		)
	_request_choice(choice)


func _cards_from_entries(entries: Array[Dictionary]) -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	for entry in entries:
		cards.append(entry["card"])
	return cards


func _move_cards(
	source: Array[CardDefinition],
	destination: Array[CardDefinition],
	cards: Array[CardDefinition]
) -> void:
	for card in cards:
		source.erase(card)
		destination.append(card)


func _take_top_card() -> CardDefinition:
	if player.draw_pile.is_empty() and not player.discard_pile.is_empty():
		player.draw_pile.append_array(player.discard_pile)
		player.discard_pile.clear()
		player.draw_pile.shuffle()
		print("[Game] Shuffle discard into draw pile (%d cards)" % player.draw_pile.size())
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


func _gain_card_by_id(card_id: String, destination: String) -> void:
	if not card_catalog.has(card_id):
		return
	var card: CardDefinition = card_catalog[card_id]
	if get_supply_count(card_id) <= 0:
		return
	_gain_from_supply(card, destination)


func _gain_from_supply(card: CardDefinition, destination: String) -> bool:
	if not supply_piles.has(card.id) or get_supply_count(card.id) <= 0:
		return false
	supply_piles[card.id] = get_supply_count(card.id) - 1
	match destination:
		"hand":
			player.hand.append(card)
		"deck":
			player.draw_pile.append(card)
		_:
			player.discard_pile.append(card)
	return true


func _trash_from_play(card: CardDefinition) -> void:
	if player.play_area.has(card):
		player.play_area.erase(card)
		player.trash_pile.append(card)


func _continue_library_draw(
	target_size: int,
	set_aside: Array[CardDefinition]
) -> void:
	while player.hand.size() < target_size:
		var card := _take_top_card()
		if card == null:
			player.discard_pile.append_array(set_aside)
			return
		if card.card_type != "action":
			player.hand.append(card)
			continue
		var choice := _new_choice(
			"Set this action card aside, or keep it in your hand?",
			0,
			1,
			"library_action",
			"SET ASIDE",
			"KEEP",
			{
				"card": card,
				"target": target_size,
				"set_aside": set_aside,
			}
		)
		choice.add_candidate("library:%d" % choice.id, card)
		_request_choice(choice)
		return
	player.discard_pile.append_array(set_aside)


func _begin_inspect_top(amount: int) -> void:
	var revealed: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card != null:
			revealed.append(card)
	if revealed.is_empty():
		return
	_request_zone_choice(
		revealed,
		"Choose any revealed cards to trash.",
		0,
		revealed.size(),
		"inspect_trash",
		"TRASH SELECTED",
		"TRASH NONE",
		{"revealed": revealed}
	)


func _request_inspect_discard(revealed: Array[CardDefinition]) -> void:
	if revealed.is_empty():
		return
	_request_zone_choice(
		revealed,
		"Choose any remaining revealed cards to discard.",
		0,
		revealed.size(),
		"inspect_discard",
		"DISCARD SELECTED",
		"DISCARD NONE",
		{"revealed": revealed}
	)


func _finish_inspect_order(revealed: Array[CardDefinition]) -> void:
	if revealed.size() <= 1:
		player.draw_pile.append_array(revealed)
		return
	_request_zone_choice(
		revealed,
		"Choose which card should be on top of your deck.",
		1,
		1,
		"inspect_order",
		"PUT ON TOP",
		"SKIP",
		{"revealed": revealed}
	)


func _begin_inspect_one() -> void:
	var card := _take_top_card()
	if card == null:
		return
	_request_zone_choice(
		[card],
		"Discard this revealed card, or leave it on top of your deck?",
		0,
		1,
		"inspect_one",
		"DISCARD",
		"KEEP ON TOP",
		{"card": card}
	)


func _begin_salvage(amount: int) -> void:
	var revealed: Array[CardDefinition] = []
	var resources: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card == null:
			continue
		revealed.append(card)
		if card.card_type == "resource":
			resources.append(card)
	if revealed.is_empty():
		return
	if resources.is_empty():
		player.discard_pile.append_array(revealed)
		return
	_request_zone_choice(
		resources,
		"Choose a revealed resource to salvage for its coin value.",
		0,
		1,
		"salvage_resource",
		"SALVAGE",
		"DISCARD ALL",
		{"revealed": revealed}
	)


func _begin_vassal() -> void:
	var card := _take_top_card()
	if card == null:
		return
	if card.card_type != "action":
		player.discard_pile.append(card)
		return
	_request_zone_choice(
		[card],
		"Play this revealed action card without spending an action?",
		0,
		1,
		"vassal_play",
		"PLAY",
		"DISCARD",
		{"card": card}
	)


func buy_card(card: CardDefinition) -> bool:
	if (
		card == null
		or has_pending_choice()
		or not market.has(card)
		or get_supply_count(card.id) <= 0
	):
		return false
	if player.buys <= 0 or player.coins < card.cost:
		return false
	player.coins -= card.cost
	player.buys -= 1
	_gain_from_supply(card, "discard")
	print(
		"[Game] Buy card: %s for %d coins (%d left)"
		% [card.card_name, card.cost, get_supply_count(card.id)]
	)
	return true


func discard_hand_and_play_area() -> void:
	var hand_count := player.hand.size()
	var play_count := player.play_area.size()
	player.discard_pile.append_array(player.hand)
	player.discard_pile.append_array(player.play_area)
	player.hand.clear()
	player.play_area.clear()
	resolution_queue.clear()
	pending_choice = null
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
