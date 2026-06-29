extends SceneTree

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"
const EXPECTED_CARD_COUNT := 63
const WORDING_GUIDE_PATH := "res://docs/card_wording_conventions.md"
const INACTIVE_CARD_IDS := [
	"starpath_seeker",
	"river_ward",
	"harvest_feast",
	"astral_spyglass",
	"relic_seeker",
	"briar_hex",
]
const EXPECTED_ART_LINKED_NAMES := {
	"wishing_garden": "Wishing Stone",
	"starpath_seeker": "Starlit Wagon",
	"master_weaver": "Weaver's Loom",
	"roadside_reaver": "Trail Cache",
	"royal_clerk": "Royal Decree",
	"root_cellar": "Root Cellar",
	"river_ward": "River Detour",
	"quiet_chapel": "Archive Purge",
	"council_hearth": "Scholar's Hall",
	"harvest_feast": "Firefly Supper",
	"lantern_festival": "Lantern Parade",
	"dawn_herald": "Dawn Whistle",
	"candlecap_laboratory": "Candlecap",
	"grand_archive": "Quiet Archive",
	"crossroads_market": "Orchard Map",
	"moonlit_mine": "Moonwell Token",
	"coin_broker": "Acorn Purse",
	"supply_scout": "Trail Biscuit",
	"manor_rebuilder": "Orchard Estate",
	"clockwork_sentry": "Tinker Wren",
	"forge_hall": "Hearthsong",
	"astral_spyglass": "Astral Vault",
	"relic_seeker": "Reliquary",
	"echoing_hall": "Hearth Refrain",
	"banner_vassal": "River Courier",
	"guild_workshop": "Loom Workshop",
}
const HINTERLAND_CARD_IDS := [
	"briar_passage",
	"orchard_acre",
	"firefly_gold",
	"silverleaf_broker",
	"river_magistrate",
	"bellfoundry_village",
	"orchard_surveyor",
	"wishing_crossroads",
	"tinkers_development",
	"lantern_bargainer",
	"starlit_causeway",
	"hearthside_lodge",
	"village_handyman",
	"moonwell_rest",
	"quiet_stratagem",
	"acorn_spicebroker",
	"mosswood_stable",
	"candlecap_kettle",
	"briar_hound",
	"river_trail",
	"moss_weaver",
	"stonewall_raider",
	"briar_hut",
	"starlit_caravan",
	"lantern_bazaar",
	"tinker_wheelwright",
]

var failure_count := 0


func _initialize() -> void:
	_test_card_catalog()
	_test_wording_conventions()
	_test_full_game_loop()
	_test_draw_across_shuffle_boundary()
	_test_scoring()
	_test_supply_piles()
	_test_turn_cooldown()
	_test_multiplayer_lobby_attacks()
	_test_multiplayer_game_end()
	_test_special_effects()
	_test_hinterland_expansion()
	_test_every_playable_card_resolves()
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
		_check(
			card.card_name.length() <= 15,
			"%s should have a compact display name." % card.id
		)
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
	for card_id in HINTERLAND_CARD_IDS:
		_check(game_state.card_catalog.has(card_id), "Hinterland card %s should exist." % card_id)
		if game_state.card_catalog.has(card_id):
			_check(
				game_state.card_catalog[card_id].card_group == GameState.HINTERLANDS_GROUP,
				"%s should belong to the named Hinterlands card group." % card_id
			)
	for card_id in GameState.REQUIRED_CARD_IDS:
		_check(game_state.card_catalog.has(card_id), "Required card %s should exist." % card_id)
		if game_state.card_catalog.has(card_id):
			_check(
				game_state.get_card_kingdom(game_state.card_catalog[card_id])
				== GameState.BASE_KINGDOM,
				"%s should belong to the required base kingdom." % card_id
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
		== "Gain a card costing up to 4.",
		"Gain wording should describe the player's supply choice."
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

	for index in range(3):
		game_state.set_supply_count(game_state.market[index].id, 0)
	_finish_turn(turn_manager)

	_check(turn_manager.game_over, "Game should end when three supply piles are empty.")
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

	game_state.player.discard_pile.append(game_state.card_catalog["briar_hex"])
	_check(game_state.calculate_score() == 9, "Curse scoring should subtract VP.")

	game_state.player.clear_all()
	game_state.player.draw_pile.append(game_state.card_catalog["wishing_garden"])
	for _index in range(9):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.calculate_score() == 1, "Wishing Garden should score per ten owned cards.")


func _test_supply_piles() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return
	var card: CardDefinition = game_state.market[0]
	var starting_count := game_state.get_supply_count(card.id)
	game_state.player.coins = card.cost
	_check(game_state.buy_card(card), "A non-empty supply pile should be purchasable.")
	_check(
		game_state.get_supply_count(card.id) == starting_count - 1,
		"Buying should remove one card from its supply pile."
	)
	game_state.set_supply_count(card.id, 0)
	game_state.player.buys = 1
	game_state.player.coins = 99
	_check(not game_state.buy_card(card), "An empty supply pile should not be purchasable.")
	_check(game_state.get_empty_supply_pile_count() == 1, "Empty supply piles should be counted.")


