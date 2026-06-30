class_name GameState
extends RefCounted

signal choice_requested(choice: CardChoice)
signal choice_resolved(choice_id: int)
signal cleanup_completed
signal active_player_changed(player_index: int)
signal end_turn_cooldown_reduced(amount: float)

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
# The market's two resource slots and two victory slots are always these cards.
# Every other treasure and victory card is folded into the action pool.
const MARKET_FIXED_RESOURCE_IDS := ["silver_leaf", "amber_circlet"]
const MARKET_FIXED_VICTORY_IDS := ["briar_gate", "royal_charter"]
const BASE_KINGDOM := "Base Kingdom"
const BEGINNER_KINGDOM := "First Harvest"
const HINTERLANDS_GROUP := "Hinterlands"
const KINGDOM_ORDER := [BASE_KINGDOM, BEGINNER_KINGDOM, HINTERLANDS_GROUP]
const REQUIRED_CARD_IDS := [
	"pebble_coin",
	"silver_leaf",
	"amber_circlet",
	"homestead",
	"briar_gate",
	"royal_charter",
	"briar_hex",
]

const ACTION_SUPPLY_COUNT := 10
const RESOURCE_SUPPLY_COUNT := 12
const VICTORY_SUPPLY_COUNT := 8
const CURSE_SUPPLY_COUNT := 10
const CURSE_CARD_ID := "briar_hex"
const SIX_VP_CARD_ID := "royal_charter"
const SUPPLY_EMPTY_END_COUNT := 3
const DEFAULT_END_TURN_COOLDOWN_SECONDS := 5.0

var player := PlayerState.new()
var players: Array[PlayerState] = []
var active_player_index: int = 0
var multiplayer_enabled: bool = false
var card_catalog: Dictionary = {}
var market: Array[CardDefinition] = []
var supply_piles: Dictionary = {}
var turn_flags: Dictionary = {}
var pending_choice: CardChoice
var resolution_queue: Array[Dictionary] = []
var next_choice_id: int = 1
var cleanup_in_progress: bool = false
var disabled_kingdoms: Dictionary = {}
var disabled_market_card_ids: Dictionary = {}
var end_turn_cooldown_seconds: float = DEFAULT_END_TURN_COOLDOWN_SECONDS
var attack_cards_enabled: bool = true
# Turn-based mode: a sequential, no-timer variation. Players take turns one at a
# time (you wait for the active player to finish before your turn begins) and
# there is no end-turn cooldown timer at all.
var turn_based_enabled: bool = false


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


func setup_starting_game(player_count: int = 1) -> bool:
	var previous_market_ids := get_market_card_ids()
	_create_players(maxi(1, player_count))
	turn_flags.clear()
	resolution_queue.clear()
	pending_choice = null
	cleanup_in_progress = false
	active_player_index = 0
	_set_active_player(0, false)
	print("[Game] Game start")

	for game_player in players:
		for card_id in STARTING_CARD_COUNTS:
			if not card_catalog.has(card_id):
				push_error("Missing starting card definition: %s" % card_id)
				return false
			for _copy_index in range(STARTING_CARD_COUNTS[card_id]):
				game_player.draw_pile.append(card_catalog[card_id])
		game_player.draw_pile.shuffle()
		print(
			"[Game] Shuffle starting deck for %s (%d cards)"
			% [game_player.player_name, game_player.draw_pile.size()]
		)

	return _setup_random_market(previous_market_ids)


func _create_players(player_count: int) -> void:
	players.clear()
	for index in range(player_count):
		var game_player := PlayerState.new()
		game_player.player_name = "Player %d" % (index + 1)
		game_player.clear_all()
		players.append(game_player)
	multiplayer_enabled = player_count > 1
	player = players[0]


func set_active_player_index(player_index: int) -> void:
	_set_active_player(player_index, true)


func advance_active_player() -> void:
	if players.size() <= 1:
		_set_active_player(0, false)
		return
	_set_active_player((active_player_index + 1) % players.size(), true)


func _set_active_player(player_index: int, emit_signal: bool) -> void:
	if players.is_empty():
		players.append(player)
	player.pending_choice = pending_choice
	player.resolution_queue = resolution_queue
	player.cleanup_in_progress = cleanup_in_progress
	active_player_index = clampi(player_index, 0, players.size() - 1)
	player = players[active_player_index]
	turn_flags = player.turn_flags
	pending_choice = player.pending_choice
	resolution_queue = player.resolution_queue
	cleanup_in_progress = player.cleanup_in_progress
	if emit_signal:
		active_player_changed.emit(active_player_index)


func get_active_player_name() -> String:
	return player.player_name


func get_player_count() -> int:
	return players.size()


func start_all_players() -> void:
	var starting_index := active_player_index
	for index in range(players.size()):
		var game_player := players[index]
		game_player.reset_turn_resources()
		if game_player.hand.is_empty():
			_set_active_player(index, false)
			draw_cards(5)
	_set_active_player(starting_index, false)


func get_end_turn_cooldown_seconds() -> float:
	# The end-turn cooldown is a multiplayer-only pacing mechanic. Singleplayer
	# games have no timeout, so ending a turn is instant. Turn-based games also
	# have no timer: play simply passes to the next player when you finish.
	if not multiplayer_enabled or turn_based_enabled:
		return 0.0
	return maxf(
		0.5,
		end_turn_cooldown_seconds - player.end_turn_cooldown_reduction
	)


func reduce_end_turn_cooldown(amount: float) -> void:
	var reduction := maxf(0.0, amount)
	if reduction <= 0.0:
		return
	player.end_turn_cooldown_reduction += reduction
	end_turn_cooldown_reduced.emit(reduction)


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
		if not card.market_enabled:
			continue
		if not is_kingdom_enabled(get_card_kingdom(card)):
			continue
		if not is_card_enabled_for_market(card.id):
			continue
		if not attack_cards_enabled and card_has_attack_effect(card):
			continue
		candidates.append(card)
	return candidates


