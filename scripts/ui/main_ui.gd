extends Control

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

const HAND_PLAYABLE := "hand_playable"
const HAND_UNPLAYABLE := "hand_unplayable"
const MARKET_AFFORDABLE := "market_affordable"
const MARKET_UNAFFORDABLE := "market_unaffordable"
const CARD_HOVER_SCALE := Vector2(1.025, 1.025)
const CARD_NORMAL_SCALE := Vector2.ONE
const HOVER_ANIMATION_SECONDS := 0.08
const CARD_MOVE_SECONDS := 0.18
const CARD_DRAW_SECONDS := 0.16
const CLEANUP_SECONDS := 0.2
const PREVIEW_SIZE := Vector2(360, 500)
const PREVIEW_EDGE_MARGIN := 24.0

const COLOR_PARCHMENT := Color("#e4d2aa")
const COLOR_PARCHMENT_LIGHT := Color("#f3e8ca")
const COLOR_CARD_BROWN := Color("#4a3021")
const COLOR_CARD_BROWN_LIGHT := Color("#5a3a28")
const COLOR_RESOURCE_CARD := Color("#51351f")
const COLOR_ACTION_CARD := Color("#40332e")
const COLOR_VICTORY_CARD := Color("#482b31")
const COLOR_WALNUT := Color("#352218")
const COLOR_WALNUT_DARK := Color("#21140f")
const COLOR_BRASS := Color("#b58a45")
const COLOR_FOREST := Color("#294638")
const COLOR_OXBLOOD := Color("#713a32")
const COLOR_SLATE := Color("#43566a")
const COLOR_INK := Color("#30251d")
const COLOR_UNAVAILABLE := Color("#796d5f")

const TITLE_FONT_PATH := "res://assets/fonts/Cinzel/static/Cinzel-SemiBold.ttf"
const BODY_FONT_PATH := "res://assets/fonts/Inter/static/Inter_18pt-Regular.ttf"
const BODY_BOLD_FONT_PATH := "res://assets/fonts/Inter/static/Inter_18pt-Bold.ttf"
const UI_ASSET_PATHS := {
	"hud": "res://assets/ui/hud_frame.svg",
	"market": "res://assets/ui/market_frame.svg",
	"hand": "res://assets/ui/hand_frame.svg",
	"card": "res://assets/ui/card_frame.svg",
	"button": "res://assets/ui/button_standard.svg",
	"button_primary": "res://assets/ui/button_primary.svg",
	"preview": "res://assets/ui/preview_frame.svg",
	"endgame": "res://assets/ui/endgame_frame.svg",
}
const ICON_BASE_PATH := (
	"res://assets/imported/kenney_board-game-icons/PNG/Default (64px)/"
)
const ICON_PATHS := {
	"coin": ICON_BASE_PATH + "dollar.png",
	"action": ICON_BASE_PATH + "hand.png",
	"buy": ICON_BASE_PATH + "pouch.png",
	"deck": ICON_BASE_PATH + "cards_stack.png",
	"discard": ICON_BASE_PATH + "cards_return.png",
	"victory": ICON_BASE_PATH + "award.png",
}
const SOUND_PATHS := {
	"button_click": "res://assets/audio/kenney_ui-audio/Audio/click3.ogg",
	"hover": "res://assets/audio/kenney_ui-audio/Audio/rollover2.ogg",
	"play_card": "res://assets/audio/kenney_interface-sounds/Audio/drop_001.ogg",
	"buy_card": "res://assets/audio/kenney_interface-sounds/Audio/confirmation_001.ogg",
	"end_turn": "res://assets/audio/kenney_interface-sounds/Audio/switch_003.ogg",
	"draw": "res://assets/audio/kenney_interface-sounds/Audio/open_002.ogg",
	"discard": "res://assets/audio/kenney_interface-sounds/Audio/close_002.ogg",
	"game_end": "res://assets/audio/kenney_interface-sounds/Audio/confirmation_004.ogg",
}

var game_state := GameState.new()
var turn_manager := TurnManager.new()
var title_font: Font
var body_font: Font
var body_bold_font: Font
var ui_textures: Dictionary = {}
var icon_textures: Dictionary = {}
var ui_sound_players: Dictionary = {}
var last_ui_sound_name: String = ""
var last_animation_event: String = ""
var card_art_cache: Dictionary = {}
var current_choice: CardChoice
var selected_choice_tokens: Array[String] = []
var choice_buttons: Dictionary = {}

