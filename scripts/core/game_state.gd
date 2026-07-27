class_name GameState
extends RefCounted

const RelicCatalog := preload("res://scripts/core/relic_catalog.gd")

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
const MARKET_CENTRAL_COUNT := 10
const MARKET_VICTORY_TOTAL := 2
const MARKET_SIZE := MARKET_RESOURCE_COUNT + MARKET_CENTRAL_COUNT + MARKET_VICTORY_TOTAL
# The market's two Treasury slots and two Estates slots are always these cards.
# The ten central slots draw uniformly from every other eligible card.
const MARKET_FIXED_RESOURCE_IDS := ["silver_leaf", "amber_circlet"]
const MARKET_FIXED_VICTORY_IDS := ["briar_gate", "royal_charter"]
const BASE_KINGDOM := "Base Kingdom"
const BEGINNER_KINGDOM := "First Harvest"
const HINTERLANDS_GROUP := "Hinterlands"
const WITCHING_HOUR_GROUP := "Witching Hour"
const CROWNWEALTH_GROUP := "Crownwealth"
const TRAILBLAZERS_GROUP := "Trailblazers"
const ADVENTURES_GROUP := "Adventures"
const KINGDOM_ORDER := [
	BASE_KINGDOM,
	BEGINNER_KINGDOM,
	HINTERLANDS_GROUP,
	WITCHING_HOUR_GROUP,
	CROWNWEALTH_GROUP,
	TRAILBLAZERS_GROUP,
	ADVENTURES_GROUP,
]
const REQUIRED_CARD_IDS := [
	"pebble_coin",
	"silver_leaf",
	"amber_circlet",
	"homestead",
	"briar_gate",
	"royal_charter",
	"briar_hex",
]

const TURN_PHASE_ACTION := "action"
const TURN_PHASE_BUY := "buy"

const ACTION_SUPPLY_COUNT := 10
const RESOURCE_SUPPLY_COUNT := 12
const VICTORY_SUPPLY_COUNT := 8
const CURSE_SUPPLY_COUNT := 20
const CURSE_CARD_ID := "briar_hex"
const CROWNWEALTH_RESOURCE_ID := "auric_reserve"
const CROWNWEALTH_VICTORY_ID := "crownland_expanse"
const CROWNWEALTH_RESOURCE_SUPPLY_COUNT := 12
const CROWNWEALTH_VICTORY_SUPPLY_COUNT_2P := 8
const CROWNWEALTH_VICTORY_SUPPLY_COUNT_3P := 12
# Backward-compatible alias for tests/UI that only need the three-player cap.
const CROWNWEALTH_VICTORY_SUPPLY_COUNT := CROWNWEALTH_VICTORY_SUPPLY_COUNT_3P
## Fixed side supplies sit outside the randomized market and can be purchased
## directly. Pebble Coin uses a modest finite pile so its zero-cost buy remains
## useful without becoming an infinite-deck escape hatch.
const PEBBLE_SIDE_SUPPLY_COUNT := 30
const SIDE_SUPPLY_CARD_IDS := ["pebble_coin", CURSE_CARD_ID]
const TRAILBLAZERS_SIDE_SUPPLY_CARD_IDS := ["trail_sunken_chest"]
const SIX_VP_CARD_ID := "royal_charter"
const SUPPLY_EMPTY_END_COUNT := 3
const DEFAULT_END_TURN_COOLDOWN_SECONDS := 5.0
const BASE_TURN_DRAW_COUNT := 5
# Every table, solo or networked, offers a relic draft once every 7 turns.
const RELIC_TURN_INTERVAL := 7
# A solo conquest is a fixed sprint: it ends once turn 21 is finished, then the
# player drafts a scoring relic before the final tally. Networked tables keep
# ending on supply depletion instead.
const SOLO_TURN_LIMIT := 21

var player := PlayerState.new()
var players: Array[PlayerState] = []
var active_player_index: int = 0
var previous_turn_player_index: int = -1
var multiplayer_enabled: bool = false
var card_catalog: Dictionary = {}
var market: Array[CardDefinition] = []
# Events are a separate offer.  They have no finite card pile and never enter a
# player's deck; buying one resolves its effects immediately.
var event_catalog: Array[CardDefinition] = []
var event_purchases: Dictionary = {}
var event_total_purchases: Dictionary = {}
var supply_piles: Dictionary = {}
# Shared pile-token counts: {card_id: {token_id: count}}.  Tokens remain on a
# pile until an effect explicitly removes them (or a gain consumes a one-shot
# token), so this stays deterministic across network snapshots.
var supply_tokens: Dictionary = {}
# Adventures pile tokens belong to a player.  `supply_tokens` remains a
# shared/count-shaped compatibility view; this map is authoritative for the
# four +1 tokens, -cost, and trash token when resolving a player's turn.
var player_supply_tokens: Array[Dictionary] = []
# Traveller training piles are finite but are not Supply piles and therefore do
# not count toward game end.  They are initialized from card metadata rather
# than card ids so renamed Adventures data works unchanged.
var traveller_piles: Dictionary = {}
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
	event_catalog.clear()
	for card in card_catalog.values():
		if (card as CardDefinition).is_event_card():
			event_catalog.append(card)
	event_catalog.sort_custom(_is_catalog_card_before)
	return not card_catalog.is_empty()


func setup_starting_game(player_count: int = 1) -> bool:
	_create_players(maxi(1, player_count))
	turn_flags.clear()
	event_purchases.clear()
	event_total_purchases.clear()
	supply_tokens.clear()
	player_supply_tokens.clear()
	player_supply_tokens.resize(players.size())
	for token_index in range(player_supply_tokens.size()):
		player_supply_tokens[token_index] = {}
	traveller_piles.clear()
	resolution_queue.clear()
	pending_choice = null
	cleanup_in_progress = false
	active_player_index = 0
	previous_turn_player_index = -1
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

	return _setup_random_market()


func _create_players(player_count: int) -> void:
	players.clear()
	for index in range(player_count):
		var game_player := PlayerState.new()
		game_player.player_name = "Player %d" % (index + 1)
		game_player.clear_all()
		players.append(game_player)
	multiplayer_enabled = player_count > 1
	player = players[0]
	player_supply_tokens.resize(players.size())
	for index in range(player_supply_tokens.size()):
		player_supply_tokens[index] = {}


func set_active_player_index(player_index: int) -> void:
	_set_active_player(player_index, true)


func advance_active_player() -> void:
	if player.mission_extra_turn_active:
		# Mission's immediate extra turn keeps control with the same seat.  The
		# no-buy marker was armed during reset_turn_resources before this call.
		return
	if players.size() <= 1:
		_set_active_player(0, false)
		return
	previous_turn_player_index = active_player_index
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
		_set_active_player(index, false)
		var should_arm_reactions := not turn_based_enabled or index == starting_index
		reset_turn_resources(true, should_arm_reactions)
		if game_player.hand.is_empty():
			draw_cards(get_turn_draw_count(game_player))
		elif should_arm_reactions:
			_arm_start_turn_reactions()
		begin_turn_phase()
	_set_active_player(starting_index, false)


func get_end_turn_cooldown_seconds() -> float:
	# The end-turn cooldown is a multiplayer-only pacing mechanic. Singleplayer
	# games have no timeout, so ending a turn is instant. Turn-based games also
	# have no timer: play simply passes to the next player when you finish.
	if not multiplayer_enabled or turn_based_enabled:
		return 0.0
	return maxf(
		0.5,
		end_turn_cooldown_seconds
		- player.end_turn_cooldown_reduction
		- player.game_cooldown_reduction
	)


func reduce_end_turn_cooldown(amount: float) -> void:
	var reduction := maxf(0.0, amount)
	if reduction <= 0.0:
		return
	player.end_turn_cooldown_reduction += reduction
	end_turn_cooldown_reduced.emit(reduction)


func reduce_end_turn_cooldown_for_game(amount: float) -> void:
	# A permanent reduction that lasts the rest of the conquest (every future
	# turn), unlike reduce_end_turn_cooldown which only affects the current turn.
	var reduction := maxf(0.0, amount)
	if reduction <= 0.0:
		return
	player.game_cooldown_reduction += reduction
	end_turn_cooldown_reduced.emit(reduction)


func request_end_turn_after_play() -> void:
	turn_flags["end_turn_after_play"] = true


func consume_end_turn_request() -> bool:
	if bool(turn_flags.get("end_turn_after_play", false)):
		turn_flags.erase("end_turn_after_play")
		return true
	return false


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
		if card.is_event_card():
			continue
		if not card.market_enabled:
			continue
		if card.multiplayer_only and not multiplayer_enabled:
			continue
		if not is_kingdom_enabled(get_card_kingdom(card)):
			continue
		if not is_card_enabled_for_market(card.id):
			continue
		if not attack_cards_enabled and card_has_attack_effect(card):
			continue
		candidates.append(card)
	return candidates


func get_event_candidates() -> Array[CardDefinition]:
	"""Return the separate event offer; events never become market piles."""
	var candidates: Array[CardDefinition] = []
	for card in event_catalog:
		if card.multiplayer_only and not multiplayer_enabled:
			continue
		if not is_kingdom_enabled(get_card_kingdom(card)):
			continue
		if not is_card_enabled_for_market(card.id):
			continue
		candidates.append(card)
	return candidates


# Lightweight expansion accessors used by UI and snapshot adapters.  They
# expose references from the active seat without introducing duplicate state.
func get_reserve_mat() -> Array[CardDefinition]:
	return player.get_reserve_cards()


func get_journey_state() -> Dictionary:
	return player.journey_state.duplicate(true)


func is_journey_face_up() -> bool:
	return player.is_journey_active("journey")


func set_journey_face_up(face_up: bool) -> void:
	player.set_journey("journey", face_up)


func toggle_journey_token() -> bool:
	return player.toggle_journey("journey")


func get_supply_tokens() -> Dictionary:
	return supply_tokens.duplicate(true)


func get_events() -> Array[CardDefinition]:
	return get_event_candidates()


func get_event_row() -> Array[CardDefinition]:
	return get_events()


func is_event_card(card: CardDefinition) -> bool:
	return card != null and card.is_event_card()


func get_event_cost(card: CardDefinition) -> int:
	if card == null:
		return 0
	# Bridge Troll/Ferry-style card discounts never affect Events.  Only an
	# explicit event discount (useful for custom sideways cards) is applied.
	var reduction := int(turn_flags.get("event_cost_reduction", 0))
	var typed_reductions: Dictionary = turn_flags.get("typed_cost_reductions", {})
	reduction += int(typed_reductions.get("event", 0))
	return maxi(0, card.get_event_cost() - reduction)


func _event_purchase_restricted(card: CardDefinition) -> bool:
	if card == null:
		return true
	var seat_key := "%d:%s" % [active_player_index, card.id]
	var turn_count := int(event_purchases.get(seat_key, 0))
	var total_count := int(event_total_purchases.get(seat_key, 0))
	# Core Adventures wording predates explicit metadata in the card JSON.  Keep
	# these canonical restrictions here so data-only imports remain faithful.
	match card.id:
		"alms":
			if turn_count > 0:
				return true
			for in_play in player.play_area:
				if card_has_type(in_play, "resource"):
					return true
		"borrow", "save", "pilgrimage":
			if turn_count > 0:
				return true
		"mission":
			# Mission is only available when the immediately preceding turn
			# belonged to a different seat.  At game start there is no previous
			# turn, so the sentinel must not count as a valid opponent turn.
			if turn_count > 0 or (
				players.size() > 1
				and (previous_turn_player_index < 0 or previous_turn_player_index == active_player_index)
			):
				return true
		"inheritance":
			if total_count > 0:
				return true
	var metadata := card.metadata
	var metadata_restriction = metadata.get("restriction", metadata.get("restrictions", {}))
	if typeof(metadata_restriction) == TYPE_DICTIONARY:
		if bool(metadata_restriction.get("once_per_turn", false)) and turn_count > 0:
			return true
		if bool(metadata_restriction.get("once_per_game", false)) and total_count > 0:
			return true
		if bool(metadata_restriction.get("requires_no_treasures", false)):
			for in_play in player.play_area:
				if card_has_type(in_play, "resource"):
					return true
	var purchase_limit := str(metadata.get("purchase_limit", metadata.get("limit", ""))).to_lower()
	if (bool(metadata.get("once_per_turn", metadata.get("once_each_turn", false))) or purchase_limit in ["once_per_turn", "once_each_turn"]) and turn_count > 0:
		return true
	if (bool(metadata.get("once_per_game", metadata.get("once_each_game", false))) or purchase_limit in ["once_per_game", "once_each_game"]) and total_count > 0:
		return true
	if bool(metadata.get("requires_no_treasures", metadata.get("no_treasures", false))):
		for in_play in player.play_area:
			if card_has_type(in_play, "resource"):
				return true
	for effect in card.special_effects:
		var restriction := str(effect.get("kind", effect.get("restriction", "")))
		var condition := str(effect.get("condition", effect.get("requires", ""))).to_lower()
		if bool(effect.get("once_per_turn", false)) and turn_count > 0:
			return true
		if bool(effect.get("once_per_game", false)) and total_count > 0:
			return true
		if restriction in ["event_restriction", "restriction", "buy_restriction"]:
			if bool(effect.get("once_per_turn", false)) and turn_count > 0:
				return true
			if bool(effect.get("once_per_game", false)) and total_count > 0:
				return true
			if bool(effect.get("requires_no_treasures", effect.get("no_treasures", false))):
				for in_play in player.play_area:
					if card_has_type(in_play, "resource"):
						return true
			if condition in ["no_treasures", "no_treasure", "no_resources"]:
				for in_play in player.play_area:
					if card_has_type(in_play, "resource"):
						return true
			if bool(effect.get("requires_previous_player", false)) and players.size() <= 1:
				return true
	return false


func buy_event(card: CardDefinition) -> bool:
	if card == null or not is_event_card(card) or not get_event_candidates().has(card):
		return false
	if has_pending_choice() or player.buys <= 0 or bool(turn_flags.get("mission_no_buys", false)) or _event_purchase_restricted(card):
		return false
	var cost := get_event_cost(card)
	if player.coins < cost:
		return false
	player.coins -= cost
	player.buys -= 1
	var count_key := "%d:%s" % [active_player_index, card.id]
	event_purchases[count_key] = int(event_purchases.get(count_key, 0)) + 1
	event_total_purchases[count_key] = int(event_total_purchases.get(count_key, 0)) + 1
	turn_flags["event_bought"] = true
	# Events resolve their own effects but are never moved through a supply pile
	# or registered as an in-play/duration card. Queue base outputs after their
	# special effects so mandatory event choices can precede an event's draw.
	resolution_queue.push_front({"kind": "event_base", "card": card})
	var event_effects: Array[Dictionary] = []
	for effect in card.special_effects:
		match str(effect.get("trigger", "play")):
			"play":
				event_effects.append({"kind": "special", "effect": effect.duplicate(true), "source_card": card})
			"next_turn":
				if str(effect.get("kind", "")) == "attack_immunity":
					_grant_timed_attack_immunity(effect)
				# Events do not occupy the play area, but their delayed payloads
				# still belong to the purchasing player.
				player.pending_duration_effects.append({
					"card": null,
					"effect": effect.duplicate(true),
				})
	for index in range(event_effects.size() - 1, -1, -1):
		resolution_queue.push_front(event_effects[index])
	_process_resolution_queue()
	return true


func get_event_purchase_count(card: CardDefinition, target_player_index: int = -1) -> int:
	if card == null:
		return 0
	var seat := active_player_index if target_player_index < 0 else target_player_index
	return int(event_purchases.get("%d:%s" % [seat, card.id], 0))


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
	if card.card_group == WITCHING_HOUR_GROUP:
		return WITCHING_HOUR_GROUP
	if card.card_group == CROWNWEALTH_GROUP:
		return CROWNWEALTH_GROUP
	if card.card_group == ADVENTURES_GROUP or card.event_group == ADVENTURES_GROUP:
		return ADVENTURES_GROUP
	if card.card_group == TRAILBLAZERS_GROUP or card.event_group == TRAILBLAZERS_GROUP:
		return TRAILBLAZERS_GROUP
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
	# Side supplies are part of the pack lifecycle, not randomized market
	# entries. Keep all existing market pile counts intact when this toggle
	# changes during a game.
	if kingdom == CROWNWEALTH_GROUP and not supply_piles.is_empty():
		_set_crownwealth_side_supplies(enabled)
	if kingdom == TRAILBLAZERS_GROUP and not supply_piles.is_empty():
		_set_trailblazers_side_supplies(enabled)
	if kingdom == ADVENTURES_GROUP and not supply_piles.is_empty():
		_set_adventures_traveller_piles(enabled)


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
	return get_random_market_candidates().size() >= MARKET_CENTRAL_COUNT


func get_supply_count(card_id: String) -> int:
	return int(supply_piles.get(card_id, 0))


func is_side_supply_card(card_id: String) -> bool:
	if SIDE_SUPPLY_CARD_IDS.has(card_id):
		return true
	return (
		is_kingdom_enabled(CROWNWEALTH_GROUP)
		and card_id in [CROWNWEALTH_RESOURCE_ID, CROWNWEALTH_VICTORY_ID]
	) or (
		is_kingdom_enabled(TRAILBLAZERS_GROUP)
		and TRAILBLAZERS_SIDE_SUPPLY_CARD_IDS.has(card_id)
	)


func get_side_supply_card_ids() -> Array[String]:
	var card_ids: Array[String] = []
	for side_card_id in SIDE_SUPPLY_CARD_IDS:
		card_ids.append(side_card_id)
	if is_kingdom_enabled(CROWNWEALTH_GROUP):
		card_ids.append(CROWNWEALTH_RESOURCE_ID)
		card_ids.append(CROWNWEALTH_VICTORY_ID)
	if is_kingdom_enabled(TRAILBLAZERS_GROUP):
		for card_id in TRAILBLAZERS_SIDE_SUPPLY_CARD_IDS:
			card_ids.append(card_id)
	return card_ids


func set_supply_count(card_id: String, amount: int) -> void:
	if supply_piles.has(card_id):
		supply_piles[card_id] = maxi(0, amount)


func get_supply_token_count(card_id: String, token_id: String) -> int:
	var pile_tokens: Dictionary = supply_tokens.get(card_id, {})
	var shared_count := int(pile_tokens.get(token_id, 0))
	if shared_count > 0:
		return shared_count
	# Adventures pile tokens are player-owned, but expose a count-shaped view for
	# older callers that only ask whether a token is present on a pile.
	var normalized := _normalize_pile_token_id(token_id)
	for owner_map in player_supply_tokens:
		if str(owner_map.get(normalized, "")) == card_id:
			return 1
	return 0


func get_player_supply_token_card(player_index: int, token_id: String) -> String:
	if player_index < 0 or player_index >= player_supply_tokens.size():
		if player_index >= 0 and player_index < players.size():
			return players[player_index].get_pile_token_card(_normalize_pile_token_id(token_id))
		return ""
	var normalized := _normalize_pile_token_id(token_id)
	var owner_card := str(player_supply_tokens[player_index].get(normalized, ""))
	if owner_card.is_empty() and player_index < players.size():
		owner_card = players[player_index].get_pile_token_card(normalized)
	return owner_card


func get_active_player_supply_token_card(token_id: String) -> String:
	return get_player_supply_token_card(active_player_index, token_id)


func _normalize_pile_token_id(token_id: String) -> String:
	var normalized := token_id.to_lower().strip_edges().replace("+1", "").replace("+", "").replace(" ", "_")
	normalized = normalized.replace("-", "minus_")
	if normalized in ["minus_cost", "cost_reduction", "minus_1_cost"]:
		return "cost"
	if normalized in ["trash_token", "trashing", "trash_card"]:
		return "trash"
	if normalized in ["action_token", "actions"]:
		return "action"
	if normalized in ["buy_token", "buys"]:
		return "buy"
	if normalized in ["card_token", "cards"]:
		return "card"
	if normalized in ["coin_token", "coins", "money"]:
		return "coin"
	return normalized


func move_player_supply_token(player_index: int, token_id: String, card_id: String) -> bool:
	if player_index < 0 or player_index >= player_supply_tokens.size():
		return false
	var normalized := _normalize_pile_token_id(token_id)
	if normalized.is_empty():
		return false
	var owner_map: Dictionary = player_supply_tokens[player_index]
	if card_id.is_empty():
		owner_map.erase(normalized)
	else:
		owner_map[normalized] = card_id
	player_supply_tokens[player_index] = owner_map
	# Keep PlayerState's data-shaped view synchronized for network/UI adapters.
	players[player_index].set_pile_token(normalized, card_id)
	return true


func move_active_player_supply_token(token_id: String, card_id: String) -> bool:
	return move_player_supply_token(active_player_index, token_id, card_id)


func place_player_supply_token(token_id: String, card_id: String, player_index: int = -1) -> bool:
	return move_player_supply_token(active_player_index if player_index < 0 else player_index, token_id, card_id)


func get_player_pile_token(token_id: String, player_index: int = -1) -> String:
	return get_player_supply_token_card(active_player_index if player_index < 0 else player_index, token_id)


