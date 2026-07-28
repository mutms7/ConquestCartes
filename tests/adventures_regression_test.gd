extends SceneTree

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

const ADVENTURES_MARKET := [
	["amulet", "Amulet", 3, "action"],
	["artificer", "Artificer", 5, "action"],
	["bridge_troll", "Bridge Troll", 5, "action"],
	["caravan_guard", "Caravan Guard", 3, "action"],
	["coin_of_the_realm", "Coin of the Realm", 2, "resource"],
	["distant_lands", "Distant Lands", 5, "action"],
	["dungeon", "Dungeon", 3, "action"],
	["duplicate", "Duplicate", 4, "action"],
	["gear", "Gear", 3, "action"],
	["giant", "Giant", 5, "action"],
	["guide", "Guide", 3, "action"],
	["haunted_woods", "Haunted Woods", 5, "action"],
	["hireling", "Hireling", 6, "action"],
	["lost_city", "Lost City", 5, "action"],
	["magpie", "Magpie", 4, "action"],
	["messenger", "Messenger", 4, "action"],
	["miser", "Miser", 4, "action"],
	["page", "Page", 2, "action"],
	["peasant", "Peasant", 2, "action"],
	["port", "Port", 4, "action"],
	["ranger", "Ranger", 4, "action"],
	["ratcatcher", "Ratcatcher", 2, "action"],
	["raze", "Raze", 2, "action"],
	["relic", "Relic", 5, "resource"],
	["royal_carriage", "Royal Carriage", 5, "action"],
	["storyteller", "Storyteller", 5, "action"],
	["swamp_hag", "Swamp Hag", 5, "action"],
	["transmogrify", "Transmogrify", 4, "action"],
	["treasure_trove", "Treasure Trove", 5, "resource"],
	["wine_merchant", "Wine Merchant", 5, "action"],
]

const ADVENTURES_TRAVELLERS := [
	["treasure_hunter", 3, "warrior"],
	["warrior", 4, "hero"],
	["hero", 5, "champion"],
	["champion", 6, ""],
	["soldier", 3, "fugitive"],
	["fugitive", 4, "disciple"],
	["disciple", 5, "teacher"],
	["teacher", 6, ""],
]

const ADVENTURES_EVENTS := [
	["alms", 0], ["ball", 5], ["bonfire", 3], ["borrow", 0],
	["expedition", 3], ["ferry", 3], ["inheritance", 7], ["lost_arts", 6],
	["mission", 4], ["pathfinding", 8], ["pilgrimage", 4], ["plan", 3],
	["quest", 0], ["raid", 5], ["save", 1], ["scouting_party", 2],
	["seaway", 5], ["trade", 5], ["training", 6], ["travelling_fair", 2],
]

# Every Adventures top-level effect currently has a resolver in GameState.
# Keeping this allow-list in the regression test makes a new data typo fail
# before it can emit the engine's "Unknown card effect kind" warning.
const KNOWN_EFFECT_KINDS := {
	"artificer": true, "attack": true, "champion": true,
	"choose_one_of_standard": true, "discard_deck": true,
	"discard_filtered": true, "discard_from_hand_draw": true,
	"distant_lands_score": true, "duration_hand_size": true,
	"duration_marker": true, "each_other_player_draws": true,
	"gain_card": true, "gain_from_supply": true, "inheritance": true,
	"journey_attack": true, "journey_flip": true, "magpie_reveal": true,
	"messenger_first_buy": true, "mission": true, "next_hand_draw_bonus": true,
	"pilgrimage": true, "player_token": true, "quest": true, "raid": true,
	"raze": true, "reaction": true, "reduce_costs": true,
	"register_buy_attack": true, "register_gain_attack": true,
	"replay_action": true, "reserve_duplicate_gain": true,
	"reserve_redraw": true, "reserve_remodel": true, "reserve_replay": true,
	"reserve_store": true, "reserve_trash": true, "set_aside_from_hand": true,
	"storyteller": true, "supply_tokens": true, "survey_top": true,
	"teacher_token": true, "trade": true, "trash_from_play": true,
	"traveller_upgrade": true, "travelling_fair": true, "turn_start_bonus": true,
	"wine_merchant_call": true,
}

var failure_count := 0


