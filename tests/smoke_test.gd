extends SceneTree

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"
const MAIN_UI_SCRIPT := preload("res://scripts/ui/main_ui.gd")
const EXPECTED_CARD_COUNT := 172
const WORDING_GUIDE_PATH := "res://docs/card_wording_conventions.md"
const INACTIVE_CARD_IDS := [
	"starpath_seeker",
	"river_ward",
	"harvest_feast",
	"astral_spyglass",
	"relic_seeker",
	"briar_hex",
	"auric_reserve",
	"crownland_expanse",
]
# Timer cards that only appear in multiplayer markets (excluded from solo).
const MULTIPLAYER_ONLY_CARD_IDS := [
	"sunspire_bell",
	"hourglass_reliquary",
	"twilight_retreat",
	"stolen_minute",
	"lantern_vigil",
]
# Cards whose effects only matter in multiplayer (attacks, shared draws, or
# attack immunity) do nothing solo, so they are pulled from singleplayer markets.
const MULTIPLAYER_ONLY_INTERACTION_CARD_IDS := [
	"roadside_reaver",
	"royal_clerk",
	"briar_witch",
	"river_magistrate",
	"candlecap_kettle",
	"stonewall_raider",
	"briar_hut",
	"thornbinder",
	"council_hearth",
	"hedgewarden",
	"sealed_treaty",
	"sable_loan",
	"raucous_bell",
]
const EXPECTED_ART_LINKED_NAMES := {
	"wishing_garden": "Gardens",
	"starpath_seeker": "Adventurer",
	"master_weaver": "Artisan",
	"roadside_reaver": "Bandit",
	"royal_clerk": "Bureaucrat",
	"root_cellar": "Cellar",
	"river_ward": "Chancellor",
	"quiet_chapel": "Chapel",
	"council_hearth": "Council Room",
	"harvest_feast": "Feast",
	"lantern_festival": "Festival",
	"dawn_herald": "Harbinger",
	"candlecap_laboratory": "Laboratory",
	"grand_archive": "Library",
	"crossroads_market": "Market",
	"moonlit_mine": "Mine",
	"coin_broker": "Moneylender",
	"supply_scout": "Poacher",
	"manor_rebuilder": "Remodel",
	"clockwork_sentry": "Sentry",
	"forge_hall": "Smithy",
	"astral_spyglass": "Spyglass",
	"relic_seeker": "Reliquary",
	"echoing_hall": "Throne Room",
	"banner_vassal": "Vassal",
	"guild_workshop": "Workshop",
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
const WITCHING_HOUR_CARD_IDS := [
	"witchs_bargain",
	"hex_eater",
	"hedgewarden",
	"thornbinder",
	"bramble_idol",
	"cursed_ingot",
	"hex_mill",
	"bone_cart",
	"bonepicker_crow",
	"moth_shrine",
	"reliquary_key",
	"pilgrim_stone",
	"stolen_minute",
	"lantern_vigil",
	"moonlit_caravan",
	"night_ferry",
	"merchant_barge",
	"fen_lighthouse",
	"dream_courier",
	"owl_post",
	"sowing_moon",
	"long_causeway",
]
const PROSPERITY_CARD_IDS := [
	"gilded_ledger",
	"cairn_appraiser",
	"skyline_foundry",
	"sealed_treaty",
	"ember_forge",
	"royal_exchange",
	"grand_bazaar",
	"copper_harbor",
	"courtly_echo",
	"sable_loan",
	"minted_seal",
	"stone_monument",
	"veil_broker",
	"quarry_mark",
	"raucous_bell",
	"crown_vessel",
	"watchtower_chart",
	"chance_engine",
	"twin_pillars",
	"venture_compass",
	"artisan_vault",
	"merchant_guild",
	"route_toll",
	"capital_mirror",
	"granary_riddle",
]
const ADVENTURES_MARKET_CARD_IDS := [
  "amulet",
  "artificer",
  "bridge_troll",
  "caravan_guard",
  "coin_of_the_realm",
  "distant_lands",
  "dungeon",
  "duplicate",
  "gear",
  "giant",
  "guide",
  "haunted_woods",
  "hireling",
  "lost_city",
  "magpie",
  "messenger",
  "miser",
  "page",
  "peasant",
  "port",
  "ranger",
  "ratcatcher",
  "raze",
  "relic",
  "royal_carriage",
  "storyteller",
  "swamp_hag",
  "transmogrify",
  "treasure_trove",
  "wine_merchant",
]
const ADVENTURES_SUPPORT_CARD_IDS := [
  "treasure_hunter",
  "warrior",
  "hero",
  "champion",
  "soldier",
  "fugitive",
  "disciple",
  "teacher",
]
const ADVENTURES_EVENT_IDS := [
  "alms",
  "ball",
  "bonfire",
  "borrow",
  "expedition",
  "ferry",
  "inheritance",
  "lost_arts",
  "mission",
  "pathfinding",
  "pilgrimage",
  "plan",
  "quest",
  "raid",
  "save",
  "scouting_party",
  "seaway",
  "trade",
  "training",
  "travelling_fair",
]
var failure_count := 0


func _initialize() -> void:
	_test_card_catalog()
	_test_adventures_expansion()
	_test_adventures_core_regressions()
	_test_wording_conventions()
	_test_full_game_loop()
	_test_draw_across_shuffle_boundary()
	_test_scoring()
	_test_supply_piles()
	_test_prosperity_cards()
	_test_turn_cooldown()
	_test_turn_phases()
	_test_turn_based_mode()
	_test_multiplayer_only_timer_cards()
	_test_relic_system()
	_test_multiplayer_lobby_attacks()
	_test_prosperity_multiplayer_choices()
	_test_network_snapshot_redaction()
	_test_multiplayer_game_end()
	_test_special_effects()
	_test_hinterland_expansion()
	_test_witching_hour_expansion()
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
			card.card_name.length() <= 18,
			"%s should have a compact display name." % card.id
		)
		_check(not card.art_id.is_empty(), "%s should map to artwork." % card.card_name)
		var art_path := "res://assets/cards/%s.png" % card.art_id
		_check(
			ResourceLoader.exists(art_path) or FileAccess.file_exists(art_path),
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
	for card_id in WITCHING_HOUR_CARD_IDS:
		_check(
			game_state.card_catalog.has(card_id),
			"Witching Hour card %s should exist." % card_id
		)
		if game_state.card_catalog.has(card_id):
			_check(
				game_state.card_catalog[card_id].card_group == GameState.WITCHING_HOUR_GROUP,
				"%s should belong to the named Witching Hour card group." % card_id
			)
	for card_id in PROSPERITY_CARD_IDS:
		_check(game_state.card_catalog.has(card_id), "Prosperity card %s should exist." % card_id)
		if game_state.card_catalog.has(card_id):
			_check(
				game_state.card_catalog[card_id].card_group == GameState.PROSPERITY_GROUP,
				"%s should belong to the named Prosperity card group." % card_id
			)
	_check(
		game_state.card_catalog[GameState.PROSPERITY_RESOURCE_ID].card_type == "resource"
		and game_state.card_catalog[GameState.PROSPERITY_VICTORY_ID].card_type == "victory",
		"Prosperity side supplies should use resource and victory types."
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
		== "Draw 4 cards. Gain 1 buy. Each other player draws a card.",
		"Standard outputs should use canonical sentence order."
	)
	_check(
		game_state.card_catalog["guild_workshop"].description
		== "Gain a card costing up to 4.",
		"Gain wording should describe the player's supply choice."
	)


func _test_adventures_expansion() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return
	var market_cards: Array[CardDefinition] = []
	for card_id in ADVENTURES_MARKET_CARD_IDS:
		_check(game_state.card_catalog.has(card_id), "Adventures market card %s should resolve." % card_id)
		if not game_state.card_catalog.has(card_id):
			continue
		var card: CardDefinition = game_state.card_catalog[card_id]
		market_cards.append(card)
		_check(card.card_group == "Adventures", "%s should belong to Adventures." % card_id)
		_check(card.market_enabled and not card.is_event_card(), "%s should be a market card." % card_id)
		_check(not card.description.is_empty(), "%s should have official rules text." % card_id)
	_check(market_cards.size() == 30, "Adventures should expose exactly 30 market piles.")
	var support_cards: Array[CardDefinition] = []
	for card_id in ADVENTURES_SUPPORT_CARD_IDS:
		_check(game_state.card_catalog.has(card_id), "Adventures non-Supply card %s should resolve." % card_id)
		if not game_state.card_catalog.has(card_id):
			continue
		var support: CardDefinition = game_state.card_catalog[card_id]
		support_cards.append(support)
		_check(not support.market_enabled, "%s should stay out of the random market." % card_id)
		_check(bool(support.metadata.get("support_pile", false)), "%s should be marked as a non-Supply pile." % card_id)
	_check(support_cards.size() == 8, "Adventures should include eight non-Supply upgrade piles.")
	for card_id in ADVENTURES_EVENT_IDS:
		_check(game_state.card_catalog.has(card_id), "Adventures event %s should resolve." % card_id)
		if not game_state.card_catalog.has(card_id):
			continue
		var event_card: CardDefinition = game_state.card_catalog[card_id]
		_check(event_card.is_event_card(), "%s should be an event card." % card_id)
		_check(event_card.event_enabled, "%s should opt into the event offer." % card_id)
		_check(event_card.event_group == "Adventures", "%s should use the Adventures event group." % card_id)
		_check(event_card.event_cost >= 0, "%s should declare an event cost." % card_id)
	_check(game_state.event_catalog.size() >= ADVENTURES_EVENT_IDS.size(), "All Adventures events should enter the event catalog.")
	_check(game_state.card_catalog["treasure_trove"].card_type == "resource" and game_state.card_catalog["treasure_trove"].market_enabled, "Treasure Trove should be a market Treasure.")
	_check(game_state.card_catalog["page"].traveller_upgrade_id == "treasure_hunter" and game_state.card_catalog["peasant"].traveller_upgrade_id == "soldier", "Page and Peasant should start the official Traveller paths.")
func _test_adventures_core_regressions() -> void:
	var game_state := _empty_game()
	_check(game_state.card_catalog["distant_lands"].special_effects.any(func(effect: Dictionary) -> bool: return str(effect.get("kind", "")) == "distant_lands_score"), "Distant Lands should use the scoring effect.")
	_check(game_state.card_catalog["coin_of_the_realm"].is_reserve_card() and game_state.card_catalog["wine_merchant"].is_reserve_card(), "Reserve cards should be marked for the Tavern mat.")
	_check(game_state.card_catalog["treasure_hunter"].traveller_upgrade_id == "warrior" and game_state.card_catalog["disciple"].traveller_upgrade_id == "teacher", "Non-Supply Traveller upgrades should form the official paths.")
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
	_check(
		GameState.CURSE_SUPPLY_COUNT == 20
		and game_state.get_supply_count("briar_hex")
			== game_state.scale_supply_count(GameState.CURSE_SUPPLY_COUNT)
		and game_state.get_supply_count("pebble_coin")
			== game_state.scale_supply_count(GameState.PEBBLE_SIDE_SUPPLY_COUNT)
		and game_state.get_supply_count(GameState.PROSPERITY_RESOURCE_ID)
			== game_state.scale_supply_count(GameState.PROSPERITY_RESOURCE_SUPPLY_COUNT)
		and game_state.get_supply_count(GameState.PROSPERITY_VICTORY_ID)
			== game_state.scale_supply_count(GameState.PROSPERITY_VICTORY_SUPPLY_COUNT_2P),
		"A solo game should halve every pile, including the finite side supplies."
	)
	var three_player := GameState.new()
	_check(three_player.load_cards(CARD_DATA_PATH), "Three-player side-supply test should load card data.")
	_check(three_player.setup_starting_game(3), "Three-player side-supply test should set up.")
	_check(
		three_player.get_supply_count(GameState.PROSPERITY_RESOURCE_ID) == 12
		and three_player.get_supply_count(GameState.PROSPERITY_VICTORY_ID) == 12,
		"Three-player Prosperity side supplies should be 12/12."
	)
	game_state.set_kingdom_enabled(GameState.PROSPERITY_GROUP, false)
	_check(
		not game_state.get_side_supply_card_ids().has(GameState.PROSPERITY_RESOURCE_ID)
		and not game_state.get_side_supply_card_ids().has(GameState.PROSPERITY_VICTORY_ID)
		and game_state.get_supply_count(GameState.PROSPERITY_RESOURCE_ID) == 0
		and game_state.get_supply_count(GameState.PROSPERITY_VICTORY_ID) == 0,
		"Disabling Prosperity should remove its side-supply entries."
	)
	game_state.set_kingdom_enabled(GameState.PROSPERITY_GROUP, true)
	_check(
		game_state.get_supply_count(GameState.PROSPERITY_RESOURCE_ID)
			== game_state.scale_supply_count(GameState.PROSPERITY_RESOURCE_SUPPLY_COUNT)
		and game_state.get_supply_count(GameState.PROSPERITY_VICTORY_ID)
			== game_state.scale_supply_count(GameState.PROSPERITY_VICTORY_SUPPLY_COUNT_2P),
		"Re-enabling Prosperity should restore only its two side supplies."
	)
	var pebble: CardDefinition = game_state.card_catalog["pebble_coin"]
	var pebble_count := game_state.get_supply_count("pebble_coin")
	game_state.player.buys = 1
	game_state.player.coins = 0
	_check(game_state.buy_card(pebble), "The zero-cost Pebble Coin side pile should be buyable.")
	_check(
		game_state.get_supply_count("pebble_coin") == pebble_count - 1
		and game_state.player.discard_pile.has(pebble),
		"Buying a side-supply Pebble Coin should decrement supply and enter discard."
	)
	var briar: CardDefinition = game_state.card_catalog[GameState.CURSE_CARD_ID]
	var briar_count := game_state.get_supply_count(GameState.CURSE_CARD_ID)
	game_state.player.buys = 1
	game_state.player.coins = 0
	_check(game_state.buy_card(briar), "The zero-cost Briar Hex side pile should be buyable.")
	_check(
		game_state.get_supply_count(GameState.CURSE_CARD_ID) == briar_count - 1
		and game_state.player.discard_pile.has(briar),
		"Buying a side-supply Briar Hex should decrement supply and enter discard."
	)
	var card: CardDefinition = game_state.market[0]
	var starting_count := game_state.get_supply_count(card.id)
	game_state.player.buys = 1
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
	game_state.set_supply_count("pebble_coin", 0)
	_check(
		game_state.get_empty_supply_pile_count() == 2,
		"Finite side piles should participate in the authoritative empty-pile count."
	)
	game_state.set_supply_count(card.id, starting_count)
	game_state.set_supply_count("pebble_coin", GameState.PEBBLE_SIDE_SUPPLY_COUNT)
	game_state.set_supply_count(GameState.PROSPERITY_VICTORY_ID, 0)
	_check(
		game_state.is_game_end_condition_met(),
		"An empty Prosperity victory pile should end a game while the pack is enabled."
	)
	game_state.set_supply_count("pebble_coin", 17)
	game_state.set_kingdom_enabled(GameState.PROSPERITY_GROUP, false)
	_check(
		game_state.get_supply_count("pebble_coin") == 17
		and not game_state.is_game_end_condition_met(),
		"Removing Prosperity should preserve other supplies and its premium-victory end condition."
	)


func _test_prosperity_cards() -> void:
	# Keep a compact, data-driven contract for every Prosperity card.  This
	# catches accidental ID/type/cost/effect drift while the focused checks below
	# exercise the new resolution hooks.
	var game_state := _empty_game()
	var contracts := {
		"gilded_ledger": ["action", 5, "vault"], "cairn_appraiser": ["action", 4, "bishop"],
		"skyline_foundry": ["action", 5, "city_empty_bonus"], "sealed_treaty": ["action", 4, "attack"],
		"ember_forge": ["action", 7, "forge"], "royal_exchange": ["resource", 5, "war_chest"],
		"grand_bazaar": ["action", 6, "buy_restriction"], "copper_harbor": ["resource", 4, "investment"],
		"courtly_echo": ["action", 7, "replay_action"], "sable_loan": ["action", 5, "attack"],
		"minted_seal": ["action", 5, "mint_copy_resource"], "stone_monument": ["action", 4, "gain_vp_tokens"],
		"veil_broker": ["resource", 7, "bank"], "quarry_mark": ["resource", 4, "reduce_costs"],
		"raucous_bell": ["action", 5, "attack"], "crown_vessel": ["resource", 6, "hoard_buy"],
		"watchtower_chart": ["action", 3, "watchtower_reaction"], "chance_engine": ["resource", 5, "crystal_ball"],
		"twin_pillars": ["action", 4, "base"], "venture_compass": ["resource", 4, "tiara_play_resource"],
		"artisan_vault": ["resource", 3, "anvil"], "merchant_guild": ["action", 8, "peddler_discount"],
		"route_toll": ["resource", 5, "collection_gain"], "capital_mirror": ["action", 7, "remodel"],
		"granary_riddle": ["action", 5, "draw_per_type_in_hand"],
	}
	for card_id in contracts:
		var card: CardDefinition = game_state.card_catalog[card_id]
		var expected: Array = contracts[card_id]
		_check(card.card_type == expected[0] and card.cost == expected[1], "%s base contract should match." % card_id)
		var kinds: Array[String] = []
		for effect in card.special_effects:
			kinds.append(str(effect.get("kind", "")))
		_check(expected[2] == "base" or kinds.has(expected[2]), "%s effect contract should include %s." % [card_id, expected[2]])
	_check(game_state.card_catalog["gilded_ledger"].draw_cards == 2 and game_state.card_catalog["gilded_ledger"].gain_actions == 0, "Vault base outputs should match.")
	_check(game_state.card_catalog["cairn_appraiser"].gain_coins == 1, "Bishop base output should match.")
	_check(game_state.card_catalog["skyline_foundry"].draw_cards == 1 and game_state.card_catalog["skyline_foundry"].gain_actions == 2, "City base outputs should match.")
	_check(game_state.card_catalog["sealed_treaty"].gain_coins == 2, "Clerk base output should match.")
	_check(game_state.card_catalog["royal_exchange"].coin_value == 0 and game_state.card_catalog["sable_loan"].gain_coins == 3, "War Chest and hex attack outputs should match.")
	_check(game_state.card_catalog["grand_bazaar"].draw_cards == 1 and game_state.card_catalog["grand_bazaar"].gain_actions == 1 and game_state.card_catalog["grand_bazaar"].gain_buys == 1 and game_state.card_catalog["grand_bazaar"].gain_coins == 2, "Bazaar outputs should match.")
	_check(game_state.card_catalog["courtly_echo"].special_effects[0].get("repetitions", 0) == 3, "Triple replay should use three repetitions.")
	var court_prompt := _empty_game()
	var court_card: CardDefinition = court_prompt.card_catalog["courtly_echo"]
	court_prompt.player.hand = [court_card, court_prompt.card_catalog["twin_pillars"]]
	_check(court_prompt.play_card(court_card), "Courtly Echo should open its replay choice.")
	_check(
		court_prompt.has_pending_choice()
		and court_prompt.pending_choice.prompt.contains("3 times")
		and court_prompt.pending_choice.confirm_text.contains("3 TIMES"),
		"Courtly Echo should label its choice as a three-play effect."
	)
	_resolve_first_choice(court_prompt)
	_check(game_state.card_catalog["stone_monument"].gain_coins == 2 and game_state.card_catalog["stone_monument"].gain_buys == 0, "Monument outputs should match.")
	_check(game_state.card_catalog["quarry_mark"].coin_value == 1 and game_state.card_catalog["quarry_mark"].special_effects[0].get("amount", 0) == 2, "Quarry discount output should match.")
	_check(game_state.card_catalog["raucous_bell"].draw_cards == 3 and game_state.card_catalog["raucous_bell"].gain_actions == 0, "Rabble reveal output should match.")
	_check(game_state.card_catalog["crown_vessel"].coin_value == 2 and game_state.card_catalog["watchtower_chart"].special_effects[0].get("amount", 0) == 6, "Hoard and Watchtower outputs should match.")
	_check(game_state.card_catalog["twin_pillars"].draw_cards == 1 and game_state.card_catalog["twin_pillars"].gain_actions == 2 and game_state.card_catalog["twin_pillars"].gain_buys == 1, "Twin Pillars outputs should match.")
	_check(game_state.card_catalog["venture_compass"].gain_buys == 1 and game_state.card_catalog["artisan_vault"].coin_value == 1, "Tiara and Anvil outputs should match.")
	_check(game_state.card_catalog["merchant_guild"].draw_cards == 1 and game_state.card_catalog["merchant_guild"].gain_actions == 1 and game_state.card_catalog["merchant_guild"].gain_coins == 1, "Peddler base outputs should match.")
	_check(game_state.card_catalog["route_toll"].gain_buys == 1 and game_state.card_catalog["capital_mirror"].special_effects[0].get("cost_delta", 0) == 3, "Collection and Expand outputs should match.")
	_check(game_state.card_catalog["granary_riddle"].draw_cards == 0 and game_state.card_catalog["granary_riddle"].special_effects[0].get("card_type", "") == "resource", "Granary should count the resources revealed in hand.")
	var minted_kinds: Array[String] = []
	for effect in game_state.card_catalog["minted_seal"].special_effects:
		minted_kinds.append(str(effect.get("kind", "")))
	_check(minted_kinds.has("mint_gain_cleanup") and game_state.card_catalog["minted_seal"].special_effects[1].get("trigger_scope", "self") == "self", "Mint should clean played resources only when gained.")
	var tiara_kinds: Array[String] = []
	for effect in game_state.card_catalog["venture_compass"].special_effects:
		tiara_kinds.append(str(effect.get("kind", "")))
	_check(tiara_kinds.has("tiara_gain_reaction"), "Tiara should react to gains.")
	game_state.market.append(game_state.card_catalog["sable_loan"])
	var briar_hex: CardDefinition = game_state.card_catalog["briar_hex"]
	_check(game_state.card_has_type(briar_hex, "resource"), "Briar Hex should become a resource while Sable Loan is in the market.")
	game_state.player.hand.append(briar_hex)
	var coins_before_hex := game_state.player.coins
	_check(game_state.play_card(briar_hex), "Briar Hex should be playable as a resource while Sable Loan is in the market.")
	_check(game_state.player.coins == coins_before_hex + 1, "Briar Hex should give one coin while Sable Loan is in the market.")

	# Representative execution contracts for choice, token, cost, and reaction hooks.
	var ledger: CardDefinition = game_state.card_catalog["gilded_ledger"]
	game_state.player.hand.assign([ledger, game_state.card_catalog["pebble_coin"], game_state.card_catalog["silver_leaf"]])
	_check(game_state.play_card(ledger), "Gilded Ledger should play.")
	if game_state.has_pending_choice():
		_check(game_state.pending_choice.context is Dictionary and game_state.pending_choice.resolver == "vault_discard", "Vault choice context should be serializable.")
		_resolve_choice_by_ids(game_state, ["pebble_coin", "silver_leaf"])
	_check(game_state.player.coins >= 2, "Vault should pay one coin per discarded card.")

	var crystal := _empty_game()
	crystal.player.hand.append(crystal.card_catalog["chance_engine"])
	crystal.player.draw_pile.append(crystal.card_catalog["pebble_coin"])
	_check(crystal.play_card(crystal.card_catalog["chance_engine"]), "Chance Engine should play.")
	_check(crystal.has_pending_choice(), "Crystal Ball should offer top-card modes.")
	if crystal.has_pending_choice():
		_check(crystal.pending_choice.candidates.size() >= 2, "Crystal Ball should expose multiple modes.")

	var monument := _empty_game()
	monument.player.hand.append(monument.card_catalog["stone_monument"])
	_check(monument.play_card(monument.card_catalog["stone_monument"]), "Stone Monument should play.")
	_check(monument.player.vp_tokens == 1, "Stone Monument should grant one VP token.")

	var quarry := _empty_game()
	var action: CardDefinition = quarry.card_catalog["grand_bazaar"]
	quarry.player.hand.append(quarry.card_catalog["quarry_mark"])
	_check(quarry.play_card(quarry.card_catalog["quarry_mark"]), "Quarry Mark should play.")
	_check(quarry.get_effective_cost(action) == maxi(0, action.cost - 2), "Quarry Mark should discount actions only.")

	var guild := _empty_game()
	guild.player.play_area.assign([guild.card_catalog["grand_bazaar"], guild.card_catalog["gilded_ledger"]])
	_check(guild.get_effective_cost(guild.card_catalog["merchant_guild"]) == 4, "Merchant Guild cost should drop by two per action in play.")

	var granary := _empty_game()
	granary.player.hand.assign([granary.card_catalog["granary_riddle"], granary.card_catalog["pebble_coin"], granary.card_catalog["silver_leaf"]])
	granary.player.draw_pile.assign([granary.card_catalog["homestead"], granary.card_catalog["homestead"]])
	_check(granary.play_card(granary.card_catalog["granary_riddle"]), "Granary Riddle should play.")
	_check(granary.player.hand.size() == 4, "Granary Riddle should draw once per resource revealed in hand.")

	var repeated := _empty_game()
	var repeated_tiara: CardDefinition = repeated.card_catalog["venture_compass"]
	var repeated_collection: CardDefinition = repeated.card_catalog["route_toll"]
	repeated.player.hand = [repeated_tiara, repeated_collection]
	_check(repeated.play_card(repeated_tiara), "Tiara should play for repeated Collection trigger test.")
	_resolve_choice_by_ids(repeated, ["route_toll"])
	var repeated_action: CardDefinition = repeated.card_catalog["gilded_ledger"]
	repeated.market.append(repeated_action)
	repeated.supply_piles[repeated_action.id] = 10
	repeated._gain_card_by_id(repeated_action.id, "discard")
	repeated._process_resolution_queue()
	_resolve_mode(repeated, "leave")
	_check(repeated.player.vp_tokens == 2, "Playing Collection twice should register two gain triggers.")
	repeated._trash_from_play(repeated_collection)
	repeated._gain_card_by_id(repeated_action.id, "discard")
	repeated._process_resolution_queue()
	_resolve_mode(repeated, "leave")
	_check(repeated.player.vp_tokens == 4, "Collection triggers should persist after their source leaves play this turn.")

	var tiara_topdeck := _empty_game()
	var topdeck_tiara: CardDefinition = tiara_topdeck.card_catalog["venture_compass"]
	var topdeck_gain: CardDefinition = tiara_topdeck.card_catalog["gilded_ledger"]
	tiara_topdeck.player.hand = [topdeck_tiara]
	tiara_topdeck.market.append(topdeck_gain)
	tiara_topdeck.supply_piles[topdeck_gain.id] = 10
	_check(tiara_topdeck.play_card(topdeck_tiara), "Tiara should play for its gain-topdeck test.")
	tiara_topdeck._gain_card_by_id(topdeck_gain.id, "discard")
	tiara_topdeck._process_resolution_queue()
	_resolve_mode(tiara_topdeck, "topdeck")
	_check(
		tiara_topdeck.player.draw_pile.has(topdeck_gain)
		and not tiara_topdeck.player.discard_pile.has(topdeck_gain),
		"Tiara should move a gained card from discard onto the deck."
	)


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
		is_equal_approx(game_state.get_end_turn_cooldown_seconds(), 4.0),
		"Sunspire Bell should reduce the multiplayer end-turn cooldown by 1 second this turn."
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
		is_equal_approx(turn_manager.cooldown_remaining, cooldown_before - 1.0),
		"Sunspire Bell should shorten an active cooldown by 1 second."
	)


