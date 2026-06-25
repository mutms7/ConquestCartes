extends SceneTree

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"
const EXPECTED_CARD_COUNT := 38
const WORDING_GUIDE_PATH := "res://docs/card_wording_conventions.md"
const INACTIVE_CARD_IDS := [
	"starpath_seeker",
	"river_ward",
	"harvest_feast",
	"astral_spyglass",
	"relic_seeker",
	"timber_camp",
]
const EXPECTED_ART_LINKED_NAMES := {
	"wishing_garden": "Wishing Stone",
	"starpath_seeker": "Starlit Wagon",
	"master_weaver": "Weaver's Loom",
	"roadside_reaver": "Trail Biscuit Cache",
	"royal_clerk": "Royal Charter Decree",
	"root_cellar": "Homestead Cellar",
	"river_ward": "River Courier's Detour",
	"quiet_chapel": "Quiet Archive Purge",
	"council_hearth": "Scholar's Hall",
	"harvest_feast": "Firefly Supper",
	"lantern_festival": "Lantern Parade",
	"dawn_herald": "Dawn Whistle",
	"candlecap_laboratory": "Candlecap",
	"grand_archive": "Quiet Archive",
	"crossroads_market": "Orchard Map",
	"town_militia": "Stone Wall Muster",
	"moonlit_mine": "Moonwell Token",
	"mist_cloak": "Moss Thread",
	"coin_broker": "Acorn Purse",
	"supply_scout": "Trail Biscuit",
	"manor_rebuilder": "Orchard Estate",
	"clockwork_sentry": "Tinker Wren",
	"forge_hall": "Hearthsong",
	"astral_spyglass": "Astral Vault",
	"relic_seeker": "Gilded Reliquary",
	"echoing_hall": "Hearthsong Refrain",
	"banner_vassal": "River Courier",
	"timber_camp": "Moss Thread Camp",
	"guild_workshop": "Loomwright's Workshop",
}

var failure_count := 0


func _initialize() -> void:
	_test_card_catalog()
	_test_wording_conventions()
	_test_full_game_loop()
	_test_draw_across_shuffle_boundary()
	_test_scoring()
	_test_special_effects()
	_test_random_market_setup()

	if failure_count > 0:
		push_error("[Test] Rules smoke test failed with %d issue(s)." % failure_count)
		quit(1)
		return

	print("[Test] Rules smoke test passed.")
	quit(0)


func _test_card_catalog() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return
	_check(
		game_state.card_catalog.size() == EXPECTED_CARD_COUNT,
		"Replacement set should contain %d cards." % EXPECTED_CARD_COUNT
	)
	for card in game_state.card_catalog.values():
		_check(not card.card_name.is_empty(), "Every card should have an original name.")
		_check(not card.art_id.is_empty(), "%s should map to artwork." % card.card_name)
		_check(
			ResourceLoader.exists("res://assets/cards/%s.png" % card.art_id),
			"%s should use an existing card illustration." % card.card_name
		)
	for card_id in EXPECTED_ART_LINKED_NAMES:
		_check(game_state.card_catalog.has(card_id), "Art-linked card %s should exist." % card_id)
		if game_state.card_catalog.has(card_id):
			_check(
				game_state.card_catalog[card_id].card_name
				== EXPECTED_ART_LINKED_NAMES[card_id],
				"%s should retain an art-linked display name." % card_id
			)
	for card_id in INACTIVE_CARD_IDS:
		_check(
			game_state.card_catalog.has(card_id),
			"Inactive card %s should remain in the catalog." % card_id
		)
		if game_state.card_catalog.has(card_id):
			var inactive_card: CardDefinition = game_state.card_catalog[card_id]
			_check(
				not inactive_card.market_enabled,
				"Inactive card %s should be excluded from the market pool." % card_id
			)
			_check(
				not game_state.get_market_candidates().has(inactive_card),
				"Inactive card %s should never be a market candidate." % card_id
			)