func card_has_attack_effect(card: CardDefinition) -> bool:
	if card == null:
		return false
	for effect in card.special_effects:
		if _effect_contains_attack(effect):
			return true
	return false


func _effect_contains_attack(value: Variant) -> bool:
	match typeof(value):
		TYPE_DICTIONARY:
			var data: Dictionary = value
			var kind := str(data.get("kind", ""))
			if kind == "attack" or kind == "register_gain_attack":
				return true
			if data.has("attack") and typeof(data["attack"]) == TYPE_DICTIONARY:
				return true
			for nested_value in data.values():
				if _effect_contains_attack(nested_value):
					return true
		TYPE_ARRAY:
			for nested_value in value:
				if _effect_contains_attack(nested_value):
					return true
	return false


func get_card_kingdom(card: CardDefinition) -> String:
	if card == null:
		return BEGINNER_KINGDOM
	if REQUIRED_CARD_IDS.has(card.id):
		return BASE_KINGDOM
	if card.card_group == HINTERLANDS_GROUP:
		return HINTERLANDS_GROUP
	return BEGINNER_KINGDOM


func get_cards_for_kingdom(kingdom: String) -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	for card in card_catalog.values():
		if get_card_kingdom(card) == kingdom:
			cards.append(card)
	cards.sort_custom(_is_catalog_card_before)
	return cards


func is_required_card(card_id: String) -> bool:
	return REQUIRED_CARD_IDS.has(card_id)


func is_kingdom_enabled(kingdom: String) -> bool:
	return kingdom == BASE_KINGDOM or not bool(disabled_kingdoms.get(kingdom, false))


func set_kingdom_enabled(kingdom: String, enabled: bool) -> void:
	if kingdom == BASE_KINGDOM:
		return
	if enabled:
		disabled_kingdoms.erase(kingdom)
	else:
		disabled_kingdoms[kingdom] = true


func is_card_enabled_for_market(card_id: String) -> bool:
	return is_required_card(card_id) or not bool(disabled_market_card_ids.get(card_id, false))


func set_card_enabled_for_market(card_id: String, enabled: bool) -> void:
	if is_required_card(card_id):
		return
	if enabled:
		disabled_market_card_ids.erase(card_id)
	else:
		disabled_market_card_ids[card_id] = true


func has_enough_market_candidates() -> bool:
	var pools := _categorize_candidates()
	var hybrid_count := MARKET_HYBRID_VICTORY_MIN
	hybrid_count = mini(hybrid_count, pools["hybrid_victory"].size())
	var normal_victory_count := MARKET_VICTORY_TOTAL - hybrid_count
	return (
		pools["resource"].size() >= MARKET_RESOURCE_COUNT
		and pools["action"].size() >= MARKET_ACTION_COUNT
		and pools["normal_victory"].size() >= normal_victory_count
		and pools["hybrid_victory"].size() >= hybrid_count
	)


func get_supply_count(card_id: String) -> int:
	return int(supply_piles.get(card_id, 0))


func set_supply_count(card_id: String, amount: int) -> void:
	if supply_piles.has(card_id):
		supply_piles[card_id] = maxi(0, amount)


func get_empty_supply_pile_count() -> int:
	var empty_count := 0
	for card_id in supply_piles:
		if int(supply_piles[card_id]) <= 0:
			empty_count += 1
	return empty_count


func is_game_end_condition_met() -> bool:
	return (
		get_empty_supply_pile_count() >= SUPPLY_EMPTY_END_COUNT
		or get_supply_count(SIX_VP_CARD_ID) <= 0
	)


func get_gain_candidates(max_cost: int, card_type: String = "") -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	for card in market:
		if get_supply_count(card.id) <= 0 or get_effective_cost(card) > max_cost:
			continue
		if not card_type.is_empty() and card.card_type != card_type:
			continue
		candidates.append(card)
	return candidates


func get_effective_cost(card: CardDefinition) -> int:
	if card == null:
		return 0
	return maxi(0, card.cost - int(turn_flags.get("cost_reduction", 0)))


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
	if card_catalog.has(CURSE_CARD_ID):
		supply_piles[CURSE_CARD_ID] = CURSE_SUPPLY_COUNT


func _card_category(card: CardDefinition) -> String:
	if MARKET_FIXED_RESOURCE_IDS.has(card.id):
		return "resource"
	if MARKET_FIXED_VICTORY_IDS.has(card.id):
		return "normal_victory"
	# Every other card (actions plus all other treasures and victory cards)
	# competes for the action slots.
	return "action"


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


func _is_catalog_card_before(first: CardDefinition, second: CardDefinition) -> bool:
	if first.card_type != second.card_type:
		return first.card_type.naturalnocasecmp_to(second.card_type) < 0
	if first.cost != second.cost:
		return first.cost < second.cost
	return first.card_name.naturalnocasecmp_to(second.card_name) < 0


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
			if str(effect.get("trigger", "play")) != "play":
				continue
			sequence.append({
				"kind": "special",
				"effect": effect.duplicate(true),
				"source_card": card,
			})
	for index in range(sequence.size() - 1, -1, -1):
		resolution_queue.push_front(sequence[index])


func _prepend_triggered_effects(
	card: CardDefinition,
	trigger: String,
	context: Dictionary = {}
) -> void:
	var sequence: Array[Dictionary] = []
	for effect in card.special_effects:
		if str(effect.get("trigger", "play")) != trigger:
			continue
		var runtime_effect := effect.duplicate(true)
		for key in context:
			runtime_effect["_event_%s" % key] = context[key]
		sequence.append({
			"kind": "special",
			"effect": runtime_effect,
			"source_card": card,
		})
	for index in range(sequence.size() - 1, -1, -1):
		resolution_queue.push_front(sequence[index])