func _test_multiplayer_only_timer_cards() -> void:
	# The timer cards only appear in multiplayer markets, and their cooldown
	# effects apply per-turn (Bell / Retreat) or per-conquest (Reliquary).
	var solo := _create_game_state()
	if solo == null:
		return
	var solo_ids: Array[String] = []
	for candidate in solo.get_market_candidates():
		solo_ids.append(candidate.id)
	for card_id in MULTIPLAYER_ONLY_CARD_IDS + MULTIPLAYER_ONLY_INTERACTION_CARD_IDS:
		_check(
			not solo_ids.has(card_id),
			"%s should be hidden from singleplayer markets." % card_id
		)

	var mp := GameState.new()
	if not mp.load_cards(CARD_DATA_PATH):
		_check(false, "Card data should load for multiplayer-only cards.")
		return
	mp.setup_starting_game(2)
	var mp_ids: Array[String] = []
	for candidate in mp.get_market_candidates():
		mp_ids.append(candidate.id)
	for card_id in MULTIPLAYER_ONLY_CARD_IDS + MULTIPLAYER_ONLY_INTERACTION_CARD_IDS:
		_check(
			mp_ids.has(card_id),
			"%s should be available as a multiplayer market candidate." % card_id
		)

	# Hourglass Reliquary: a per-conquest reduction that survives a turn reset,
	# and trashes itself when played.
	var relic_state := _empty_game()
	relic_state.multiplayer_enabled = true
	var relic: CardDefinition = relic_state.card_catalog["hourglass_reliquary"]
	relic_state.player.hand.append(relic)
	_check(relic_state.play_card(relic), "Hourglass Reliquary should play.")
	_check(
		relic_state.player.trash_pile.has(relic),
		"Hourglass Reliquary should trash itself when played."
	)
	_check(
		is_equal_approx(relic_state.get_end_turn_cooldown_seconds(), 4.5),
		"Hourglass Reliquary should cut the cooldown by 0.5 seconds."
	)
	relic_state.reset_turn_resources()
	_check(
		is_equal_approx(relic_state.get_end_turn_cooldown_seconds(), 4.5),
		"The conquest cooldown reduction should persist past a turn reset."
	)

	# Twilight Retreat: reduces this turn's cooldown and flags the turn to end.
	var retreat_state := _empty_game()
	retreat_state.multiplayer_enabled = true
	var retreat: CardDefinition = retreat_state.card_catalog["twilight_retreat"]
	retreat_state.player.hand.append(retreat)
	_check(retreat_state.play_card(retreat), "Twilight Retreat should play.")
	_check(
		is_equal_approx(retreat_state.get_end_turn_cooldown_seconds(), 2.0),
		"Twilight Retreat should cut this turn's cooldown by 3 seconds."
	)
	_check(
		retreat_state.consume_end_turn_request(),
		"Twilight Retreat should request that the turn ends."
	)