func put_deck_minus_card_token(player_index: int = -1) -> bool:
	var seat := active_player_index if player_index < 0 else player_index
	if seat < 0 or seat >= players.size():
		return false
	return players[seat].put_deck_minus_card_token()


func put_coin_minus_token(player_index: int = -1) -> bool:
	var seat := active_player_index if player_index < 0 else player_index
	if seat < 0 or seat >= players.size():
		return false
	return players[seat].put_coin_minus_token()


func get_player_pile_tokens(player_index: int = -1) -> Dictionary:
	var seat := active_player_index if player_index < 0 else player_index
	if seat < 0 or seat >= player_supply_tokens.size():
		return {}
	return player_supply_tokens[seat].duplicate(true)


func get_player_supply_tokens(player_index: int = -1) -> Dictionary:
	return get_player_pile_tokens(player_index)


func place_supply_token(card_id: String, token_id: String, amount: int = 1) -> int:
	if card_id.is_empty() or token_id.is_empty() or amount <= 0:
		return get_supply_token_count(card_id, token_id)
	var pile_tokens: Dictionary = supply_tokens.get(card_id, {}).duplicate(true)
	pile_tokens[token_id] = get_supply_token_count(card_id, token_id) + amount
	supply_tokens[card_id] = pile_tokens
	return int(pile_tokens[token_id])


func remove_supply_token(card_id: String, token_id: String, amount: int = 1) -> int:
	if amount <= 0:
		return get_supply_token_count(card_id, token_id)
	var next_value := maxi(0, get_supply_token_count(card_id, token_id) - amount)
	var pile_tokens: Dictionary = supply_tokens.get(card_id, {}).duplicate(true)
	if next_value == 0:
		pile_tokens.erase(token_id)
	else:
		pile_tokens[token_id] = next_value
	if pile_tokens.is_empty():
		supply_tokens.erase(card_id)
	else:
		supply_tokens[card_id] = pile_tokens
	return next_value


func move_supply_token(
	from_card_id: String,
	to_card_id: String,
	token_id: String,
	amount: int = 1
) -> int:
	var movable := mini(maxi(0, amount), get_supply_token_count(from_card_id, token_id))
	if movable <= 0:
		return 0
	remove_supply_token(from_card_id, token_id, movable)
	return place_supply_token(to_card_id, token_id, movable)


func get_empty_supply_pile_count() -> int:
	var empty_count := 0
	for card_id in supply_piles:
		if int(supply_piles[card_id]) <= 0:
			empty_count += 1
	return empty_count


func is_game_end_condition_met() -> bool:
	if not multiplayer_enabled and player.turn_number >= SOLO_TURN_LIMIT:
		return true
	return (
		get_empty_supply_pile_count() >= SUPPLY_EMPTY_END_COUNT
		or get_supply_count(SIX_VP_CARD_ID) <= 0
		or (
			is_kingdom_enabled(CROWNWEALTH_GROUP)
			and get_supply_count(CROWNWEALTH_VICTORY_ID) <= 0
		)
	)


func get_gain_candidates(max_cost: int, card_type: String = "") -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	for card in _get_gain_supply_cards():
		# Buy-phase discounts (Peddler/Trickster's Die) never change the cost
		# used by a gain instruction, while this-turn Quarry reductions do.
		if get_supply_count(card.id) <= 0 or get_non_buy_cost(card) > max_cost:
			continue
		if not card_type.is_empty() and not card_has_type(card, card_type):
			continue
		candidates.append(card)
	return candidates


func get_effective_cost(card: CardDefinition) -> int:
	if card == null:
		return 0
	var cost := get_non_buy_cost(card)
	# Peddler-style discounts are passive properties of the pile being bought.
	if card.card_type == "action":
		cost -= _peddler_discount(card)
	# Trickster's Die: one random market pile is 1 cheaper for the relic holder.
	if str(turn_flags.get("die_discount_card_id", "")) == card.id:
		cost -= 1
	return maxi(0, cost)


func get_non_buy_cost(card: CardDefinition) -> int:
	"""Current cost for gain/exact-cost effects, excluding buy-only discounts."""
	if card == null:
		return 0
	var reduction := int(turn_flags.get("cost_reduction", 0))
	var typed_reductions: Dictionary = turn_flags.get("typed_cost_reductions", {})
	reduction += int(typed_reductions.get(card.card_type, 0))
	# A cost token on a supply pile applies to gains and exact-cost checks as
	# well as purchases.  It is persistent until a caller removes it.
	if card != null:
		var owner_cost_card := get_active_player_supply_token_card("cost")
		if owner_cost_card == card.id:
			# Ferry's token is the Adventures -2 coin cost token (the data uses
			# amount 1 to mean one token, not one coin).
			reduction += 2
		else:
			# Preserve the old count-shaped API for generic effects/tests that do
			# not assign an owner to their token.
			reduction += get_supply_token_count(card.id, "cost") * 2
	return maxi(0, card.cost - reduction)


func _peddler_discount(card: CardDefinition) -> int:
	var amount_per_action := 0
	for effect in card.special_effects:
		if str(effect.get("kind", "")) == "peddler_discount":
			amount_per_action += int(effect.get("amount", 2))
	if amount_per_action <= 0:
		return 0
	var count := 0
	for in_play in player.play_area:
		if in_play.card_type == "action":
			count += 1
	return count * amount_per_action


func card_has_type(card: CardDefinition, requested_type: String) -> bool:
	if card == null:
		return false
	if card.card_type == requested_type:
		return true
	for source_card in market:
		for effect in source_card.special_effects:
			if (
				str(effect.get("kind", "")) == "global_card_rule"
				and str(effect.get("target_card_id", "")) == card.id
				and str(effect.get("add_type", "")) == requested_type
			):
				return true
	return false


func is_card_playable(card: CardDefinition) -> bool:
	return card != null and (card.is_playable() or card_has_type(card, "resource"))


func _card_coin_value(card: CardDefinition) -> int:
	if card == null:
		return 0
	var value := card.coin_value
	for source_card in market:
		for effect in source_card.special_effects:
			if (
				str(effect.get("kind", "")) == "global_card_rule"
				and str(effect.get("target_card_id", "")) == card.id
			):
				value = maxi(value, int(effect.get("coin_value", 0)))
	return value


func _setup_random_market() -> bool:
	var random_pool := get_random_market_candidates()
	if random_pool.size() < MARKET_CENTRAL_COUNT:
		push_error(
			"Not enough eligible cards for the central market (need %d, have %d)."
			% [MARKET_CENTRAL_COUNT, random_pool.size()]
		)
		return false
	random_pool.shuffle()
	var selected: Array[CardDefinition] = []
	for fixed_id in MARKET_FIXED_RESOURCE_IDS + MARKET_FIXED_VICTORY_IDS:
		var fixed_card := card_catalog.get(fixed_id) as CardDefinition
		if fixed_card == null:
			push_error("Missing fixed market card definition: %s" % fixed_id)
			return false
		selected.append(fixed_card)
	for index in range(MARKET_CENTRAL_COUNT):
		selected.append(random_pool[index])

	market.assign(selected)
	_initialize_supply_piles()
	print("[Game] Market setup: %s" % ", ".join(get_market_card_ids()))
	return true


func _initialize_supply_piles() -> void:
	supply_piles.clear()
	supply_tokens.clear()
	traveller_piles.clear()
	for catalog_card in card_catalog.values():
		var training_card := catalog_card as CardDefinition
		if training_card == null or (
				not training_card.is_traveller_card()
				and not bool(training_card.metadata.get("support_pile", false))
				and not bool(training_card.metadata.get("non_supply", false))
			):
			continue
		# Page/Peasant are Supply cards; their training stages are not.  Data may
		# state this explicitly, or infer it from a stage greater than zero.
		if training_card.is_supply_card() and training_card.traveller_stage <= 0:
			continue
		traveller_piles[training_card.id] = _traveller_pile_size(training_card)
	for card in market:
		match card.card_type:
			"victory":
				supply_piles[card.id] = scale_supply_count(VICTORY_SUPPLY_COUNT)
			"resource":
				supply_piles[card.id] = scale_supply_count(RESOURCE_SUPPLY_COUNT)
			_:
				supply_piles[card.id] = scale_supply_count(ACTION_SUPPLY_COUNT)
	if card_catalog.has("pebble_coin"):
		supply_piles["pebble_coin"] = scale_supply_count(PEBBLE_SIDE_SUPPLY_COUNT)
	if card_catalog.has(CURSE_CARD_ID):
		supply_piles[CURSE_CARD_ID] = scale_supply_count(CURSE_SUPPLY_COUNT)
	_set_crownwealth_side_supplies(is_kingdom_enabled(CROWNWEALTH_GROUP))
	_set_trailblazers_side_supplies(is_kingdom_enabled(TRAILBLAZERS_GROUP))
	_set_adventures_traveller_piles(is_kingdom_enabled(ADVENTURES_GROUP))


func _traveller_pile_size(card: CardDefinition) -> int:
	# Adventures uses five copies of each non-Supply Traveller.  Allow data to
	# override this for compatible expansions without making the rules depend on
	# an id or a group name.
	if card == null:
		return 0
	var declared := int(card.metadata.get("pile_size", card.metadata.get("supply_count", 5)))
	return maxi(0, declared)


func get_traveller_supply_count(card_id: String) -> int:
	return int(traveller_piles.get(card_id, 0))


func _set_adventures_traveller_piles(enabled: bool) -> void:
	if enabled:
		for catalog_card in card_catalog.values():
			var traveller := catalog_card as CardDefinition
			if traveller == null or (
				not traveller.is_traveller_card()
				and not bool(traveller.metadata.get("support_pile", false))
				and not bool(traveller.metadata.get("non_supply", false))
			):
				continue
			if traveller.is_supply_card() and traveller.traveller_stage <= 0:
				continue
			if not traveller_piles.has(traveller.id):
				traveller_piles[traveller.id] = _traveller_pile_size(traveller)
		return
	for catalog_card in card_catalog.values():
		var traveller := catalog_card as CardDefinition
		if traveller != null and (
				traveller.is_traveller_card()
				or bool(traveller.metadata.get("support_pile", false))
				or bool(traveller.metadata.get("non_supply", false))
			) and (not traveller.is_supply_card() or traveller.traveller_stage > 0):
			traveller_piles.erase(traveller.id)


func _set_crownwealth_side_supplies(enabled: bool) -> void:
	if not enabled:
		supply_piles.erase(CROWNWEALTH_RESOURCE_ID)
		supply_piles.erase(CROWNWEALTH_VICTORY_ID)
		return
	if card_catalog.has(CROWNWEALTH_RESOURCE_ID):
		supply_piles[CROWNWEALTH_RESOURCE_ID] = scale_supply_count(CROWNWEALTH_RESOURCE_SUPPLY_COUNT)
	if card_catalog.has(CROWNWEALTH_VICTORY_ID):
		supply_piles[CROWNWEALTH_VICTORY_ID] = scale_supply_count(
			CROWNWEALTH_VICTORY_SUPPLY_COUNT_2P
			if players.size() <= 2
			else CROWNWEALTH_VICTORY_SUPPLY_COUNT_3P
		)


func _set_trailblazers_side_supplies(enabled: bool) -> void:
	for card_id in TRAILBLAZERS_SIDE_SUPPLY_CARD_IDS:
		if not enabled:
			supply_piles.erase(card_id)
			continue
		if card_catalog.has(card_id):
			supply_piles[card_id] = _default_supply_count(card_catalog[card_id])


func _get_gain_supply_cards() -> Array[CardDefinition]:
	"""Market piles plus enabled side supplies for gain effects."""
	var cards: Array[CardDefinition] = []
	cards.append_array(market)
	for card_id in get_side_supply_card_ids():
		if not card_catalog.has(card_id):
			continue
		var side_card: CardDefinition = card_catalog[card_id]
		if not cards.has(side_card):
			cards.append(side_card)
	return cards


func get_random_market_candidates() -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	for card in get_market_candidates():
		if MARKET_FIXED_RESOURCE_IDS.has(card.id) or MARKET_FIXED_VICTORY_IDS.has(card.id):
			continue
		candidates.append(card)
	return candidates


func _is_catalog_card_before(first: CardDefinition, second: CardDefinition) -> bool:
	if first.card_type != second.card_type:
		return first.card_type.naturalnocasecmp_to(second.card_type) < 0
	if first.cost != second.cost:
		return first.cost < second.cost
	return first.card_name.naturalnocasecmp_to(second.card_name) < 0


func reset_turn_resources(resolve_durations: bool = true, arm_start_reactions: bool = true) -> void:
	var finishing_mission_extra := player.mission_extra_turn_active
	var starting_mission_extra := player.mission_extra_turn_pending
	var initializing_mission_extra := player.mission_extra_turn_start_pending
	player.reset_turn_resources()
	turn_flags.clear()
	if finishing_mission_extra:
		# In turn-based multiplayer, cleanup first resets the Mission buyer and
		# then the seat-pass path resets that same player a second time. Preserve
		# the no-buy marker across that initialization reset; the next cleanup
		# (with no transient marker) ends the extra turn normally.
		if initializing_mission_extra and resolve_durations and arm_start_reactions:
			player.mission_extra_turn_start_pending = false
			player.mission_extra_turn_active = true
			turn_flags["mission_no_buys"] = true
		else:
			player.mission_extra_turn_start_pending = false
			player.mission_extra_turn_active = false
	elif starting_mission_extra:
		player.mission_extra_turn_pending = false
		player.mission_extra_turn_active = true
		player.mission_extra_turn_start_pending = turn_based_enabled and players.size() > 1
		turn_flags["mission_no_buys"] = true
	# Event purchases are tracked per seat/turn for analytics and future event
	# restrictions; the event row itself remains available every turn.
	for key in event_purchases.keys():
		if str(key).begins_with("%d:" % active_player_index):
			event_purchases.erase(key)
	# Clerk reactions are offered after the turn-start draw.  The eligible set is
	# captured by draw_cards at the end of that draw, so cards drawn later in the
	# turn can never become start-turn reactions.
	turn_flags["start_turn_reactions_pending"] = arm_start_reactions
	turn_flags["start_turn_reactions_armed"] = arm_start_reactions
	turn_flags["start_turn_reaction_ids"] = []
	apply_turn_start_relics(player)
	if resolve_durations:
		_resolve_pending_durations()


func apply_turn_start_relics(target: PlayerState) -> void:
	if target.relics.has("gilded_purse"):
		target.add_coins(1)
	if target.relics.has("marching_orders") or target.relics.has("sunflower_metronome"):
		target.actions += 1
	if target.relics.has("market_writ"):
		target.buys += 1
	if target.relics.has("tricksters_die") and not market.is_empty():
		var discounted: CardDefinition = market[randi() % market.size()]
		target.turn_flags["die_discount_card_id"] = discounted.id
		print(
			"[Game] Trickster's Die discounts %s for %s"
			% [discounted.card_name, target.player_name]
		)


func _resolve_pending_durations() -> void:
	# Duration cards queue their "next turn" payloads here; they resolve once at
	# the start of the owner's next turn (twice with the Moonwake Mirror relic).
	if player.pending_duration_effects.is_empty():
		return
	var entries := player.pending_duration_effects.duplicate()
	player.pending_duration_effects.clear()
	var repetitions := 2 if player.relics.has("moonwake_mirror") else 1
	for entry in entries:
		var entry_repetitions := (
			1 if bool(entry.get("effect", {}).get("ignore_duration_mirror", false)) else repetitions
		)
		for _repeat_index in range(entry_repetitions):
			var duration_effect: Dictionary = entry.get("effect", {}).duplicate(true)
			duration_effect["_duration_resolving"] = true
			resolution_queue.push_back({
				"kind": "special",
				"effect": duration_effect,
				"source_card": entry.get("card"),
			})
		# Repeat durations remain armed while their source is still held in play.
		# A hand-size target paired with a repeating start-turn draw (Camp
		# Companion) must repeat as well, otherwise later turns fall back to five.
		# Re-queue only once per original payload, independent of mirror copies.
		var source_card: CardDefinition = entry.get("card") as CardDefinition
		var source_effect: Dictionary = entry.get("effect", {})
		var repeats_with_source := bool(source_effect.get("repeat", false)) or (
			str(source_effect.get("kind", "")) == "duration_hand_size"
			and _has_repeating_duration_effect(source_card)
		)
		if (
			repeats_with_source
			and source_card != null
			and player.play_area.has(source_card)
		):
			player.pending_duration_effects.append({
				"card": source_card,
				"effect": source_effect.duplicate(true),
			})
			if not player.duration_hold.has(source_card):
				player.duration_hold.append(source_card)
	print(
		"[Game] Resolve %d duration effect(s) for %s"
		% [entries.size() * repetitions, player.player_name]
	)
	_process_resolution_queue()
	check_idle_relics()


func get_turn_draw_count(target: PlayerState) -> int:
	var draw_count := BASE_TURN_DRAW_COUNT
	if target.relics.has("dawn_banner"):
		draw_count += 1
	# A duration may draw before the normal turn draw.  A hand-size modifier
	# raises the final hand target, rather than stacking a second full draw on
	# top of that early draw (Camp Companion should total six, not seven).
	var hand_size_bonus := int(target.turn_flags.get("duration_hand_size_bonus", 0))
	var early_duration_draws := int(target.turn_flags.get("duration_early_draws", 0))
	return maxi(0, draw_count + hand_size_bonus - early_duration_draws)


func relic_pool_includes_cooldown() -> bool:
	# Only tables with an end-turn cooldown (timed multiplayer) may offer the
	# cooldown-shortening relic; solo and turn-based tables have no timer.
	return multiplayer_enabled and not turn_based_enabled


func generate_relic_offer(target: PlayerState, allow_at_cap: bool = false) -> bool:
	if target == null:
		return false
	if not allow_at_cap and target.relics.size() >= RelicCatalog.RELIC_CAP:
		return false
	if not target.pending_relic_offer.is_empty():
		return false
	var available: Array[String] = []
	for relic_id in RelicCatalog.get_pool(relic_pool_includes_cooldown()):
		if not target.relics.has(relic_id):
			available.append(relic_id)
	if available.is_empty():
		return false
	available.shuffle()
	var offer_size := RelicCatalog.OFFER_SIZE
	if target.relics.has("patient_spider"):
		offer_size += 1
	var offer: Array[String] = []
	for index in range(mini(offer_size, available.size())):
		offer.append(available[index])
	target.pending_relic_offer = offer
	print("[Game] Relic offer for %s: %s" % [target.player_name, ", ".join(offer)])
	return true


func begin_relic_replacement(target: PlayerState) -> bool:
	# Replacement drafts are optional and start by asking which existing boon the
	# player is willing to trade.  Keep the old relic in place until a new one is
	# claimed so declining at either stage leaves the collection unchanged.
	if target == null or target.relics.is_empty():
		return false
	if not target.pending_relic_offer.is_empty() or not target.pending_relic_replacement.is_empty():
		return false
	target.pending_relic_replacement = {
		"stage": "choose_owned",
		"replaced_relic_id": "",
	}
	print("[Game] %s may replace one of their relics" % target.player_name)
	return true


func maybe_offer_turn_relic(target: PlayerState) -> void:
	# Every mode drafts on the same 7-turn cadence (turns 8, 15, 22, ...).
	if target.pending_choice != null:
		return
	if target.turn_number <= 1 or (target.turn_number - 1) % RELIC_TURN_INTERVAL != 0:
		return
	generate_relic_offer(target)


func choose_relic(target: PlayerState, relic_id: String) -> bool:
	if target == null:
		return false
	if not target.pending_relic_replacement.is_empty():
		return _choose_relic_replacement(target, relic_id)
	if relic_id.is_empty():
		# Declining the draft clears the offer without claiming anything.
		if target.pending_relic_offer.is_empty():
			return false
		target.pending_relic_offer.clear()
		print("[Game] %s declines the relic offer" % target.player_name)
		return true
	if not target.pending_relic_offer.has(relic_id):
		return false
	if target.relics.size() >= RelicCatalog.RELIC_CAP:
		target.pending_relic_offer.clear()
		return false
	target.pending_relic_offer.clear()
	_apply_relic_claim(target, relic_id)
	print("[Game] %s claims relic: %s" % [target.player_name, RelicCatalog.get_relic_name(relic_id)])
	return true