func _test_wording_conventions() -> void:
	_check(FileAccess.file_exists(WORDING_GUIDE_PATH), "Card wording guide should exist.")
	var guide_text := FileAccess.get_file_as_string(WORDING_GUIDE_PATH)
	_check(
		guide_text.contains("Card creation checklist"),
		"Card wording guide should include the creation checklist."
	)

	var game_state := _create_game_state()
	if game_state == null:
		return
	var forbidden_openers := [
		"Draws ",
		"Gains ",
		"Grants ",
		"Places ",
		"Produces ",
		"Reveals ",
		"Trashes ",
	]
	for card in game_state.card_catalog.values():
		_check(not card.description.is_empty(), "%s should have rules text." % card.card_name)
		_check(
			card.description.ends_with("."),
			"%s rules text should end with a period." % card.card_name
		)
		for opener in forbidden_openers:
			_check(
				not card.description.begins_with(opener),
				"%s should use direct imperative wording." % card.card_name
			)
		for effect in card.special_effects:
			var label := str(effect.get("label", ""))
			_check(not label.is_empty(), "%s special effects should have labels." % card.card_name)
			_check(
				not label.contains("Topdeck")
				and not label.contains("Inspect")
				and not label.contains("Remodel"),
				"%s labels should use the canonical wording vocabulary." % card.card_name
			)
	_check(
		game_state.card_catalog["council_hearth"].description
		== "Draw 4 cards. Gain 1 buy.",
		"Standard outputs should use canonical sentence order."
	)
	_check(
		game_state.card_catalog["guild_workshop"].description
		== "Gain the strongest card costing up to 4.",
		"Automatic gain wording should identify the solo choice rule."
	)


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

	while not turn_manager.game_over:
		turn_manager.end_turn()

	_check(turn_manager.turn_number == 15, "Game should end on turn 15.")
	_check(
		turn_manager.final_score >= 3 + purchased_card.victory_points,
		"Final score should include all fixed and variable victory values."
	)
	_check(game_state.player.hand.is_empty(), "Final cleanup should empty the hand.")
	_check(game_state.player.play_area.is_empty(), "Final cleanup should empty the play area.")
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


func _test_scoring() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return

	game_state.player.clear_all()
	game_state.player.draw_pile.append(game_state.card_catalog["homestead"])
	game_state.player.hand.append(game_state.card_catalog["briar_gate"])
	game_state.player.play_area.append(game_state.card_catalog["royal_charter"])
	_check(game_state.calculate_score() == 10, "Fixed scoring should include every owned zone.")

	game_state.player.clear_all()
	game_state.player.draw_pile.append(game_state.card_catalog["wishing_garden"])
	for _index in range(9):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.calculate_score() == 1, "Wishing Garden should score per ten owned cards.")


func _test_special_effects() -> void:
	_test_starpath_seeker()
	_test_root_cellar()
	_test_quiet_chapel()
	_test_harvest_feast()
	_test_silver_merchant()
	_test_echoing_hall()
	_test_banner_vassal()


func _test_starpath_seeker() -> void:
	var game_state := _empty_game()
	var seeker: CardDefinition = game_state.card_catalog["starpath_seeker"]
	game_state.player.hand.append(seeker)
	game_state.player.draw_pile.append(game_state.card_catalog["forge_hall"])
	game_state.player.draw_pile.append(game_state.card_catalog["silver_leaf"])
	game_state.player.draw_pile.append(game_state.card_catalog["homestead"])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(seeker), "Inactive Starlit Wagon should remain playable.")
	_check(
		_count_type(game_state.player.hand, "resource") == 2,
		"Starlit Wagon should find two resources."
	)
	_check(game_state.player.discard_pile.size() == 1, "Non-resource reveals should be discarded.")


func _test_root_cellar() -> void:
	var game_state := _empty_game()
	var cellar: CardDefinition = game_state.card_catalog["root_cellar"]
	var homestead: CardDefinition = game_state.card_catalog["homestead"]
	game_state.player.hand.assign([cellar, homestead, game_state.card_catalog["silver_leaf"]])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(cellar), "Root Cellar should play.")
	_check(game_state.player.discard_pile.has(homestead), "Root Cellar should cycle victory cards.")
	_check(game_state.player.hand.size() == 2, "Root Cellar should replace each cycled card.")


func _test_quiet_chapel() -> void:
	var game_state := _empty_game()
	var chapel: CardDefinition = game_state.card_catalog["quiet_chapel"]
	game_state.player.hand.append(chapel)
	for _index in range(4):
		game_state.player.hand.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(chapel), "Quiet Chapel should play.")
	_check(game_state.player.trash_pile.size() == 4, "Quiet Chapel should trash up to four cards.")