func _initialize() -> void:
	seed(1337)
	_test_catalog_contracts()
	_test_event_offer_contract()
	_test_port_is_non_recursive()
	_test_treasure_trove_on_play()
	_test_storyteller_order()
	_test_wine_merchant_cleanup()
	_test_distant_lands_tavern_scoring()
	_test_distant_lands_gain_path()
	_test_pile_token_timing()
	_test_mission_eligibility_and_extra_turn()
	_test_journey_flip()
	_test_tokens()
	_test_traveller_exchange()
	_test_all_records_and_effects()
	if failure_count > 0:
		push_error("[Test] Adventures regression test failed with %d issue(s)." % failure_count)
		quit(1)
		return
	print("[Test] Adventures regression test passed.")
	quit(0)


func _new_expansion_game(player_count: int = 1) -> GameState:
	var game_state := GameState.new()
	if not game_state.load_cards(CARD_DATA_PATH):
		_check(false, "The full card catalog should load.")
		return null
	if not game_state.setup_starting_game(player_count):
		_check(false, "A deterministic game should initialize.")
		return null
	# Put every Adventures market pile in one controlled market, while keeping
	# the ordinary resource/victory side piles available to gain effects.
	game_state.market.clear()
	for row in ADVENTURES_MARKET:
		game_state.market.append(game_state.card_catalog[str(row[0])])
	for card_id in ["silver_leaf", "amber_circlet", "homestead", "briar_gate", "royal_charter"]:
		game_state.market.append(game_state.card_catalog[card_id])
	game_state._initialize_supply_piles()
	for game_player in game_state.players:
		game_player.clear_all()
	game_state.player.actions = 100
	game_state.player.buys = 100
	game_state.player.turn_phase = GameState.TURN_PHASE_ACTION
	return game_state


func _test_catalog_contracts() -> void:
	var game_state := _new_expansion_game()
	if game_state == null:
		return
	var market_ids: Array[String] = []
	for row in ADVENTURES_MARKET:
		var card_id := str(row[0])
		_check(game_state.card_catalog.has(card_id), "Adventures card %s should exist." % card_id)
		if not game_state.card_catalog.has(card_id):
			continue
		var card: CardDefinition = game_state.card_catalog[card_id]
		market_ids.append(card_id)
		_check(card.card_group == GameState.ADVENTURES_GROUP, "%s should be in Adventures." % card_id)
		_check(card.card_name == str(row[1]), "%s should retain its Kingdom name." % card_id)
		_check(card.cost == int(row[2]), "%s should cost %d." % [card_id, int(row[2])])
		_check(card.card_type == str(row[3]), "%s should have core type %s." % [card_id, str(row[3])])
		_check(card.market_enabled and not card.is_event_card(), "%s should be a Kingdom pile." % card_id)
	_check(market_ids.size() == 30, "Adventures should expose exactly 30 Kingdom piles.")

	for row in ADVENTURES_TRAVELLERS:
		var card_id := str(row[0])
		_check(game_state.card_catalog.has(card_id), "Traveller pile %s should exist." % card_id)
		if not game_state.card_catalog.has(card_id):
			continue
		var card: CardDefinition = game_state.card_catalog[card_id]
		_check(card.cost == int(row[1]), "%s should cost %d." % [card_id, int(row[1])])
		# Champion and Teacher are the terminal upgrades: they remain five-card
		# non-Supply piles but no longer offer another Traveller exchange.
		if not ["champion", "teacher"].has(card_id):
			_check(card.is_traveller_card(), "%s should be a Traveller." % card_id)
		_check(not card.is_supply_card(), "%s should be a non-Supply Traveller pile." % card_id)
		_check(not card.market_enabled, "%s should stay out of the Kingdom market." % card_id)
		_check(bool(card.metadata.get("support_pile", false)), "%s should be a support pile." % card_id)
		_check(card.traveller_upgrade_id == str(row[2]), "%s should point to %s." % [card_id, str(row[2]) if not str(row[2]).is_empty() else "the end of its path"])
		_check(game_state.get_traveller_supply_count(card_id) == 5, "%s should have five Traveller copies." % card_id)

	for row in ADVENTURES_EVENTS:
		var card_id := str(row[0])
		_check(game_state.card_catalog.has(card_id), "Event %s should exist." % card_id)
		if not game_state.card_catalog.has(card_id):
			continue
		var event_card: CardDefinition = game_state.card_catalog[card_id]
		_check(event_card.is_event_card() and event_card.event_enabled, "%s should be an enabled Event." % card_id)
		_check(event_card.event_group == GameState.ADVENTURES_GROUP, "%s should use Adventures events." % card_id)
		_check(event_card.get_event_cost() == int(row[1]), "%s should cost %d." % [card_id, int(row[1])])
	_check(game_state.event_catalog.size() >= 20, "All 20 Adventures Events should enter the event catalog.")