func _test_turn_phases() -> void:
	# Each turn runs an action phase (only actions play) then a buy phase (only
	# treasures play, purchases allowed). The action phase auto-advances the moment
	# nothing playable remains, and can also be ended manually.
	var game_state := _create_game_state()
	if game_state == null:
		return
	var turn_manager := TurnManager.new()
	turn_manager.configure(game_state)
	turn_manager.start_first_turn()
	# The starting deck holds no action cards, so the action phase auto-advances.
	_check(
		game_state.is_buy_phase(),
		"A turn-start hand with no playable action should open in the buy phase."
	)

	var smithy: CardDefinition = game_state.card_catalog["forge_hall"]
	var coin: CardDefinition = game_state.card_catalog["pebble_coin"]
	game_state.player.hand.assign([smithy, coin])
	game_state.player.actions = 1
	game_state.begin_turn_phase()
	_check(
		game_state.is_action_phase(),
		"A hand with a playable action should open in the action phase."
	)
	_check(
		game_state.can_play_in_current_phase(smithy)
		and not game_state.can_play_in_current_phase(coin),
		"Only actions may be played during the action phase."
	)
	_check(game_state.end_action_phase(), "Ending the action phase should succeed once.")
	_check(
		game_state.is_buy_phase() and not game_state.end_action_phase(),
		"The action phase ends exactly once, switching to the buy phase."
	)
	_check(
		game_state.can_play_in_current_phase(coin)
		and not game_state.can_play_in_current_phase(smithy),
		"Only treasures may be played during the buy phase."
	)

	# With actions but no action cards left, the action phase auto-advances too.
	game_state.player.turn_phase = GameState.TURN_PHASE_ACTION
	game_state.player.hand.assign([coin])
	game_state.player.actions = 1
	game_state.evaluate_auto_phase()
	_check(
		game_state.is_buy_phase(),
		"An action phase with no action cards in hand should auto-advance to buys."
	)