func _choose_relic_replacement(target: PlayerState, relic_id: String) -> bool:
	var stage := str(target.pending_relic_replacement.get("stage", ""))
	if stage == "choose_owned":
		if relic_id.is_empty():
			target.pending_relic_replacement.clear()
			print("[Game] %s declines the relic replacement" % target.player_name)
			return true
		if not target.relics.has(relic_id):
			return false
		target.pending_relic_replacement["stage"] = "draft"
		target.pending_relic_replacement["replaced_relic_id"] = relic_id
		if not generate_relic_offer(target, true):
			target.pending_relic_replacement.clear()
			return false
		print(
			"[Game] %s selected %s for relic replacement"
			% [target.player_name, RelicCatalog.get_relic_name(relic_id)]
		)
		return true
	if stage != "draft":
		return false
	if relic_id.is_empty():
		target.pending_relic_offer.clear()
		target.pending_relic_replacement.clear()
		print("[Game] %s declines the relic replacement draft" % target.player_name)
		return true
	if not target.pending_relic_offer.has(relic_id):
		return false
	var replaced_relic_id := str(target.pending_relic_replacement.get("replaced_relic_id", ""))
	if replaced_relic_id.is_empty() or not target.relics.has(replaced_relic_id):
		return false
	# Remove first, then append, so replacement can also be used at the cap while
	# preserving the invariant that one relic is exchanged for one relic.
	_remove_relic_claim(target, replaced_relic_id)
	target.relics.erase(replaced_relic_id)
	target.pending_relic_offer.clear()
	target.pending_relic_replacement.clear()
	_apply_relic_claim(target, relic_id)
	print("[Game] %s claims relic: %s" % [target.player_name, RelicCatalog.get_relic_name(relic_id)])
	return true


func _apply_relic_claim(target: PlayerState, relic_id: String) -> void:
	target.relics.append(relic_id)
	if relic_id == "swift_hourglass":
		target.game_cooldown_reduction += 1.0
	if relic_id == "culling_reliquary":
		# This relic is drafted during the current turn, so keep the payload in
		# duration bookkeeping until reset_turn_resources at the next turn start.
		target.pending_duration_effects.append({
			"card": null,
			"effect": {
				"kind": "relic_full_deck_trash",
				"amount": 5,
				"ignore_duration_mirror": true,
			},
		})


func _remove_relic_claim(target: PlayerState, relic_id: String) -> void:
	if relic_id == "swift_hourglass":
		target.game_cooldown_reduction = maxf(0.0, target.game_cooldown_reduction - 1.0)
	elif relic_id == "culling_reliquary":
		var remaining_duration: Array[Dictionary] = []
		for entry in target.pending_duration_effects:
			if str(entry.get("effect", {}).get("kind", "")) != "relic_full_deck_trash":
				remaining_duration.append(entry)
		target.pending_duration_effects = remaining_duration


func check_idle_relics() -> void:
	# Victory Levy: once per turn, when nothing in hand can be played, gain a
	# coin per victory card held. Checked after plays, choices, and turn draws.
	if not player.relics.has("victory_levy"):
		return
	if has_pending_choice() or cleanup_in_progress:
		return
	if bool(turn_flags.get("victory_levy_used", false)):
		return
	if player.hand.is_empty():
		return
	for card in player.hand:
		if card.card_type == "resource":
			return
		if card.card_type == "action" and player.actions > 0:
			return
	var victory_count := 0
	for card in player.hand:
		if card.card_type == "victory":
			victory_count += 1
	if victory_count <= 0:
		return
	turn_flags["victory_levy_used"] = true
	player.add_coins(victory_count)
	print(
		"[Game] Victory Levy grants %s %d coins"
		% [player.player_name, victory_count]
	)


func draw_cards(amount: int) -> int:
	var requested_amount := maxi(0, amount)
	if requested_amount > 0 and player.deck_minus_card_token:
		# The large -1 Card token modifies one draw instruction, not reveals or
		# draw-to-size loops that make repeated zero-card requests.
		requested_amount = maxi(0, requested_amount - 1)
		player.deck_minus_card_token = false
	var drawn_count := 0
	for _draw_index in range(requested_amount):
		if _maybe_request_shuffle_predraw(amount - drawn_count):
			# Seeker's Compass paused the draw with a choice; the resolver
			# draws the remaining cards once the player has picked.
			break
		var card := _take_top_card()
		if card == null:
			print("[Game] Draw stopped: no cards available (%d/%d drawn)" % [drawn_count, amount])
			break
		player.hand.append(card)
		drawn_count += 1
		print("[Game] Draw: %s" % card.card_name)
	if (
		bool(turn_flags.get("start_turn_reactions_pending", false))
		and bool(turn_flags.get("start_turn_reactions_armed", false))
		and not has_pending_choice()
	):
		_arm_start_turn_reactions()
	return drawn_count


func _arm_start_turn_reactions() -> void:
	if not bool(turn_flags.get("start_turn_reactions_pending", false)):
		return
	var start_reaction_ids: Array[String] = []
	for card in player.hand:
		for effect in card.special_effects:
			if str(effect.get("trigger", "")) == "start_turn":
				start_reaction_ids.append(card.id)
				break
	turn_flags["start_turn_reaction_ids"] = start_reaction_ids
	turn_flags.erase("start_turn_reactions_pending")
	_play_start_turn_reactions()


func _play_start_turn_reactions() -> void:
	# Offer one eligible reaction at a time. After it resolves, the queue returns
	# here so the player can play another copy or decline.
	var eligible_ids: Array = turn_flags.get("start_turn_reaction_ids", [])
	var clerks: Array[CardDefinition] = []
	for card in player.hand:
		if not eligible_ids.has(card.id):
			continue
		for effect in card.special_effects:
			if str(effect.get("trigger", "")) == "start_turn":
				clerks.append(card)
				break
	if clerks.is_empty():
		turn_flags.erase("start_turn_reactions_pending")
		turn_flags.erase("start_turn_reaction_ids")
		return
	_request_zone_choice(
		clerks,
		"You may play a start-turn reaction from your hand.",
		0,
		1,
		"start_turn_reaction",
		"PLAY",
		"DONE"
	)


func _maybe_request_shuffle_predraw(remaining: int) -> bool:
	if remaining <= 0 or has_pending_choice():
		return false
	if not player.relics.has("seekers_compass"):
		return false
	if not player.draw_pile.is_empty() or player.discard_pile.is_empty():
		return false
	player.draw_pile.append_array(player.discard_pile)
	player.discard_pile.clear()
	player.draw_pile.shuffle()
	print(
		"[Game] Seeker's Compass: shuffle discard into %s draw pile (%d cards)"
		% [player.player_name, player.draw_pile.size()]
	)
	var candidates: Array[CardDefinition] = []
	candidates.append_array(player.draw_pile)
	_request_zone_choice(
		candidates,
		"Seeker's Compass: choose up to 2 cards to draw first.",
		0,
		2,
		"relic_predraw",
		"DRAW THESE",
		"JUST DRAW",
		{"remaining": remaining}
	)
	return has_pending_choice()


func is_action_phase() -> bool:
	return player.turn_phase == TURN_PHASE_ACTION


func is_buy_phase() -> bool:
	return player.turn_phase == TURN_PHASE_BUY


func has_playable_action() -> bool:
	# A hand holds a playable action only while the player still has actions to
	# spend and at least one action card left to play.
	if player.actions <= 0:
		return false
	for card in player.hand:
		if card.card_type == "action" or _is_inherited_estate(card):
			return true
	return false


func can_play_in_current_phase(card: CardDefinition) -> bool:
	# Phase gate for the interactive (hand-click) play path. Effect-driven plays
	# such as Throne Room / Tiara go through _play_card_internal and bypass this.
	if card == null:
		return false
	if card.card_type == "action" or _is_inherited_estate(card):
		return is_action_phase()
	if card_has_type(card, "resource"):
		return is_buy_phase() and not bool(turn_flags.get("event_bought", false))
	return false


func evaluate_auto_phase() -> void:
	# Slip into the buy phase the moment the action phase has nothing left to do:
	# no playable action remains. Never runs backwards, and never mid-choice.
	if player.turn_phase != TURN_PHASE_ACTION:
		return
	if has_pending_choice() or cleanup_in_progress:
		return
	if not has_playable_action():
		player.turn_phase = TURN_PHASE_BUY


func begin_turn_phase() -> void:
	# Called at the start of a turn once the hand is in place: open on the action
	# phase, then auto-advance if there is nothing to do there.
	player.turn_phase = TURN_PHASE_ACTION
	evaluate_auto_phase()


func end_action_phase() -> bool:
	# Manual transition from the action phase to the buy phase.
	if player.turn_phase != TURN_PHASE_ACTION:
		return false
	player.turn_phase = TURN_PHASE_BUY
	print("[Game] %s ends the action phase" % player.player_name)
	return true


func play_card(card: CardDefinition) -> bool:
	return _play_card_internal(card, true, 1)


func _is_inherited_estate(card: CardDefinition) -> bool:
	return card != null and card.id == "homestead" and not player.inheritance_card_id.is_empty() and card_catalog.has(player.inheritance_card_id)


func _play_card_internal(
	card: CardDefinition,
	spend_action: bool,
	repetitions: int
) -> bool:
	if card == null or (not is_card_playable(card) and not _is_inherited_estate(card)) or has_pending_choice():
		return false
	if spend_action and card_has_type(card, "resource") and bool(turn_flags.get("event_bought", false)):
		# Buying an Event ends Treasure plays for the rest of that Buy phase.
		return false
	var hand_index := player.hand.find(card)
	if hand_index == -1:
		return false
	if (card.card_type == "action" or _is_inherited_estate(card)) and spend_action:
		if player.actions <= 0:
			return false
		player.actions -= 1

	var total_repetitions := repetitions

	player.hand.remove_at(hand_index)
	player.play_area.append(card)
	player.register_play_display(card, total_repetitions)
	# Reserve/Tavern cards leave the play area immediately after being played.
	# Older data encoded this as a reserve_store special effect; canonical
	# Adventures data also marks Coin of the Realm and Distant Lands via the
	# reserve flag alone, so support both shapes.
	if card.is_reserve_card():
		player.play_area.erase(card)
		player.store_reserve(card)
	if _is_inherited_estate(card):
		_prepend_card_resolutions(card_catalog[player.inheritance_card_id], total_repetitions)
	else:
		_prepend_card_resolutions(card, total_repetitions)
	_process_resolution_queue()
	check_idle_relics()
	print("[Game] Play card: %s" % card.card_name)
	return true


func _prepend_card_resolutions(card: CardDefinition, repetitions: int) -> void:
	_register_duration_effects(card, repetitions)
	_register_turn_play_triggers(card, repetitions)
	var sequence: Array[Dictionary] = []
	for _repeat_index in range(repetitions):
		sequence.append({"kind": "card_base", "card": card})
		for effect in card.special_effects:
			if str(effect.get("trigger", "play")) not in ["play", "attack"]:
				continue
			sequence.append({
				"kind": "special",
				"effect": effect.duplicate(true),
				"source_card": card,
			})
	for index in range(sequence.size() - 1, -1, -1):
		resolution_queue.push_front(sequence[index])


func _register_turn_play_triggers(card: CardDefinition, repetitions: int) -> void:
	# Persistent this-turn effects are registered per resolution, not per
	# physical card.  A Tiara replaying Hoard/Collection twice therefore creates
	# two independent trigger entries, which remain valid even if the source is
	# later trashed during this turn.
	if card == null or repetitions <= 0:
		return
	var gain_triggers: Array = turn_flags.get("turn_gain_triggers", [])
	var buy_triggers: Array = turn_flags.get("turn_buy_triggers", [])
	for _repeat_index in range(repetitions):
		for effect in card.special_effects:
			var trigger := str(effect.get("trigger", ""))
			if str(effect.get("trigger_scope", "self")) != "in_play":
				continue
			var entry := {
				"effect": effect.duplicate(true),
				"source_card": card,
			}
			if trigger == "gain":
				gain_triggers.append(entry)
			elif trigger == "buy":
				buy_triggers.append(entry)
	turn_flags["turn_gain_triggers"] = gain_triggers
	turn_flags["turn_buy_triggers"] = buy_triggers


func _register_duration_effects(card: CardDefinition, repetitions: int) -> void:
	# A card with any "next_turn" effects stays in play through the next cleanup
	# and queues one payload per repetition (a replayed duration pays out twice).
	var payloads: Array[Dictionary] = []
	for effect in card.special_effects:
		var effect_trigger := str(effect.get("trigger", "play"))
		if effect_trigger in ["next_turn", "future", "duration"] or bool(effect.get("duration", false)):
			payloads.append(effect)
			if str(effect.get("kind", "")) == "attack_immunity":
				# The guard begins as soon as the duration is played, then its
				# queued payload refreshes it for the following turn.
				_grant_timed_attack_immunity(effect)
	if payloads.is_empty():
		return
	player.duration_hold.append(card)
	for _repeat_index in range(repetitions):
		for effect in payloads:
			player.pending_duration_effects.append({
				"card": card,
				"effect": effect.duplicate(true),
			})
	print("[Game] %s stays in play until next turn" % card.card_name)


func _prepend_triggered_effects(
	card: CardDefinition,
	trigger: String,
	context: Dictionary = {}
) -> void:
	var sequence: Array[Dictionary] = []
	for effect in card.special_effects:
		if str(effect.get("trigger", "play")) != trigger:
			continue
		if str(effect.get("trigger_scope", "self")) == "in_play":
			continue
		if bool(effect.get("once", false)) and trigger == "gain":
			var once_key := "_gain_once_chain:%s:%s" % [card.id, str(context.get("card_id", ""))]
			if bool(turn_flags.get(once_key, false)):
				continue
			turn_flags[once_key] = true
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
	var return_index := int(turn_flags.get("_gain_return_player_index", -1))
	for reaction_card in player.hand:
		for effect in reaction_card.special_effects:
			if str(effect.get("trigger", "")) != "gain_reaction":
				continue
			if str(effect.get("card_id", "")) == gained_card.id:
				continue
			var runtime_effect := effect.duplicate(true)
			runtime_effect["_event_gained_card"] = gained_card
			runtime_effect["_event_destination"] = destination
			if return_index >= 0:
				runtime_effect["_event_return_player_index"] = return_index
			reactions.append({
				"kind": "special",
				"effect": runtime_effect,
				"source_card": reaction_card,
			})
	for index in range(reactions.size() - 1, -1, -1):
		resolution_queue.push_front(reactions[index])


func _prepend_gain_play_triggers(gained_card: CardDefinition, destination: String) -> void:
	# Played cards such as Mint, Hoard, and Collection watch later gains. Entries
	# are registered once per play and survive if the source leaves play later.
	var triggers: Array[Dictionary] = []
	var return_index := int(turn_flags.get("_gain_return_player_index", -1))
	for registered in turn_flags.get("turn_gain_triggers", []):
		var runtime_effect: Dictionary = registered.get("effect", {}).duplicate(true)
		runtime_effect["_event_gained_card"] = gained_card
		runtime_effect["_event_destination"] = destination
		if return_index >= 0:
			runtime_effect["_event_return_player_index"] = return_index
		triggers.append({
			"kind": "special",
			"effect": runtime_effect,
			"source_card": registered.get("source_card"),
		})
	for index in range(triggers.size() - 1, -1, -1):
		resolution_queue.push_front(triggers[index])
	# Reserve gain watchers are derived from the persistent mat itself, not
	# transient turn flags. This survives turn changes and network snapshots.
	var reserve_triggers: Array[Dictionary] = []
	for watched_card in player.reserve_mat.duplicate():
		for raw_effect in watched_card.special_effects:
			if str(raw_effect.get("kind", "")) != "reserve_duplicate_gain":
				continue
			if get_non_buy_cost(gained_card) > int(raw_effect.get("max_cost", 99)):
				continue
			var watched_effect: Dictionary = raw_effect.duplicate(true)
			watched_effect["_event_gained_card"] = gained_card
			watched_effect["_event_destination"] = destination
			reserve_triggers.append({"kind": "special", "effect": watched_effect, "source_card": watched_card})
			break
	for index in range(reserve_triggers.size() - 1, -1, -1):
		resolution_queue.push_front(reserve_triggers[index])


func _prepend_buy_play_triggers(gained_card: CardDefinition) -> void:
	var triggers: Array[Dictionary] = []
	for registered in turn_flags.get("turn_buy_triggers", []):
		var runtime_effect: Dictionary = registered.get("effect", {}).duplicate(true)
		runtime_effect["_event_gained_card"] = gained_card
		triggers.append({
			"kind": "special",
			"effect": runtime_effect,
			"source_card": registered.get("source_card"),
		})
	for index in range(triggers.size() - 1, -1, -1):
		resolution_queue.push_front(triggers[index])


func _process_resolution_queue() -> void:
	while not has_pending_choice() and not resolution_queue.is_empty():
		var entry: Dictionary = resolution_queue.pop_front()
		match str(entry.get("kind", "")):
			"card_base":
				_apply_card_base(entry["card"])
			"event_base":
				_apply_event_base(entry["card"])
			"special":
				_resolve_special_effect(entry["effect"], entry["source_card"])
			"exact_gain_request":
				_request_exact_supply_choice(
					int(entry.get("cost", 0)),
					str(entry.get("destination", "discard")),
					str(entry.get("exclude_card_id", "")),
					str(entry.get("prompt", "Choose a card to gain."))
				)
			"target_gain":
				var target_index := int(entry.get("target_index", -1))
				if target_index >= 0 and target_index < players.size():
					_gain_card_by_id_for_player(
						str(entry.get("card_id", "")),
						str(entry.get("destination", "discard")),
						players[target_index]
					)
			"start_turn_reactions":
				_play_start_turn_reactions()
	if resolution_queue.is_empty() and not has_pending_choice():
		for key in turn_flags.keys().duplicate():
			if str(key).begins_with("_gain_once_chain:"):
				turn_flags.erase(key)


func _apply_card_base(card: CardDefinition) -> void:
	_apply_pile_token_bonus(card)
	player.add_coins(_card_coin_value(card) + card.gain_coins)
	player.actions += card.gain_actions
	if card.card_type == "action":
		for permanent in player.play_area:
			if permanent.id == "champion":
				player.actions += 1
	player.buys += card.gain_buys
	if card.draw_cards > 0:
		draw_cards(card.draw_cards)
	if card_has_type(card, "resource"):
		_apply_resource_bonus(card)


func _apply_event_base(card: CardDefinition) -> void:
	if card == null:
		return
	player.add_coins(card.coin_value + card.gain_coins)
	player.actions += card.gain_actions
	player.buys += card.gain_buys
	if card.draw_cards > 0:
		draw_cards(card.draw_cards)


func _apply_pile_token_bonus(card: CardDefinition) -> void:
	if card == null:
		return
	for token_id in ["action", "buy", "card", "coin"]:
		if get_active_player_supply_token_card(token_id) != card.id:
			continue
		match token_id:
			"action":
				player.actions += 1
			"buy":
				player.buys += 1
			"card":
				draw_cards(1)
			"coin":
				player.add_coins(1)


func _apply_resource_bonus(card: CardDefinition) -> void:
	if not turn_flags.has("resource_bonus"):
		return
	var bonus: Dictionary = turn_flags["resource_bonus"]
	if bool(bonus.get("used", false)) or str(bonus.get("card_id", "")) != card.id:
		return
	player.add_coins(int(bonus.get("amount", 0)))
	bonus["used"] = true
	turn_flags["resource_bonus"] = bonus


func _queue_effect_list(effects: Variant, source_card: CardDefinition) -> void:
	if typeof(effects) != TYPE_ARRAY:
		return
	var entries: Array[Dictionary] = []
	for raw_effect in effects:
		if typeof(raw_effect) != TYPE_DICTIONARY:
			continue
		entries.append({
			"kind": "special",
			"effect": raw_effect.duplicate(true),
			"source_card": source_card,
		})
	for index in range(entries.size() - 1, -1, -1):
		resolution_queue.push_front(entries[index])


func _reserve_candidates(effect: Dictionary) -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	var requested_id := str(effect.get("card_id", ""))
	var requested_type := str(effect.get("card_type", ""))
	for card in player.reserve_mat:
		if not requested_id.is_empty() and card.id != requested_id:
			continue
		if not requested_type.is_empty() and not card_has_type(card, requested_type):
			continue
		candidates.append(card)
	return candidates


func _request_reserve_choice(effect: Dictionary) -> void:
	var candidates := _reserve_candidates(effect)
	var optional := bool(effect.get("optional", true))
	var minimum := 1 if not optional and not candidates.is_empty() else 0
	var choice := _new_choice(
		str(effect.get("prompt", "Choose a card to call from your reserve mat.")),
		minimum,
		mini(1, candidates.size()),
		"call_reserve",
		str(effect.get("confirm_text", "CALL")),
		str(effect.get("skip_text", "LEAVE THEM")),
		{"call_effect": effect.duplicate(true)}
	)
	for index in range(candidates.size()):
		choice.add_candidate("reserve:%d:%d" % [choice.id, index], candidates[index])
	if not candidates.is_empty() or optional:
		_request_choice(choice)


func call_reserve_card(card: CardDefinition) -> bool:
	"""Authoritatively call a card from the active player's reserve mat."""
	if card == null or has_pending_choice() or not player.call_reserve(card):
		return false
	player.play_area.append(card)
	player.register_play_display(card, 1)
	_prepend_called_card_resolutions(card)
	_process_resolution_queue()
	return true


func call_reserve_card_by_id(card_id: String) -> bool:
	for card in player.reserve_mat:
		if card.id == card_id:
			return call_reserve_card(card)
	return false


func call_tavern_card(card: CardDefinition) -> bool:
	return call_reserve_card(card)


func call_tavern_card_by_id(card_id: String) -> bool:
	return call_reserve_card_by_id(card_id)