@onready var turn_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/TurnStat/Value
@onready var deck_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/DeckStat/ValueRow/Value
@onready var discard_label: Label = (
	$Margin/Layout/HudPanel/HudMargin/Hud/DiscardStat/ValueRow/Value
)
@onready var coin_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/CoinStat/ValueRow/Value
@onready var action_label: Label = (
	$Margin/Layout/HudPanel/HudMargin/Hud/ActionStat/ValueRow/Value
)
@onready var buy_label: Label = $Margin/Layout/HudPanel/HudMargin/Hud/BuyStat/ValueRow/Value
@onready var new_game_button: Button = $Margin/Layout/HudPanel/HudMargin/Hud/NewGameButton
@onready var end_turn_button: Button = $Margin/Layout/HudPanel/HudMargin/Hud/EndTurnButton
@onready var hud_panel: PanelContainer = $Margin/Layout/HudPanel
@onready var market_panel: PanelContainer = $Margin/Layout/MarketPanel
@onready var play_area_panel: PanelContainer = $Margin/Layout/PlayAreaPanel
@onready var hand_panel: PanelContainer = $Margin/Layout/HandPanel
@onready var market_container: HBoxContainer = (
	$Margin/Layout/MarketPanel/MarketMargin/MarketScroll/MarketContainer
)
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
@onready var animation_layer: Control = $AnimationLayer
@onready var choice_overlay: Control = $ChoiceOverlay
@onready var choice_panel: PanelContainer = $ChoiceOverlay/Center/Panel
@onready var choice_prompt_label: Label = (
	$ChoiceOverlay/Center/Panel/Margin/Layout/Prompt
)
@onready var choice_selection_label: Label = (
	$ChoiceOverlay/Center/Panel/Margin/Layout/SelectionLabel
)
@onready var choice_options: HBoxContainer = (
	$ChoiceOverlay/Center/Panel/Margin/Layout/OptionsScroll/Options
)
@onready var choice_skip_button: Button = (
	$ChoiceOverlay/Center/Panel/Margin/Layout/Buttons/SkipButton
)
@onready var choice_confirm_button: Button = (
	$ChoiceOverlay/Center/Panel/Margin/Layout/Buttons/ConfirmButton
)
@onready var end_game_overlay: Control = $EndGameOverlay
@onready var end_game_panel: PanelContainer = $EndGameOverlay/Center/Panel
@onready var final_score_label: Label = (
	$EndGameOverlay/Center/Panel/Margin/Layout/ScoreRow/ScoreLabel
)
@onready var final_victory_icon: TextureRect = (
	$EndGameOverlay/Center/Panel/Margin/Layout/ScoreRow/VictoryIcon
)
@onready var play_again_button: Button = (
	$EndGameOverlay/Center/Panel/Margin/Layout/PlayAgainButton
)
@onready var card_preview: PanelContainer = $CardPreview
@onready var preview_name_label: Label = $CardPreview/Margin/Layout/NameLabel
@onready var preview_meta_label: Label = $CardPreview/Margin/Layout/MetaLabel
@onready var preview_art_frame: PanelContainer = $CardPreview/Margin/Layout/ArtFrame
@onready var preview_art: TextureRect = $CardPreview/Margin/Layout/ArtFrame/Art
@onready var preview_effect_label: RichTextLabel = $CardPreview/Margin/Layout/EffectLabel
@onready var preview_description_label: RichTextLabel = (
	$CardPreview/Margin/Layout/DescriptionLabel
)