func _test_turn_cooldown() -> void:
	# Singleplayer has no end-turn timeout: ending a turn draws the next hand
	# immediately and never blocks the End Turn button.
	var solo_state := _create_game_state()
	if solo_state == null:
		return
	var solo_manager := TurnManager.new()
	solo_manager.configure(solo_state)
	solo_manager.start_first_turn()
	solo_manager.end_turn()
	_check(
		is_equal_approx(solo_state.get_end_turn_cooldown_seconds(), 0.0),
		"Singleplayer end-turn cooldown should be zero."
	)
	_check(not solo_manager.is_cooling_down(), "Singleplayer end turn should not start a cooldown.")
	_check(
		solo_state.player.hand.size() == 5,
		"Singleplayer end turn should immediately draw the next hand."
	)

	# Multiplayer keeps the parallel end-turn cooldown so online turns stay paced.
	var game_state := _create_game_state()
	if game_state == null:
		return
	game_state.multiplayer_enabled = true
	var turn_manager := TurnManager.new()
	turn_manager.configure(game_state)
	turn_manager.start_first_turn()
	turn_manager.end_turn()
	_check(turn_manager.is_cooling_down(), "Multiplayer end turn should start a cooldown.")
	_check(not turn_manager.ending_turn, "End turn cleanup should finish before button cooldown expires.")
	_check(game_state.player.hand.size() == 5, "End turn should immediately draw the next hand.")
	var cooldown_before_second_end := turn_manager.cooldown_remaining
	turn_manager.end_turn()
	_check(
		is_equal_approx(turn_manager.cooldown_remaining, cooldown_before_second_end),
		"End Turn should be the only action blocked during cooldown."
	)
	var playable_resource: CardDefinition = null
	for card in game_state.player.hand:
		if card.card_type == "resource":
			playable_resource = card
			break
	_check(playable_resource != null, "Cooldown test should have a resource to play.")
	if playable_resource != null:
		_check(
			game_state.play_card(playable_resource),
			"Cards should remain playable while end-turn cooldown is running."
		)
	var buy_target := game_state.market[0]
	game_state.player.coins = 99
	game_state.player.buys = 1
	_check(
		game_state.buy_card(buy_target),
		"Buying should remain available while end-turn cooldown is running."
	)
	turn_manager.tick(GameState.DEFAULT_END_TURN_COOLDOWN_SECONDS)
	_check(not turn_manager.is_cooling_down(), "Cooldown expiry should re-enable End Turn.")

	game_state = _empty_game()
	game_state.multiplayer_enabled = true
	turn_manager = TurnManager.new()
	turn_manager.configure(game_state)
	var bell: CardDefinition = game_state.card_catalog["sunspire_bell"]
	game_state.player.hand.append(bell)
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(bell), "Sunspire Bell should play.")
	_check(
		is_equal_approx(game_state.get_end_turn_cooldown_seconds(), 4.5),
		"Sunspire Bell should reduce the multiplayer end-turn cooldown by 0.5 seconds."
	)

	game_state = _empty_game()
	game_state.multiplayer_enabled = true
	turn_manager = TurnManager.new()
	turn_manager.configure(game_state)
	bell = game_state.card_catalog["sunspire_bell"]
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	game_state.player.draw_pile.append(bell)
	turn_manager.end_turn()
	var cooldown_before := turn_manager.cooldown_remaining
	_check(game_state.play_card(bell), "Sunspire Bell should play during cooldown.")
	_check(
		is_equal_approx(turn_manager.cooldown_remaining, cooldown_before - 0.5),
		"Sunspire Bell should shorten an active cooldown by 0.5 seconds."
	)


func _test_multiplayer_lobby_attacks() -> void:
	var game_state := GameState.new()
	_check(game_state.load_cards(CARD_DATA_PATH), "Card data should load for multiplayer.")
	_check(game_state.setup_starting_game(2), "A two-player lobby should set up.")
	_check(game_state.get_player_count() == 2, "The lobby should contain two players.")
	game_state.start_all_players()
	var attacker := game_state.players[0]
	var defender := game_state.players[1]
	game_state.set_active_player_index(0)
	attacker.hand.clear()
	attacker.hand.append(game_state.card_catalog["briar_witch"])
	defender.discard_pile.clear()
	_check(game_state.play_card(game_state.card_catalog["briar_witch"]), "Attack card should play.")
	_check(
		defender.discard_pile.has(game_state.card_catalog["briar_hex"]),
		"Multiplayer attacks should gain curses for rival players."
	)
	_check(
		not attacker.discard_pile.has(game_state.card_catalog["briar_hex"]),
		"Multiplayer attacks should not hit the attacker."
	)

	var turn_manager := TurnManager.new()
	turn_manager.configure(game_state)
	turn_manager.start_first_turn()
	var first_player_name := game_state.get_active_player_name()
	_finish_turn(turn_manager)
	_check(
		game_state.get_active_player_name() == first_player_name,
		"End Turn should keep the local player view active for parallel play."
	)


