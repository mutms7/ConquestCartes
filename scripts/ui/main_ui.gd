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

const TITLE_FONT_PATH := "res://assets/fonts/Cinzel/static/Cinzel-SemiBold.ttf"
const BODY_FONT_PATH := "res://assets/fonts/Inter/static/Inter_18pt-Regular.ttf"
const PANEL_TEXTURE_PATH := (
	"res://assets/imported/kenney_fantasy-ui-borders/"
	+ "PNG/Double/Panel/panel-024.png"
)
const CARD_FRAME_TEXTURE_PATH := (
	"res://assets/imported/kenney_fantasy-ui-borders/"
	+ "PNG/Double/Panel/panel-006.png"
)
const BUTTON_TEXTURE_PATH := (
	"res://assets/imported/kenney_fantasy-ui-borders/"
	+ "PNG/Double/Panel/panel-010.png"
)
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
}

var game_state := GameState.new()
var turn_manager := TurnManager.new()
var title_font: Font
var body_font: Font
var panel_texture: Texture2D
var card_frame_texture: Texture2D
var button_texture: Texture2D
var icon_textures: Dictionary = {}
var ui_sound_players: Dictionary = {}
var last_ui_sound_name: String = ""

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
@onready var status_panel: PanelContainer = $Margin/Layout/StatusPanel
@onready var play_area_panel: PanelContainer = $Margin/Layout/PlayAreaPanel
@onready var hand_panel: PanelContainer = $Margin/Layout/HandPanel
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
	_load_optional_assets()
	_apply_imported_theme()
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


func _load_optional_assets() -> void:
	title_font = _load_optional_font(TITLE_FONT_PATH)
	body_font = _load_optional_font(BODY_FONT_PATH)
	panel_texture = _load_optional_texture(PANEL_TEXTURE_PATH)
	card_frame_texture = _load_optional_texture(CARD_FRAME_TEXTURE_PATH)
	button_texture = _load_optional_texture(BUTTON_TEXTURE_PATH)

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

	if title_font != null:
		var title_paths := [
			"Margin/Layout/HudPanel/HudMargin/Hud/Brand/Title",
			"Margin/Layout/MarketHeader/Title",
			"Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaLabel",
			"Margin/Layout/HandHeader/Title",
			"CardPreview/Margin/Layout/NameLabel",
		]
		for path in title_paths:
			var label := get_node_or_null(path) as Label
			if label != null:
				label.add_theme_font_override("font", title_font)

	if panel_texture != null:
		hud_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(panel_texture, Color("#19352a"), 24.0)
		)
		market_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(panel_texture, Color("#152b24"), 24.0)
		)
		play_area_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(panel_texture, Color("#152b24"), 24.0)
		)
		hand_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(panel_texture, Color("#152b24"), 24.0)
		)
		status_panel.add_theme_stylebox_override(
			"panel",
			_make_asset_style(panel_texture, Color("#34452f"), 24.0)
		)

	if button_texture != null:
		_apply_button_asset_styles(new_game_button, Color("#28433a"))
		_apply_button_asset_styles(end_turn_button, Color("#6a4c20"))

	_set_hud_icon("CoinStat", "coin", Color("#f6c95d"))
	_set_hud_icon("ActionStat", "action", Color("#a9cdf8"))
	_set_hud_icon("BuyStat", "buy", Color("#a8e0ad"))
	_set_hud_icon("DeckStat", "deck", Color("#e6dfcb"))
	_set_hud_icon("DiscardStat", "discard", Color("#c7bda9"))


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


func _apply_button_asset_styles(button: Button, base_color: Color) -> void:
	button.add_theme_stylebox_override(
		"normal",
		_make_asset_style(button_texture, base_color, 20.0)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_asset_style(button_texture, base_color.lightened(0.12), 20.0)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_asset_style(button_texture, base_color.darkened(0.12), 20.0)
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
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	layout.add_child(name_label)

	var meta_row := HBoxContainer.new()
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

	if card.victory_points > 0:
		if icon_textures.has("victory"):
			meta_row.add_child(
				_create_icon(icon_textures["victory"], Vector2(14, 14), Color("#e9d083"))
			)
		var victory_label := Label.new()
		victory_label.text = "%d VP" % card.victory_points
		victory_label.add_theme_color_override("font_color", Color("#e9d083"))
		victory_label.add_theme_font_size_override("font_size", 12)
		if body_font != null:
			victory_label.add_theme_font_override("font", body_font)
		meta_row.add_child(victory_label)

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
	if body_font != null:
		description_label.add_theme_font_override("font", body_font)
	layout.add_child(description_label)
	return button


func _create_icon(texture: Texture2D, size: Vector2, color: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = texture
	icon.modulate = color
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _update_card_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_card_mouse_entered(
	card: CardDefinition,
	button: Button,
	visual_state: String,
	status_text: String
) -> void:
	_play_ui_sound("hover")
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
	preview_meta_label.text = "%s  |  COST %d" % [card.card_type.to_upper(), card.cost]
	if card.victory_points > 0:
		preview_meta_label.text += "  |  %d VP" % card.victory_points
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


func _make_card_style(color: Color, border_color: Color, border_width: int) -> StyleBox:
	if card_frame_texture != null:
		return _make_asset_style(card_frame_texture, color, 22.0)
	return _make_flat_card_style(color, border_color, border_width)


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


func _make_preview_style(color: Color, border_color: Color) -> StyleBox:
	if panel_texture != null:
		return _make_asset_style(panel_texture, color.darkened(0.08), 24.0)
	var style := _make_flat_card_style(
		color.darkened(0.08),
		border_color.lightened(0.1),
		3
	)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 16
	return style


func _make_asset_style(texture: Texture2D, color: Color, margin: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = color
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style


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


func _on_hand_card_pressed(card: CardDefinition) -> void:
	if game_state.play_card(card):
		_play_ui_sound("play_card")
		status_label.text = "Played %s. Its effects have been applied." % card.card_name
	else:
		status_label.text = "That card cannot be played right now."
	_refresh_ui()


func _on_market_card_pressed(card: CardDefinition) -> void:
	if game_state.buy_card(card):
		_play_ui_sound("buy_card")
		status_label.text = "Bought %s. It is now in your discard pile." % card.card_name
	else:
		status_label.text = "That card requires enough coins and an available buy."
	_refresh_ui()


func _on_end_turn_pressed() -> void:
	_play_ui_sound("end_turn")
	turn_manager.end_turn()
	if turn_manager.game_over:
		status_label.text = "Game complete — final score: %d victory points." % turn_manager.final_score
	else:
		status_label.text = "Turn %d started. Your hand and turn resources have refreshed." % (
			turn_manager.turn_number
		)
	_refresh_ui()


func _on_new_game_pressed() -> void:
	_play_ui_sound("button_click")
	_start_new_game(true)