func _prepend_gain_reactions(gained_card: CardDefinition, destination: String) -> void:
	var reactions: Array[Dictionary] = []
	for reaction_card in player.hand:
		for effect in reaction_card.special_effects:
			if str(effect.get("trigger", "")) != "gain_reaction":
				continue
			if str(effect.get("card_id", "")) == gained_card.id:
				continue
			var runtime_effect := effect.duplicate(true)
			runtime_effect["_event_gained_card"] = gained_card
			runtime_effect["_event_destination"] = destination
			reactions.append({
				"kind": "special",
				"effect": runtime_effect,
				"source_card": reaction_card,
			})
	for index in range(reactions.size() - 1, -1, -1):
		resolution_queue.push_front(reactions[index])


func _process_resolution_queue() -> void:
	while not has_pending_choice() and not resolution_queue.is_empty():
		var entry: Dictionary = resolution_queue.pop_front()
		match str(entry.get("kind", "")):
			"card_base":
				_apply_card_base(entry["card"])
			"special":
				_resolve_special_effect(entry["effect"], entry["source_card"])
			"exact_gain_request":
				_request_exact_supply_choice(
					int(entry.get("cost", 0)),
					str(entry.get("destination", "discard")),
					str(entry.get("exclude_card_id", "")),
					str(entry.get("prompt", "Choose a card to gain."))
				)


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
		"progressive_resource":
			var progress_key := "played_%s" % source_card.id
			var play_count := int(turn_flags.get(progress_key, 0)) + 1
			turn_flags[progress_key] = play_count
			player.coins += (
				int(effect.get("first_amount", 1))
				if play_count == 1
				else int(effect.get("later_amount", 4))
			)
		"draw_per_type_in_hand":
			var type_count := 0
			var card_type := str(effect.get("card_type", "victory"))
			for card in player.hand:
				if card.card_type == card_type:
					type_count += 1
			draw_cards(type_count * int(effect.get("amount", 1)))
		"first_play_actions":
			var first_key := "first_play_%s" % source_card.id
			if not bool(turn_flags.get(first_key, false)):
				turn_flags[first_key] = true
				player.actions += int(effect.get("amount", 0))
		"survey_top":
			_begin_survey_top(int(effect.get("amount", 4)))
		"develop":
			_request_zone_choice(
				player.hand,
				"Choose a card from your hand to trash and develop.",
				mini(1, player.hand.size()),
				mini(1, player.hand.size()),
				"develop_trash",
				"DEVELOP",
				"SKIP"
			)
		"register_buy_bonus":
			turn_flags["buy_bonus_count"] = int(turn_flags.get("buy_bonus_count", 0)) + 1
		"reduce_costs":
			turn_flags["cost_reduction"] = (
				int(turn_flags.get("cost_reduction", 0))
				+ int(effect.get("amount", 1))
			)
		"reduce_end_turn_cooldown":
			reduce_end_turn_cooldown(float(effect.get("amount", 0.5)))
		"discard_filtered":
			var discard_candidates := _filter_hand_cards(effect)
			var discard_amount := mini(int(effect.get("amount", 1)), discard_candidates.size())
			var discard_context := {}
			if effect.has("attack"):
				discard_context["attack"] = effect["attack"]
				discard_context["attack_if_discarded_type"] = str(
					effect.get("attack_if_discarded_type", "")
				)
				discard_context["source_card"] = source_card
			_request_zone_choice(
				discard_candidates,
				str(effect.get("prompt", "Choose cards from your hand to discard.")),
				discard_amount if bool(effect.get("required", true)) else 0,
				discard_amount,
				"discard_hand",
				"DISCARD",
				"SKIP",
				discard_context
			)
		"trash_filtered":
			var trash_candidates := _filter_hand_cards(effect)
			var trash_amount := mini(int(effect.get("amount", 1)), trash_candidates.size())
			_request_zone_choice(
				trash_candidates,
				str(effect.get("prompt", "Choose cards from your hand to trash.")),
				trash_amount if bool(effect.get("required", false)) else 0,
				trash_amount,
				"trash_hand",
				"TRASH",
				"SKIP"
			)
		"topdeck_action_at_cleanup":
			turn_flags["cleanup_topdeck_actions"] = (
				int(turn_flags.get("cleanup_topdeck_actions", 0))
				+ int(effect.get("amount", 1))
			)
		"trash_resource_choose_bonus":
			var trash_resources: Array[CardDefinition] = []
			for card in player.hand:
				if card.card_type == "resource":
					trash_resources.append(card)
			_request_zone_choice(
				trash_resources,
				"You may trash a resource from your hand.",
				0,
				mini(1, trash_resources.size()),
				"trash_resource_mode",
				"TRASH",
				"SKIP",
				{"modes": effect.get("modes", [])}
			)
		"discard_resource_bonus":
			var discard_resources: Array[CardDefinition] = []
			for card in player.hand:
				if card.card_type == "resource":
					discard_resources.append(card)
			_request_zone_choice(
				discard_resources,
				"You may discard a resource for the bonus.",
				0,
				mini(1, discard_resources.size()),
				"discard_resource_bonus",
				"DISCARD",
				"SKIP",
				{
					"draw_cards": int(effect.get("draw_cards", 0)),
					"gain_actions": int(effect.get("gain_actions", 0)),
				}
			)
		"conditional_draw":
			if player.hand.size() <= int(effect.get("maximum_hand_size", 5)):
				draw_cards(int(effect.get("amount", 0)))
		"choose_named_or_supply":
			_request_mode_choice(
				source_card,
				str(effect.get("prompt", "Choose how to gain cards.")),
				effect.get("modes", []),
				"named_or_supply_mode"
			)
		"gain_cheaper":
			_request_filtered_supply_choice(
				{
					"max_cost": get_effective_cost(source_card) - 1,
					"exclude_card_id": source_card.id,
					"exclude_victory": bool(effect.get("exclude_victory", false)),
				},
				str(effect.get("destination", "discard")),
				str(effect.get("prompt", "Choose a cheaper card to gain."))
			)
		"gain_coins_trigger":
			player.coins += int(effect.get("amount", 0))
		"play_self_optional":
			_request_play_self(source_card, effect)
		"play_self_if_action_in_play":
			if _has_other_action_in_play(source_card):
				_play_card_from_event_zone(source_card, effect)
		"dynamic_hand_coins":
			player.coins += maxi(
				0,
				int(effect.get("base_amount", 0))
				- player.hand.size() * int(effect.get("per_card", 1))
			)
		"discard_for_action_gain":
			_request_zone_choice(
				player.hand,
				"You may discard a card to gain an action card costing no more.",
				0,
				mini(1, player.hand.size()),
				"discard_for_action_gain",
				"DISCARD",
				"SKIP"
			)
		"optional_gain_card":
			_request_optional_source_choice(
				source_card,
				str(effect.get("prompt", "Gain the named card?")),
				"optional_gain_card",
				"GAIN",
				"SKIP",
				{
					"card_id": str(effect.get("card_id", "")),
					"destination": str(effect.get("destination", "discard")),
				}
			)
		"trash_for_copies":
			_request_zone_choice(
				player.hand,
				"Choose a card from your hand to trash.",
				mini(1, player.hand.size()),
				mini(1, player.hand.size()),
				"trash_for_copies",
				"TRASH",
				"SKIP",
				{"card_id": str(effect.get("card_id", ""))}
			)
		"replace_gain":
			_request_optional_source_choice(
				source_card,
				str(effect.get("prompt", "Exchange the gained card?")),
				"replace_gain",
				"EXCHANGE",
				"KEEP",
				{
					"gained_card": effect.get("_event_gained_card"),
					"destination": str(effect.get("_event_destination", "discard")),
					"replacement_card_id": str(effect.get("card_id", "")),
				}
			)
		"shuffle_actions_from_discard":
			var discard_actions: Array[CardDefinition] = []
			for card in player.discard_pile:
				if card.card_type == "action":
					discard_actions.append(card)
			_request_zone_choice(
				discard_actions,
				"Choose any action cards from your discard pile to shuffle into your deck.",
				0,
				discard_actions.size(),
				"shuffle_actions",
				"SHUFFLE IN",
				"LEAVE THEM"
			)
		"attack":
			_resolve_attack(effect, source_card)
		"register_gain_attack":
			_register_gain_attack(effect, source_card)
		"upgrade_exact_nonself":
			_request_zone_choice(
				player.hand,
				"Choose a card from your hand to trash.",
				mini(1, player.hand.size()),
				mini(1, player.hand.size()),
				"upgrade_exact_nonself",
				"TRASH",
				"SKIP",
				{
					"cost_delta": int(effect.get("cost_delta", 2)),
					"exclude_card_id": source_card.id,
				}
			)
		_:
			push_warning("Unknown card effect kind: %s" % kind)