func _test_turn_based_mode() -> void:
	# Turn-based is a no-timer, sequential variation: play passes to the next
	# player once the active player finishes, and no cooldown is ever started.
	var game_state := GameState.new()
	if not game_state.load_cards(CARD_DATA_PATH):
		_check(false, "Card data should load for turn-based mode.")
		return
	if not game_state.setup_starting_game(3):
		_check(false, "A three-player turn-based game should set up.")
		return
	game_state.turn_based_enabled = true
	_check(
		is_equal_approx(game_state.get_end_turn_cooldown_seconds(), 0.0),
		"Turn-based games should have no end-turn cooldown timer."
	)
	var turn_manager := TurnManager.new()
	turn_manager.configure(game_state)
	turn_manager.start_first_turn()
	_check(game_state.active_player_index == 0, "Turn-based play should start with the first player.")
	_finish_turn(turn_manager)
	_check(
		game_state.active_player_index == 1,
		"Finishing a turn should pass play to the next seated player."
	)
	_check(not turn_manager.is_cooling_down(), "Turn-based end turn should never start a cooldown.")
	_check(game_state.player.hand.size() == 5, "The next player should begin with a full hand.")
	_finish_turn(turn_manager)
	_finish_turn(turn_manager)
	_check(
		game_state.active_player_index == 0,
		"Turn-based play should cycle back around the table."
	)

	# A turn-based player's redraw occurs before control advances and must not
	# fire their Clerk reaction. It becomes eligible only when their next turn
	# actually begins.
	var clerk: CardDefinition = game_state.card_catalog["sealed_treaty"]
	game_state.players[0].hand = [clerk]
	game_state.players[0].draw_pile = [clerk]
	game_state.set_active_player_index(0)
	_finish_turn(turn_manager)
	_check(game_state.active_player_index == 1, "Turn-based Clerk deferral should pass to player two.")
	_check(game_state.players[0].pending_choice == null, "A Clerk drawn during pre-turn redraw must wait.")
	_finish_turn(turn_manager)
	_finish_turn(turn_manager)
	_check(game_state.active_player_index == 0 and game_state.has_pending_choice(), "Clerk should react when its owner receives control.")
	_resolve_first_choice(game_state)


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


func _test_prosperity_multiplayer_choices() -> void:
	# Choices for opponent portions are owned by the victim seat and resolve one
	# at a time, while returning control to the attacking player afterward.
	var vault := _empty_multiplayer_game()
	var ledger: CardDefinition = vault.card_catalog["gilded_ledger"]
	vault.players[0].hand = [ledger]
	vault.players[1].hand = [vault.card_catalog["pebble_coin"], vault.card_catalog["silver_leaf"]]
	vault.players[1].draw_pile = [vault.card_catalog["homestead"]]
	vault.set_active_player_index(0)
	_check(vault.play_card(ledger), "Vault should play in multiplayer.")
	_check(vault.has_pending_choice() and vault.pending_choice.resolver == "vault_discard", "Vault should ask for the active discard choice first.")
	_resolve_choice_by_ids(vault, [])
	_check(vault.active_player_index == 1 and vault.has_pending_choice(), "Vault should then hand an opponent choice to the victim seat.")
	_check(vault.pending_choice.resolver == "vault_discard", "Vault victim should choose whether to discard two cards.")
	_resolve_choice_by_ids(vault, [])
	_check(vault.active_player_index == 0, "Vault should return control to the attacking player.")
	_check(vault.players[1].hand.size() == 2, "Declining Vault should leave the opponent hand unchanged.")

	var vault_reward := _empty_multiplayer_game()
	var reward_vault: CardDefinition = vault_reward.card_catalog["gilded_ledger"]
	vault_reward.players[0].hand = [reward_vault]
	vault_reward.players[0].draw_pile = [
		vault_reward.card_catalog["pebble_coin"],
		vault_reward.card_catalog["silver_leaf"],
	]
	vault_reward.players[1].hand = [
		vault_reward.card_catalog["pebble_coin"],
		vault_reward.card_catalog["silver_leaf"],
	]
	vault_reward.players[1].draw_pile = [vault_reward.card_catalog["homestead"]]
	vault_reward.set_active_player_index(0)
	_check(vault_reward.play_card(reward_vault), "Vault should begin its reward path.")
	var owner_coins_before := vault_reward.players[0].coins
	_resolve_choice_by_ids(vault_reward, ["pebble_coin", "silver_leaf"])
	_check(
		vault_reward.players[0].coins == owner_coins_before + 2,
		"Vault owner should gain one coin per discarded card."
	)
	_check(vault_reward.active_player_index == 1 and vault_reward.has_pending_choice(), "Vault should offer the opponent reaction.")
	var opponent_coins_before := vault_reward.players[1].coins
	_resolve_choice_by_ids(vault_reward, ["pebble_coin", "silver_leaf"])
	_check(
		vault_reward.players[1].hand.size() == 1
		and vault_reward.players[1].hand[0].id == "homestead",
		"Vault opponent should discard two cards and draw one."
	)
	_check(
		vault_reward.players[1].coins == opponent_coins_before,
		"Vault opponent should not gain coins for the reaction discard."
	)

	var vault_sequence := GameState.new()
	_check(vault_sequence.load_cards(CARD_DATA_PATH), "Three-player choice test should load card data.")
	_check(vault_sequence.setup_starting_game(3), "A three-player lobby should set up.")
	vault_sequence.start_all_players()
	var sequence_vault: CardDefinition = vault_sequence.card_catalog["gilded_ledger"]
	vault_sequence.players[0].hand = [sequence_vault]
	vault_sequence.players[0].draw_pile = [
		vault_sequence.card_catalog["pebble_coin"],
		vault_sequence.card_catalog["silver_leaf"],
	]
	vault_sequence.players[1].hand = [vault_sequence.card_catalog["pebble_coin"], vault_sequence.card_catalog["silver_leaf"]]
	vault_sequence.players[2].hand = [vault_sequence.card_catalog["pebble_coin"], vault_sequence.card_catalog["silver_leaf"]]
	vault_sequence.set_active_player_index(0)
	_check(vault_sequence.play_card(sequence_vault), "Three-player Vault should play.")
	_resolve_choice_by_ids(vault_sequence, [])
	_check(vault_sequence.active_player_index == 1 and vault_sequence.has_pending_choice(), "First opponent should receive the Vault choice.")
	_resolve_choice_by_ids(vault_sequence, [])
	_check(vault_sequence.active_player_index == 2 and vault_sequence.has_pending_choice(), "Second opponent should receive the Vault choice.")
	_resolve_choice_by_ids(vault_sequence, [])
	_check(vault_sequence.active_player_index == 0, "Three-player opponent choices should restore the original attacker.")

	var bishop := _empty_multiplayer_game()
	var appraiser: CardDefinition = bishop.card_catalog["cairn_appraiser"]
	bishop.players[0].hand = [appraiser]
	bishop.players[1].hand = [bishop.card_catalog["pebble_coin"]]
	bishop.set_active_player_index(0)
	_check(bishop.play_card(appraiser), "Bishop should play with an empty active hand.")
	_check(bishop.active_player_index == 1 and bishop.has_pending_choice(), "Bishop should still ask an opponent when the active hand is empty.")
	_resolve_choice_by_ids(bishop, [])
	_check(bishop.active_player_index == 0, "Bishop should return control after the opponent decision.")
	_check(bishop.players[1].trash_pile.is_empty(), "A declined Bishop victim choice should not trash a card.")

	var bishop_reward := _empty_multiplayer_game()
	var reward_bishop: CardDefinition = bishop_reward.card_catalog["cairn_appraiser"]
	var bishop_target_card: CardDefinition = bishop_reward.card_catalog["silver_leaf"]
	bishop_reward.players[0].hand = [reward_bishop]
	bishop_reward.players[1].hand = [bishop_target_card]
	bishop_reward.set_active_player_index(0)
	_check(bishop_reward.play_card(reward_bishop), "Bishop should begin its opponent reward path.")
	var opponent_vp_before := bishop_reward.players[1].vp_tokens
	_resolve_choice_by_ids(bishop_reward, ["silver_leaf"])
	_check(
		bishop_reward.players[1].trash_pile.has(bishop_target_card),
		"Bishop opponent should trash the selected card."
	)
	_check(
		bishop_reward.players[1].vp_tokens == opponent_vp_before,
		"Bishop opponent should not gain VP for trashing a card."
	)

	var bishop_solo := _empty_game()
	var solo_appraiser: CardDefinition = bishop_solo.card_catalog["cairn_appraiser"]
	var solo_target: CardDefinition = bishop_solo.card_catalog["silver_leaf"]
	bishop_solo.player.hand = [solo_appraiser, solo_target]
	_check(bishop_solo.play_card(solo_appraiser), "Solo Bishop should play.")
	_check(
		bishop_solo.has_pending_choice()
		and str(bishop_solo.pending_choice.context.get("ui_choice_kind", "")) == "trash_from_hand"
		and str(bishop_solo.pending_choice.context.get("ui_source_zone", "")) == "hand",
		"Solo Bishop's required trash should use the direct-hand choice context."
	)
	_resolve_choice_by_ids(bishop_solo, ["silver_leaf"])
	_check(
		not bishop_solo.has_pending_choice(),
		"Solo Bishop should not offer an optional second self-trash."
	)
	_check(bishop_solo.player.trash_pile.has(solo_target), "Solo Bishop should trash the required card.")
	_check(
		bishop_solo.player.vp_tokens == 1 + floori(float(solo_target.cost) / 2.0),
		"Solo Bishop should award VP for the required trash (got %d, expected %d)."
		% [bishop_solo.player.vp_tokens, 1 + floori(float(solo_target.cost) / 2.0)]
	)

	var treaty := _empty_multiplayer_game()
	var treaty_card: CardDefinition = treaty.card_catalog["sealed_treaty"]
	treaty.players[0].hand = [treaty_card]
	for _index in range(5):
		treaty.players[1].hand.append(treaty.card_catalog["pebble_coin"])
	treaty.set_active_player_index(0)
	_check(treaty.play_card(treaty_card), "Sealed Treaty should play in multiplayer.")
	_check(treaty.active_player_index == 1 and treaty.has_pending_choice(), "Sealed Treaty should give each eligible victim a genuine choice.")
	_resolve_first_choice(treaty)
	_check(treaty.active_player_index == 0, "Sealed Treaty should restore the attacker after the victim choice.")

	var war := _empty_multiplayer_game()
	var exchange: CardDefinition = war.card_catalog["royal_exchange"]
	war.players[1].hand = [exchange]
	war.set_active_player_index(1)
	_check(war.play_card(exchange), "War Chest should play in multiplayer.")
	_check(war.active_player_index == 0 and war.has_pending_choice(), "War Chest naming should belong to the player on the left.")
	_resolve_first_choice(war)
	_check(war.active_player_index == 1, "War Chest should return to the exchanger for the gain choice.")

	var war_three := GameState.new()
	_check(war_three.load_cards(CARD_DATA_PATH), "Three-player War Chest test should load card data.")
	_check(war_three.setup_starting_game(3), "A three-player War Chest table should set up.")
	war_three.start_all_players()
	var exchange_three: CardDefinition = war_three.card_catalog["royal_exchange"]
	war_three.players[1].hand = [exchange_three]
	war_three.set_active_player_index(1)
	_check(war_three.play_card(exchange_three), "Three-player War Chest should play.")
	_check(war_three.active_player_index == 2, "War Chest left seat should follow the +1 turn order in three-player games.")
	_resolve_first_choice(war_three)
	_check(war_three.active_player_index == 1, "Three-player War Chest should return to the exchanger.")

	var reductions := _empty_game()
	var quarry: CardDefinition = reductions.card_catalog["quarry_mark"]
	var forge_target: CardDefinition = reductions.card_catalog["ember_forge"]
	reductions.market.append(quarry)
	reductions.market.append(forge_target)
	reductions.supply_piles[forge_target.id] = 10
	reductions.turn_flags["typed_cost_reductions"] = {"action": 2}
	_check(reductions.get_non_buy_cost(forge_target) == forge_target.cost - 2, "Typed Quarry reductions should affect non-buy costs.")
	_check(reductions.get_gain_candidates(forge_target.cost - 2).has(forge_target), "Typed reductions should make reduced-cost gains eligible.")

	var start_reaction := _empty_multiplayer_game()
	var sealed: CardDefinition = start_reaction.card_catalog["sealed_treaty"]
	start_reaction.players[0].hand.clear()
	start_reaction.players[0].draw_pile = [sealed]
	start_reaction.set_active_player_index(0)
	start_reaction.reset_turn_resources()
	start_reaction.draw_cards(1)
	_check(start_reaction.has_pending_choice(), "The turn-start draw should offer a Clerk reaction.")
	_resolve_first_choice(start_reaction)
	start_reaction.player.draw_pile = [sealed]
	start_reaction.draw_cards(1)
	_check(not start_reaction.has_pending_choice(), "Cards drawn after the turn-start reaction window must not become reactions.")

	var parallel_start := GameState.new()
	_check(parallel_start.load_cards(CARD_DATA_PATH), "Parallel Clerk test should load card data.")
	_check(parallel_start.setup_starting_game(2), "Parallel Clerk test should set up two players.")
	for parallel_player in parallel_start.players:
		parallel_player.clear_all()
		parallel_player.draw_pile = [parallel_start.card_catalog["sealed_treaty"]]
	parallel_start.start_all_players()
	_check(
		parallel_start.players[0].pending_choice != null
		and parallel_start.players[1].pending_choice != null,
		"Parallel multiplayer should open each player's first-turn Clerk reaction window."
	)

	# Target-owned gain reactions resolve in order and retain the attack queue:
	# Watchtower may trash the curse before a later Tiara trigger attempts to
	# topdeck it, and that later trigger must not resurrect the trashed card.
	var reaction_order := _empty_multiplayer_game()
	var watchtower: CardDefinition = reaction_order.card_catalog["watchtower_chart"]
	var tiara: CardDefinition = reaction_order.card_catalog["venture_compass"]
	var sable: CardDefinition = reaction_order.card_catalog["sable_loan"]
	reaction_order.players[1].hand = [watchtower, tiara]
	reaction_order.set_active_player_index(1)
	_check(reaction_order.play_card(tiara), "Target Tiara should play before the gain attack.")
	reaction_order.players[0].hand = [sable]
	reaction_order.set_active_player_index(0)
	_check(reaction_order.play_card(sable), "Sable attack should begin the target gain pipeline.")
	_check(reaction_order.active_player_index == 1 and reaction_order.has_pending_choice(), "Target Watchtower should own the first gain reaction.")
	_resolve_mode(reaction_order, "trash")
	_check(reaction_order.active_player_index == 1 and reaction_order.has_pending_choice(), "Later Tiara gain trigger should resolve for the target.")
	_resolve_mode(reaction_order, "topdeck")
	var attacked_card: CardDefinition = reaction_order.card_catalog["briar_hex"]
	_check(reaction_order.active_player_index == 0, "Attack resolution should return to the attacker after target reactions.")
	_check(reaction_order.players[1].trash_pile.has(attacked_card), "Watchtower should trash the target's gained curse.")
	_check(
		not reaction_order.players[1].hand.has(attacked_card)
		and not reaction_order.players[1].discard_pile.has(attacked_card)
		and not reaction_order.players[1].draw_pile.has(attacked_card),
		"A later Tiara trigger must not resurrect a card already trashed by Watchtower."
	)