func _test_event_offer_contract() -> void:
	var game_state := _new_expansion_game()
	if game_state == null:
		return
	var offer := game_state.get_selected_event_ids()
	_check(offer.size() >= 1 and offer.size() <= 2, "An enabled Adventures game should offer one or two Events.")
	_check(game_state.get_event_candidates().size() == offer.size(), "The visible Event row should match the authoritative offer.")
	var rejected: CardDefinition = null
	for card in game_state.event_catalog:
		if not offer.has(card.id):
			rejected = card
			break
	if rejected != null:
		game_state.player.coins = 100
		game_state.player.buys = 100
		_check(not game_state.buy_event(rejected), "An unselected Event must be rejected by the authoritative buy path.")
	game_state.set_kingdom_enabled(GameState.ADVENTURES_GROUP, false)
	_check(game_state.get_selected_event_ids().is_empty(), "Disabling Adventures should clear the Event offer.")
	_check(game_state.get_event_candidates().is_empty(), "Disabled Adventures should expose no Events.")
	if rejected != null:
		_check(not game_state.buy_event(rejected), "Disabled Adventures must reject Event purchases.")


func _test_port_is_non_recursive() -> void:
	var game_state := _new_expansion_game()
	var port: CardDefinition = game_state.card_catalog["port"]
	var initial_supply := game_state.get_supply_count("port")
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(game_state.buy_card(port), "Port should be bought from its Supply pile.")
	_drain_choices(game_state)
	_check(game_state.get_supply_count("port") == initial_supply - 2, "Port's gain should consume exactly one additional Port (initial %d, remaining %d)." % [initial_supply, game_state.get_supply_count("port")])
	_check(game_state.player.discard_pile.count(port) == 2, "Port should gain one copy, not recurse (discard copies %d)." % game_state.player.discard_pile.count(port))
	_check(game_state.player.play_area.is_empty(), "A bought Port should not enter play while testing its on-gain rule.")


func _test_treasure_trove_on_play() -> void:
	var game_state := _new_expansion_game()
	var trove: CardDefinition = game_state.card_catalog["treasure_trove"]
	game_state.player.turn_phase = GameState.TURN_PHASE_BUY
	game_state.player.hand.append(trove)
	_check(game_state.play_card(trove), "Treasure Trove should play in the Buy phase.")
	_drain_choices(game_state)
	_check(game_state.player.discard_pile.has(game_state.card_catalog["amber_circlet"]), "Treasure Trove should gain a Gold on play.")
	_check(game_state.player.discard_pile.has(game_state.card_catalog["pebble_coin"]), "Treasure Trove should gain a Copper on play.")
	_check(game_state.player.coins == 2, "Treasure Trove should provide its two base coins before its gains.")


func _test_storyteller_order() -> void:
	var game_state := _new_expansion_game()
	var storyteller: CardDefinition = game_state.card_catalog["storyteller"]
	var silver: CardDefinition = game_state.card_catalog["silver_leaf"]
	game_state.player.hand.assign([storyteller, silver, silver])
	for _index in range(5):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(storyteller), "Storyteller should play.")
	_check(game_state.pending_choice != null, "Storyteller should ask which Treasures to play.")
	if game_state.pending_choice != null:
		var tokens: Array[String] = []
		for candidate in game_state.pending_choice.candidates:
			if tokens.size() < 2:
				tokens.append(str(candidate["token"]))
		_check(game_state.resolve_choice(tokens), "Storyteller's Treasure selection should resolve.")
	_drain_choices(game_state)
	_check(game_state.player.coins == 0, "Storyteller should pay all coins after playing Treasures.")
	_check(game_state.player.hand.size() == 5, "Storyteller should draw one card, then one per coin paid.")
	_check(game_state.player.play_area.count(silver) == 2, "Storyteller should play both selected Silvers before conversion.")


