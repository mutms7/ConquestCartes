extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failure_count := 0
var main_ui: Control


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	main_ui = MAIN_SCENE.instantiate()
	root.add_child(main_ui)
	await process_frame

	_check(_home_overlay().visible, "Startup should open on the home screen.")
	_check(_home_art().texture != null, "Home screen should use uploaded card artwork.")
	_check(
		_home_set_label().text == GameState.HINTERLANDS_GROUP.to_upper(),
		"Home screen should name the active Hinterlands card group."
	)
	_check(_home_continue_button().disabled, "Continue should be disabled before a game starts.")
	_home_settings_button().pressed.emit()
	await process_frame
	_check(_home_settings_panel().visible, "Settings should open from the home menu.")
	_check(_home_audio_toggle().button_pressed, "Audio should default to enabled.")
	_home_motion_toggle().set_pressed_no_signal(false)
	_home_motion_toggle().toggled.emit(false)
	_check(not main_ui.motion_enabled, "Motion toggle should update the UI setting.")
	_home_motion_toggle().set_pressed_no_signal(true)
	_home_motion_toggle().toggled.emit(true)
	_home_noise_slider().set_value_no_signal(0.24)
	_home_noise_slider().value_changed.emit(0.24)
	_check(
		is_equal_approx(main_ui.home_noise_amount, 0.24)
		and is_equal_approx(_home_noise_overlay().modulate.a, 0.24),
		"Home noise slider should control the home noise overlay."
	)
	_check(
		_home_noise_overlay().stretch_mode == TextureRect.STRETCH_TILE,
		"Home noise should tile instead of stretching."
	)
	_table_noise_slider().set_value_no_signal(0.12)
	_table_noise_slider().value_changed.emit(0.12)
	_check(
		is_equal_approx(main_ui.table_noise_amount, 0.12)
		and is_equal_approx(_table_noise_overlay().modulate.a, 0.12),
		"Table noise slider should control the in-game table noise overlay."
	)
	_check(
		_table_noise_overlay().stretch_mode == TextureRect.STRETCH_TILE,
		"Table noise should tile instead of stretching."
	)
	_action_speed_slider().set_value_no_signal(2.0)
	_action_speed_slider().value_changed.emit(2.0)
	_check(
		is_equal_approx(main_ui.action_animation_speed, 2.0)
		and is_equal_approx(main_ui._action_animation_duration(0.2), 0.1),
		"Action speed slider should affect action animation durations."
	)
	_home_kingdoms_button().pressed.emit()
	await process_frame
	_check(
		_home_kingdoms_panel().visible and not _home_settings_panel().visible,
		"Kingdoms should open as its own home tab."
	)
	_check(
		_kingdom_tabs().get_child_count() == GameState.KINGDOM_ORDER.size()
		and _kingdom_card_grid().get_child_count() > 0
		and _kingdom_detail_host().get_child_count() > 0,
		"Kingdoms should open a tabbed card browser with a detail pane."
	)
	_check(_kingdom_toggle(GameState.BASE_KINGDOM).disabled, "Base Kingdom should stay required.")
	_kingdom_card_button("silver_leaf").pressed.emit()
	await process_frame
	_check(
		_kingdom_detail_card("silver_leaf") != null
		and _kingdom_detail_toggle().disabled,
		"Necessary economy cards should be viewable but not removable."
	)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).set_pressed_no_signal(false)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).toggled.emit(false)
	_check(
		not main_ui.game_state.is_kingdom_enabled(GameState.HINTERLANDS_GROUP)
		and not _market_candidates_include_kingdom(GameState.HINTERLANDS_GROUP),
		"Turning off Hinterlands should remove that kingdom from the market pool."
	)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).set_pressed_no_signal(true)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).toggled.emit(true)
	_kingdom_tab(GameState.HINTERLANDS_GROUP).pressed.emit()
	await process_frame
	_check(
		_kingdom_detail_card("briar_passage") != null
		or _kingdom_detail_host().get_child_count() > 0,
		"Hinterlands tab should show real card faces in the browser."
	)
	_kingdom_card_button("river_magistrate").set_pressed_no_signal(false)
	_kingdom_card_button("river_magistrate").toggled.emit(false)
	_check(
		not main_ui.game_state.is_card_enabled_for_market("river_magistrate")
		and not _market_candidates_include_card("river_magistrate"),
		"Individual card toggles should remove one card from market draw."
	)
	_kingdom_card_button("river_magistrate").set_pressed_no_signal(true)
	_kingdom_card_button("river_magistrate").toggled.emit(true)
	_kingdom_toggle(GameState.BEGINNER_KINGDOM).set_pressed_no_signal(false)
	_kingdom_toggle(GameState.BEGINNER_KINGDOM).toggled.emit(false)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).set_pressed_no_signal(false)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).toggled.emit(false)
	_check(_home_new_game_button().disabled, "New Game should lock when filters cannot fill a market.")
	_kingdom_toggle(GameState.BEGINNER_KINGDOM).set_pressed_no_signal(true)
	_kingdom_toggle(GameState.BEGINNER_KINGDOM).toggled.emit(true)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).set_pressed_no_signal(true)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).toggled.emit(true)
	_home_new_game_button().pressed.emit()
	await process_frame
	await process_frame
	_check(not _home_overlay().visible, "New Game should leave the home screen.")
	_check(main_ui.has_active_game, "Starting from the home menu should create an active game.")

	_check(_hand_container().get_child_count() == 5, "Initial hand should render five cards.")
	_check(
		_all_market_buttons().size() == GameState.MARKET_SIZE,
		"Market should render the configured number of randomly selected cards."
	)
	_check(
		_treasury_cards().get_child_count() == GameState.MARKET_RESOURCE_COUNT,
		"The left market column should render two resource piles."
	)
	_check(
		_barracks_cards().get_child_count() == GameState.MARKET_ACTION_COUNT,
		"The center market grid should render ten action piles."
	)
	_check(
		_estates_cards().get_child_count() == GameState.MARKET_VICTORY_TOTAL,
		"The right market column should render two victory piles."
	)
	_check(
		_container_has_type(_treasury_cards(), "resource")
		and _container_has_type(_barracks_cards(), "action")
		and _container_has_type(_estates_cards(), "victory"),
		"Market cards should be routed to carpets by their data-driven card type."
	)
	_check(
		_treasury_cards().columns == 1
		and _barracks_cards().columns == 5
		and _estates_cards().columns == 1,
		"Market carpets should use the requested 2x1, 2x5, and 2x1 grids."
	)
	_check(
		_costs_descend_in_child_order(_treasury_cards())
		and _costs_descend_in_child_order(_estates_cards()),
		"Resource and victory piles should run from most expensive at the top to cheapest below."
	)
	_check(
		_barracks_follows_cost_path(),
		"Action piles should descend from top-right to top-left, then bottom-right to bottom-left."
	)
	_check(
		_market_scroll().horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		and _market_scroll().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"The complete market should fit without scrolling."
	)
	_check(
		_market_container().find_child("Title", true, false) == null
		and _market_container().find_child("Subtitle", true, false) == null,
		"The art-first market should not reserve space for section titles."
	)
	_check(_play_area_container().get_child_count() == 1, "Empty play area should show its hint.")
	_check(main_ui.title_font != null, "Imported title font should load.")
	_check(main_ui.body_font != null, "Imported body font should load.")
	_check(main_ui.body_bold_font != null, "Imported bold effect font should load.")
	_check(main_ui.ui_textures.size() == 8, "All original medieval UI textures should load.")
	_check(_hud_icon("CoinStat").texture != null, "Coin HUD icon should load.")
	_check(_hud_icon("ActionStat").texture != null, "Action HUD icon should load.")
	_check(_hud_icon("BuyStat").texture != null, "Buy HUD icon should load.")
	_check(main_ui.ui_sound_players.size() == 8, "All configured UI sounds should load.")
	_check(
		not main_ui.has_node("Margin/Layout/StatusPanel"),
		"The obsolete persistent status panel should not exist."
	)
	_check(
		main_ui.COLOR_RESOURCE_CARD != main_ui.COLOR_ACTION_CARD
		and main_ui.COLOR_ACTION_CARD != main_ui.COLOR_VICTORY_CARD
		and main_ui.COLOR_RESOURCE_CARD != main_ui.COLOR_VICTORY_CARD,
		"Each card type should have a distinct dark medieval surface color."
	)
	_check(
		_color_distance(main_ui.COLOR_RESOURCE_CARD, main_ui.COLOR_ACTION_CARD) > 0.22
		and _color_distance(main_ui.COLOR_ACTION_CARD, main_ui.COLOR_VICTORY_CARD) > 0.16
		and _color_distance(main_ui.COLOR_RESOURCE_CARD, main_ui.COLOR_VICTORY_CARD) > 0.16,
		"Card type surfaces should be visibly different rather than near-identical browns."
	)
	_check(
		main_ui._get_card_type_accent("resource") != main_ui._get_card_type_accent("action")
		and main_ui._get_card_type_accent("action")
		!= main_ui._get_card_type_accent("victory"),
		"Each card type should also have a distinct bright inner accent."
	)
	_check(
		_hand_panel().get_global_rect().end.y <= root.get_visible_rect().end.y,
		"The full hand panel should remain inside the 1280x720 viewport."
	)
	_check(
		_market_panel().get_global_rect().end.y <= root.get_visible_rect().end.y,
		"The complete art-first market should remain inside the viewport."
	)
	_check(
		_children_fit_parent(_treasury_cards())
		and _children_fit_parent(_barracks_cards())
		and _children_fit_parent(_estates_cards()),
		"Every market card should remain inside its assigned carpet."
	)
	_check(
		main_ui.left_ledger.get_global_rect().end.x
		<= _hand_panel().get_global_rect().position.x
		and main_ui.right_ledger.get_global_rect().position.x
		>= _hand_panel().get_global_rect().end.x,
		"Persistent game details should occupy the lower sides of the hand."
	)
	_check(
		main_ui.left_ledger.get_global_rect().position.x >= 0.0
		and main_ui.right_ledger.get_global_rect().end.x <= root.get_visible_rect().end.x
		and main_ui.right_ledger.get_global_rect().end.y <= root.get_visible_rect().end.y,
		"Both lower docks should remain inside the 1280x720 viewport."
	)
	_check(
		main_ui.left_ledger.get_global_rect().position.y
		>= _play_area_container().get_global_rect().end.y
		and main_ui.right_ledger.get_global_rect().position.y
		>= _play_area_container().get_global_rect().end.y,
		"The side docks should sit below the market and played-card strip."
	)

	var resource_button := _find_card_button(_hand_container(), "pebble_coin")
	_check(resource_button != null, "A Pebble Coin button should render in hand.")
	if resource_button != null:
		_check(not resource_button.disabled, "A resource card should be visibly playable.")
		_check(
			resource_button.get_meta("card_base_color") == main_ui.COLOR_RESOURCE_CARD,
			"Resource cards should use the warm umber surface."
		)
		_check(
			resource_button.get_meta("card_accent_color")
			== main_ui._get_card_palette("hand_playable").border,
			"Playable hand cards should use the slate accent."
		)
		var normal_style := resource_button.get_theme_stylebox("normal") as StyleBoxFlat
		_check(
			normal_style != null and normal_style.border_width_left >= 4,
			"Card outlines should remain thick and obvious in their normal state."
		)
		_check(
			resource_button.has_node("MedievalFrame"),
			"Card faces should include the original medieval frame ornament."
		)
		_check(_card_art(resource_button).texture != null, "Card faces should display card artwork.")
		_check(
			_card_effect(resource_button).get_parsed_text()
			== _plain_card_rules_text(
				main_ui.game_state.card_catalog["pebble_coin"].description
			),
			"Card faces should show the formatted rules description."
		)
		_check(
			main_ui._get_card_rules_text("Gain 1 buy and 2 coins.")
			== "[b]+1 buy[/b] and [b]+2 coins[/b].",
			"Numeric gain text should render as bold shorthand."
		)
		_check(
			_card_name(resource_button).get_theme_font_size("font_size") >= 15
			and _card_effect(resource_button).get_theme_font_size("normal_font_size") >= 12,
			"Hand card titles and rules text should use the enlarged type."
		)
		_check(
			resource_button.custom_minimum_size == main_ui.CARD_FACE_SIZE
			and _all_market_buttons()[0].custom_minimum_size == main_ui.CARD_FACE_SIZE,
			"Hand and market cards should use the same face dimensions."
		)
		_check(
			_card_price(resource_button).text
			== str(main_ui.game_state.get_effective_cost(
				main_ui.game_state.card_catalog["pebble_coin"]
			)),
			"Card prices should appear in the upper-left coin badge."
		)
		_check(
			_card_price(resource_button).get_theme_font("font") == main_ui.title_font,
			"Card price numbers should use the fancy title font."
		)
		_check(
			_card_text_layout_is_clear(resource_button),
			"Hand card text should stay inside the frame without intersecting neighboring regions."
		)
		_check(
			is_equal_approx(
				_card_art(resource_button).get_parent().size.y,
				main_ui.CARD_ART_HEIGHT
			),
			"Hand artwork should use the shared card art height."
		)
		resource_button.mouse_entered.emit()
		await create_timer(0.2).timeout
		_check(_card_preview().visible, "Hovering a hand card should show its preview.")
		_check(main_ui.last_ui_sound_name == "hover", "Card hover should trigger its UI sound.")
		_check(
			_preview_name_label().text == "Pebble Coin",
			"Hand preview should show the hovered card name."
		)
		_check(
			_preview_art().texture == _card_art(resource_button).texture,
			"Hand preview should display the hovered card artwork."
		)
		_check(
			_preview_effect().get_parsed_text()
			== _plain_card_rules_text(
				main_ui.game_state.card_catalog["pebble_coin"].description
			),
			"Hand previews should show the same complete rules description once."
		)
		_check(
			_card_preview().get_meta("card_base_color") == main_ui.COLOR_RESOURCE_CARD,
			"Resource previews should reuse the resource surface treatment."
		)
		_check(
			_card_preview().get_global_rect().end.x <= root.get_visible_rect().end.x
			and _card_preview().get_global_rect().end.y <= root.get_visible_rect().end.y,
			"Card previews should remain inside the viewport."
		)
		_check(
			resource_button.scale.x > 1.0,
			"Hovered hand card should receive subtle scale feedback."
		)
		resource_button.mouse_exited.emit()
		await process_frame
		_check(not _card_preview().visible, "Leaving a hand card should hide its preview.")
		resource_button.pressed.emit()
		await process_frame
		_check(main_ui.last_ui_sound_name == "play_card", "Playing a card should trigger its sound.")
		_check(main_ui.last_animation_event == "play", "Playing should trigger card movement.")
		_check(_hud_value("CoinStat") == "1", "Coin HUD should update after playing a resource.")
		_check(_hand_container().get_child_count() == 4, "Played card should leave the hand UI.")
		_check(_play_area_container().get_child_count() == 1, "Played card should render in play area.")

	var short_rules_card: CardDefinition = main_ui.game_state.card_catalog["candlecap_laboratory"]
	var short_rules_button := main_ui._create_card_button(short_rules_card, "hand_playable")
	root.add_child(short_rules_button)
	await process_frame
	_check(
		_card_effect(short_rules_button).get_parsed_text()
		== "+2 cards.\n+1 action.",
		"Short multi-sentence rules text should split into one sentence per line."
	)
	short_rules_button.queue_free()

	var long_rules := main_ui.game_state.card_catalog["grand_archive"].description
	_check(
		main_ui._get_card_rules_text(long_rules) == long_rules,
		"Long rules text should remain a single paragraph."
	)

	var score_button := _find_card_button(_hand_container(), "homestead")
	if score_button != null:
		_check(score_button.disabled, "Victory-only hand cards should remain unavailable.")
		_check(
			score_button.get_meta("card_base_color") == main_ui.COLOR_VICTORY_CARD,
			"Victory cards should use the restrained oxblood surface."
		)
		_check(
			score_button.get_meta("card_accent_color") == main_ui.COLOR_UNAVAILABLE.darkened(0.12),
			"Unavailable hand cards should use the muted accent."
		)

	main_ui.game_state.player.coins = 99
	main_ui._refresh_ui()
	await process_frame
	var market_button: Button = _all_market_buttons()[0]
	var market_card_id: String = market_button.get_meta("card_id")
	var market_card: CardDefinition = main_ui.game_state.card_catalog[market_card_id]
	var market_supply_before: int = main_ui.game_state.get_supply_count(market_card_id)
	if market_button != null:
		_check(not market_button.disabled, "Affordable market card should be enabled.")
		_check(
			market_button.get_meta("visual_state") == "market_affordable",
			"Affordable market card should use its distinct visual state."
		)
		_check(
			market_button.get_meta("card_base_color")
			== main_ui._get_card_surface_color(market_card.card_type),
			"Market cards should use the surface color for their card type."
		)
		_check(
			market_button.get_meta("card_accent_color")
			== main_ui._get_card_palette("market_affordable").border,
			"Affordable market cards should use the forest accent."
		)
		_check(
			_market_pile_label(market_button).text == "×%d" % market_supply_before,
			"Market cards should show their remaining pile count."
		)
		_check(
			market_button.custom_minimum_size == main_ui.CARD_FACE_SIZE,
			"Market cards should use the same dimensions as cards in hand."
		)
		_check(
			is_equal_approx(
				_card_art(market_button).get_parent().size.y,
				main_ui.CARD_ART_HEIGHT
			),
			"Market artwork should use the shared card art height."
		)
		_check(
			_card_price(market_button).text
			== str(main_ui.game_state.get_effective_cost(market_card)),
			"Market prices should appear in the upper-left coin badge."
		)
		_check(
			_card_effect(market_button).get_parsed_text()
			== _plain_card_rules_text(market_card.description),
			"Market card faces should show their complete rules description."
		)
		_check(
			_card_name(market_button).get_theme_font_size("font_size") >= 12
			and _card_effect(market_button).get_theme_font_size("normal_font_size") >= 10,
			"Market card titles and rules text should use the enlarged type."
		)
		_check(
			_card_text_layout_is_clear(market_button),
			"Market card text should stay inside the frame without intersecting neighboring regions."
		)
		market_button.mouse_entered.emit()
		await process_frame
		_check(_card_preview().visible, "Hovering a market card should show its preview.")
		_check(
			_preview_name_label().text == market_card.card_name,
			"Market preview should show the hovered card name."
		)
		_check(
			_preview_art().texture == _card_art(market_button).texture,
			"Market preview should display the hovered card artwork."
		)
		_check(
			_preview_effect().get_parsed_text()
			== _plain_card_rules_text(market_card.description),
			"Market previews should show the exact data-driven rules description."
		)
		_check(
			_card_preview().get_meta("card_base_color")
			== main_ui._get_card_surface_color(market_card.card_type),
			"Market previews should retain the hovered card type treatment."
		)
		_check(
			_card_preview().get_global_rect().end.x <= root.get_visible_rect().end.x
			and _card_preview().get_global_rect().end.y <= root.get_visible_rect().end.y,
			"Market card previews should remain inside the viewport."
		)
		market_button.mouse_exited.emit()
		await process_frame
		var discard_before: int = main_ui.game_state.player.discard_pile.size()
		market_button.pressed.emit()
		await process_frame
		_check(main_ui.last_ui_sound_name == "buy_card", "Buying a card should trigger its sound.")
		_check(main_ui.last_animation_event == "buy", "Buying should trigger card movement.")
		_check(
			main_ui.game_state.player.discard_pile.size() == discard_before + 1,
			"Bought card should enter discard."
		)
		_check(
			main_ui.game_state.get_supply_count(market_card_id) == market_supply_before - 1,
			"Buying should decrement the visible supply pile."
		)
		_check(_hud_value("BuyStat") == "0", "Buy HUD should update after a purchase.")
		for button in _all_market_buttons():
			_check(button.disabled, "Market cards should be unavailable with no buys remaining.")
		main_ui.game_state.player.buys = 1
		main_ui.game_state.player.coins = 99
		main_ui.game_state.set_supply_count(market_card_id, 0)
		main_ui._refresh_ui()
		var sold_out_button := _find_card_button(_market_container(), market_card_id)
		_check(sold_out_button != null, "Sold-out market pile should remain rendered.")
		if sold_out_button != null:
			_check(sold_out_button.disabled, "Sold-out market piles should remain disabled.")
			_check(
				_market_pile_label(sold_out_button).text == "×0",
				"Sold-out market piles should visibly show zero remaining."
			)

	_end_turn_button().pressed.emit()
	await process_frame
	await process_frame
	_check(main_ui.last_ui_sound_name == "draw", "End turn should finish with draw feedback.")
	_check(main_ui.last_animation_event == "draw", "End turn should animate the new hand.")
	_check(_hand_container().get_child_count() == 5, "End turn should render a new five-card hand.")
	_check(_hud_value("CoinStat") == "0", "Coin HUD should reset at end of turn.")
	_check(_hud_value("ActionStat") == "1", "Action HUD should reset at end of turn.")
	_check(_hud_value("BuyStat") == "1", "Buy HUD should reset at end of turn.")
	_check(
		main_ui.game_state.player.play_area.is_empty(),
		"Play area state should be empty after cleanup."
	)

	var market_before_restart: Array[String] = main_ui.game_state.get_market_card_ids()
	main_ui.game_state.player.coins = 8
	main_ui.game_state.player.discard_pile.append(main_ui.game_state.card_catalog["silver_leaf"])
	main_ui._refresh_ui()
	_home_button().pressed.emit()
	await process_frame
	_check(_home_overlay().visible, "Home button should return to the home screen.")
	_check(not _home_continue_button().disabled, "Continue should unlock once a game exists.")
	_home_continue_button().pressed.emit()
	await process_frame
	_check(not _home_overlay().visible, "Continue should resume the current game.")
	_check(_hud_value("CoinStat") == "8", "Continue should preserve the current game state.")
	_home_button().pressed.emit()
	await process_frame
	_home_new_game_button().pressed.emit()
	await process_frame
	await process_frame
	_check(main_ui.last_ui_sound_name == "draw", "Home New Game should finish with draw feedback.")
	var market_after_restart: Array[String] = main_ui.game_state.get_market_card_ids()
	_check(
		not _same_card_ids(market_before_restart, market_after_restart),
		"Home New Game should display a different market."
	)
	_check(_hud_value("TurnStat") == "1 / 15", "Home New Game should reset the turn counter.")
	_check(_hud_value("CoinStat") == "0", "Home New Game should reset coins.")
	_check(main_ui.game_state.player.hand.size() == 5, "Home New Game should draw a fresh hand.")
	_check(
		main_ui.game_state.player.get_all_cards().size() == 10,
		"Home New Game should restore the starting deck."
	)
	_check(
		main_ui.game_state.player.discard_pile.is_empty(),
		"Home New Game should clear the discard pile."
	)

	main_ui.game_state.player.clear_all()
	main_ui.game_state.player.actions = 1
	main_ui.game_state.player.hand.append(main_ui.game_state.card_catalog["quiet_chapel"])
	main_ui.game_state.player.hand.append(main_ui.game_state.card_catalog["pebble_coin"])
	main_ui.game_state.player.hand.append(main_ui.game_state.card_catalog["homestead"])
	main_ui._refresh_ui()
	var chapel_button := _find_card_button(_hand_container(), "quiet_chapel")
	_check(chapel_button != null, "Choice-effect card should render in hand.")
	if chapel_button != null:
		chapel_button.pressed.emit()
		await process_frame
		_check(_choice_overlay().visible, "Playing a choice card should open the choice overlay.")
		_check(_choice_options().get_child_count() == 2, "Choice overlay should list eligible cards.")
		_check(_end_turn_button().disabled, "End Turn should lock while a choice is pending.")
		for option in _choice_options().get_children():
			(option as Button).pressed.emit()
		_check(not _choice_confirm_button().disabled, "Valid selection should enable confirmation.")
		_choice_confirm_button().pressed.emit()
		await process_frame
		_check(not _choice_overlay().visible, "Resolving a choice should close the overlay.")
		_check(
			main_ui.game_state.player.trash_pile.size() == 2,
			"Choice confirmation should apply the selected card movement."
		)

	main_ui._start_new_game(true)
	await process_frame
	await process_frame
	main_ui.turn_manager.turn_number = 15
	_end_turn_button().pressed.emit()
	await process_frame
	_check(_end_game_overlay().visible, "Final scoring should show an intentional overlay.")
	_check(
		_final_score_label().text == str(main_ui.turn_manager.final_score),
		"Final score overlay should show the calculated score."
	)
	_check(main_ui.last_animation_event == "game_end", "Final scoring should animate its reveal.")
	_check(main_ui.last_ui_sound_name == "game_end", "Final scoring should trigger its sound.")

	_play_again_button().pressed.emit()
	await process_frame
	await process_frame
	_check(not _end_game_overlay().visible, "Play Again should close the final score overlay.")
	_check(_hud_value("TurnStat") == "1 / 15", "Play Again should start a fresh game.")
	_check(
		_active_ui_uses_original_assets(),
		"Active UI code should use original assets and no Kenney fantasy-border paths."
	)

	if failure_count > 0:
		push_error("[Test] UI smoke test failed with %d issue(s)." % failure_count)
		_cleanup_main_ui()
		await process_frame
		await process_frame
		await create_timer(0.1).timeout
		quit(1)
		return

	print("[Test] UI smoke test passed.")
	_cleanup_main_ui()
	await process_frame
	await process_frame
	await create_timer(0.1).timeout
	quit(0)