func _ready() -> void:
	_load_optional_assets()
	_apply_imported_theme()
	new_game_button.pressed.connect(_on_new_game_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	choice_skip_button.pressed.connect(_on_choice_skipped)
	choice_confirm_button.pressed.connect(_on_choice_confirmed)
	new_game_button.mouse_entered.connect(_on_hud_button_hovered.bind(new_game_button))
	new_game_button.mouse_exited.connect(_on_hud_button_unhovered.bind(new_game_button))
	end_turn_button.mouse_entered.connect(_on_hud_button_hovered.bind(end_turn_button))
	end_turn_button.mouse_exited.connect(_on_hud_button_unhovered.bind(end_turn_button))
	play_again_button.mouse_entered.connect(_on_hud_button_hovered.bind(play_again_button))
	play_again_button.mouse_exited.connect(_on_hud_button_unhovered.bind(play_again_button))
	choice_skip_button.mouse_entered.connect(_on_hud_button_hovered.bind(choice_skip_button))
	choice_skip_button.mouse_exited.connect(_on_hud_button_unhovered.bind(choice_skip_button))
	choice_confirm_button.mouse_entered.connect(
		_on_hud_button_hovered.bind(choice_confirm_button)
	)
	choice_confirm_button.mouse_exited.connect(
		_on_hud_button_unhovered.bind(choice_confirm_button)
	)
	game_state.choice_requested.connect(_on_choice_requested)
	game_state.choice_resolved.connect(_on_choice_resolved)
	turn_manager.configure(game_state)

	if not game_state.load_cards(CARD_DATA_PATH):
		push_error("Could not load card data from %s." % CARD_DATA_PATH)
		new_game_button.disabled = true
		end_turn_button.disabled = true
		return

	_start_new_game(false)


func _start_new_game(_is_restart: bool) -> void:
	_hide_end_game_overlay()
	_hide_choice_overlay()
	_clear_animation_layer()
	if not game_state.setup_starting_game():
		push_error("Could not prepare a new game.")
		end_turn_button.disabled = true
		return

	turn_manager.start_first_turn()
	_refresh_ui()
	call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _load_optional_assets() -> void:
	title_font = _load_optional_font(TITLE_FONT_PATH)
	body_font = _load_optional_font(BODY_FONT_PATH)
	body_bold_font = _load_optional_font(BODY_BOLD_FONT_PATH)
	for asset_name in UI_ASSET_PATHS:
		var ui_texture := _load_optional_texture(UI_ASSET_PATHS[asset_name])
		if ui_texture != null:
			ui_textures[asset_name] = ui_texture

	for icon_name in ICON_PATHS:
		var texture := _load_optional_texture(ICON_PATHS[icon_name])
		if texture != null:
			icon_textures[icon_name] = texture

	for sound_name in SOUND_PATHS:
		if not ResourceLoader.exists(SOUND_PATHS[sound_name]):
			continue
		var stream := load(SOUND_PATHS[sound_name]) as AudioStream
		if stream == null:
			continue
		var player := AudioStreamPlayer.new()
		player.name = "UISound_%s" % sound_name
		player.stream = stream
		player.volume_db = -9.0
		add_child(player)
		ui_sound_players[sound_name] = player


func _load_optional_font(path: String) -> Font:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Font


func _load_optional_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _apply_imported_theme() -> void:
	if body_font != null:
		_apply_body_font_recursive(self)
		preview_effect_label.add_theme_font_override("normal_font", body_font)
		preview_description_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		preview_effect_label.add_theme_font_override("bold_font", body_bold_font)

	if title_font != null:
		var title_paths := [
			"Margin/Layout/HudPanel/HudMargin/Hud/Brand/Title",
			"Margin/Layout/MarketHeader/Title",
			"Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaLabel",
			"Margin/Layout/HandHeader/Title",
			"CardPreview/Margin/Layout/NameLabel",
			"ChoiceOverlay/Center/Panel/Margin/Layout/Title",
			"EndGameOverlay/Center/Panel/Margin/Layout/Title",
			"EndGameOverlay/Center/Panel/Margin/Layout/ScoreRow/ScoreLabel",
		]
		for path in title_paths:
			var label := get_node_or_null(path) as Label
			if label != null:
				label.add_theme_font_override("font", title_font)

	_apply_original_ui_assets()
	_apply_scene_colors()

	_set_hud_icon("CoinStat", "coin", COLOR_BRASS.lightened(0.18))
	_set_hud_icon("ActionStat", "action", COLOR_SLATE.lightened(0.32))
	_set_hud_icon("BuyStat", "buy", COLOR_FOREST.lightened(0.34))
	_set_hud_icon("DeckStat", "deck", COLOR_PARCHMENT_LIGHT)
	_set_hud_icon("DiscardStat", "discard", COLOR_PARCHMENT)
	if icon_textures.has("victory"):
		final_victory_icon.texture = icon_textures["victory"]
		final_victory_icon.modulate = COLOR_BRASS.lightened(0.24)
	else:
		final_victory_icon.hide()


func _apply_original_ui_assets() -> void:
	if ui_textures.has("hud"):
		hud_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(ui_textures["hud"], 18.0, 14.0)
		)
	if ui_textures.has("market"):
		market_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(ui_textures["market"], 18.0, 12.0)
		)
	if ui_textures.has("hand"):
		hand_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(ui_textures["hand"], 18.0, 12.0)
		)
	play_area_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.12, 0.075, 0.05, 0.72), COLOR_BRASS.darkened(0.25), 1)
	)
	if ui_textures.has("endgame"):
		end_game_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(ui_textures["endgame"], 22.0, 18.0)
		)
		choice_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(ui_textures["endgame"], 22.0, 18.0)
		)
	if ui_textures.has("button"):
		_apply_button_asset_styles(new_game_button, ui_textures["button"])
	if ui_textures.has("button_primary"):
		_apply_button_asset_styles(end_turn_button, ui_textures["button_primary"])
		_apply_button_asset_styles(play_again_button, ui_textures["button_primary"])


func _apply_scene_colors() -> void:
	var cream_paths := [
		"Margin/Layout/HudPanel/HudMargin/Hud/Brand/Title",
		"Margin/Layout/HudPanel/HudMargin/Hud/TurnStat/Value",
		"Margin/Layout/MarketHeader/Title",
		"Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaLabel",
		"Margin/Layout/HandHeader/Title",
		"ChoiceOverlay/Center/Panel/Margin/Layout/Title",
		"EndGameOverlay/Center/Panel/Margin/Layout/Title",
		"EndGameOverlay/Center/Panel/Margin/Layout/SummaryLabel",
	]
	for path in cream_paths:
		var label := get_node_or_null(path) as Label
		if label != null:
			label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	var muted_paths := [
		"Margin/Layout/HudPanel/HudMargin/Hud/Brand/Subtitle",
		"Margin/Layout/MarketHeader/Hint",
		"Margin/Layout/HandHeader/HandCount",
		"Margin/Layout/HandHeader/Hint",
		"ChoiceOverlay/Center/Panel/Margin/Layout/SelectionLabel",
		"EndGameOverlay/Center/Panel/Margin/Layout/Caption",
	]
	for path in muted_paths:
		var label := get_node_or_null(path) as Label
		if label != null:
			label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.2))
	preview_name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	preview_meta_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.18))
	preview_effect_label.add_theme_color_override("default_color", COLOR_PARCHMENT_LIGHT)
	preview_description_label.add_theme_color_override(
		"default_color",
		COLOR_PARCHMENT.darkened(0.08)
	)
	choice_prompt_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	final_score_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.22))


func _apply_body_font_recursive(node: Node) -> void:
	if node is Label:
		(node as Label).add_theme_font_override("font", body_font)
	elif node is Button:
		(node as Button).add_theme_font_override("font", body_font)
	for child in node.get_children():
		_apply_body_font_recursive(child)


func _set_hud_icon(stat_name: String, icon_name: String, color: Color) -> void:
	var icon := get_node_or_null(
		"Margin/Layout/HudPanel/HudMargin/Hud/%s/ValueRow/Icon" % stat_name
	) as TextureRect
	if icon == null:
		return
	if not icon_textures.has(icon_name):
		icon.hide()
		return
	icon.texture = icon_textures[icon_name]
	icon.modulate = color
	icon.show()