func resolve_choice(tokens: Array[String]) -> bool:
	if pending_choice == null or not pending_choice.is_valid_selection(tokens):
		return false
	var choice := pending_choice
	var selected := choice.get_selected_entries(tokens)
	pending_choice = null
	player.pending_choice = null
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
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			draw_cards(cards.size())
		"discard_hand":
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			_resolve_choice_attack(choice, cards)
		"trash_hand":
			_move_cards(player.hand, player.trash_pile, cards, "trash")
		"topdeck_discard":
			_move_cards(player.discard_pile, player.draw_pile, cards)
		"upgrade_resource":
			if cards.is_empty():
				return
			var trashed := cards[0]
			_move_cards(player.hand, player.trash_pile, [trashed], "trash")
			_request_supply_choice(
				get_effective_cost(trashed) + int(choice.context.get("cost_delta", 0)),
				"hand",
				"resource",
				"Choose a replacement resource to gain to your hand."
			)
		"trash_named_coins":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.trash_pile, cards, "trash")
			player.coins += int(choice.context.get("amount", 0))
		"remodel":
			if cards.is_empty():
				return
			var trashed := cards[0]
			_move_cards(player.hand, player.trash_pile, [trashed], "trash")
			_request_supply_choice(
				get_effective_cost(trashed) + int(choice.context.get("cost_delta", 0)),
				"discard",
				"",
				"Choose a card to gain."
			)
		"inspect_trash":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			for card in cards:
				revealed.erase(card)
			player.trash_pile.append_array(cards)
			_queue_zone_events(cards, "trash", "trash")
			_request_inspect_discard(revealed)
		"inspect_discard":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			for card in cards:
				revealed.erase(card)
			player.discard_pile.append_array(cards)
			_queue_zone_events(cards, "discard", "discard")
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
				_prepend_triggered_effects(card, "discard", {"zone": "discard"})
		"salvage_resource":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			if not cards.is_empty():
				var resource := cards[0]
				revealed.erase(resource)
				player.trash_pile.append(resource)
				_prepend_triggered_effects(resource, "trash", {"zone": "trash"})
				player.coins += resource.coin_value
			player.discard_pile.append_array(revealed)
			_queue_zone_events(revealed, "discard", "discard")
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
				_prepend_triggered_effects(card, "discard", {"zone": "discard"})
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
		"survey_discard":
			var surveyed: Array[CardDefinition] = choice.context.get("revealed", [])
			for card in cards:
				surveyed.erase(card)
			player.discard_pile.append_array(cards)
			_queue_zone_events(cards, "discard", "discard")
			_begin_order_cards(surveyed)
		"order_cards":
			var remaining: Array[CardDefinition] = choice.context.get("remaining", [])
			var ordered: Array[CardDefinition] = choice.context.get("ordered", [])
			if not cards.is_empty():
				var top_card := cards[0]
				remaining.erase(top_card)
				ordered.append(top_card)
			_continue_order_cards(remaining, ordered)
		"develop_trash":
			if cards.is_empty():
				return
			var developed := cards[0]
			_move_cards(player.hand, player.trash_pile, [developed], "trash")
			_request_mode_choice(
				developed,
				"Choose which developed card should be gained first.",
				[
					{"id": "higher_first", "label": "HIGHER FIRST"},
					{"id": "lower_first", "label": "LOWER FIRST"},
				],
				"develop_order",
				{"trashed_cost": get_effective_cost(developed)}
			)
		"develop_order":
			var mode_id := _selected_mode_id(selected)
			var trashed_cost := int(choice.context.get("trashed_cost", 0))
			var first_delta := 1 if mode_id == "higher_first" else -1
			resolution_queue.push_front({
				"kind": "exact_gain_request",
				"cost": trashed_cost - first_delta,
				"destination": "deck",
				"prompt": "Choose the second developed card.",
			})
			_request_exact_supply_choice(
				trashed_cost + first_delta,
				"deck",
				"",
				"Choose the first developed card."
			)
		"trash_resource_mode":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.trash_pile, cards, "trash")
			_request_mode_choice(
				cards[0],
				"Choose the spicebroker bonus.",
				choice.context.get("modes", []),
				"apply_bonus_mode"
			)
		"apply_bonus_mode":
			_apply_mode_bonus(_selected_mode(choice, selected))
		"discard_resource_bonus":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			draw_cards(int(choice.context.get("draw_cards", 0)))
			player.actions += int(choice.context.get("gain_actions", 0))
		"named_or_supply_mode":
			var gain_mode := _selected_mode(choice, selected)
			if gain_mode.is_empty():
				return
			if gain_mode.has("card_id"):
				for _index in range(int(gain_mode.get("amount", 1))):
					_gain_card_by_id(
						str(gain_mode.get("card_id", "")),
						str(gain_mode.get("destination", "discard"))
					)
			else:
				_request_filtered_supply_choice(
					{
						"max_cost": int(gain_mode.get("max_cost", 99)),
						"card_type": str(gain_mode.get("card_type", "")),
					},
					str(gain_mode.get("destination", "discard")),
					str(gain_mode.get("prompt", "Choose a card to gain."))
				)
		"play_self":
			if not cards.is_empty():
				_play_card_from_event_zone(
					choice.context.get("source_card"),
					choice.context.get("effect", {})
				)
		"discard_for_action_gain":
			if cards.is_empty():
				return
			var discarded := cards[0]
			_move_cards(player.hand, player.discard_pile, [discarded], "discard")
			_request_filtered_supply_choice(
				{
					"max_cost": get_effective_cost(discarded),
					"card_type": "action",
				},
				"discard",
				"Choose an action card to gain."
			)
		"optional_gain_card":
			if not cards.is_empty():
				_gain_card_by_id(
					str(choice.context.get("card_id", "")),
					str(choice.context.get("destination", "discard"))
				)
		"trash_for_copies":
			if cards.is_empty():
				return
			var traded := cards[0]
			_move_cards(player.hand, player.trash_pile, [traded], "trash")
			for _index in range(get_effective_cost(traded)):
				_gain_card_by_id(str(choice.context.get("card_id", "")), "discard")
		"replace_gain":
			if cards.is_empty():
				return
			var gained: CardDefinition = choice.context.get("gained_card")
			var destination_name := str(choice.context.get("destination", "discard"))
			var destination: Array[CardDefinition] = _get_zone(destination_name)
			if gained == null or not destination.has(gained):
				return
			destination.erase(gained)
			if supply_piles.has(gained.id):
				supply_piles[gained.id] = get_supply_count(gained.id) + 1
			_gain_card_by_id(
				str(choice.context.get("replacement_card_id", "")),
				destination_name
			)
		"shuffle_actions":
			for card in cards:
				player.discard_pile.erase(card)
				player.draw_pile.append(card)
			player.draw_pile.shuffle()
		"upgrade_exact_nonself":
			if cards.is_empty():
				return
			var upgraded := cards[0]
			_move_cards(player.hand, player.trash_pile, [upgraded], "trash")
			var target_cost := (
				get_effective_cost(upgraded)
				+ int(choice.context.get("cost_delta", 2))
			)
			_request_exact_supply_choice(
				target_cost,
				"discard",
				str(choice.context.get("exclude_card_id", "")),
				"Choose a different card costing exactly %d." % target_cost
			)
		"cleanup_topdeck":
			_move_cards(player.play_area, player.draw_pile, cards)
			_finish_cleanup()
		"attack_trash_resource":
			_finish_attack_reveal_resource(choice.context.get("revealed", []), cards)


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
	player.pending_choice = choice
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
			"Cost %d  •  %d left"
			% [get_effective_cost(card), get_supply_count(card.id)]
		)
	_request_choice(choice)