func _hand_container() -> HBoxContainer:
	return main_ui.hand_container


func _hand_panel() -> PanelContainer:
	return main_ui.hand_panel


func _market_container() -> HBoxContainer:
	return main_ui.get_node(
		"Margin/Layout/MarketPanel/MarketMargin/MarketScroll/MarketContainer"
	)


func _market_panel() -> PanelContainer:
	return main_ui.get_node("Margin/Layout/MarketPanel")


func _home_overlay() -> Control:
	return main_ui.get_node("HomeOverlay")


func _home_art() -> TextureRect:
	return main_ui.get_node("HomeOverlay/HomeArt")


func _home_set_label() -> Label:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/SetLabel")


func _home_new_game_button() -> Button:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/Buttons/NewGameButton")


func _home_continue_button() -> Button:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/Buttons/ContinueButton")


func _home_settings_button() -> Button:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/Buttons/SettingsButton")


func _home_kingdoms_button() -> Button:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/Buttons/KingdomsButton")


func _home_settings_panel() -> VBoxContainer:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/SettingsPanel")


func _home_kingdoms_panel() -> PanelContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel")


func _home_audio_toggle() -> CheckButton:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/SettingsPanel/AudioToggle")


func _home_motion_toggle() -> CheckButton:
	return main_ui.get_node("HomeOverlay/MenuMargin/Menu/SettingsPanel/MotionToggle")