func _test_wine_merchant_cleanup() -> void:
	var game_state := _new_expansion_game()
	var wine: CardDefinition = game_state.card_catalog["wine_merchant"]
	game_state.player.hand.append(wine)
	_check(game_state.play_card(wine), "Wine Merchant should play.")
	_drain_choices(game_state)
	_check(game_state.player.reserve_mat.has(wine), "Wine Merchant should move to the Tavern mat.")
	game_state.player.coins = 4
	game_state.begin_cleanup()
	_check(not game_state.player.reserve_mat.has(wine), "Wine Merchant should leave the Tavern mat during cleanup at two or more coins.")
	_check(game_state.player.discard_pile.has(wine), "Wine Merchant should be discarded by Tavern cleanup.")


func _test_distant_lands_tavern_scoring() -> void:
	var game_state := _new_expansion_game()
	var distant: CardDefinition = game_state.card_catalog["distant_lands"]
	game_state.player.reserve_mat.append(distant)
	_check(game_state.calculate_score() == 4, "Distant Lands should score four VP while on the Tavern mat.")
	game_state.player.reserve_mat.clear()
	game_state.player.discard_pile.append(distant)
	_check(game_state.calculate_score() == 0, "Distant Lands should score zero VP after leaving the Tavern mat.")


func _test_distant_lands_gain_path() -> void:
	var game_state := _new_expansion_game()
	var distant: CardDefinition = game_state.card_catalog["distant_lands"]
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(game_state.buy_card(distant), "Distant Lands should be gainable from its Supply pile.")
	_drain_choices(game_state)
	_check(game_state.player.discard_pile.has(distant), "A normal Distant Lands gain should enter the discard pile.")
	_check(not game_state.player.set_aside_pile.has(distant), "A normal Distant Lands gain should not be set aside.")
	_check(game_state.calculate_score() == 0, "Distant Lands should score no VP before being played to the Tavern.")

	game_state.player.discard_pile.erase(distant)
	game_state.player.hand.append(distant)
	game_state.player.actions = 10
	game_state.player.turn_phase = GameState.TURN_PHASE_ACTION
	_check(game_state.play_card(distant), "A gained Distant Lands should be playable.")
	_drain_choices(game_state)
	_check(game_state.player.reserve_mat.has(distant), "Playing Distant Lands should move it to the Tavern mat.")
	_check(game_state.calculate_score() == 4, "Distant Lands should score four VP once on the Tavern mat.")


func _test_pile_token_timing() -> void:
	# +1 pile tokens are consumed by playing a card from the pile, not by
	# gaining that card. Guide has no coin-producing text, isolating the token.
	var game_state := _new_expansion_game()
	var guide: CardDefinition = game_state.card_catalog["guide"]
	_check(game_state.move_active_player_supply_token("coin", "guide"), "A coin token should be placeable on Guide.")
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(game_state.buy_card(guide), "Guide should be gainable from its tokenized pile.")
	_drain_choices(game_state)
	_check(game_state.player.coins == 7, "A coin pile token should not grant a coin when the card is gained.")
	_check(game_state.get_active_player_supply_token_card("coin") == "guide", "A +1 pile token should remain after a gain.")
	game_state.player.discard_pile.erase(guide)
	game_state.player.hand.append(guide)
	game_state.player.actions = 10
	game_state.player.turn_phase = GameState.TURN_PHASE_ACTION
	_check(game_state.play_card(guide), "Guide should play from its tokenized pile.")
	_drain_choices(game_state)
	_check(game_state.player.coins == 8, "A coin pile token should grant one coin when its pile card is played.")

	# Plan's trash token is a buy trigger, not a generic gain trigger.
	game_state = _new_expansion_game()
	guide = game_state.card_catalog["guide"]
	var copper: CardDefinition = game_state.card_catalog["pebble_coin"]
	_check(game_state.move_active_player_supply_token("trash", "guide"), "A trash token should be placeable on Guide.")
	game_state.player.hand.append(copper)
	game_state._gain_card_by_id("guide", "discard")
	_check(not game_state.has_pending_choice(), "A generic gain should not offer Plan's hand-trash choice.")
	_check(game_state.player.hand.has(copper), "A generic gain should not trash a card for Plan.")
	_check(game_state.get_active_player_supply_token_card("trash") == "guide", "Plan's token should remain after a generic gain.")
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(game_state.buy_card(guide), "Guide should still be buyable after a generic gain.")
	_check(game_state.has_pending_choice(), "Buying from Plan's pile should offer a hand-trash choice.")
	if game_state.pending_choice != null:
		_check(str(game_state.pending_choice.context.get("expansion_token", "")) == "trash", "Plan's buy choice should be tagged as a trash-token choice.")
	_drain_choices(game_state)