func _empty_multiplayer_game() -> GameState:
	var game_state := GameState.new()
	_check(game_state.load_cards(CARD_DATA_PATH), "Multiplayer choice test should load card data.")
	_check(game_state.setup_starting_game(2), "Multiplayer choice test should set up two players.")
	game_state.start_all_players()
	return game_state


func _test_network_snapshot_redaction() -> void:
	var game_state := GameState.new()
	_check(game_state.load_cards(CARD_DATA_PATH), "Snapshot redaction test should load card data.")
	_check(game_state.setup_starting_game(3), "Snapshot redaction test should set up three players.")
	var hidden_hand_card: CardDefinition = game_state.card_catalog["pebble_coin"]
	var hidden_deck_card: CardDefinition = game_state.card_catalog["silver_leaf"]
	for index in range(game_state.players.size()):
		game_state.players[index].hand = [hidden_hand_card]
		game_state.players[index].draw_pile = [hidden_deck_card, hidden_hand_card]
	var choice := CardChoice.new()
	choice.id = 77
	choice.prompt = "Choose a hidden card"
	choice.minimum = 1
	choice.maximum = 1
	choice.resolver = "trash_hand"
	choice.add_candidate("hidden:77", hidden_hand_card)
	game_state.players[0].pending_choice = choice
	game_state.players[1].pending_relic_offer = ["dawn_banner"] as Array[String]
	game_state.players[1].pending_relic_replacement = {
		"stage": "draft",
		"replaced_relic_id": "victory_levy",
	}
	var ui = MAIN_UI_SCRIPT.new()
	ui.game_state = game_state
	ui.network_enabled = true
	ui.local_player_index = 1
	var guest_snapshot: Dictionary = ui._create_network_snapshot()
	var host_view: Dictionary = guest_snapshot["players"][0]
	var guest_view: Dictionary = guest_snapshot["players"][1]
	_check(host_view["hand"].is_empty(), "Guests should not receive another player's hand identities.")
	_check(host_view["draw"].is_empty(), "Guests should not receive another player's deck order.")
	_check(host_view["hand_count"] == 1 and host_view["draw_count"] == 2, "Redacted zones should preserve card counts.")
	_check(
		(host_view["pending_choice"] as Dictionary).is_empty(),
		"Guests should not receive another player's pending choice metadata."
	)
	_check(
		(guest_view["hand"] as Array).size() == 1
		and str((guest_view["hand"] as Array)[0]) == "pebble_coin",
		"The owning guest should receive their actionable hand identities."
	)
	_check(
		str((guest_view["relic_replacement"] as Dictionary).get("stage", "")) == "draft"
		and str((guest_view["relic_replacement"] as Dictionary).get("replaced_relic_id", "")) == "victory_levy",
		"Network snapshots should retain the active relic replacement stage."
	)
	ui.free()


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
	var play_records := game_state.player.get_play_display_records()
	_check(play_records.size() == 3, "Echoing Hall should add one record per resolved play.")
	_check(
		play_records[1].get("card") == forge
		and int(play_records[1].get("occurrence", 0)) == 1
		and int(play_records[1].get("total", 0)) == 2,
		"The first replay record should be labelled 1/2."
	)
	_check(
		play_records[2].get("card") == forge
		and int(play_records[2].get("occurrence", 0)) == 2
		and int(play_records[2].get("total", 0)) == 2,
		"The second replay record should be labelled 2/2."
	)
	game_state.begin_cleanup()
	_check(
		game_state.player.get_play_display_records().is_empty(),
		"Cleanup should clear transient play display records."
	)


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
		game_state.get_supply_count("briar_hex")
			== game_state.scale_supply_count(GameState.CURSE_SUPPLY_COUNT) - 1,
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
	_check(
		game_state.player.discard_pile.has(game_state.card_catalog["pebble_coin"])
		and not game_state.player.trash_pile.has(game_state.card_catalog["pebble_coin"]),
		"Spicebroker should discard its chosen resource instead of trashing it."
	)
	_check(
		game_state.pending_choice != null and game_state.pending_choice.candidates.size() == 3,
		"Spicebroker should offer exactly three rewards after the discard."
	)
	_resolve_mode(game_state, "cards")
	_check(game_state.player.hand.size() == 2, "The card mode should draw two cards.")

	game_state = _empty_game()
	spicebroker = game_state.card_catalog["acorn_spicebroker"]
	game_state.player.hand.assign([spicebroker, game_state.card_catalog["pebble_coin"]])
	_check(game_state.play_card(spicebroker), "Spicebroker should play for each reward mode.")
	_resolve_choice_by_ids(game_state, ["pebble_coin"])
	_resolve_mode(game_state, "coins")
	_check(game_state.player.coins == 3, "Spicebroker's third reward should grant three coins.")

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
		== (
			EXPECTED_CARD_COUNT
			- GameState.STARTING_CARD_COUNTS.size()
			- INACTIVE_CARD_IDS.size()
			- MULTIPLAYER_ONLY_CARD_IDS.size()
			- MULTIPLAYER_ONLY_INTERACTION_CARD_IDS.size()
			- ADVENTURES_SUPPORT_CARD_IDS.size()
			- ADVENTURES_EVENT_IDS.size()
		),
		"Solo markets should exclude starter, inactive, and multiplayer-only cards."
	)
	for card_id in INACTIVE_CARD_IDS:
		_check(not first_market.has(card_id), "%s should not appear in the market." % card_id)

	var central_ids: Array[String] = []
	for card in game_state.market:
		if not GameState.MARKET_FIXED_RESOURCE_IDS.has(card.id) and not GameState.MARKET_FIXED_VICTORY_IDS.has(card.id):
			central_ids.append(card.id)
	_check(
		central_ids.size() == GameState.MARKET_CENTRAL_COUNT
		and _unique_string_count(central_ids) == GameState.MARKET_CENTRAL_COUNT,
		"The central market should contain exactly ten unique random cards."
	)
	for central_id in central_ids:
		_check(
			_market_candidates_include_card(game_state, central_id)
			and not GameState.MARKET_FIXED_RESOURCE_IDS.has(central_id)
			and not GameState.MARKET_FIXED_VICTORY_IDS.has(central_id),
			"Central card %s should come from the eligible non-fixed pool." % central_id
		)
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
	game_state.set_kingdom_enabled(GameState.WITCHING_HOUR_GROUP, false)
	game_state.set_kingdom_enabled(GameState.PROSPERITY_GROUP, false)
	game_state.set_kingdom_enabled("Adventures", false)
	_check(
		not game_state.has_enough_market_candidates(),
		"Market setup should know when kingdom filters cannot fill the central row."
	)
	game_state.set_kingdom_enabled(GameState.BEGINNER_KINGDOM, true)
	game_state.set_kingdom_enabled(GameState.HINTERLANDS_GROUP, true)
	game_state.set_kingdom_enabled(GameState.WITCHING_HOUR_GROUP, true)
	game_state.set_kingdom_enabled(GameState.PROSPERITY_GROUP, true)
	game_state.set_kingdom_enabled("Adventures", true)

	_check(game_state.setup_starting_game(), "A second game should set up even when a repeat is allowed.")
	_check(
		game_state.get_market_card_ids().size() == GameState.MARKET_SIZE,
		"A repeated automatic setup should still keep the complete market size."
	)

	# A controlled pool with seven victories, two resources, and one action must
	# still succeed: the central sample has no type/cost/victory quotas.
	var controlled_ten := _build_controlled_market_game(10)
	_check(
		controlled_ten != null and controlled_ten.has_enough_market_candidates(),
		"Exactly ten eligible central cards should be sufficient regardless of type mix."
	)
	if controlled_ten != null:
		_check(
			controlled_ten.setup_starting_game()
			and _central_market_ids(controlled_ten).size() == GameState.MARKET_CENTRAL_COUNT,
			"A ten-card mixed-type pool should produce exactly ten central cards."
		)
	var controlled_nine := _build_controlled_market_game(9)
	_check(
		controlled_nine != null and not controlled_nine.has_enough_market_candidates()
		and not controlled_nine.setup_starting_game(),
		"Nine eligible central cards should fail cleanly rather than inventing a quota fill."
	)