func _home_noise_slider() -> HSlider:
	return main_ui.home_noise_slider


func _table_noise_slider() -> HSlider:
	return main_ui.table_noise_slider


func _action_speed_slider() -> HSlider:
	return main_ui.action_animation_speed_slider


func _home_noise_overlay() -> TextureRect:
	return main_ui.home_noise_overlay


func _table_noise_overlay() -> TextureRect:
	return main_ui.table_noise_overlay


func _kingdom_tabs() -> VBoxContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel/Margin/Browser/KingdomTabs")


func _kingdom_card_grid() -> GridContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel/Margin/Browser/CardsPane/CardScroll/CardGrid")


func _kingdom_detail_host() -> VBoxContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel/Margin/Browser/DetailPane/Margin/DetailHost")


func _kingdom_tab(kingdom: String) -> Button:
	return main_ui.get_node(
		"HomeOverlay/KingdomsPanel/Margin/Browser/KingdomTabs/Kingdom_%s/KingdomTab"
		% main_ui._node_key(kingdom)
	)


func _kingdom_toggle(kingdom: String) -> CheckButton:
	return main_ui.get_node(
		"HomeOverlay/KingdomsPanel/Margin/Browser/KingdomTabs/Kingdom_%s/KingdomToggle"
		% main_ui._node_key(kingdom)
	)