func _apply_button_asset_styles(button: Button, texture: Texture2D) -> void:
	button.add_theme_stylebox_override(
		"normal",
		_make_asset_style(texture, 16.0, 10.0)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_asset_style(texture, 16.0, 10.0, Color(1.12, 1.08, 0.94, 1.0))
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_asset_style(texture, 16.0, 10.0, Color(0.84, 0.84, 0.84, 1.0))
	)


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
	end_turn_button.disabled = turn_manager.game_over or game_state.has_pending_choice()
	new_game_button.disabled = game_state.has_pending_choice()

	_refresh_hand()
	_refresh_market()
	_refresh_play_area()


func _refresh_hand() -> void:
	_clear_container(hand_container)
	for card in game_state.player.hand:
		var playable := _can_play_card(card)
		var visual_state := HAND_PLAYABLE if playable else HAND_UNPLAYABLE
		var button := _create_card_button(card, visual_state)
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
		var visual_state := MARKET_AFFORDABLE if affordable else MARKET_UNAFFORDABLE
		var button := _create_card_button(card, visual_state)
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
		empty_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.28))
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		play_area_container.add_child(empty_label)
		return

	for card in played_cards:
		play_area_container.add_child(_create_played_card_chip(card))


func _can_play_card(card: CardDefinition) -> bool:
	if turn_manager.game_over or game_state.has_pending_choice() or not card.is_playable():
		return false
	if card.card_type == "action" and game_state.player.actions <= 0:
		return false
	return true


func _can_buy_card(card: CardDefinition) -> bool:
	return (
		not turn_manager.game_over
		and not game_state.has_pending_choice()
		and game_state.player.buys > 0
		and game_state.player.coins >= card.cost
		and game_state.get_supply_count(card.id) > 0
	)


func _create_card_button(
	card: CardDefinition,
	visual_state: String
) -> Button:
	var palette := _get_card_palette(visual_state)
	var card_surface := _get_card_surface_color(card.card_type)
	var button := Button.new()
	button.custom_minimum_size = Vector2(164, 208)
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("card_id", card.id)
	button.set_meta("visual_state", visual_state)
	button.set_meta("card_base_color", card_surface)
	button.set_meta("card_type", card.card_type)
	button.set_meta("card_accent_color", palette.border)
	button.set_meta("supply_count", game_state.get_supply_count(card.id))
	button.tooltip_text = "%s — %s" % [card.card_name, card.description]
	if visual_state.begins_with("market_"):
		button.tooltip_text += "\n%d cards remain in this pile." % game_state.get_supply_count(card.id)
	button.resized.connect(_update_card_pivot.bind(button))
	button.mouse_entered.connect(
		_on_card_mouse_entered.bind(card, button, visual_state)
	)
	button.mouse_exited.connect(_on_card_mouse_exited.bind(button))
	button.add_theme_stylebox_override(
		"normal",
		_make_card_style(card_surface, palette.border, 3)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_card_style(card_surface.lightened(0.1), palette.border.lightened(0.14), 4)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_card_style(card_surface.darkened(0.08), palette.border, 4)
	)
	button.add_theme_stylebox_override(
		"focus",
		_make_card_style(Color.TRANSPARENT, COLOR_BRASS.lightened(0.28), 4)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_card_style(card_surface.darkened(0.12), palette.border, 3)
	)

	if ui_textures.has("card"):
		var ornament := TextureRect.new()
		ornament.name = "MedievalFrame"
		ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ornament.texture = ui_textures["card"]
		ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ornament.stretch_mode = TextureRect.STRETCH_SCALE
		button.add_child(ornament)
		ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var content := MarginContainer.new()
	content.name = "CardContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", 11)
	content.add_theme_constant_override("margin_top", 7)
	content.add_theme_constant_override("margin_right", 11)
	content.add_theme_constant_override("margin_bottom", 7)
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.name = "CardLayout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 3)
	content.add_child(layout)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.custom_minimum_size = Vector2(0, 28)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", palette.text)
	name_label.add_theme_font_size_override("font_size", 14)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	layout.add_child(name_label)

	# Card art window: the picture sits in a framed box, like a tabletop card.
	var art_texture := _load_card_texture(card.art_id)
	if art_texture != null:
		var art_frame := PanelContainer.new()
		art_frame.name = "ArtFrame"
		art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_frame.clip_contents = true
		art_frame.custom_minimum_size = Vector2(0, 108)
		art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_frame.add_theme_stylebox_override(
			"panel",
			_make_flat_card_style(COLOR_WALNUT_DARK, palette.border, 2)
		)
		var art_rect := TextureRect.new()
		art_rect.name = "Art"
		art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_rect.texture = art_texture
		art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_frame.add_child(art_rect)
		layout.add_child(art_frame)

	var effect_label := RichTextLabel.new()
	effect_label.name = "EffectLabel"
	effect_label.custom_minimum_size = Vector2(0, 32)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_label.bbcode_enabled = true
	effect_label.fit_content = false
	effect_label.scroll_active = false
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.text = "[center][b]%s[/b][/center]" % _get_card_effect_text(card)
	effect_label.add_theme_color_override("default_color", palette.text)
	effect_label.add_theme_font_size_override("normal_font_size", 11)
	effect_label.add_theme_font_size_override("bold_font_size", 11)
	if body_font != null:
		effect_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		effect_label.add_theme_font_override("bold_font", body_bold_font)
	layout.add_child(effect_label)

	# Footer: cost and type along the bottom edge.
	var meta_row := HBoxContainer.new()
	meta_row.name = "MetaRow"
	meta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_row.add_theme_constant_override("separation", 4)
	layout.add_child(meta_row)

	var type_label := Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.text = card.card_type.to_upper()
	type_label.add_theme_color_override("font_color", palette.muted)
	type_label.add_theme_font_size_override("font_size", 12)
	if body_font != null:
		type_label.add_theme_font_override("font", body_font)
	meta_row.add_child(type_label)

	if icon_textures.has("coin"):
		meta_row.add_child(_create_icon(icon_textures["coin"], Vector2(14, 14), palette.muted))
		var cost_label := Label.new()
		cost_label.text = str(card.cost)
		cost_label.add_theme_color_override("font_color", palette.muted)
		cost_label.add_theme_font_size_override("font_size", 12)
		if body_font != null:
			cost_label.add_theme_font_override("font", body_font)
		meta_row.add_child(cost_label)
	else:
		type_label.text += "  |  COST %d" % card.cost

	if card.victory_points > 0 or card.score_per_cards > 0:
		if icon_textures.has("victory"):
			meta_row.add_child(
				_create_icon(icon_textures["victory"], Vector2(14, 14), COLOR_BRASS)
			)
		var victory_label := Label.new()
		victory_label.text = (
			"%d VP" % card.victory_points
			if card.victory_points > 0
			else "VP / %d" % card.score_per_cards
		)
		victory_label.add_theme_color_override("font_color", COLOR_OXBLOOD)
		victory_label.add_theme_font_size_override("font_size", 12)
		if body_font != null:
			victory_label.add_theme_font_override("font", body_font)
		meta_row.add_child(victory_label)

	if visual_state.begins_with("market_"):
		var pile_label := Label.new()
		pile_label.name = "PileLabel"
		pile_label.text = "×%d" % game_state.get_supply_count(card.id)
		pile_label.add_theme_color_override(
			"font_color",
			COLOR_OXBLOOD if game_state.get_supply_count(card.id) <= 0 else palette.muted
		)
		pile_label.add_theme_font_size_override("font_size", 12)
		if body_bold_font != null:
			pile_label.add_theme_font_override("font", body_bold_font)
		meta_row.add_child(pile_label)

	return button