func _test_relic_system() -> void:
	# Draft cadence: every table offers a relic once every 7 turns (turn 8, 15, ...).
	var solo := _empty_game()
	solo.player.turn_number = 3
	solo.maybe_offer_turn_relic(solo.player)
	_check(
		solo.player.pending_relic_offer.is_empty(),
		"No relic offer should appear outside the 7-turn cadence."
	)
	solo.player.turn_number = 8
	solo.maybe_offer_turn_relic(solo.player)
	_check(
		solo.player.pending_relic_offer.size() == 3,
		"A solo relic offer should present 3 relics at turn 8."
	)
	_check(
		not solo.player.pending_relic_offer.has("swift_hourglass"),
		"Untimed games should never offer the cooldown relic."
	)
	_check(
		not solo.choose_relic(solo.player, "not_a_relic"),
		"Choosing a relic outside the offer should be rejected."
	)
	var chosen: String = solo.player.pending_relic_offer[0]
	_check(solo.choose_relic(solo.player, chosen), "Choosing an offered relic should work.")
	_check(
		solo.player.relics.has(chosen) and solo.player.pending_relic_offer.is_empty(),
		"A claimed relic should join the player's relics and clear the offer."
	)
	solo.player.turn_number = 15
	solo.maybe_offer_turn_relic(solo.player)
	_check(solo.choose_relic(solo.player, ""), "Declining a relic offer should be allowed.")
	_check(
		solo.player.pending_relic_offer.is_empty() and solo.player.relics.size() == 1,
		"Declining should clear the offer without claiming a relic."
	)

	# Pilgrim's replacement draft is optional, keeps the old relic until the
	# final pick, and works at the four-relic cap without increasing the count.
	var pilgrim_empty := _empty_game()
	_check(
		not pilgrim_empty.begin_relic_replacement(pilgrim_empty.player),
		"Pilgrim should do nothing when no relic is owned."
	)
	var pilgrim := _empty_game()
	pilgrim.player.relics = ["victory_levy"] as Array[String]
	_check(
		pilgrim.begin_relic_replacement(pilgrim.player)
		and str(pilgrim.player.pending_relic_replacement.get("stage", "")) == "choose_owned",
		"Pilgrim should open a first-stage owned-relic choice."
	)
	_check(
		not pilgrim.choose_relic(pilgrim.player, "not_owned"),
		"Pilgrim should reject an unowned relic in the replacement stage."
	)
	_check(
		pilgrim.choose_relic(pilgrim.player, "victory_levy")
		and str(pilgrim.player.pending_relic_replacement.get("stage", "")) == "draft"
		and pilgrim.player.pending_relic_offer.size() == 3
		and pilgrim.player.relics == (["victory_levy"] as Array[String]),
		"Pilgrim should draft three replacements while retaining the old relic."
	)
	var replacement_pick: String = pilgrim.player.pending_relic_offer[0]
	_check(
		pilgrim.choose_relic(pilgrim.player, replacement_pick)
		and pilgrim.player.relics.size() == 1
		and pilgrim.player.relics.has(replacement_pick)
		and not pilgrim.player.relics.has("victory_levy")
		and pilgrim.player.pending_relic_replacement.is_empty(),
		"Pilgrim should exchange exactly one relic after the drafted pick."
	)
	var pilgrim_decline := _empty_game()
	pilgrim_decline.player.relics = ["victory_levy"] as Array[String]
	pilgrim_decline.begin_relic_replacement(pilgrim_decline.player)
	_check(
		pilgrim_decline.choose_relic(pilgrim_decline.player, "")
		and pilgrim_decline.player.relics == (["victory_levy"] as Array[String]),
		"Declining Pilgrim's first stage should keep the owned relic."
	)
	var pilgrim_cap := _empty_game()
	pilgrim_cap.player.relics = [
		"victory_levy", "seekers_compass", "dawn_banner", "gilded_purse",
	] as Array[String]
	_check(
		pilgrim_cap.begin_relic_replacement(pilgrim_cap.player)
		and pilgrim_cap.choose_relic(pilgrim_cap.player, "gilded_purse")
		and pilgrim_cap.player.pending_relic_offer.size() == 3,
		"Pilgrim should still offer a replacement at the relic cap."
	)
	var cap_replacement_pick: String = pilgrim_cap.player.pending_relic_offer[0]
	_check(
		pilgrim_cap.choose_relic(pilgrim_cap.player, cap_replacement_pick)
		and pilgrim_cap.player.relics.size() == 4,
		"A capped replacement should preserve the relic cap."
	)

	# Timed multiplayer shares the same 7-turn cadence, and its pool may include
	# the cooldown relic (it is the only mode with an end-turn timer).
	var timed := _empty_game()
	timed.multiplayer_enabled = true
	timed.player.turn_number = 6
	timed.maybe_offer_turn_relic(timed.player)
	_check(
		timed.player.pending_relic_offer.is_empty(),
		"No timed relic offer should appear off the 7-turn cadence."
	)
	timed.player.turn_number = 8
	timed.maybe_offer_turn_relic(timed.player)
	_check(
		timed.player.pending_relic_offer.size() == 3,
		"Timed multiplayer should offer relics on the 7-turn cadence."
	)
	timed.player.pending_relic_offer.clear()
	_check(timed.generate_relic_offer(timed.player), "Generating a timed offer should work.")
	timed.player.pending_relic_offer = ["swift_hourglass"] as Array[String]
	_check(
		timed.choose_relic(timed.player, "swift_hourglass"),
		"Claiming the cooldown relic should work in timed games."
	)
	_check(
		is_equal_approx(timed.get_end_turn_cooldown_seconds(), 4.0),
		"Swift Hourglass should cut the end-turn cooldown by 1 second."
	)
	timed.reset_turn_resources()
	_check(
		is_equal_approx(timed.get_end_turn_cooldown_seconds(), 4.0),
		"The Swift Hourglass reduction should persist across turns."
	)
	_check(
		timed.begin_relic_replacement(timed.player)
		and timed.choose_relic(timed.player, "swift_hourglass")
		and timed.player.pending_relic_offer.size() == 3,
		"Swift Hourglass should be eligible for Pilgrim replacement."
	)
	var hourglass_replacement: String = timed.player.pending_relic_offer[0]
	_check(
		timed.choose_relic(timed.player, hourglass_replacement)
		and not timed.player.relics.has("swift_hourglass")
		and is_equal_approx(timed.get_end_turn_cooldown_seconds(), 5.0),
		"Replacing Swift Hourglass should restore the normal end-turn cooldown."
	)

	# Relic cap: a full rail stops producing offers.
	var full := _empty_game()
	full.player.relics = [
		"victory_levy", "seekers_compass", "dawn_banner", "gilded_purse",
	] as Array[String]
	_check(
		not full.generate_relic_offer(full.player),
		"A player at the relic cap should get no further offers."
	)

	# Turn-start bonuses and the extra draw.
	var boons := _empty_game()
	boons.player.relics = ["gilded_purse", "marching_orders", "dawn_banner"] as Array[String]
	boons.reset_turn_resources()
	_check(
		boons.player.coins == 1 and boons.player.actions == 2,
		"Gilded Purse and Marching Orders should grant turn-start bonuses."
	)
	_check(
		boons.get_turn_draw_count(boons.player) == 6,
		"Dawn Banner should raise the turn draw count to 6."
	)

	# Victory Levy: fires once per turn when nothing in hand is playable.
	var levy := _empty_game()
	levy.player.relics = ["victory_levy"] as Array[String]
	levy.player.hand.append(levy.card_catalog["homestead"])
	levy.player.hand.append(levy.card_catalog["homestead"])
	var coins_before: int = levy.player.coins
	levy.check_idle_relics()
	_check(
		levy.player.coins == coins_before + 2,
		"Victory Levy should grant a coin per victory card when stuck."
	)
	levy.check_idle_relics()
	_check(
		levy.player.coins == coins_before + 2,
		"Victory Levy should only trigger once per turn."
	)
	var levy_blocked := _empty_game()
	levy_blocked.player.relics = ["victory_levy"] as Array[String]
	levy_blocked.player.hand.append(levy_blocked.card_catalog["homestead"])
	levy_blocked.player.hand.append(levy_blocked.card_catalog["pebble_coin"])
	levy_blocked.check_idle_relics()
	_check(
		levy_blocked.player.coins == 0,
		"Victory Levy should stay quiet while a resource is still playable."
	)

	# Seeker's Compass: a shuffle during drawing pauses for a pre-draw pick.
	var compass := _empty_game()
	compass.player.relics = ["seekers_compass"] as Array[String]
	for _index in range(4):
		compass.player.discard_pile.append(compass.card_catalog["pebble_coin"])
	compass.player.discard_pile.append(compass.card_catalog["homestead"])
	compass.draw_cards(3)
	_check(
		compass.has_pending_choice()
		and compass.pending_choice.resolver == "relic_predraw",
		"Seeker's Compass should pause a shuffle-draw with a pre-draw choice."
	)
	if compass.has_pending_choice():
		var predraw_token: Array[String] = [
			str(compass.pending_choice.candidates[0]["token"]),
		]
		_check(
			compass.resolve_choice(predraw_token),
			"The Seeker's Compass pick should resolve."
		)
		_check(
			compass.player.hand.size() == 3,
			"The compass pick plus remaining draws should fill the requested hand."
		)