func _test_harvest_feast() -> void:
	var game_state := _empty_game()
	var feast: CardDefinition = game_state.card_catalog["harvest_feast"]
	game_state.player.hand.append(feast)
	_check(game_state.play_card(feast), "Inactive Firefly Supper should remain playable.")
	_check(game_state.player.trash_pile.has(feast), "Firefly Supper should trash itself.")
	_check(game_state.player.discard_pile.size() == 1, "Firefly Supper should gain one card.")
	_check(game_state.player.discard_pile[0].cost <= 5, "Firefly Supper gain should respect cost.")


func _test_silver_merchant() -> void:
	var game_state := _empty_game()
	var merchant: CardDefinition = game_state.card_catalog["silver_merchant"]
	var silver: CardDefinition = game_state.card_catalog["silver_leaf"]
	game_state.player.hand.assign([merchant, silver])
	_check(game_state.play_card(merchant), "Silver Merchant should play.")
	_check(game_state.play_card(silver), "Silver Leaf should play after the merchant.")
	_check(game_state.player.coins == 3, "First Silver Leaf should receive the merchant bonus.")


func _test_echoing_hall() -> void:
	var game_state := _empty_game()
	var hall: CardDefinition = game_state.card_catalog["echoing_hall"]
	var forge: CardDefinition = game_state.card_catalog["forge_hall"]
	game_state.player.hand.assign([hall, forge])
	for _index in range(6):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(hall), "Echoing Hall should play.")
	_check(game_state.player.play_area.has(forge), "Echoing Hall should play another action.")
	_check(game_state.player.hand.size() == 6, "The chosen action should resolve twice.")


func _test_banner_vassal() -> void:
	var game_state := _empty_game()
	var vassal: CardDefinition = game_state.card_catalog["banner_vassal"]
	var forge: CardDefinition = game_state.card_catalog["forge_hall"]
	game_state.player.hand.append(vassal)
	for _index in range(3):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	game_state.player.draw_pile.append(forge)
	_check(game_state.play_card(vassal), "Banner Vassal should play.")
	_check(game_state.player.coins == 2, "Banner Vassal should produce two coins.")
	_check(game_state.player.play_area.has(forge), "Banner Vassal should play a revealed action.")
	_check(game_state.player.hand.size() == 3, "The revealed Forge Hall should draw three cards.")


func _test_random_market_setup() -> void:
	seed(11)
	var game_state := _create_game_state()
	if game_state == null:
		return

	var first_market := game_state.get_market_card_ids()
	_check(first_market.size() == GameState.MARKET_SIZE, "Market should use its configured size.")
	_check(
		game_state.get_market_candidates().size()
		== EXPECTED_CARD_COUNT - GameState.STARTING_CARD_COUNTS.size() - INACTIVE_CARD_IDS.size(),
		"Only starter and explicitly inactive cards should be excluded from the market."
	)
	for card_id in INACTIVE_CARD_IDS:
		_check(not first_market.has(card_id), "%s should not appear in the market." % card_id)

	var resource_count := 0
	var action_count := 0
	var victory_count := 0
	for card in game_state.market:
		match card.card_type:
			"resource":
				resource_count += 1
			"action":
				action_count += 1
			"victory":
				victory_count += 1
	_check(resource_count == GameState.MARKET_RESOURCE_COUNT, "Market resource count should match.")
	_check(action_count == GameState.MARKET_ACTION_COUNT, "Market action count should match.")
	_check(victory_count == GameState.MARKET_VICTORY_TOTAL, "Market victory count should match.")

	_check(game_state.setup_starting_game(), "A second game should set up.")
	_check(
		not _same_card_ids(first_market, game_state.get_market_card_ids()),
		"An immediate new game should choose a different action row."
	)


func _empty_game() -> GameState:
	var game_state := _create_game_state()
	game_state.player.clear_all()
	game_state.player.actions = 10
	return game_state


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


func _count_type(cards: Array[CardDefinition], card_type: String) -> int:
	var count := 0
	for card in cards:
		if card.card_type == card_type:
			count += 1
	return count


func _same_card_ids(first: Array[String], second: Array[String]) -> bool:
	if first.size() != second.size():
		return false
	for card_id in first:
		if not second.has(card_id):
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error("[Test] %s" % message)