func _test_multiplayer_game_end() -> void:
	var game_state := GameState.new()
	_check(game_state.load_cards(CARD_DATA_PATH), "Card data should load for multiplayer game end.")
	_check(game_state.setup_starting_game(2), "A two-player lobby should set up for game end.")
	game_state.start_all_players()
	_check(
		not game_state.is_game_end_condition_met(),
		"A fresh multiplayer lobby should not already be over."
	)

	# Give the two players different victory holdings so their scores differ.
	var homestead: CardDefinition = game_state.card_catalog["homestead"]
	game_state.players[0].discard_pile.append(homestead)
	game_state.players[0].discard_pile.append(homestead)
	game_state.players[1].discard_pile.append(homestead)

	# Emptying three supply piles ends the shared game.
	var emptied := 0
	for card_id in game_state.supply_piles.keys():
		if emptied >= GameState.SUPPLY_EMPTY_END_COUNT:
			break
		game_state.set_supply_count(card_id, 0)
		emptied += 1
	_check(
		game_state.is_game_end_condition_met(),
		"Three empty supply piles should end a multiplayer game."
	)
	var scores := game_state.calculate_all_scores()
	_check(scores.size() == 2, "Game end should score every lobby player.")
	_check(
		scores[0] > scores[1],
		"Per-player scoring should reflect each player's own victory cards."
	)

	# Emptying the top victory pile is the other end condition.
	var fresh := GameState.new()
	_check(fresh.load_cards(CARD_DATA_PATH), "Card data should reload for the VP end check.")
	_check(fresh.setup_starting_game(2), "A second two-player lobby should set up.")
	fresh.start_all_players()
	_check(
		not fresh.is_game_end_condition_met(),
		"A second fresh lobby should not already be over."
	)
	fresh.set_supply_count(GameState.SIX_VP_CARD_ID, 0)
	_check(
		fresh.is_game_end_condition_met(),
		"Emptying the top victory pile should end a multiplayer game."
	)


func _test_special_effects() -> void:
	_test_starpath_seeker()
	_test_master_weaver()
	_test_root_cellar()
	_test_quiet_chapel()
	_test_harvest_feast()
	_test_harbinger_and_library()
	_test_mine_remodel_and_sentry()
	_test_poacher_and_spy()
	_test_silver_merchant()
	_test_echoing_hall()
	_test_banner_vassal()
	_test_attack_effects()


func _test_master_weaver() -> void:
	var game_state := _empty_game()
	var loom: CardDefinition = game_state.card_catalog["master_weaver"]
	var pebble: CardDefinition = game_state.card_catalog["pebble_coin"]
	game_state.player.hand.assign([loom, pebble])
	_check(game_state.play_card(loom), "Weaver's Loom should play.")
	_check(game_state.has_pending_choice(), "Weaver's Loom should request a gain choice.")
	var gained_id := _first_choice_card_id(game_state)
	var supply_before := game_state.get_supply_count(gained_id)
	_resolve_first_choice(game_state)
	_check(game_state.has_pending_choice(), "Weaver's Loom should request a top-deck choice.")
	_resolve_choice_by_ids(game_state, ["pebble_coin"])
	_check(game_state.player.draw_pile.back() == pebble, "Selected hand card should go on deck.")
	_check(
		game_state.get_supply_count(gained_id) == supply_before - 1,
		"Gaining should remove a card from its supply pile."
	)


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
	_check(game_state.has_pending_choice(), "Root Cellar should request discard choices.")
	_resolve_choice_by_ids(game_state, ["homestead"])
	_check(game_state.player.discard_pile.has(homestead), "Root Cellar should discard selected cards.")
	_check(game_state.player.hand.size() == 2, "Root Cellar should replace each cycled card.")


func _test_quiet_chapel() -> void:
	var game_state := _empty_game()
	var chapel: CardDefinition = game_state.card_catalog["quiet_chapel"]
	game_state.player.hand.append(chapel)
	for _index in range(4):
		game_state.player.hand.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(chapel), "Quiet Chapel should play.")
	_resolve_choice_by_ids(game_state, [
		"pebble_coin",
		"pebble_coin",
		"pebble_coin",
		"pebble_coin",
	])
	_check(game_state.player.trash_pile.size() == 4, "Quiet Chapel should trash up to four cards.")


func _test_harvest_feast() -> void:
	var game_state := _empty_game()
	var feast: CardDefinition = game_state.card_catalog["harvest_feast"]
	game_state.player.hand.append(feast)
	_check(game_state.play_card(feast), "Inactive Firefly Supper should remain playable.")
	_check(game_state.player.trash_pile.has(feast), "Firefly Supper should trash itself.")
	_resolve_first_choice(game_state)
	_check(game_state.player.discard_pile.size() == 1, "Firefly Supper should gain one card.")
	if not game_state.player.discard_pile.is_empty():
		_check(game_state.player.discard_pile[0].cost <= 5, "Firefly Supper gain should respect cost.")


