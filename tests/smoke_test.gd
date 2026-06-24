extends SceneTree

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"


func _initialize() -> void:
	seed(7)
	var game_state := GameState.new()
	var turn_manager := TurnManager.new()
	turn_manager.configure(game_state)

	_check(game_state.load_cards(CARD_DATA_PATH), "Card data should load.")
	_check(game_state.setup_starting_game(), "Starting game should be created.")
	turn_manager.start_first_turn()
	_check(game_state.player.hand.size() == 5, "First hand should contain five cards.")

	var resource_card: CardDefinition = null
	for card in game_state.player.hand:
		if card.card_type == "resource":
			resource_card = card
			break
	_check(resource_card != null, "Starting hand should contain a playable resource.")
	_check(game_state.play_card(resource_card), "Resource card should be playable.")
	_check(game_state.player.coins > 0, "Playing a resource should add coins.")

	game_state.player.coins = 6
	var purchased_card: CardDefinition = game_state.card_catalog["royal_charter"]
	_check(game_state.buy_card(purchased_card), "Affordable market card should be bought.")
	_check(game_state.player.discard_pile.has(purchased_card), "Bought card should enter discard.")

	while not turn_manager.game_over:
		turn_manager.end_turn()

	_check(turn_manager.turn_number == 15, "Game should end on turn 15.")
	_check(turn_manager.final_score == 8, "Final score should include all owned victory cards.")
	print("[Test] Rules smoke test passed.")
	quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[Test] %s" % message)
	quit(1)
