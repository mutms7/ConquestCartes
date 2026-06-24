extends Control

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

var game_state := GameState.new()
var turn_manager := TurnManager.new()

@onready var turn_label: Label = $Margin/Layout/StatsBar/TurnLabel
@onready var deck_label: Label = $Margin/Layout/StatsBar/DeckLabel
@onready var discard_label: Label = $Margin/Layout/StatsBar/DiscardLabel
@onready var coin_label: Label = $Margin/Layout/StatsBar/CoinLabel
@onready var action_label: Label = $Margin/Layout/StatsBar/ActionLabel
@onready var buy_label: Label = $Margin/Layout/StatsBar/BuyLabel
@onready var end_turn_button: Button = $Margin/Layout/StatsBar/EndTurnButton
@onready var market_container: HBoxContainer = $Margin/Layout/MarketScroll/MarketContainer
@onready var hand_container: HBoxContainer = $Margin/Layout/HandScroll/HandContainer
@onready var status_label: Label = $Margin/Layout/StatusLabel


func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	turn_manager.configure(game_state)

	if not game_state.load_cards(CARD_DATA_PATH):
		status_label.text = "Could not load card data. Check the Godot output."
		end_turn_button.disabled = true
		return
	if not game_state.setup_starting_game():
		status_label.text = "Could not prepare the starting deck. Check the Godot output."
		end_turn_button.disabled = true
		return

	turn_manager.start_first_turn()
	status_label.text = "Play resource and action cards, then buy from the market."
	_refresh_ui()


func _refresh_ui() -> void:
	var player := game_state.player
	turn_label.text = "Turn: %d/%d" % [turn_manager.turn_number, turn_manager.maximum_turns]
	deck_label.text = "Deck: %d" % player.draw_pile.size()
	discard_label.text = "Discard: %d" % player.discard_pile.size()
	coin_label.text = "Coins: %d" % player.coins
	action_label.text = "Actions: %d" % player.actions
	buy_label.text = "Buys: %d" % player.buys
	end_turn_button.disabled = turn_manager.game_over

	_clear_container(hand_container)
	for card in player.hand:
		var button := _create_card_button(card, false)
		button.disabled = turn_manager.game_over or not card.is_playable()
		if card.card_type == "action" and player.actions <= 0:
			button.disabled = true
		button.pressed.connect(_on_hand_card_pressed.bind(card))
		hand_container.add_child(button)

	_clear_container(market_container)
	for card in game_state.market:
		var button := _create_card_button(card, true)
		button.disabled = (
			turn_manager.game_over
			or player.buys <= 0
			or player.coins < card.cost
		)
		button.pressed.connect(_on_market_card_pressed.bind(card))
		market_container.add_child(button)


func _create_card_button(card: CardDefinition, is_market_card: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(165, 155)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text = "%s\nCost %d  |  %s\n\n%s" % [
		card.card_name,
		card.cost,
		card.card_type.capitalize(),
		card.description,
	]
	button.tooltip_text = card.description
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#f7f0d5"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))

	var base_color := Color("#3c5a50") if is_market_card else Color("#55486f")
	button.add_theme_stylebox_override("normal", _make_card_style(base_color))
	button.add_theme_stylebox_override("hover", _make_card_style(base_color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _make_card_style(base_color.darkened(0.08)))
	button.add_theme_stylebox_override("disabled", _make_card_style(base_color.darkened(0.28)))
	return button


func _make_card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#d7c894")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_hand_card_pressed(card: CardDefinition) -> void:
	if game_state.play_card(card):
		status_label.text = "Played %s." % card.card_name
	else:
		status_label.text = "That card cannot be played right now."
	_refresh_ui()


func _on_market_card_pressed(card: CardDefinition) -> void:
	if game_state.buy_card(card):
		status_label.text = "Bought %s; it was placed in your discard pile." % card.card_name
	else:
		status_label.text = "You need enough coins and an available buy."
	_refresh_ui()


func _on_end_turn_pressed() -> void:
	turn_manager.end_turn()
	if turn_manager.game_over:
		status_label.text = "Game complete. Final score: %d victory points." % turn_manager.final_score
	else:
		status_label.text = "Turn %d begins with a new hand." % turn_manager.turn_number
	_refresh_ui()