func _test_harbinger_and_library() -> void:
	var game_state := _empty_game()
	var herald: CardDefinition = game_state.card_catalog["dawn_herald"]
	var recovered: CardDefinition = game_state.card_catalog["homestead"]
	game_state.player.hand.append(herald)
	game_state.player.discard_pile.append(recovered)
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(herald), "Dawn Whistle should play.")
	_resolve_choice_by_ids(game_state, ["homestead"])
	_check(game_state.player.draw_pile.back() == recovered, "Chosen discard card should go on deck.")

	game_state = _empty_game()
	var archive: CardDefinition = game_state.card_catalog["grand_archive"]
	var action: CardDefinition = game_state.card_catalog["forge_hall"]
	game_state.player.hand.append(archive)
	for _index in range(7):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	game_state.player.draw_pile.append(action)
	_check(game_state.play_card(archive), "Quiet Archive should play.")
	_check(game_state.has_pending_choice(), "Quiet Archive should pause on a revealed action.")
	_resolve_choice_by_ids(game_state, ["forge_hall"])
	_check(game_state.player.hand.size() == 7, "Quiet Archive should draw to seven cards.")
	_check(game_state.player.discard_pile.has(action), "Set-aside actions should be discarded.")


func _test_mine_remodel_and_sentry() -> void:
	var game_state := _empty_game()
	var mine: CardDefinition = game_state.card_catalog["moonlit_mine"]
	var pebble: CardDefinition = game_state.card_catalog["pebble_coin"]
	game_state.player.hand.assign([mine, pebble])
	_check(game_state.play_card(mine), "Moonwell Token should play.")
	_resolve_choice_by_ids(game_state, ["pebble_coin"])
	_resolve_choice_by_ids(game_state, ["silver_leaf"])
	_check(game_state.player.trash_pile.has(pebble), "Mine should trash the selected resource.")
	_check(
		game_state.player.hand.has(game_state.card_catalog["silver_leaf"]),
		"Mine should gain the selected upgraded resource to hand."
	)

	game_state = _empty_game()
	var rebuilder: CardDefinition = game_state.card_catalog["manor_rebuilder"]
	var homestead: CardDefinition = game_state.card_catalog["homestead"]
	game_state.player.hand.assign([rebuilder, homestead])
	_check(game_state.play_card(rebuilder), "Orchard Estate should play.")
	_resolve_choice_by_ids(game_state, ["homestead"])
	_resolve_first_choice(game_state)
	_check(game_state.player.trash_pile.has(homestead), "Remodel should trash the selected card.")
	_check(game_state.player.discard_pile.size() == 1, "Remodel should gain one card.")

	game_state = _empty_game()
	var sentry: CardDefinition = game_state.card_catalog["clockwork_sentry"]
	game_state.player.hand.append(sentry)
	game_state.player.draw_pile.append(game_state.card_catalog["homestead"])
	game_state.player.draw_pile.append(game_state.card_catalog["silver_leaf"])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(sentry), "Tinker Wren should play.")
	_resolve_choice_by_ids(game_state, ["homestead"])
	_resolve_choice_by_ids(game_state, [])
	_check(
		game_state.player.trash_pile.has(game_state.card_catalog["homestead"]),
		"Sentry should trash selected revealed cards."
	)
	_check(
		game_state.player.draw_pile.back() == game_state.card_catalog["silver_leaf"],
		"Unselected revealed cards should return to the deck."
	)


func _test_poacher_and_spy() -> void:
	var game_state := _empty_game()
	var poacher: CardDefinition = game_state.card_catalog["supply_scout"]
	var homestead: CardDefinition = game_state.card_catalog["homestead"]
	game_state.set_supply_count(game_state.market[0].id, 0)
	game_state.player.hand.assign([poacher, homestead])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(poacher), "Trail Biscuit should play.")
	_resolve_choice_by_ids(game_state, ["homestead"])
	_check(game_state.player.discard_pile.has(homestead), "Poacher should discard per empty pile.")

	game_state = _empty_game()
	var spy: CardDefinition = game_state.card_catalog["astral_spyglass"]
	game_state.player.hand.append(spy)
	game_state.player.draw_pile.append(game_state.card_catalog["homestead"])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(spy), "Astral Vault should play.")
	_resolve_choice_by_ids(game_state, ["homestead"])
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["homestead"]),
		"Spy should discard the selected revealed card."
	)


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
	_resolve_choice_by_ids(game_state, ["forge_hall"])
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
	_resolve_choice_by_ids(game_state, ["forge_hall"])
	_check(game_state.player.play_area.has(forge), "Banner Vassal should play a revealed action.")
	_check(game_state.player.hand.size() == 3, "The revealed Forge Hall should draw three cards.")


