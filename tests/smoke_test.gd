extends SceneTree

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

const NEW_CARD_IDS := [
	"candlecap",
	"trail_biscuit",
	"moss_thread",
	"acorn_purse",
	"hearthsong",
	"orchard_map",
	"river_courier",
	"moonwell_token",
	"tinker_wren",
	"lantern_parade",
	"quiet_archive",
	"briar_gate",
	"starlit_wagon",
	"amber_circlet",
	"firefly_supper",
	"wishing_stone",
]

var failure_count := 0


func _initialize() -> void:
	_test_full_game_loop()
	_test_draw_across_shuffle_boundary()
	_test_scoring_includes_every_owned_zone()
	_test_expanded_card_set()
	_test_random_market_setup()

	if failure_count > 0:
		push_error("[Test] Rules smoke test failed with %d issue(s)." % failure_count)
		quit(1)
		return

	print("[Test] Rules smoke test passed.")
	quit(0)


func _test_full_game_loop() -> void:
	seed(7)
	var game_state := _create_game_state()
	if game_state == null:
		return

	var turn_manager := TurnManager.new()
	turn_manager.configure(game_state)
	turn_manager.start_first_turn()
	_check(game_state.player.hand.size() == 5, "First hand should contain five cards.")
	_check(_owned_card_count(game_state) == 10, "Starting deck should contain ten cards.")

	var resource_card: CardDefinition = null
	for card in game_state.player.hand:
		if card.card_type == "resource":
			resource_card = card
			break
	_check(resource_card != null, "Starting hand should contain a playable resource.")
	if resource_card != null:
		_check(game_state.play_card(resource_card), "Resource card should be playable.")
		_check(game_state.player.coins > 0, "Playing a resource should add coins.")

	var purchased_card: CardDefinition = game_state.market[0]
	game_state.player.coins = purchased_card.cost
	_check(game_state.buy_card(purchased_card), "Affordable market card should be bought.")
	_check(game_state.player.discard_pile.has(purchased_card), "Bought card should enter discard.")
	_check(_owned_card_count(game_state) == 11, "Buying should add exactly one owned card.")

	var purchased_card_cycled := false
	while not turn_manager.game_over:
		turn_manager.end_turn()
		if (
			game_state.player.draw_pile.has(purchased_card)
			or game_state.player.hand.has(purchased_card)
			or game_state.player.play_area.has(purchased_card)
		):
			purchased_card_cycled = true

	_check(purchased_card_cycled, "Bought card should later cycle out of discard.")
	_check(turn_manager.turn_number == 15, "Game should end on turn 15.")
	_check(
		turn_manager.final_score == 3 + purchased_card.victory_points,
		"Final score should include the purchased card."
	)
	_check(game_state.player.hand.is_empty(), "Final cleanup should empty the hand.")
	_check(game_state.player.play_area.is_empty(), "Final cleanup should empty the play area.")
	_check(game_state.player.coins == 0, "Final cleanup should reset coins.")
	_check(game_state.player.actions == 1, "Final cleanup should reset actions.")
	_check(game_state.player.buys == 1, "Final cleanup should reset buys.")
	_check(_owned_card_count(game_state) == 11, "Cards should not be lost or duplicated.")


func _test_draw_across_shuffle_boundary() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return

	game_state.player.clear_all()
	var first_card: CardDefinition = game_state.card_catalog["pebble_coin"]
	var discarded_card: CardDefinition = game_state.card_catalog["silver_leaf"]
	game_state.player.draw_pile.append(first_card)
	game_state.player.discard_pile.append(discarded_card)

	game_state.draw_cards(2)

	_check(game_state.player.hand.size() == 2, "Draw should continue after shuffling discard.")
	_check(game_state.player.hand.has(first_card), "Draw should include the remaining deck card.")
	_check(game_state.player.hand.has(discarded_card), "Draw should include the shuffled discard card.")
	_check(game_state.player.draw_pile.is_empty(), "Boundary draw should consume the two cards.")
	_check(game_state.player.discard_pile.is_empty(), "Shuffled discard should be cleared.")


func _test_scoring_includes_every_owned_zone() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return

	game_state.player.clear_all()
	var homestead: CardDefinition = game_state.card_catalog["homestead"]
	var royal_charter: CardDefinition = game_state.card_catalog["royal_charter"]
	game_state.player.draw_pile.append(homestead)
	game_state.player.hand.append(homestead)
	game_state.player.play_area.append(homestead)
	game_state.player.discard_pile.append(royal_charter)

	_check(game_state.calculate_score() == 8, "Scoring should include draw, hand, play, and discard.")