func _kingdom_card_button(card_id: String) -> Button:
	return _home_kingdoms_panel().find_child("Card_%s" % card_id, true, false) as Button


func _kingdom_detail_card(card_id: String) -> Button:
	return _home_kingdoms_panel().find_child("DetailCard_%s" % card_id, true, false) as Button


func _kingdom_detail_toggle() -> CheckButton:
	return _home_kingdoms_panel().find_child("DetailCardToggle", true, false) as CheckButton


func _plain_card_rules_text(description: String) -> String:
	return main_ui._get_card_rules_text(description).replace("[b]", "").replace("[/b]", "")


func _market_candidates_include_kingdom(kingdom: String) -> bool:
	for card in main_ui.game_state.get_market_candidates():
		if main_ui.game_state.get_card_kingdom(card) == kingdom:
			return true
	return false


func _market_candidates_include_card(card_id: String) -> bool:
	for card in main_ui.game_state.get_market_candidates():
		if card.id == card_id:
			return true
	return false


func _market_scroll() -> ScrollContainer:
	return main_ui.get_node("Margin/Layout/MarketPanel/MarketMargin/MarketScroll")


func _treasury_cards() -> GridContainer:
	return main_ui.market_resource_container


func _barracks_cards() -> GridContainer:
	return main_ui.market_action_container


