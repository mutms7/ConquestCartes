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
const CARD_FACE_SIZE := Vector2(172, 214)
const CARD_ART_HEIGHT := 96.0
const PREVIEW_SIZE := Vector2(360, 500)
const PREVIEW_EDGE_MARGIN := 24.0
const SHORT_RULE_BREAK_LIMIT := 72
const HOME_ART_PATH := "res://assets/cards/sunspire_monument.png"
const CARD_RULE_SIDE_MARGIN := 9
const CARD_RULE_TOP_MARGIN := 1
const CARD_RULE_BOTTOM_MARGIN := 7

const COLOR_PARCHMENT := Color("#ead8ad")
const COLOR_PARCHMENT_LIGHT := Color("#fff1ca")
const COLOR_CARD_BROWN := Color("#4a3021")
const COLOR_CARD_BROWN_LIGHT := Color("#5a3a28")
const COLOR_RESOURCE_CARD := Color("#68431f")
const COLOR_ACTION_CARD := Color("#293e52")
const COLOR_VICTORY_CARD := Color("#552d46")
const COLOR_WALNUT := Color("#39251b")
const COLOR_WALNUT_DARK := Color("#19161a")
const COLOR_BRASS := Color("#d5aa50")
const COLOR_FOREST := Color("#3d7d58")
const COLOR_OXBLOOD := Color("#a64b55")
const COLOR_SLATE := Color("#5c8fc2")
const COLOR_INK := Color("#30251d")
const COLOR_UNAVAILABLE := Color("#77756f")
const COLOR_TREASURY_CARPET := Color("#682b37")
const COLOR_BARRACKS_CARPET := Color("#263f5b")
const COLOR_ESTATES_CARPET := Color("#28503b")
const COLOR_RESOURCE_ACCENT := Color("#f0bd58")
const COLOR_ACTION_ACCENT := Color("#76b5e8")
const COLOR_VICTORY_ACCENT := Color("#df7890")

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
var has_active_game := false
var audio_enabled := true
var motion_enabled := true
var home_noise_amount := 0.12
var table_noise_amount := 0.04
var action_animation_speed := 1.0
var current_choice: CardChoice
var selected_choice_tokens: Array[String] = []
var choice_buttons: Dictionary = {}
var left_ledger: PanelContainer
var right_ledger: PanelContainer
var hand_column: VBoxContainer
var treasury_carpet: PanelContainer
var barracks_carpet: PanelContainer
var estates_carpet: PanelContainer
var market_resource_container: GridContainer
var market_action_container: GridContainer
var market_victory_container: GridContainer
var pending_cleanup_ghosts: Array[Control] = []
var home_overlay: Control
var home_new_game_button: Button
var home_continue_button: Button
var home_settings_panel: VBoxContainer
var home_kingdoms_panel: PanelContainer
var home_kingdom_tab_list: VBoxContainer
var home_kingdom_title_label: Label
var home_kingdom_summary_label: Label
var home_kingdom_card_grid: GridContainer
var home_kingdom_detail_host: VBoxContainer
var selected_home_kingdom := GameState.BASE_KINGDOM
var selected_home_kingdom_card_id := ""
var home_noise_overlay: TextureRect
var table_noise_overlay: TextureRect
var home_noise_slider: HSlider
var table_noise_slider: HSlider
var action_animation_speed_slider: HSlider
var home_audio_toggle: CheckButton
var home_motion_toggle: CheckButton
var noise_texture: Texture2D

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
@onready var home_button: Button = $Margin/Layout/HudPanel/HudMargin/Hud/HomeButton
@onready var end_turn_button: Button = $Margin/Layout/HudPanel/HudMargin/Hud/EndTurnButton
@onready var hud_panel: PanelContainer = $Margin/Layout/HudPanel
@onready var hud_row: HBoxContainer = $Margin/Layout/HudPanel/HudMargin/Hud
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


