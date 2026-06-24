extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failure_count := 0
var main_ui: Control


func _initialize() -> void:
	main_ui = MAIN_SCENE.instantiate()
	root.add_child(main_ui)
	await process_frame

	_check(_hand_container().get_child_count() == 5, "Initial hand should render five cards.")
	_check(
		_market_container().get_child_count() == GameState.MARKET_SIZE,
		"Market should render six randomly selected cards."
	)
	_check(_play_area_container().get_child_count() == 1, "Empty play area should show its hint.")

	var resource_button := _find_card_button(_hand_container(), "pebble_coin")
	_check(resource_button != null, "A Pebble Coin button should render in hand.")
	if resource_button != null:
		_check(not resource_button.disabled, "A resource card should be visibly playable.")
		resource_button.mouse_entered.emit()
		await create_timer(0.1).timeout
		_check(_card_preview().visible, "Hovering a hand card should show its preview.")
		_check(
			_preview_name_label().text == "Pebble Coin",
			"Hand preview should show the hovered card name."
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
		_check(_hud_value("CoinStat") == "1", "Coin HUD should update after playing a resource.")
		_check(_hand_container().get_child_count() == 4, "Played card should leave the hand UI.")
		_check(_play_area_container().get_child_count() == 1, "Played card should render in play area.")

	main_ui.game_state.player.coins = 99
	main_ui._refresh_ui()
	var market_button: Button = _market_container().get_child(0)
	var market_card_id: String = market_button.get_meta("card_id")
	var market_card: CardDefinition = main_ui.game_state.card_catalog[market_card_id]
	if market_button != null:
		_check(not market_button.disabled, "Affordable market card should be enabled.")
		_check(
			market_button.get_meta("visual_state") == "market_affordable",
			"Affordable market card should use its distinct visual state."
		)
		market_button.mouse_entered.emit()
		await process_frame
		_check(_card_preview().visible, "Hovering a market card should show its preview.")
		_check(
			_preview_name_label().text == market_card.card_name,
			"Market preview should show the hovered card name."
		)
		market_button.mouse_exited.emit()
		await process_frame
		var discard_before: int = main_ui.game_state.player.discard_pile.size()
		market_button.pressed.emit()
		await process_frame
		_check(
			main_ui.game_state.player.discard_pile.size() == discard_before + 1,
			"Bought card should enter discard."
		)
		_check(_hud_value("BuyStat") == "0", "Buy HUD should update after a purchase.")
		for button in _market_container().get_children():
			_check(button.disabled, "Market cards should be unavailable with no buys remaining.")

	_end_turn_button().pressed.emit()
	await process_frame
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

	if failure_count > 0:
		push_error("[Test] UI smoke test failed with %d issue(s)." % failure_count)
		quit(1)
		return

	print("[Test] UI smoke test passed.")
	quit(0)


func _hand_container() -> HBoxContainer:
	return main_ui.get_node("Margin/Layout/HandPanel/HandMargin/HandScroll/HandContainer")


func _market_container() -> HBoxContainer:
	return main_ui.get_node(
		"Margin/Layout/MarketPanel/MarketMargin/MarketScroll/MarketContainer"
	)


func _play_area_container() -> HBoxContainer:
	return main_ui.get_node(
		"Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaScroll/PlayAreaContainer"
	)


func _end_turn_button() -> Button:
	return main_ui.get_node("Margin/Layout/HudPanel/HudMargin/Hud/EndTurnButton")


func _new_game_button() -> Button:
	return main_ui.get_node("Margin/Layout/HudPanel/HudMargin/Hud/NewGameButton")


func _card_preview() -> PanelContainer:
	return main_ui.get_node("CardPreview")


func _preview_name_label() -> Label:
	return main_ui.get_node("CardPreview/Margin/Layout/NameLabel")


func _hud_value(stat_name: String) -> String:
	var label: Label = main_ui.get_node(
		"Margin/Layout/HudPanel/HudMargin/Hud/%s/Value" % stat_name
	)
	return label.text


func _find_card_button(container: Container, card_id: String) -> Button:
	for child in container.get_children():
		if child.get_meta("card_id", "") == card_id:
			return child
	return null


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