func _estates_cards() -> GridContainer:
	return main_ui.market_victory_container


func _all_market_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for container in [_treasury_cards(), _barracks_cards(), _estates_cards()]:
		for child in container.get_children():
			buttons.append(child as Button)
	return buttons


func _container_has_type(container: GridContainer, card_type: String) -> bool:
	for child in container.get_children():
		if child.get_meta("card_type", "") != card_type:
			return false
	return true


func _costs_descend_in_child_order(container: GridContainer) -> bool:
	var previous_cost := 999
	for child in container.get_children():
		var current_cost := _market_button_cost(child as Button)
		if current_cost > previous_cost:
			return false
		previous_cost = current_cost
	return true


func _barracks_follows_cost_path() -> bool:
	var buttons := _barracks_cards().get_children()
	if buttons.size() != 10:
		return false
	var visual_path := [4, 3, 2, 1, 0, 9, 8, 7, 6, 5]
	var previous_cost := 999
	for index in visual_path:
		var current_cost := _market_button_cost(buttons[index] as Button)
		if current_cost > previous_cost:
			return false
		previous_cost = current_cost
	return true


func _market_button_cost(button: Button) -> int:
	var card_id := str(button.get_meta("card_id", ""))
	return main_ui.game_state.get_effective_cost(main_ui.game_state.card_catalog[card_id])