func _ready() -> void:
	_load_optional_assets()
	_build_bottom_docks()
	_build_market_board()
	_build_home_screen()
	_apply_imported_theme()
	home_button.pressed.connect(_on_home_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	choice_skip_button.pressed.connect(_on_choice_skipped)
	choice_confirm_button.pressed.connect(_on_choice_confirmed)
	home_button.mouse_entered.connect(_on_hud_button_hovered.bind(home_button))
	home_button.mouse_exited.connect(_on_hud_button_unhovered.bind(home_button))
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
	turn_manager.turn_completed.connect(_on_turn_completed)

	if not game_state.load_cards(CARD_DATA_PATH):
		push_error("Could not load card data from %s." % CARD_DATA_PATH)
		home_button.disabled = true
		end_turn_button.disabled = true
		if home_continue_button != null:
			home_continue_button.disabled = true
		return

	_refresh_kingdom_tab()
	_show_home_screen(false)


func _start_new_game(_is_restart: bool) -> void:
	if game_state.card_catalog.is_empty() or not game_state.has_enough_market_candidates():
		_refresh_home_controls()
		return
	_hide_home_screen()
	_hide_end_game_overlay()
	_hide_choice_overlay()
	_clear_animation_layer()
	if not game_state.setup_starting_game():
		push_error("Could not prepare a new game.")
		has_active_game = false
		end_turn_button.disabled = true
		_show_home_screen(false)
		return

	has_active_game = true
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


func _build_bottom_docks() -> void:
	var brand := hud_row.get_node("Brand") as VBoxContainer
	var turn_stat := turn_label.get_parent() as VBoxContainer
	var deck_stat := deck_label.get_parent().get_parent() as VBoxContainer
	var discard_stat := discard_label.get_parent().get_parent() as VBoxContainer
	var coin_stat := coin_label.get_parent().get_parent() as VBoxContainer
	var action_stat := action_label.get_parent().get_parent() as VBoxContainer
	var buy_stat := buy_label.get_parent().get_parent() as VBoxContainer

	var left_parts := _create_hud_ledger("LeftDock")
	left_ledger = left_parts.panel
	var left_stats: VBoxContainer = left_parts.stats
	var right_parts := _create_hud_ledger("RightDock")
	right_ledger = right_parts.panel
	var right_stats: VBoxContainer = right_parts.stats
	hand_column = VBoxContainer.new()
	hand_column.name = "HandColumn"
	hand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_column.add_theme_constant_override("separation", 2)

	hud_row.add_theme_constant_override("separation", 8)
	hud_row.add_child(left_ledger)
	hud_row.add_child(hand_column)
	hud_row.add_child(right_ledger)

	for stat in [turn_stat, deck_stat, discard_stat, coin_stat, action_stat, buy_stat]:
		stat.custom_minimum_size = Vector2(0, 38)
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_button.custom_minimum_size = Vector2(0, 38)
	end_turn_button.custom_minimum_size = Vector2(0, 42)

	turn_stat.reparent(left_stats)
	deck_stat.reparent(left_stats)
	discard_stat.reparent(left_stats)
	home_button.reparent(left_stats)
	coin_stat.reparent(right_stats)
	action_stat.reparent(right_stats)
	buy_stat.reparent(right_stats)
	end_turn_button.reparent(right_stats)
	hand_count_label.get_parent().reparent(hand_column)
	hand_panel.reparent(hand_column)
	brand.queue_free()

	for obsolete_name in ["Divider", "ZoneDivider", "Spacer"]:
		var obsolete := hud_row.get_node_or_null(obsolete_name)
		if obsolete != null:
			obsolete.free()

	hud_row.move_child(left_ledger, 0)
	hud_row.move_child(hand_column, 1)
	hud_row.move_child(right_ledger, 2)
	var main_layout := hud_panel.get_parent() as VBoxContainer
	main_layout.move_child(hud_panel, main_layout.get_child_count() - 1)


func _create_hud_ledger(ledger_name: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = ledger_name
	panel.custom_minimum_size = Vector2(148, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var stats := VBoxContainer.new()
	stats.name = "Stats"
	stats.add_theme_constant_override("separation", 4)
	margin.add_child(stats)
	return {"panel": panel, "stats": stats}


func _build_home_screen() -> void:
	noise_texture = _create_noise_texture()
	table_noise_overlay = _create_noise_rect("TableNoise", table_noise_amount)
	add_child(table_noise_overlay)
	table_noise_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(table_noise_overlay, mini(2, get_child_count() - 1))

	home_overlay = Control.new()
	home_overlay.name = "HomeOverlay"
	home_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	home_overlay.z_index = 240
	add_child(home_overlay)
	home_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var home_art := _load_optional_texture(HOME_ART_PATH)
	if home_art != null:
		var background := TextureRect.new()
		background.name = "HomeArt"
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.texture = home_art
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		home_overlay.add_child(background)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	home_noise_overlay = _create_noise_rect("HomeNoise", home_noise_amount)
	home_overlay.add_child(home_noise_overlay)
	home_noise_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.color = Color(0.02, 0.026, 0.03, 0.56)
	home_overlay.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var side_shade := ColorRect.new()
	side_shade.name = "MenuShade"
	side_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_shade.color = Color(0.03, 0.036, 0.04, 0.52)
	home_overlay.add_child(side_shade)
	side_shade.anchor_right = 0.48
	side_shade.anchor_bottom = 1.0
	side_shade.offset_right = 80.0

	var menu_margin := MarginContainer.new()
	menu_margin.name = "MenuMargin"
	menu_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_margin.add_theme_constant_override("margin_left", 74)
	menu_margin.add_theme_constant_override("margin_top", 58)
	menu_margin.add_theme_constant_override("margin_right", 74)
	menu_margin.add_theme_constant_override("margin_bottom", 58)
	home_overlay.add_child(menu_margin)
	menu_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var menu_layout := VBoxContainer.new()
	menu_layout.name = "Menu"
	menu_layout.custom_minimum_size = Vector2(370, 0)
	menu_layout.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_layout.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu_layout)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 28)
	menu_layout.add_child(spacer_top)

	var title := Label.new()
	title.name = "Title"
	title.text = "CONQUEST CARTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.76))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 42)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	menu_layout.add_child(title)

	var set_label := Label.new()
	set_label.name = "SetLabel"
	set_label.text = GameState.HINTERLANDS_GROUP.to_upper()
	set_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	set_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.2))
	set_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	set_label.add_theme_constant_override("shadow_offset_x", 1)
	set_label.add_theme_constant_override("shadow_offset_y", 2)
	set_label.add_theme_font_size_override("font_size", 16)
	if body_bold_font != null:
		set_label.add_theme_font_override("font", body_bold_font)
	menu_layout.add_child(set_label)

	var button_stack := VBoxContainer.new()
	button_stack.name = "Buttons"
	button_stack.custom_minimum_size = Vector2(310, 0)
	button_stack.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button_stack.add_theme_constant_override("separation", 10)
	menu_layout.add_child(button_stack)

	home_new_game_button = _create_home_menu_button("NEW GAME")
	home_new_game_button.name = "NewGameButton"
	home_new_game_button.pressed.connect(_on_home_new_game_pressed)
	button_stack.add_child(home_new_game_button)

	home_continue_button = _create_home_menu_button("CONTINUE")
	home_continue_button.name = "ContinueButton"
	home_continue_button.pressed.connect(_on_home_continue_pressed)
	button_stack.add_child(home_continue_button)

	var settings_button := _create_home_menu_button("SETTINGS")
	settings_button.name = "SettingsButton"
	settings_button.pressed.connect(_on_home_settings_pressed)
	button_stack.add_child(settings_button)

	var kingdoms_button := _create_home_menu_button("KINGDOMS")
	kingdoms_button.name = "KingdomsButton"
	kingdoms_button.pressed.connect(_on_home_kingdoms_pressed)
	button_stack.add_child(kingdoms_button)

	home_settings_panel = VBoxContainer.new()
	home_settings_panel.name = "SettingsPanel"
	home_settings_panel.visible = false
	home_settings_panel.custom_minimum_size = Vector2(310, 0)
	home_settings_panel.add_theme_constant_override("separation", 6)
	menu_layout.add_child(home_settings_panel)

	home_audio_toggle = CheckButton.new()
	home_audio_toggle.name = "AudioToggle"
	home_audio_toggle.text = "AUDIO"
	home_audio_toggle.button_pressed = audio_enabled
	home_audio_toggle.toggled.connect(_on_home_audio_toggled)
	_style_home_toggle(home_audio_toggle)
	home_settings_panel.add_child(home_audio_toggle)

	home_motion_toggle = CheckButton.new()
	home_motion_toggle.name = "MotionToggle"
	home_motion_toggle.text = "ACTION MOTION"
	home_motion_toggle.button_pressed = motion_enabled
	home_motion_toggle.toggled.connect(_on_home_motion_toggled)
	_style_home_toggle(home_motion_toggle)
	home_settings_panel.add_child(home_motion_toggle)

	home_noise_slider = _create_home_slider(
		"HOME NOISE",
		home_noise_amount,
		0.0,
		0.35,
		0.01
	)
	home_noise_slider.value_changed.connect(_on_home_noise_changed)
	home_settings_panel.add_child(home_noise_slider.get_parent())

	table_noise_slider = _create_home_slider(
		"TABLE NOISE",
		table_noise_amount,
		0.0,
		0.24,
		0.01
	)
	table_noise_slider.value_changed.connect(_on_table_noise_changed)
	home_settings_panel.add_child(table_noise_slider.get_parent())

	action_animation_speed_slider = _create_home_slider(
		"ACTION SPEED",
		action_animation_speed,
		0.5,
		2.0,
		0.1
	)
	action_animation_speed_slider.value_changed.connect(_on_action_animation_speed_changed)
	home_settings_panel.add_child(action_animation_speed_slider.get_parent())

	var spacer_fill := Control.new()
	spacer_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_layout.add_child(spacer_fill)

	_build_kingdom_browser()
	_refresh_home_controls()