func _test_attack_effects() -> void:
	var game_state := _empty_game()
	var witch: CardDefinition = game_state.card_catalog["briar_witch"]
	game_state.player.hand.append(witch)
	_check(game_state.play_card(witch), "Briar Witch should play.")
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["briar_hex"]),
		"Briar Witch should gain a Briar Hex through its attack."
	)
	_check(
		game_state.get_supply_count("briar_hex") == GameState.CURSE_SUPPLY_COUNT - 1,
		"Briar Hex attacks should use a finite curse pile."
	)

	game_state = _empty_game()
	var clerk: CardDefinition = game_state.card_catalog["royal_clerk"]
	var homestead: CardDefinition = game_state.card_catalog["homestead"]
	game_state.player.hand.assign([clerk, homestead])
	_check(game_state.play_card(clerk), "Royal Decree should play.")
	_check(game_state.has_pending_choice(), "Royal Decree should request a victory topdeck.")
	_resolve_choice_by_ids(game_state, ["homestead"])
	_check(
		game_state.player.draw_pile.back() == homestead,
		"Royal Decree should put the chosen victory card on top of the deck."
	)

	game_state = _empty_game()
	var reaver: CardDefinition = game_state.card_catalog["roadside_reaver"]
	var silver: CardDefinition = game_state.card_catalog["silver_leaf"]
	game_state.player.hand.append(reaver)
	game_state.player.draw_pile.append(game_state.card_catalog["homestead"])
	game_state.player.draw_pile.append(silver)
	_check(game_state.play_card(reaver), "Trail Cache should play.")
	_check(game_state.has_pending_choice(), "Trail Cache should request a resource to trash.")
	_resolve_choice_by_ids(game_state, ["silver_leaf"])
	_check(
		game_state.player.trash_pile.has(silver),
		"Trail Cache should trash the selected revealed resource."
	)

	game_state = _empty_game()
	var magistrate: CardDefinition = game_state.card_catalog["river_magistrate"]
	game_state.player.hand.assign([
		magistrate,
		game_state.card_catalog["homestead"],
		game_state.card_catalog["silver_leaf"],
	])
	for _index in range(3):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(magistrate), "Magistrate should play.")
	_check(game_state.has_pending_choice(), "Magistrate should request attack discards.")
	_resolve_choice_by_ids(game_state, ["homestead", "silver_leaf"])
	_check(game_state.player.hand.size() == 3, "Magistrate should discard down to 3 cards.")

	game_state = _empty_game()
	var hut: CardDefinition = game_state.card_catalog["briar_hut"]
	game_state.player.hand.append(hut)
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	game_state.player.draw_pile.append(game_state.card_catalog["homestead"])
	game_state.player.draw_pile.append(game_state.card_catalog["forge_hall"])
	_check(game_state.play_card(hut), "Briar Hut should play.")
	_resolve_choice_by_ids(game_state, ["forge_hall", "pebble_coin"])
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["briar_hex"]),
		"Briar Hut should attack when it discarded an action."
	)

	game_state = _empty_game()
	_set_test_market(game_state, ["guild_workshop"])
	var kettle: CardDefinition = game_state.card_catalog["candlecap_kettle"]
	game_state.player.hand.append(kettle)
	_check(game_state.play_card(kettle), "Cap Kettle should play.")
	game_state.player.coins = 99
	_check(
		game_state.buy_card(game_state.card_catalog["guild_workshop"]),
		"Cap Kettle should allow buying a test action."
	)
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["briar_hex"]),
		"Cap Kettle should attack after an action card is gained."
	)


func _test_hinterland_expansion() -> void:
	_test_progressive_cards_and_costs()
	_test_gain_and_discard_triggers()
	_test_develop_modes_and_filtered_gains()
	_test_cleanup_and_buy_watchers()


func _test_progressive_cards_and_costs() -> void:
	var game_state := _empty_game()
	var firefly: CardDefinition = game_state.card_catalog["firefly_gold"]
	game_state.player.hand.assign([firefly, firefly])
	_check(game_state.play_card(firefly), "Firefly Gold should play the first time.")
	_check(game_state.play_card(firefly), "Firefly Gold should play a later time.")
	_check(game_state.player.coins == 5, "Firefly Gold should produce 1 coin, then 4 coins.")

	game_state = _empty_game()
	var crossroads: CardDefinition = game_state.card_catalog["wishing_crossroads"]
	game_state.player.hand.assign([
		crossroads,
		game_state.card_catalog["homestead"],
		game_state.card_catalog["briar_passage"],
	])
	game_state.player.draw_pile.assign([
		game_state.card_catalog["pebble_coin"],
		game_state.card_catalog["pebble_coin"],
	])
	var actions_before := game_state.player.actions
	_check(game_state.play_card(crossroads), "Wish Crossroads should play.")
	_check(game_state.player.hand.size() == 4, "Crossroads should draw per victory card.")
	_check(
		game_state.player.actions == actions_before - 1 + 3,
		"The first Crossroads play should grant three actions."
	)

	game_state = _empty_game()
	var causeway: CardDefinition = game_state.card_catalog["starlit_causeway"]
	game_state.player.hand.append(causeway)
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(causeway), "Star Causeway should play.")
	_check(
		game_state.get_effective_cost(game_state.card_catalog["amber_circlet"]) == 5,
		"Star Causeway should reduce card costs for the turn."
	)


