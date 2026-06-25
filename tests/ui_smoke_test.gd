extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failure_count := 0
var main_ui: Control


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	main_ui = MAIN_SCENE.instantiate()
	root.add_child(main_ui)
	await process_frame

	_check(_hand_container().get_child_count() == 5, "Initial hand should render five cards.")
	_check(
		_all_market_buttons().size() == GameState.MARKET_SIZE,
		"Market should render the configured number of randomly selected cards."
	)
	_check(
		_treasury_cards().get_child_count() == GameState.MARKET_RESOURCE_COUNT,
		"Royal Treasury should render two resource piles."
	)
	_check(
		_barracks_cards().get_child_count() == GameState.MARKET_ACTION_COUNT,
		"Guild Barracks should render ten action piles."
	)
	_check(
		_estates_cards().get_child_count() == GameState.MARKET_VICTORY_TOTAL,
		"Crown Estates should render two victory piles."
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
		_market_scroll().horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		and _market_scroll().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"The complete market should fit without scrolling."
	)
	_check(
		_zone_title("TreasuryCarpet") == "ROYAL TREASURY"
		and _zone_title("BarracksCarpet") == "GUILD BARRACKS"
		and _zone_title("EstatesCarpet") == "CROWN ESTATES",
		"Each functional market carpet should display its themed name."
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
		main_ui._get_card_effect_text(main_ui.game_state.card_catalog["crossroads_market"])
		== "+1 Card  +1 Action  +1 Coin  +1 Buy",
		"Combined card effects should use concise singular and plural labels."
	)
	_check(
		main_ui._get_card_effect_text(main_ui.game_state.card_catalog["briar_gate"]) == "3 VP",
		"Victory-only cards should show their point value concisely."
	)
	_check(
		main_ui._get_card_effect_text(main_ui.game_state.card_catalog["wishing_garden"])
		== "1 VP / 10 Cards",
		"Variable victory cards should explain their scoring rule concisely."
	)
	_check(
		main_ui.COLOR_RESOURCE_CARD != main_ui.COLOR_ACTION_CARD
		and main_ui.COLOR_ACTION_CARD != main_ui.COLOR_VICTORY_CARD
		and main_ui.COLOR_RESOURCE_CARD != main_ui.COLOR_VICTORY_CARD,
		"Each card type should have a distinct dark medieval surface color."
	)
	_check(
		_hand_panel().get_global_rect().end.y <= root.get_visible_rect().end.y,
		"The full hand panel should remain inside the 1280x720 viewport."
	)
	_check(
		_market_panel().get_global_rect().end.y <= root.get_visible_rect().end.y,
		"The complete three-carpet market should remain inside the viewport."
	)
	_check(
		_children_fit_parent(_treasury_cards())
		and _children_fit_parent(_barracks_cards())
		and _children_fit_parent(_estates_cards()),
		"Every market card should remain inside its assigned carpet."
	)
	_check(
		main_ui.left_ledger.get_global_rect().end.x
		< main_ui.brand_panel.get_global_rect().end.x
		and main_ui.right_ledger.get_global_rect().position.x
		> main_ui.brand_panel.get_global_rect().position.x,
		"Persistent game details should occupy the upper side ledgers."
	)
	_check(
		main_ui.left_ledger.get_global_rect().position.x >= 0.0
		and main_ui.right_ledger.get_global_rect().end.x <= root.get_visible_rect().end.x
		and main_ui.right_ledger.get_global_rect().end.y <= root.get_visible_rect().end.y,
		"Both upper ledgers should remain inside the 1280x720 viewport."
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
			resource_button.get_meta("card_accent_color") == main_ui.COLOR_SLATE,
			"Playable hand cards should use the slate accent."
		)
		_check(
			resource_button.has_node("MedievalFrame"),
			"Card faces should include the original medieval frame ornament."
		)
		_check(_card_art(resource_button).texture != null, "Card faces should display card artwork.")
		_check(
			_card_effect(resource_button).get_parsed_text() == "+1 Coin",
			"Card faces should show concise data-derived effect text."
		)
		_check(
			_card_art(resource_button).get_parent().size.y >= 108.0,
			"Card artwork should use the enlarged art window."
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
			_preview_effect().get_parsed_text() == "+1 Coin",
			"Hand preview should reuse the concise effect summary."
		)
		_check(
			_preview_description().get_parsed_text() == "Gain 1 coin.",
			"Card previews should show the full detailed rules wording."
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
			market_button.get_meta("card_accent_color") == main_ui.COLOR_FOREST,
			"Affordable market cards should use the forest accent."
		)
		_check(
			_market_pile_label(market_button).text == "×%d" % market_supply_before,
			"Market cards should show their remaining pile count."
		)
		_check(
			market_button.size.y <= 140.0,
			"Market cards should use the compact two-row presentation."
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
	_new_game_button().pressed.emit()
	await process_frame
	await process_frame
	_check(main_ui.last_ui_sound_name == "draw", "New Game should finish with draw feedback.")
	var market_after_restart: Array[String] = main_ui.game_state.get_market_card_ids()
	_check(
		not _same_card_ids(market_before_restart, market_after_restart),
		"New Game button should display a different market."
	)
	_check(_hud_value("TurnStat") == "1 / 15", "New Game should reset the turn counter.")
	_check(_hud_value("CoinStat") == "0", "New Game should reset coins.")
	_check(main_ui.game_state.player.hand.size() == 5, "New Game should draw a fresh hand.")
	_check(
		main_ui.game_state.player.get_all_cards().size() == 10,
		"New Game should restore the starting deck."
	)
	_check(
		main_ui.game_state.player.discard_pile.is_empty(),
		"New Game should clear the discard pile."
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
	return main_ui.get_node("Margin/Layout/HandPanel/HandMargin/HandScroll/HandContainer")


func _hand_panel() -> PanelContainer:
	return main_ui.get_node("Margin/Layout/HandPanel")


func _market_container() -> HBoxContainer:
	return main_ui.get_node(
		"Margin/Layout/MarketPanel/MarketMargin/MarketScroll/MarketContainer"
	)


func _market_panel() -> PanelContainer:
	return main_ui.get_node("Margin/Layout/MarketPanel")


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


func _zone_title(carpet_name: String) -> String:
	var carpet := _market_container().get_node(carpet_name)
	var title := carpet.find_child("Title", true, false) as Label
	return title.text


func _container_has_type(container: GridContainer, card_type: String) -> bool:
	for child in container.get_children():
		if child.get_meta("card_type", "") != card_type:
			return false
	return true


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


func _new_game_button() -> Button:
	return main_ui.new_game_button


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


func _preview_description() -> RichTextLabel:
	return main_ui.get_node("CardPreview/Margin/Layout/DescriptionLabel")


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


func _card_effect(button: Button) -> RichTextLabel:
	return button.get_node("CardContent/CardLayout/EffectLabel")


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