func _test_expanded_card_set() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return

	_check(NEW_CARD_IDS.size() == 16, "Expanded set should contain sixteen new cards.")
	for card_id in NEW_CARD_IDS:
		_check(game_state.card_catalog.has(card_id), "Card data should include %s." % card_id)
		if not game_state.card_catalog.has(card_id):
			continue

		var card: CardDefinition = game_state.card_catalog[card_id]
		_check(
			game_state.get_market_candidates().has(card),
			"%s should be eligible for random markets." % card.card_name
		)
		_check(card.cost >= 2 and card.cost <= 7, "%s should use a supported cost tier." % card.card_name)
		_test_card_purchase(game_state, card)

		if card.card_type == "victory":
			_test_victory_card(game_state, card)
		else:
			_test_playable_card(game_state, card)


func _test_card_purchase(game_state: GameState, card: CardDefinition) -> void:
	game_state.player.clear_all()
	game_state.market.assign([card])
	game_state.player.coins = card.cost
	_check(game_state.buy_card(card), "%s should be purchasable." % card.card_name)
	_check(
		game_state.player.discard_pile.has(card),
		"%s should enter discard after purchase." % card.card_name
	)


func _test_playable_card(game_state: GameState, card: CardDefinition) -> void:
	game_state.player.clear_all()
	game_state.player.actions = 10
	game_state.player.buys = 1
	game_state.player.coins = 0
	game_state.player.hand.append(card)

	var filler: CardDefinition = game_state.card_catalog["pebble_coin"]
	for _draw_index in range(card.draw_cards):
		game_state.player.draw_pile.append(filler)

	var starting_actions := game_state.player.actions
	var starting_buys := game_state.player.buys
	_check(game_state.play_card(card), "%s should play without errors." % card.card_name)
	_check(game_state.player.play_area.has(card), "%s should enter the play area." % card.card_name)
	_check(
		game_state.player.coins == card.coin_value + card.gain_coins,
		"%s should apply its coin effect." % card.card_name
	)
	var action_cost := 1 if card.card_type == "action" else 0
	_check(
		game_state.player.actions == starting_actions - action_cost + card.gain_actions,
		"%s should apply its action effect." % card.card_name
	)
	_check(
		game_state.player.buys == starting_buys + card.gain_buys,
		"%s should apply its buy effect." % card.card_name
	)
	_check(
		game_state.player.hand.size() == card.draw_cards,
		"%s should draw the configured number of cards." % card.card_name
	)


func _test_victory_card(game_state: GameState, card: CardDefinition) -> void:
	game_state.player.clear_all()
	game_state.player.discard_pile.append(card)
	_check(
		game_state.calculate_score() == card.victory_points,
		"%s should contribute its configured victory points." % card.card_name
	)


func _test_random_market_setup() -> void:
	seed(11)
	var game_state := _create_game_state()
	if game_state == null:
		return

	var first_market := game_state.get_market_card_ids()
	_check(first_market.size() == GameState.MARKET_SIZE, "Market should contain six cards.")
	_check(
		game_state.get_market_candidates().size() == game_state.card_catalog.size() - 2,
		"Every non-starter card should be market-eligible."
	)
	for starter_id in GameState.STARTING_CARD_COUNTS:
		_check(not first_market.has(starter_id), "Starter cards should not enter the market.")

	game_state.player.discard_pile.append(game_state.card_catalog["silver_leaf"])
	game_state.player.coins = 9
	_check(game_state.setup_starting_game(), "New game setup should succeed.")
	var second_market := game_state.get_market_card_ids()

	_check(
		not _same_card_ids(first_market, second_market),
		"An immediate new game should choose a different market."
	)
	_check(_owned_card_count(game_state) == 10, "New game should restore the ten-card deck.")
	_check(game_state.player.discard_pile.is_empty(), "New game should clear discard.")
	_check(game_state.player.hand.is_empty(), "New game setup should clear hand before drawing.")
	_check(game_state.player.play_area.is_empty(), "New game should clear played cards.")
	_check(game_state.player.coins == 0, "New game should reset coins.")


func _same_card_ids(first: Array[String], second: Array[String]) -> bool:
	if first.size() != second.size():
		return false
	for card_id in first:
		if not second.has(card_id):
			return false
	return true


func _create_game_state() -> GameState:
	var game_state := GameState.new()
	if not game_state.load_cards(CARD_DATA_PATH):
		_check(false, "Card data should load.")
		return null
	if not game_state.setup_starting_game():
		_check(false, "Starting game should be created.")
		return null
	return game_state


func _owned_card_count(game_state: GameState) -> int:
	return game_state.player.get_all_cards().size()


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error("[Test] %s" % message)