func _test_gain_and_discard_triggers() -> void:
	var game_state := _empty_game()
	_set_test_market(game_state, [
		"silver_leaf",
		"forge_hall",
		"orchard_acre",
		"firefly_gold",
	])
	var broker: CardDefinition = game_state.card_catalog["silverleaf_broker"]
	var forge: CardDefinition = game_state.card_catalog["forge_hall"]
	game_state.player.hand.append(broker)
	_check(game_state._gain_from_supply(forge, "discard"), "A test card should be gained.")
	game_state._process_resolution_queue()
	_check(game_state.has_pending_choice(), "Leaf Broker should react to a gain.")
	_resolve_choice_by_ids(game_state, ["silverleaf_broker"])
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["silver_leaf"])
		and not game_state.player.discard_pile.has(forge),
		"Leaf Broker should exchange the gained card for a Silver Leaf."
	)

	game_state = _empty_game()
	_set_test_market(game_state, ["orchard_acre", "firefly_gold"])
	var pebble: CardDefinition = game_state.card_catalog["pebble_coin"]
	game_state.player.hand.append(pebble)
	_check(
		game_state._gain_from_supply(game_state.card_catalog["orchard_acre"], "discard"),
		"Orchard Acre should be gainable."
	)
	game_state._process_resolution_queue()
	_resolve_choice_by_ids(game_state, ["pebble_coin"])
	_resolve_choice_by_ids(game_state, ["firefly_gold"])
	_check(game_state.player.trash_pile.has(pebble), "Orchard Acre should trash a hand card.")

	game_state = _empty_game()
	var passage: CardDefinition = game_state.card_catalog["briar_passage"]
	game_state.player.hand.append(passage)
	game_state._move_cards(
		game_state.player.hand,
		game_state.player.discard_pile,
		[passage],
		"discard"
	)
	game_state._process_resolution_queue()
	_resolve_choice_by_ids(game_state, ["briar_passage"])
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["amber_circlet"]),
		"Briar Passage should optionally gain an Amber Circlet when discarded."
	)

	game_state = _empty_game()
	var trail: CardDefinition = game_state.card_catalog["river_trail"]
	game_state.player.hand.append(trail)
	game_state._move_cards(
		game_state.player.hand,
		game_state.player.discard_pile,
		[trail],
		"discard"
	)
	game_state._process_resolution_queue()
	_resolve_choice_by_ids(game_state, ["river_trail"])
	_check(game_state.player.play_area.has(trail), "River Trail should play from a discard trigger.")

	game_state = _empty_game()
	_set_test_market(game_state, ["bellfoundry_village", "guild_workshop"])
	_check(
		game_state._gain_from_supply(
			game_state.card_catalog["bellfoundry_village"],
			"discard"
		),
		"Bellfoundry should be gainable."
	)
	game_state._process_resolution_queue()
	_resolve_choice_by_ids(game_state, ["guild_workshop"])
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["guild_workshop"]),
		"Bellfoundry should gain a cheaper card."
	)

	game_state = _empty_game()
	_set_test_market(game_state, ["hearthside_lodge"])
	var recovered_action: CardDefinition = game_state.card_catalog["forge_hall"]
	game_state.player.discard_pile.append(recovered_action)
	_check(
		game_state._gain_from_supply(game_state.card_catalog["hearthside_lodge"], "discard"),
		"Hearth Lodge should be gainable."
	)
	game_state._process_resolution_queue()
	_resolve_choice_by_ids(game_state, ["forge_hall"])
	_check(
		game_state.player.draw_pile.has(recovered_action),
		"Hearth Lodge should shuffle selected actions into the deck."
	)

	game_state = _empty_game()
	_set_test_market(game_state, ["starlit_caravan"])
	_check(
		game_state._gain_from_supply(game_state.card_catalog["starlit_caravan"], "discard"),
		"Star Caravan should be gainable."
	)
	game_state._process_resolution_queue()
	_check(game_state.player.coins == 2, "Star Caravan should grant coins when gained.")
	var caravan: CardDefinition = game_state.card_catalog["starlit_caravan"]
	game_state._move_cards(
		game_state.player.discard_pile,
		game_state.player.trash_pile,
		[caravan],
		"trash"
	)
	game_state._process_resolution_queue()
	_check(game_state.player.coins == 4, "Star Caravan should grant coins when trashed.")

	game_state = _empty_game()
	_set_test_market(game_state, ["lantern_bazaar"])
	game_state.player.hand.assign([
		game_state.card_catalog["pebble_coin"],
		game_state.card_catalog["homestead"],
	])
	_check(
		game_state._gain_from_supply(game_state.card_catalog["lantern_bazaar"], "discard"),
		"Lantern Bazaar should be gainable."
	)
	game_state._process_resolution_queue()
	_resolve_choice_by_ids(game_state, ["pebble_coin", "homestead"])
	_check(
		game_state.player.trash_pile.size() == 2,
		"Lantern Bazaar should trash up to two cards when gained."
	)


