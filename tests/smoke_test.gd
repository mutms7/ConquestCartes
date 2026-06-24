extends SceneTree

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

var failure_count := 0


func _initialize() -> void:
	_test_full_game_loop()
	_test_draw_across_shuffle_boundary()
	_test_scoring_includes_every_owned_zone()

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

	game_state.player.coins = 6
	var purchased_card: CardDefinition = game_state.card_catalog["royal_charter"]
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
	_check(turn_manager.final_score == 8, "Final score should include bought victory cards.")
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