func _children_fit_parent(container: Container) -> bool:
	var parent_rect := container.get_global_rect()
	for child in container.get_children():
		var child_rect: Rect2 = child.get_global_rect()
		if (
			child_rect.position.x < parent_rect.position.x
			or child_rect.position.y < parent_rect.position.y
			or child_rect.end.x > parent_rect.end.x
			or child_rect.end.y > parent_rect.end.y
		):
			return false
	return true


func _play_area_container() -> HBoxContainer:
	return main_ui.get_node(
		"Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaScroll/PlayAreaContainer"
	)


func _end_turn_button() -> Button:
	return main_ui.end_turn_button


func _home_button() -> Button:
	return main_ui.home_button


func _card_preview() -> PanelContainer:
	return main_ui.get_node("CardPreview")


func _end_game_overlay() -> Control:
	return main_ui.get_node("EndGameOverlay")


func _final_score_label() -> Label:
	return main_ui.get_node(
		"EndGameOverlay/Center/Panel/Margin/Layout/ScoreRow/ScoreLabel"
	)


func _play_again_button() -> Button:
	return main_ui.get_node(
		"EndGameOverlay/Center/Panel/Margin/Layout/PlayAgainButton"
	)


func _preview_name_label() -> Label:
	return main_ui.get_node("CardPreview/Margin/Layout/NameLabel")