func _test_develop_modes_and_filtered_gains() -> void:
	var game_state := _empty_game()
	_set_test_market(game_state, ["firefly_gold", "silver_leaf", "forge_hall"])
	var development: CardDefinition = game_state.card_catalog["tinkers_development"]
	var silver: CardDefinition = game_state.card_catalog["silver_leaf"]
	game_state.player.hand.assign([development, silver])
	_check(game_state.play_card(development), "Tinker Dev should play.")
	_resolve_choice_by_ids(game_state, ["silver_leaf"])
	_resolve_mode(game_state, "higher_first")
	_resolve_choice_by_ids(game_state, ["forge_hall"])
	_resolve_choice_by_ids(game_state, ["firefly_gold"])
	_check(
		game_state.player.draw_pile.size() == 2,
		"Development should gain both exact-cost cards onto the deck."
	)

	game_state = _empty_game()
	var spicebroker: CardDefinition = game_state.card_catalog["acorn_spicebroker"]
	game_state.player.hand.assign([spicebroker, game_state.card_catalog["pebble_coin"]])
	game_state.player.draw_pile.assign([
		game_state.card_catalog["homestead"],
		game_state.card_catalog["homestead"],
	])
	_check(game_state.play_card(spicebroker), "Spicebroker should play.")
	_resolve_choice_by_ids(game_state, ["pebble_coin"])
	_resolve_mode(game_state, "cards")
	_check(game_state.player.hand.size() == 2, "The card mode should draw two cards.")

	game_state = _empty_game()
	var weaver: CardDefinition = game_state.card_catalog["moss_weaver"]
	game_state.player.hand.append(weaver)
	_check(game_state.play_card(weaver), "Moss Weaver should play.")
	_resolve_mode(game_state, "silvers")
	_check(
		_count_card_id(game_state.player.discard_pile, "silver_leaf") == 2,
		"Moss Weaver should be able to gain two Silver Leaves."
	)

	game_state = _empty_game()
	_set_test_market(game_state, ["guild_workshop", "forge_hall"])
	var wheelwright: CardDefinition = game_state.card_catalog["tinker_wheelwright"]
	var forge: CardDefinition = game_state.card_catalog["forge_hall"]
	game_state.player.hand.assign([wheelwright, forge])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(wheelwright), "Cartwright should play.")
	_resolve_choice_by_ids(game_state, ["forge_hall"])
	_resolve_choice_by_ids(game_state, ["guild_workshop"])
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["guild_workshop"]),
		"Wheelwright should gain an affordable action card."
	)


func _test_cleanup_and_buy_watchers() -> void:
	var game_state := _empty_game()
	var scheme: CardDefinition = game_state.card_catalog["quiet_stratagem"]
	var forge: CardDefinition = game_state.card_catalog["forge_hall"]
	game_state.player.hand.assign([scheme, forge])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(scheme), "Quiet Stratagem should play.")
	_check(game_state.play_card(forge), "A second action should play for cleanup.")
	game_state.begin_cleanup()
	_check(game_state.has_pending_choice(), "Cleanup should pause for Quiet Stratagem.")
	_resolve_choice_by_ids(game_state, ["forge_hall"])
	_check(game_state.player.draw_pile.back() == forge, "Chosen cleanup action should go on deck.")

	game_state = _empty_game()
	_set_test_market(game_state, ["river_magistrate", "guild_workshop"])
	var bargainer: CardDefinition = game_state.card_catalog["lantern_bargainer"]
	game_state.player.hand.append(bargainer)
	_check(game_state.play_card(bargainer), "Lantern Trade should play.")
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(
		game_state.buy_card(game_state.card_catalog["river_magistrate"]),
		"A card should be bought while Lantern Trade is active."
	)
	_resolve_choice_by_ids(game_state, ["guild_workshop"])
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["guild_workshop"]),
		"Lantern Trade should gain a cheaper non-victory card after a buy."
	)

	game_state = _empty_game()
	_set_test_market(game_state, ["stonewall_raider", "guild_workshop"])
	game_state.player.play_area.append(game_state.card_catalog["village_bell"])
	_check(
		game_state._gain_from_supply(game_state.card_catalog["stonewall_raider"], "discard"),
		"Stone Raider should be gainable."
	)
	game_state._process_resolution_queue()
	_check(
		game_state.player.play_area.has(game_state.card_catalog["stonewall_raider"]),
		"Stone Raider should play itself when an action is already in play."
	)


