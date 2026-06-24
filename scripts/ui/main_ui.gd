extends Control

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

const HAND_PLAYABLE := "hand_playable"
const HAND_UNPLAYABLE := "hand_unplayable"
const MARKET_AFFORDABLE := "market_affordable"
const MARKET_UNAFFORDABLE := "market_unaffordable"
const CARD_HOVER_SCALE := Vector2(1.025, 1.025)
const CARD_NORMAL_SCALE := Vector2.ONE
const HOVER_ANIMATION_SECONDS := 0.08
const PREVIEW_SIZE := Vector2(300, 300)
const PREVIEW_EDGE_MARGIN := 24.0

var game_state := GameState.new()
var turn_manager := TurnManager.new()

@onready var turn_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/TurnStat/Value
@onready var deck_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/DeckStat/Value
@onready var discard_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/DiscardStat/Value
@onready var coin_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/CoinStat/Value
@onready var action_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/ActionStat/Value
@onready var buy_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/BuyStat/Value
@onready var new_game_button: Button = $Margin/Layout/HudPanel/HudMargin/Hud/NewGameButton
@onready var end_turn_button: Button = $Margin/Layout/HudPanel/HudMargin/Hud/EndTurnButton
@onready var market_container: HBoxContainer = (
	$Margin/Layout/MarketPanel/MarketMargin/MarketScroll/MarketContainer
)
@onready var status_label: Label = $Margin/Layout/StatusPanel/StatusLabel
@onready var play_area_label: Label = (
	$Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaLabel
)
@onready var play_area_container: HBoxContainer = (
	$Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaScroll/PlayAreaContainer
)
@onready var hand_count_label: Label = $Margin/Layout/HandHeader/HandCount
@onready var hand_container: HBoxContainer = (
	$Margin/Layout/HandPanel/HandMargin/HandScroll/HandContainer
)
@onready var card_preview: PanelContainer = $CardPreview
@onready var preview_location_label: Label = $CardPreview/Margin/Layout/LocationLabel
@onready var preview_state_label: Label = $CardPreview/Margin/Layout/StateLabel
@onready var preview_name_label: Label = $CardPreview/Margin/Layout/NameLabel
@onready var preview_meta_label: Label = $CardPreview/Margin/Layout/MetaLabel
@onready var preview_description_label: Label = $CardPreview/Margin/Layout/DescriptionLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	turn_manager.configure(game_state)

	if not game_state.load_cards(CARD_DATA_PATH):
		status_label.text = "Could not load card data. Check the Godot output."
		new_game_button.disabled = true
		end_turn_button.disabled = true
		return

	_start_new_game(false)


func _start_new_game(is_restart: bool) -> void:
	if not game_state.setup_starting_game():
		status_label.text = "Could not prepare a new game. Check the Godot output."
		end_turn_button.disabled = true
		return

	turn_manager.start_first_turn()
	if is_restart:
		status_label.text = "New game started with a fresh deck and random market."
	else:
		status_label.text = "Start by clicking a purple resource or action card in your hand."
	_refresh_ui()


func _refresh_ui() -> void:
	_hide_card_preview()
	var player := game_state.player
	turn_label.text = "%d / %d" % [turn_manager.turn_number, turn_manager.maximum_turns]
	deck_label.text = str(player.draw_pile.size())
	discard_label.text = str(player.discard_pile.size())
	coin_label.text = str(player.coins)
	action_label.text = str(player.actions)
	buy_label.text = str(player.buys)
	hand_count_label.text = "%d card%s" % [
		player.hand.size(),
		"" if player.hand.size() == 1 else "s",
	]
	end_turn_button.disabled = turn_manager.game_over

	_refresh_hand()
	_refresh_market()
	_refresh_play_area()


func _refresh_hand() -> void:
	_clear_container(hand_container)
	for card in game_state.player.hand:
		var playable := _can_play_card(card)
		var status_text := _get_hand_status(card)
		var visual_state := HAND_PLAYABLE if playable else HAND_UNPLAYABLE
		var button := _create_card_button(card, visual_state, status_text)
		button.disabled = not playable
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if playable else Control.CURSOR_ARROW
		)
		button.pressed.connect(_on_hand_card_pressed.bind(card))
		hand_container.add_child(button)


func _refresh_market() -> void:
	_clear_container(market_container)
	for card in game_state.market:
		var affordable := _can_buy_card(card)
		var status_text := _get_market_status(card)
		var visual_state := MARKET_AFFORDABLE if affordable else MARKET_UNAFFORDABLE
		var button := _create_card_button(card, visual_state, status_text)
		button.disabled = not affordable
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if affordable else Control.CURSOR_ARROW
		)
		button.pressed.connect(_on_market_card_pressed.bind(card))
		market_container.add_child(button)