func _prepend_called_card_resolutions(card: CardDefinition) -> void:
	if card == null:
		return
	var call_effects: Array[Dictionary] = []
	var has_explicit_call := false
	for effect in card.special_effects:
		var trigger := str(effect.get("trigger", "play"))
		if trigger == "call":
			has_explicit_call = true
			call_effects.append(effect)
	# Coin of the Realm's call ability is printed as reserve text in the
	# canonical data (without a separate special_effect record).
	if card.id == "coin_of_the_realm" and not has_explicit_call:
		call_effects.append({"kind": "gain_actions", "amount": 2, "trigger": "call"})
	if not has_explicit_call:
		for effect in card.special_effects:
			if (
				str(effect.get("trigger", "play")) == "play"
				and str(effect.get("kind", "")) not in ["reserve_store", "reserve_duplicate_gain", "distant_lands_score"]
			):
				call_effects.append(effect)
	# Calling a Reserve card only resolves the text below its dividing line;
	# bonuses printed above it happened when the card was first played.  Legacy
	# data may opt into replaying the base with `call_replay_base`.
	var sequence: Array[Dictionary] = []
	if bool(card.metadata.get("call_replay_base", false)):
		sequence.append({"kind": "card_base", "card": card})
	for effect in call_effects:
		sequence.append({
			"kind": "special",
			"effect": effect.duplicate(true),
			"source_card": card,
		})
	for index in range(sequence.size() - 1, -1, -1):
		resolution_queue.push_front(sequence[index])


func _resolve_special_effect(effect: Dictionary, source_card: CardDefinition) -> void:
	var kind := str(effect.get("kind", ""))
	# Compact Adventures data often describes a future payload by its fields
	# instead of a bespoke kind.  Normalize those records before dispatch while
	# retaining the original effect for callers that inspect it.
	if kind.is_empty():
		if effect.has("draw_cards") or effect.has("gain_actions") or effect.has("gain_buys") or effect.has("gain_coins"):
			kind = "turn_start_bonus" if bool(effect.get("_duration_resolving", false)) or str(effect.get("trigger", "")) in ["next_turn", "future", "duration"] else "card_base"
		elif effect.has("draw"):
			kind = "draw"
	if kind in ["draw", "draw_cards"]:
		draw_cards(int(effect.get("amount", effect.get("draw", effect.get("draw_cards", 0)))))
		return
	if kind in ["gain_coins", "coins"]:
		player.add_coins(int(effect.get("amount", effect.get("coins", 0))))
		return
	if kind in ["gain_actions", "actions"]:
		player.actions += int(effect.get("amount", effect.get("actions", 0)))
		return
	if kind in ["gain_buys", "buys"]:
		player.buys += int(effect.get("amount", effect.get("buys", 0)))
		return
	if kind in ["duration", "future", "duration_effect"]:
		if bool(effect.get("_duration_resolving", false)):
			_queue_effect_list(effect.get("effects", []), source_card)
		else:
			player.pending_duration_effects.append({"card": source_card, "effect": effect.duplicate(true)})
		return
	# Reserve aliases without an explicit `trigger: call` are registrations, not
	# immediate effects.  The card is already on the mat after reserve_store and
	# its payload is replayed when the owner calls it later.
	if (
		source_card != null
		and player.reserve_mat.has(source_card)
		and kind.begins_with("reserve_")
		and kind != "reserve_store"
		and kind != "reserve_call"
		and kind != "reserve_duplicate_gain"
		and not effect.has("_event_gained_card")
		and str(effect.get("trigger", "play")) != "call"
	):
		var reserve_effects: Array = turn_flags.get("reserve_call_effects", [])
		reserve_effects.append({"card": source_card, "effect": effect.duplicate(true)})
		turn_flags["reserve_call_effects"] = reserve_effects
		return
	match kind:
		"choose_one_of_standard":
			_request_mode_choice(
				source_card,
				str(effect.get("prompt", "Choose one effect.")),
				effect.get("modes", []),
				"standard_mode",
				{"source_card": source_card}
			)
		"gain_card_hand":
			_gain_card_by_id(str(effect.get("card_id", "")), "hand")
		"gain_card_from_supply":
			_request_supply_choice(
				int(effect.get("max_cost", effect.get("cost", 99))),
				str(effect.get("destination", "discard")),
				str(effect.get("card_type", "")),
				str(effect.get("prompt", "Choose a card to gain."))
			)
		"reserve_store", "reserve_to_mat":
			if source_card != null:
				player.play_area.erase(source_card)
				player.store_reserve(source_card)
				turn_flags["reserve_stored_%s" % source_card.id] = true
		"call_reserve":
			_request_reserve_choice(effect)
		"reserve_call":
			_request_reserve_choice(effect)
		"reserve_duplicate_gain":
			var duplicated_gain: CardDefinition = effect.get("_event_gained_card")
			if duplicated_gain == null and source_card != null and player.reserve_mat.has(source_card):
				# The persistent reserve mat is the watcher; no transient registration.
				return
			if duplicated_gain != null:
				# Earlier gains may have queued a prompt before this Seal was called.
				# Never surface an unusable stale prompt once its source left the mat.
				if source_card == null or not player.reserve_mat.has(source_card):
					return
				_request_optional_source_choice(
					source_card,
					"Call this to gain a copy of %s?" % duplicated_gain.card_name,
					"reserve_duplicate_gain",
					"CALL & COPY",
					"KEEP STORED",
					{
						"gained_card": duplicated_gain,
						"destination": str(effect.get("_event_destination", effect.get("destination", "discard"))),
					}
				)
			else:
				# When called directly, offer a qualifying card to copy.  This keeps
				# the alias useful for reserve rows that are not gain watchers.
				_request_filtered_supply_choice(
					{"max_cost": int(effect.get("max_cost", 99))},
					str(effect.get("destination", "discard")),
					str(effect.get("prompt", "Choose a card to copy."))
				)
		"reserve_redraw":
			_request_zone_choice(player.hand, "Discard your hand, then draw 5 cards.", player.hand.size(), player.hand.size(), "discard_hand_draw", "REDRAW")
		"reserve_remodel":
			_request_zone_choice(player.hand, "Choose a card to transform.", mini(1, player.hand.size()), mini(1, player.hand.size()), "remodel", "TRANSFORM", "SKIP", _hand_trash_choice_context({"cost_delta": int(effect.get("cost_delta", 1))}))
		"reserve_replay":
			var reserve_actions: Array[CardDefinition] = []
			for hand_card in player.hand:
				if hand_card.card_type == "action":
					reserve_actions.append(hand_card)
			_request_zone_choice(reserve_actions, "Choose an action to replay.", 0, mini(1, reserve_actions.size()), "replay_action", "REPLAY", "SKIP", {"repetitions": int(effect.get("repetitions", 2))})
		"reserve_trash":
			var reserve_trash_limit := mini(int(effect.get("amount", 1)), player.hand.size())
			_request_zone_choice(player.hand, "Choose cards to trash.", 0 if not bool(effect.get("required", false)) else reserve_trash_limit, reserve_trash_limit, "trash_hand", "TRASH", "SKIP")
		"start_journey", "journey_start", "journey":
			var journey_id := str(effect.get("journey_id", effect.get("id", "journey")))
			player.set_journey(journey_id, true)
			if effect.has("effects"):
				_queue_effect_list(effect.get("effects", []), source_card)
		"journey_flip":
			var flip_id := str(effect.get("journey_id", effect.get("id", "journey")))
			var flipped_active := not player.is_journey_active(flip_id)
			player.set_journey(flip_id, flipped_active)
			var flip_effects = effect.get("on_active", []) if flipped_active else effect.get("on_inactive", [])
			_queue_effect_list(flip_effects, source_card)
		"journey_conditional":
			var conditional_id := str(effect.get("journey_id", effect.get("id", "journey")))
			var branch = effect.get("if_active", []) if player.is_journey_active(conditional_id) else effect.get("if_inactive", [])
			_queue_effect_list(branch, source_card)
		"journey_attack":
			if player.is_journey_active(str(effect.get("journey_id", "journey"))):
				_resolve_attack(effect.get("attack", effect), source_card)
		"artificer":
			# Artificer discards any number, then gains one exact-cost card onto
			# the deck for each card discarded.  Keep this as a normal zone choice
			# so a zero-card choice can resolve without manufacturing a gain.
			_request_zone_choice(
				player.hand,
				"Discard any number of cards for an exact-cost gain.",
				0,
				player.hand.size(),
				"artificer_discard",
				"DISCARD & GAIN",
				"DISCARD NONE"
			)
		"magpie_reveal":
			_resolve_magpie_reveal()
		"messenger_first_buy":
			# Each played Messenger watches the first buy made this turn.  The
			# watcher is consumed in buy_card, after the purchased card resolves.
			turn_flags["messenger_first_buy_count"] = int(turn_flags.get("messenger_first_buy_count", 0)) + 1
		"messenger_gain":
			_request_messenger_gain_choice(effect)
		"mission":
			# Mission grants a second turn after cleanup; persistent state carries
			# the marker through reset_turn_resources and the turn-based seat pass.
			player.mission_extra_turn_pending = true
		"storyteller":
			var storyteller_treasures: Array[CardDefinition] = []
			for hand_card in player.hand:
				if card_has_type(hand_card, "resource"):
					storyteller_treasures.append(hand_card)
			if storyteller_treasures.is_empty():
				_resolve_storyteller([], source_card)
			else:
				_request_zone_choice(
					storyteller_treasures,
					"Play up to 3 Treasures from your hand.",
					0,
					mini(3, storyteller_treasures.size()),
					"storyteller_play_treasures",
					"PLAY TREASURES",
					"PLAY NONE",
					{"source_card": source_card}
				)
		"pilgrimage":
			var pilgrimage_id := str(effect.get("journey_id", "journey"))
			var pilgrimage_active := not player.is_journey_active(pilgrimage_id)
			player.set_journey(pilgrimage_id, pilgrimage_active)
			if not pilgrimage_active:
				return
			var pilgrimage_cards: Array[CardDefinition] = []
			var seen_pilgrimage_ids: Dictionary = {}
			for in_play in player.play_area:
				if not seen_pilgrimage_ids.has(in_play.id):
					seen_pilgrimage_ids[in_play.id] = true
					pilgrimage_cards.append(in_play)
			if not pilgrimage_cards.is_empty():
				_request_zone_choice(
					pilgrimage_cards,
					"Choose up to 3 differently named cards to gain copies of.",
					0,
					mini(3, pilgrimage_cards.size()),
					"pilgrimage_cards",
					"GAIN COPIES",
					"GAIN NONE"
				)
		"quest":
			_request_zone_choice(
				player.hand,
				"Discard an Attack, two Curses, or six cards to gain a Gold.",
				0,
				mini(6, player.hand.size()),
				"quest_discard",
				"DISCARD FOR GOLD",
				"DECLINE"
			)
		"raid":
			var silver_count := 0
			for in_play in player.play_area:
				if in_play.id == "silver_leaf":
					silver_count += 1
			for _silver_index in range(silver_count):
				_gain_card_by_id("silver_leaf", "discard")
			_resolve_attack({"mode": "raid"}, source_card)
		"inheritance":
			_request_inheritance_choice(effect)
		"bonfire":
			var bonfire_cards: Array[CardDefinition] = []
			for in_play in player.play_area:
				bonfire_cards.append(in_play)
			_request_zone_choice(
				bonfire_cards,
				"Trash up to 2 cards from your play area.",
				0,
				mini(2, bonfire_cards.size()),
				"bonfire_trash",
				"TRASH",
				"TRASH NONE"
			)
		"trash_from_play":
			var trash_play_cards: Array[CardDefinition] = player.play_area.duplicate()
			_request_zone_choice(
				trash_play_cards,
				"Trash up to %d cards from your play area." % int(effect.get("amount", 2)),
				0,
				mini(int(effect.get("amount", 2)), trash_play_cards.size()),
				"bonfire_trash",
				"TRASH",
				"TRASH NONE"
			)
		"trade":
			var trade_limit := mini(int(effect.get("amount", 2)), player.hand.size())
			_request_zone_choice(player.hand, "Trash up to %d cards for Silver." % trade_limit, 0, trade_limit, "trade_trash", "TRASH", "TRASH NONE")
		"next_hand_draw_bonus":
			player.next_hand_draw_bonus += int(effect.get("amount", 0))
		"teacher_token":
			_request_mode_choice(
				source_card,
				"Choose which Teacher token to move.",
				[
					{"id": "card", "label": "+1 Card token"},
					{"id": "action", "label": "+1 Action token"},
					{"id": "buy", "label": "+1 Buy token"},
					{"id": "coin", "label": "+1 Coin token"},
				],
				"teacher_token_choice"
			)
		"champion":
			# Champion's ongoing protection and action bonus are derived from its
			# permanent presence in play; no immediate payload is required.
			pass
		"wine_merchant_call":
			# Wine Merchant is discarded from the Tavern mat at Buy-phase end if
			# the player still has two coins.  The cleanup pass handles the actual
			# removal; this marker makes the rule data-driven.
			if source_card != null:
				var wine_effects: Array = turn_flags.get("reserve_cleanup_effects", [])
				wine_effects.append({"card": source_card, "minimum_coins": 2})
				turn_flags["reserve_cleanup_effects"] = wine_effects
		"duration_marker":
			if source_card != null and not bool(effect.get("_duration_resolving", false)) and not player.duration_hold.has(source_card):
				player.duration_hold.append(source_card)
		"supply_tokens", "supply_token", "pile_token", "place_pile_token":
			_resolve_supply_token_effect(effect, source_card)
		"move_token_to_pile", "choose_supply_pile", "move_player_supply_token", "move_token", "token_move":
			_request_pile_token_choice(effect)
		"player_token", "add_player_token", "gain_player_token":
			var player_token_id := str(effect.get("token", effect.get("token_id", ""))).to_lower()
			var token_targets: Array[PlayerState] = [player]
			if str(effect.get("trigger", "")) == "attack":
				token_targets = _get_attack_targets()
			for token_target in token_targets:
				if player_token_id in ["-1_card", "minus_1_card", "minus_card", "deck_minus_card", "-card"]:
					token_target.put_deck_minus_card_token()
				elif player_token_id in ["-1_coin", "minus_1_coin", "minus_coin", "coin_minus", "-coin"]:
					token_target.put_coin_minus_token()
				else:
					token_target.add_player_token(player_token_id, int(effect.get("amount", 1)))
		"remove_player_token", "spend_player_token":
			player.remove_player_token(str(effect.get("token", effect.get("token_id", ""))), int(effect.get("amount", 1)))
		"deck_minus_card", "minus_card", "minus_one_card", "place_minus_card_token":
			player.put_deck_minus_card_token()
		"coin_minus", "minus_coin", "minus_one_coin", "place_minus_coin_token":
			player.put_coin_minus_token()
		"toggle_journey", "journey_token_flip":
			player.toggle_journey(str(effect.get("journey_id", "journey")))
		"coin_mat_deposit", "deposit_coin_mat":
			var deposit_candidates: Array[CardDefinition] = []
			var deposit_id := str(effect.get("card_id", "pebble_coin"))
			for hand_card in player.hand:
				if hand_card.id == deposit_id:
					deposit_candidates.append(hand_card)
			if deposit_candidates.is_empty():
				return
			_request_zone_choice(deposit_candidates, "Put a Copper on your Tavern mat.", 1, 1, "coin_mat_deposit", "DEPOSIT")
		"coin_mat_take", "take_coin_mat":
			var take_amount := mini(player.coin_mat, int(effect.get("amount", player.coin_mat)))
			take_amount = maxi(0, take_amount)
			player.coin_mat -= take_amount
			player.add_coins(take_amount)
		"traveller_upgrade", "upgrade_traveller":
			_request_optional_source_choice(
				source_card,
				"Retire %s to take its next training card?" % source_card.card_name,
				"traveller_upgrade",
				"RETIRE",
				"KEEP",
				{"effect": effect.duplicate(true)}
			)
		"duration_hand_size":
			if bool(effect.get("_duration_resolving", false)):
				player.turn_flags["duration_hand_size_bonus"] = (
					int(player.turn_flags.get("duration_hand_size_bonus", 0))
					+ int(effect.get("amount", 0))
				)
			else:
				player.pending_duration_effects.append({"card": source_card, "effect": effect.duplicate(true)})
		"duration_set_aside":
			if bool(effect.get("_duration_resolving", false)):
				var set_aside_amount := int(effect.get("amount", 1))
				if set_aside_amount > 0:
					_request_zone_choice(
						player.hand,
						str(effect.get("prompt", "Set a card aside until your next turn.")),
						0,
						mini(set_aside_amount, player.hand.size()),
						"set_aside_hand",
						"SET ASIDE",
						"SKIP"
					)
			else:
				player.pending_duration_effects.append({"card": source_card, "effect": effect.duplicate(true)})
		"distant_lands_score":
			# End-game-only metadata. Scoring reads this effect directly; it must
			# never create an in-game token when a card is resolved incidentally.
			pass
		"miser_tokens":
			player.add_player_token(str(effect.get("token", effect.get("token_id", kind))), int(effect.get("amount", 1)))
		"miser_spend_tokens":
			var spend_count := player.coin_mat
			player.coin_mat = 0
			player.add_coins(spend_count * int(effect.get("value", effect.get("amount", 1))))
		"magpie_cache":
			if int(turn_flags.get("last_revealed_resource_count", 0)) >= 2:
				player.add_coins(int(effect.get("amount", 1)))
		"storyteller_discard_for_coins":
			_request_zone_choice(player.hand, "Discard any number of cards for coins.", 0, player.hand.size(), "storyteller_discard_for_coins", "TELL STORY", "KEEP HAND")
		"raze":
			_begin_raze(source_card)
		"register_buy_attack":
			var buy_attacks: Array = turn_flags.get("buy_attacks", [])
			buy_attacks.append(effect.get("attack", {}).duplicate(true))
			turn_flags["buy_attacks"] = buy_attacks
		"reaction":
			# Caravan Guard's reaction is a hand-play opportunity when another
			# player attacks.  The attack dispatcher checks the presence of this
			# marker; no immediate effect is needed while simply playing the card.
			turn_flags["attack_reaction"] = true
		"travelling_fair":
			turn_flags["travelling_fair"] = true
		"plan_buy_trash":
			if not player.hand.is_empty():
				_request_zone_choice(
					player.hand,
					"You may trash a card from your hand.",
					0,
					1,
					"plan_buy_trash",
					"TRASH",
					"SKIP",
					{
						"expansion_token": "trash",
						"bought_card_id": str(effect.get("bought_card_id", "")),
						"ui_choice_kind": "trash_from_hand",
						"ui_source_zone": "hand",
					}
				)
		"reveal_resources_to_hand":
			_reveal_resources_to_hand(int(effect.get("amount", 1)))
		"each_other_player_draws":
			_each_other_player_draws(int(effect.get("amount", 1)))
		"vault":
			if player.hand.is_empty():
				_vault_other_players()
			else:
				_request_zone_choice(
					player.hand,
					"You may discard any number of cards for 1 coin each.",
					0,
					player.hand.size(),
					"vault_discard",
					"DISCARD",
					"KEEP ALL"
				)
		"bishop":
			var bishop_candidates := player.hand.duplicate()
			if bishop_candidates.is_empty():
				_bishop_other_players()
			else:
				_request_zone_choice(
					bishop_candidates,
					"Choose a card from your hand to trash for VP tokens.",
					1,
					1,
					"bishop_trash",
					"TRASH",
					"SKIP",
					_hand_trash_choice_context()
				)
		"city_empty_bonus":
			var empty_piles := get_empty_supply_pile_count()
			if empty_piles >= int(effect.get("buy_at", 1)):
				player.buys += 1
			if empty_piles >= int(effect.get("coin_at", 2)):
				player.add_coins(1)
			if empty_piles >= int(effect.get("draw_at", 3)):
				draw_cards(1)
		"forge":
			if player.hand.is_empty():
				_request_exact_supply_choice(
					0,
					"discard",
					"",
					"Choose a card costing exactly 0."
				)
			else:
				_request_zone_choice(
					player.hand,
					"Choose any number of cards to trash for an exact-cost gain.",
					0,
					player.hand.size(),
					"forge_trash",
					"TRASH",
					"TRASH NONE"
				)
		"war_chest":
			_request_war_chest_name(source_card, int(effect.get("max_cost", 5)))
		"bank":
			var resources_in_play := 0
			for in_play in player.play_area:
				if card_has_type(in_play, "resource"):
					resources_in_play += 1
			player.add_coins(resources_in_play * int(effect.get("per_resource", 1)))
		"investment":
			var investment_candidates := player.hand.duplicate()
			if investment_candidates.is_empty():
				_request_mode_choice(
					source_card,
					"Choose an Investment reward.",
					[
						{"id": "coin", "label": "+1 COIN"},
						{"id": "trash_self", "label": "TRASH THIS FOR VP"},
					],
					"investment_choice",
					{"source_card": source_card}
				)
			else:
				_request_zone_choice(
					investment_candidates,
					"Choose a card from your hand to trash.",
					1,
					1,
					"investment_trash",
					"TRASH",
					"SKIP",
					{"source_card": source_card}
				)
		"mint_copy_resource":
			var mint_resources: Array[CardDefinition] = []
			for in_hand in player.hand:
				if card_has_type(in_hand, "resource"):
					mint_resources.append(in_hand)
			_request_zone_choice(
				mint_resources,
				"You may reveal a resource from your hand and gain a copy.",
				0,
				mini(1, mint_resources.size()),
				"mint_copy_resource",
				"REVEAL & COPY",
				"SKIP"
			)
		"mint_gain_cleanup":
			var played_resources: Array[CardDefinition] = []
			for in_play in player.play_area:
				if card_has_type(in_play, "resource") and not player.duration_hold.has(in_play):
					played_resources.append(in_play)
			for resource in played_resources:
				_trash_from_play(resource)
		"crystal_ball":
			_begin_crystal_ball()
		"tiara_play_resource":
			var tiara_resources: Array[CardDefinition] = []
			for in_hand in player.hand:
				if card_has_type(in_hand, "resource"):
					tiara_resources.append(in_hand)
			_request_zone_choice(
				tiara_resources,
				"You may play a resource from your hand twice.",
				0,
				mini(1, tiara_resources.size()),
				"tiara_play_resource",
				"PLAY TWICE",
				"SKIP"
			)
		"tiara_gain_reaction":
			var tiara_gained: CardDefinition = effect.get("_event_gained_card")
			if tiara_gained != null:
				var tiara_return_index := int(effect.get("_event_return_player_index", -1))
				var tiara_context: Dictionary = {"gained_card": tiara_gained}
				if tiara_return_index >= 0:
					tiara_context["_choice_return_player_index"] = tiara_return_index
					tiara_context["_defer_return_until_queue_empty"] = true
				_request_mode_choice(
					source_card,
					"You may put the gained card on top of your deck.",
					[
						{"id": "topdeck", "label": "PUT ON DECK"},
						{"id": "leave", "label": "LEAVE IT"},
					],
					"tiara_gain_choice",
					tiara_context
				)
		"anvil":
			var anvil_resources: Array[CardDefinition] = []
			for in_hand in player.hand:
				if card_has_type(in_hand, "resource"):
					anvil_resources.append(in_hand)
			_request_zone_choice(
				anvil_resources,
				"You may discard a resource to gain a card costing up to 4.",
				0,
				mini(1, anvil_resources.size()),
				"anvil_discard",
				"DISCARD",
				"SKIP"
			)
		"watchtower_reaction":
			var watchtower_return_index := int(effect.get("_event_return_player_index", -1))
			var watchtower_context: Dictionary = {"gained_card": effect.get("_event_gained_card")}
			if watchtower_return_index >= 0:
				watchtower_context["_choice_return_player_index"] = watchtower_return_index
				watchtower_context["_defer_return_until_queue_empty"] = true
			_request_mode_choice(
				source_card,
				"Choose what to do with the gained card.",
				[
					{"id": "trash", "label": "TRASH GAINED CARD"},
					{"id": "topdeck", "label": "PUT IT ON DECK"},
					{"id": "leave", "label": "LEAVE IT"},
				],
				"watchtower_reaction",
				watchtower_context
			)
		"hoard_buy":
			var gained_for_hoard: CardDefinition = effect.get("_event_gained_card")
			if gained_for_hoard != null and gained_for_hoard.card_type == "victory":
				_gain_card_by_id("amber_circlet", "discard")
		"collection_gain":
			var collected: CardDefinition = effect.get("_event_gained_card")
			if collected != null and collected.card_type == "action":
				if str(effect.get("reward", "coin")) == "vp_token":
					player.vp_tokens += int(effect.get("amount", 1))
				else:
					player.add_coins(int(effect.get("amount", 1)))
		"peddler_discount":
			# Passive metadata read from the pile by get_effective_cost().
			pass
		"global_card_rule":
			# Passive metadata read by card_has_type() and _card_coin_value().
			pass
		"buy_restriction":
			# Passive metadata checked by buy_card; playing the card has no
			# additional resolution step.
			pass
		"gain_from_supply":
			_request_supply_choice(
				int(effect.get("max_cost", 99)),
				str(effect.get("destination", "discard")),
				str(effect.get("card_type", "")),
				str(effect.get("prompt", "Choose a card to gain."))
			)
		"gain_card":
			var gain_id := str(effect.get("card_id", ""))
			var once_guard := "_gain_once_active:%s:%s" % [source_card.id if source_card != null else "", gain_id]
			if bool(effect.get("once", false)) and bool(turn_flags.get(once_guard, false)):
				return
			if bool(effect.get("once", false)):
				turn_flags[once_guard] = true
			_gain_card_by_id(gain_id, str(effect.get("destination", "discard")))
			if bool(effect.get("once", false)):
				turn_flags.erase(once_guard)
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
			if source_card != null and source_card.has_tag("redraw"):
				if player.hand.is_empty():
					_draw_to_size_simple(int(effect.get("target_hand_size", 5)))
				else:
					_request_zone_choice(
						player.hand,
						"Discard your hand, then draw 5 cards.",
						player.hand.size(),
						player.hand.size(),
						"discard_hand_draw_to_size",
						"REDRAW",
						"SKIP",
						{"target_hand_size": int(effect.get("target_hand_size", 5))}
					)
			else:
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
			var trash_limit := mini(int(effect.get("amount", 1)), player.hand.size())
			var trash_required := bool(effect.get("required", false))
			_request_zone_choice(
				player.hand,
				"Choose up to %d cards from your hand to trash."
				% int(effect.get("amount", 1)),
				trash_limit if trash_required else 0,
				trash_limit,
				"trash_hand",
				"TRASH",
				"SKIP",
				_hand_trash_choice_context()
			)
		"relic_full_deck_trash":
			_resolve_relic_full_deck_trash(int(effect.get("amount", 5)))
		"trash_self":
			_trash_from_play(source_card)
		"topdeck_from_discard":
			var topdeck_required := source_card != null and is_event_card(source_card)
			_request_zone_choice(
				player.discard_pile,
				"Choose a card from your discard pile to put on top of your deck.",
				1 if topdeck_required and not player.discard_pile.is_empty() else 0,
				mini(1, player.discard_pile.size()),
				"topdeck_discard",
				"PUT ON DECK",
				"LEAVE IT"
			)
		"draw_to_size":
			_continue_library_draw(int(effect.get("amount", 7)), [])
		"simple_draw_to_size":
			_draw_to_size_simple(int(effect.get("amount", 6)))
		"resource_bonus":
			turn_flags["resource_bonus"] = {
				"card_id": str(effect.get("card_id", "")),
				"amount": int(effect.get("amount", 0)),
				"used": false,
			}
		"upgrade_resource":
			var resources: Array[CardDefinition] = []
			for card in player.hand:
				if card_has_type(card, "resource"):
					resources.append(card)
			var upgrade_required := source_card != null and is_event_card(source_card)
			_request_zone_choice(
				resources,
				"Choose a resource from your hand to trash.",
				1 if upgrade_required and not resources.is_empty() else 0,
				mini(1, resources.size()),
				"upgrade_resource",
				"TRASH & UPGRADE",
				"SKIP",
				_hand_trash_choice_context({"cost_delta": int(effect.get("cost_delta", 0))})
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
				_hand_trash_choice_context({"amount": int(effect.get("amount", 0))})
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
				_hand_trash_choice_context({"cost_delta": int(effect.get("cost_delta", 0))})
			)
		"inspect_top":
			if source_card != null and source_card.has_tag("ranger_path"):
				_begin_ranger_inspect_top(int(effect.get("amount", 5)))
			else:
				_begin_inspect_top(int(effect.get("amount", 2)))
		"inspect_top_one":
			_begin_inspect_one()
		"salvage_resource":
			_begin_salvage(int(effect.get("amount", 2)))
		"replay_action":
			var actions: Array[CardDefinition] = []
			var replay_count := int(effect.get("repetitions", 2))
			for card in player.hand:
				if card.card_type == "action":
					actions.append(card)
			_request_zone_choice(
				actions,
				"Choose an action card from your hand to play %d times." % replay_count,
				0,
				mini(1, actions.size()),
				"replay_action",
				"PLAY %d TIMES" % replay_count,
				"SKIP",
				{"repetitions": replay_count}
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
			player.add_coins(
				int(effect.get("first_amount", 1))
				if play_count == 1
				else int(effect.get("later_amount", 4))
			)
		"draw_per_type_in_hand":
			var type_count := 0
			var card_type := str(effect.get("card_type", "victory"))
			for card in player.hand:
				if card_has_type(card, card_type):
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
				"SKIP",
				_hand_trash_choice_context()
			)
		"register_buy_bonus":
			# Legacy cards omit amount and grant a cheaper follow-up gain. Events
			# with an explicit amount instead register a coin rebate per purchase.
			if effect.has("amount"):
				turn_flags["buy_coin_bonus"] = (
					int(turn_flags.get("buy_coin_bonus", 0))
					+ int(effect.get("amount", 0))
				)
			else:
				turn_flags["buy_bonus_count"] = int(turn_flags.get("buy_bonus_count", 0)) + 1
		"reduce_costs":
			var reduction_type := str(effect.get("card_type", ""))
			if reduction_type.is_empty():
				turn_flags["cost_reduction"] = (
					int(turn_flags.get("cost_reduction", 0))
					+ int(effect.get("amount", 1))
				)
			else:
				var typed_reductions: Dictionary = turn_flags.get("typed_cost_reductions", {})
				typed_reductions[reduction_type] = (
					int(typed_reductions.get(reduction_type, 0))
					+ int(effect.get("amount", 1))
				)
				turn_flags["typed_cost_reductions"] = typed_reductions
		"reduce_end_turn_cooldown":
			reduce_end_turn_cooldown(float(effect.get("amount", 0.5)))
		"reduce_end_turn_cooldown_game":
			reduce_end_turn_cooldown_for_game(float(effect.get("amount", 0.5)))
		"end_turn":
			request_end_turn_after_play()
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
				"SKIP",
				_hand_trash_choice_context()
			)
		"topdeck_action_at_cleanup":
			turn_flags["cleanup_topdeck_actions"] = (
				int(turn_flags.get("cleanup_topdeck_actions", 0))
				+ int(effect.get("amount", 1))
			)
		"discard_resource_choose_bonus":
			var discard_resources: Array[CardDefinition] = []
			for card in player.hand:
				if card.card_type == "resource":
					discard_resources.append(card)
			_request_zone_choice(
				discard_resources,
				"You may discard a resource from your hand.",
				0,
				mini(1, discard_resources.size()),
				"discard_resource_mode",
				"DISCARD",
				"SKIP",
				{
				"modes": effect.get("modes", []),
				"ui_choice_kind": "discard_from_hand",
					"ui_source_zone": "hand",
				}
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
					"max_cost": get_non_buy_cost(source_card) - 1,
					"exclude_card_id": source_card.id,
					"exclude_victory": bool(effect.get("exclude_victory", false)),
				},
				str(effect.get("destination", "discard")),
				str(effect.get("prompt", "Choose a cheaper card to gain."))
			)
		"gain_coins_trigger":
			player.add_coins(int(effect.get("amount", 0)))
		"gain_vp_tokens":
			player.vp_tokens += int(effect.get("amount", 1))
		"play_self_optional":
			_request_play_self(source_card, effect)
		"play_self_if_action_in_play":
			if _has_other_action_in_play(source_card):
				_play_card_from_event_zone(source_card, effect)
		"dynamic_hand_coins":
			player.add_coins(maxi(
				0,
				int(effect.get("base_amount", 0))
				- player.hand.size() * int(effect.get("per_card", 1))
			))
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
				_hand_trash_choice_context({"card_id": str(effect.get("card_id", ""))})
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
				_hand_trash_choice_context({
					"cost_delta": int(effect.get("cost_delta", 2)),
					"exclude_card_id": source_card.id,
				})
			)
		"turn_start_bonus":
			# Duration payload: resolves at the start of the owner's next turn.
			var early_draw_count := int(effect.get("draw_cards", 0))
			draw_cards(early_draw_count)
			if bool(effect.get("_duration_resolving", false)) and early_draw_count > 0:
				player.turn_flags["duration_early_draws"] = (
					int(player.turn_flags.get("duration_early_draws", 0)) + early_draw_count
				)
			player.actions += int(effect.get("gain_actions", 0))
			player.buys += int(effect.get("gain_buys", 0))
			player.add_coins(int(effect.get("gain_coins", 0)))
		"set_aside_from_hand":
			var return_next_turn := (
				bool(effect.get("return_next_turn", false))
				or (source_card != null and is_event_card(source_card))
			)
			_request_zone_choice(
				player.hand,
				str(effect.get(
					"prompt",
					"You may set a card from your hand aside until your next turn."
				)),
				0,
				mini(int(effect.get("amount", 1)), player.hand.size()),
				"set_aside_hand",
				"SET ASIDE",
				"SKIP",
				{"return_next_turn": return_next_turn}
			)
		"return_set_aside":
			if not player.set_aside_pile.is_empty():
				player.hand.append_array(player.set_aside_pile)
				player.set_aside_pile.clear()
		"gain_from_trash":
			var reclaim_candidates: Array[CardDefinition] = []
			var reclaim_max_cost := int(effect.get("max_cost", 99))
			for card in player.trash_pile:
				if get_non_buy_cost(card) <= reclaim_max_cost:
					reclaim_candidates.append(card)
			var reclaim_required := source_card != null and is_event_card(source_card)
			_request_zone_choice(
				reclaim_candidates,
				str(effect.get(
					"prompt",
					"You may put a card from your trash pile into your discard pile."
				)),
				1 if reclaim_required and not reclaim_candidates.is_empty() else 0,
				mini(1, reclaim_candidates.size()),
				"gain_from_trash",
				"RECLAIM",
				"SKIP"
			)
		"trash_size_bonus":
			if player.trash_pile.size() >= int(effect.get("threshold", 5)):
				draw_cards(int(effect.get("draw_cards", 0)))
				player.actions += int(effect.get("gain_actions", 0))
				player.buys += int(effect.get("gain_buys", 0))
				player.add_coins(int(effect.get("gain_coins", 0)))
		"trash_filtered_bonus":
			var bonus_trash_candidates := _filter_hand_cards(effect)
			var bonus_trash_amount := mini(
				int(effect.get("amount", 1)),
				bonus_trash_candidates.size()
			)
			_request_zone_choice(
				bonus_trash_candidates,
				str(effect.get("prompt", "Choose cards from your hand to trash.")),
				0,
				bonus_trash_amount,
				"trash_hand_bonus",
				"TRASH",
				"SKIP",
				_hand_trash_choice_context(_per_card_bonus_context(effect))
			)
		"discard_filtered_bonus":
			var bonus_discard_candidates := _filter_hand_cards(effect)
			var bonus_discard_amount := mini(
				int(effect.get("amount", 1)),
				bonus_discard_candidates.size()
			)
			_request_zone_choice(
				bonus_discard_candidates,
				str(effect.get("prompt", "Choose cards from your hand to discard.")),
				0,
				bonus_discard_amount,
				"discard_hand_bonus",
				"DISCARD",
				"SKIP",
				_per_card_bonus_context(effect)
			)
		"draw_per_relic":
			draw_cards(player.relics.size() * int(effect.get("amount", 1)))
		"offer_relic_draft":
			if bool(effect.get("replace_owned", false)):
				begin_relic_replacement(player)
			else:
				generate_relic_offer(player)
		"attack_immunity":
			if not bool(effect.get("_duration_resolving", false)):
				_grant_timed_attack_immunity(effect)
		_:
			push_warning("Unknown card effect kind: %s" % kind)