func _test_mission_eligibility_and_extra_turn() -> void:
	var mission_game := _new_expansion_game(2)
	var mission: CardDefinition = mission_game.card_catalog["mission"]
	mission_game.player.coins = 100
	mission_game.player.buys = 1
	mission_game.set_selected_event_ids([mission.id])
	_check(not mission_game.buy_event(mission), "Mission should be unavailable before another player's turn has occurred.")
	mission_game.advance_active_player()
	mission_game.player.coins = 100
	mission_game.player.buys = 1
	_check(mission_game.buy_event(mission), "Mission should be eligible after the previous turn belonged to another player.")
	_drain_choices(mission_game)

	# In turn-based multiplayer, finishing the Mission buyer's normal turn
	# should keep control for exactly one extra turn with buys disabled.
	var game_state := _new_expansion_game(2)
	game_state.turn_based_enabled = true
	var turn_manager := TurnManager.new()
	turn_manager.configure(game_state)
	turn_manager.start_first_turn()
	turn_manager.end_turn()
	turn_manager.tick(0.0)
	_check(game_state.active_player_index == 1, "Turn-based cleanup should advance to the other player.")
	game_state.player.coins = 100
	game_state.player.buys = 1
	mission = game_state.card_catalog["mission"]
	game_state.set_selected_event_ids([mission.id])
	_check(game_state.buy_event(mission), "Mission should be buyable by the player whose previous turn was another seat.")
	_drain_choices(game_state)
	var guide: CardDefinition = game_state.card_catalog["guide"]
	turn_manager.end_turn()
	turn_manager.tick(0.0)
	_check(game_state.active_player_index == 1, "Mission should grant the same player one extra turn.")
	_check(bool(game_state.turn_flags.get("mission_no_buys", false)), "Mission's extra turn should carry the no-buy marker.")
	game_state.player.coins = 100
	_check(not game_state.buy_card(guide), "Cards should not be buyable during Mission's extra turn.")
	turn_manager.end_turn()
	turn_manager.tick(0.0)
	_check(game_state.active_player_index == 0, "After the Mission extra turn, control should pass to the next player.")


func _test_journey_flip() -> void:
	var game_state := _new_expansion_game()
	var giant: CardDefinition = game_state.card_catalog["giant"]
	game_state.player.hand.assign([giant, giant])
	_check(game_state.player.is_journey_active("journey"), "The Journey token should start face up.")
	_check(game_state.play_card(giant), "Giant should play from a face-up Journey.")
	_drain_choices(game_state)
	_check(not game_state.player.is_journey_active("journey"), "Giant should flip the Journey token.")
	_check(game_state.player.coins == 1, "The first Giant should take the inactive Journey branch.")
	_check(game_state.play_card(giant), "A second Giant should play.")
	_drain_choices(game_state)
	_check(game_state.player.is_journey_active("journey"), "The second Giant should flip the Journey token back.")
	_check(game_state.player.coins == 6, "The second Giant should take the active Journey branch for five coins.")


func _test_tokens() -> void:
	var game_state := _new_expansion_game()
	var borrow: CardDefinition = game_state.card_catalog["borrow"]
	game_state.set_selected_event_ids([borrow.id])
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(game_state.buy_event(borrow), "Borrow should be purchasable.")
	_drain_choices(game_state)
	_check(game_state.player.deck_minus_card_token, "Borrow should place the -1 Card token on the player's deck.")

	game_state = _new_expansion_game()
	var ball: CardDefinition = game_state.card_catalog["ball"]
	game_state.set_selected_event_ids([ball.id])
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(game_state.buy_event(ball), "Ball should be purchasable.")
	_drain_choices(game_state)
	_check(game_state.player.coin_minus_token, "Ball should place the -1 coin token on the player.")

	game_state = _new_expansion_game()
	var ferry: CardDefinition = game_state.card_catalog["ferry"]
	game_state.set_selected_event_ids([ferry.id])
	game_state.player.coins = 10
	game_state.player.buys = 1
	_check(game_state.buy_event(ferry), "Ferry should be purchasable.")
	_drain_choices(game_state)
	_check(not game_state.get_active_player_supply_token_card("cost").is_empty(), "Ferry should move the -2 coin token to an Action Supply pile.")