func _build_kingdom_browser() -> void:
	home_kingdoms_panel = PanelContainer.new()
	home_kingdoms_panel.name = "KingdomsPanel"
	home_kingdoms_panel.visible = false
	home_kingdoms_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	home_kingdoms_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.055, 0.07, 0.068, 0.92), COLOR_BRASS.darkened(0.08), 2)
	)
	home_overlay.add_child(home_kingdoms_panel)
	home_kingdoms_panel.anchor_left = 0.36
	home_kingdoms_panel.anchor_top = 0.08
	home_kingdoms_panel.anchor_right = 0.965
	home_kingdoms_panel.anchor_bottom = 0.92
	home_kingdoms_panel.offset_left = 0
	home_kingdoms_panel.offset_top = 0
	home_kingdoms_panel.offset_right = 0
	home_kingdoms_panel.offset_bottom = 0

	var browser_margin := MarginContainer.new()
	browser_margin.name = "Margin"
	browser_margin.add_theme_constant_override("margin_left", 12)
	browser_margin.add_theme_constant_override("margin_top", 12)
	browser_margin.add_theme_constant_override("margin_right", 12)
	browser_margin.add_theme_constant_override("margin_bottom", 12)
	home_kingdoms_panel.add_child(browser_margin)

	var browser := HBoxContainer.new()
	browser.name = "Browser"
	browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser.add_theme_constant_override("separation", 12)
	browser_margin.add_child(browser)

	home_kingdom_tab_list = VBoxContainer.new()
	home_kingdom_tab_list.name = "KingdomTabs"
	home_kingdom_tab_list.custom_minimum_size = Vector2(150, 0)
	home_kingdom_tab_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_kingdom_tab_list.add_theme_constant_override("separation", 8)
	browser.add_child(home_kingdom_tab_list)

	var cards_pane := VBoxContainer.new()
	cards_pane.name = "CardsPane"
	cards_pane.custom_minimum_size = Vector2(368, 0)
	cards_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_pane.add_theme_constant_override("separation", 8)
	browser.add_child(cards_pane)

	home_kingdom_title_label = Label.new()
	home_kingdom_title_label.name = "KingdomTitle"
	home_kingdom_title_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	home_kingdom_title_label.add_theme_font_size_override("font_size", 20)
	if title_font != null:
		home_kingdom_title_label.add_theme_font_override("font", title_font)
	cards_pane.add_child(home_kingdom_title_label)

	home_kingdom_summary_label = Label.new()
	home_kingdom_summary_label.name = "KingdomSummary"
	home_kingdom_summary_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.1))
	home_kingdom_summary_label.add_theme_font_size_override("font_size", 12)
	if body_bold_font != null:
		home_kingdom_summary_label.add_theme_font_override("font", body_bold_font)
	cards_pane.add_child(home_kingdom_summary_label)

	var card_scroll := ScrollContainer.new()
	card_scroll.name = "CardScroll"
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cards_pane.add_child(card_scroll)

	home_kingdom_card_grid = GridContainer.new()
	home_kingdom_card_grid.name = "CardGrid"
	home_kingdom_card_grid.columns = 2
	home_kingdom_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_kingdom_card_grid.add_theme_constant_override("h_separation", 10)
	home_kingdom_card_grid.add_theme_constant_override("v_separation", 10)
	card_scroll.add_child(home_kingdom_card_grid)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "DetailPane"
	detail_panel.custom_minimum_size = Vector2(230, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.075, 0.09, 0.085, 0.86), COLOR_SLATE.lightened(0.16), 1)
	)
	browser.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.name = "Margin"
	detail_margin.add_theme_constant_override("margin_left", 10)
	detail_margin.add_theme_constant_override("margin_top", 10)
	detail_margin.add_theme_constant_override("margin_right", 10)
	detail_margin.add_theme_constant_override("margin_bottom", 10)
	detail_panel.add_child(detail_margin)

	home_kingdom_detail_host = VBoxContainer.new()
	home_kingdom_detail_host.name = "DetailHost"
	home_kingdom_detail_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_kingdom_detail_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_kingdom_detail_host.add_theme_constant_override("separation", 8)
	detail_margin.add_child(home_kingdom_detail_host)