func _get_card_effect_text(card: CardDefinition) -> String:
	var effects: Array[String] = []
	_append_effect(effects, card.draw_cards, "Card", "Cards")
	_append_effect(effects, card.gain_actions, "Action", "Actions")
	_append_effect(effects, card.coin_value + card.gain_coins, "Coin", "Coins")
	_append_effect(effects, card.gain_buys, "Buy", "Buys")
	if card.victory_points > 0:
		effects.append("%d VP" % card.victory_points)
	if card.score_per_cards > 0:
		effects.append("1 VP / %d Cards" % card.score_per_cards)
	for effect in card.special_effects:
		var label := str(effect.get("label", ""))
		if not label.is_empty():
			effects.append(label)
	return "  ".join(effects)


func _append_effect(effects: Array[String], amount: int, singular: String, plural: String) -> void:
	if amount <= 0:
		return
	effects.append("+%d %s" % [amount, singular if amount == 1 else plural])


func _create_icon(texture: Texture2D, size: Vector2, color: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = texture
	icon.modulate = color
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _load_card_texture(card_id: String) -> Texture2D:
	if card_art_cache.has(card_id):
		return card_art_cache[card_id]
	var path := "res://assets/cards/%s.png" % card_id
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			texture = ImageTexture.create_from_image(image)
	card_art_cache[card_id] = texture
	return texture


func _update_card_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_card_mouse_entered(
	card: CardDefinition,
	button: Button,
	visual_state: String
) -> void:
	_play_ui_sound("hover")
	_animate_card_scale(button, CARD_HOVER_SCALE)
	button.z_index = 10
	_show_card_preview(card, button, visual_state)


func _on_card_mouse_exited(button: Button) -> void:
	_animate_card_scale(button, CARD_NORMAL_SCALE)
	button.z_index = 0
	_hide_card_preview()


func _on_hud_button_hovered(button: Button) -> void:
	_play_ui_sound("hover")
	_animate_control_scale(button, Vector2(1.035, 1.035), HOVER_ANIMATION_SECONDS)


func _on_hud_button_unhovered(button: Button) -> void:
	_animate_control_scale(button, Vector2.ONE, HOVER_ANIMATION_SECONDS)


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


func _animate_control_scale(control: Control, target_scale: Vector2, duration: float) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.bind_node(control)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", target_scale, duration)


func _show_card_preview(
	card: CardDefinition,
	source_button: Button,
	visual_state: String
) -> void:
	var palette := _get_card_palette(visual_state)
	preview_name_label.text = card.card_name
	preview_meta_label.text = "%s  |  COST %d" % [card.card_type.to_upper(), card.cost]
	if visual_state.begins_with("market_"):
		preview_meta_label.text += "  |  %d LEFT" % game_state.get_supply_count(card.id)
	card_preview.set_meta("card_type", card.card_type)
	card_preview.set_meta("card_base_color", _get_card_surface_color(card.card_type))
	preview_art.texture = _load_card_texture(card.art_id)
	preview_art_frame.visible = preview_art.texture != null
	preview_art_frame.add_theme_stylebox_override(
		"panel",
		_make_flat_card_style(COLOR_WALNUT_DARK, palette.border, 2)
	)
	preview_effect_label.text = (
		"[center][b]%s[/b][/center]" % _get_card_effect_text(card)
	)
	preview_description_label.text = "[center]%s[/center]" % card.description
	preview_effect_label.add_theme_color_override("default_color", COLOR_PARCHMENT_LIGHT)
	card_preview.add_theme_stylebox_override(
		"panel",
		_make_preview_style(_get_card_surface_color(card.card_type), palette.border)
	)
	card_preview.position = _get_preview_position(source_button)
	card_preview.show()


func _get_preview_position(source_button: Button) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var preview_size := Vector2(
		maxf(PREVIEW_SIZE.x, card_preview.size.x),
		maxf(PREVIEW_SIZE.y, card_preview.size.y)
	)
	var source_rect := source_button.get_global_rect()
	var source_center := source_rect.get_center()
	var preview_x := PREVIEW_EDGE_MARGIN
	if source_center.x < viewport_size.x * 0.5:
		preview_x = viewport_size.x - preview_size.x - PREVIEW_EDGE_MARGIN

	var preview_y := PREVIEW_EDGE_MARGIN + 68.0
	if source_center.y < viewport_size.y * 0.5:
		preview_y = viewport_size.y - preview_size.y - PREVIEW_EDGE_MARGIN

	return Vector2(
		clampf(
			preview_x,
			PREVIEW_EDGE_MARGIN,
			viewport_size.x - preview_size.x - PREVIEW_EDGE_MARGIN
		),
		clampf(
			preview_y,
			PREVIEW_EDGE_MARGIN,
			viewport_size.y - preview_size.y - PREVIEW_EDGE_MARGIN
		)
	)


func _hide_card_preview() -> void:
	card_preview.hide()


func _create_played_card_chip(card: CardDefinition) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(150, 36)
	chip.set_meta("card_id", card.id)
	chip.add_theme_stylebox_override(
		"panel",
		_make_panel_style(COLOR_WALNUT, COLOR_BRASS.darkened(0.12), 2)
	)

	var label := Label.new()
	label.text = "%s  •  %s" % [card.card_name, card.card_type.capitalize()]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	label.add_theme_font_size_override("font_size", 12)
	chip.add_child(label)
	return chip


func _get_card_palette(visual_state: String) -> Dictionary:
	match visual_state:
		HAND_PLAYABLE:
			return {
				"border": COLOR_SLATE,
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.darkened(0.12),
			}
		MARKET_AFFORDABLE:
			return {
				"border": COLOR_FOREST,
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.darkened(0.12),
			}
		MARKET_UNAFFORDABLE:
			return {
				"border": COLOR_UNAVAILABLE,
				"text": COLOR_PARCHMENT.darkened(0.12),
				"muted": COLOR_PARCHMENT.darkened(0.28),
			}
		_:
			return {
				"border": COLOR_UNAVAILABLE.darkened(0.12),
				"text": COLOR_PARCHMENT.darkened(0.12),
				"muted": COLOR_PARCHMENT.darkened(0.28),
			}


func _get_card_surface_color(card_type: String) -> Color:
	match card_type:
		"resource":
			return COLOR_RESOURCE_CARD
		"victory":
			return COLOR_VICTORY_CARD
		_:
			return COLOR_ACTION_CARD


func _make_card_style(color: Color, border_color: Color, border_width: int) -> StyleBox:
	var style := _make_flat_card_style(color, border_color, border_width)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	return style


func _make_flat_card_style(
	color: Color,
	border_color: Color,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 3
	return style


func _make_panel_style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := _make_flat_card_style(color, border_color, border_width)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 7
	return style


func _make_preview_style(surface_color: Color, border_color: Color) -> StyleBox:
	if ui_textures.has("preview"):
		return _make_asset_style(
			ui_textures["preview"],
			22.0,
			18.0,
			_get_preview_type_modulate(surface_color)
		)
	var style := _make_flat_card_style(surface_color, border_color, 3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 16
	return style


func _get_preview_type_modulate(surface_color: Color) -> Color:
	return Color(
		clampf(surface_color.r / COLOR_CARD_BROWN.r, 0.82, 1.12),
		clampf(surface_color.g / COLOR_CARD_BROWN.g, 0.82, 1.12),
		clampf(surface_color.b / COLOR_CARD_BROWN.b, 0.82, 1.12),
		1.0
	)


func _make_asset_style(
	texture: Texture2D,
	texture_margin: float,
	content_margin: float,
	modulate: Color = Color.WHITE
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = modulate
	style.texture_margin_left = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_bottom = texture_margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style


func _create_moving_card(
	card: CardDefinition,
	source_rect: Rect2,
	color: Color
) -> PanelContainer:
	var ghost := PanelContainer.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 1
	ghost.position = source_rect.position
	ghost.size = source_rect.size
	ghost.pivot_offset = source_rect.size * 0.5
	ghost.add_theme_stylebox_override(
		"panel",
		_make_card_style(color, color.lightened(0.35), 2)
	)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = card.card_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	label.add_theme_font_size_override("font_size", 16)
	if title_font != null:
		label.add_theme_font_override("font", title_font)
	ghost.add_child(label)
	animation_layer.add_child(ghost)
	return ghost


func _animate_moving_card(
	ghost: Control,
	target_center: Vector2,
	duration: float,
	target_scale: Vector2 = Vector2(0.34, 0.34)
) -> void:
	var target_position := target_center - ghost.size * 0.5
	var tween := create_tween()
	tween.bind_node(ghost)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(ghost, "position", target_position, duration)
	tween.tween_property(ghost, "scale", target_scale, duration)
	tween.tween_property(ghost, "rotation", 0.06, duration)
	tween.tween_property(ghost, "modulate:a", 0.15, duration)
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)


func _capture_cleanup_cards() -> Array[Control]:
	var ghosts: Array[Control] = []
	for child in hand_container.get_children():
		if not child.has_meta("card_id"):
			continue
		var card_id := str(child.get_meta("card_id"))
		if not game_state.card_catalog.has(card_id):
			continue
		ghosts.append(
			_create_moving_card(
				game_state.card_catalog[card_id],
				(child as Control).get_global_rect(),
				COLOR_SLATE.darkened(0.18)
			)
		)

	for child in play_area_container.get_children():
		if not child.has_meta("card_id"):
			continue
		var card_id := str(child.get_meta("card_id"))
		if not game_state.card_catalog.has(card_id):
			continue
		ghosts.append(
			_create_moving_card(
				game_state.card_catalog[card_id],
				(child as Control).get_global_rect(),
				COLOR_SLATE.darkened(0.18)
			)
		)
	return ghosts


func _animate_cleanup_cards(ghosts: Array[Control]) -> void:
	if ghosts.is_empty():
		return
	last_animation_event = "discard"
	_play_ui_sound("discard")
	var target := _get_hud_target_center("DiscardStat")
	for ghost in ghosts:
		_animate_moving_card(
			ghost,
			target,
			CLEANUP_SECONDS,
			Vector2(0.22, 0.22)
		)
	_pulse_control(discard_label, COLOR_BRASS.lightened(0.24))


func _animate_draw_cards(card_count: int) -> void:
	if card_count <= 0 or hand_container.get_child_count() == 0:
		return
	last_animation_event = "draw"
	_play_ui_sound("draw")
	var source := _get_hud_target_center("DeckStat")
	var first_index := maxi(0, hand_container.get_child_count() - card_count)
	for index in range(first_index, hand_container.get_child_count()):
		var target_button := hand_container.get_child(index) as Control
		if target_button == null or not target_button.has_meta("card_id"):
			continue
		var card_id := str(target_button.get_meta("card_id"))
		if not game_state.card_catalog.has(card_id):
			continue
		var source_rect := Rect2(source - Vector2(24, 34), Vector2(48, 68))
		var ghost := _create_moving_card(
			game_state.card_catalog[card_id],
			source_rect,
			COLOR_SLATE
		)
		ghost.scale = Vector2(0.35, 0.35)
		ghost.modulate.a = 0.35
		_animate_draw_ghost(
			ghost,
			target_button.get_global_rect(),
			CARD_DRAW_SECONDS
		)
	_pulse_control(deck_label, COLOR_PARCHMENT_LIGHT)


func _animate_draw_ghost(ghost: Control, target_rect: Rect2, duration: float) -> void:
	var tween := create_tween()
	tween.bind_node(ghost)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(ghost, "position", target_rect.position, duration)
	tween.tween_property(ghost, "size", target_rect.size, duration)
	tween.tween_property(ghost, "scale", Vector2.ONE, duration)
	tween.tween_property(ghost, "modulate:a", 0.85, duration)
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)


func _get_hud_target_center(stat_name: String) -> Vector2:
	var stat := get_node(
		"Margin/Layout/HudPanel/HudMargin/Hud/%s" % stat_name
	) as Control
	return stat.get_global_rect().get_center()


func _pulse_control(control: Control, color: Color) -> void:
	var original_color := control.modulate
	control.modulate = color
	control.scale = Vector2(1.08, 1.08)
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.bind_node(control)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, 0.16)
	tween.tween_property(control, "modulate", original_color, 0.2)


func _clear_animation_layer() -> void:
	for child in animation_layer.get_children():
		child.queue_free()


func _play_ui_sound(sound_name: String) -> void:
	if not ui_sound_players.has(sound_name):
		return
	var player: AudioStreamPlayer = ui_sound_players[sound_name]
	last_ui_sound_name = sound_name
	player.stop()
	player.play()


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_choice_requested(choice: CardChoice) -> void:
	current_choice = choice
	selected_choice_tokens.clear()
	choice_buttons.clear()
	_clear_container(choice_options)
	_hide_card_preview()
	card_preview.z_index = 180
	choice_prompt_label.text = choice.prompt
	choice_confirm_button.text = choice.confirm_text
	choice_skip_button.text = choice.skip_text

	for candidate in choice.candidates:
		var card: CardDefinition = candidate["card"]
		var token := str(candidate.get("token", ""))
		var visual_state := (
			MARKET_AFFORDABLE
			if token.begins_with("supply:")
			else HAND_PLAYABLE
		)
		var button := _create_card_button(card, visual_state)
		button.set_meta("choice_token", token)
		button.set_meta("choice_selected", false)
		button.disabled = false
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_choice_card_pressed.bind(token))
		choice_options.add_child(button)
		choice_buttons[token] = button

	choice_overlay.show()
	_refresh_choice_controls()
	_refresh_ui()