func _test_witching_hour_expansion() -> void:
	_test_duration_cards()
	_test_sowing_moon()
	_test_hex_economy()
	_test_trash_synergies()
	_test_attack_immunity()
	_test_relic_tempo_cards()
	_test_new_relic_boons()


func _test_duration_cards() -> void:
	var game_state := _empty_game()
	var caravan: CardDefinition = game_state.card_catalog["moonlit_caravan"]
	game_state.player.hand.append(caravan)
	for _index in range(6):
		game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(caravan), "Moonlit Caravan should play.")
	_check(game_state.player.coins == 1, "Moonlit Caravan should grant a coin on play.")
	_check(game_state.player.hand.size() == 1, "Moonlit Caravan should draw on play.")
	game_state.begin_cleanup()
	_check(
		game_state.player.play_area.has(caravan),
		"A duration card should stay in play through cleanup."
	)
	_check(game_state.player.hand.is_empty(), "Cleanup should still discard the hand.")
	game_state.reset_turn_resources()
	_check(
		game_state.player.coins == 1,
		"Moonlit Caravan should grant a coin at the next turn start."
	)
	_check(
		game_state.player.hand.size() == 1,
		"Moonlit Caravan should draw a card at the next turn start."
	)
	game_state.begin_cleanup()
	_check(
		not game_state.player.play_area.has(caravan),
		"A spent duration card should leave play at the following cleanup."
	)
	_check(
		game_state.player.discard_pile.has(caravan),
		"A spent duration card should be discarded normally."
	)

	var causeway_game := _empty_game()
	var causeway: CardDefinition = causeway_game.card_catalog["long_causeway"]
	var silver: CardDefinition = causeway_game.card_catalog["silver_leaf"]
	causeway_game.player.hand.append(causeway)
	_check(causeway_game.play_card(causeway), "Long Causeway should play.")
	_check(
		causeway_game.player.buys == 2 and causeway_game.player.coins == 1,
		"Long Causeway should grant a buy and a coin on play."
	)
	causeway_game.begin_cleanup()
	causeway_game.reset_turn_resources()
	_check(
		causeway_game.get_effective_cost(silver) == silver.cost - 1,
		"Long Causeway should reduce costs at the next turn start."
	)


func _test_sowing_moon() -> void:
	var game_state := _empty_game()
	var moon: CardDefinition = game_state.card_catalog["sowing_moon"]
	var keepsake: CardDefinition = game_state.card_catalog["briar_gate"]
	game_state.player.hand.assign([moon, keepsake])
	game_state.player.draw_pile.append(game_state.card_catalog["pebble_coin"])
	_check(game_state.play_card(moon), "Sowing Moon should play.")
	_check(game_state.has_pending_choice(), "Sowing Moon should offer a set-aside choice.")
	_resolve_choice_by_ids(game_state, ["briar_gate"])
	_check(
		game_state.player.set_aside_pile.has(keepsake),
		"Sowing Moon should set the chosen card aside."
	)
	game_state.begin_cleanup()
	_check(
		game_state.player.set_aside_pile.has(keepsake),
		"Set-aside cards should survive cleanup."
	)
	game_state.reset_turn_resources()
	_check(
		game_state.player.hand.has(keepsake),
		"Sowing Moon should return the set-aside card next turn."
	)
	_check(
		game_state.player.set_aside_pile.is_empty(),
		"The set-aside pile should empty after returning cards."
	)


func _test_hex_economy() -> void:
	var bargain_game := _empty_game()
	var bargain: CardDefinition = bargain_game.card_catalog["witchs_bargain"]
	var hex: CardDefinition = bargain_game.card_catalog["briar_hex"]
	bargain_game.player.hand.append(bargain)
	_check(bargain_game.play_card(bargain), "Witch's Bargain should play.")
	_check(bargain_game.player.coins == 3, "Witch's Bargain should grant 3 coins.")
	_check(bargain_game.player.hand.has(hex), "Witch's Bargain should gain a hex to hand.")

	var eater_game := _empty_game()
	var eater: CardDefinition = eater_game.card_catalog["hex_eater"]
	eater_game.player.hand.assign([eater, hex, hex])
	for _index in range(4):
		eater_game.player.draw_pile.append(eater_game.card_catalog["pebble_coin"])
	_check(eater_game.play_card(eater), "Hex Eater should play.")
	_check(eater_game.has_pending_choice(), "Hex Eater should offer a hex trash choice.")
	_check(
		str(eater_game.pending_choice.context.get("ui_choice_kind", "")) == "trash_from_hand"
		and str(eater_game.pending_choice.context.get("ui_source_zone", "")) == "hand",
		"Hand-trash choices should expose their UI intent explicitly."
	)
	_resolve_choice_by_ids(eater_game, ["briar_hex", "briar_hex"])
	_check(
		eater_game.player.trash_pile.size() == 2,
		"Hex Eater should trash the chosen hexes."
	)
	_check(eater_game.player.coins == 2, "Hex Eater should grant a coin per trashed hex.")

	var mill_game := _empty_game()
	var mill: CardDefinition = mill_game.card_catalog["hex_mill"]
	mill_game.player.hand.assign([mill, hex])
	mill_game.player.draw_pile.append(mill_game.card_catalog["pebble_coin"])
	_check(mill_game.play_card(mill), "Hex Mill should play.")
	_resolve_choice_by_ids(mill_game, ["briar_hex"])
	_check(mill_game.player.coins == 2, "Hex Mill should pay for the discarded hex.")
	_check(mill_game.player.discard_pile.has(hex), "Hex Mill should discard the hex.")

	var gain_choice_game := _empty_game()
	_set_test_market(gain_choice_game, ["forge_hall"])
	gain_choice_game._request_filtered_supply_choice({}, "hand", "Gain a card to your hand.")
	_check(
		gain_choice_game.has_pending_choice()
		and str(gain_choice_game.pending_choice.context.get("ui_choice_kind", "")) == "gain_from_supply"
		and str(gain_choice_game.pending_choice.context.get("ui_source_zone", "")) == "supply"
		and str(gain_choice_game.pending_choice.context.get("destination", "")) == "hand",
		"Supply-gain choices should expose their source and destination for direct market UI."
	)

	var ingot_game := _empty_game()
	var ingot_hex: CardDefinition = ingot_game.card_catalog["briar_hex"]
	ingot_game._gain_card_by_id("cursed_ingot", "discard")
	ingot_game._process_resolution_queue()
	_check(
		ingot_game.player.discard_pile.has(ingot_game.card_catalog["cursed_ingot"])
		and ingot_game.player.discard_pile.has(ingot_hex),
		"Gaining a Cursed Ingot should also gain a Briar Hex."
	)

	var idol_game := _empty_game()
	idol_game.player.draw_pile.append(idol_game.card_catalog["bramble_idol"])
	idol_game.player.draw_pile.append(hex)
	idol_game.player.draw_pile.append(hex)
	_check(
		idol_game.calculate_score() == 1,
		"Bramble Idol should score 1 VP per owned hex against the hex penalty."
	)

	var binder_game := _empty_game()
	var binder: CardDefinition = binder_game.card_catalog["thornbinder"]
	binder_game.player.hand.assign([binder, hex])
	_check(binder_game.play_card(binder), "Thornbinder should play.")
	_resolve_choice_by_ids(binder_game, ["briar_hex"])
	_check(
		binder_game.player.coins == 4,
		"Thornbinder should pay 2 extra coins for the trashed hex."
	)


func _test_trash_synergies() -> void:
	var cart_game := _empty_game()
	var cart: CardDefinition = cart_game.card_catalog["bone_cart"]
	var silver: CardDefinition = cart_game.card_catalog["silver_leaf"]
	cart_game.player.trash_pile.append(silver)
	cart_game.player.hand.append(cart)
	_check(cart_game.play_card(cart), "Bone Cart should play.")
	_check(cart_game.has_pending_choice(), "Bone Cart should offer a reclaim choice.")
	_resolve_choice_by_ids(cart_game, ["silver_leaf"])
	_check(
		cart_game.player.discard_pile.has(silver) and cart_game.player.trash_pile.is_empty(),
		"Bone Cart should move the reclaimed card to the discard pile."
	)

	var crow_game := _empty_game()
	var crow: CardDefinition = crow_game.card_catalog["bonepicker_crow"]
	for _index in range(5):
		crow_game.player.trash_pile.append(crow_game.card_catalog["pebble_coin"])
	crow_game.player.hand.append(crow)
	crow_game.player.draw_pile.append(crow_game.card_catalog["pebble_coin"])
	_check(crow_game.play_card(crow), "Bonepicker Crow should play.")
	_check(
		crow_game.player.coins == 2,
		"Bonepicker Crow should pay out with a full trash pile."
	)

	var quiet_crow_game := _empty_game()
	var quiet_crow: CardDefinition = quiet_crow_game.card_catalog["bonepicker_crow"]
	quiet_crow_game.player.hand.append(quiet_crow)
	quiet_crow_game.player.draw_pile.append(quiet_crow_game.card_catalog["pebble_coin"])
	_check(quiet_crow_game.play_card(quiet_crow), "Bonepicker Crow should still play.")
	_check(
		quiet_crow_game.player.coins == 0,
		"Bonepicker Crow should stay quiet below the trash threshold."
	)

	var shrine_game := _empty_game()
	shrine_game.player.draw_pile.append(shrine_game.card_catalog["moth_shrine"])
	for _index in range(8):
		shrine_game.player.trash_pile.append(shrine_game.card_catalog["pebble_coin"])
	_check(
		shrine_game.calculate_score() == 3,
		"Moth Shrine should score 1 VP plus 1 per 4 trashed cards."
	)