func _resolve_magpie_reveal() -> void:
	var revealed := _take_top_card()
	if revealed == null:
		return
	if card_has_type(revealed, "resource"):
		player.hand.append(revealed)
		return
	# A non-Treasure reveal is discarded; Action/Victory reveals also award a
	# Magpie from its supply.  Gain the copy before the discard trigger so the
	# normal gain pipeline remains observable to reactions.
	if revealed.card_type in ["action", "victory"]:
		_gain_card_by_id("magpie", "discard")
	player.discard_pile.append(revealed)
	_prepend_triggered_effects(revealed, "discard", {"zone": "discard"})


func _resolve_storyteller(selected: Array[CardDefinition], _source_card: CardDefinition) -> void:
	# Resources are played without spending actions.  Their coin values and any
	# normal play payloads resolve before Storyteller converts the final coin
	# total into cards.
	for treasure in selected:
		if treasure == null or not player.hand.has(treasure):
			continue
		player.hand.erase(treasure)
		player.play_area.append(treasure)
		player.register_play_display(treasure, 1)
		_apply_card_base(treasure)
		_prepend_triggered_effects(treasure, "play", {"zone": "play"})
	var coin_total := player.coins
	# Storyteller's printed +1 Card is in addition to one card per coin
	# generated by the played Treasures.
	draw_cards(1 + coin_total)
	player.coins = 0


func _begin_raze(source_card: CardDefinition) -> void:
	var candidates: Array[CardDefinition] = []
	if source_card != null and player.play_area.has(source_card):
		candidates.append(source_card)
	candidates.append_array(player.hand)
	if candidates.is_empty():
		return
	var choice := _new_choice(
		"Trash this or a card from your hand to reveal cards costing that many coins.",
		1,
		1,
		"raze_source",
		"TRASH"
	)
	for index in range(candidates.size()):
		choice.add_candidate("raze:%d:%d" % [choice.id, index], candidates[index])
	choice.context["source_card"] = source_card
	_request_choice(choice)


func _request_inheritance_choice(effect: Dictionary) -> void:
	var max_cost := int(effect.get("max_cost", 5))
	var candidates: Array[CardDefinition] = []
	for card in _get_gain_supply_cards():
		if card == null or card.card_type != "action" or get_non_buy_cost(card) > max_cost:
			continue
		if card.has_tag("command") or card.has_tag("duration") and card.id == "champion":
			continue
		if not supply_piles.has(card.id) or get_supply_count(card.id) <= 0:
			continue
		candidates.append(card)
	if candidates.is_empty():
		return
	var choice := _new_choice(
		"Choose an Action Supply pile for your Estate token.",
		1,
		1,
		"inheritance_target",
		"SET ESTATE TOKEN"
	)
	for card in candidates:
		choice.add_candidate("inheritance:%d:%s" % [choice.id, card.id], card)
	_request_choice(choice)


func _request_messenger_gain_choice(effect: Dictionary) -> void:
	var candidates := get_gain_candidates(int(effect.get("max_cost", 4)), "")
	if candidates.is_empty():
		return
	var choice := _new_choice(
		"Choose a card for Messenger and each other player to gain.",
		1,
		1,
		"messenger_gain",
		"GAIN FOR ALL"
	)
	for candidate in candidates:
		choice.add_candidate("messenger:%d:%s" % [choice.id, candidate.id], candidate)
	_request_choice(choice)


func _resolve_supply_token_effect(effect: Dictionary, source_card: CardDefinition = null) -> void:
	var token_list = effect.get("tokens", null)
	if typeof(token_list) == TYPE_ARRAY:
		for token_entry in token_list:
			if typeof(token_entry) != TYPE_DICTIONARY:
				continue
			var expanded := effect.duplicate(true)
			for key in token_entry:
				expanded[key] = token_entry[key]
			expanded.erase("tokens")
			_resolve_supply_token_effect(expanded, source_card)
		return
	var raw_token_id := str(effect.get("token", effect.get("token_id", effect.get("token_kind", ""))))
	var token_id := _normalize_pile_token_id(raw_token_id)
	if bool(effect.get("choose_pile", effect.get("choose_target", false))):
		_request_pile_token_choice(effect)
		return
	var amount := int(effect.get("amount", 1))
	# A gain-triggered token without a target pile represents taking that token
	# from the shared supply into the active player's token collection.
	if (
		str(effect.get("trigger", "")) == "gain"
		and str(effect.get("card_id", effect.get("supply_card_id", ""))).is_empty()
		and str(effect.get("target_card_id", "")).is_empty()
	):
		player.add_player_token(token_id, amount)
		return
	if token_id in ["card", "action", "buy", "coin", "cost", "trash"]:
		# These tokens are owned by the active player.  An explicit `shared`
		# flag retains the old count-shaped API for cards that intentionally place
		# a common token on a pile.
		var owner := int(effect.get("player_index", active_player_index))
		var target_pile := str(effect.get("card_id", effect.get("supply_card_id", effect.get("target_card_id", ""))))
		if target_pile.is_empty() and turn_flags.has("_last_gain_card_id"):
			target_pile = str(turn_flags.get("_last_gain_card_id", ""))
		if target_pile.is_empty() and source_card != null and not is_event_card(source_card):
			target_pile = source_card.id
		if target_pile.is_empty():
			_request_pile_token_choice(effect)
			return
		var owner_mode := str(effect.get("mode", "place"))
		if not bool(effect.get("shared", false)) and owner_mode == "move":
			move_player_supply_token(owner, token_id, str(effect.get("to_card_id", effect.get("destination_card_id", ""))))
			turn_flags.erase("_last_gain_card_id")
			return
		if not bool(effect.get("shared", false)) and owner_mode not in ["remove", "take", "move"]:
			move_player_supply_token(owner, token_id, target_pile)
			turn_flags.erase("_last_gain_card_id")
			return
		if not bool(effect.get("shared", false)) and owner_mode in ["remove", "take"]:
			move_player_supply_token(owner, token_id, "")
			turn_flags.erase("_last_gain_card_id")
			return
	if token_id.is_empty() or amount == 0:
		return
	var card_id := str(effect.get("card_id", effect.get("supply_card_id", "")))
	if card_id.is_empty():
		card_id = str(effect.get("target_card_id", ""))
	if card_id.is_empty() and turn_flags.has("_last_gain_card_id"):
		card_id = str(turn_flags.get("_last_gain_card_id", ""))
	if card_id.is_empty() and source_card != null and not is_event_card(source_card):
		card_id = source_card.id
	if card_id.is_empty() and token_id in ["action", "buy", "card", "coin", "cost", "trash"]:
		_request_pile_token_choice(effect)
		return
	var mode := str(effect.get("mode", "place"))
	match mode:
		"remove", "take":
			remove_supply_token(card_id, token_id, maxi(0, amount))
		"move":
			move_supply_token(card_id, str(effect.get("to_card_id", effect.get("destination_card_id", ""))), token_id, amount)
		_:
			place_supply_token(card_id, token_id, maxi(0, amount))