func _on_choice_resolved(choice_id: int) -> void:
	if current_choice != null and current_choice.id != choice_id:
		return
	_hide_choice_overlay()


func _hide_choice_overlay() -> void:
	choice_overlay.hide()
	card_preview.z_index = 100
	current_choice = null
	selected_choice_tokens.clear()
	choice_buttons.clear()
	_clear_container(choice_options)


func _on_choice_card_pressed(token: String) -> void:
	if current_choice == null:
		return
	if selected_choice_tokens.has(token):
		selected_choice_tokens.erase(token)
	else:
		if current_choice.maximum == 1:
			selected_choice_tokens.clear()
		elif selected_choice_tokens.size() >= current_choice.maximum:
			return
		selected_choice_tokens.append(token)
	_refresh_choice_controls()


func _refresh_choice_controls() -> void:
	if current_choice == null:
		return
	for token in choice_buttons:
		var button: Button = choice_buttons[token]
		var selected := selected_choice_tokens.has(token)
		button.set_meta("choice_selected", selected)
		button.modulate = Color(1.12, 1.06, 0.82, 1.0) if selected else Color.WHITE

	var count := selected_choice_tokens.size()
	var minimum := current_choice.minimum
	var maximum := current_choice.maximum
	if minimum == maximum:
		choice_selection_label.text = "Select %d  •  %d selected" % [minimum, count]
	else:
		choice_selection_label.text = (
			"Select %d–%d  •  %d selected" % [minimum, maximum, count]
		)
	choice_confirm_button.disabled = count < minimum or count > maximum or count == 0
	choice_skip_button.visible = minimum == 0