func _request_filtered_supply_choice(
	filter: Dictionary,
	destination: String,
	prompt: String
) -> void:
	var candidates: Array[CardDefinition] = []
	var max_cost := int(filter.get("max_cost", 99))
	var min_cost := int(filter.get("min_cost", 0))
	var exact_cost = filter.get("exact_cost", null)
	var card_type := str(filter.get("card_type", ""))
	var exclude_card_id := str(filter.get("exclude_card_id", ""))
	var exclude_victory := bool(filter.get("exclude_victory", false))
	for card in market:
		var effective_cost := get_effective_cost(card)
		if get_supply_count(card.id) <= 0:
			continue
		if effective_cost < min_cost or effective_cost > max_cost:
			continue
		if exact_cost != null and effective_cost != int(exact_cost):
			continue
		if not card_type.is_empty() and card.card_type != card_type:
			continue
		if not exclude_card_id.is_empty() and card.id == exclude_card_id:
			continue
		if exclude_victory and card.card_type == "victory":
			continue
		candidates.append(card)
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
			"Cost %d | %d left" % [get_effective_cost(card), get_supply_count(card.id)]
		)
	_request_choice(choice)


func _request_exact_supply_choice(
	cost: int,
	destination: String,
	exclude_card_id: String,
	prompt: String
) -> void:
	_request_filtered_supply_choice(
		{
			"exact_cost": cost,
			"exclude_card_id": exclude_card_id,
		},
		destination,
		prompt
	)