func _request_pile_token_choice(effect: Dictionary) -> void:
	var token_id := _normalize_pile_token_id(str(effect.get("token", effect.get("token_id", effect.get("token_kind", "")))))
	var candidates: Array[CardDefinition] = []
	for card in _get_gain_supply_cards():
		if card == null or card.card_type != "action" or not supply_piles.has(card.id):
			continue
		if get_player_supply_token_card(active_player_index, token_id) == card.id:
			continue
		candidates.append(card)
	if candidates.is_empty():
		return
	var choice := _new_choice(
		str(effect.get("prompt", "Choose an Action Supply pile for this token.")),
		1,
		1,
		"pile_token_target",
		str(effect.get("confirm_text", "PLACE TOKEN")),
		str(effect.get("skip_text", "CANCEL")),
		{"effect": effect.duplicate(true), "token_id": token_id}
	)
	for card in candidates:
		choice.add_candidate("pile-token:%d:%s" % [choice.id, card.id], card)
	_request_choice(choice)


func _upgrade_traveller(source_card: CardDefinition, effect: Dictionary, cleanup_exchange: bool = false) -> void:
	if source_card == null:
		return
	var upgrade_id := str(effect.get("card_id", effect.get("upgrade_to", source_card.traveller_upgrade_id)))
	if upgrade_id.is_empty() or not card_catalog.has(upgrade_id):
		return
	var current_level := int(player.traveller_progress.get(source_card.id, 0)) + 1
	player.traveller_progress[source_card.id] = current_level
	# Retiring a Traveller during cleanup returns the old card to its own pile;
	# this is an exchange, not a trash or gain and therefore must not trigger
	# gain/trash reactions.  The legacy in-turn retirement path retains its
	# previous trash semantics for compatibility with existing card data.
	if cleanup_exchange:
		player.play_area.erase(source_card)
		if supply_piles.has(source_card.id):
			supply_piles[source_card.id] = get_supply_count(source_card.id) + 1
		else:
			traveller_piles[source_card.id] = int(traveller_piles.get(source_card.id, 0)) + 1
	else:
		_trash_from_play(source_card)
	var upgraded: CardDefinition = card_catalog[upgrade_id]
	if traveller_piles.has(upgrade_id) and get_traveller_supply_count(upgrade_id) > 0:
		traveller_piles[upgrade_id] = get_traveller_supply_count(upgrade_id) - 1
		player.discard_pile.append(upgraded)
	elif supply_piles.has(upgrade_id) and get_supply_count(upgrade_id) > 0:
		_gain_from_supply(upgraded, "discard")
	else:
		# A custom data set may omit explicit pile initialization; only consume a
		# non-Supply card when its declared pile has copies available.
		if not upgraded.is_supply_card():
			return
		player.discard_pile.append(upgraded)


func _grant_timed_attack_immunity(effect: Dictionary) -> void:
	var protections: Dictionary = player.turn_flags.get("timed_attack_immunity", {})
	protections[str(effect.get("zone", "hand"))] = true
	player.turn_flags["timed_attack_immunity"] = protections


func _has_repeating_duration_effect(card: CardDefinition) -> bool:
	if card == null:
		return false
	for effect in card.special_effects:
		if str(effect.get("trigger", "")) == "next_turn" and bool(effect.get("repeat", false)):
			return true
	return false


func _per_card_bonus_context(effect: Dictionary) -> Dictionary:
	return {
		"per_draw_cards": int(effect.get("per_draw_cards", 0)),
		"per_gain_actions": int(effect.get("per_gain_actions", 0)),
		"per_gain_buys": int(effect.get("per_gain_buys", 0)),
		"per_gain_coins": int(effect.get("per_gain_coins", 0)),
	}


func _apply_per_card_bonus(context: Dictionary, card_count: int) -> void:
	if card_count <= 0:
		return
	draw_cards(int(context.get("per_draw_cards", 0)) * card_count)
	player.actions += int(context.get("per_gain_actions", 0)) * card_count
	player.buys += int(context.get("per_gain_buys", 0)) * card_count
	player.add_coins(int(context.get("per_gain_coins", 0)) * card_count)


func resolve_choice(tokens: Array[String]) -> bool:
	if pending_choice == null or not pending_choice.is_valid_selection(tokens):
		return false
	var choice := pending_choice
	var allowed_sizes: Array = choice.context.get("allowed_selection_sizes", [])
	if not allowed_sizes.is_empty() and not allowed_sizes.has(tokens.size()):
		return false
	var return_index := int(choice.context.get("_choice_return_player_index", -1))
	var restore_before := bool(choice.context.get("_restore_before_resolution", false))
	var defer_return := bool(choice.context.get("_defer_return_until_queue_empty", false))
	var selected := choice.get_selected_entries(tokens)
	pending_choice = null
	player.pending_choice = null
	if restore_before and return_index >= 0 and return_index < players.size():
		_set_active_player(return_index, false)
	_apply_choice_resolution(choice, selected)
	choice_resolved.emit(choice.id)
	if bool(choice.context.get("_opponent_choice", false)) and not has_pending_choice():
		_continue_opponent_choice(choice.context)
	elif defer_return:
		# Target-owned gain reactions may have queued another reaction. Drain the
		# target queue before restoring the attacking seat, preserving sequencing.
		_process_resolution_queue()
		if not has_pending_choice() and return_index >= 0 and return_index < players.size() and return_index != active_player_index:
			_set_active_player(return_index, false)
	else:
		if not has_pending_choice() and return_index >= 0 and return_index < players.size() and return_index != active_player_index:
			_set_active_player(return_index, false)
		_process_resolution_queue()
	if not has_pending_choice():
		turn_flags.erase("_last_gain_card_id")
	check_idle_relics()
	return true


func _apply_choice_resolution(
	choice: CardChoice,
	selected: Array[Dictionary]
) -> void:
	var cards := _cards_from_entries(selected)
	match choice.resolver:
		"standard_mode":
			var standard_mode := _selected_mode(choice, selected)
			if standard_mode.has("effects"):
				_queue_effect_list(standard_mode.get("effects", []), choice.context.get("source_card"))
			else:
				_apply_mode_bonus(standard_mode)
		"call_reserve":
			if cards.is_empty():
				return
			call_reserve_card(cards[0])
		"traveller_cleanup":
			var cleanup_card: CardDefinition = choice.context.get("traveller_card")
			if not cards.is_empty() and cleanup_card != null:
				_upgrade_traveller(cleanup_card, choice.context.get("effect", {}), true)
			# A decline or a successful exchange may leave another Traveller in
			# play; continue the same cleanup transaction until all are offered.
			if not has_pending_choice():
				_finish_cleanup()
		"gain_supply":
			if not cards.is_empty():
				_gain_from_supply(cards[0], str(choice.context.get("destination", "discard")))
		"pile_token_target":
			if not cards.is_empty():
				move_active_player_supply_token(str(choice.context.get("token_id", "")), cards[0].id)
		"artificer_discard":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			_request_exact_supply_choice(
				cards.size(),
				"deck",
				"",
				"Choose a card costing exactly %d to put onto your deck." % cards.size()
			)
		"storyteller_play_treasures":
			_resolve_storyteller(cards, choice.context.get("source_card"))
		"pilgrimage_cards":
			for copied_card in cards:
				_gain_card_by_id(copied_card.id, "discard")
		"quest_discard":
			if cards.is_empty():
				return
			var valid_quest := false
			if cards.size() == 1 and cards[0].has_tag("attack"):
				valid_quest = true
			elif cards.size() == 2:
				valid_quest = cards[0].card_type == "curse" and cards[1].card_type == "curse"
			elif cards.size() == 6:
				valid_quest = true
			if not valid_quest:
				return
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			_gain_card_by_id("amber_circlet", "discard")
		"travelling_fair_choice":
			if cards.is_empty():
				return
			var fair_card: CardDefinition = choice.context.get("gained_card")
			if fair_card == null:
				return
			var fair_destination := _get_zone(str(choice.context.get("destination", "discard")))
			fair_destination.erase(fair_card)
			player.draw_pile.append(fair_card)
		"bonfire_trash":
			for card in cards:
				_trash_from_play(card)
		"trade_trash":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.trash_pile, cards, "trash")
			for _silver_index in range(cards.size()):
				_gain_card_by_id("silver_leaf", "discard")
		"plan_buy_trash":
			if not cards.is_empty():
				_move_cards(player.hand, player.trash_pile, cards, "trash")
		"inheritance_target":
			if cards.is_empty():
				return
			var inherited := cards[0]
			if supply_piles.has(inherited.id) and get_supply_count(inherited.id) > 0:
				supply_piles[inherited.id] = get_supply_count(inherited.id) - 1
			player.inheritance_card_id = inherited.id
			# Estate is not physically moved out of the deck in this engine; its
			# token target is enough for future Estate-as-Action interpretation.
		"messenger_gain":
			if cards.is_empty():
				return
			var messenger_card := cards[0]
			_gain_card_by_id(messenger_card.id, "discard")
			for target_index in range(players.size()):
				if target_index == active_player_index:
					continue
				_gain_card_by_id_for_player(messenger_card.id, "discard", players[target_index])
		"teacher_token_choice":
			var teacher_token_id := _selected_mode_id(selected)
			if not teacher_token_id.is_empty():
				_request_pile_token_choice({"token": teacher_token_id, "amount": 1, "prompt": "Choose an Action Supply pile for this token."})
		"topdeck_hand":
			_move_cards(player.hand, player.draw_pile, cards)
		"rabble_opponent_order":
			if cards.is_empty():
				return
			var remaining_rabble: Array[CardDefinition] = choice.context.get("remaining", [])
			var ordered_rabble: Array[CardDefinition] = choice.context.get("ordered", [])
			var next_card := cards[0]
			remaining_rabble.erase(next_card)
			ordered_rabble.append(next_card)
			if remaining_rabble.size() <= 1:
				if remaining_rabble.size() == 1:
					ordered_rabble.append(remaining_rabble[0])
				for index in range(ordered_rabble.size() - 1, -1, -1):
					player.draw_pile.append(ordered_rabble[index])
			else:
				var next_context := choice.context.duplicate(true)
				next_context["remaining"] = remaining_rabble
				next_context["ordered"] = ordered_rabble
				var next_choice := _new_choice(
					"Choose the next revealed card to put on top of your deck.",
					1,
					1,
					"rabble_opponent_order",
					"PUT NEXT",
					"SKIP",
					next_context
				)
				for index in range(remaining_rabble.size()):
					next_choice.add_candidate(
						"opponent-rabble:%d:%d" % [next_choice.id, index],
						remaining_rabble[index]
					)
				_request_choice(next_choice)
		"discard_hand_draw":
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			draw_cards(cards.size())
		"discard_hand_draw_to_size":
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			_draw_to_size_simple(int(choice.context.get("target_hand_size", 5)))
		"storyteller_discard_for_coins":
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			player.add_coins(cards.size())
		"coin_mat_deposit":
			if cards.is_empty():
				return
			for deposited in cards:
				player.hand.erase(deposited)
			player.coin_mat += cards.size()
		"raze_source":
			if cards.is_empty():
				return
			var raze_target := cards[0]
			var raze_cost := get_non_buy_cost(raze_target)
			if raze_target == choice.context.get("source_card"):
				_trash_from_play(raze_target)
			else:
				_move_cards(player.hand, player.trash_pile, [raze_target], "trash")
			var revealed: Array[CardDefinition] = []
			for _raze_index in range(raze_cost):
				var revealed_card := _take_top_card()
				if revealed_card != null:
					revealed.append(revealed_card)
			if revealed.is_empty():
				return
			_request_zone_choice(revealed, "Choose one revealed card to put into your hand.", 1, 1, "raze_keep", "KEEP", "SKIP", {"revealed": revealed})
		"raze_keep":
			var raze_revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			if cards.is_empty():
				player.discard_pile.append_array(raze_revealed)
				return
			var kept_raze := cards[0]
			raze_revealed.erase(kept_raze)
			player.hand.append(kept_raze)
			player.discard_pile.append_array(raze_revealed)
		"start_turn_reaction":
			if cards.is_empty():
				return
			var reaction_card := cards[0]
			var remaining_reaction_ids: Array = turn_flags.get("start_turn_reaction_ids", [])
			remaining_reaction_ids.erase(reaction_card.id)
			turn_flags["start_turn_reaction_ids"] = remaining_reaction_ids
			player.hand.erase(reaction_card)
			player.play_area.append(reaction_card)
			player.register_play_display(reaction_card, 1)
			resolution_queue.push_front({"kind": "start_turn_reactions"})
			_prepend_card_resolutions(reaction_card, 1)
		"vault_discard":
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			# Opponents may discard two to draw, but only the Vault owner's
			# optional discard grants coins.
			if not bool(choice.context.get("_opponent_choice", false)):
				player.add_coins(cards.size())
			if not bool(choice.context.get("_opponent_choice", false)):
				_vault_other_players()
			elif cards.size() == 2:
				var drawn := _take_top_card_for_player(player)
				if drawn != null:
					player.hand.append(drawn)
		"bishop_trash":
			if cards.is_empty():
				if not bool(choice.context.get("_opponent_choice", false)):
					_bishop_other_players()
				return
			var bishop_card := cards[0]
			_move_cards(player.hand, player.trash_pile, [bishop_card], "trash")
			# The VP token reward belongs to the Bishop owner; an opponent's
			# reaction is a trash-only choice.
			if not bool(choice.context.get("_opponent_choice", false)):
				player.vp_tokens += floori(float(get_non_buy_cost(bishop_card)) / 2.0)
			if not bool(choice.context.get("_opponent_choice", false)):
				_bishop_other_players()
		"forge_trash":
			_move_cards(player.hand, player.trash_pile, cards, "trash")
			var forge_total := 0
			for trashed in cards:
				forge_total += get_non_buy_cost(trashed)
			_request_exact_supply_choice(
				forge_total,
				"discard",
				"",
				"Choose a card costing exactly %d." % forge_total
			)
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
				get_non_buy_cost(trashed) + int(choice.context.get("cost_delta", 0)),
				"hand",
				"resource",
				"Choose a replacement resource to gain to your hand."
			)
		"trash_named_coins":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.trash_pile, cards, "trash")
			player.add_coins(int(choice.context.get("amount", 0)))
		"remodel":
			if cards.is_empty():
				return
			var trashed := cards[0]
			_move_cards(player.hand, player.trash_pile, [trashed], "trash")
			_request_supply_choice(
				get_non_buy_cost(trashed) + int(choice.context.get("cost_delta", 0)),
				"discard",
				"",
				"Choose a card to gain."
			)
		"inspect_trash":
			var revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			for card in cards:
				revealed.erase(card)
			player.trash_pile.append_array(cards)
			_notify_cards_trashed(player, cards.size())
			_queue_zone_events(cards, "trash", "trash")
			_request_inspect_discard(revealed)
		"ranger_keep_resource":
			var ranger_revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			if not cards.is_empty():
				var kept_resource := cards[0]
				ranger_revealed.erase(kept_resource)
				player.hand.append(kept_resource)
			_discard_revealed_cards(ranger_revealed)
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
				_notify_cards_trashed(player, 1)
				_prepend_triggered_effects(resource, "trash", {"zone": "trash"})
				player.add_coins(resource.coin_value)
			player.discard_pile.append_array(revealed)
			_queue_zone_events(revealed, "discard", "discard")
		"replay_action":
			if cards.is_empty():
				return
			var action := cards[0]
			player.hand.erase(action)
			player.play_area.append(action)
			var repetitions := int(choice.context.get("repetitions", 2))
			player.register_play_display(action, repetitions)
			_prepend_card_resolutions(action, repetitions)
		"vassal_play":
			var card: CardDefinition = choice.context.get("card")
			if cards.is_empty():
				player.discard_pile.append(card)
				_prepend_triggered_effects(card, "discard", {"zone": "discard"})
			else:
				player.play_area.append(card)
				player.register_play_display(card, 1)
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
				{"trashed_cost": get_non_buy_cost(developed)}
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
		"discard_resource_mode":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			_request_mode_choice(
				cards[0],
				"Choose your Spicebroker reward.",
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
					"max_cost": get_non_buy_cost(discarded),
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
		"traveller_upgrade":
			if not cards.is_empty():
				_upgrade_traveller(cards[0], choice.context.get("effect", {}))
		"reserve_duplicate_gain":
			if cards.is_empty():
				return
			var echo_seal := cards[0]
			var copied_gain: CardDefinition = choice.context.get("gained_card")
			if copied_gain == null or not player.reserve_mat.has(echo_seal):
				return
			player.reserve_mat.erase(echo_seal)
			player.play_area.append(echo_seal)
			player.register_play_display(echo_seal, 1)
			_gain_card_by_id(copied_gain.id, str(choice.context.get("destination", "discard")))
		"trash_for_copies":
			if cards.is_empty():
				return
			var traded := cards[0]
			_move_cards(player.hand, player.trash_pile, [traded], "trash")
			for _index in range(get_non_buy_cost(traded)):
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
				get_non_buy_cost(upgraded)
				+ int(choice.context.get("cost_delta", 2))
			)
			_request_exact_supply_choice(
				target_cost,
				"discard",
				str(choice.context.get("exclude_card_id", "")),
				"Choose a different card costing exactly %d." % target_cost
			)
		"relic_predraw":
			var remaining := int(choice.context.get("remaining", 0))
			for card in cards:
				player.draw_pile.erase(card)
				player.hand.append(card)
				remaining -= 1
				print("[Game] Draw: %s (Seeker's Compass)" % card.card_name)
			if remaining > 0:
				draw_cards(remaining)
		"cleanup_topdeck":
			_move_cards(player.play_area, player.draw_pile, cards)
			_finish_cleanup()
		"attack_trash_resource":
			_finish_attack_reveal_resource(choice.context.get("revealed", []), cards)
		"rabble_discard":
			var rabble_revealed: Array[CardDefinition] = choice.context.get("revealed", [])
			for card in cards:
				rabble_revealed.erase(card)
			player.discard_pile.append_array(cards)
			_queue_zone_events(cards, "discard", "discard")
			_begin_order_cards(rabble_revealed)
		"set_aside_hand":
			_move_cards(player.hand, player.set_aside_pile, cards)
			if not cards.is_empty() and bool(choice.context.get("return_next_turn", false)):
				player.pending_duration_effects.append({
					"card": null,
					"effect": {"kind": "return_set_aside"},
				})
		"gain_from_trash":
			_move_cards(player.trash_pile, player.discard_pile, cards)
			_queue_zone_events(cards, "gain", "discard")
		"trash_hand_bonus":
			_move_cards(player.hand, player.trash_pile, cards, "trash")
			_apply_per_card_bonus(choice.context, cards.size())
		"discard_hand_bonus":
			_move_cards(player.hand, player.discard_pile, cards, "discard")
			_apply_per_card_bonus(choice.context, cards.size())
		"war_chest_name":
			var named_mode := _selected_mode(choice, selected)
			var excluded: Array = turn_flags.get("war_chest_exclusions", [])
			var named_id := str(named_mode.get("id", ""))
			if not named_id.is_empty() and not excluded.has(named_id):
				excluded.append(named_id)
			turn_flags["war_chest_exclusions"] = excluded
			_request_filtered_supply_choice(
				{
					"max_cost": int(choice.context.get("max_cost", 5)),
					"exclude_card_ids": excluded,
				},
				"discard",
				"Choose a card to gain (named cards are excluded)."
			)
		"investment_trash":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.trash_pile, [cards[0]], "trash")
			_request_mode_choice(
				choice.context.get("source_card"),
				"Choose an Investment reward.",
				[
					{"id": "coin", "label": "+1 COIN"},
					{"id": "trash_self", "label": "TRASH THIS FOR VP"},
				],
				"investment_choice",
				{"source_card": choice.context.get("source_card")}
			)
		"investment_choice":
			var investment_mode := _selected_mode(choice, selected)
			if str(investment_mode.get("id", "")) == "coin":
				player.add_coins(1)
			else:
				var investment_source: CardDefinition = choice.context.get("source_card")
				if investment_source == null or not player.play_area.has(investment_source):
					return
				_trash_from_play(investment_source)
				var distinct_resources: Dictionary = {}
				for in_hand in player.hand:
					if card_has_type(in_hand, "resource"):
						distinct_resources[in_hand.id] = true
				player.vp_tokens += distinct_resources.size()
		"mint_copy_resource":
			if cards.is_empty():
				return
			var mint_resource := cards[0]
			_gain_card_by_id(mint_resource.id, "discard")
		"tiara_play_resource":
			if cards.is_empty():
				return
			var tiara_resource := cards[0]
			player.hand.erase(tiara_resource)
			player.play_area.append(tiara_resource)
			player.register_play_display(tiara_resource, 2)
			_prepend_card_resolutions(tiara_resource, 2)
		"anvil_discard":
			if cards.is_empty():
				return
			_move_cards(player.hand, player.discard_pile, [cards[0]], "discard")
			_request_filtered_supply_choice(
				{"max_cost": 4},
				"discard",
				"Choose a card costing up to 4."
			)
		"watchtower_reaction":
			var gained_card: CardDefinition = choice.context.get("gained_card")
			if gained_card == null:
				return
			var watch_mode := _selected_mode(choice, selected)
			if str(watch_mode.get("id", "")) == "leave":
				return
			# A gain reaction may run before/after a destination move.  Search all
			# owned zones so the resolver is robust to hand/deck destinations.
			var gained_card_found := false
			for zone in [player.hand, player.discard_pile, player.draw_pile]:
				if zone.has(gained_card):
					zone.erase(gained_card)
					gained_card_found = true
			if not gained_card_found:
				return
			if str(watch_mode.get("id", "")) == "trash":
				player.trash_pile.append(gained_card)
				_notify_cards_trashed(player, 1)
			else:
				player.draw_pile.append(gained_card)
		"tiara_gain_choice":
			var tiara_gain: CardDefinition = choice.context.get("gained_card")
			if tiara_gain == null or _selected_mode_id(selected) != "topdeck":
				return
			var gained_card_found := false
			for zone in [player.hand, player.discard_pile, player.draw_pile]:
				if zone.has(tiara_gain):
					gained_card_found = true
			if not gained_card_found:
				# A prior gain reaction (for example Watchtower) may have trashed
				# this card. Never resurrect a card that left all owned gain zones.
				return
			for zone in [player.hand, player.discard_pile, player.draw_pile]:
				zone.erase(tiara_gain)
			player.draw_pile.append(tiara_gain)
		"crystal_ball_choice":
			var crystal_card: CardDefinition = choice.context.get("card")
			if crystal_card == null:
				return
			var crystal_mode := _selected_mode(choice, selected)
			match str(crystal_mode.get("id", "")):
				"trash":
					player.trash_pile.append(crystal_card)
					_notify_cards_trashed(player, 1)
				"play":
					player.play_area.append(crystal_card)
					player.register_play_display(crystal_card, 1)
					_prepend_card_resolutions(crystal_card, 1)
				"discard":
					player.discard_pile.append(crystal_card)
				_:
					player.draw_pile.append(crystal_card)