func _create_home_menu_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(310, 48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", COLOR_PARCHMENT.darkened(0.35))
	button.add_theme_font_size_override("font_size", 17)
	if body_bold_font != null:
		button.add_theme_font_override("font", body_bold_font)
	if ui_textures.has("button_primary"):
		_apply_button_asset_styles(button, ui_textures["button_primary"])
	else:
		button.add_theme_stylebox_override(
			"normal",
			_make_panel_style(Color("#233c3b"), COLOR_BRASS.darkened(0.05), 2)
		)
	return button


func _style_home_toggle(toggle: CheckButton) -> void:
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	toggle.add_theme_color_override("font_hover_color", Color.WHITE)
	toggle.add_theme_font_size_override("font_size", 14)
	if body_bold_font != null:
		toggle.add_theme_font_override("font", body_bold_font)


func _create_home_slider(
	label_text: String,
	value: float,
	minimum: float,
	maximum: float,
	step: float
) -> HSlider:
	var row := VBoxContainer.new()
	row.name = "%sRow" % _node_key(label_text)
	row.add_theme_constant_override("separation", 2)

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	label.add_theme_font_size_override("font_size", 12)
	if body_bold_font != null:
		label.add_theme_font_override("font", body_bold_font)
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "%sSlider" % _node_key(label_text)
	slider.custom_minimum_size = Vector2(0, 24)
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return slider


func _create_noise_texture() -> Texture2D:
	var image := Image.create(160, 160, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7717
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var grain := rng.randf_range(0.2, 1.0)
			image.set_pixel(x, y, Color(grain, grain, grain, 1.0))
	return ImageTexture.create_from_image(image)


func _create_noise_rect(rect_name: String, amount: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = rect_name
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = noise_texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_TILE
	_set_noise_amount(rect, amount)
	return rect


func _set_noise_amount(rect: TextureRect, amount: float) -> void:
	if rect == null:
		return
	rect.modulate = Color(1, 1, 1, amount)


func _show_home_screen(_from_game: bool) -> void:
	_hide_card_preview()
	_refresh_home_controls()
	if home_overlay != null:
		home_overlay.show()


func _hide_home_screen() -> void:
	if home_overlay != null:
		home_overlay.hide()


func _refresh_home_controls() -> void:
	if home_new_game_button != null:
		home_new_game_button.disabled = (
			game_state.card_catalog.is_empty()
			or not game_state.has_enough_market_candidates()
		)
	if home_continue_button != null:
		home_continue_button.disabled = not has_active_game
	if home_audio_toggle != null:
		home_audio_toggle.set_pressed_no_signal(audio_enabled)
	if home_motion_toggle != null:
		home_motion_toggle.set_pressed_no_signal(motion_enabled)
	if home_noise_slider != null:
		home_noise_slider.set_value_no_signal(home_noise_amount)
	if table_noise_slider != null:
		table_noise_slider.set_value_no_signal(table_noise_amount)
	if action_animation_speed_slider != null:
		action_animation_speed_slider.set_value_no_signal(action_animation_speed)


func _show_home_tab(tab_name: String) -> void:
	if home_settings_panel != null:
		home_settings_panel.visible = tab_name == "settings"
	if home_kingdoms_panel != null:
		home_kingdoms_panel.visible = tab_name == "kingdoms"
	if tab_name == "kingdoms":
		_refresh_kingdom_tab()


func _refresh_kingdom_tab() -> void:
	if home_kingdom_tab_list == null or game_state.card_catalog.is_empty():
		return
	if not GameState.KINGDOM_ORDER.has(selected_home_kingdom):
		selected_home_kingdom = GameState.BASE_KINGDOM
	_select_default_kingdom_card()
	_refresh_kingdom_tabs()
	_refresh_kingdom_cards()
	_refresh_kingdom_detail()
	_refresh_home_controls()


func _select_default_kingdom_card() -> void:
	var selected_card = game_state.card_catalog.get(selected_home_kingdom_card_id)
	if selected_card is CardDefinition:
		var selected_definition := selected_card as CardDefinition
		if game_state.get_card_kingdom(selected_definition) == selected_home_kingdom:
			return
	var cards := game_state.get_cards_for_kingdom(selected_home_kingdom)
	selected_home_kingdom_card_id = cards[0].id if not cards.is_empty() else ""


func _refresh_kingdom_tabs() -> void:
	_clear_container(home_kingdom_tab_list)
	for kingdom in GameState.KINGDOM_ORDER:
		home_kingdom_tab_list.add_child(_create_kingdom_tab_section(kingdom))


func _create_kingdom_tab_section(kingdom: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = "Kingdom_%s" % _node_key(kingdom)
	section.add_theme_constant_override("separation", 3)

	var tab_button := Button.new()
	tab_button.name = "KingdomTab"
	tab_button.text = kingdom.to_upper()
	tab_button.toggle_mode = true
	tab_button.button_pressed = kingdom == selected_home_kingdom
	tab_button.custom_minimum_size = Vector2(0, 42)
	tab_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tab_button.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	tab_button.add_theme_color_override("font_pressed_color", COLOR_BRASS.lightened(0.25))
	tab_button.add_theme_font_size_override("font_size", 13)
	if body_bold_font != null:
		tab_button.add_theme_font_override("font", body_bold_font)
	if ui_textures.has("button"):
		_apply_button_asset_styles(tab_button, ui_textures["button"])
	tab_button.pressed.connect(_on_kingdom_tab_pressed.bind(kingdom))
	section.add_child(tab_button)

	var kingdom_toggle := CheckButton.new()
	kingdom_toggle.name = "KingdomToggle"
	kingdom_toggle.text = "BASE" if kingdom == GameState.BASE_KINGDOM else "IN POOL"
	kingdom_toggle.button_pressed = game_state.is_kingdom_enabled(kingdom)
	kingdom_toggle.disabled = kingdom == GameState.BASE_KINGDOM
	kingdom_toggle.toggled.connect(_on_kingdom_toggled.bind(kingdom))
	_style_home_toggle(kingdom_toggle)
	section.add_child(kingdom_toggle)
	return section


func _refresh_kingdom_cards() -> void:
	_clear_container(home_kingdom_card_grid)
	var cards := game_state.get_cards_for_kingdom(selected_home_kingdom)
	home_kingdom_title_label.text = selected_home_kingdom.to_upper()
	home_kingdom_summary_label.text = _get_kingdom_summary_text(cards)
	for card in cards:
		home_kingdom_card_grid.add_child(_create_kingdom_card_button(card))


func _get_kingdom_summary_text(cards: Array[CardDefinition]) -> String:
	var market_count := 0
	var active_count := 0
	for card in cards:
		if not card.market_enabled or GameState.STARTING_CARD_COUNTS.has(card.id):
			continue
		market_count += 1
		if (
			game_state.is_kingdom_enabled(game_state.get_card_kingdom(card))
			and game_state.is_card_enabled_for_market(card.id)
		):
			active_count += 1
	return "%d CARDS    %d / %d MARKET" % [cards.size(), active_count, market_count]


func _create_kingdom_card_button(card: CardDefinition) -> Button:
	var button := _create_card_button(card, "kingdom_browser")
	button.name = "Card_%s" % card.id
	var kingdom_enabled := game_state.is_kingdom_enabled(game_state.get_card_kingdom(card))
	var card_enabled := game_state.is_card_enabled_for_market(card.id)
	var can_toggle := (
		kingdom_enabled
		and card.market_enabled
		and not game_state.is_required_card(card.id)
		and not GameState.STARTING_CARD_COUNTS.has(card.id)
	)
	button.toggle_mode = can_toggle
	button.button_pressed = kingdom_enabled and card_enabled if can_toggle else false
	button.disabled = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.modulate = Color.WHITE if kingdom_enabled and card_enabled else Color(0.48, 0.48, 0.48, 1.0)
	if can_toggle:
		button.toggled.connect(_on_kingdom_card_toggled.bind(card.id))
	else:
		button.pressed.connect(_on_kingdom_card_selected.bind(card.id))
	if selected_home_kingdom_card_id == card.id:
		button.add_theme_stylebox_override(
			"normal",
			_make_card_style(
				_get_card_surface_color(card.card_type).lightened(0.08),
				COLOR_BRASS.lightened(0.26),
				5
			)
		)
	return button


func _refresh_kingdom_detail() -> void:
	_clear_container(home_kingdom_detail_host)
	if selected_home_kingdom_card_id.is_empty():
		return
	if not game_state.card_catalog.has(selected_home_kingdom_card_id):
		return
	var card: CardDefinition = game_state.card_catalog[selected_home_kingdom_card_id]

	var detail_card := _create_card_button(card, "kingdom_detail")
	detail_card.name = "DetailCard_%s" % card.id
	detail_card.focus_mode = Control.FOCUS_NONE
	detail_card.mouse_default_cursor_shape = Control.CURSOR_ARROW
	home_kingdom_detail_host.add_child(detail_card)

	var meta_label := Label.new()
	meta_label.name = "DetailMeta"
	meta_label.text = "%s    COST %d" % [card.card_type.to_upper(), card.cost]
	if not card.card_group.is_empty():
		meta_label.text += "    %s" % card.card_group.to_upper()
	meta_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.18))
	meta_label.add_theme_font_size_override("font_size", 12)
	if body_bold_font != null:
		meta_label.add_theme_font_override("font", body_bold_font)
	home_kingdom_detail_host.add_child(meta_label)

	var card_toggle := CheckButton.new()
	card_toggle.name = "DetailCardToggle"
	card_toggle.text = "IN MARKET"
	var kingdom_enabled := game_state.is_kingdom_enabled(game_state.get_card_kingdom(card))
	card_toggle.button_pressed = kingdom_enabled and game_state.is_card_enabled_for_market(card.id)
	card_toggle.disabled = (
		not kingdom_enabled
		or game_state.is_required_card(card.id)
		or not card.market_enabled
		or GameState.STARTING_CARD_COUNTS.has(card.id)
	)
	_style_home_toggle(card_toggle)
	card_toggle.toggled.connect(_on_kingdom_card_toggled.bind(card.id))
	home_kingdom_detail_host.add_child(card_toggle)

	var rules_label := RichTextLabel.new()
	rules_label.name = "DetailRules"
	rules_label.bbcode_enabled = true
	rules_label.fit_content = false
	rules_label.scroll_active = true
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.custom_minimum_size = Vector2(0, 116)
	rules_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_label.text = "[center]%s[/center]" % _get_card_rules_text(card.description)
	rules_label.add_theme_color_override("default_color", COLOR_PARCHMENT_LIGHT)
	rules_label.add_theme_font_size_override("normal_font_size", 13)
	rules_label.add_theme_font_size_override("bold_font_size", 13)
	if body_font != null:
		rules_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		rules_label.add_theme_font_override("bold_font", body_bold_font)
	home_kingdom_detail_host.add_child(rules_label)


func _node_key(value: String) -> String:
	var key := value.replace(" ", "")
	key = key.replace("'", "")
	key = key.replace("-", "")
	key = key.replace("/", "")
	return key


func _build_market_board() -> void:
	market_container.add_theme_constant_override("separation", 4)
	market_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var treasury := _create_market_carpet(
		"TreasuryCarpet",
		1,
		172.0,
		COLOR_TREASURY_CARPET,
		COLOR_BRASS
	)
	treasury_carpet = treasury.panel
	market_resource_container = treasury.cards

	var barracks := _create_market_carpet(
		"BarracksCarpet",
		5,
		0.0,
		COLOR_BARRACKS_CARPET,
		COLOR_SLATE.lightened(0.32)
	)
	barracks_carpet = barracks.panel
	barracks_carpet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_action_container = barracks.cards

	var estates := _create_market_carpet(
		"EstatesCarpet",
		1,
		172.0,
		COLOR_ESTATES_CARPET,
		COLOR_FOREST.lightened(0.32)
	)
	estates_carpet = estates.panel
	market_victory_container = estates.cards

	market_container.add_child(treasury_carpet)
	market_container.add_child(barracks_carpet)
	market_container.add_child(estates_carpet)


func _create_market_carpet(
	carpet_name: String,
	columns: int,
	minimum_width: float,
	surface_color: Color,
	accent_color: Color
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = carpet_name
	panel.custom_minimum_size = Vector2(minimum_width, 432)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.set_meta("carpet_surface", surface_color)
	panel.set_meta("carpet_accent", accent_color)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	panel.add_child(margin)

	var cards := GridContainer.new()
	cards.name = "Cards"
	cards.columns = columns
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 4)
	cards.add_theme_constant_override("v_separation", 4)
	margin.add_child(cards)

	return {"panel": panel, "cards": cards}


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
	if body_bold_font != null:
		preview_effect_label.add_theme_font_override("bold_font", body_bold_font)

	if title_font != null:
		var title_paths := [
			"HomeOverlay/MenuMargin/Menu/Title",
			"Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaLabel",
			"CardPreview/Margin/Layout/NameLabel",
			"ChoiceOverlay/Center/Panel/Margin/Layout/Title",
			"EndGameOverlay/Center/Panel/Margin/Layout/Title",
			"EndGameOverlay/Center/Panel/Margin/Layout/ScoreRow/ScoreLabel",
		]
		for path in title_paths:
			var label := get_node_or_null(path) as Label
			if label != null:
				label.add_theme_font_override("font", title_font)
		var hand_title := hand_column.find_child("Title", true, false) as Label
		if hand_title != null:
			hand_title.add_theme_font_override("font", title_font)
	var home_set_label := get_node_or_null("HomeOverlay/MenuMargin/Menu/SetLabel") as Label
	if home_set_label != null and body_bold_font != null:
		home_set_label.add_theme_font_override("font", body_bold_font)

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
	hud_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	market_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	left_ledger.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color("#182838"), COLOR_SLATE.lightened(0.18), 2)
	)
	right_ledger.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color("#193429"), COLOR_FOREST.lightened(0.24), 2)
	)
	for market_zone in [treasury_carpet, barracks_carpet, estates_carpet]:
		market_zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	hand_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			Color("#171f27"),
			COLOR_BRASS.darkened(0.04),
			2
		)
	)
	play_area_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color("#17252b"), COLOR_BRASS.darkened(0.08), 2)
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
		_apply_button_asset_styles(home_button, ui_textures["button"])
	if ui_textures.has("button_primary"):
		_apply_button_asset_styles(end_turn_button, ui_textures["button_primary"])
		_apply_button_asset_styles(play_again_button, ui_textures["button_primary"])