func _preview_art() -> TextureRect:
	return main_ui.get_node("CardPreview/Margin/Layout/ArtFrame/Art")


func _preview_effect() -> RichTextLabel:
	return main_ui.get_node("CardPreview/Margin/Layout/EffectLabel")


func _choice_overlay() -> Control:
	return main_ui.get_node("ChoiceOverlay")


func _choice_options() -> HBoxContainer:
	return main_ui.get_node(
		"ChoiceOverlay/Center/Panel/Margin/Layout/OptionsScroll/Options"
	)


func _choice_confirm_button() -> Button:
	return main_ui.get_node(
		"ChoiceOverlay/Center/Panel/Margin/Layout/Buttons/ConfirmButton"
	)


func _card_art(button: Button) -> TextureRect:
	return button.get_node("CardContent/CardLayout/ArtFrame/Art")


func _card_name(button: Button) -> Label:
	return button.get_node("CardContent/CardLayout/NameLabel")


func _card_effect(button: Button) -> RichTextLabel:
	return button.get_node("CardContent/CardLayout/EffectSlot/EffectCenter/EffectLabel")


func _card_price(button: Button) -> Label:
	return button.get_node("PriceBadge/CostLabel")


func _card_text_layout_is_clear(button: Button) -> bool:
	var content := button.get_node("CardContent") as MarginContainer
	var name_label := _card_name(button)
	var art_frame := _card_art(button).get_parent() as Control
	var effect_slot := button.get_node("CardContent/CardLayout/EffectSlot") as MarginContainer
	var effect_center := button.get_node("CardContent/CardLayout/EffectSlot/EffectCenter") as VBoxContainer
	var effect_label := _card_effect(button)
	var meta_row := button.get_node("CardContent/CardLayout/MetaRow") as Control
	var price_badge := button.get_node("PriceBadge") as Control
	var price_label := _card_price(button)
	var button_rect := button.get_global_rect()
	var safe_rect := button_rect.grow(-4.0)
	var regions: Array[Control] = [name_label, art_frame, effect_slot, effect_label, meta_row]
	var footer_gap := button_rect.end.y - meta_row.get_global_rect().end.y

	if (
		content.get_theme_constant("margin_top") != 5
		or content.get_theme_constant("margin_bottom") != 5
		or name_label.custom_minimum_size.y < 30.0
		or name_label.vertical_alignment != VERTICAL_ALIGNMENT_BOTTOM
		or effect_slot.get_theme_constant("margin_left") != main_ui.CARD_RULE_SIDE_MARGIN
		or effect_slot.get_theme_constant("margin_top") != main_ui.CARD_RULE_TOP_MARGIN
		or effect_slot.get_theme_constant("margin_right") != main_ui.CARD_RULE_SIDE_MARGIN
		or effect_slot.get_theme_constant("margin_bottom") != main_ui.CARD_RULE_BOTTOM_MARGIN
		or effect_center.alignment != BoxContainer.ALIGNMENT_CENTER
		or not price_badge.has_node("CoinFace")
		or not price_badge.has_node("InnerRing")
		or not price_badge.has_node("CoinRivet")
		or price_label.offset_left != 0
		or price_label.offset_top != 2
	):
		return false

	for region in regions:
		var region_rect := region.get_global_rect()
		if not safe_rect.encloses(region_rect):
			return false

	return (
		name_label.get_global_rect().end.y <= art_frame.get_global_rect().position.y
		and art_frame.get_global_rect().end.y + 5.0
		<= effect_label.get_global_rect().position.y
		and effect_label.get_global_rect().end.y <= meta_row.get_global_rect().position.y
		and footer_gap >= 0.0
		and footer_gap <= 8.0
		and safe_rect.encloses(price_badge.get_global_rect())
		and price_badge.get_global_rect().position.x < art_frame.get_global_rect().position.x
		and price_badge.get_global_rect().end.y <= art_frame.get_global_rect().position.y
		and not art_frame.get_global_rect().encloses(price_badge.get_global_rect())
	)