func _test_every_playable_card_resolves() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return
	for card in game_state.card_catalog.values():
		if not card.is_playable():
			continue
		game_state.player.clear_all()
		game_state.resolution_queue.clear()
		game_state.pending_choice = null
		game_state.player.actions = 10
		game_state.player.hand.append(card)
		for _index in range(12):
			game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
		_check(game_state.play_card(card), "%s should begin resolving." % card.card_name)
		var guard := 0
		while game_state.has_pending_choice() and guard < 12:
			var choice := game_state.pending_choice
			var tokens: Array[String] = []
			for index in range(choice.minimum):
				tokens.append(str(choice.candidates[index]["token"]))
			_check(
				game_state.resolve_choice(tokens),
				"%s pending choice should resolve." % card.card_name
			)
			guard += 1
		_check(guard < 12, "%s should not create an endless choice loop." % card.card_name)


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
		if GameState.MARKET_FIXED_RESOURCE_IDS.has(card.id):
			resource_count += 1
		elif GameState.MARKET_FIXED_VICTORY_IDS.has(card.id):
			victory_count += 1
		else:
			action_count += 1
	_check(resource_count == GameState.MARKET_RESOURCE_COUNT, "Market resource count should match.")
	_check(action_count == GameState.MARKET_ACTION_COUNT, "Market action count should match.")
	_check(victory_count == GameState.MARKET_VICTORY_TOTAL, "Market victory count should match.")
	for fixed_id in GameState.MARKET_FIXED_RESOURCE_IDS + GameState.MARKET_FIXED_VICTORY_IDS:
		_check(first_market.has(fixed_id), "%s should always anchor the market." % fixed_id)

	game_state.set_kingdom_enabled(GameState.HINTERLANDS_GROUP, false)
	_check(
		not _market_candidates_include_kingdom(game_state, GameState.HINTERLANDS_GROUP),
		"Disabled kingdoms should leave the random market pool."
	)
	game_state.set_kingdom_enabled(GameState.HINTERLANDS_GROUP, true)
	game_state.set_card_enabled_for_market("river_magistrate", false)
	_check(
		not _market_candidates_include_card(game_state, "river_magistrate"),
		"Disabled individual cards should leave the random market pool."
	)
	game_state.set_card_enabled_for_market("river_magistrate", true)
	game_state.set_kingdom_enabled(GameState.BEGINNER_KINGDOM, false)
	game_state.set_kingdom_enabled(GameState.HINTERLANDS_GROUP, false)
	_check(
		not game_state.has_enough_market_candidates(),
		"Market setup should know when kingdom filters cannot fill the action row."
	)
	game_state.set_kingdom_enabled(GameState.BEGINNER_KINGDOM, true)
	game_state.set_kingdom_enabled(GameState.HINTERLANDS_GROUP, true)

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


func _count_card_id(cards: Array[CardDefinition], card_id: String) -> int:
	var count := 0
	for card in cards:
		if card.id == card_id:
			count += 1
	return count


func _market_candidates_include_kingdom(game_state: GameState, kingdom: String) -> bool:
	for card in game_state.get_market_candidates():
		if game_state.get_card_kingdom(card) == kingdom:
			return true
	return false


func _market_candidates_include_card(game_state: GameState, card_id: String) -> bool:
	for card in game_state.get_market_candidates():
		if card.id == card_id:
			return true
	return false


func _set_test_market(game_state: GameState, card_ids: Array[String]) -> void:
	game_state.market.clear()
	game_state.supply_piles.clear()
	for card_id in card_ids:
		var card: CardDefinition = game_state.card_catalog[card_id]
		game_state.market.append(card)
		game_state.supply_piles[card_id] = game_state._default_supply_count(card)


func _resolve_mode(game_state: GameState, mode_id: String) -> void:
	_check(game_state.pending_choice != null, "A mode choice should exist.")
	if game_state.pending_choice == null:
		return
	for candidate in game_state.pending_choice.candidates:
		var token := str(candidate.get("token", ""))
		if token.ends_with(":%s" % mode_id):
			_check(game_state.resolve_choice([token]), "Mode %s should resolve." % mode_id)
			return
	_check(false, "Mode %s should be available." % mode_id)


func _finish_turn(turn_manager: TurnManager) -> void:
	turn_manager.end_turn()
	turn_manager.tick(GameState.DEFAULT_END_TURN_COOLDOWN_SECONDS)


func _first_choice_card_id(game_state: GameState) -> String:
	if game_state.pending_choice == null or game_state.pending_choice.candidates.is_empty():
		return ""
	var card: CardDefinition = game_state.pending_choice.candidates[0]["card"]
	return card.id


func _resolve_first_choice(game_state: GameState) -> void:
	_check(game_state.pending_choice != null, "A pending choice should exist.")
	if game_state.pending_choice == null:
		return
	if game_state.pending_choice.minimum == 0:
		_check(game_state.resolve_choice([]), "Optional choice should accept an empty selection.")
		return
	var token := str(game_state.pending_choice.candidates[0]["token"])
	_check(game_state.resolve_choice([token]), "The first pending choice should resolve.")


func _resolve_choice_by_ids(game_state: GameState, card_ids: Array[String]) -> void:
	_check(game_state.pending_choice != null, "A pending choice should exist.")
	if game_state.pending_choice == null:
		return
	var remaining := card_ids.duplicate()
	var tokens: Array[String] = []
	for candidate in game_state.pending_choice.candidates:
		var card: CardDefinition = candidate["card"]
		var index := remaining.find(card.id)
		if index == -1:
			continue
		tokens.append(str(candidate["token"]))
		remaining.remove_at(index)
	_check(remaining.is_empty(), "Requested choice cards should be available.")
	_check(game_state.resolve_choice(tokens), "Pending choice should accept selected cards.")


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