func _apply_scene_colors() -> void:
	var cream_paths := [
		"Margin/Layout/PlayAreaPanel/PlayAreaMargin/Row/PlayAreaLabel",
		"ChoiceOverlay/Center/Panel/Margin/Layout/Title",
		"EndGameOverlay/Center/Panel/Margin/Layout/Title",
		"EndGameOverlay/Center/Panel/Margin/Layout/SummaryLabel",
	]
	for path in cream_paths:
		var label := get_node_or_null(path) as Label
		if label != null:
			label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	var muted_paths := [
		"ChoiceOverlay/Center/Panel/Margin/Layout/SelectionLabel",
		"EndGameOverlay/Center/Panel/Margin/Layout/Caption",
	]
	for path in muted_paths:
		var label := get_node_or_null(path) as Label
		if label != null:
			label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.2))
	var hand_title := hand_column.find_child("Title", true, false) as Label
	if hand_title != null:
		hand_title.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	hand_count_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.2))
	var hand_hint := hand_column.find_child("Hint", true, false) as Label
	if hand_hint != null:
		hand_hint.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.2))
	preview_name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	preview_meta_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.18))
	preview_effect_label.add_theme_color_override("default_color", COLOR_PARCHMENT_LIGHT)
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
	var stat := hud_row.find_child(stat_name, true, false)
	var icon := stat.find_child("Icon", true, false) as TextureRect if stat != null else null
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
	home_button.disabled = false

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
	_clear_container(market_resource_container)
	_clear_container(market_action_container)
	_clear_container(market_victory_container)

	var resource_cards: Array[CardDefinition] = []
	var action_cards: Array[CardDefinition] = []
	var victory_cards: Array[CardDefinition] = []
	for card in game_state.market:
		match card.card_type:
			"resource":
				resource_cards.append(card)
			"victory":
				victory_cards.append(card)
			_:
				action_cards.append(card)

	_render_market_cards(
		_sort_market_cards_descending(resource_cards),
		market_resource_container
	)
	_render_market_cards(
		_arrange_action_market(action_cards),
		market_action_container
	)
	_render_market_cards(
		_sort_market_cards_descending(victory_cards),
		market_victory_container
	)


func _render_market_cards(
	cards: Array[CardDefinition],
	container: GridContainer
) -> void:
	for card in cards:
		var affordable := _can_buy_card(card)
		var visual_state := MARKET_AFFORDABLE if affordable else MARKET_UNAFFORDABLE
		var button := _create_card_button(card, visual_state)
		button.disabled = not affordable
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if affordable else Control.CURSOR_ARROW
		)
		button.pressed.connect(_on_market_card_pressed.bind(card))
		container.add_child(button)