func _market_pile_label(button: Button) -> Label:
	return button.get_node("CardContent/CardLayout/MetaRow/PileLabel")


func _hud_value(stat_name: String) -> String:
	var stat := main_ui.hud_row.find_child(stat_name, true, false) as Control
	var label := stat.find_child("Value", true, false) as Label
	return label.text


func _hud_icon(stat_name: String) -> TextureRect:
	var stat := main_ui.hud_row.find_child(stat_name, true, false) as Control
	return stat.find_child("Icon", true, false) as TextureRect


func _find_card_button(container: Container, card_id: String) -> Button:
	for child in container.get_children():
		if child.get_meta("card_id", "") == card_id:
			return child
		if child is Container:
			var nested := _find_card_button(child as Container, card_id)
			if nested != null:
				return nested
	return null


func _same_card_ids(first: Array[String], second: Array[String]) -> bool:
	if first.size() != second.size():
		return false
	for card_id in first:
		if not second.has(card_id):
			return false
	return true


func _color_distance(first: Color, second: Color) -> float:
	return Vector3(first.r, first.g, first.b).distance_to(
		Vector3(second.r, second.g, second.b)
	)


func _active_ui_uses_original_assets() -> bool:
	var script_text := FileAccess.get_file_as_string("res://scripts/ui/main_ui.gd")
	var scene_text := FileAccess.get_file_as_string("res://scenes/Main.tscn")
	return (
		script_text.contains("res://assets/ui/")
		and scene_text.contains("res://assets/ui/")
		and not script_text.contains("kenney_fantasy-ui-borders")
		and not scene_text.contains("kenney_fantasy-ui-borders")
	)


func _cleanup_main_ui() -> void:
	for player in main_ui.ui_sound_players.values():
		(player as AudioStreamPlayer).stop()
	main_ui.free()
	main_ui = null


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error("[Test] %s" % message)