func _on_choice_confirmed() -> void:
	_submit_choice(selected_choice_tokens.duplicate())


func _on_choice_skipped() -> void:
	_submit_choice([])


func _submit_choice(tokens: Array[String]) -> void:
	if current_choice == null:
		return
	var hand_before := game_state.player.hand.size()
	if not game_state.resolve_choice(tokens):
		return
	_refresh_ui()
	var drawn_count := maxi(0, game_state.player.hand.size() - hand_before)
	if drawn_count > 0:
		call_deferred("_animate_draw_cards", drawn_count)


func _on_hand_card_pressed(card: CardDefinition) -> void:
	var source_button := _find_card_button(hand_container, card.id)
	var ghost: Control = null
	if source_button != null:
		ghost = _create_moving_card(
			card,
			source_button.get_global_rect(),
			COLOR_SLATE
		)
	var played := game_state.play_card(card)
	if played:
		last_animation_event = "play"
		_play_ui_sound("play_card")
	else:
		if ghost != null:
			ghost.queue_free()
		push_warning("Card cannot be played right now: %s" % card.card_name)
	_refresh_ui()
	if played and ghost != null:
		_animate_moving_card(
			ghost,
			play_area_panel.get_global_rect().get_center(),
			CARD_MOVE_SECONDS,
			Vector2(0.48, 0.48)
		)
	if played and card.draw_cards > 0:
		call_deferred("_animate_draw_cards", card.draw_cards)