func _resolve_relic_full_deck_trash(maximum: int) -> void:
	# A Culling Reliquary resolves before the normal hand draw. Gather the
	# holder's complete deck (draw + discard) into their hand, then pause on the
	# standard hand-trash choice so the UI can present the same direct controls.
	if not player.discard_pile.is_empty():
		player.draw_pile.append_array(player.discard_pile)
		player.discard_pile.clear()
		player.draw_pile.shuffle()
	while not player.draw_pile.is_empty():
		var card: CardDefinition = player.draw_pile.pop_back()
		if card != null:
			player.hand.append(card)
	if player.hand.is_empty():
		return
	_request_zone_choice(
		player.hand,
		"Culling Reliquary: choose up to %d cards from your deck to trash." % maximum,
		0,
		mini(maximum, player.hand.size()),
		"trash_hand",
		"TRASH SELECTED",
		"TRASH NONE",
		_hand_trash_choice_context({"relic_id": "culling_reliquary"})
	)


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
	# A choice may belong to a different seat than the player whose effect is
	# currently resolving (left-player War Chest naming and attack victims).
	# Temporarily make that seat authoritative; the continuation context tells
	# resolve_choice where to return after the decision.
	var requested_owner := int(choice.context.get("_choice_owner_index", -1))
	if requested_owner >= 0 and requested_owner < players.size() and requested_owner != active_player_index:
		# Opponent-choice continuations already carry the original initiating
		# seat. Preserve it while walking through a 3+ player sequence.
		if not choice.context.has("_choice_return_player_index"):
			choice.context["_choice_return_player_index"] = active_player_index
		_set_active_player(requested_owner, false)
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