func _sort_market_cards_descending(
	cards: Array[CardDefinition]
) -> Array[CardDefinition]:
	var sorted_cards := cards.duplicate()
	sorted_cards.sort_custom(_is_market_card_before)
	return sorted_cards


func _is_market_card_before(
	first: CardDefinition,
	second: CardDefinition
) -> bool:
	var first_cost := game_state.get_effective_cost(first)
	var second_cost := game_state.get_effective_cost(second)
	if first_cost != second_cost:
		return first_cost > second_cost
	return first.card_name.naturalnocasecmp_to(second.card_name) < 0


func _get_card_rules_text(description: String) -> String:
	var rules_text := description
	if description.length() > SHORT_RULE_BREAK_LIMIT:
		return _format_rule_shorthand(rules_text)
	var sentences := description.split(". ", false)
	if sentences.size() <= 1:
		return _format_rule_shorthand(rules_text)
	var formatted_text := ""
	for index in range(sentences.size()):
		var sentence := sentences[index]
		if index < sentences.size() - 1 and not sentence.ends_with("."):
			sentence += "."
		if not formatted_text.is_empty():
			formatted_text += "\n"
		formatted_text += sentence
	return _format_rule_shorthand(formatted_text)


func _format_rule_shorthand(text: String) -> String:
	var formatted_text := _replace_numeric_rule_phrase(
		text,
		"(Gain|gain|Draw|draw) ([0-9]+) (extra |more )?(card|cards|action|actions|buy|buys|coin|coins)",
		false
	)
	return _replace_numeric_rule_phrase(
		formatted_text,
		"(, and |, | and )([0-9]+) (card|cards|action|actions|buy|buys|coin|coins)",
		true
	)


func _replace_numeric_rule_phrase(text: String, pattern: String, keep_prefix: bool) -> String:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return text
	var matches := regex.search_all(text)
	if matches.is_empty():
		return text

	var formatted_text := ""
	var cursor := 0
	for match_result in matches:
		formatted_text += text.substr(cursor, match_result.get_start() - cursor)
		if keep_prefix:
			formatted_text += "%s[b]+%s %s[/b]" % [
				match_result.get_string(1),
				match_result.get_string(2),
				match_result.get_string(3),
			]
		else:
			formatted_text += "[b]+%s %s[/b]" % [
				match_result.get_string(2),
				match_result.get_string(4),
			]
		cursor = match_result.get_end()
	formatted_text += text.substr(cursor)
	return formatted_text


func _arrange_action_market(
	cards: Array[CardDefinition]
) -> Array[CardDefinition]:
	var sorted_cards := _sort_market_cards_descending(cards)
	var arranged: Array[CardDefinition] = []
	var row_size := mini(market_action_container.columns, sorted_cards.size())

	# GridContainer fills left-to-right. Reverse each row so the visual reading
	# path runs from top-right to top-left, then bottom-right to bottom-left.
	for index in range(row_size - 1, -1, -1):
		arranged.append(sorted_cards[index])
	for index in range(sorted_cards.size() - 1, row_size - 1, -1):
		arranged.append(sorted_cards[index])
	return arranged


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
		and game_state.player.coins >= game_state.get_effective_cost(card)
		and game_state.get_supply_count(card.id) > 0
	)


func _create_card_button(
	card: CardDefinition,
	visual_state: String
) -> Button:
	var palette := _get_card_palette(visual_state)
	var card_surface := _get_card_surface_color(card.card_type)
	var is_market_card := visual_state.begins_with("market_")
	var button := Button.new()
	button.custom_minimum_size = CARD_FACE_SIZE
	if is_market_card:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("card_id", card.id)
	button.set_meta("visual_state", visual_state)
	button.set_meta("card_base_color", card_surface)
	button.set_meta("card_type", card.card_type)
	button.set_meta("card_group", card.card_group)
	button.set_meta("card_accent_color", palette.border)
	button.set_meta("supply_count", game_state.get_supply_count(card.id))
	button.tooltip_text = "%s — %s" % [card.card_name, card.description]
	if visual_state.begins_with("market_"):
		button.tooltip_text += "\n%d cards remain in this pile." % game_state.get_supply_count(card.id)
	button.resized.connect(_update_card_pivot.bind(button))
	if not visual_state.begins_with("kingdom_"):
		button.mouse_entered.connect(
			_on_card_mouse_entered.bind(card, button, visual_state)
		)
		button.mouse_exited.connect(_on_card_mouse_exited.bind(button))
	button.add_theme_stylebox_override(
		"normal",
		_make_card_style(card_surface, palette.border, 4)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_card_style(card_surface.lightened(0.14), palette.border.lightened(0.2), 6)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_card_style(card_surface.darkened(0.06), palette.border.lightened(0.08), 5)
	)
	button.add_theme_stylebox_override(
		"focus",
		_make_card_style(Color.TRANSPARENT, COLOR_BRASS.lightened(0.3), 6)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_card_style(card_surface.darkened(0.16), palette.border, 4)
	)

	if ui_textures.has("card"):
		var ornament := TextureRect.new()
		ornament.name = "MedievalFrame"
		ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ornament.texture = ui_textures["card"]
		ornament.modulate = Color(1.18, 1.12, 0.92, 1.0)
		ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ornament.stretch_mode = TextureRect.STRETCH_SCALE
		button.add_child(ornament)
		ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var content := MarginContainer.new()
	content.name = "CardContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", 7 if is_market_card else 9)
	content.add_theme_constant_override("margin_top", 5)
	content.add_theme_constant_override("margin_right", 7 if is_market_card else 9)
	content.add_theme_constant_override("margin_bottom", 5)
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.name = "CardLayout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 2)
	content.add_child(layout)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.custom_minimum_size = Vector2(0, 30)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", palette.text)
	name_label.add_theme_font_size_override("font_size", 12 if is_market_card else 15)
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
		art_frame.custom_minimum_size = Vector2(0, CARD_ART_HEIGHT)
		art_frame.add_theme_stylebox_override(
			"panel",
			_make_flat_card_style(
				COLOR_WALNUT_DARK,
				_get_card_type_accent(card.card_type),
				3
			)
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

	var effect_slot := MarginContainer.new()
	effect_slot.name = "EffectSlot"
	effect_slot.custom_minimum_size = Vector2(0, 51)
	effect_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_slot.add_theme_constant_override("margin_left", CARD_RULE_SIDE_MARGIN)
	effect_slot.add_theme_constant_override("margin_top", CARD_RULE_TOP_MARGIN)
	effect_slot.add_theme_constant_override("margin_right", CARD_RULE_SIDE_MARGIN)
	effect_slot.add_theme_constant_override("margin_bottom", CARD_RULE_BOTTOM_MARGIN)
	layout.add_child(effect_slot)

	var effect_center := VBoxContainer.new()
	effect_center.name = "EffectCenter"
	effect_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_center.alignment = BoxContainer.ALIGNMENT_CENTER
	effect_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_center.add_theme_constant_override("separation", 0)
	effect_slot.add_child(effect_center)

	var effect_label := RichTextLabel.new()
	effect_label.name = "EffectLabel"
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_label.bbcode_enabled = true
	var rules_text := _get_card_rules_text(card.description)
	var rules_fit_content := card.description.length() <= SHORT_RULE_BREAK_LIMIT
	effect_label.fit_content = rules_fit_content
	effect_label.scroll_active = false
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.text = "[center]%s[/center]" % rules_text
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER if rules_fit_content else Control.SIZE_EXPAND_FILL
	)
	effect_label.add_theme_color_override("default_color", palette.text)
	effect_label.add_theme_font_size_override("normal_font_size", 10 if is_market_card else 12)
	effect_label.add_theme_font_size_override("bold_font_size", 10 if is_market_card else 12)
	if body_font != null:
		effect_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		effect_label.add_theme_font_override("bold_font", body_bold_font)
	effect_center.add_child(effect_label)

	# Footer: cost and type along the bottom edge.
	var meta_row := HBoxContainer.new()
	meta_row.name = "MetaRow"
	meta_row.custom_minimum_size = Vector2(0, 18 if is_market_card else 20)
	meta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_row.add_theme_constant_override("separation", 2 if is_market_card else 4)
	layout.add_child(meta_row)

	var type_label := Label.new()
	type_label.name = "TypeLabel"
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.custom_minimum_size = Vector2(0, 14 if is_market_card else 18)
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	type_label.text = card.card_type.to_upper()
	type_label.add_theme_color_override(
		"font_color",
		_get_card_type_accent(card.card_type).lightened(0.1)
	)
	type_label.add_theme_font_size_override("font_size", 8 if is_market_card else 12)
	if body_bold_font != null:
		type_label.add_theme_font_override("font", body_bold_font)
	meta_row.add_child(type_label)

	if card.victory_points > 0 or card.score_per_cards > 0:
		if icon_textures.has("victory"):
			meta_row.add_child(
				_create_icon(
					icon_textures["victory"],
					Vector2(9, 9) if is_market_card else Vector2(14, 14),
					COLOR_BRASS
				)
			)
		var victory_label := Label.new()
		victory_label.custom_minimum_size = Vector2(0, 14 if is_market_card else 18)
		victory_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		victory_label.text = (
			"%d VP" % card.victory_points
			if card.victory_points > 0
			else "VP / %d" % card.score_per_cards
		)
		victory_label.add_theme_color_override(
			"font_color",
			COLOR_VICTORY_ACCENT.lightened(0.08)
		)
		victory_label.add_theme_font_size_override("font_size", 8 if is_market_card else 12)
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
		pile_label.add_theme_font_size_override("font_size", 8 if is_market_card else 12)
		if body_bold_font != null:
			pile_label.add_theme_font_override("font", body_bold_font)
		meta_row.add_child(pile_label)

	button.add_child(_create_price_badge(game_state.get_effective_cost(card)))

	return button