func _request_mode_choice(
	source_card: CardDefinition,
	prompt: String,
	modes: Array,
	resolver: String,
	context: Dictionary = {}
) -> void:
	if modes.is_empty():
		return
	var choice := _new_choice(prompt, 1, 1, resolver, "CHOOSE", "SKIP", context)
	choice.context["modes"] = modes
	for index in range(modes.size()):
		var mode: Dictionary = modes[index]
		choice.add_candidate(
			"mode:%d:%s" % [choice.id, str(mode.get("id", index))],
			source_card,
			str(mode.get("label", "OPTION"))
		)
	_request_choice(choice)


func _request_optional_source_choice(
	source_card: CardDefinition,
	prompt: String,
	resolver: String,
	confirm_text: String,
	skip_text: String,
	context: Dictionary
) -> void:
	var choice := _new_choice(
		prompt,
		0,
		1,
		resolver,
		confirm_text,
		skip_text,
		context
	)
	choice.add_candidate("optional:%d" % choice.id, source_card)
	_request_choice(choice)


func _selected_mode(choice: CardChoice, selected: Array[Dictionary]) -> Dictionary:
	var mode_id := _selected_mode_id(selected)
	for mode in choice.context.get("modes", []):
		if str(mode.get("id", "")) == mode_id:
			return mode
	return {}


func _selected_mode_id(selected: Array[Dictionary]) -> String:
	if selected.is_empty():
		return ""
	var token := str(selected[0].get("token", ""))
	return token.get_slice(":", 2)


func _apply_mode_bonus(mode: Dictionary) -> void:
	if mode.is_empty():
		return
	draw_cards(int(mode.get("draw_cards", 0)))
	player.actions += int(mode.get("gain_actions", 0))
	player.buys += int(mode.get("gain_buys", 0))
	player.coins += int(mode.get("gain_coins", 0))


func _filter_hand_cards(effect: Dictionary) -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	var card_type := str(effect.get("card_type", ""))
	var exclude_type := str(effect.get("exclude_type", ""))
	for card in player.hand:
		if not card_type.is_empty() and card.card_type != card_type:
			continue
		if not exclude_type.is_empty() and card.card_type == exclude_type:
			continue
		candidates.append(card)
	return candidates


func _cards_from_entries(entries: Array[Dictionary]) -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	for entry in entries:
		cards.append(entry["card"])
	return cards


func _move_cards(
	source: Array[CardDefinition],
	destination: Array[CardDefinition],
	cards: Array[CardDefinition],
	event: String = ""
) -> void:
	for card in cards:
		source.erase(card)
		destination.append(card)
	if not event.is_empty():
		_queue_zone_events(cards, event, event)


func _queue_zone_events(
	cards: Array[CardDefinition],
	trigger: String,
	zone_name: String
) -> void:
	for card in cards:
		_prepend_triggered_effects(card, trigger, {"zone": zone_name})


func _get_zone(zone_name: String) -> Array[CardDefinition]:
	match zone_name:
		"hand":
			return player.hand
		"deck":
			return player.draw_pile
		"trash":
			return player.trash_pile
		"play":
			return player.play_area
		_:
			return player.discard_pile


func _take_top_card() -> CardDefinition:
	return _take_top_card_for_player(player)


func _take_top_card_for_player(target: PlayerState) -> CardDefinition:
	if target.draw_pile.is_empty() and not target.discard_pile.is_empty():
		target.draw_pile.append_array(target.discard_pile)
		target.discard_pile.clear()
		target.draw_pile.shuffle()
		print(
			"[Game] Shuffle discard into %s draw pile (%d cards)"
			% [target.player_name, target.draw_pile.size()]
		)
	if target.draw_pile.is_empty():
		return null
	return target.draw_pile.pop_back()


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
	if not supply_piles.has(card_id):
		supply_piles[card_id] = _default_supply_count(card)
	if get_supply_count(card_id) <= 0:
		return
	_gain_from_supply(card, destination)


func _default_supply_count(card: CardDefinition) -> int:
	match card.card_type:
		"victory":
			return VICTORY_SUPPLY_COUNT
		"resource":
			return RESOURCE_SUPPLY_COUNT
		"curse":
			return CURSE_SUPPLY_COUNT
		_:
			return ACTION_SUPPLY_COUNT


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
	_prepend_gain_reactions(card, destination)
	_prepend_triggered_effects(card, "gain", {"zone": destination})
	_queue_gain_attacks(card)
	return true


func _trash_from_play(card: CardDefinition) -> void:
	if player.play_area.has(card):
		player.play_area.erase(card)
		player.trash_pile.append(card)
		_prepend_triggered_effects(card, "trash", {"zone": "trash"})


func _continue_library_draw(
	target_size: int,
	set_aside: Array[CardDefinition]
) -> void:
	while player.hand.size() < target_size:
		var card := _take_top_card()
		if card == null:
			player.discard_pile.append_array(set_aside)
			_queue_zone_events(set_aside, "discard", "discard")
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
	_queue_zone_events(set_aside, "discard", "discard")


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
		_queue_zone_events(revealed, "discard", "discard")
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
		_prepend_triggered_effects(card, "discard", {"zone": "discard"})
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


func _begin_survey_top(amount: int) -> void:
	var revealed: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card != null:
			revealed.append(card)
	if revealed.is_empty():
		return
	_request_zone_choice(
		revealed,
		"Choose any revealed cards to discard.",
		0,
		revealed.size(),
		"survey_discard",
		"DISCARD SELECTED",
		"DISCARD NONE",
		{"revealed": revealed}
	)