func _test_traveller_exchange() -> void:
	var game_state := _new_expansion_game()
	var page: CardDefinition = game_state.card_catalog["page"]
	var treasure_hunter: CardDefinition = game_state.card_catalog["treasure_hunter"]
	var page_supply := game_state.get_supply_count("page")
	var hunter_supply := game_state.get_traveller_supply_count("treasure_hunter")
	# Model a Page that was bought from its Supply pile before it is played.
	game_state.set_supply_count("page", page_supply - 1)
	game_state.player.hand.append(page)
	_check(game_state.play_card(page), "Page should play before its Traveller exchange.")
	_drain_choices(game_state)
	game_state.begin_cleanup()
	_check(game_state.pending_choice != null, "Cleanup should offer a Page-to-Treasure-Hunter exchange.")
	if game_state.pending_choice != null:
		var token := str(game_state.pending_choice.candidates[0]["token"])
		_check(game_state.resolve_choice([token]), "The Traveller exchange should resolve.")
	_drain_choices(game_state)
	_check(game_state.player.discard_pile.has(treasure_hunter), "Exchanging Page should gain a Treasure Hunter.")
	_check(game_state.get_supply_count("page") == page_supply, "Exchanging Page should return it to its Supply pile.")
	_check(game_state.get_traveller_supply_count("treasure_hunter") == hunter_supply - 1, "Exchanging Page should consume one Treasure Hunter.")


func _test_all_records_and_effects() -> void:
	var all_ids: Array[String] = []
	var exercised_effect_count := 0
	for row in ADVENTURES_MARKET:
		all_ids.append(str(row[0]))
	for row in ADVENTURES_TRAVELLERS:
		all_ids.append(str(row[0]))
	for row in ADVENTURES_EVENTS:
		all_ids.append(str(row[0]))
	_check(all_ids.size() == 58, "The Adventures regression set should contain all 58 records.")
	for card_id in all_ids:
		var game_state := _new_expansion_game()
		if game_state == null or not game_state.card_catalog.has(card_id):
			continue
		var card: CardDefinition = game_state.card_catalog[card_id]
		for effect in card.special_effects:
			var kind := str(effect.get("kind", ""))
			_check(KNOWN_EFFECT_KINDS.has(kind), "%s has an unrecognized effect kind %s." % [card_id, kind])
		# Play every Kingdom/Traveller record and buy every Event record.  Choices
		# are resolved deterministically so this remains a true headless exercise.
		if card.is_event_card():
			game_state.set_selected_event_ids([card.id])
			game_state.player.coins = 100
			game_state.player.buys = 100
			_check(game_state.buy_event(card), "%s should resolve as an Event." % card_id)
		else:
			game_state.player.hand.append(card)
			game_state.player.actions = 100
			game_state.player.turn_phase = GameState.TURN_PHASE_ACTION
			_check(game_state.play_card(card), "%s should resolve as a playable record." % card_id)
		_drain_choices(game_state)
		_check(not game_state.has_pending_choice(), "%s should leave no unresolved choice." % card_id)
		_check(game_state.resolution_queue.is_empty(), "%s should drain its resolution queue." % card_id)
		# Trigger every top-level effect explicitly as well.  This covers data
		# effects whose normal trigger is gain, scoring, cleanup, or next_turn.
		for effect in card.special_effects:
			game_state._resolve_special_effect(effect.duplicate(true), card)
			exercised_effect_count += 1
			_drain_choices(game_state)
	_check(exercised_effect_count == 83, "All 83 Adventures effect records should be exercised.")


func _drain_choices(game_state: GameState) -> void:
	var guard := 0
	while game_state.has_pending_choice() and guard < 200:
		var choice := game_state.pending_choice
		var tokens: Array[String] = []
		if choice.minimum > 0:
			var needed := mini(choice.minimum, choice.candidates.size())
			for index in range(needed):
				tokens.append(str(choice.candidates[index]["token"]))
		_check(game_state.resolve_choice(tokens), "A deterministic choice should resolve (%s)." % choice.resolver)
		guard += 1
	_check(guard < 200, "Choice resolution should terminate without a loop.")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error("[Test] %s" % message)