func _on_market_card_pressed(card: CardDefinition) -> void:
	var source_button := _find_card_button(market_container, card.id)
	var ghost: Control = null
	if source_button != null:
		ghost = _create_moving_card(
			card,
			source_button.get_global_rect(),
			COLOR_FOREST
		)
	var bought := game_state.buy_card(card)
	if bought:
		last_animation_event = "buy"
		_play_ui_sound("buy_card")
	else:
		if ghost != null:
			ghost.queue_free()
		push_warning("Card cannot be bought right now: %s" % card.card_name)
	_refresh_ui()
	if bought and ghost != null:
		_animate_moving_card(
			ghost,
			_get_hud_target_center("DiscardStat"),
			CARD_MOVE_SECONDS,
			Vector2(0.22, 0.22)
		)
		_pulse_control(discard_label, COLOR_BRASS.lightened(0.24))


func _on_end_turn_pressed() -> void:
	if game_state.has_pending_choice():
		return
	var cleanup_ghosts := _capture_cleanup_cards()
	_play_ui_sound("end_turn")
	turn_manager.end_turn()
	_refresh_ui()
	_animate_cleanup_cards(cleanup_ghosts)
	if turn_manager.game_over:
		_show_final_score(turn_manager.final_score)
	else:
		call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _on_new_game_pressed() -> void:
	_play_ui_sound("button_click")
	_start_new_game(true)


func _on_play_again_pressed() -> void:
	_play_ui_sound("button_click")
	_start_new_game(true)


func _show_final_score(score: int) -> void:
	last_animation_event = "game_end"
	_play_ui_sound("game_end")
	final_score_label.text = str(score)
	end_game_overlay.modulate.a = 0.0
	end_game_panel.scale = Vector2(0.9, 0.9)
	end_game_panel.pivot_offset = end_game_panel.size * 0.5
	end_game_overlay.show()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(end_game_overlay, "modulate:a", 1.0, 0.2)
	tween.tween_property(end_game_panel, "scale", Vector2.ONE, 0.24)


func _hide_end_game_overlay() -> void:
	end_game_overlay.hide()
	end_game_overlay.modulate.a = 1.0
	end_game_panel.scale = Vector2.ONE


func _find_card_button(container: Container, card_id: String) -> Button:
	for child in container.get_children():
		if child.get_meta("card_id", "") == card_id:
			return child as Button
	return null