func _get_attack_targets() -> Array[PlayerState]:
	if players.size() <= 1:
		return [player]
	var targets: Array[PlayerState] = []
	for index in range(players.size()):
		if index == active_player_index:
			continue
		targets.append(players[index])
	return targets


func _gain_card_by_id_for_player(
	card_id: String,
	destination: String,
	target: PlayerState
) -> void:
	if target == player:
		_gain_card_by_id(card_id, destination)
		return
	if not card_catalog.has(card_id):
		return
	var card: CardDefinition = card_catalog[card_id]
	if not supply_piles.has(card_id):
		supply_piles[card_id] = _default_supply_count(card)
	if get_supply_count(card_id) <= 0:
		return
	supply_piles[card_id] = get_supply_count(card_id) - 1
	match destination:
		"hand":
			target.hand.append(card)
		"deck":
			target.draw_pile.append(card)
		_:
			target.discard_pile.append(card)


func _discard_down_for_player(target: PlayerState, target_size: int) -> void:
	var discard_count := maxi(0, target.hand.size() - target_size)
	for _index in range(discard_count):
		var card: CardDefinition = target.hand.pop_back() as CardDefinition
		if card != null:
			target.discard_pile.append(card)


func _topdeck_victory_for_player(target: PlayerState) -> void:
	for card in target.hand:
		if card.card_type != "victory":
			continue
		target.hand.erase(card)
		target.draw_pile.append(card)
		return


func _trash_revealed_resource_for_player(
	target: PlayerState,
	amount: int,
	exclude_card_id: String
) -> void:
	var revealed: Array[CardDefinition] = []
	var trashed_resource: CardDefinition = null
	for _index in range(amount):
		var card := _take_top_card_for_player(target)
		if card == null:
			continue
		if (
			trashed_resource == null
			and card.card_type == "resource"
			and card.id != exclude_card_id
		):
			trashed_resource = card
			target.trash_pile.append(card)
		else:
			revealed.append(card)
	target.discard_pile.append_array(revealed)


func _resolve_attack(effect: Dictionary, _source_card: CardDefinition) -> void:
	var targets := _get_attack_targets()
	match str(effect.get("mode", "gain_curse")):
		"gain_curse":
			for target in targets:
				for _index in range(int(effect.get("amount", 1))):
					_gain_card_by_id_for_player(
						str(effect.get("card_id", CURSE_CARD_ID)),
						str(effect.get("destination", "discard")),
						target
					)
		"discard_down":
			var target_size := int(effect.get("target_hand_size", 3))
			for target in targets:
				if target == player:
					var discard_count := maxi(0, player.hand.size() - target_size)
					_request_zone_choice(
						player.hand,
						"Choose %d card%s to discard for the attack."
						% [discard_count, "" if discard_count == 1 else "s"],
						discard_count,
						discard_count,
						"discard_hand",
						"DISCARD"
					)
				else:
					_discard_down_for_player(target, target_size)
		"topdeck_victory":
			for target in targets:
				if target == player:
					var victory_cards: Array[CardDefinition] = []
					for card in player.hand:
						if card.card_type == "victory":
							victory_cards.append(card)
					_request_zone_choice(
						victory_cards,
						"Choose a victory card from your hand to put on top of your deck.",
						mini(1, victory_cards.size()),
						mini(1, victory_cards.size()),
						"topdeck_hand",
						"PUT ON DECK"
					)
				else:
					_topdeck_victory_for_player(target)
		"trash_revealed_resource":
			for target in targets:
				if target == player:
					_begin_attack_reveal_resource(
						int(effect.get("amount", 2)),
						str(effect.get("exclude_card_id", ""))
					)
				else:
					_trash_revealed_resource_for_player(
						target,
						int(effect.get("amount", 2)),
						str(effect.get("exclude_card_id", ""))
					)
		_:
			push_warning("Unknown attack mode: %s" % str(effect.get("mode", "")))


func _register_gain_attack(effect: Dictionary, source_card: CardDefinition) -> void:
	var raw_attack = effect.get("attack", {})
	if typeof(raw_attack) != TYPE_DICTIONARY:
		return
	var gain_attacks: Array = turn_flags.get("gain_attacks", [])
	gain_attacks.append({
		"card_type": str(effect.get("card_type", "")),
		"attack": raw_attack.duplicate(true),
		"source_card": source_card,
	})
	turn_flags["gain_attacks"] = gain_attacks


func _queue_gain_attacks(gained_card: CardDefinition) -> void:
	for watcher in turn_flags.get("gain_attacks", []):
		var watched_type := str(watcher.get("card_type", ""))
		if not watched_type.is_empty() and gained_card.card_type != watched_type:
			continue
		var attack: Dictionary = watcher.get("attack", {}).duplicate(true)
		attack["kind"] = "attack"
		resolution_queue.push_back({
			"kind": "special",
			"effect": attack,
			"source_card": watcher.get("source_card"),
		})


func _resolve_choice_attack(choice: CardChoice, cards: Array[CardDefinition]) -> void:
	if not choice.context.has("attack"):
		return
	if cards.is_empty():
		return
	var required_type := str(choice.context.get("attack_if_discarded_type", ""))
	if not required_type.is_empty():
		var has_required_type := false
		for card in cards:
			if card.card_type == required_type:
				has_required_type = true
				break
		if not has_required_type:
			return
	var attack: Dictionary = choice.context.get("attack", {}).duplicate(true)
	_resolve_attack(attack, choice.context.get("source_card"))


func _begin_attack_reveal_resource(amount: int, exclude_card_id: String) -> void:
	var revealed: Array[CardDefinition] = []
	var resources: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card == null:
			continue
		revealed.append(card)
		if card.card_type == "resource" and card.id != exclude_card_id:
			resources.append(card)
	if revealed.is_empty():
		return
	if resources.is_empty():
		_discard_revealed_cards(revealed)
		return
	_request_zone_choice(
		resources,
		"Choose a revealed resource to trash for the attack.",
		1,
		1,
		"attack_trash_resource",
		"TRASH",
		"SKIP",
		{"revealed": revealed}
	)