func _create_price_badge(cost: int) -> Control:
	var badge := Control.new()
	badge.name = "PriceBadge"
	badge.custom_minimum_size = Vector2(32, 32)
	badge.size = Vector2(32, 32)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.position = Vector2(6, 4)
	badge.z_index = 4

	var coin_face := PanelContainer.new()
	coin_face.name = "CoinFace"
	coin_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_face.add_theme_stylebox_override(
		"panel",
		_make_coin_style(COLOR_BRASS.lightened(0.08), COLOR_WALNUT_DARK, 2, 16)
	)
	badge.add_child(coin_face)
	coin_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var inner_ring := PanelContainer.new()
	inner_ring.name = "InnerRing"
	inner_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_ring.position = Vector2(4, 4)
	inner_ring.size = Vector2(24, 24)
	inner_ring.add_theme_stylebox_override(
		"panel",
		_make_coin_style(COLOR_BRASS.lightened(0.22), COLOR_BRASS.darkened(0.34), 2, 12)
	)
	badge.add_child(inner_ring)

	if icon_textures.has("coin"):
		var stamp := TextureRect.new()
		stamp.name = "CoinStamp"
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp.texture = icon_textures["coin"]
		stamp.modulate = Color(0.36, 0.22, 0.08, 0.24)
		stamp.position = Vector2(8, 8)
		stamp.size = Vector2(16, 16)
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.add_child(stamp)

	var glint := ColorRect.new()
	glint.name = "CoinGlint"
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glint.color = Color(1.0, 0.92, 0.58, 0.58)
	glint.position = Vector2(8, 6)
	glint.size = Vector2(12, 2)
	badge.add_child(glint)

	for dot_position in [
		Vector2(15, 4),
		Vector2(24, 15),
		Vector2(15, 24),
		Vector2(4, 15),
	]:
		badge.add_child(_create_coin_rivet(dot_position))

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.text = str(cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_color_override("font_color", COLOR_INK)
	cost_label.add_theme_color_override("font_shadow_color", COLOR_BRASS.lightened(0.34))
	cost_label.add_theme_constant_override("shadow_offset_x", 1)
	cost_label.add_theme_constant_override("shadow_offset_y", 1)
	cost_label.add_theme_font_size_override("font_size", 14)
	if title_font != null:
		cost_label.add_theme_font_override("font", title_font)
	elif body_bold_font != null:
		cost_label.add_theme_font_override("font", body_bold_font)
	badge.add_child(cost_label)
	cost_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cost_label.offset_left = 0
	cost_label.offset_top = 2
	cost_label.offset_right = 0
	cost_label.offset_bottom = 2
	return badge


func _make_coin_style(
	color: Color,
	border_color: Color,
	border_width: int,
	radius: int
) -> StyleBoxFlat:
	var coin_style := _make_flat_card_style(
		COLOR_BRASS.lightened(0.08),
		border_color,
		border_width
	)
	coin_style.bg_color = color
	coin_style.set_corner_radius_all(radius)
	coin_style.shadow_color = Color(0, 0, 0, 0.62)
	coin_style.shadow_size = 4
	coin_style.shadow_offset = Vector2(1, 2)
	return coin_style


func _create_coin_rivet(position: Vector2) -> PanelContainer:
	var rivet := PanelContainer.new()
	rivet.name = "CoinRivet"
	rivet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rivet.position = position
	rivet.size = Vector2(3, 3)
	rivet.add_theme_stylebox_override(
		"panel",
		_make_coin_style(COLOR_BRASS.lightened(0.34), COLOR_BRASS.darkened(0.42), 1, 2)
	)
	return rivet


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
	if not motion_enabled:
		button.scale = target_scale
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
	if not motion_enabled:
		control.scale = target_scale
		return
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
	preview_meta_label.text = (
		"%s  |  COST %d"
		% [card.card_type.to_upper(), game_state.get_effective_cost(card)]
	)
	if not card.card_group.is_empty():
		preview_meta_label.text += "  |  %s" % card.card_group.to_upper()
	if visual_state.begins_with("market_"):
		preview_meta_label.text += "  |  %d LEFT" % game_state.get_supply_count(card.id)
	card_preview.set_meta("card_type", card.card_type)
	card_preview.set_meta("card_base_color", _get_card_surface_color(card.card_type))
	preview_art.texture = _load_card_texture(card.art_id)
	preview_art_frame.visible = preview_art.texture != null
	preview_art_frame.add_theme_stylebox_override(
		"panel",
		_make_flat_card_style(
			COLOR_WALNUT_DARK,
			_get_card_type_accent(card.card_type),
			4
		)
	)
	preview_effect_label.text = "[center]%s[/center]" % _get_card_rules_text(card.description)
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
				"border": COLOR_SLATE.lightened(0.1),
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.lightened(0.02),
			}
		MARKET_AFFORDABLE:
			return {
				"border": COLOR_FOREST.lightened(0.16),
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.lightened(0.02),
			}
		MARKET_UNAFFORDABLE:
			return {
				"border": COLOR_UNAVAILABLE,
				"text": COLOR_PARCHMENT.darkened(0.06),
				"muted": COLOR_PARCHMENT.darkened(0.18),
			}
		"kingdom_browser", "kingdom_detail":
			return {
				"border": COLOR_BRASS.darkened(0.02),
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.lightened(0.02),
			}
		_:
			return {
				"border": COLOR_UNAVAILABLE.darkened(0.12),
				"text": COLOR_PARCHMENT.darkened(0.06),
				"muted": COLOR_PARCHMENT.darkened(0.18),
			}