func _test_attack_immunity() -> void:
	var game_state := _create_game_state()
	if game_state == null:
		return
	game_state.setup_starting_game(2)
	var defender: PlayerState = game_state.players[1]
	var witch: CardDefinition = game_state.card_catalog["briar_witch"]
	var hex: CardDefinition = game_state.card_catalog["briar_hex"]

	defender.hand.append(game_state.card_catalog["hedgewarden"])
	game_state.player.hand.append(witch)
	game_state.player.actions = 5
	_check(game_state.play_card(witch), "Briar Witch should play against a warded rival.")
	_check(
		not defender.discard_pile.has(hex),
		"Hedgewarden in hand should block the curse attack."
	)

	defender.hand.clear()
	defender.play_area.append(game_state.card_catalog["fen_lighthouse"])
	game_state.player.hand.append(witch)
	_check(game_state.play_card(witch), "Briar Witch should play against the lighthouse.")
	_check(
		not defender.discard_pile.has(hex),
		"Fen Lighthouse in play should block the curse attack."
	)

	defender.play_area.clear()
	game_state.player.hand.append(witch)
	_check(game_state.play_card(witch), "Briar Witch should play against an open rival.")
	_check(
		defender.discard_pile.has(hex),
		"An unprotected rival should gain the curse."
	)


func _test_relic_tempo_cards() -> void:
	var key_game := _empty_game()
	var key: CardDefinition = key_game.card_catalog["reliquary_key"]
	key_game.player.relics = ["dawn_banner", "gilded_purse"] as Array[String]
	key_game.player.hand.append(key)
	for _index in range(4):
		key_game.player.draw_pile.append(key_game.card_catalog["pebble_coin"])
	_check(key_game.play_card(key), "Reliquary Key should play.")
	_check(
		key_game.player.hand.size() == 2,
		"Reliquary Key should draw one card per held relic."
	)

	var stone_game := _empty_game()
	var stone: CardDefinition = stone_game.card_catalog["pilgrim_stone"]
	stone_game.player.relics = ["dawn_banner"] as Array[String]
	stone_game.player.hand.append(stone)
	_check(stone_game.play_card(stone), "Pilgrim Stone should play.")
	_check(stone_game.player.trash_pile.has(stone), "Pilgrim Stone should trash itself.")
	_check(
		str(stone_game.player.pending_relic_replacement.get("stage", "")) == "choose_owned",
		"Pilgrim Stone should open the owned-relic replacement stage."
	)
	_check(
		stone_game.choose_relic(stone_game.player, "dawn_banner")
		and stone_game.player.pending_relic_offer.size() == 3,
		"Pilgrim Stone should open a replacement relic draft after the owned pick."
	)

	var minute_game := _create_game_state()
	if minute_game == null:
		return
	minute_game.setup_starting_game(2)
	var minute: CardDefinition = minute_game.card_catalog["stolen_minute"]
	minute_game.player.hand.append(minute)
	_check(minute_game.play_card(minute), "Stolen Minute should play.")
	_check(
		is_equal_approx(minute_game.players[1].end_turn_cooldown_reduction, -2.0),
		"Stolen Minute should lengthen the rival end-turn cooldown."
	)

	var vigil_game := _empty_game()
	var vigil: CardDefinition = vigil_game.card_catalog["lantern_vigil"]
	vigil_game.player.hand.append(vigil)
	_check(vigil_game.play_card(vigil), "Lantern Vigil should play.")
	vigil_game.begin_cleanup()
	vigil_game.reset_turn_resources()
	_check(
		is_equal_approx(vigil_game.player.end_turn_cooldown_reduction, 2.0),
		"Lantern Vigil should pre-pay a cooldown reduction next turn."
	)


func _test_new_relic_boons() -> void:
	# Sunflower Metronome grants one action at every turn start.
	var metronome := _empty_game()
	metronome.player.relics = ["sunflower_metronome"] as Array[String]
	metronome.reset_turn_resources()
	_check(
		metronome.player.actions == 2,
		"Sunflower Metronome should grant an action at turn start."
	)

	# Thumbed Ledger grants two coins on the first buy.
	var ledger := _create_game_state()
	if ledger == null:
		return
	ledger.player.relics = ["thumbed_ledger"] as Array[String]
	var bought: CardDefinition = ledger.market[0]
	ledger.player.coins = ledger.get_effective_cost(bought)
	_check(ledger.buy_card(bought), "A ledger buy should work.")
	_check(ledger.player.coins == 2, "Thumbed Ledger should grant 2 coins on the first buy.")

	# Market Writ grants an additional buy at every turn start.
	var writ := _empty_game()
	writ.player.relics = ["market_writ"] as Array[String]
	writ.reset_turn_resources()
	_check(writ.player.buys == 2, "Market Writ should grant a buy at turn start.")

	# Culling Reliquary drafts now, then resolves at the next turn start.
	var culling := _empty_game()
	culling.player.pending_relic_offer = ["culling_reliquary"] as Array[String]
	_check(culling.choose_relic(culling.player, "culling_reliquary"), "Culling Reliquary should be claimable.")
	culling.player.draw_pile.assign([
		culling.card_catalog["pebble_coin"],
		culling.card_catalog["homestead"],
		culling.card_catalog["pebble_coin"],
		culling.card_catalog["homestead"],
		culling.card_catalog["pebble_coin"],
		culling.card_catalog["homestead"],
	])
	culling.reset_turn_resources()
	_check(culling.has_pending_choice(), "Culling Reliquary should ask for a next-turn trash choice.")
	_check(culling.player.hand.size() == 6, "Culling Reliquary should draw the full deck.")
	_resolve_choice_by_ids(culling, ["pebble_coin", "homestead"])
	_check(culling.player.trash_pile.size() == 2, "Culling Reliquary should trash the selected cards.")

	# Ashen Urn pays a coin per trashed card.
	var urn := _empty_game()
	urn.player.relics = ["ashen_urn"] as Array[String]
	urn.player.hand.append(urn.card_catalog["quiet_chapel"])
	urn.player.hand.append(urn.card_catalog["pebble_coin"])
	urn.player.hand.append(urn.card_catalog["pebble_coin"])
	_check(urn.play_card(urn.card_catalog["quiet_chapel"]), "Archive Purge should play.")
	_resolve_choice_by_ids(urn, ["pebble_coin", "pebble_coin"])
	_check(urn.player.coins == 2, "Ashen Urn should grant a coin per trashed card.")

	# Trickster's Die discounts one random market pile each turn.
	var die := _create_game_state()
	if die == null:
		return
	die.player.relics = ["tricksters_die"] as Array[String]
	die.reset_turn_resources()
	var discount_id := str(die.turn_flags.get("die_discount_card_id", ""))
	_check(not discount_id.is_empty(), "Trickster's Die should pick a market pile.")
	if not discount_id.is_empty():
		var discounted: CardDefinition = die.card_catalog[discount_id]
		_check(
			die.get_effective_cost(discounted) == maxi(0, discounted.cost - 1),
			"Trickster's Die should shave 1 coin off its pile."
		)

	# Moonwake Mirror doubles duration payloads.
	var mirror := _empty_game()
	mirror.player.relics = ["moonwake_mirror"] as Array[String]
	mirror.player.hand.append(mirror.card_catalog["merchant_barge"])
	_check(
		mirror.play_card(mirror.card_catalog["merchant_barge"]),
		"Merchant Barge should play."
	)
	mirror.begin_cleanup()
	mirror.reset_turn_resources()
	_check(
		mirror.player.coins == 4,
		"Moonwake Mirror should double the duration coins."
	)

	# Patient Spider widens relic drafts to 4 options.
	var spider := _empty_game()
	spider.player.relics = ["patient_spider"] as Array[String]
	_check(spider.generate_relic_offer(spider.player), "A spider draft should generate.")
	_check(
		spider.player.pending_relic_offer.size() == 4,
		"Patient Spider should offer 4 relic choices."
	)

	# Hex Ward deflects the first curse gained each turn into the trash.
	var ward := _empty_game()
	ward.player.relics = ["hex_ward"] as Array[String]
	var hex: CardDefinition = ward.card_catalog["briar_hex"]
	ward._gain_card_by_id("briar_hex", "discard")
	_check(
		ward.player.trash_pile.has(hex) and not ward.player.discard_pile.has(hex),
		"Hex Ward should trash the first gained hex."
	)
	ward._gain_card_by_id("briar_hex", "discard")
	_check(
		ward.player.discard_pile.has(hex),
		"Hex Ward should only deflect one hex per turn."
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


func _build_controlled_market_game(candidate_count: int) -> GameState:
	var game_state := GameState.new()
	if not game_state.load_cards(CARD_DATA_PATH):
		return null
	var source_catalog := game_state.card_catalog.duplicate()
	game_state.card_catalog.clear()
	for card_id in [
		"pebble_coin",
		"homestead",
		"silver_leaf",
		"amber_circlet",
		"briar_gate",
		"royal_charter",
		"briar_hex",
	]:
		game_state.card_catalog[card_id] = source_catalog[card_id]
	for index in range(candidate_count):
		var card_type := "victory" if index < 7 else "resource" if index < 9 else "action"
		var card := CardDefinition.from_dict({
			"id": "controlled_%02d" % index,
			"name": "Controlled %02d" % index,
			"type": card_type,
			"cost": 1 + index,
			"description": "A controlled market sample card.",
			"market_enabled": true,
		})
		game_state.card_catalog[card.id] = card
	return game_state


func _central_market_ids(game_state: GameState) -> Array[String]:
	var central_ids: Array[String] = []
	for card in game_state.market:
		if GameState.MARKET_FIXED_RESOURCE_IDS.has(card.id) or GameState.MARKET_FIXED_VICTORY_IDS.has(card.id):
			continue
		central_ids.append(card.id)
	return central_ids


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


func _unique_string_count(values: Array[String]) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[value] = true
	return unique.size()


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error("[Test] %s" % message)