func _finish_attack_reveal_resource(
	revealed: Array[CardDefinition],
	trashed_cards: Array[CardDefinition]
) -> void:
	for card in trashed_cards:
		revealed.erase(card)
	player.trash_pile.append_array(trashed_cards)
	_queue_zone_events(trashed_cards, "trash", "trash")
	_discard_revealed_cards(revealed)


func _discard_revealed_cards(cards: Array[CardDefinition]) -> void:
	player.discard_pile.append_array(cards)
	_queue_zone_events(cards, "discard", "discard")


func _begin_order_cards(cards: Array[CardDefinition]) -> void:
	_continue_order_cards(cards, [])


func _continue_order_cards(
	remaining: Array[CardDefinition],
	ordered: Array[CardDefinition]
) -> void:
	if remaining.is_empty():
		for index in range(ordered.size() - 1, -1, -1):
			player.draw_pile.append(ordered[index])
		return
	if remaining.size() == 1:
		ordered.append(remaining[0])
		remaining.clear()
		_continue_order_cards(remaining, ordered)
		return
	_request_zone_choice(
		remaining,
		"Choose the next card to place on top of your deck.",
		1,
		1,
		"order_cards",
		"PUT NEXT",
		"SKIP",
		{
			"remaining": remaining,
			"ordered": ordered,
		}
	)


func _request_play_self(source_card: CardDefinition, effect: Dictionary) -> void:
	var event_zone := str(effect.get("_event_zone", "discard"))
	var zone: Array[CardDefinition] = _get_zone(event_zone)
	if not zone.has(source_card):
		return
	_request_optional_source_choice(
		source_card,
		str(effect.get("prompt", "Play this card now?")),
		"play_self",
		"PLAY",
		"LEAVE IT",
		{
			"source_card": source_card,
			"effect": effect,
		}
	)


func _play_card_from_event_zone(source_card: CardDefinition, effect: Dictionary) -> void:
	if source_card == null:
		return
	var event_zone := str(effect.get("_event_zone", "discard"))
	var zone: Array[CardDefinition] = _get_zone(event_zone)
	if not zone.has(source_card):
		return
	zone.erase(source_card)
	player.play_area.append(source_card)
	_prepend_card_resolutions(source_card, 1)


func _has_other_action_in_play(source_card: CardDefinition) -> bool:
	for card in player.play_area:
		if card.card_type == "action" and card != source_card:
			return true
	return false


func buy_card(card: CardDefinition) -> bool:
	if (
		card == null
		or has_pending_choice()
		or not market.has(card)
		or get_supply_count(card.id) <= 0
	):
		return false
	var effective_cost := get_effective_cost(card)
	if player.buys <= 0 or player.coins < effective_cost:
		return false
	player.coins -= effective_cost
	player.buys -= 1
	_gain_from_supply(card, "discard")
	_prepend_triggered_effects(card, "buy", {"zone": "discard"})
	for _index in range(int(turn_flags.get("buy_bonus_count", 0))):
		resolution_queue.push_back({
			"kind": "special",
			"source_card": card,
			"effect": {
				"kind": "gain_cheaper",
				"destination": "discard",
				"exclude_victory": true,
				"prompt": "Choose a cheaper non-victory card to gain.",
			},
		})
	_process_resolution_queue()
	print(
		"[Game] Buy card: %s for %d coins (%d left)"
		% [card.card_name, effective_cost, get_supply_count(card.id)]
	)
	return true


func begin_cleanup() -> void:
	if cleanup_in_progress:
		return
	cleanup_in_progress = true
	player.cleanup_in_progress = true
	var topdeck_count := int(turn_flags.get("cleanup_topdeck_actions", 0))
	var actions_in_play: Array[CardDefinition] = []
	for card in player.play_area:
		if card.card_type == "action":
			actions_in_play.append(card)
	if topdeck_count > 0 and not actions_in_play.is_empty():
		_request_zone_choice(
			actions_in_play,
			"Choose up to %d action card%s to put on top of your deck before cleanup."
			% [topdeck_count, "" if topdeck_count == 1 else "s"],
			0,
			mini(topdeck_count, actions_in_play.size()),
			"cleanup_topdeck",
			"PUT ON DECK",
			"DISCARD ALL"
		)
		if has_pending_choice():
			return
	_finish_cleanup()


func _finish_cleanup() -> void:
	var hand_count := player.hand.size()
	var play_count := player.play_area.size()
	player.discard_pile.append_array(player.hand)
	player.discard_pile.append_array(player.play_area)
	player.hand.clear()
	player.play_area.clear()
	resolution_queue.clear()
	pending_choice = null
	player.pending_choice = null
	print(
		"[Game] Cleanup: discarded %d hand and %d played cards (discard: %d)"
		% [hand_count, play_count, player.discard_pile.size()]
	)
	cleanup_in_progress = false
	player.cleanup_in_progress = false
	cleanup_completed.emit()


func discard_hand_and_play_area() -> void:
	begin_cleanup()


func calculate_score() -> int:
	return _calculate_score_for_player(player)


func calculate_all_scores() -> Array[int]:
	var scores: Array[int] = []
	for game_player in players:
		scores.append(_calculate_score_for_player(game_player))
	return scores


func _calculate_score_for_player(scored_player: PlayerState) -> int:
	var score := 0
	var owned_cards := scored_player.get_all_cards()
	for card in owned_cards:
		score += card.victory_points
		if card.score_per_cards > 0:
			score += owned_cards.size() / card.score_per_cards
	print(
		"[Game] Scoring %s: %d victory points (draw: %d, hand: %d, play: %d, discard: %d)"
		% [
			scored_player.player_name,
			score,
			scored_player.draw_pile.size(),
			scored_player.hand.size(),
			scored_player.play_area.size(),
			scored_player.discard_pile.size(),
		]
	)
	return score