## UI contract for a selection that trashes cards directly from the active hand.
## Keep this semantic marker independent of the rules resolver so presentation
## does not need to infer a destructive action from implementation details.
func _hand_trash_choice_context(context: Dictionary = {}) -> Dictionary:
	var tagged_context := context.duplicate(true)
	tagged_context["ui_choice_kind"] = "trash_from_hand"
	tagged_context["ui_source_zone"] = "hand"
	return tagged_context


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
		{
			"destination": destination,
			"ui_choice_kind": "gain_from_supply",
			"ui_source_zone": "supply",
		}
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
	var exclude_card_ids: Array = filter.get("exclude_card_ids", [])
	var exclude_victory := bool(filter.get("exclude_victory", false))
	for card in _get_gain_supply_cards():
		var effective_cost := get_non_buy_cost(card)
		if get_supply_count(card.id) <= 0:
			continue
		if effective_cost < min_cost or effective_cost > max_cost:
			continue
		if exact_cost != null and effective_cost != int(exact_cost):
			continue
		if not card_type.is_empty() and not card_has_type(card, card_type):
			continue
		if not exclude_card_id.is_empty() and card.id == exclude_card_id:
			continue
		if exclude_card_ids.has(card.id):
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
		{
			"destination": destination,
			"ui_choice_kind": "gain_from_supply",
			"ui_source_zone": "supply",
		}
	)
	for card in candidates:
		choice.add_candidate(
			"supply:%s" % card.id,
			card,
			"Cost %d | %d left" % [get_non_buy_cost(card), get_supply_count(card.id)]
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
	choice.context["ui_choice_kind"] = "mode"
	for index in range(modes.size()):
		var mode: Dictionary = modes[index]
		choice.add_candidate(
			"mode:%d:%s" % [choice.id, str(mode.get("id", index))],
			source_card,
			str(mode.get("label", "OPTION"))
		)
	_request_choice(choice)


func _request_war_chest_name(source_card: CardDefinition, max_cost: int) -> void:
	var modes: Array[Dictionary] = []
	var naming_candidates: Array[CardDefinition] = []
	for candidate_value in card_catalog.values():
		var candidate := candidate_value as CardDefinition
		if candidate != null:
			naming_candidates.append(candidate)
	naming_candidates.sort_custom(_is_catalog_card_before)
	for candidate in naming_candidates:
		modes.append({"id": candidate.id, "label": "NAME %s" % candidate.card_name})
	if modes.is_empty():
		return
	var left_player_index := active_player_index
	if players.size() > 1:
		# Turn order advances with +1, so that is the seat to this player's left.
		left_player_index = (active_player_index + 1) % players.size()
	_request_mode_choice(
		source_card,
		"The player to your left names a card you cannot gain with this chest.",
		modes,
		"war_chest_name",
		{
			"max_cost": max_cost,
			"_choice_owner_index": left_player_index,
			"_restore_before_resolution": left_player_index != active_player_index,
		}
	)


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
	player.add_coins(int(mode.get("gain_coins", 0)))


func _filter_hand_cards(effect: Dictionary) -> Array[CardDefinition]:
	var candidates: Array[CardDefinition] = []
	var card_type := str(effect.get("card_type", ""))
	var exclude_type := str(effect.get("exclude_type", ""))
	for card in player.hand:
		if not card_type.is_empty() and not card_has_type(card, card_type):
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
		if event == "trash":
			_notify_cards_trashed(player, cards.size())
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
	turn_flags["last_revealed_resource_count"] = found


func _gain_card_by_id(card_id: String, destination: String) -> void:
	if not card_catalog.has(card_id):
		return
	var card: CardDefinition = card_catalog[card_id]
	if not supply_piles.has(card_id):
		supply_piles[card_id] = _default_supply_count(card)
	if get_supply_count(card_id) <= 0:
		return
	_gain_from_supply(card, destination)


func scale_supply_count(amount: int) -> int:
	# Solo conquests use half-size piles (10 -> 5, 12 -> 6, ...) so a one-player
	# sprint ends sooner. Any table with two or more seats keeps full piles.
	if multiplayer_enabled:
		return amount
	return maxi(1, amount / 2)


func _default_supply_count(card: CardDefinition) -> int:
	var base_count := ACTION_SUPPLY_COUNT
	if card != null and card.id == "pebble_coin":
		base_count = PEBBLE_SIDE_SUPPLY_COUNT
	elif card != null and card.id == CURSE_CARD_ID:
		base_count = CURSE_SUPPLY_COUNT
	elif card != null and card.id == CROWNWEALTH_RESOURCE_ID:
		base_count = CROWNWEALTH_RESOURCE_SUPPLY_COUNT
	elif card != null and card.id == CROWNWEALTH_VICTORY_ID:
		base_count = (
			CROWNWEALTH_VICTORY_SUPPLY_COUNT_2P
			if players.size() <= 2
			else CROWNWEALTH_VICTORY_SUPPLY_COUNT_3P
		)
	else:
		match card.card_type:
			"victory":
				base_count = VICTORY_SUPPLY_COUNT
			"resource":
				base_count = RESOURCE_SUPPLY_COUNT
			"curse":
				base_count = CURSE_SUPPLY_COUNT
			_:
				base_count = ACTION_SUPPLY_COUNT
	return scale_supply_count(base_count)


func _hex_ward_intercepts(target: PlayerState, card: CardDefinition) -> bool:
	# Hex Ward: the first curse a player would gain each turn is trashed instead.
	if card.card_type != "curse" or not target.relics.has("hex_ward"):
		return false
	if bool(target.turn_flags.get("hex_ward_used", false)):
		return false
	target.turn_flags["hex_ward_used"] = true
	target.trash_pile.append(card)
	_notify_cards_trashed(target, 1)
	print("[Game] Hex Ward deflects %s to %s's trash" % [card.card_name, target.player_name])
	return true


func _notify_cards_trashed(target: PlayerState, amount: int) -> void:
	# Ashen Urn: a coin whenever one of the holder's cards is trashed.
	if amount <= 0 or not target.relics.has("ashen_urn"):
		return
	target.add_coins(amount)
	print("[Game] Ashen Urn grants %s %d coin(s)" % [target.player_name, amount])


func _gain_from_supply(card: CardDefinition, destination: String) -> bool:
	if not supply_piles.has(card.id) or get_supply_count(card.id) <= 0:
		return false
	supply_piles[card.id] = get_supply_count(card.id) - 1
	turn_flags["_last_gain_card_id"] = card.id
	if _hex_ward_intercepts(player, card):
		return true
	var resolved_destination := _resolve_supply_tokens_on_gain(card, destination)
	var set_aside_on_gain := _sets_aside_on_gain(card)
	if set_aside_on_gain or resolved_destination == "set_aside":
		player.set_aside_pile.append(card)
		resolved_destination = "set_aside"
	else:
		match resolved_destination:
			"hand":
				player.hand.append(card)
			"deck":
				player.draw_pile.append(card)
			"trash":
				player.trash_pile.append(card)
				_notify_cards_trashed(player, 1)
			_:
				player.discard_pile.append(card)
	if bool(turn_flags.get("travelling_fair", false)) and resolved_destination != "trash":
		var fair_choice := _new_choice(
			"You may put %s onto your deck." % card.card_name,
			0,
			1,
			"travelling_fair_choice",
			"PUT ON DECK",
			"LEAVE IT",
			{"gained_card": card, "destination": resolved_destination}
		)
		fair_choice.add_candidate("travelling-fair:%d" % fair_choice.id, card)
		_request_choice(fair_choice)
	# Hand reactions resolve before persistent played-card triggers. This makes a
	# Watchtower trash decisive: a later Tiara topdeck trigger cannot resurrect it.
	_prepend_gain_play_triggers(card, resolved_destination)
	_prepend_gain_reactions(card, resolved_destination)
	_prepend_triggered_effects(card, "gain", {"zone": resolved_destination, "card_id": card.id})
	_queue_gain_attacks(card)
	return true


func _sets_aside_on_gain(card: CardDefinition) -> bool:
	return false


func _resolve_supply_tokens_on_gain(card: CardDefinition, destination: String) -> String:
	# Adventures +1 pile tokens trigger when their pile card is played, not when
	# that card is gained.  Play resolution applies player-owned tokens via
	# _apply_pile_token_bonus; gains must leave both owned and legacy shared token
	# placements untouched.
	return destination


func _trash_from_play(card: CardDefinition) -> void:
	if player.play_area.has(card):
		player.play_area.erase(card)
		player.trash_pile.append(card)
		_notify_cards_trashed(player, 1)
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


func _draw_to_size_simple(target_size: int) -> void:
	# Watchtower-style draws never offer Library's action-card set-aside choice.
	while player.hand.size() < target_size:
		var card := _take_top_card()
		if card == null:
			return
		player.hand.append(card)


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


func _begin_ranger_inspect_top(amount: int) -> void:
	var revealed: Array[CardDefinition] = []
	var resources: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card == null:
			break
		revealed.append(card)
		if card_has_type(card, "resource"):
			resources.append(card)
	if resources.is_empty():
		_discard_revealed_cards(revealed)
		return
	_request_zone_choice(
		resources,
		"Choose one revealed resource to keep. Discard the rest.",
		1,
		1,
		"ranger_keep_resource",
		"KEEP RESOURCE",
		"SKIP",
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


func _begin_crystal_ball() -> void:
	var card := _take_top_card()
	if card == null:
		return
	var modes: Array[Dictionary] = [
		{"id": "keep", "label": "KEEP ON DECK"},
		{"id": "discard", "label": "DISCARD"},
		{"id": "trash", "label": "TRASH"},
	]
	if card.card_type == "action" or card_has_type(card, "resource"):
		modes.append({"id": "play", "label": "PLAY"})
	_request_mode_choice(
		card,
		"Choose what to do with the top card of your deck.",
		modes,
		"crystal_ball_choice",
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


func _each_other_player_draws(amount: int) -> void:
	# Scholar's Hall (Council Room): every player other than the active one draws.
	# Solo tables never see this card, so nobody draws when there is one player.
	if amount <= 0:
		return
	for index in range(players.size()):
		if index == active_player_index:
			continue
		var other := players[index]
		for _draw_index in range(amount):
			var drawn := _take_top_card_for_player(other)
			if drawn == null:
				break
			other.hand.append(drawn)


func _opponent_choice_context(
	kind: String,
	targets: Array[int],
	position: int,
	return_index: int,
	extra: Dictionary = {}
) -> Dictionary:
	var context: Dictionary = extra.duplicate(true)
	context["_opponent_choice"] = true
	context["_opponent_kind"] = kind
	context["_opponent_targets"] = targets.duplicate()
	context["_opponent_position"] = position
	context["_choice_owner_index"] = targets[position] if position < targets.size() else -1
	context["_choice_return_player_index"] = return_index
	return context


func _begin_vault_opponent_choice(
	targets: Array[int],
	position: int,
	return_index: int
) -> void:
	if position >= targets.size():
		if return_index >= 0 and return_index < players.size() and active_player_index != return_index:
			_set_active_player(return_index, false)
		return
	var target := players[targets[position]]
	if target.hand.is_empty():
		_begin_vault_opponent_choice(targets, position + 1, return_index)
		return
	var maximum := mini(2, target.hand.size())
	var choice := _new_choice(
		"You may discard up to 2 cards; draw 1 card only if you discard exactly 2.",
		0,
		maximum,
		"vault_discard",
		"DISCARD & DRAW",
		"DECLINE",
		_opponent_choice_context("vault", targets, position, return_index, {
			"allowed_selection_sizes": [0, 1, 2],
			"ui_choice_kind": "trash_from_hand",
			"ui_source_zone": "hand",
		})
	)
	for index in range(target.hand.size()):
		choice.add_candidate("opponent:%d:%d" % [choice.id, index], target.hand[index])
	_request_choice(choice)


func _begin_bishop_opponent_choice(
	targets: Array[int],
	position: int,
	return_index: int
) -> void:
	if position >= targets.size():
		if return_index >= 0 and return_index < players.size() and active_player_index != return_index:
			_set_active_player(return_index, false)
		return
	var target := players[targets[position]]
	if target.hand.is_empty():
		_begin_bishop_opponent_choice(targets, position + 1, return_index)
		return
	var choice := _new_choice(
		"You may trash a card from your hand.",
		0,
		1,
		"bishop_trash",
		"TRASH",
		"DECLINE",
		_opponent_choice_context("bishop", targets, position, return_index, {
			"allowed_selection_sizes": [0, 1],
			"ui_choice_kind": "trash_from_hand",
			"ui_source_zone": "hand",
		})
	)
	for index in range(target.hand.size()):
		choice.add_candidate("opponent:%d:%d" % [choice.id, index], target.hand[index])
	_request_choice(choice)


func _continue_opponent_choice(context: Dictionary) -> void:
	var kind := str(context.get("_opponent_kind", ""))
	var targets: Array[int] = []
	for target_index in context.get("_opponent_targets", []):
		targets.append(int(target_index))
	var position := int(context.get("_opponent_position", 0)) + 1
	var return_index := int(context.get("_choice_return_player_index", -1))
	match kind:
		"vault":
			_begin_vault_opponent_choice(targets, position, return_index)
		"bishop":
			_begin_bishop_opponent_choice(targets, position, return_index)
		"sealed_treaty":
			_begin_sealed_treaty_choice(targets, position, return_index, int(context.get("target_hand_size", 5)))
		"rabble":
			_begin_rabble_opponent_choice(targets, position, return_index, int(context.get("amount", 3)))


func _vault_other_players() -> void:
	var targets: Array[int] = []
	var return_index := active_player_index
	for target in _get_attack_targets():
		var index := players.find(target)
		if index >= 0 and not target.hand.is_empty():
			targets.append(index)
	_begin_vault_opponent_choice(targets, 0, return_index)


func _bishop_other_players() -> void:
	# Bishop's optional trash is explicitly for other players. In solo there
	# are no eligible opponents, so do not loop back to the owner for a second
	# optional choice after resolving the required self-trash.
	if players.size() <= 1:
		return
	var targets: Array[int] = []
	var return_index := active_player_index
	for target in _get_attack_targets():
		var index := players.find(target)
		if index >= 0 and not target.hand.is_empty():
			targets.append(index)
	_begin_bishop_opponent_choice(targets, 0, return_index)


func _get_attack_targets() -> Array[PlayerState]:
	if players.size() <= 1:
		return [player]
	var targets: Array[PlayerState] = []
	for offset in range(1, players.size()):
		var index := (active_player_index + offset) % players.size()
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
	var return_index := active_player_index
	var target_index := players.find(target)
	if target_index < 0:
		return
	# Run the normal gain pipeline as the target owner so their Watchtower,
	# Hoard/Collection, Clerk-style hooks, and gain attacks see the event.
	_set_active_player(target_index, false)
	turn_flags["_gain_return_player_index"] = return_index
	var gained := _gain_from_supply(card, destination)
	turn_flags.erase("_gain_return_player_index")
	if not gained:
		_set_active_player(return_index, false)
		return
	if has_pending_choice():
		pending_choice.context["_choice_return_player_index"] = return_index
		pending_choice.context["_defer_return_until_queue_empty"] = true
		return
	_process_resolution_queue()
	if not has_pending_choice() and active_player_index != return_index:
		_set_active_player(return_index, false)


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
			_notify_cards_trashed(target, 1)
		else:
			revealed.append(card)
	target.discard_pile.append_array(revealed)


func _is_attack_protected(target: PlayerState) -> bool:
	for permanent in target.play_area:
		if permanent.id == "champion":
			return true
	var timed_protections: Dictionary = target.turn_flags.get("timed_attack_immunity", {})
	return (
		not timed_protections.is_empty()
		or
		_zone_has_attack_immunity(target.play_area, "play")
		or _zone_has_attack_immunity(target.hand, "hand")
	)


func _zone_has_attack_immunity(zone: Array[CardDefinition], zone_name: String) -> bool:
	for card in zone:
		for effect in card.special_effects:
			if (
				str(effect.get("kind", "")) == "attack_immunity"
				and str(effect.get("zone", "")) == zone_name
			):
				return true
	return false


func _resolve_attack(effect: Dictionary, _source_card: CardDefinition) -> void:
	var targets: Array[PlayerState] = []
	for target in _get_attack_targets():
		if _is_attack_protected(target):
			print("[Game] %s is protected from the attack" % target.player_name)
			continue
		target.times_attacked += 1
		targets.append(target)
	match str(effect.get("mode", "gain_curse")):
		"gain_curse":
			for target in targets:
				var target_index := players.find(target)
				for _index in range(int(effect.get("amount", 1))):
					if target_index < 0:
						continue
					# Queue each target gain so a victim's reaction choice pauses the
					# attack and resumes the next victim in turn order afterward.
					resolution_queue.push_back({
						"kind": "target_gain",
						"target_index": target_index,
						"card_id": str(effect.get("card_id", CURSE_CARD_ID)),
						"destination": str(effect.get("destination", "discard")),
					})
		"minus_card_token":
			for target in targets:
				target.put_deck_minus_card_token()
		"raid":
			for target in targets:
				target.put_deck_minus_card_token()
		"giant":
			for target in targets:
				var giant_revealed := _take_top_card_for_player(target)
				if giant_revealed == null:
					continue
				if giant_revealed.cost >= 3 and giant_revealed.cost <= 6:
					target.trash_pile.append(giant_revealed)
					_notify_cards_trashed(target, 1)
				else:
					target.discard_pile.append(giant_revealed)
					# A card that Giant discards still causes its discard reactions.
					# Opponent discard reactions are intentionally not interactive here;
					# the revealed card is already owned by the target and remains in its
					# discard pile.
					_gain_card_by_id_for_player("briar_hex", "discard", target)
		"warrior":
			var traveller_count := 0
			for own_card in player.play_area:
				if own_card.is_traveller_card():
					traveller_count += 1
			for target in targets:
				for _traveller_index in range(traveller_count):
					var warrior_revealed := _take_top_card_for_player(target)
					if warrior_revealed == null:
						continue
					if warrior_revealed.cost == 3 or warrior_revealed.cost == 4:
						target.trash_pile.append(warrior_revealed)
						_notify_cards_trashed(target, 1)
					else:
						target.discard_pile.append(warrior_revealed)
		"soldier":
			for target in targets:
				if target.hand.size() < 4:
					continue
				if target == player:
					_request_zone_choice(target.hand, "Choose a card to discard.", 1, 1, "discard_hand", "DISCARD")
				else:
					var soldier_discard := target.hand.back() as CardDefinition
					_move_cards(target.hand, target.discard_pile, [soldier_discard], "discard")
		"champion":
			player.turn_flags["champion_active"] = true
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
		"discard_resource":
			for target in targets:
				var resource_cards: Array[CardDefinition] = []
				for target_card in target.hand:
					if target_card.card_type == "resource":
						resource_cards.append(target_card)
				if resource_cards.is_empty():
					continue
				if target == player:
					_request_zone_choice(resource_cards, "Choose a resource to discard.", 1, 1, "discard_hand", "DISCARD")
				else:
					_move_cards(target.hand, target.discard_pile, [resource_cards[0]], "discard")
		"discard_one":
			for target in targets:
				if target.hand.is_empty():
					continue
				if target == player:
					_request_zone_choice(target.hand, "Choose a card to discard.", 1, 1, "discard_hand", "DISCARD")
				else:
					var discarded: CardDefinition = target.hand.back() as CardDefinition
					_move_cards(target.hand, target.discard_pile, [discarded], "discard")
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
		"topdeck_hand_size":
			var treaty_targets: Array[int] = []
			for target in targets:
				var target_index := players.find(target)
				if target.hand.size() < int(effect.get("target_hand_size", 5)):
					continue
				treaty_targets.append(target_index)
			_begin_sealed_treaty_choice(
				treaty_targets,
				0,
				active_player_index,
				int(effect.get("target_hand_size", 5))
			)
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
		"reveal_discard_reorder":
			var rabble_targets: Array[int] = []
			for target in targets:
				var target_index := players.find(target)
				if target_index >= 0:
					rabble_targets.append(target_index)
			if rabble_targets.is_empty():
				_begin_rabble_attack(int(effect.get("amount", 3)))
			else:
				_begin_rabble_opponent_choice(
					rabble_targets,
					0,
					active_player_index,
					int(effect.get("amount", 3))
				)
		"extend_cooldown":
			# A tempo attack: victims' end-turn cooldowns run longer this turn.
			# The reduction field is per-turn, so a negative value is an extension.
			for target in targets:
				target.end_turn_cooldown_reduction -= float(effect.get("amount", 1.0))
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


func _begin_rabble_attack(amount: int) -> void:
	var revealed: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card()
		if card != null:
			revealed.append(card)
	if revealed.is_empty():
		return
	var discard_candidates: Array[CardDefinition] = []
	for card in revealed:
		if card_has_type(card, "resource") or card.card_type == "action":
			discard_candidates.append(card)
	if discard_candidates.is_empty():
		for index in range(revealed.size() - 1, -1, -1):
			player.draw_pile.append(revealed[index])
		return
	_request_zone_choice(
		discard_candidates,
		"Discard the revealed resources and actions.",
		discard_candidates.size(),
		discard_candidates.size(),
		"rabble_discard",
		"DISCARD",
		"DISCARD ALL",
		{"revealed": revealed}
	)


func _begin_sealed_treaty_choice(
	targets: Array[int],
	position: int,
	return_index: int,
	target_hand_size: int
) -> void:
	if position >= targets.size():
		if return_index >= 0 and return_index < players.size() and active_player_index != return_index:
			_set_active_player(return_index, false)
		return
	var target := players[targets[position]]
	if target.hand.size() < target_hand_size:
		_begin_sealed_treaty_choice(targets, position + 1, return_index, target_hand_size)
		return
	var choice := _new_choice(
		"Choose a card to put on top of your deck.",
		1,
		1,
		"topdeck_hand",
		"PUT ON DECK",
		"SKIP",
		_opponent_choice_context("sealed_treaty", targets, position, return_index, {
			"target_hand_size": target_hand_size,
			"ui_choice_kind": "trash_from_hand",
			"ui_source_zone": "hand",
		})
	)
	for index in range(target.hand.size()):
		choice.add_candidate("opponent:%d:%d" % [choice.id, index], target.hand[index])
	_request_choice(choice)


func _begin_rabble_opponent_choice(
	targets: Array[int],
	position: int,
	return_index: int,
	amount: int
) -> void:
	if position >= targets.size():
		if return_index >= 0 and return_index < players.size() and active_player_index != return_index:
			_set_active_player(return_index, false)
		return
	var target := players[targets[position]]
	var revealed: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card_for_player(target)
		if card != null:
			revealed.append(card)
	if revealed.is_empty():
		_begin_rabble_opponent_choice(targets, position + 1, return_index, amount)
		return
	var discard_candidates: Array[CardDefinition] = []
	var keep: Array[CardDefinition] = []
	for card in revealed:
		if card_has_type(card, "resource") or card.card_type == "action":
			discard_candidates.append(card)
		else:
			keep.append(card)
	for card in discard_candidates:
		target.discard_pile.append(card)
	if keep.size() <= 1:
		for index in range(keep.size() - 1, -1, -1):
			target.draw_pile.append(keep[index])
		_begin_rabble_opponent_choice(targets, position + 1, return_index, amount)
		return
	var context := _opponent_choice_context("rabble", targets, position, return_index, {
		"amount": amount,
		"rabble_phase": "order",
		"remaining": keep,
		"ordered": [],
	})
	var choice := _new_choice(
		"Choose the next revealed card to put on top of your deck.",
		1,
		1,
		"rabble_opponent_order",
		"PUT NEXT",
		"SKIP",
		context
	)
	for index in range(keep.size()):
		choice.add_candidate("opponent-rabble:%d:%d" % [choice.id, index], keep[index])
	_request_choice(choice)


func _resolve_rabble_for_player(target: PlayerState, amount: int) -> void:
	var revealed: Array[CardDefinition] = []
	for _index in range(amount):
		var card := _take_top_card_for_player(target)
		if card != null:
			revealed.append(card)
	var keep: Array[CardDefinition] = []
	for card in revealed:
		if card_has_type(card, "resource") or card.card_type == "action":
			target.discard_pile.append(card)
		else:
			keep.append(card)
	for index in range(keep.size() - 1, -1, -1):
		target.draw_pile.append(keep[index])


func _finish_attack_reveal_resource(
	revealed: Array[CardDefinition],
	trashed_cards: Array[CardDefinition]
) -> void:
	for card in trashed_cards:
		revealed.erase(card)
	player.trash_pile.append_array(trashed_cards)
	_notify_cards_trashed(player, trashed_cards.size())
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
	player.register_play_display(source_card, 1)
	_prepend_card_resolutions(source_card, 1)


func _has_other_action_in_play(source_card: CardDefinition) -> bool:
	for card in player.play_area:
		if card.card_type == "action" and card != source_card:
			return true
	return false


func buy_card(card: CardDefinition) -> bool:
	if is_event_card(card):
		return buy_event(card)
	if (
		card == null
		or has_pending_choice()
		or (not market.has(card) and not is_side_supply_card(card.id))
		or get_supply_count(card.id) <= 0
	):
		return false
	var effective_cost := get_effective_cost(card)
	if player.buys <= 0 or bool(turn_flags.get("mission_no_buys", false)) or player.coins < effective_cost:
		return false
	if _buy_restricted_by_played_card(card):
		return false
	player.coins -= effective_cost
	player.buys -= 1
	var messenger_watchers := int(turn_flags.get("messenger_first_buy_count", 0))
	if messenger_watchers > 0:
		turn_flags["messenger_first_buy_count"] = 0
	# Thumbed Ledger: the first purchase each turn rebates two coins.
	if (
		player.relics.has("thumbed_ledger")
		and not bool(turn_flags.get("thumbed_ledger_used", false))
	):
		turn_flags["thumbed_ledger_used"] = true
		player.add_coins(2)
		print("[Game] Thumbed Ledger rebates %s 2 coins" % player.player_name)
	_gain_from_supply(card, "discard")
	if get_active_player_supply_token_card("trash") == card.id:
		resolution_queue.push_back({
			"kind": "special",
			"source_card": card,
			"effect": {
				"kind": "plan_buy_trash",
				"bought_card_id": card.id,
				"expansion_token": "trash",
			},
		})
	if messenger_watchers > 0:
		for _messenger_index in range(messenger_watchers):
			resolution_queue.push_back({
				"kind": "special",
				"source_card": card_catalog.get("messenger"),
				"effect": {"kind": "messenger_gain", "max_cost": 4},
			})
	_resolve_registered_buy_attacks()
	player.add_coins(int(turn_flags.get("buy_coin_bonus", 0)))
	_prepend_buy_play_triggers(card)
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


func _resolve_registered_buy_attacks() -> void:
	# Haunted Woods-style buy attacks are attached to the player who played the
	# card, but affect the buyer (and not that owner) when another seat buys.
	if players.size() <= 1:
		return
	for owner_index in range(players.size()):
		if owner_index == active_player_index:
			continue
		var owner := players[owner_index]
		for owned in owner.play_area:
			for effect in owned.special_effects:
				if str(effect.get("kind", "")) != "register_buy_attack":
					continue
				if _is_attack_protected(player):
					continue
				var attack: Dictionary = effect.get("attack", {}).duplicate(true)
				if str(attack.get("mode", "")) == "topdeck_hand":
					var hand_copy := player.hand.duplicate()
					player.hand.clear()
					player.draw_pile.append_array(hand_copy)


func _buy_restricted_by_played_card(card: CardDefinition) -> bool:
	# Restrictions belong to the pile being bought, rather than requiring a
	# copy of that card to already be in play.
	for effect in card.special_effects:
			if str(effect.get("kind", "")) != "buy_restriction":
				continue
			var required_id := str(effect.get("requirement_card_id", ""))
			if required_id.is_empty():
				continue
			for in_play in player.play_area:
				if in_play.id == required_id:
					return true
	return false


func begin_cleanup() -> void:
	if cleanup_in_progress:
		return
	previous_turn_player_index = active_player_index
	cleanup_in_progress = true
	player.cleanup_in_progress = true
	_cleanup_tavern_mat()
	if not turn_flags.has("cleanup_traveller_seen"):
		turn_flags["cleanup_traveller_seen"] = []
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


func _cleanup_tavern_mat() -> void:
	# Most Reserve cards remain on the Tavern mat indefinitely.  Cards with an
	# explicit end-of-buy/cleanup condition (Wine Merchant-style) opt in through
	# data and are discarded here, after the Buy phase has ended.
	for reserved in player.reserve_mat.duplicate():
		for effect in reserved.special_effects:
			var kind := str(effect.get("kind", ""))
			if kind == "wine_merchant_call":
				if player.coins >= 2:
					player.reserve_mat.erase(reserved)
					player.discard_pile.append(reserved)
				break
			if kind not in ["reserve_cleanup", "tavern_cleanup", "discard_reserve_if"]:
				continue
			var threshold := int(effect.get("minimum_coins", effect.get("min_coins", effect.get("amount", 0))))
			if player.coins < threshold or bool(effect.get("requires_unspent_buys", false)) and player.buys <= 0:
				continue
			player.reserve_mat.erase(reserved)
			player.discard_pile.append(reserved)
			break


func _finish_cleanup() -> void:
	if _request_cleanup_traveller_exchange():
		return
	# Duration cards played this turn stay in play until the next cleanup.
	var kept_durations: Array[CardDefinition] = []
	for card in player.duration_hold:
		var play_index := player.play_area.find(card)
		if play_index != -1:
			player.play_area.remove_at(play_index)
			kept_durations.append(card)
	# Champion's text says it stays in play for the rest of the game even though
	# its data has no per-turn payload. Treat it as a permanent duration card.
	for card in player.play_area:
		if card.id == "champion" and not kept_durations.has(card):
			kept_durations.append(card)
	player.duration_hold.clear()
	var hand_count := player.hand.size()
	var play_count := player.play_area.size()
	player.discard_pile.append_array(player.hand)
	player.discard_pile.append_array(player.play_area)
	player.hand.clear()
	player.play_area.clear()
	player.clear_play_display_records()
	player.play_area.append_array(kept_durations)
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


func _request_cleanup_traveller_exchange() -> bool:
	var seen: Array = turn_flags.get("cleanup_traveller_seen", [])
	for card in player.play_area:
		if card == null or not card.is_traveller_card() or card.traveller_upgrade_id.is_empty():
			continue
		if seen.has(card):
			continue
		if get_traveller_supply_count(card.traveller_upgrade_id) <= 0 and get_supply_count(card.traveller_upgrade_id) <= 0:
			seen.append(card)
			continue
		seen.append(card)
		turn_flags["cleanup_traveller_seen"] = seen
		var choice := _new_choice(
			"You may exchange %s for %s." % [card.card_name, card_catalog[card.traveller_upgrade_id].card_name if card_catalog.has(card.traveller_upgrade_id) else card.traveller_upgrade_id],
			0,
			1,
			"traveller_cleanup",
			"EXCHANGE",
			"KEEP",
			{
				"traveller_card": card,
				"effect": {"upgrade_to": card.traveller_upgrade_id, "cleanup_exchange": true},
			}
		)
		choice.add_candidate("traveller-cleanup:%d" % choice.id, card)
		_request_choice(choice)
		return true
	return false


func discard_hand_and_play_area() -> void:
	begin_cleanup()


func calculate_score() -> int:
	return _calculate_score_for_player(player)


func get_current_victory_points(target: PlayerState = null) -> int:
	# HUD/player-status callers need the live tally without emitting the verbose
	# end-game scoring log on every refresh.
	return _calculate_score_for_player(target if target != null else player, false)


func calculate_all_scores() -> Array[int]:
	var scores: Array[int] = []
	for game_player in players:
		scores.append(_calculate_score_for_player(game_player))
	return scores


func _calculate_score_for_player(scored_player: PlayerState, announce: bool = true) -> int:
	var score := 0
	var owned_cards := scored_player.get_all_cards()
	var owned_counts := {}
	for card in owned_cards:
		owned_counts[card.id] = int(owned_counts.get(card.id, 0)) + 1
	for card in owned_cards:
		score += card.victory_points
		if card.score_per_cards > 0:
			score += owned_cards.size() / card.score_per_cards
		if card.score_per_trashed > 0:
			score += scored_player.trash_pile.size() / card.score_per_trashed
		if not card.score_card_id.is_empty():
			score += int(owned_counts.get(card.score_card_id, 0)) * card.score_card_points
		score += _scoring_effect_bonus(card, owned_cards, scored_player)
	score += _scoring_relic_bonus(scored_player)
	score += scored_player.vp_tokens
	if announce:
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


func _scoring_effect_bonus(
	card: CardDefinition,
	owned_cards: Array[CardDefinition],
	scored_player: PlayerState = null
) -> int:
	if card == null:
		return 0
	var total := 0
	for effect in card.special_effects:
		if str(effect.get("trigger", "")) != "scoring":
			continue
		match str(effect.get("kind", "")):
			"distant_lands_score":
				if effect.has("on_mat_points"):
					if scored_player != null and scored_player.reserve_mat.has(card):
						total += int(effect.get("on_mat_points", 0))
					continue
				var types: Dictionary = {}
				for owned_card in owned_cards:
					if not owned_card.card_type.is_empty():
						types[owned_card.card_type] = true
				total += mini(
					int(effect.get("maximum", 999)),
					types.size() * int(effect.get("per_type", 1))
				)
	return total


func _count_cards_of_type(cards: Array[CardDefinition], card_type: String) -> int:
	var total := 0
	for card in cards:
		if card_has_type(card, card_type):
			total += 1
	return total


func _count_cards_with_id(cards: Array[CardDefinition], card_id: String) -> int:
	var total := 0
	for card in cards:
		if card.id == card_id:
			total += 1
	return total


func _scoring_relic_bonus(scored_player: PlayerState) -> int:
	var relic_id := scored_player.scoring_relic
	if relic_id.is_empty() or not RelicCatalog.has_scoring_relic(relic_id):
		return 0
	var owned := scored_player.get_all_cards()
	match relic_id:
		"warlords_tribute":
			return _count_cards_of_type(owned, "action")
		"hoarders_vault":
			return _count_cards_of_type(owned, "resource") / 2
		"crown_of_conquest":
			return _count_cards_of_type(owned, "victory")
		"ascetics_reliquary":
			return scored_player.trash_pile.size() * 2
		"merchants_charter":
			return owned.size() / 3
		"purists_medallion":
			return 10 if owned.size() <= 16 else 0
		"hexbreakers_idol":
			return _count_cards_with_id(owned, CURSE_CARD_ID) * 2
		"wanderers_map":
			var names := {}
			for card in owned:
				names[card.id] = true
			return names.size()
	return 0


func generate_scoring_relic_offer() -> Array[String]:
	# Two random scoring relics for the solo end-game draft.
	var pool := RelicCatalog.get_scoring_pool()
	pool.shuffle()
	var offer: Array[String] = []
	for index in range(mini(RelicCatalog.SCORING_OFFER_SIZE, pool.size())):
		offer.append(pool[index])
	return offer


func choose_scoring_relic(target: PlayerState, relic_id: String) -> bool:
	if target == null or not RelicCatalog.has_scoring_relic(relic_id):
		return false
	target.scoring_relic = relic_id
	print("[Game] %s drafts scoring relic: %s" % [
		target.player_name, RelicCatalog.get_scoring_relic_name(relic_id)
	])
	return true


func calculate_score_breakdown(scored_player: PlayerState) -> Array:
	# Row list [{ "label": String, "points": int }] mirroring the score tally,
	# used by the end-of-game summary. The rows sum to the player's final score.
	var owned_cards := scored_player.get_all_cards()
	var owned_counts := {}
	for card in owned_cards:
		owned_counts[card.id] = int(owned_counts.get(card.id, 0)) + 1
	var rows: Array = []
	var vp_by_name := {}
	var vp_order: Array[String] = []
	for card in owned_cards:
		if card.victory_points != 0:
			if not vp_by_name.has(card.card_name):
				vp_order.append(card.card_name)
			vp_by_name[card.card_name] = int(vp_by_name.get(card.card_name, 0)) + card.victory_points
	for card_name in vp_order:
		rows.append({"label": card_name, "points": int(vp_by_name[card_name])})
	for card_id in owned_counts:
		var card: CardDefinition = card_catalog[card_id]
		var count := int(owned_counts[card_id])
		var bonus := 0
		if card.score_per_cards > 0:
			bonus += count * (owned_cards.size() / card.score_per_cards)
		if card.score_per_trashed > 0:
			bonus += count * (scored_player.trash_pile.size() / card.score_per_trashed)
		if not card.score_card_id.is_empty():
			bonus += count * int(owned_counts.get(card.score_card_id, 0)) * card.score_card_points
		bonus += count * _scoring_effect_bonus(card, owned_cards)
		if bonus != 0:
			rows.append({"label": card.card_name, "points": bonus})
	var relic_bonus := _scoring_relic_bonus(scored_player)
	if relic_bonus != 0:
		rows.append({
			"label": RelicCatalog.get_scoring_relic_name(scored_player.scoring_relic),
			"points": relic_bonus,
		})
	if scored_player.vp_tokens != 0:
		rows.append({"label": "Victory tokens", "points": scored_player.vp_tokens})
	return rows