func _refresh_play_area() -> void:
	_clear_container(play_area_container)
	var played_cards := game_state.player.play_area
	play_area_label.text = "PLAYED THIS TURN  %d" % played_cards.size()

	if played_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Played cards appear here and move to discard when you end the turn."
		empty_label.add_theme_color_override("font_color", Color("#82958a"))
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		play_area_container.add_child(empty_label)
		return

	for card in played_cards:
		play_area_container.add_child(_create_played_card_chip(card))


func _can_play_card(card: CardDefinition) -> bool:
	if turn_manager.game_over or not card.is_playable():
		return false
	if card.card_type == "action" and game_state.player.actions <= 0:
		return false
	return true


func _can_buy_card(card: CardDefinition) -> bool:
	return (
		not turn_manager.game_over
		and game_state.player.buys > 0
		and game_state.player.coins >= card.cost
	)


func _get_hand_status(card: CardDefinition) -> String:
	if turn_manager.game_over:
		return "GAME COMPLETE"
	if not card.is_playable():
		return "SCORE CARD • NOT PLAYABLE"
	if card.card_type == "action" and game_state.player.actions <= 0:
		return "NO ACTIONS LEFT"
	return "CLICK TO PLAY"


func _get_market_status(card: CardDefinition) -> String:
	if turn_manager.game_over:
		return "GAME COMPLETE"
	if game_state.player.buys <= 0:
		return "NO BUYS LEFT"
	if game_state.player.coins < card.cost:
		return "NEED %d MORE COIN%s" % [
			card.cost - game_state.player.coins,
			"" if card.cost - game_state.player.coins == 1 else "S",
		]
	return "CLICK TO BUY"


func _create_card_button(
	card: CardDefinition,
	visual_state: String,
	status_text: String
) -> Button:
	var palette := _get_card_palette(visual_state)
	var button := Button.new()
	button.custom_minimum_size = Vector2(184, 170)
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("card_id", card.id)
	button.set_meta("visual_state", visual_state)
	button.tooltip_text = "%s — %s" % [card.card_name, card.description]
	button.resized.connect(_update_card_pivot.bind(button))
	button.mouse_entered.connect(
		_on_card_mouse_entered.bind(card, button, visual_state, status_text)
	)
	button.mouse_exited.connect(_on_card_mouse_exited.bind(button))
	button.add_theme_stylebox_override(
		"normal",
		_make_card_style(palette.base, palette.border, 2)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_card_style(palette.hover, palette.border.lightened(0.18), 3)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_card_style(palette.base.darkened(0.08), palette.border, 3)
	)
	button.add_theme_stylebox_override(
		"focus",
		_make_card_style(Color.TRANSPARENT, Color("#fff0a8"), 3)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_card_style(palette.base, palette.border, 2)
	)

	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", 11)
	content.add_theme_constant_override("margin_top", 9)
	content.add_theme_constant_override("margin_right", 11)
	content.add_theme_constant_override("margin_bottom", 9)
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 3)
	content.add_child(layout)

	var state_label := Label.new()
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_label.text = status_text
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_color_override("font_color", palette.status)
	state_label.add_theme_font_size_override("font_size", 11)
	layout.add_child(state_label)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size = Vector2(0, 40)
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", palette.text)
	name_label.add_theme_font_size_override("font_size", 19)
	layout.add_child(name_label)

	var meta_label := Label.new()
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_label.text = "%s  •  COST %d" % [card.card_type.to_upper(), card.cost]
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_color_override("font_color", palette.muted)
	meta_label.add_theme_font_size_override("font_size", 12)
	layout.add_child(meta_label)

	var separator := HSeparator.new()
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(separator)

	var description_label := Label.new()
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description_label.text = card.description
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", palette.text)
	description_label.add_theme_font_size_override("font_size", 13)
	layout.add_child(description_label)
	return button


func _update_card_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_card_mouse_entered(
	card: CardDefinition,
	button: Button,
	visual_state: String,
	status_text: String
) -> void:
	_animate_card_scale(button, CARD_HOVER_SCALE)
	button.z_index = 10
	_show_card_preview(card, button, visual_state, status_text)


func _on_card_mouse_exited(button: Button) -> void:
	_animate_card_scale(button, CARD_NORMAL_SCALE)
	button.z_index = 0
	_hide_card_preview()