func _get_card_surface_color(card_type: String) -> Color:
	match card_type:
		"resource":
			return COLOR_RESOURCE_CARD
		"victory":
			return COLOR_VICTORY_CARD
		_:
			return COLOR_ACTION_CARD


func _get_card_type_accent(card_type: String) -> Color:
	match card_type:
		"resource":
			return COLOR_RESOURCE_ACCENT
		"victory":
			return COLOR_VICTORY_ACCENT
		_:
			return COLOR_ACTION_ACCENT


func _make_card_style(color: Color, border_color: Color, border_width: int) -> StyleBox:
	var style := _make_flat_card_style(color, border_color, border_width)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
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
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 4
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
	var style := _make_flat_card_style(surface_color, border_color, 5)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 16
	return style


func _get_preview_type_modulate(surface_color: Color) -> Color:
	return Color(
		clampf(surface_color.r / COLOR_CARD_BROWN.r, 0.72, 1.42),
		clampf(surface_color.g / COLOR_CARD_BROWN.g, 0.72, 1.42),
		clampf(surface_color.b / COLOR_CARD_BROWN.b, 0.72, 1.42),
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
	if not motion_enabled:
		ghost.queue_free()
		return
	duration = _action_animation_duration(duration)
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
	if not motion_enabled:
		ghost.queue_free()
		return
	duration = _action_animation_duration(duration)
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
	var stat := hud_row.find_child(stat_name, true, false) as Control
	if stat == null:
		return hud_panel.get_global_rect().get_center()
	return stat.get_global_rect().get_center()


func _pulse_control(control: Control, color: Color) -> void:
	var original_color := control.modulate
	control.modulate = color
	control.scale = Vector2(1.08, 1.08)
	control.pivot_offset = control.size * 0.5
	if not motion_enabled:
		control.modulate = original_color
		control.scale = Vector2.ONE
		return
	var pulse_in_seconds := _action_animation_duration(0.16)
	var pulse_out_seconds := _action_animation_duration(0.2)
	var tween := create_tween()
	tween.bind_node(control)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, pulse_in_seconds)
	tween.tween_property(control, "modulate", original_color, pulse_out_seconds)


func _action_animation_duration(base_seconds: float) -> float:
	return base_seconds / maxf(0.1, action_animation_speed)


func _clear_animation_layer() -> void:
	for child in animation_layer.get_children():
		child.queue_free()


func _play_ui_sound(sound_name: String) -> void:
	if not audio_enabled or not ui_sound_players.has(sound_name):
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
	pending_cleanup_ghosts = _capture_cleanup_cards()
	_play_ui_sound("end_turn")
	turn_manager.end_turn()
	_refresh_ui()


func _on_turn_completed(game_is_over: bool) -> void:
	_refresh_ui()
	_animate_cleanup_cards(pending_cleanup_ghosts)
	pending_cleanup_ghosts.clear()
	if game_is_over:
		_show_final_score(turn_manager.final_score)
	else:
		call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _on_home_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_screen(true)


func _on_home_new_game_pressed() -> void:
	_play_ui_sound("button_click")
	_start_new_game(true)


func _on_home_continue_pressed() -> void:
	if not has_active_game:
		return
	_play_ui_sound("button_click")
	_hide_home_screen()


func _on_home_settings_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_tab("settings")


func _on_home_kingdoms_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_tab("kingdoms")


func _on_home_audio_toggled(enabled: bool) -> void:
	audio_enabled = enabled
	_play_ui_sound("button_click")


func _on_home_motion_toggled(enabled: bool) -> void:
	motion_enabled = enabled
	_play_ui_sound("button_click")


func _on_home_noise_changed(value: float) -> void:
	home_noise_amount = value
	_set_noise_amount(home_noise_overlay, home_noise_amount)


func _on_table_noise_changed(value: float) -> void:
	table_noise_amount = value
	_set_noise_amount(table_noise_overlay, table_noise_amount)


func _on_action_animation_speed_changed(value: float) -> void:
	action_animation_speed = value


func _on_kingdom_tab_pressed(kingdom: String) -> void:
	selected_home_kingdom = kingdom
	selected_home_kingdom_card_id = ""
	_play_ui_sound("button_click")
	_refresh_kingdom_tab()


func _on_kingdom_toggled(enabled: bool, kingdom: String) -> void:
	game_state.set_kingdom_enabled(kingdom, enabled)
	if selected_home_kingdom != kingdom:
		selected_home_kingdom = kingdom
	_refresh_kingdom_tab()


func _on_kingdom_card_selected(card_id: String) -> void:
	selected_home_kingdom_card_id = card_id
	if game_state.card_catalog.has(card_id):
		var card: CardDefinition = game_state.card_catalog[card_id]
		selected_home_kingdom = game_state.get_card_kingdom(card)
	_play_ui_sound("button_click")
	_refresh_kingdom_tab()


func _on_kingdom_card_toggled(enabled: bool, card_id: String) -> void:
	selected_home_kingdom_card_id = card_id
	if game_state.card_catalog.has(card_id):
		var card: CardDefinition = game_state.card_catalog[card_id]
		selected_home_kingdom = game_state.get_card_kingdom(card)
	game_state.set_card_enabled_for_market(card_id, enabled)
	_refresh_kingdom_tab()


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
	if not motion_enabled:
		end_game_overlay.modulate.a = 1.0
		end_game_panel.scale = Vector2.ONE
		return
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
		if child is Container:
			var nested := _find_card_button(child as Container, card_id)
			if nested != null:
				return nested
	return null