func _animate_card_scale(button: Button, target_scale: Vector2) -> void:
	if not is_instance_valid(button):
		return

	if button.has_meta("hover_tween"):
		var active_tween = button.get_meta("hover_tween")
		if active_tween != null and active_tween.is_valid():
			active_tween.kill()

	var tween := create_tween()
	tween.bind_node(button)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, HOVER_ANIMATION_SECONDS)
	button.set_meta("hover_tween", tween)


func _show_card_preview(
	card: CardDefinition,
	source_button: Button,
	visual_state: String,
	status_text: String
) -> void:
	var palette := _get_card_palette(visual_state)
	var is_market_card := visual_state.begins_with("market_")
	preview_location_label.text = "MARKET PREVIEW" if is_market_card else "HAND PREVIEW"
	preview_state_label.text = status_text
	preview_name_label.text = card.card_name
	preview_meta_label.text = "%s  •  COST %d" % [card.card_type.to_upper(), card.cost]
	preview_description_label.text = card.description
	preview_state_label.add_theme_color_override("font_color", palette.status)
	card_preview.add_theme_stylebox_override(
		"panel",
		_make_preview_style(palette.base, palette.border)
	)
	card_preview.position = _get_preview_position(source_button)
	card_preview.show()


func _get_preview_position(source_button: Button) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var source_rect := source_button.get_global_rect()
	var source_center := source_rect.get_center()
	var preview_x := PREVIEW_EDGE_MARGIN
	if source_center.x < viewport_size.x * 0.5:
		preview_x = viewport_size.x - PREVIEW_SIZE.x - PREVIEW_EDGE_MARGIN

	var preview_y := PREVIEW_EDGE_MARGIN + 68.0
	if source_center.y < viewport_size.y * 0.5:
		preview_y = viewport_size.y - PREVIEW_SIZE.y - PREVIEW_EDGE_MARGIN

	return Vector2(preview_x, preview_y)


func _hide_card_preview() -> void:
	card_preview.hide()


func _create_played_card_chip(card: CardDefinition) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(150, 36)
	chip.add_theme_stylebox_override(
		"panel",
		_make_card_style(Color("#302943"), Color("#8b79ad"), 1)
	)

	var label := Label.new()
	label.text = "%s  •  %s" % [card.card_name, card.card_type.capitalize()]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#eee7f7"))
	label.add_theme_font_size_override("font_size", 12)
	chip.add_child(label)
	return chip


func _get_card_palette(visual_state: String) -> Dictionary:
	match visual_state:
		HAND_PLAYABLE:
			return {
				"base": Color("#3b3153"),
				"hover": Color("#50416f"),
				"border": Color("#b69adb"),
				"status": Color("#e7d3ff"),
				"text": Color("#f5f0fa"),
				"muted": Color("#c5b8d4"),
			}
		MARKET_AFFORDABLE:
			return {
				"base": Color("#244d3d"),
				"hover": Color("#30634f"),
				"border": Color("#79d49e"),
				"status": Color("#a9f5c6"),
				"text": Color("#f0f8ef"),
				"muted": Color("#b5cbbd"),
			}
		MARKET_UNAFFORDABLE:
			return {
				"base": Color("#302c28"),
				"hover": Color("#302c28"),
				"border": Color("#715f52"),
				"status": Color("#d6a88f"),
				"text": Color("#c8c0b9"),
				"muted": Color("#928a83"),
			}
		_:
			return {
				"base": Color("#292b31"),
				"hover": Color("#292b31"),
				"border": Color("#5b606a"),
				"status": Color("#b5bac4"),
				"text": Color("#c6c9cf"),
				"muted": Color("#858a94"),
			}


func _make_card_style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 3
	return style


func _make_preview_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style := _make_card_style(color.darkened(0.08), border_color.lightened(0.1), 3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 16
	return style


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_hand_card_pressed(card: CardDefinition) -> void:
	if game_state.play_card(card):
		status_label.text = "Played %s. Its effects have been applied." % card.card_name
	else:
		status_label.text = "That card cannot be played right now."
	_refresh_ui()


func _on_market_card_pressed(card: CardDefinition) -> void:
	if game_state.buy_card(card):
		status_label.text = "Bought %s. It is now in your discard pile." % card.card_name
	else:
		status_label.text = "That card requires enough coins and an available buy."
	_refresh_ui()


func _on_end_turn_pressed() -> void:
	turn_manager.end_turn()
	if turn_manager.game_over:
		status_label.text = "Game complete — final score: %d victory points." % turn_manager.final_score
	else:
		status_label.text = "Turn %d started. Your hand and turn resources have refreshed." % (
			turn_manager.turn_number
		)
	_refresh_ui()


func _on_new_game_pressed() -> void:
	_start_new_game(true)
