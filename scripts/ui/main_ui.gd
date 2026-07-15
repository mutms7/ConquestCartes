extends Control

const RelicCatalog := preload("res://scripts/core/relic_catalog.gd")
const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

const HAND_PLAYABLE := "hand_playable"
const HAND_UNPLAYABLE := "hand_unplayable"
const MARKET_AFFORDABLE := "market_affordable"
const MARKET_UNAFFORDABLE := "market_unaffordable"
const MARKET_NEUTRAL := "market_neutral"
const CARD_HOVER_SCALE := Vector2(1.03, 1.03)
const HAND_HOVER_SCALE := Vector2(1.1, 1.1)
const CARD_NORMAL_SCALE := Vector2.ONE
# Distance (px) from the hand row's bottom edge down to the shared fan pivot.
# Larger = gentler arc. Card centres ride an arc around this point (the spread).
const HAND_FAN_PIVOT_DROP := 360.0
# How much each card actually tilts, as a fraction of its arc angle. Lower keeps
# the same fan spread but stands the card faces flatter / more upright.
const HAND_FAN_TILT := 0.42
const HOVER_ANIMATION_SECONDS := 0.08
const CARD_MOVE_SECONDS := 0.18
const CARD_DRAW_SECONDS := 0.16
const CLEANUP_SECONDS := 0.2
const TABLE_SCALE := 0.667
const TOP_BAR_HEIGHT := 55.0
const BOTTOM_BAND_HEIGHT := 276.0
const CARD_FACE_SIZE := Vector2(123, 165)
const PLAY_AREA_PANEL_HEIGHT := 76.0
const PLAY_AREA_CONTENT_HEIGHT := 64.0
const PLAYED_CARD_SIZE := Vector2(72, 64)
const PLAYED_CARD_ART_HEIGHT := 45.0
const CARD_ART_HEIGHT := 85.0
const HAND_CARD_ART_HEIGHT := 91.0
const CARD_ART_OPACITY := 1.0
const CARD_TEXT_SCRIM_Y := 85.0
const CARD_NAME_Y := 88.0
const CARD_NAME_HEIGHT := 20.0
const CARD_EFFECT_Y := 110.0
const CARD_EFFECT_HEIGHT := 42.0
const CARD_META_Y := 153.0
const CARD_META_HEIGHT := 10.0
const HUD_LEDGER_WIDTH := 158.0
const RIGHT_DOCK_WIDTH := 202.0
const END_TURN_BUTTON_WIDTH := 188.0
const PLAYER_STATUS_ROW_HEIGHT := 49.0
const PLAYER_STATUS_COOLDOWN_BAR_HEIGHT := 5.0
const PILE_FACE_SIZE := Vector2(105, 145)
const PREVIEW_SIZE := Vector2(252, 340)
const PREVIEW_ART_HEIGHT := 184.0
const PREVIEW_EDGE_MARGIN := 16.0
const SHORT_RULE_BREAK_LIMIT := 72
const HOME_ART_PATH := "res://assets/cards/sunspire_monument.png"
const CARD_RULE_SIDE_MARGIN := 9
const CARD_RULE_TOP_MARGIN := 1
const CARD_RULE_BOTTOM_MARGIN := 7
const NETWORK_PORT := 27041
const NETWORK_DEFAULT_ADDRESS := "127.0.0.1"
const NETWORK_MAX_PLAYERS := 4
const NETWORK_MODE_LOCAL := "local"
const NETWORK_MODE_ONLINE := "online"
const ONLINE_RELAY_PATH := "/api/relay"
# The relay keeps lobby state in memory, so it must run as a single long-lived
# process, NOT a serverless function (a second serverless instance can't see
# rooms created by the first, which silently kicks the host out of the lobby).
# Point every build at that one dedicated host below. CONQUEST_CARTES_RELAY_URL
# overrides it for local dev (e.g. `node api/relay.js` at
# http://127.0.0.1:3000/api/relay).
const ONLINE_RELAY_DEFAULT_URL := "https://conquest-cartes-relay.onrender.com/api/relay"
const ONLINE_LOBBY_CODE_LENGTH := 4
const ONLINE_RELAY_MAX_RECONNECT_ATTEMPTS := 3
const ONLINE_RELAY_RECONNECT_DELAY_SECONDS := 2.0
const ONLINE_RELAY_CONNECT_TIMEOUT_SECONDS := 10.0
const ONLINE_RELAY_POLL_INTERVAL_SECONDS := 0.35
# Players get one minute to read the board before the opening round begins.
const RESPITE_SECONDS := 60.0

const COLOR_PARCHMENT := Color("#ecdcb6")
const COLOR_PARCHMENT_LIGHT := Color("#f4e6c4")
const COLOR_CARD_BROWN := Color("#271c12")
const COLOR_CARD_BROWN_LIGHT := Color("#3c2a14")
const COLOR_RESOURCE_CARD := Color("#3c2a14")
const COLOR_ACTION_CARD := Color("#1c2d48")
const COLOR_VICTORY_CARD := Color("#36182d")
const COLOR_CURSE_CARD := Color("#32263f")
const COLOR_WALNUT := Color("#271c12")
const COLOR_WALNUT_DARK := Color("#150e08")
const COLOR_BRASS := Color("#e8c879")
const COLOR_FOREST := Color("#3d7d58")
const COLOR_OXBLOOD := Color("#a64b55")
const COLOR_SLATE := Color("#a87845")
const COLOR_INK := Color("#30251d")
const COLOR_UNAVAILABLE := Color("#77756f")
const COLOR_TREASURY_CARPET := Color("#5c3018")
const COLOR_BARRACKS_CARPET := Color("#3e2819")
const COLOR_ESTATES_CARPET := Color("#304027")
const COLOR_RESOURCE_ACCENT := Color("#f0bd58")
const COLOR_ACTION_ACCENT := Color("#7db6e8")
const COLOR_VICTORY_ACCENT := Color("#e08aa2")
const COLOR_CURSE_ACCENT := Color("#b49ad9")
# Menu surfaces (Settings / Kingdoms / Multiplayer / Lobby) are styled to match
# the dark, thin-brass-bordered home buttons that open them: a dark walnut
# interior with light parchment type, rather than a bright cream parchment card.
const COLOR_PARCHMENT_PANEL := Color(0.105, 0.075, 0.045, 0.98)
const COLOR_PARCHMENT_PANEL_DARK := Color(0.07, 0.05, 0.03, 0.98)
const COLOR_PARCHMENT_INK := Color("#f0dcab")
const COLOR_PARCHMENT_BODY := Color("#e4d4ad")
const COLOR_PARCHMENT_MUTED := Color("#9c8a64")
const COLOR_MENU_ACCENT := Color("#caa25a")
const COLOR_MENU_BORDER := Color(0.835, 0.667, 0.314, 0.5)

const TITLE_FONT_PATH := "res://assets/fonts/Cinzel/static/Cinzel-Bold.ttf"
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
	"logo": "res://assets/ui/logo_crest.svg",
}
const ICON_PATHS := {
	"coin": "res://assets/icons/ui/coin.png",
	"action": "res://assets/icons/ui/action.png",
	"buy": "res://assets/icons/ui/buy.png",
	"deck": "res://assets/icons/ui/deck.png",
	"discard": "res://assets/icons/ui/discard.png",
	"victory": "res://assets/icons/ui/victory.png",
}
const RELIC_ICON_PATH_TEMPLATE := "res://assets/icons/relics/%s.png"
const RELIC_RAIL_ICON_SIZE := Vector2(32, 32)
const RELIC_DRAFT_ICON_SIZE := Vector2(74, 74)
const RELIC_PREVIEW_ICON_SIZE := Vector2(110, 110)
const SOUND_PATHS := {
	"button_click": "res://assets/audio/ui/button_click.ogg",
	"play_card": "res://assets/audio/ui/play_card.ogg",
	"buy_card": "res://assets/audio/ui/buy_card.ogg",
	"end_turn": "res://assets/audio/ui/end_turn.ogg",
	"draw": "res://assets/audio/ui/draw.ogg",
	"discard": "res://assets/audio/ui/discard.ogg",
	"game_end": "res://assets/audio/ui/game_end.ogg",
}
const BACKGROUND_MUSIC_PATH := "res://assets/audio/dominion_board_game_ambience.mp3"
# Offset applied on top of the slider curve. -3 dB puts the loudest music setting
# at roughly what the old 75%-ish slider used to reach, and shifts the whole
# range down so the quiet end sits genuinely soft in the background.
const BACKGROUND_MUSIC_VOLUME_DB := -3.0
const DEFAULT_AUDIO_VOLUME := 0.7
const VOLUME_SLIDER_STEP := 0.01
const VOLUME_RESPONSE_EXPONENT := 2.0
# Sound effects get their own volume slider, mapped with the same perceptual
# curve. At the top of the slider they play at SFX_VOLUME_DB.
const DEFAULT_SFX_VOLUME := 0.6
const SFX_VOLUME_DB := 0.0
# The New Game click is played much quieter than a normal button press.
const NEW_GAME_SOUND_OFFSET_DB := -14.0

var game_state := GameState.new()
var turn_manager := TurnManager.new()
var title_font: Font
var body_font: Font
var body_bold_font: Font
var ui_textures: Dictionary = {}
var icon_textures: Dictionary = {}
var relic_icon_cache: Dictionary = {}
var ui_sound_players: Dictionary = {}
var background_music_player: AudioStreamPlayer
var background_music_loading := false
var background_music_start_requested := false
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
var direct_hand_choice := false
var direct_hand_tokens: Dictionary = {}
var direct_supply_gain_choice := false
var direct_supply_gain_tokens: Dictionary = {}
var choice_minimized := false
var choice_restore_button: Button
var choice_minimize_button: Button
var trash_pile_button: Button
var left_ledger: PanelContainer
var right_ledger: PanelContainer
var hand_column: VBoxContainer
var top_bar: PanelContainer
var player_status_list: VBoxContainer
var player_status_rows: Dictionary = {}
var discard_pile_art: TextureRect
var discard_pile_scrim: ColorRect
var bazaar_button: Button
var treasury_carpet: PanelContainer
var barracks_carpet: PanelContainer
var estates_carpet: PanelContainer
var market_resource_container: GridContainer
var market_action_container: GridContainer
var market_victory_container: GridContainer
var briar_hex_tab: Button
var pending_cleanup_ghosts: Array[Control] = []
var home_overlay: Control
var menu_backdrop: Control
var home_menu_root: Control
var home_new_game_button: Button
var home_continue_button: Button
var home_resign_button: Button
var home_create_lobby_button: Button
var home_join_lobby_button: Button
var home_create_online_button: Button
var home_join_online_button: Button
var home_lobby_address_input: LineEdit
var home_lobby_status_label: Label
var player_status_label: Label
var home_settings_panel: PanelContainer
var home_multiplayer_panel: PanelContainer
var home_lobby_panel: PanelContainer
var home_lobby_seat_list: VBoxContainer
var home_lobby_rules_summary: Label
var home_lobby_start_button: Button
var home_lobby_turn_based_toggle: CheckButton
var home_lobby_edit_kingdom_button: Button
var lobby_cooldown_slider: HSlider
var home_kingdoms_panel: PanelContainer
var home_kingdom_tab_list: VBoxContainer
var home_kingdom_title_label: Label
var home_kingdom_summary_label: Label
var home_kingdom_card_grid: GridContainer
var home_kingdom_detail_host: VBoxContainer
var selected_home_kingdom := GameState.BASE_KINGDOM
var selected_home_kingdom_card_id := ""
var active_lobby_player_count := 1
var network_enabled := false
var network_is_host := false
var network_mode := NETWORK_MODE_LOCAL
var local_player_index := 0
var network_peer_to_player: Dictionary = {}
var online_relay_connected := false
var online_relay_role := ""
var online_relay_lobby_code := ""
var online_relay_client_id := ""
var online_relay_host_id := ""
var online_relay_url_override := ""
var online_relay_reconnect_attempts := 0
var online_relay_reconnect_timer := 0.0
var online_relay_connect_timer := 0.0
var online_relay_poll_timer := 0.0
var online_relay_poll_in_flight := false
var network_ready_seats: Array[int] = []
var lobby_ready_sent := false
var lobby_code_banner: PanelContainer
var lobby_code_value_label: Label
var lobby_panel_status_label: Label
var kingdom_return_tab := ""
# True once the host has actually opened the table. Online joiners wait in the
# lobby panel until the snapshot says the game started.
var network_table_open := false
var network_connected_seats: Array[int] = []
# Opening 60-second turn timer (client-local; it changes no game state, just
# gates play so each player can read the market and starting hand first). It is
# shown as a countdown on the End Turn button.
var respite_remaining := 0.0
# Seats that have readied up during the opening timer. Once every connected seat
# is ready the timer is skipped. Host-authoritative and synced in the snapshot.
var respite_ready_seats: Array[int] = []
var relic_overlay: Control
var relic_options_row: HBoxContainer
var relic_overlay_offer: Array[String] = []

# End-of-game summary and the solo scoring-relic draft (both built in code).
var summary_overlay: Control
var summary_content: VBoxContainer
var summary_title_label: Label
var scoring_relic_overlay: Control
var scoring_relic_options_row: HBoxContainer
var scoring_relic_offer: Array[String] = []
var relics_rail_row: HBoxContainer
var relic_preview: PanelContainer
var relic_preview_icon_host: CenterContainer
var relic_preview_name_label: Label
var relic_preview_meta_label: Label
var relic_preview_description_label: Label
var active_preview_kind := ""
var active_preview_id := ""
var last_play_area_ids: Array[String] = []
var last_play_area_owner: int = 0
var home_noise_overlay: TextureRect
var table_noise_overlay: TextureRect
var home_noise_slider: HSlider
var table_noise_slider: HSlider
var action_animation_speed_slider: HSlider
var background_music_slider: HSlider
var sfx_volume_slider: HSlider
var end_turn_cooldown_slider: HSlider
var home_audio_toggle: CheckButton
var home_music_toggle: CheckButton
var home_motion_toggle: CheckButton
var fullscreen_toggle: CheckButton
var noise_texture: Texture2D
var lobby_pending_mode := "host"
var lobby_max_players := NETWORK_MAX_PLAYERS
var background_music_volume := DEFAULT_AUDIO_VOLUME
var music_enabled := true
var sfx_volume := DEFAULT_SFX_VOLUME
# The local player's chosen display name and whether opponents' chosen names are
# shown (off falls back to the "Player N" template). Both are local preferences;
# the name itself is synced to the table so it reaches everyone.
var player_display_name := "Player 1"
var show_opponent_names := true
var show_opponent_names_toggle: CheckButton
var lobby_name_input: LineEdit

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
@onready var hand_scroll: ScrollContainer = $Margin/Layout/HandPanel/HandMargin/HandScroll
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
@onready var final_summary_label: Label = (
	$EndGameOverlay/Center/Panel/Margin/Layout/SummaryLabel
)
@onready var play_again_button: Button = (
	$EndGameOverlay/Center/Panel/Margin/Layout/PlayAgainButton
)
@onready var end_game_home_button: Button = (
	$EndGameOverlay/Center/Panel/Margin/Layout/HomeButton
)
@onready var card_preview: PanelContainer = $CardPreview
@onready var preview_name_label: Label = $CardPreview/Margin/Layout/NameLabel
@onready var preview_meta_label: Label = $CardPreview/Margin/Layout/MetaLabel
@onready var preview_art_frame: PanelContainer = $CardPreview/Margin/Layout/ArtFrame
@onready var preview_art: TextureRect = $CardPreview/Margin/Layout/ArtFrame/Art
@onready var preview_effect_label: RichTextLabel = $CardPreview/Margin/Layout/EffectLabel

var card_desaturate_material: ShaderMaterial


func _ready() -> void:
	_load_optional_assets()
	_build_bottom_docks()
	_build_top_bar()
	_build_market_board()
	_build_home_screen()
	_build_relic_overlay()
	_build_relic_preview()
	_build_scoring_relic_overlay()
	_build_summary_overlay()
	_apply_imported_theme()
	_configure_choice_overlay()
	home_button.pressed.connect(_on_home_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	end_game_home_button.pressed.connect(_on_end_game_home_pressed)
	choice_skip_button.pressed.connect(_on_choice_skipped)
	choice_confirm_button.pressed.connect(_on_choice_confirmed)
	home_button.mouse_entered.connect(_on_hud_button_hovered.bind(home_button))
	home_button.mouse_exited.connect(_on_hud_button_unhovered.bind(home_button))
	end_turn_button.mouse_entered.connect(_on_hud_button_hovered.bind(end_turn_button))
	end_turn_button.mouse_exited.connect(_on_hud_button_unhovered.bind(end_turn_button))
	play_again_button.mouse_entered.connect(_on_hud_button_hovered.bind(play_again_button))
	play_again_button.mouse_exited.connect(_on_hud_button_unhovered.bind(play_again_button))
	end_game_home_button.mouse_entered.connect(
		_on_hud_button_hovered.bind(end_game_home_button)
	)
	end_game_home_button.mouse_exited.connect(
		_on_hud_button_unhovered.bind(end_game_home_button)
	)
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
	game_state.active_player_changed.connect(_on_active_player_changed)
	game_state.end_turn_cooldown_reduced.connect(_on_network_end_turn_cooldown_reduced)
	turn_manager.configure(game_state)
	turn_manager.turn_completed.connect(_on_turn_completed)
	turn_manager.turn_cleanup_started.connect(_on_turn_cleanup_started)
	multiplayer.peer_connected.connect(_on_network_peer_connected)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_network_connected_to_server)
	multiplayer.connection_failed.connect(_on_network_connection_failed)
	multiplayer.server_disconnected.connect(_on_network_server_disconnected)

	if not game_state.load_cards(CARD_DATA_PATH):
		push_error("Could not load card data from %s." % CARD_DATA_PATH)
		home_button.disabled = true
		end_turn_button.disabled = true
		if home_continue_button != null:
			home_continue_button.disabled = true
		return

	_refresh_kingdom_tab()
	_show_home_screen(false)
	_refresh_background_music()


func _process(delta: float) -> void:
	_poll_background_music_load()
	_keep_background_music_alive()
	_tick_online_relay_reconnect(delta)
	_tick_online_relay_poll(delta)
	if network_enabled:
		if network_is_host:
			_tick_network_cooldowns(delta)
		elif game_state.player.cooldown_remaining > 0.0:
			game_state.player.cooldown_remaining = maxf(
				0.0,
				game_state.player.cooldown_remaining - delta
			)
			if game_state.player.cooldown_remaining <= 0.0:
				game_state.player.cooldown_duration = 0.0
		_sync_turn_manager_to_local_player()
	else:
		turn_manager.tick(delta)
	if respite_remaining > 0.0:
		_tick_respite(delta)
	_refresh_end_turn_button()
	_refresh_player_status()


func _start_new_game(_is_restart: bool) -> void:
	_disconnect_network()
	if game_state.card_catalog.is_empty() or not game_state.has_enough_market_candidates():
		_refresh_home_controls()
		return
	_hide_home_screen()
	_hide_end_game_overlay()
	_hide_choice_overlay()
	_clear_animation_layer()
	active_lobby_player_count = 1
	if not game_state.setup_starting_game(active_lobby_player_count):
		push_error("Could not prepare a new game.")
		has_active_game = false
		end_turn_button.disabled = true
		_show_home_screen(false)
		return

	has_active_game = true
	turn_manager.start_first_turn()
	_apply_local_player_name(false)
	_start_respite()
	_refresh_ui()
	call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _start_lobby_game(player_count: int = 2) -> void:
	if game_state.card_catalog.is_empty() or not game_state.has_enough_market_candidates():
		_refresh_home_controls()
		return
	_hide_home_screen()
	_hide_end_game_overlay()
	_hide_choice_overlay()
	_clear_animation_layer()
	active_lobby_player_count = maxi(2, player_count)
	if not game_state.setup_starting_game(active_lobby_player_count):
		push_error("Could not prepare a multiplayer lobby.")
		has_active_game = false
		end_turn_button.disabled = true
		_show_home_screen(false)
		return
	has_active_game = true
	turn_manager.start_first_turn()
	_apply_local_player_name(false)
	_start_respite()
	_refresh_ui()
	call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _prepare_online_lobby_game(player_count: int = 2) -> void:
	if game_state.card_catalog.is_empty() or not game_state.has_enough_market_candidates():
		_refresh_home_controls()
		return
	_hide_end_game_overlay()
	_hide_choice_overlay()
	_clear_animation_layer()
	active_lobby_player_count = maxi(2, player_count)
	if not game_state.setup_starting_game(active_lobby_player_count):
		push_error("Could not prepare an online multiplayer lobby.")
		has_active_game = false
		end_turn_button.disabled = true
		return
	has_active_game = true
	turn_manager.start_first_turn()
	_refresh_ui()
	_refresh_home_controls()


func _host_network_lobby() -> void:
	if game_state.card_catalog.is_empty() or not game_state.has_enough_market_candidates():
		_refresh_home_controls()
		return
	_disconnect_network()
	var peer := ENetMultiplayerPeer.new()
	var max_players := clampi(lobby_max_players, 2, NETWORK_MAX_PLAYERS)
	var error := peer.create_server(NETWORK_PORT, max_players - 1)
	if error != OK:
		_set_lobby_status("Could not host lobby on port %d." % NETWORK_PORT)
		return
	multiplayer.multiplayer_peer = peer
	network_enabled = true
	network_is_host = true
	network_mode = NETWORK_MODE_LOCAL
	local_player_index = 0
	network_peer_to_player = {1: 0}
	_start_lobby_game(max_players)
	network_table_open = has_active_game
	_set_lobby_status("Hosting on port %d. Give players your IP address." % NETWORK_PORT)
	_queue_network_ui_refresh()
	_broadcast_network_snapshot()


func _join_network_lobby() -> void:
	if game_state.card_catalog.is_empty():
		_refresh_home_controls()
		return
	_disconnect_network()
	var address := NETWORK_DEFAULT_ADDRESS
	if home_lobby_address_input != null:
		address = home_lobby_address_input.text.strip_edges()
		if address.contains(":"):
			address = address.get_slice(":", 0)
	if address.is_empty():
		address = NETWORK_DEFAULT_ADDRESS
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, NETWORK_PORT)
	if error != OK:
		_set_lobby_status("Could not start connection to %s." % address)
		return
	multiplayer.multiplayer_peer = peer
	network_enabled = true
	network_is_host = false
	network_mode = NETWORK_MODE_LOCAL
	local_player_index = 1
	has_active_game = false
	_set_lobby_status("Connecting to %s:%d..." % [address, NETWORK_PORT])
	_refresh_home_controls()
	_queue_network_ui_refresh()


func _host_online_lobby() -> void:
	if game_state.card_catalog.is_empty() or not game_state.has_enough_market_candidates():
		_refresh_home_controls()
		return
	_disconnect_network()
	network_enabled = true
	network_is_host = true
	network_mode = NETWORK_MODE_ONLINE
	local_player_index = 0
	online_relay_role = "host"
	online_relay_lobby_code = ""
	online_relay_client_id = ""
	network_peer_to_player.clear()
	_set_lobby_status("Creating online lobby...")
	_refresh_home_controls()
	_connect_online_relay()


func _join_online_lobby() -> void:
	if game_state.card_catalog.is_empty():
		_refresh_home_controls()
		return
	var code := ""
	if home_lobby_address_input != null:
		code = _normalize_online_lobby_code(home_lobby_address_input.text)
	if code.length() != ONLINE_LOBBY_CODE_LENGTH:
		_set_lobby_status("Enter a 4-letter lobby code.")
		return
	_disconnect_network()
	network_enabled = true
	network_is_host = false
	network_mode = NETWORK_MODE_ONLINE
	local_player_index = 1
	has_active_game = false
	online_relay_role = "join"
	online_relay_lobby_code = code
	online_relay_client_id = ""
	network_peer_to_player.clear()
	_set_lobby_status("Joining online lobby %s..." % code)
	_refresh_home_controls()
	_connect_online_relay()


func _connect_online_relay() -> void:
	online_relay_connected = false
	online_relay_connect_timer = ONLINE_RELAY_CONNECT_TIMEOUT_SECONDS
	online_relay_poll_timer = 0.0
	online_relay_poll_in_flight = false
	_set_lobby_status("Contacting the online relay...")
	if online_relay_role == "host":
		_send_online_relay_message({
			"type": "create",
			"maxPlayers": lobby_max_players,
		})
	elif online_relay_role == "join":
		_send_online_relay_message({
			"type": "join",
			"code": online_relay_lobby_code,
		})
	else:
		_disconnect_network()
		_refresh_home_controls()
		_set_lobby_status("Choose Create Online or Join Online first.")


func _disconnect_network() -> void:
	var should_leave_online := (
		network_enabled
		and network_mode == NETWORK_MODE_ONLINE
		and not online_relay_lobby_code.is_empty()
		and not online_relay_client_id.is_empty()
	)
	if should_leave_online:
		_send_online_relay_leave(online_relay_lobby_code, online_relay_client_id)
	online_relay_connected = false
	online_relay_role = ""
	online_relay_lobby_code = ""
	online_relay_client_id = ""
	online_relay_host_id = ""
	online_relay_reconnect_attempts = 0
	online_relay_reconnect_timer = 0.0
	online_relay_poll_timer = 0.0
	online_relay_poll_in_flight = false
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	network_enabled = false
	network_is_host = false
	network_mode = NETWORK_MODE_LOCAL
	local_player_index = 0
	network_peer_to_player.clear()
	network_table_open = false
	network_connected_seats.clear()
	network_ready_seats.clear()
	lobby_ready_sent = false
	online_relay_connect_timer = 0.0


func _set_lobby_status(message: String) -> void:
	# The home menu and the lobby panel each carry a status line; keep both in
	# step so messages are visible from whichever screen is open.
	if home_lobby_status_label != null:
		home_lobby_status_label.text = message
	if lobby_panel_status_label != null:
		lobby_panel_status_label.text = message


func _tick_online_relay_poll(delta: float) -> void:
	if not online_relay_connected:
		return
	if not network_enabled or network_mode != NETWORK_MODE_ONLINE:
		return
	online_relay_poll_timer -= delta
	if online_relay_poll_timer > 0.0:
		return
	online_relay_poll_timer = ONLINE_RELAY_POLL_INTERVAL_SECONDS
	_poll_online_relay()


func _poll_online_relay() -> void:
	if online_relay_poll_in_flight:
		return
	if online_relay_client_id.is_empty() or online_relay_lobby_code.is_empty():
		return
	online_relay_poll_in_flight = true
	_send_online_relay_message({"type": "poll"})


func _on_online_relay_closed() -> void:
	var was_online := network_enabled and network_mode == NETWORK_MODE_ONLINE
	var was_host := network_is_host
	var never_connected := not online_relay_connected
	online_relay_connected = false
	online_relay_connect_timer = 0.0
	online_relay_poll_timer = 0.0
	online_relay_poll_in_flight = false
	if not was_online:
		_disconnect_network()
		return
	if never_connected and not has_active_game:
		# The relay could not be reached at all (no code was ever issued).
		_disconnect_network()
		_refresh_home_controls()
		_set_lobby_status(
			"Could not reach the online relay. Check your internet connection and try again."
		)
		return
	if (
		not was_host
		and has_active_game
		and not online_relay_lobby_code.is_empty()
		and online_relay_reconnect_attempts < ONLINE_RELAY_MAX_RECONNECT_ATTEMPTS
	):
		# The socket dropped mid-game (relay hiccup). Keep the lobby code and
		# quietly rejoin; the host re-seats us and sends a fresh snapshot.
		online_relay_reconnect_attempts += 1
		online_relay_reconnect_timer = ONLINE_RELAY_RECONNECT_DELAY_SECONDS
		online_relay_role = "join"
		_set_lobby_status(
			"Connection lost. Rejoining %s (attempt %d of %d)..."
			% [
				online_relay_lobby_code,
				online_relay_reconnect_attempts,
				ONLINE_RELAY_MAX_RECONNECT_ATTEMPTS,
			]
		)
		return
	_disconnect_network()
	_refresh_home_controls()
	if not was_host:
		has_active_game = false
		_show_home_screen(false)
		_set_lobby_status("Host disconnected.")
	else:
		_set_lobby_status("Online relay disconnected.")


func _handle_online_relay_message(message: Dictionary) -> void:
	match str(message.get("type", "")):
		"hello":
			online_relay_client_id = str(message.get("clientId", online_relay_client_id))
		"created":
			_on_online_lobby_created(message)
		"joined":
			_on_online_lobby_joined(message)
		"peer_joined":
			_on_online_relay_peer_joined(str(message.get("clientId", "")))
		"peer_left":
			_on_online_relay_peer_left(str(message.get("clientId", "")))
		"signal":
			var payload = message.get("payload", {})
			if typeof(payload) == TYPE_DICTIONARY:
				_handle_online_relay_signal(str(message.get("from", "")), payload)
		"closed":
			_on_network_server_disconnected()
		"error":
			_set_lobby_status(str(message.get("message", "Online relay error.")))
			var error_code := str(message.get("code", ""))
			if not has_active_game:
				_disconnect_network()
			elif error_code == "not_found" or error_code == "full":
				# A mid-game rejoin attempt hit a dead or full lobby; give up.
				_disconnect_network()
				has_active_game = false
				_show_home_screen(false)
				_refresh_home_controls()
		_:
			pass


func _on_online_lobby_created(message: Dictionary) -> void:
	online_relay_lobby_code = str(message.get("code", ""))
	online_relay_client_id = str(message.get("clientId", online_relay_client_id))
	online_relay_host_id = online_relay_client_id
	online_relay_connected = true
	online_relay_connect_timer = 0.0
	online_relay_poll_timer = 0.0
	online_relay_poll_in_flight = false
	online_relay_reconnect_attempts = 0
	network_peer_to_player.clear()
	network_peer_to_player[online_relay_client_id] = 0
	if home_lobby_address_input != null:
		home_lobby_address_input.text = online_relay_lobby_code
	var max_players := clampi(int(message.get("maxPlayers", lobby_max_players)), 2, NETWORK_MAX_PLAYERS)
	_prepare_online_lobby_game(max_players)
	_set_lobby_status("Online lobby %s. Share this code." % online_relay_lobby_code)
	_broadcast_network_snapshot()


func _on_online_lobby_joined(message: Dictionary) -> void:
	online_relay_lobby_code = str(message.get("code", online_relay_lobby_code))
	online_relay_client_id = str(message.get("clientId", online_relay_client_id))
	online_relay_host_id = str(message.get("hostId", online_relay_host_id))
	online_relay_connected = true
	online_relay_connect_timer = 0.0
	online_relay_poll_timer = 0.0
	online_relay_poll_in_flight = false
	online_relay_reconnect_attempts = 0
	if home_lobby_address_input != null:
		home_lobby_address_input.text = online_relay_lobby_code
	_set_lobby_status("Joined %s. Waiting for the host..." % online_relay_lobby_code)
	_refresh_home_controls()


func _on_online_relay_peer_joined(client_id: String) -> void:
	if not network_is_host or client_id.is_empty():
		return
	var player_index := _next_open_network_player_index()
	if player_index == -1:
		_send_online_signal(client_id, {"method": "lobby_full"})
		return
	network_peer_to_player[client_id] = player_index
	_send_online_signal(client_id, {
		"method": "set_local_player_index",
		"player_index": player_index,
	})
	_set_lobby_status(
		"%s joined online lobby %s."
		% [game_state.players[player_index].player_name, online_relay_lobby_code]
	)
	_broadcast_network_snapshot()
	# Rebuild the host's seat list right away; without this the host only sees
	# the new player once they press I'M READY.
	_refresh_lobby_panel()


func _on_online_relay_peer_left(client_id: String) -> void:
	if not network_is_host:
		return
	var seat := int(network_peer_to_player.get(client_id, -1))
	network_peer_to_player.erase(client_id)
	if seat >= 0:
		network_ready_seats.erase(seat)
	_set_lobby_status("Player disconnected. Online lobby %s remains open." % online_relay_lobby_code)
	_broadcast_network_snapshot()
	_refresh_lobby_panel()


func _handle_online_relay_signal(sender_id: String, payload: Dictionary) -> void:
	# Host-originated methods are only honoured on clients when they really came
	# from the host, so a hostile peer cannot spoof snapshots or reseat players.
	var sender_is_host := (
		not network_is_host
		and not sender_id.is_empty()
		and (online_relay_host_id.is_empty() or sender_id == online_relay_host_id)
	)
	match str(payload.get("method", "")):
		"apply_network_snapshot":
			if sender_is_host and typeof(payload.get("snapshot", {})) == TYPE_DICTIONARY:
				_apply_network_snapshot(payload["snapshot"])
		"set_local_player_index":
			if sender_is_host:
				_rpc_set_local_player_index(int(payload.get("player_index", 0)))
		"request_play_card":
			_handle_network_play_card_request(
				_player_index_for_relay_client(sender_id),
				str(payload.get("card_id", ""))
			)
		"request_buy_card":
			_handle_network_buy_card_request(
				_player_index_for_relay_client(sender_id),
				str(payload.get("card_id", ""))
			)
		"request_end_turn":
			_handle_network_end_turn_request(_player_index_for_relay_client(sender_id))
		"request_choice":
			var raw_tokens = payload.get("tokens", [])
			if typeof(raw_tokens) == TYPE_ARRAY:
				_handle_network_choice_request(_player_index_for_relay_client(sender_id), raw_tokens)
		"request_relic_choice":
			_handle_network_relic_choice_request(
				_player_index_for_relay_client(sender_id),
				str(payload.get("relic_id", ""))
			)
		"lobby_ready":
			_handle_network_lobby_ready(_player_index_for_relay_client(sender_id))
		"request_respite_ready":
			_handle_network_respite_ready(_player_index_for_relay_client(sender_id))
		"set_name":
			_handle_network_set_name(
				_player_index_for_relay_client(sender_id), str(payload.get("name", ""))
			)
		"lobby_full":
			if sender_is_host:
				_disconnect_network()
				has_active_game = false
				_show_home_screen(false)
				_set_lobby_status("That online lobby is already full.")
				_refresh_home_controls()
		_:
			pass


func _send_online_relay_message(message: Dictionary) -> void:
	var relay_message := message.duplicate(true)
	if not online_relay_client_id.is_empty() and not relay_message.has("clientId"):
		relay_message["clientId"] = online_relay_client_id
	if not online_relay_lobby_code.is_empty() and not relay_message.has("code"):
		relay_message["code"] = online_relay_lobby_code
	_send_online_relay_http_request(relay_message)


func _send_online_relay_leave(lobby_code: String, client_id: String) -> void:
	_send_online_relay_http_request(
		{
			"type": "leave",
			"code": lobby_code,
			"clientId": client_id,
		},
		true
	)


func _send_online_relay_http_request(message: Dictionary, ignore_response: bool = false) -> void:
	var request := HTTPRequest.new()
	request.timeout = ONLINE_RELAY_CONNECT_TIMEOUT_SECONDS
	add_child(request)
	var request_type := str(message.get("type", ""))
	if ignore_response:
		request_type = "leave"
	request.request_completed.connect(
		_on_online_relay_request_completed.bind(request, request_type)
	)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
	])
	var error := request.request(
		_get_online_relay_url(),
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(message)
	)
	if error != OK:
		request.queue_free()
		_handle_online_relay_request_failed(request_type)


func _on_online_relay_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest,
	request_type: String
) -> void:
	if is_instance_valid(request):
		request.queue_free()
	if request_type == "poll":
		online_relay_poll_in_flight = false
	if request_type == "leave":
		return
	if not network_enabled or network_mode != NETWORK_MODE_ONLINE:
		return
	if request_type == "create" and online_relay_role != "host":
		return
	if request_type == "join" and online_relay_role != "join":
		return
	var response_text := body.get_string_from_utf8()
	var parsed_response = JSON.parse_string(response_text)
	var handled_message := false
	if typeof(parsed_response) == TYPE_DICTIONARY:
		var messages = parsed_response.get("messages", [])
		if typeof(messages) == TYPE_ARRAY:
			for relay_message in messages:
				if typeof(relay_message) == TYPE_DICTIONARY:
					handled_message = true
					_handle_online_relay_message(relay_message)
		elif parsed_response.has("type"):
			handled_message = true
			_handle_online_relay_message(parsed_response)
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if not handled_message:
			_handle_online_relay_request_failed(request_type)


func _handle_online_relay_request_failed(request_type: String) -> void:
	if request_type == "poll":
		online_relay_poll_in_flight = false
	if request_type == "leave":
		return
	if request_type == "create" or request_type == "join":
		_disconnect_network()
		_refresh_home_controls()
		_set_lobby_status("Could not reach the online relay. Check your connection and try again.")
		return
	if network_enabled and network_mode == NETWORK_MODE_ONLINE:
		_on_online_relay_closed()


func _send_online_signal(target: String, payload: Dictionary) -> void:
	_send_online_relay_message({
		"type": "signal",
		"target": target,
		"payload": payload,
	})


func _send_network_client_request(method: String, payload: Dictionary = {}) -> void:
	if network_mode == NETWORK_MODE_ONLINE:
		var online_payload := payload.duplicate(true)
		online_payload["method"] = method
		_send_online_signal("host", online_payload)
		return
	match method:
		"request_play_card":
			rpc_id(1, "_rpc_request_play_card", str(payload.get("card_id", "")))
		"request_buy_card":
			rpc_id(1, "_rpc_request_buy_card", str(payload.get("card_id", "")))
		"request_end_turn":
			rpc_id(1, "_rpc_request_end_turn")
		"request_choice":
			rpc_id(1, "_rpc_request_choice", payload.get("tokens", []))
		"request_relic_choice":
			rpc_id(1, "_rpc_request_relic_choice", str(payload.get("relic_id", "")))
		"request_respite_ready":
			rpc_id(1, "_rpc_request_respite_ready")
		"set_name":
			rpc_id(1, "_rpc_request_set_name", str(payload.get("name", "")))


func _get_online_relay_url() -> String:
	if not online_relay_url_override.is_empty():
		return online_relay_url_override
	var env_url := OS.get_environment("CONQUEST_CARTES_RELAY_URL")
	if not env_url.is_empty():
		return env_url
	# Web builds used to derive the relay URL from window.location.origin, but the
	# relay no longer lives alongside the static site (it needs a single long-lived
	# process). Every build now targets the same dedicated relay host; CORS on the
	# relay allows the cross-origin request.
	return ONLINE_RELAY_DEFAULT_URL


func _normalize_online_lobby_code(raw_code: String) -> String:
	var normalized := ""
	var upper_code := raw_code.to_upper()
	for index in range(upper_code.length()):
		var character := upper_code.substr(index, 1)
		if "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(character):
			normalized += character
		if normalized.length() >= ONLINE_LOBBY_CODE_LENGTH:
			break
	return normalized


func _is_network_client() -> bool:
	return network_enabled and not network_is_host


func _queue_network_ui_refresh() -> void:
	if network_enabled:
		call_deferred("_refresh_ui")


func _can_control_active_player() -> bool:
	if not network_enabled:
		return true
	return game_state.active_player_index == local_player_index


func _can_interact_with_local_player() -> bool:
	# Must stay a pure read. This runs inside _refresh_ui (via _can_play_card
	# and friends), and _refresh_ui fires from active_player_changed while the
	# host is processing a client request. Restoring the local view here used
	# to snap the active player back to the host's seat mid-request, so guest
	# plays resolved out of the host's hand. Click handlers that want the view
	# restored call _restore_local_network_view() themselves first.
	if not network_enabled:
		return true
	if game_state.players.is_empty():
		return false
	return _can_control_active_player()


func _can_edit_table_settings() -> bool:
	return not network_enabled or network_is_host


func _can_edit_lobby_setup() -> bool:
	return _can_edit_table_settings() and not has_active_game


func _player_index_for_peer(peer_id: int) -> int:
	if peer_id == 1:
		return 0
	return int(network_peer_to_player.get(peer_id, -1))


func _player_index_for_relay_client(client_id: String) -> int:
	if client_id.is_empty():
		return -1
	return int(network_peer_to_player.get(client_id, -1))


func _set_network_view_player(player_index: int) -> void:
	if game_state.players.is_empty():
		return
	var target_index := clampi(player_index, 0, game_state.players.size() - 1)
	if (
		game_state.active_player_index == target_index
		and game_state.player == game_state.players[target_index]
	):
		_sync_turn_manager_to_local_player()
		return
	game_state.set_active_player_index(target_index)
	_sync_turn_manager_to_local_player()


func _set_authoritative_player(player_index: int) -> void:
	if game_state.players.is_empty():
		return
	game_state.set_active_player_index(clampi(player_index, 0, game_state.players.size() - 1))


func _restore_local_network_view() -> void:
	if not network_enabled:
		return
	_set_network_view_player(local_player_index)


func _sync_turn_manager_to_local_player() -> void:
	if not network_enabled or game_state.players.is_empty():
		return
	var local_player := game_state.players[clampi(local_player_index, 0, game_state.players.size() - 1)]
	turn_manager.turn_number = local_player.turn_number
	turn_manager.ending_turn = local_player.ending_turn
	turn_manager.cooldown_remaining = local_player.cooldown_remaining
	turn_manager.cooldown_duration = local_player.cooldown_duration


func _on_network_peer_connected(peer_id: int) -> void:
	if not network_is_host:
		return
	var player_index := _next_open_network_player_index()
	if player_index == -1:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	network_peer_to_player[peer_id] = player_index
	rpc_id(peer_id, "_rpc_set_local_player_index", player_index)
	_set_lobby_status("%s connected." % game_state.players[player_index].player_name)
	_broadcast_network_snapshot()
	_refresh_lobby_panel()


func _on_network_peer_disconnected(peer_id: int) -> void:
	if network_is_host:
		var seat := int(network_peer_to_player.get(peer_id, -1))
		network_peer_to_player.erase(peer_id)
		if seat >= 0:
			network_ready_seats.erase(seat)
		_set_lobby_status("Player disconnected. Hosting remains open.")
		_broadcast_network_snapshot()
		_refresh_lobby_panel()


func _on_network_connected_to_server() -> void:
	network_enabled = true
	network_is_host = false
	_set_lobby_status("Connected. Waiting for lobby state...")


func _next_open_network_player_index() -> int:
	# Seats are bounded by the players actually created for this table, so a
	# surplus joiner can never be assigned an index past the player list.
	var seat_count := mini(game_state.players.size(), NETWORK_MAX_PLAYERS)
	for player_index in range(1, seat_count):
		if not network_peer_to_player.values().has(player_index):
			return player_index
	return -1


@rpc("authority", "call_remote", "reliable")
func _rpc_set_local_player_index(player_index: int) -> void:
	# The host's seat assignment is authoritative. Never clamp it against the
	# local players array: a joiner can still hold a stale solo game (one
	# player), which would squash any assigned seat down to seat 0 and leave
	# the client viewing and playing the host's hand.
	local_player_index = clampi(player_index, 0, NETWORK_MAX_PLAYERS - 1)
	_set_lobby_status("Connected as Player %d." % (local_player_index + 1))
	if network_enabled and not game_state.players.is_empty():
		_restore_local_network_view()
		_sync_choice_overlay_from_network()
		_refresh_ui()
		_queue_network_ui_refresh()


func _on_network_connection_failed() -> void:
	_disconnect_network()
	_set_lobby_status("Connection failed.")
	_refresh_home_controls()


func _on_network_server_disconnected() -> void:
	_disconnect_network()
	has_active_game = false
	_show_home_screen(false)
	_set_lobby_status("Host disconnected.")
	_refresh_home_controls()


func _on_network_end_turn_cooldown_reduced(amount: float) -> void:
	if not network_enabled:
		return
	var game_player := game_state.player
	if game_player.cooldown_remaining <= 0.0:
		return
	game_player.cooldown_remaining = maxf(0.0, game_player.cooldown_remaining - maxf(0.0, amount))
	if game_player.cooldown_remaining <= 0.0:
		game_player.cooldown_duration = 0.0
	_sync_turn_manager_to_local_player()


func _start_network_player_cooldown(player_index: int) -> void:
	if turn_manager.game_over or game_state.players.is_empty():
		return
	_set_authoritative_player(player_index)
	var game_player := game_state.player
	if game_player.pending_choice != null or game_player.cooldown_remaining > 0.0:
		_restore_local_network_view()
		return
	game_player.cooldown_duration = game_state.get_end_turn_cooldown_seconds()
	game_player.cooldown_remaining = game_player.cooldown_duration
	game_player.ending_turn = true
	print(
		"[Game] End turn %d for %s in %.1f seconds"
		% [game_player.turn_number, game_player.player_name, game_player.cooldown_duration]
	)
	_finish_network_player_turn(player_index)
	_restore_local_network_view()


func _tick_network_cooldowns(delta: float) -> void:
	if turn_manager.game_over:
		return
	# Tick every player's End Turn button cooldown locally, but only broadcast a
	# snapshot when a cooldown actually expires. Clients run their own local
	# countdown for the button, so a per-frame snapshot would rebuild their whole
	# board 60 times a second and swallow card/market clicks mid-cooldown. The
	# cooldown must lock the End Turn button only, never the rest of the screen.
	var expired := false
	for player_index in range(game_state.players.size()):
		var game_player := game_state.players[player_index]
		if game_player.cooldown_remaining <= 0.0:
			continue
		game_player.cooldown_remaining = maxf(0.0, game_player.cooldown_remaining - delta)
		if game_player.cooldown_remaining > 0.0:
			continue
		game_player.ending_turn = false
		game_player.cooldown_duration = 0.0
		expired = true
	if expired:
		_restore_local_network_view()
		_broadcast_network_snapshot()


func _tick_online_relay_reconnect(delta: float) -> void:
	if online_relay_connect_timer > 0.0 and not online_relay_connected:
		# The HTTP relay can be unreachable or slow; make that visible instead of
		# leaving the lobby stuck forever with no code.
		online_relay_connect_timer -= delta
		if online_relay_connect_timer <= 0.0:
			_on_online_relay_closed()
			return
	if online_relay_reconnect_timer <= 0.0:
		return
	online_relay_reconnect_timer -= delta
	if online_relay_reconnect_timer > 0.0:
		return
	if network_enabled and not online_relay_connected:
		_connect_online_relay()


func _finish_network_player_turn(player_index: int) -> void:
	_set_authoritative_player(player_index)
	var game_player := game_state.player
	if not game_player.ending_turn:
		return
	pending_cleanup_ghosts = _capture_cleanup_cards() if player_index == local_player_index else []
	var previous_turn_manager_ending := turn_manager.ending_turn
	turn_manager.ending_turn = false
	game_state.begin_cleanup()
	turn_manager.ending_turn = previous_turn_manager_ending
	if game_player.pending_choice != null or game_player.cleanup_in_progress:
		return
	_complete_network_player_cleanup(player_index)


func _complete_network_player_cleanup(player_index: int) -> void:
	_set_authoritative_player(player_index)
	var game_player := game_state.player
	game_player.ending_turn = false
	game_state.reset_turn_resources()
	if game_state.is_game_end_condition_met():
		game_player.cooldown_remaining = 0.0
		game_player.cooldown_duration = 0.0
		turn_manager.game_over = true
		turn_manager.final_scores = game_state.calculate_all_scores()
		turn_manager.final_score = (
			turn_manager.final_scores[local_player_index]
			if local_player_index < turn_manager.final_scores.size()
			else 0
		)
		_restore_local_network_view()
		_show_final_score(turn_manager.final_score)
		return
	game_player.turn_number += 1
	game_state.draw_cards(game_state.get_turn_draw_count(game_player))
	game_state.maybe_offer_turn_relic(game_player)
	game_state.check_idle_relics()
	_restore_local_network_view()
	if player_index == local_player_index:
		_animate_cleanup_cards(pending_cleanup_ghosts)
		pending_cleanup_ghosts.clear()
		call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _broadcast_network_snapshot() -> void:
	if not network_enabled or not network_is_host:
		return
	var snapshot := _create_network_snapshot()
	if network_mode == NETWORK_MODE_ONLINE:
		_send_online_signal("all", {
			"method": "apply_network_snapshot",
			"snapshot": snapshot,
		})
	else:
		rpc("_rpc_apply_network_snapshot", snapshot)
	_refresh_ui()


func _create_network_snapshot() -> Dictionary:
	var player_snapshots: Array[Dictionary] = []
	for game_player in game_state.players:
		player_snapshots.append({
			"name": game_player.player_name,
			"turn_number": game_player.turn_number,
			"draw": _card_ids_from_zone(game_player.draw_pile),
			"hand": _card_ids_from_zone(game_player.hand),
			"play": _card_ids_from_zone(game_player.play_area),
			"play_display": _serialize_play_display_records(game_player),
			"discard": _card_ids_from_zone(game_player.discard_pile),
			"trash": _card_ids_from_zone(game_player.trash_pile),
			"set_aside": _card_ids_from_zone(game_player.set_aside_pile),
			"duration_hold": _card_ids_from_zone(game_player.duration_hold),
			"pending_durations": _serialize_pending_durations(game_player),
			"coins": game_player.coins,
			"actions": game_player.actions,
			"buys": game_player.buys,
			"cooldown_reduction": game_player.end_turn_cooldown_reduction,
			"game_cooldown_reduction": game_player.game_cooldown_reduction,
			"relics": game_player.relics.duplicate(),
			"relic_offer": game_player.pending_relic_offer.duplicate(),
			"turn_flags": _serialize_turn_flags(game_player.turn_flags),
			"pending_choice": _serialize_choice(game_player.pending_choice),
			"cleanup_in_progress": game_player.cleanup_in_progress,
			"ending_turn": game_player.ending_turn,
			"cooldown_remaining": game_player.cooldown_remaining,
			"cooldown_duration": game_player.cooldown_duration,
			"times_attacked": game_player.times_attacked,
		})
	return {
		"players": player_snapshots,
		"started": network_table_open,
		"connected_seats": _connected_seat_indexes(),
		"ready_seats": network_ready_seats.duplicate(),
		"respite_ready_seats": respite_ready_seats.duplicate(),
		"multiplayer_enabled": game_state.multiplayer_enabled,
		"turn_based_enabled": game_state.turn_based_enabled,
		"end_turn_cooldown_seconds": game_state.end_turn_cooldown_seconds,
		"attack_cards_enabled": game_state.attack_cards_enabled,
		"market": _card_ids_from_zone(game_state.market),
		"supply": game_state.supply_piles.duplicate(true),
		"turn": {
			"turn_number": turn_manager.turn_number,
			"game_over": turn_manager.game_over,
			"final_score": turn_manager.final_score,
			"final_scores": turn_manager.final_scores.duplicate(),
		},
	}


func _connected_seat_indexes() -> Array[int]:
	var seats: Array[int] = [0]
	for seat in network_peer_to_player.values():
		var seat_index := int(seat)
		if not seats.has(seat_index):
			seats.append(seat_index)
	seats.sort()
	return seats


func _string_array(values: Array) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(str(value))
	return strings


func _card_ids_from_zone(zone: Array[CardDefinition]) -> Array[String]:
	var card_ids: Array[String] = []
	for card in zone:
		if card != null:
			card_ids.append(card.id)
	return card_ids


func _serialize_play_display_records(game_player: PlayerState) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for record in game_player.get_play_display_records():
		var card := record.get("card") as CardDefinition
		if card == null:
			continue
		records.append({
			"card_id": card.id,
			"occurrence": int(record.get("occurrence", 1)),
			"total": int(record.get("total", 1)),
		})
	return records


func _play_display_records_from_snapshot(data: Array) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for record in data:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var card := game_state.card_catalog.get(str(record.get("card_id", ""))) as CardDefinition
		if card != null:
			records.append({"card": card, "occurrence": int(record.get("occurrence", 1)), "total": int(record.get("total", 1))})
	return records


func _serialize_pending_durations(game_player: PlayerState) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in game_player.pending_duration_effects:
		var card: CardDefinition = entry.get("card") as CardDefinition
		entries.append({
			"card_id": card.id if card != null else "",
			"effect": entry.get("effect", {}).duplicate(true),
		})
	return entries


func _pending_durations_from_snapshot(data: Array) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var card_id := str(entry.get("card_id", ""))
		if not game_state.card_catalog.has(card_id):
			continue
		entries.append({
			"card": game_state.card_catalog[card_id],
			"effect": entry.get("effect", {}).duplicate(true),
		})
	return entries


func _serialize_turn_flags(flags: Dictionary) -> Dictionary:
	var serialized: Dictionary = {}
	for key in flags:
		var value = flags[key]
		match typeof(value):
			TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
				serialized[key] = value
	return serialized


func _serialize_choice(choice: CardChoice) -> Dictionary:
	if choice == null:
		return {}
	var candidates: Array[Dictionary] = []
	for candidate in choice.candidates:
		var card: CardDefinition = candidate.get("card") as CardDefinition
		if card == null:
			continue
		candidates.append({
			"token": str(candidate.get("token", "")),
			"card_id": card.id,
			"subtitle": str(candidate.get("subtitle", "")),
		})
	return {
		"id": choice.id,
		"prompt": choice.prompt,
		"minimum": choice.minimum,
		"maximum": choice.maximum,
		"confirm_text": choice.confirm_text,
		"skip_text": choice.skip_text,
		"resolver": choice.resolver,
		"context": choice.context.duplicate(true),
		"candidates": candidates,
	}


@rpc("authority", "call_remote", "reliable")
func _rpc_apply_network_snapshot(snapshot: Dictionary) -> void:
	if network_is_host:
		return
	_apply_network_snapshot(snapshot)


func _apply_network_snapshot(snapshot: Dictionary) -> void:
	var previous_summary := _capture_local_zone_summary()
	game_state.players.clear()
	for player_data in snapshot.get("players", []):
		var synced_player := PlayerState.new()
		synced_player.player_name = str(player_data.get("name", "Player"))
		synced_player.turn_number = int(player_data.get("turn_number", 1))
		synced_player.draw_pile = _cards_from_ids(player_data.get("draw", []))
		synced_player.hand = _cards_from_ids(player_data.get("hand", []))
		synced_player.play_area = _cards_from_ids(player_data.get("play", []))
		synced_player.play_display_records = _play_display_records_from_snapshot(player_data.get("play_display", []))
		synced_player.discard_pile = _cards_from_ids(player_data.get("discard", []))
		synced_player.trash_pile = _cards_from_ids(player_data.get("trash", []))
		synced_player.set_aside_pile = _cards_from_ids(player_data.get("set_aside", []))
		synced_player.duration_hold = _cards_from_ids(player_data.get("duration_hold", []))
		synced_player.pending_duration_effects = _pending_durations_from_snapshot(
			player_data.get("pending_durations", [])
		)
		synced_player.coins = int(player_data.get("coins", 0))
		synced_player.actions = int(player_data.get("actions", 1))
		synced_player.buys = int(player_data.get("buys", 1))
		synced_player.end_turn_cooldown_reduction = float(
			player_data.get("cooldown_reduction", 0.0)
		)
		synced_player.game_cooldown_reduction = float(
			player_data.get("game_cooldown_reduction", 0.0)
		)
		synced_player.relics = _string_array(player_data.get("relics", []))
		synced_player.pending_relic_offer = _string_array(player_data.get("relic_offer", []))
		synced_player.times_attacked = int(player_data.get("times_attacked", 0))
		synced_player.turn_flags = player_data.get("turn_flags", {}).duplicate(true)
		synced_player.pending_choice = _choice_from_snapshot(player_data.get("pending_choice", {}))
		synced_player.cleanup_in_progress = bool(player_data.get("cleanup_in_progress", false))
		synced_player.ending_turn = bool(player_data.get("ending_turn", false))
		synced_player.cooldown_remaining = float(player_data.get("cooldown_remaining", 0.0))
		synced_player.cooldown_duration = float(player_data.get("cooldown_duration", 0.0))
		game_state.players.append(synced_player)
	if game_state.players.is_empty():
		return
	game_state.active_player_index = clampi(
		local_player_index,
		0,
		game_state.players.size() - 1
	)
	game_state.player = game_state.players[game_state.active_player_index]
	game_state.turn_flags = game_state.player.turn_flags
	game_state.cleanup_in_progress = game_state.player.cleanup_in_progress
	game_state.multiplayer_enabled = bool(snapshot.get("multiplayer_enabled", true))
	game_state.turn_based_enabled = bool(
		snapshot.get("turn_based_enabled", game_state.turn_based_enabled)
	)
	var table_was_open := network_table_open
	network_table_open = bool(snapshot.get("started", true))
	if network_table_open and not table_was_open and not network_is_host:
		# The host just opened the table; give this guest the reading respite too.
		_start_respite()
	network_connected_seats.clear()
	for seat in snapshot.get("connected_seats", []):
		network_connected_seats.append(int(seat))
	network_ready_seats.clear()
	for seat in snapshot.get("ready_seats", []):
		network_ready_seats.append(int(seat))
	respite_ready_seats.clear()
	for seat in snapshot.get("respite_ready_seats", []):
		respite_ready_seats.append(int(seat))
	if _respite_active() and _all_seats_respite_ready():
		_end_respite()
	game_state.end_turn_cooldown_seconds = float(
		snapshot.get("end_turn_cooldown_seconds", game_state.end_turn_cooldown_seconds)
	)
	game_state.attack_cards_enabled = bool(
		snapshot.get("attack_cards_enabled", game_state.attack_cards_enabled)
	)
	game_state.market = _cards_from_ids(snapshot.get("market", []))
	game_state.supply_piles = snapshot.get("supply", {}).duplicate(true)
	game_state.pending_choice = game_state.player.pending_choice
	game_state.player.pending_choice = game_state.pending_choice

	var turn_data: Dictionary = snapshot.get("turn", {})
	turn_manager.game_over = bool(turn_data.get("game_over", false))
	turn_manager.final_score = int(turn_data.get("final_score", 0))
	turn_manager.final_scores.clear()
	for score in turn_data.get("final_scores", []):
		turn_manager.final_scores.append(int(score))
	if local_player_index < turn_manager.final_scores.size():
		turn_manager.final_score = turn_manager.final_scores[local_player_index]
	_sync_turn_manager_to_local_player()

	# Joiners stay on the lobby screen until the host actually opens the table.
	has_active_game = network_table_open
	if network_table_open:
		_hide_home_screen()
	else:
		_refresh_home_controls()
	_sync_choice_overlay_from_network()
	_refresh_ui()
	_queue_network_ui_refresh()
	if network_table_open:
		_animate_snapshot_changes(previous_summary)
	if turn_manager.game_over and not end_game_overlay.visible:
		_show_final_score(turn_manager.final_score)


func _cards_from_ids(card_ids: Array) -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	for card_id in card_ids:
		var card: CardDefinition = game_state.card_catalog.get(str(card_id)) as CardDefinition
		if card != null:
			cards.append(card)
	return cards


func _choice_from_snapshot(choice_data: Dictionary) -> CardChoice:
	if choice_data.is_empty():
		return null
	var choice := CardChoice.new()
	choice.id = int(choice_data.get("id", 0))
	choice.prompt = str(choice_data.get("prompt", ""))
	choice.minimum = int(choice_data.get("minimum", 0))
	choice.maximum = int(choice_data.get("maximum", 0))
	choice.confirm_text = str(choice_data.get("confirm_text", "CONFIRM"))
	choice.skip_text = str(choice_data.get("skip_text", "SKIP"))
	choice.resolver = str(choice_data.get("resolver", ""))
	choice.context = choice_data.get("context", {}).duplicate(true)
	for candidate_data in choice_data.get("candidates", []):
		var card: CardDefinition = (
			game_state.card_catalog.get(str(candidate_data.get("card_id", "")))
			as CardDefinition
		)
		if card != null:
			choice.add_candidate(
				str(candidate_data.get("token", "")),
				card,
				str(candidate_data.get("subtitle", ""))
			)
	return choice


func _sync_choice_overlay_from_network() -> void:
	if game_state.pending_choice != null and _can_control_active_player():
		if current_choice == null or current_choice.id != game_state.pending_choice.id:
			_on_choice_requested(game_state.pending_choice)
	else:
		_hide_choice_overlay()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_play_card(card_id: String) -> void:
	_handle_network_play_card_request(
		_player_index_for_peer(multiplayer.get_remote_sender_id()),
		card_id
	)


func _handle_network_play_card_request(player_index: int, card_id: String) -> void:
	if not network_is_host or player_index < 0:
		return
	_set_authoritative_player(player_index)
	var card := _find_card_in_active_hand(card_id)
	if card != null and game_state.play_card(card):
		if game_state.consume_end_turn_request():
			_start_network_player_cooldown(player_index)
		_restore_local_network_view()
		_sync_choice_overlay_from_network()
		_broadcast_network_snapshot()
	else:
		_restore_local_network_view()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_buy_card(card_id: String) -> void:
	_handle_network_buy_card_request(
		_player_index_for_peer(multiplayer.get_remote_sender_id()),
		card_id
	)


func _handle_network_buy_card_request(player_index: int, card_id: String) -> void:
	if not network_is_host or player_index < 0:
		return
	_set_authoritative_player(player_index)
	var card: CardDefinition = game_state.card_catalog.get(card_id) as CardDefinition
	if card != null and game_state.buy_card(card):
		_restore_local_network_view()
		_sync_choice_overlay_from_network()
		_broadcast_network_snapshot()
	else:
		_restore_local_network_view()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_end_turn() -> void:
	_handle_network_end_turn_request(_player_index_for_peer(multiplayer.get_remote_sender_id()))


func _handle_network_end_turn_request(player_index: int) -> void:
	if not network_is_host or player_index < 0:
		return
	_start_network_player_cooldown(player_index)
	_sync_choice_overlay_from_network()
	_broadcast_network_snapshot()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_relic_choice(relic_id: String) -> void:
	_handle_network_relic_choice_request(
		_player_index_for_peer(multiplayer.get_remote_sender_id()),
		relic_id
	)


func _handle_network_relic_choice_request(player_index: int, relic_id: String) -> void:
	if not network_is_host or player_index < 0 or player_index >= game_state.players.size():
		return
	if game_state.choose_relic(game_state.players[player_index], relic_id):
		_refresh_ui()
		_broadcast_network_snapshot()


func _handle_network_lobby_ready(player_index: int) -> void:
	if not network_is_host or player_index <= 0:
		return
	if not network_ready_seats.has(player_index):
		network_ready_seats.append(player_index)
		network_ready_seats.sort()
		_play_ui_sound("button_click")
		_set_lobby_status("Player %d is ready to play." % (player_index + 1))
	_refresh_lobby_panel()
	_broadcast_network_snapshot()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_respite_ready() -> void:
	_handle_network_respite_ready(_player_index_for_peer(multiplayer.get_remote_sender_id()))


func _handle_network_respite_ready(player_index: int) -> void:
	if not network_is_host or player_index < 0:
		return
	_mark_respite_ready(player_index)
	_refresh_ui()
	_broadcast_network_snapshot()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_set_name(new_name: String) -> void:
	_handle_network_set_name(_player_index_for_peer(multiplayer.get_remote_sender_id()), new_name)


func _handle_network_set_name(player_index: int, new_name: String) -> void:
	if not network_is_host or player_index < 0 or player_index >= game_state.players.size():
		return
	var trimmed := new_name.strip_edges()
	game_state.players[player_index].player_name = (
		trimmed if not trimmed.is_empty() else "Player %d" % (player_index + 1)
	)
	_refresh_lobby_panel()
	_refresh_ui()
	_broadcast_network_snapshot()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_choice(raw_tokens: Array) -> void:
	_handle_network_choice_request(
		_player_index_for_peer(multiplayer.get_remote_sender_id()),
		raw_tokens
	)


func _handle_network_choice_request(player_index: int, raw_tokens: Array) -> void:
	if not network_is_host or player_index < 0:
		return
	_set_authoritative_player(player_index)
	var tokens: Array[String] = []
	for token in raw_tokens:
		tokens.append(str(token))
	var previous_turn_manager_ending := turn_manager.ending_turn
	if game_state.player.ending_turn:
		turn_manager.ending_turn = false
	if game_state.resolve_choice(tokens):
		turn_manager.ending_turn = previous_turn_manager_ending
		if (
			game_state.player.ending_turn
			and game_state.player.pending_choice == null
			and not game_state.player.cleanup_in_progress
		):
			_complete_network_player_cleanup(player_index)
		_restore_local_network_view()
		_sync_choice_overlay_from_network()
		_broadcast_network_snapshot()
	else:
		turn_manager.ending_turn = previous_turn_manager_ending
		_restore_local_network_view()


func _find_card_in_active_hand(card_id: String) -> CardDefinition:
	for card in game_state.player.hand:
		if card.id == card_id:
			return card
	return null


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

	if ResourceLoader.exists(BACKGROUND_MUSIC_PATH):
		# Keep music loading off the main thread so entering or restarting a game
		# never waits on the audio stream.
		background_music_player = AudioStreamPlayer.new()
		background_music_player.name = "BackgroundMusic"
		background_music_player.volume_db = _get_background_music_volume_db()
		add_child(background_music_player)
		_request_background_music_playback()
		if ResourceLoader.load_threaded_request(BACKGROUND_MUSIC_PATH) == OK:
			background_music_loading = true
		else:
			push_warning("Background music load request failed for %s." % BACKGROUND_MUSIC_PATH)


func _build_bottom_docks() -> void:
	var brand := hud_row.get_node("Brand") as VBoxContainer
	var turn_stat := turn_label.get_parent() as VBoxContainer
	var deck_stat := deck_label.get_parent().get_parent() as VBoxContainer
	var discard_stat := discard_label.get_parent().get_parent() as VBoxContainer
	var coin_stat := coin_label.get_parent().get_parent() as VBoxContainer
	var action_stat := action_label.get_parent().get_parent() as VBoxContainer
	var buy_stat := buy_label.get_parent().get_parent() as VBoxContainer
	var hand_header := hand_count_label.get_parent() as HBoxContainer
	var root_margin := get_node("Margin") as MarginContainer
	var main_layout := hud_panel.get_parent() as VBoxContainer

	root_margin.add_theme_constant_override("margin_left", 8)
	root_margin.add_theme_constant_override("margin_top", 3)
	root_margin.add_theme_constant_override("margin_right", 8)
	root_margin.add_theme_constant_override("margin_bottom", 3)
	main_layout.add_theme_constant_override("separation", 4)

	var left_parts := _create_hud_ledger("LeftDock")
	left_ledger = left_parts.panel
	var left_stats: VBoxContainer = left_parts.stats
	var right_parts := _create_hud_ledger("RightDock")
	right_ledger = right_parts.panel
	right_ledger.custom_minimum_size = Vector2(RIGHT_DOCK_WIDTH, 0)
	var right_stats: VBoxContainer = right_parts.stats
	hand_column = VBoxContainer.new()
	hand_column.name = "HandColumn"
	hand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_column.add_theme_constant_override("separation", 4)

	hud_panel.custom_minimum_size = Vector2(0, BOTTOM_BAND_HEIGHT)
	hud_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	hud_row.add_theme_constant_override("separation", 8)
	hud_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_row.add_child(left_ledger)
	hud_row.add_child(hand_column)
	hud_row.add_child(right_ledger)

	for stat in [turn_stat, deck_stat, discard_stat, coin_stat, action_stat, buy_stat]:
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_button.custom_minimum_size = Vector2(34, 34)
	end_turn_button.custom_minimum_size = Vector2(END_TURN_BUTTON_WIDTH, 48)
	end_turn_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Keep the button a constant width: without this the button grows to fit
	# longer labels (the countdown timer, "COOLDOWN 5.0s"), stretching the dock.
	end_turn_button.clip_text = true

	# Left dock: compact Coins / Actions / Buys ledger, rows split by hairlines.
	left_stats.add_theme_constant_override("separation", 4)
	coin_stat.reparent(left_stats)
	left_stats.add_child(_create_ledger_hairline())
	action_stat.reparent(left_stats)
	left_stats.add_child(_create_ledger_hairline())
	buy_stat.reparent(left_stats)
	_configure_stat_row(coin_stat, COLOR_RESOURCE_ACCENT)
	_configure_stat_row(action_stat, COLOR_ACTION_ACCENT)
	_configure_stat_row(buy_stat, COLOR_BRASS)

	# Center band: in-play strip above physical draw pile, hand, and discard pile.
	hand_header.reparent(hand_column)
	hand_header.visible = false
	play_area_panel.reparent(hand_column)
	var pile_hand_row := HBoxContainer.new()
	pile_hand_row.name = "PileHandRow"
	pile_hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_hand_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pile_hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pile_hand_row.add_theme_constant_override("separation", 10)
	hand_column.add_child(pile_hand_row)

	deck_stat.reparent(pile_hand_row)
	hand_panel.reparent(pile_hand_row)
	discard_stat.reparent(pile_hand_row)
	_configure_physical_pile(deck_stat, deck_label, false)
	_configure_physical_pile(discard_stat, discard_label, true)
	trash_pile_button = Button.new()
	trash_pile_button.name = "TrashPileButton"
	trash_pile_button.custom_minimum_size = Vector2(72, 42)
	trash_pile_button.tooltip_text = "View trashed cards"
	trash_pile_button.pressed.connect(_show_trash_pile)
	trash_pile_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	trash_pile_button.add_theme_stylebox_override("normal", _make_panel_style(COLOR_WALNUT, COLOR_OXBLOOD.darkened(0.15), 1))
	trash_pile_button.add_theme_stylebox_override("hover", _make_panel_style(COLOR_WALNUT.lightened(0.08), COLOR_OXBLOOD.lightened(0.14), 1))
	if title_font != null:
		trash_pile_button.add_theme_font_override("font", title_font)
	pile_hand_row.add_child(trash_pile_button)

	hand_panel.custom_minimum_size = Vector2(0, 188)
	hand_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_container.add_theme_constant_override("separation", -22)
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_container.sort_children.connect(_apply_hand_fan_offsets)

	# Right dock: player/turn tracker with End Turn beneath it.
	turn_stat.reparent(right_stats)
	turn_stat.visible = false
	player_status_label = Label.new()
	player_status_label.name = "PlayerStatus"
	player_status_label.visible = false
	right_stats.add_child(player_status_label)
	right_stats.add_child(_create_players_turn_panel())
	end_turn_button.reparent(right_stats)
	brand.queue_free()

	for obsolete_name in ["Divider", "ZoneDivider", "Spacer"]:
		var obsolete := hud_row.get_node_or_null(obsolete_name)
		if obsolete != null:
			obsolete.free()

	hud_row.move_child(left_ledger, 0)
	hud_row.move_child(hand_column, 1)
	hud_row.move_child(right_ledger, 2)
	main_layout.move_child(hud_panel, main_layout.get_child_count() - 1)
	_lock_play_area_height()


func _lock_play_area_height() -> void:
	play_area_panel.custom_minimum_size = Vector2(0, PLAY_AREA_PANEL_HEIGHT)
	play_area_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play_area_label.custom_minimum_size = Vector2(74, 0)
	play_area_label.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		play_area_label.add_theme_font_override("font", title_font)
	play_area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_area_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	play_area_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	var play_area_scroll := play_area_container.get_parent() as ScrollContainer
	if play_area_scroll != null:
		play_area_scroll.custom_minimum_size = Vector2(0, PLAY_AREA_CONTENT_HEIGHT)
		play_area_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	play_area_container.custom_minimum_size = Vector2(0, PLAY_AREA_CONTENT_HEIGHT)


func _create_hud_ledger(ledger_name: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = ledger_name
	panel.custom_minimum_size = Vector2(HUD_LEDGER_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var stats := VBoxContainer.new()
	stats.name = "Stats"
	stats.add_theme_constant_override("separation", 5)
	margin.add_child(stats)
	return {"panel": panel, "stats": stats}


func _create_ledger_hairline() -> ColorRect:
	var rule := ColorRect.new()
	rule.name = "LedgerHairline"
	rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.color = Color(0.835, 0.667, 0.314, 0.16)
	return rule


func _configure_stat_row(stat: VBoxContainer, accent: Color) -> void:
	# Lay each ledger row out as a single line: [icon] LABEL .......... VALUE.
	# The icon sits in a fixed-width left column so all three icons share one
	# vertical line, and values right-align into a column of their own.
	stat.custom_minimum_size = Vector2(0, 44)
	stat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stat.add_theme_constant_override("separation", 0)
	var title := stat.find_child("Title", true, false) as Label
	var value := stat.find_child("Value", true, false) as Label
	var value_row := value.get_parent() as HBoxContainer if value != null else null
	var icon := stat.find_child("Icon", true, false) as TextureRect
	if value_row == null:
		return
	value_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	value_row.add_theme_constant_override("separation", 10)
	value_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if icon != null:
		icon.custom_minimum_size = Vector2(26, 26)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = accent
	if title != null:
		title.reparent(value_row)
		value_row.move_child(title, 1)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.size_flags_vertical = Control.SIZE_EXPAND_FILL
		title.add_theme_color_override("font_color", COLOR_BRASS)
		title.add_theme_font_size_override("font_size", 13)
		if title_font != null:
			title.add_theme_font_override("font", title_font)
	if value != null:
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.custom_minimum_size = Vector2(46, 0)
		value.size_flags_horizontal = Control.SIZE_SHRINK_END
		value.size_flags_vertical = Control.SIZE_EXPAND_FILL
		value.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
		value.add_theme_font_size_override("font_size", 30)
		if title_font != null:
			value.add_theme_font_override("font", title_font)


func _configure_physical_pile(
	stat: VBoxContainer,
	value_label: Label,
	is_discard: bool
) -> void:
	stat.custom_minimum_size = Vector2(PILE_FACE_SIZE.x + 16, 0)
	stat.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stat.size_flags_vertical = Control.SIZE_SHRINK_END
	stat.add_theme_constant_override("separation", 4)

	var title := stat.find_child("Title", true, false) as Label
	var value_row := value_label.get_parent() as HBoxContainer
	var icon := value_row.find_child("Icon", true, false) as TextureRect
	if icon != null:
		icon.hide()
	value_row.alignment = BoxContainer.ALIGNMENT_CENTER
	value_row.add_theme_constant_override("separation", 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_color_override("font_color", Color("#3a2410"))
	value_label.add_theme_font_size_override("font_size", 18)
	if title_font != null:
		value_label.add_theme_font_override("font", title_font)

	var stack := Control.new()
	stack.name = "DiscardPileStack" if is_discard else "DrawPileStack"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.custom_minimum_size = Vector2(PILE_FACE_SIZE.x + 12, PILE_FACE_SIZE.y + 10)
	stat.add_child(stack)
	stat.move_child(stack, 0)

	for layer_index in range(2):
		var layer := PanelContainer.new()
		layer.name = "Layer%d" % (layer_index + 1)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.position = Vector2(5 - layer_index * 3, 6 - layer_index * 3)
		layer.size = PILE_FACE_SIZE
		layer.rotation_degrees = -2.0 + float(layer_index)
		layer.add_theme_stylebox_override(
			"panel",
			_make_card_back_style(Color(0.1, 0.065, 0.035, 0.88))
		)
		stack.add_child(layer)

	var face := PanelContainer.new()
	face.name = "DiscardFace" if is_discard else "DrawFace"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.position = Vector2(2, 2)
	face.size = PILE_FACE_SIZE
	face.add_theme_stylebox_override(
		"panel",
		_make_discard_pile_style() if is_discard else _make_card_back_style(Color("#20140a"))
	)
	stack.add_child(face)

	if is_discard:
		discard_pile_art = TextureRect.new()
		discard_pile_art.name = "TopCardArt"
		discard_pile_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		discard_pile_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		discard_pile_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.add_child(discard_pile_art)
		discard_pile_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		discard_pile_scrim = ColorRect.new()
		discard_pile_scrim.name = "DiscardScrim"
		discard_pile_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		discard_pile_scrim.color = Color(0, 0, 0, 0.5)
		face.add_child(discard_pile_scrim)
		discard_pile_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var emblem := _create_logo_emblem(40)
		emblem.name = "Sunburst"
		face.add_child(emblem)
		emblem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var count_badge := PanelContainer.new()
	count_badge.name = "PileCountBadge"
	count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_badge.position = Vector2((PILE_FACE_SIZE.x - 46.0) * 0.5 + 2, 0)
	count_badge.size = Vector2(46, 24)
	count_badge.add_theme_stylebox_override(
		"panel",
		_make_count_badge_style()
	)
	stack.add_child(count_badge)
	value_row.reparent(count_badge)

	if title != null:
		title.text = "DISCARD" if is_discard else "DRAW PILE"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_color_override("font_color", COLOR_BRASS)
		title.add_theme_font_size_override("font_size", 10)
		if title_font != null:
			title.add_theme_font_override("font", title_font)
		stat.move_child(title, stat.get_child_count() - 1)


func _create_players_turn_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "PlayersTurnPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color("#1d140c"), Color(0.835, 0.667, 0.314, 0.32), 1)
	)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var header := Label.new()
	header.name = "Header"
	header.text = "TABLE"
	header.add_theme_color_override("font_color", COLOR_BRASS)
	header.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		header.add_theme_font_override("font", title_font)
	layout.add_child(header)

	player_status_list = VBoxContainer.new()
	player_status_list.name = "PlayerRows"
	player_status_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_status_list.add_theme_constant_override("separation", 4)
	layout.add_child(player_status_list)
	return panel


func _build_top_bar() -> void:
	var main_layout := hud_panel.get_parent() as VBoxContainer
	top_bar = PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.custom_minimum_size = Vector2(0, TOP_BAR_HEIGHT)
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_bar.add_theme_stylebox_override("panel", _make_top_bar_style())

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 6)
	top_bar.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var brand_row := HBoxContainer.new()
	brand_row.name = "BrandRow"
	brand_row.custom_minimum_size = Vector2(250, 0)
	brand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_row.add_theme_constant_override("separation", 10)
	row.add_child(brand_row)

	var star := _create_logo_emblem(26)
	star.name = "Star"
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand_row.add_child(star)

	var title := Label.new()
	title.name = "Title"
	title.text = "CONQUEST CARTES"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	title.add_theme_font_size_override("font_size", 18)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	brand_row.add_child(title)

	row.add_child(_create_relics_rail())

	var right_row := HBoxContainer.new()
	right_row.name = "RightActions"
	right_row.custom_minimum_size = Vector2(44, 0)
	right_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_row.alignment = BoxContainer.ALIGNMENT_END
	right_row.add_theme_constant_override("separation", 8)
	row.add_child(right_row)

	home_button.reparent(right_row)
	home_button.name = "SettingsGearButton"
	home_button.text = "⚙"
	home_button.tooltip_text = "Settings"
	home_button.custom_minimum_size = Vector2(38, 38)
	home_button.add_theme_font_size_override("font_size", 20)
	home_button.add_theme_color_override("font_color", COLOR_BRASS)
	home_button.add_theme_stylebox_override("normal", _make_top_button_style(true))
	home_button.add_theme_stylebox_override("hover", _make_top_button_style(true, true))
	home_button.add_theme_stylebox_override("pressed", _make_top_button_style(true))

	main_layout.add_child(top_bar)
	main_layout.move_child(top_bar, 0)


func _create_relics_rail() -> PanelContainer:
	var rail := PanelContainer.new()
	rail.name = "RelicsRail"
	rail.custom_minimum_size = Vector2(306, 42)
	rail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rail.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color(0.047, 0.031, 0.02, 0.55), Color(0.835, 0.667, 0.314, 0.24), 13)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 3)
	rail.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var label := Label.new()
	label.text = "RELICS"
	label.add_theme_color_override("font_color", COLOR_BRASS)
	label.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		label.add_theme_font_override("font", title_font)
	row.add_child(label)

	relics_rail_row = HBoxContainer.new()
	relics_rail_row.name = "Slots"
	relics_rail_row.add_theme_constant_override("separation", 10)
	row.add_child(relics_rail_row)
	# Relic slots start empty; claimed relics fill them via _refresh_relics_rail.
	for index in range(RelicCatalog.RELIC_CAP):
		relics_rail_row.add_child(_create_relic_slot("", index))
	return rail


func _refresh_relics_rail() -> void:
	if relics_rail_row == null:
		return
	var relics: Array[String] = []
	if has_active_game and not game_state.players.is_empty():
		relics = _local_view_player().relics
	var signature := ",".join(relics)
	if str(relics_rail_row.get_meta("relic_signature", "")) == signature:
		return
	relics_rail_row.set_meta("relic_signature", signature)
	_clear_container(relics_rail_row)
	for index in range(RelicCatalog.RELIC_CAP):
		var relic_id := relics[index] if index < relics.size() else ""
		relics_rail_row.add_child(_create_relic_slot(relic_id, index))


func _create_relic_slot(relic_id: String, index: int) -> PanelContainer:
	var filled := not relic_id.is_empty()
	var slot := PanelContainer.new()
	slot.name = "RelicSlot%d" % (index + 1)
	slot.custom_minimum_size = Vector2(36, 36)
	slot.add_theme_stylebox_override(
		"panel",
		_make_relic_slot_style(filled)
	)
	if filled:
		slot.tooltip_text = "%s\n%s" % [
			RelicCatalog.get_relic_name(relic_id),
			RelicCatalog.get_relic_description(relic_id),
		]
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_relic_slot_gui_input.bind(relic_id, slot))
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.add_child(_create_relic_icon_or_glyph(relic_id, RELIC_RAIL_ICON_SIZE, filled, 18))
	return slot


func _build_relic_overlay() -> void:
	relic_overlay = Control.new()
	relic_overlay.name = "RelicOverlay"
	relic_overlay.visible = false
	relic_overlay.z_index = 150
	relic_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	relic_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(relic_overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.012, 0.006, 0.74)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	relic_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	relic_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "RelicPanel"
	panel.add_theme_stylebox_override("panel", _make_parchment_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.name = "Title"
	title.text = "CLAIM A RELIC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_PARCHMENT_INK)
	title.add_theme_font_size_override("font_size", 26)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "A boon that lasts the rest of the conquest."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	subtitle.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		subtitle.add_theme_font_override("font", body_font)
	layout.add_child(subtitle)

	relic_options_row = HBoxContainer.new()
	relic_options_row.name = "RelicOptions"
	relic_options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_options_row.add_theme_constant_override("separation", 14)
	layout.add_child(relic_options_row)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(footer)
	var skip_button := _create_parchment_button("RelicSkipButton", "PASS", false)
	skip_button.pressed.connect(_on_relic_option_pressed.bind(""))
	footer.add_child(skip_button)


func _start_respite() -> void:
	# The opening 60-second turn timer: play stays locked so everyone can read
	# the board first. It shows as a countdown on the End Turn button and ends on
	# its own; no modal, no skip. Client-local and changes no game state.
	# Solo games skip it entirely: there's no one to wait on, so play starts now.
	respite_ready_seats.clear()
	if not game_state.multiplayer_enabled:
		respite_remaining = 0.0
		return
	respite_remaining = RESPITE_SECONDS
	_refresh_end_turn_button()


func _local_respite_seat() -> int:
	return local_player_index if network_enabled else game_state.active_player_index


func _is_respite_ready(seat: int) -> bool:
	return respite_ready_seats.has(seat)


func _all_seats_respite_ready() -> bool:
	var seats := _connected_seat_indexes() if network_enabled else [0]
	if seats.is_empty():
		return false
	for seat in seats:
		if not respite_ready_seats.has(seat):
			return false
	return true


func _mark_respite_ready(seat: int) -> void:
	if seat < 0 or respite_ready_seats.has(seat):
		return
	respite_ready_seats.append(seat)
	if _all_seats_respite_ready():
		_end_respite()


func _on_respite_ready_pressed() -> void:
	if not _respite_active():
		return
	_play_ui_sound("button_click")
	if not network_enabled:
		# Local pass-and-play shares one screen, so a single ready starts the game.
		_end_respite()
		return
	_mark_respite_ready(local_player_index)
	if network_is_host:
		_broadcast_network_snapshot()
	else:
		_send_network_client_request("request_respite_ready")
	_refresh_ui()


func _end_respite() -> void:
	respite_remaining = 0.0
	_refresh_ui()


func _respite_active() -> bool:
	return respite_remaining > 0.0 and has_active_game and not turn_manager.game_over


func _tick_respite(delta: float) -> void:
	if not has_active_game or turn_manager.game_over:
		_end_respite()
		return
	respite_remaining = maxf(0.0, respite_remaining - delta)
	if respite_remaining <= 0.0:
		_end_respite()


func _format_respite_clock() -> String:
	var seconds := int(ceilf(respite_remaining))
	return "%d:%02d" % [seconds / 60, seconds % 60]


func _build_relic_preview() -> void:
	relic_preview = PanelContainer.new()
	relic_preview.name = "RelicPreview"
	relic_preview.visible = false
	relic_preview.z_index = 180
	relic_preview.custom_minimum_size = Vector2(252, 286)
	relic_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_preview.add_theme_stylebox_override(
		"panel",
		_make_preview_style(Color(0.13, 0.095, 0.055, 1.0), COLOR_BRASS)
	)
	add_child(relic_preview)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	relic_preview.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	relic_preview_icon_host = CenterContainer.new()
	relic_preview_icon_host.name = "IconHost"
	relic_preview_icon_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_preview_icon_host.custom_minimum_size = Vector2(0, 116)
	layout.add_child(relic_preview_icon_host)

	relic_preview_name_label = Label.new()
	relic_preview_name_label.name = "NameLabel"
	relic_preview_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_preview_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_preview_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_preview_name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	relic_preview_name_label.add_theme_font_size_override("font_size", 20)
	if title_font != null:
		relic_preview_name_label.add_theme_font_override("font", title_font)
	layout.add_child(relic_preview_name_label)

	relic_preview_meta_label = Label.new()
	relic_preview_meta_label.name = "MetaLabel"
	relic_preview_meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_preview_meta_label.text = "RELIC"
	relic_preview_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_preview_meta_label.add_theme_color_override("font_color", COLOR_BRASS)
	relic_preview_meta_label.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		relic_preview_meta_label.add_theme_font_override("font", title_font)
	layout.add_child(relic_preview_meta_label)

	relic_preview_description_label = Label.new()
	relic_preview_description_label.name = "DescriptionLabel"
	relic_preview_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_preview_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_preview_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	relic_preview_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_preview_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	relic_preview_description_label.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	relic_preview_description_label.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		relic_preview_description_label.add_theme_font_override("font", body_font)
	layout.add_child(relic_preview_description_label)


func _create_relic_option_button(relic_id: String) -> Button:
	var button := Button.new()
	button.name = "Relic_%s" % relic_id
	button.custom_minimum_size = Vector2(196, 230)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var surface := Color(0.13, 0.095, 0.055, 1.0)
	button.add_theme_stylebox_override(
		"normal",
		_make_card_style(surface, Color(0.835, 0.667, 0.314, 0.4), 1)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_card_style(surface.lightened(0.06), COLOR_BRASS, 2)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_card_style(surface.darkened(0.08), COLOR_BRASS, 2)
	)
	button.pressed.connect(_on_relic_option_pressed.bind(relic_id))
	button.gui_input.connect(_on_relic_slot_gui_input.bind(relic_id, button))
	button.mouse_entered.connect(_on_hud_button_hovered.bind(button))
	button.mouse_exited.connect(_on_hud_button_unhovered.bind(button))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	button.add_child(margin)

	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	stack.add_child(_create_relic_icon_or_glyph(relic_id, RELIC_DRAFT_ICON_SIZE, true, 34))

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = RelicCatalog.get_relic_name(relic_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	name_label.add_theme_font_size_override("font_size", 15)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	stack.add_child(name_label)

	var description := Label.new()
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.text = RelicCatalog.get_relic_description(relic_id)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	description.add_theme_font_size_override("font_size", 11)
	if body_font != null:
		description.add_theme_font_override("font", body_font)
	stack.add_child(description)
	return button


func _create_relic_icon_or_glyph(
	relic_id: String,
	size: Vector2,
	filled: bool,
	fallback_font_size: int
) -> Control:
	var holder := CenterContainer.new()
	holder.name = "RelicIconHost"
	holder.custom_minimum_size = size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture := _load_relic_icon_texture(relic_id) if filled else null
	if texture != null:
		var icon := TextureRect.new()
		icon.name = "RelicIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = texture
		icon.custom_minimum_size = size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		holder.add_child(icon)
		return holder

	var glyph := Label.new()
	glyph.name = "RelicGlyph"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.text = RelicCatalog.get_relic_glyph(relic_id) if filled else "+"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_color_override(
		"font_color",
		Color("#3a2410") if filled else Color(0.835, 0.667, 0.314, 0.5)
	)
	glyph.add_theme_font_size_override("font_size", fallback_font_size)
	if title_font != null:
		glyph.add_theme_font_override("font", title_font)
	holder.add_child(glyph)
	return holder


func _local_view_player() -> PlayerState:
	if network_enabled and not game_state.players.is_empty():
		return game_state.players[clampi(local_player_index, 0, game_state.players.size() - 1)]
	return game_state.player


func _local_relic_offer() -> Array[String]:
	var empty_offer: Array[String] = []
	if not has_active_game or game_state.players.is_empty() or turn_manager.game_over:
		return empty_offer
	if home_overlay != null and home_overlay.visible:
		return empty_offer
	return _local_view_player().pending_relic_offer


func _refresh_relic_overlay() -> void:
	if relic_overlay == null:
		return
	var offer := _local_relic_offer()
	if offer.is_empty():
		if relic_overlay.visible:
			relic_overlay.hide()
		relic_overlay_offer.clear()
		return
	if relic_overlay.visible and offer == relic_overlay_offer:
		return
	relic_overlay_offer = offer.duplicate()
	_clear_container(relic_options_row)
	for relic_id in offer:
		relic_options_row.add_child(_create_relic_option_button(relic_id))
	relic_overlay.show()
	last_animation_event = "relic_offer"
	_play_ui_sound("draw")


func _on_relic_option_pressed(relic_id: String) -> void:
	_play_ui_sound("button_click" if relic_id.is_empty() else "buy_card")
	if _is_network_client():
		_send_network_client_request("request_relic_choice", {"relic_id": relic_id})
		# Clear the offer optimistically; the next host snapshot is authoritative.
		_local_view_player().pending_relic_offer.clear()
		_refresh_ui()
		return
	if game_state.choose_relic(_local_view_player(), relic_id):
		_refresh_ui()
		if network_enabled and network_is_host:
			_broadcast_network_snapshot()


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

	# "The Sunspire" title screen: monument art bleeds in from the right while the
	# menu options sit on the left over a dark left-to-clear scrim (handoff 1a).
	var art := TextureRect.new()
	art.name = "HomeArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _load_optional_texture(HOME_ART_PATH)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	home_overlay.add_child(art)
	# Bias the cover crop towards the right two thirds so the monument frames the
	# right side and the menu column reads against the darker left.
	art.anchor_left = 0.18
	art.anchor_top = 0.0
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0

	var scrim := TextureRect.new()
	scrim.name = "HomeScrim"
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scrim_gradient := Gradient.new()
	scrim_gradient.offsets = PackedFloat32Array([0.0, 0.32, 0.55, 0.75, 1.0])
	scrim_gradient.colors = PackedColorArray([
		Color(0.039, 0.027, 0.02, 1.0),
		Color(0.039, 0.027, 0.02, 0.96),
		Color(0.047, 0.035, 0.027, 0.55),
		Color(0.047, 0.035, 0.027, 0.12),
		Color(0.047, 0.035, 0.027, 0.0)
	])
	var scrim_texture := GradientTexture2D.new()
	scrim_texture.gradient = scrim_gradient
	scrim_texture.fill_from = Vector2(0, 0)
	scrim_texture.fill_to = Vector2(1, 0)
	scrim_texture.width = 96
	scrim_texture.height = 4
	scrim.texture = scrim_texture
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	home_overlay.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vignette := TextureRect.new()
	vignette.name = "HomeVignette"
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.texture = _make_radial_gradient_texture(
		PackedFloat32Array([0.0, 0.45, 1.0]),
		PackedColorArray([
			Color(0, 0, 0, 0.0),
			Color(0, 0, 0, 0.0),
			Color(0, 0, 0, 0.42)
		]),
		Vector2(0.2, 0.5),
		Vector2(1.25, 1.1)
	)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	home_overlay.add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	home_noise_overlay = _create_noise_rect("HomeNoise", home_noise_amount)
	home_overlay.add_child(home_noise_overlay)
	home_noise_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var menu_margin := MarginContainer.new()
	menu_margin.name = "MenuMargin"
	menu_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_margin.add_theme_constant_override("margin_left", 72)
	menu_margin.add_theme_constant_override("margin_top", 28)
	menu_margin.add_theme_constant_override("margin_right", 40)
	menu_margin.add_theme_constant_override("margin_bottom", 28)
	home_overlay.add_child(menu_margin)
	menu_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_menu_root = menu_margin

	var menu_layout := VBoxContainer.new()
	menu_layout.name = "Menu"
	menu_layout.custom_minimum_size = Vector2(486, 0)
	menu_layout.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_layout.add_theme_constant_override("separation", 6)
	menu_margin.add_child(menu_layout)

	var title := Label.new()
	title.name = "Title"
	title.text = "CONQUEST\nCARTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title.add_theme_color_override("font_color", Color("#edca7a"))
	title.add_theme_color_override("font_shadow_color", Color(0.835, 0.667, 0.314, 0.22))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_constant_override("line_spacing", -6)
	title.add_theme_font_size_override("font_size", 66)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	menu_layout.add_child(title)

	var divider := _create_home_divider()
	divider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_layout.add_child(divider)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = (
		"A game of kingdoms, coin, and quiet conquest. Build your deck, "
		+ "raid the market, and out-scheme every rival at the table."
	)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(430, 0)
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	subtitle.add_theme_color_override("font_color", Color(0.905, 0.847, 0.714, 0.82))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	subtitle.add_theme_font_size_override("font_size", 16)
	if body_font != null:
		subtitle.add_theme_font_override("font", body_font)
	menu_layout.add_child(subtitle)

	var button_gap := Control.new()
	button_gap.custom_minimum_size = Vector2(0, 16)
	menu_layout.add_child(button_gap)

	var button_stack := VBoxContainer.new()
	button_stack.name = "Buttons"
	button_stack.custom_minimum_size = Vector2(404, 0)
	button_stack.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button_stack.add_theme_constant_override("separation", 11)
	menu_layout.add_child(button_stack)

	home_new_game_button = _create_home_primary_button("NEW GAME")
	home_new_game_button.name = "NewGameButton"
	home_new_game_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_new_game_button.pressed.connect(_on_home_new_game_pressed)
	button_stack.add_child(home_new_game_button)

	home_continue_button = _create_home_ghost_button("CONTINUE")
	home_continue_button.name = "ContinueButton"
	home_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_continue_button.pressed.connect(_on_home_continue_pressed)
	button_stack.add_child(home_continue_button)

	# Resign leaves the current game (and closes/leaves any lobby). Only shown
	# while a game is in progress; see _refresh_home_controls.
	home_resign_button = _create_home_ghost_button("RESIGN")
	home_resign_button.name = "ResignButton"
	home_resign_button.visible = false
	home_resign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_resign_button.add_theme_color_override("font_color", Color("#e0a07a"))
	home_resign_button.add_theme_color_override("font_hover_color", Color("#ffd0b0"))
	home_resign_button.pressed.connect(_on_home_resign_pressed)
	button_stack.add_child(home_resign_button)

	var button_row := HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_theme_constant_override("separation", 11)
	button_stack.add_child(button_row)

	var multiplayer_button := _create_home_ghost_button("MULTIPLAYER")
	multiplayer_button.name = "MultiplayerButton"
	multiplayer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	multiplayer_button.pressed.connect(_on_home_multiplayer_pressed)
	button_row.add_child(multiplayer_button)

	var kingdoms_button := _create_home_ghost_button("KINGDOMS")
	kingdoms_button.name = "KingdomsButton"
	kingdoms_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kingdoms_button.pressed.connect(_on_home_kingdoms_pressed)
	button_row.add_child(kingdoms_button)

	var settings_button := _create_home_ghost_button("SETTINGS")
	settings_button.name = "SettingsButton"
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(_on_home_settings_pressed)
	button_row.add_child(settings_button)

	home_lobby_status_label = Label.new()
	home_lobby_status_label.name = "LobbyStatus"
	home_lobby_status_label.text = "Choose Multiplayer to host or join a table."
	home_lobby_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	home_lobby_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home_lobby_status_label.custom_minimum_size = Vector2(404, 0)
	home_lobby_status_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	home_lobby_status_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.08))
	home_lobby_status_label.add_theme_font_size_override("font_size", 12)
	if body_font != null:
		home_lobby_status_label.add_theme_font_override("font", body_font)
	button_stack.add_child(home_lobby_status_label)

	var footer := Label.new()
	footer.name = "HomeFooter"
	footer.text = "v0.4 · PROTOTYPE      The Bazaar opens to travelers soon."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	footer.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	footer.add_theme_color_override("font_color", Color(0.909, 0.784, 0.475, 0.5))
	footer.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		footer.add_theme_font_override("font", body_font)
	menu_layout.add_child(footer)

	_build_menu_backdrop()
	_build_settings_panel()
	_build_kingdom_browser()
	_build_multiplayer_panel()
	_build_lobby_panel()
	_refresh_home_controls()


func _build_menu_backdrop() -> void:
	# Full-screen dark vignette that sits over the home menu whenever a menu
	# panel (Settings / Kingdoms / Multiplayer / Lobby) is open, so those
	# screens read as a regal parchment-on-dark takeover rather than a popup
	# floating over the main menu buttons.
	menu_backdrop = Control.new()
	menu_backdrop.name = "MenuBackdrop"
	menu_backdrop.visible = false
	menu_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	home_overlay.add_child(menu_backdrop)
	menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vignette := TextureRect.new()
	vignette.name = "Vignette"
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.texture = _make_radial_gradient_texture(
		PackedFloat32Array([0.0, 0.55, 1.0]),
		PackedColorArray([Color("#241813"), Color("#130c08"), Color("#0a0705")]),
		Vector2(0.5, 0.42),
		Vector2(1.08, 1.0)
	)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	menu_backdrop.add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var glow := TextureRect.new()
	glow.name = "BrassGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = _make_radial_gradient_texture(
		PackedFloat32Array([0.0, 1.0]),
		PackedColorArray([Color(0.835, 0.667, 0.314, 0.16), Color(0.835, 0.667, 0.314, 0.0)]),
		Vector2(0.5, 0.5),
		Vector2(1.0, 1.0)
	)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	menu_backdrop.add_child(glow)
	glow.anchor_left = 0.5
	glow.anchor_right = 0.5
	glow.anchor_top = 0.0
	glow.anchor_bottom = 0.0
	glow.offset_left = -440
	glow.offset_right = 440
	glow.offset_top = -210
	glow.offset_bottom = 360

	if noise_texture != null:
		var grain := _create_noise_rect("MenuBackdropGrain", 0.05)
		menu_backdrop.add_child(grain)
		grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _make_radial_gradient_texture(
	offsets: PackedFloat32Array,
	colors: PackedColorArray,
	fill_from: Vector2,
	fill_to: Vector2
) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = fill_from
	texture.fill_to = fill_to
	texture.width = 320
	texture.height = 180
	return texture


func _create_home_panel(panel_name: String, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_parchment_panel_style())
	home_overlay.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -panel_size.x * 0.5
	panel.offset_top = -panel_size.y * 0.5
	panel.offset_right = panel_size.x * 0.5
	panel.offset_bottom = panel_size.y * 0.5
	return panel


func _build_settings_panel() -> void:
	home_settings_panel = _create_home_panel("SettingsPanel", Vector2(470, 772))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 20)
	home_settings_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	layout.add_child(_create_parchment_title("Settings", "Tune the table without leaving the match."))
	layout.add_child(_create_parchment_rule())
	layout.add_child(_create_settings_section_label("Audio"))

	home_audio_toggle = _create_parchment_toggle("AudioToggle", audio_enabled)
	home_audio_toggle.toggled.connect(_on_home_audio_toggled)
	layout.add_child(_create_settings_toggle_row("Sound effects", home_audio_toggle))

	sfx_volume_slider = _create_settings_slider_row(
		layout,
		"Effects volume",
		"SfxVolume",
		sfx_volume,
		0.0,
		1.0,
		VOLUME_SLIDER_STEP,
		"pct"
	)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	home_music_toggle = _create_parchment_toggle("MusicToggle", music_enabled)
	home_music_toggle.toggled.connect(_on_home_music_toggled)
	layout.add_child(_create_settings_toggle_row("Background music", home_music_toggle))

	background_music_slider = _create_settings_slider_row(
		layout,
		"Music volume",
		"BackgroundMusic",
		background_music_volume,
		0.0,
		1.0,
		VOLUME_SLIDER_STEP,
		"pct"
	)
	background_music_slider.value_changed.connect(_on_background_music_changed)

	layout.add_child(_create_settings_section_label("Gameplay"))
	home_motion_toggle = _create_parchment_toggle("MotionToggle", motion_enabled)
	home_motion_toggle.toggled.connect(_on_home_motion_toggled)
	layout.add_child(_create_settings_toggle_row("Action animations", home_motion_toggle))

	action_animation_speed_slider = _create_settings_slider_row(
		layout,
		"Animation speed",
		"ActionSpeed",
		action_animation_speed,
		0.5,
		2.0,
		0.1,
		"x"
	)
	action_animation_speed_slider.value_changed.connect(_on_action_animation_speed_changed)

	end_turn_cooldown_slider = _create_settings_slider_row(
		layout,
		"End-turn cooldown",
		"EndTurnCooldown",
		game_state.end_turn_cooldown_seconds,
		0.5,
		10.0,
		0.5,
		"s"
	)
	end_turn_cooldown_slider.value_changed.connect(_on_end_turn_cooldown_changed)

	layout.add_child(_create_settings_section_label("Atmosphere and display"))
	table_noise_slider = _create_settings_slider_row(
		layout,
		"Table grain",
		"TableNoise",
		table_noise_amount,
		0.0,
		0.24,
		0.01,
		"pct"
	)
	table_noise_slider.value_changed.connect(_on_table_noise_changed)

	home_noise_slider = _create_settings_slider_row(
		layout,
		"Menu grain",
		"HomeNoise",
		home_noise_amount,
		0.0,
		0.35,
		0.01,
		"pct"
	)
	home_noise_slider.value_changed.connect(_on_home_noise_changed)

	fullscreen_toggle = _create_parchment_toggle("FullscreenToggle", false)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	layout.add_child(_create_settings_toggle_row("Fullscreen", fullscreen_toggle))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	layout.add_child(footer)
	var back_button := _create_parchment_button("BackButton", "<- BACK", false)
	back_button.pressed.connect(_on_home_back_pressed)
	footer.add_child(back_button)
	var done_button := _create_parchment_button("DoneButton", "DONE", true)
	done_button.pressed.connect(_on_home_back_pressed)
	footer.add_child(done_button)


func _build_multiplayer_panel() -> void:
	home_multiplayer_panel = _create_home_panel("MultiplayerPanel", Vector2(548, 430))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	home_multiplayer_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	layout.add_child(_create_parchment_title("Multiplayer", "Gather a local table or open an online room."))
	layout.add_child(_create_parchment_rule())

	var options := GridContainer.new()
	options.name = "Options"
	options.columns = 2
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("h_separation", 14)
	options.add_theme_constant_override("v_separation", 14)
	layout.add_child(options)

	home_create_lobby_button = _create_multiplayer_option_button(
		"CreateLocalButton",
		"Create local",
		"Host a table on your network.",
		true,
		"host"
	)
	home_create_lobby_button.pressed.connect(_on_home_create_lobby_pressed)
	options.add_child(home_create_lobby_button)

	home_join_lobby_button = _create_multiplayer_option_button(
		"JoinLocalButton",
		"Join local",
		"Enter a host IP to join.",
		true,
		"join"
	)
	home_join_lobby_button.pressed.connect(_on_home_join_lobby_pressed)
	options.add_child(home_join_lobby_button)

	home_create_online_button = _create_multiplayer_option_button(
		"CreateOnlineButton",
		"Create online",
		"Set rules, then generate a code.",
		true,
		"online"
	)
	home_create_online_button.pressed.connect(_on_home_create_online_pressed)
	options.add_child(home_create_online_button)

	home_join_online_button = _create_multiplayer_option_button(
		"JoinOnlineButton",
		"Join online",
		"Enter a 4-letter code.",
		true,
		"online"
	)
	home_join_online_button.pressed.connect(_on_home_join_online_pressed)
	options.add_child(home_join_online_button)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(footer)
	var back_button := _create_parchment_button("BackButton", "<- BACK", false)
	back_button.pressed.connect(_on_home_back_pressed)
	footer.add_child(back_button)


func _build_lobby_panel() -> void:
	home_lobby_panel = _create_home_panel("LobbyPanel", Vector2(790, 560))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	home_lobby_panel.add_child(margin)

	var columns := HBoxContainer.new()
	columns.name = "Columns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	margin.add_child(columns)

	var left := VBoxContainer.new()
	left.name = "SeatsColumn"
	left.custom_minimum_size = Vector2(420, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)
	left.add_child(_create_parchment_title("Lobby", "Seat players before opening the table."))
	left.add_child(_create_parchment_rule())

	# A big, unmissable lobby code banner: this is the thing players share.
	lobby_code_banner = PanelContainer.new()
	lobby_code_banner.name = "CodeBanner"
	lobby_code_banner.visible = false
	lobby_code_banner.custom_minimum_size = Vector2(0, 74)
	lobby_code_banner.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color(0.16, 0.115, 0.06, 0.92), COLOR_BRASS, 12)
	)
	left.add_child(lobby_code_banner)
	var banner_stack := VBoxContainer.new()
	banner_stack.name = "Stack"
	banner_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_stack.add_theme_constant_override("separation", 0)
	lobby_code_banner.add_child(banner_stack)
	var banner_eyebrow := Label.new()
	banner_eyebrow.name = "Eyebrow"
	banner_eyebrow.text = "LOBBY CODE"
	banner_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_eyebrow.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	banner_eyebrow.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		banner_eyebrow.add_theme_font_override("font", title_font)
	banner_stack.add_child(banner_eyebrow)
	lobby_code_value_label = Label.new()
	lobby_code_value_label.name = "CodeValue"
	lobby_code_value_label.text = "...."
	lobby_code_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_code_value_label.add_theme_color_override("font_color", COLOR_BRASS)
	lobby_code_value_label.add_theme_font_size_override("font_size", 34)
	lobby_code_value_label.add_theme_constant_override("outline_size", 0)
	if title_font != null:
		lobby_code_value_label.add_theme_font_override("font", title_font)
	banner_stack.add_child(lobby_code_value_label)

	var name_row := HBoxContainer.new()
	name_row.name = "NameRow"
	name_row.add_theme_constant_override("separation", 8)
	left.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Your name"
	name_label.custom_minimum_size = Vector2(84, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	name_label.add_theme_font_size_override("font_size", 14)
	if body_font != null:
		name_label.add_theme_font_override("font", body_font)
	name_row.add_child(name_label)
	lobby_name_input = LineEdit.new()
	lobby_name_input.name = "LobbyName"
	lobby_name_input.text = player_display_name
	lobby_name_input.placeholder_text = "Your name"
	lobby_name_input.max_length = 18
	lobby_name_input.custom_minimum_size = Vector2(0, 34)
	lobby_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lobby_name_input.add_theme_stylebox_override("normal", _make_parchment_input_style())
	lobby_name_input.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	if body_font != null:
		lobby_name_input.add_theme_font_override("font", body_font)
	lobby_name_input.text_changed.connect(_on_lobby_name_changed)
	lobby_name_input.text_submitted.connect(_on_name_submitted)
	lobby_name_input.focus_exited.connect(_on_name_focus_exited)
	name_row.add_child(lobby_name_input)

	show_opponent_names_toggle = _create_parchment_toggle("ShowNamesToggle", show_opponent_names)
	show_opponent_names_toggle.toggled.connect(_on_show_opponent_names_toggled)
	left.add_child(_create_settings_toggle_row("Show opponent names", show_opponent_names_toggle))

	home_lobby_seat_list = VBoxContainer.new()
	home_lobby_seat_list.name = "SeatList"
	home_lobby_seat_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_lobby_seat_list.add_theme_constant_override("separation", 8)
	left.add_child(home_lobby_seat_list)

	var invite_row := HBoxContainer.new()
	invite_row.name = "InviteRow"
	invite_row.add_theme_constant_override("separation", 8)
	left.add_child(invite_row)
	home_lobby_address_input = LineEdit.new()
	home_lobby_address_input.name = "LobbyAddress"
	home_lobby_address_input.text = "%s:%d" % [NETWORK_DEFAULT_ADDRESS, NETWORK_PORT]
	home_lobby_address_input.placeholder_text = "Host address"
	home_lobby_address_input.custom_minimum_size = Vector2(0, 34)
	home_lobby_address_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_lobby_address_input.add_theme_stylebox_override("normal", _make_parchment_input_style())
	home_lobby_address_input.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	if body_font != null:
		home_lobby_address_input.add_theme_font_override("font", body_font)
	home_lobby_address_input.text_changed.connect(_on_lobby_address_text_changed)
	invite_row.add_child(home_lobby_address_input)
	var copy_button := _create_parchment_button("CopyButton", "COPY", false)
	copy_button.pressed.connect(_on_lobby_copy_pressed)
	invite_row.add_child(copy_button)

	lobby_panel_status_label = Label.new()
	lobby_panel_status_label.name = "LobbyPanelStatus"
	lobby_panel_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lobby_panel_status_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.08))
	lobby_panel_status_label.add_theme_font_size_override("font_size", 12)
	if body_font != null:
		lobby_panel_status_label.add_theme_font_override("font", body_font)
	left.add_child(lobby_panel_status_label)

	var right := VBoxContainer.new()
	right.name = "RulesColumn"
	right.custom_minimum_size = Vector2(280, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	var rules_title := Label.new()
	rules_title.name = "RulesTitle"
	rules_title.text = "Table rules"
	rules_title.add_theme_color_override("font_color", COLOR_PARCHMENT_INK)
	rules_title.add_theme_font_size_override("font_size", 24)
	if title_font != null:
		rules_title.add_theme_font_override("font", title_font)
	right.add_child(rules_title)

	lobby_cooldown_slider = _create_settings_slider_row(
		right,
		"Turn cooldown",
		"LobbyCooldown",
		game_state.end_turn_cooldown_seconds,
		0.5,
		10.0,
		0.5,
		"s"
	)
	lobby_cooldown_slider.value_changed.connect(_on_end_turn_cooldown_changed)

	right.add_child(_create_lobby_max_players_row())

	home_lobby_turn_based_toggle = _create_parchment_toggle(
		"TurnBasedToggle",
		game_state.turn_based_enabled
	)
	home_lobby_turn_based_toggle.toggled.connect(_on_lobby_turn_based_toggled)
	right.add_child(_create_settings_toggle_row("Turn based", home_lobby_turn_based_toggle))

	var kingdom_row := HBoxContainer.new()
	kingdom_row.name = "KingdomRow"
	kingdom_row.add_theme_constant_override("separation", 8)
	right.add_child(kingdom_row)
	var kingdom_label := Label.new()
	kingdom_label.text = "Kingdom: Base Kingdom"
	kingdom_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kingdom_label.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	kingdom_label.add_theme_font_size_override("font_size", 14)
	if body_font != null:
		kingdom_label.add_theme_font_override("font", body_font)
	kingdom_row.add_child(kingdom_label)
	home_lobby_edit_kingdom_button = _create_parchment_button("EditKingdomButton", "EDIT", false)
	home_lobby_edit_kingdom_button.pressed.connect(_on_home_kingdoms_pressed)
	kingdom_row.add_child(home_lobby_edit_kingdom_button)

	home_lobby_rules_summary = Label.new()
	home_lobby_rules_summary.name = "RulesSummary"
	home_lobby_rules_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home_lobby_rules_summary.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	home_lobby_rules_summary.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		home_lobby_rules_summary.add_theme_font_override("font", body_font)
	right.add_child(home_lobby_rules_summary)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	right.add_child(footer)
	var leave_button := _create_parchment_button("LeaveButton", "<- LEAVE", false)
	leave_button.pressed.connect(_on_lobby_leave_pressed)
	footer.add_child(leave_button)
	home_lobby_start_button = _create_parchment_button("StartGameButton", "START GAME", true)
	home_lobby_start_button.pressed.connect(_on_lobby_start_pressed)
	footer.add_child(home_lobby_start_button)


func _create_parchment_title(title_text: String, subtitle: String) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.name = "%sTitleBlock" % _node_key(title_text)
	stack.add_theme_constant_override("separation", 3)
	var crest := _create_logo_emblem(30)
	crest.name = "Crest"
	crest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(crest)
	var title := Label.new()
	title.name = "Title"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_PARCHMENT_INK)
	title.add_theme_font_size_override("font_size", 36)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	stack.add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = subtitle
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	sub.add_theme_font_size_override("font_size", 14)
	if body_font != null:
		sub.add_theme_font_override("font", body_font)
	stack.add_child(sub)
	return stack


func _create_parchment_rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.name = "GoldRule"
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = Color(0.835, 0.667, 0.314, 0.4)
	return rule


func _create_settings_section_label(text: String) -> Label:
	var label := Label.new()
	label.name = "%sSection" % _node_key(text)
	label.text = text.to_upper()
	label.add_theme_color_override("font_color", COLOR_MENU_ACCENT)
	label.add_theme_font_size_override("font_size", 12)
	if title_font != null:
		label.add_theme_font_override("font", title_font)
	return label


func _create_settings_toggle_row(label_text: String, toggle: CheckButton) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "%sRow" % _node_key(label_text)
	row.custom_minimum_size = Vector2(0, 34)
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	label.add_theme_font_size_override("font_size", 15)
	if body_font != null:
		label.add_theme_font_override("font", body_font)
	row.add_child(label)
	row.add_child(toggle)
	return row


func _create_settings_slider_row(
	parent: Container,
	label_text: String,
	node_name: String,
	value: float,
	minimum: float,
	maximum: float,
	step: float,
	display_mode: String
) -> HSlider:
	var row := HBoxContainer.new()
	row.name = "%sRow" % node_name
	row.custom_minimum_size = Vector2(0, 38)
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	label.add_theme_font_size_override("font_size", 15)
	if body_font != null:
		label.add_theme_font_override("font", body_font)
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "%sSlider" % node_name
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_label := Label.new()
	value_label.name = "%sValue" % node_name
	value_label.custom_minimum_size = Vector2(44, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_color_override("font_color", COLOR_MENU_ACCENT)
	value_label.add_theme_font_size_override("font_size", 13)
	if body_bold_font != null:
		value_label.add_theme_font_override("font", body_bold_font)
	row.add_child(value_label)
	_update_settings_slider_value(value, value_label, display_mode)
	slider.value_changed.connect(_on_settings_slider_value_changed.bind(value_label, display_mode))
	return slider


func _create_parchment_toggle(toggle_name: String, pressed: bool) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.name = toggle_name
	toggle.text = ""
	toggle.button_pressed = pressed
	toggle.custom_minimum_size = Vector2(58, 31)
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	return toggle


func _create_parchment_button(button_name: String, label: String, primary: bool) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = label
	var button_width := 116 if primary else 92
	button.custom_minimum_size = Vector2(button_width, 36)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var font_color := Color("#2c1d0c") if primary else COLOR_PARCHMENT_BODY
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override(
		"font_disabled_color",
		Color(0.42, 0.34, 0.22, 0.58)
	)
	button.add_theme_font_size_override("font_size", 13)
	if title_font != null:
		button.add_theme_font_override("font", title_font)
	button.add_theme_stylebox_override("normal", _make_parchment_button_style(primary))
	button.add_theme_stylebox_override("hover", _make_parchment_button_style(primary, true))
	button.add_theme_stylebox_override("pressed", _make_parchment_button_style(primary))
	button.add_theme_stylebox_override("disabled", _make_parchment_button_style(primary, false, true))
	return button


func _create_multiplayer_option_button(
	button_name: String,
	title: String,
	description: String,
	enabled: bool,
	icon_kind: String = "online"
) -> Button:
	var button := Button.new()
	button.name = button_name
	button.custom_minimum_size = Vector2(230, 118)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.disabled = not enabled
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	button.add_theme_stylebox_override("normal", _make_parchment_button_style(false))
	button.add_theme_stylebox_override("hover", _make_parchment_button_style(false, true))
	button.add_theme_stylebox_override("disabled", _make_parchment_button_style(false, false, true))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)

	var ink := COLOR_PARCHMENT_INK if enabled else COLOR_PARCHMENT_MUTED
	row.add_child(_create_mp_icon_tile(icon_kind, enabled))

	var text_column := VBoxContainer.new()
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 4)
	row.add_child(text_column)

	var title_label := Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = title
	title_label.add_theme_color_override("font_color", ink)
	title_label.add_theme_font_size_override("font_size", 18)
	if title_font != null:
		title_label.add_theme_font_override("font", title_font)
	text_column.add_child(title_label)

	var desc_label := Label.new()
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	desc_label.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		desc_label.add_theme_font_override("font", body_font)
	text_column.add_child(desc_label)
	return button


func _create_mp_icon_tile(kind: String, enabled: bool) -> Panel:
	# A dark, antique-brass medallion: deep translucent walnut fill with a thin
	# brass rim, then a crisp line-art glyph drawn directly so it always renders
	# (the old approach leaned on font glyphs that fell back to empty boxes).
	var tile := Panel.new()
	tile.clip_contents = true
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.custom_minimum_size = Vector2(46, 46)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := Color(0.14, 0.095, 0.052, 0.66) if enabled else Color(0.14, 0.1, 0.06, 0.34)
	var rim := Color(0.835, 0.667, 0.314, 0.7) if enabled else Color(0.835, 0.667, 0.314, 0.28)
	var style := _make_flat_card_style(fill, rim, 1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.35) if enabled else Color.TRANSPARENT
	style.shadow_size = 5 if enabled else 0
	style.shadow_offset = Vector2(0, 2)
	tile.add_theme_stylebox_override("panel", style)

	var glyph := Control.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := Color("#e8c879") if enabled else Color(0.835, 0.667, 0.314, 0.42)
	glyph.draw.connect(_draw_mp_icon.bind(glyph, kind, ink))
	tile.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return tile


func _draw_mp_icon(canvas: Control, kind: String, ink: Color) -> void:
	# Line-art icons drawn in the canvas's local space (the icon tile, ~46x46).
	var c := canvas.size * 0.5
	var w := 2.4
	match kind:
		"host":
			# A table / pavilion: a peaked roof over an open frame.
			canvas.draw_polyline(PackedVector2Array([
				Vector2(c.x - 10, c.y - 1),
				Vector2(c.x, c.y - 10),
				Vector2(c.x + 10, c.y - 1),
			]), ink, w, true)
			canvas.draw_polyline(PackedVector2Array([
				Vector2(c.x - 7, c.y - 1),
				Vector2(c.x - 7, c.y + 8),
				Vector2(c.x + 7, c.y + 8),
				Vector2(c.x + 7, c.y - 1),
			]), ink, w, true)
			canvas.draw_line(Vector2(c.x, c.y + 8), Vector2(c.x, c.y + 2), ink, w, true)
		"join":
			# Enter / arrow stepping through a doorway.
			canvas.draw_line(Vector2(c.x - 10, c.y), Vector2(c.x + 4, c.y), ink, w, true)
			canvas.draw_polyline(PackedVector2Array([
				Vector2(c.x, c.y - 5),
				Vector2(c.x + 5, c.y),
				Vector2(c.x, c.y + 5),
			]), ink, w, true)
			canvas.draw_line(Vector2(c.x + 8, c.y - 9), Vector2(c.x + 8, c.y + 9), ink, w, true)
		_:
			# Globe: an outer ring with latitude chords and a central meridian.
			canvas.draw_arc(c, 9.0, 0.0, TAU, 48, ink, w, true)
			canvas.draw_line(Vector2(c.x - 9, c.y), Vector2(c.x + 9, c.y), ink, w, true)
			canvas.draw_line(Vector2(c.x - 7, c.y - 4.5), Vector2(c.x + 7, c.y - 4.5), ink, w * 0.8, true)
			canvas.draw_line(Vector2(c.x - 7, c.y + 4.5), Vector2(c.x + 7, c.y + 4.5), ink, w * 0.8, true)
			canvas.draw_line(Vector2(c.x, c.y - 9), Vector2(c.x, c.y + 9), ink, w, true)


func _create_lobby_max_players_row() -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.name = "MaxPlayersRow"
	stack.add_theme_constant_override("separation", 5)
	var label := Label.new()
	label.text = "Max players"
	label.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	label.add_theme_font_size_override("font_size", 15)
	if body_font != null:
		label.add_theme_font_override("font", body_font)
	stack.add_child(label)
	var segments := HBoxContainer.new()
	segments.name = "Segments"
	segments.add_theme_constant_override("separation", 6)
	stack.add_child(segments)
	for count in [2, 3, 4]:
		var button := _create_parchment_button("Max%dButton" % count, str(count), count == lobby_max_players)
		button.toggle_mode = true
		button.button_pressed = count == lobby_max_players
		button.custom_minimum_size = Vector2(54, 32)
		button.pressed.connect(_on_lobby_max_players_pressed.bind(count))
		segments.add_child(button)
	return stack


func _refresh_lobby_panel() -> void:
	if home_lobby_seat_list == null:
		return
	if lobby_name_input != null and not lobby_name_input.has_focus() and lobby_name_input.text != player_display_name:
		lobby_name_input.text = player_display_name
	if show_opponent_names_toggle != null:
		show_opponent_names_toggle.set_pressed_no_signal(show_opponent_names)
	var can_edit_table := _can_edit_table_settings()
	var can_edit_lobby_setup := _can_edit_lobby_setup()
	var online_mode := lobby_pending_mode == "host_online" or lobby_pending_mode == "join_online"
	if not network_enabled:
		if lobby_pending_mode == "host_online":
			_set_lobby_status("Press CREATE LOBBY to generate a 4-letter code.")
		elif lobby_pending_mode == "join_online":
			_set_lobby_status("Enter a 4-letter code from the host.")
	if lobby_code_banner != null:
		var show_code := online_mode and not online_relay_lobby_code.is_empty()
		lobby_code_banner.visible = show_code
		if show_code and lobby_code_value_label != null:
			# Space the letters out so the code reads at a glance.
			lobby_code_value_label.text = " ".join(online_relay_lobby_code.split(""))
	_clear_container(home_lobby_seat_list)
	var filled_seats: Array[int] = []
	if network_enabled:
		# Show who is actually connected, not just how many seats exist.
		if network_is_host:
			filled_seats = _connected_seat_indexes()
		elif not network_connected_seats.is_empty():
			filled_seats = network_connected_seats.duplicate()
		else:
			filled_seats = [0, clampi(local_player_index, 0, NETWORK_MAX_PLAYERS - 1)]
	else:
		var filled_count := game_state.players.size() if has_active_game else 1
		filled_count = clampi(filled_count, 1, lobby_max_players)
		for index in range(filled_count):
			filled_seats.append(index)
	for index in range(lobby_max_players):
		home_lobby_seat_list.add_child(_create_lobby_seat_row(index, filled_seats.has(index)))
	if home_lobby_rules_summary != null:
		if lobby_pending_mode == "host_online":
			home_lobby_rules_summary.text = (
				"Cooldown %.1fs, up to %d players, attacks on."
				% [game_state.end_turn_cooldown_seconds, lobby_max_players]
			)
		elif lobby_pending_mode == "join_online":
			home_lobby_rules_summary.text = (
				"Online: enter the host's 4-letter code. Cooldown %.1fs, up to %d players, attacks on."
				% [game_state.end_turn_cooldown_seconds, lobby_max_players]
			)
		elif game_state.turn_based_enabled:
			home_lobby_rules_summary.text = (
				"Turn based: pass-and-play on one screen with no timer. "
				+ "Up to %d players take sequential turns; the next player goes when you finish."
				% lobby_max_players
			)
		else:
			home_lobby_rules_summary.text = (
				"Starts when all seated players are ready. Cooldown %.1fs, up to %d players, attacks on."
				% [game_state.end_turn_cooldown_seconds, lobby_max_players]
			)
		if not can_edit_table:
			home_lobby_rules_summary.text += " Only the host can edit table rules."
	if home_lobby_start_button != null:
		home_lobby_start_button.disabled = (
			not game_state.has_enough_market_candidates()
			or (network_enabled and not network_is_host)
		)
		match lobby_pending_mode:
			"join":
				home_lobby_start_button.text = "JOIN LOBBY"
			"host_online":
				home_lobby_start_button.text = (
					"ENTER TABLE"
					if network_enabled and has_active_game and not online_relay_lobby_code.is_empty()
					else "CREATE LOBBY"
				)
			"join_online":
				if network_enabled and not network_is_host:
					# A seated guest signals readiness instead of starting.
					if lobby_ready_sent or network_ready_seats.has(local_player_index):
						home_lobby_start_button.text = "READY - WAITING FOR HOST"
						home_lobby_start_button.disabled = true
					else:
						home_lobby_start_button.text = "I'M READY"
						home_lobby_start_button.disabled = false
				else:
					home_lobby_start_button.text = "JOIN ONLINE"
			_:
				home_lobby_start_button.text = "START GAME"
	if home_lobby_address_input != null:
		# Turn-based tables are local, so the network invite row is dimmed.
		var online_lobby := lobby_pending_mode == "host_online" or lobby_pending_mode == "join_online"
		var network_lobby := online_lobby or not game_state.turn_based_enabled or lobby_pending_mode == "join"
		home_lobby_address_input.editable = (
			network_lobby
			and (lobby_pending_mode == "join" or lobby_pending_mode == "join_online")
			and not network_enabled
		)
		home_lobby_address_input.modulate = Color(1, 1, 1, 1.0 if network_lobby else 0.4)
		if lobby_pending_mode == "host":
			home_lobby_address_input.text = "%s:%d" % [NETWORK_DEFAULT_ADDRESS, NETWORK_PORT]
			home_lobby_address_input.placeholder_text = "Host address"
		elif lobby_pending_mode == "host_online":
			if not online_relay_lobby_code.is_empty():
				home_lobby_address_input.text = online_relay_lobby_code
			else:
				home_lobby_address_input.text = ""
			home_lobby_address_input.placeholder_text = "Code appears here"
		elif lobby_pending_mode == "join_online":
			if not network_enabled:
				home_lobby_address_input.text = _normalize_online_lobby_code(home_lobby_address_input.text)
			home_lobby_address_input.placeholder_text = "4-letter code"
	if home_lobby_turn_based_toggle != null:
		home_lobby_turn_based_toggle.set_pressed_no_signal(game_state.turn_based_enabled)
		home_lobby_turn_based_toggle.disabled = (
			not can_edit_lobby_setup
			or lobby_pending_mode == "host_online"
			or lobby_pending_mode == "join_online"
		)
	if lobby_cooldown_slider != null:
		lobby_cooldown_slider.editable = can_edit_table
		lobby_cooldown_slider.modulate = Color(1, 1, 1, 1.0 if can_edit_table else 0.4)
	if home_lobby_edit_kingdom_button != null:
		home_lobby_edit_kingdom_button.disabled = not can_edit_lobby_setup
		home_lobby_edit_kingdom_button.modulate = Color(
			1,
			1,
			1,
			1.0 if can_edit_lobby_setup else 0.4
		)
	var max_buttons := home_lobby_panel.find_children("Max*Button", "Button", true, false)
	for button_node in max_buttons:
		var button := button_node as Button
		if button != null:
			button.disabled = not can_edit_lobby_setup
			button.modulate = Color(1, 1, 1, 1.0 if can_edit_lobby_setup else 0.4)


func _create_lobby_seat_row(index: int, filled: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Seat%d" % (index + 1)
	panel.custom_minimum_size = Vector2(0, 62)
	var seat_bg := Color(0.19, 0.14, 0.085, 0.6) if filled else Color(0.07, 0.05, 0.03, 0.42)
	var seat_border_alpha := 0.5 if filled else 0.24
	panel.add_theme_stylebox_override(
		"panel",
		_make_pill_style(
			seat_bg,
			Color(0.612, 0.435, 0.157, seat_border_alpha),
			10
		)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(38, 38)
	avatar.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color("#9c6f28"), Color("#6e4a16"), 19)
	)
	row.add_child(avatar)
	var avatar_label := Label.new()
	if not filled:
		avatar_label.text = str(index + 1)
	elif index == local_player_index:
		avatar_label.text = "Y"
	else:
		avatar_label.text = "P"
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", Color("#f5e6c0"))
	avatar_label.add_theme_font_size_override("font_size", 16)
	if title_font != null:
		avatar_label.add_theme_font_override("font", title_font)
	avatar.add_child(avatar_label)

	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 1)
	row.add_child(names)
	var title := Label.new()
	if filled:
		if index == local_player_index:
			var own := player_display_name.strip_edges()
			title.text = "%s (you)" % (own if not own.is_empty() else "Player %d" % (index + 1))
		else:
			title.text = _display_name_for(index)
		if index == 0:
			title.text += " - host"
	else:
		title.text = "Open seat %d" % (index + 1)
	title.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY if filled else COLOR_PARCHMENT_MUTED)
	title.add_theme_font_size_override("font_size", 15)
	if body_bold_font != null:
		title.add_theme_font_override("font", body_bold_font)
	names.add_child(title)
	var seat_ready := filled and _is_seat_ready(index)
	var seat_is_host := network_enabled and index == 0

	var sub := Label.new()
	if not filled:
		sub.text = "Waiting for a player"
	elif network_enabled and not seat_ready:
		sub.text = "Getting ready..."
	else:
		sub.text = "Starting deck ready"
	sub.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	sub.add_theme_font_size_override("font_size", 12)
	if body_font != null:
		sub.add_theme_font_override("font", body_font)
	names.add_child(sub)

	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(74, 24)
	var ready_bg := Color(0.46, 0.34, 0.16, 0.18)
	var ready_border := Color(0.46, 0.34, 0.16, 0.26)
	if seat_ready:
		ready_bg = Color("#3d7d58")
		ready_border = Color("#2f6949")
	elif filled:
		ready_bg = Color("#8a6a2a")
		ready_border = Color("#6e5320")
	pill.add_theme_stylebox_override(
		"panel",
		_make_pill_style(
			ready_bg,
			ready_border,
			8
		)
	)
	row.add_child(pill)
	var pill_label := Label.new()
	if seat_is_host:
		pill_label.text = "HOST"
	elif seat_ready:
		pill_label.text = "READY"
	elif filled:
		pill_label.text = "JOINED"
	else:
		pill_label.text = "WAITING"
	pill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pill_text_color := Color("#f5e6c0") if filled else COLOR_PARCHMENT_MUTED
	pill_label.add_theme_color_override("font_color", pill_text_color)
	pill_label.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		pill_label.add_theme_font_override("font", title_font)
	pill.add_child(pill_label)
	return panel


func _build_kingdom_browser() -> void:
	home_kingdoms_panel = PanelContainer.new()
	home_kingdoms_panel.name = "KingdomsPanel"
	home_kingdoms_panel.visible = false
	home_kingdoms_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	home_kingdoms_panel.add_theme_stylebox_override(
		"panel",
		_make_parchment_panel_style()
	)
	home_overlay.add_child(home_kingdoms_panel)
	home_kingdoms_panel.anchor_left = 0.04
	home_kingdoms_panel.anchor_top = 0.05
	home_kingdoms_panel.anchor_right = 0.96
	home_kingdoms_panel.anchor_bottom = 0.95
	home_kingdoms_panel.offset_left = 0
	home_kingdoms_panel.offset_top = 0
	home_kingdoms_panel.offset_right = 0
	home_kingdoms_panel.offset_bottom = 0

	var browser_margin := MarginContainer.new()
	browser_margin.name = "Margin"
	browser_margin.add_theme_constant_override("margin_left", 20)
	browser_margin.add_theme_constant_override("margin_top", 20)
	browser_margin.add_theme_constant_override("margin_right", 20)
	browser_margin.add_theme_constant_override("margin_bottom", 20)
	home_kingdoms_panel.add_child(browser_margin)

	var outer_layout := VBoxContainer.new()
	outer_layout.name = "Layout"
	outer_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_layout.add_theme_constant_override("separation", 12)
	browser_margin.add_child(outer_layout)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.custom_minimum_size = Vector2(0, 32)
	header.add_theme_constant_override("separation", 8)
	outer_layout.add_child(header)

	var heading := Label.new()
	heading.name = "Title"
	heading.text = "Kingdoms"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", COLOR_PARCHMENT_INK)
	heading.add_theme_font_size_override("font_size", 34)
	if title_font != null:
		heading.add_theme_font_override("font", title_font)
	header.add_child(heading)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "<- BACK"
	close_button.custom_minimum_size = Vector2(92, 34)
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	close_button.add_theme_font_size_override("font_size", 12)
	if body_bold_font != null:
		close_button.add_theme_font_override("font", body_bold_font)
	close_button.add_theme_stylebox_override("normal", _make_parchment_button_style(false))
	close_button.add_theme_stylebox_override("hover", _make_parchment_button_style(false, true))
	close_button.add_theme_stylebox_override("pressed", _make_parchment_button_style(false))
	close_button.pressed.connect(_on_kingdoms_close_pressed)
	header.add_child(close_button)

	var browser := HBoxContainer.new()
	browser.name = "Browser"
	browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser.add_theme_constant_override("separation", 14)
	outer_layout.add_child(browser)

	home_kingdom_tab_list = VBoxContainer.new()
	home_kingdom_tab_list.name = "KingdomTabs"
	home_kingdom_tab_list.custom_minimum_size = Vector2(150, 0)
	home_kingdom_tab_list.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	home_kingdom_tab_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_kingdom_tab_list.add_theme_constant_override("separation", 8)
	browser.add_child(home_kingdom_tab_list)

	var cards_pane := VBoxContainer.new()
	cards_pane.name = "CardsPane"
	cards_pane.custom_minimum_size = Vector2(470, 0)
	cards_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_pane.add_theme_constant_override("separation", 8)
	browser.add_child(cards_pane)

	home_kingdom_title_label = Label.new()
	home_kingdom_title_label.name = "KingdomTitle"
	home_kingdom_title_label.add_theme_color_override("font_color", COLOR_PARCHMENT_INK)
	home_kingdom_title_label.add_theme_font_size_override("font_size", 24)
	if title_font != null:
		home_kingdom_title_label.add_theme_font_override("font", title_font)
	cards_pane.add_child(home_kingdom_title_label)

	home_kingdom_summary_label = Label.new()
	home_kingdom_summary_label.name = "KingdomSummary"
	home_kingdom_summary_label.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	home_kingdom_summary_label.add_theme_font_size_override("font_size", 12)
	if body_bold_font != null:
		home_kingdom_summary_label.add_theme_font_override("font", body_bold_font)
	cards_pane.add_child(home_kingdom_summary_label)

	var card_scroll := ScrollContainer.new()
	card_scroll.name = "CardScroll"
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	cards_pane.add_child(card_scroll)

	home_kingdom_card_grid = GridContainer.new()
	home_kingdom_card_grid.name = "CardGrid"
	home_kingdom_card_grid.columns = 4
	home_kingdom_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_kingdom_card_grid.add_theme_constant_override("h_separation", 7)
	home_kingdom_card_grid.add_theme_constant_override("v_separation", 7)
	card_scroll.add_child(home_kingdom_card_grid)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "DetailPane"
	detail_panel.custom_minimum_size = Vector2(240, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override(
		"panel",
			_make_pill_style(Color(0.05, 0.035, 0.022, 0.55), Color(0.835, 0.667, 0.314, 0.32), 14)
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



func _create_home_divider() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "HomeDivider"
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 14)

	var left_line := ColorRect.new()
	left_line.custom_minimum_size = Vector2(82, 1)
	left_line.color = Color(0.835, 0.667, 0.314, 0.55)
	left_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(left_line)

	var diamond := Label.new()
	diamond.text = "◆"
	diamond.add_theme_color_override("font_color", Color("#d5aa50"))
	diamond.add_theme_font_size_override("font_size", 11)
	row.add_child(diamond)

	var right_line := ColorRect.new()
	right_line.custom_minimum_size = Vector2(82, 1)
	right_line.color = Color(0.835, 0.667, 0.314, 0.55)
	right_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(right_line)
	return row


func _create_home_primary_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(330, 50)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", Color("#3a2410"))
	button.add_theme_color_override("font_hover_color", Color("#2a1908"))
	button.add_theme_color_override("font_disabled_color", Color(0.23, 0.2, 0.16, 0.7))
	button.add_theme_font_size_override("font_size", 18)
	if title_font != null:
		button.add_theme_font_override("font", title_font)
	button.add_theme_stylebox_override("normal", _make_end_turn_style(false))
	button.add_theme_stylebox_override("hover", _make_end_turn_style(true))
	button.add_theme_stylebox_override("pressed", _make_end_turn_style(false))
	button.add_theme_stylebox_override("disabled", _make_end_turn_style(false, true))
	return button


func _create_home_ghost_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 44)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", COLOR_PARCHMENT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", COLOR_PARCHMENT.darkened(0.4))
	button.add_theme_font_size_override("font_size", 14)
	if title_font != null:
		button.add_theme_font_override("font", title_font)
	button.add_theme_stylebox_override(
		"normal",
		_make_pill_style(Color(0.157, 0.114, 0.078, 0.6), Color(0.835, 0.667, 0.314, 0.42), 11)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_pill_style(Color(0.22, 0.16, 0.1, 0.7), Color(0.835, 0.667, 0.314, 0.7), 11)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_pill_style(Color(0.13, 0.094, 0.062, 0.8), Color(0.835, 0.667, 0.314, 0.5), 11)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_pill_style(Color(0.1, 0.08, 0.06, 0.45), Color(0.4, 0.32, 0.18, 0.3), 11)
	)
	return button


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
	_hide_all_previews()
	_refresh_home_controls()
	if not _home_modal_is_visible():
		_set_menu_overlay_active(false)
	if home_overlay != null:
		home_overlay.show()


func _hide_home_screen() -> void:
	if home_overlay != null:
		home_overlay.hide()
	# A relic offer may have been waiting behind the menu.
	_refresh_relic_overlay()


func _refresh_home_controls() -> void:
	var can_start := (
		not game_state.card_catalog.is_empty()
		and game_state.has_enough_market_candidates()
	)
	if home_new_game_button != null:
		home_new_game_button.disabled = not can_start
	if home_continue_button != null:
		home_continue_button.disabled = not has_active_game
	if home_resign_button != null:
		home_resign_button.visible = has_active_game
	if home_create_lobby_button != null:
		home_create_lobby_button.disabled = not can_start
	if home_join_lobby_button != null:
		home_join_lobby_button.disabled = not can_start or network_enabled
	if home_create_online_button != null:
		home_create_online_button.disabled = not can_start or network_enabled
	if home_join_online_button != null:
		home_join_online_button.disabled = not can_start or network_enabled
	if home_lobby_address_input != null:
		home_lobby_address_input.editable = (
			(lobby_pending_mode == "join" or lobby_pending_mode == "join_online")
			and not network_enabled
		)
	if home_lobby_status_label != null:
		if network_enabled and network_is_host and network_mode == NETWORK_MODE_ONLINE:
			home_lobby_status_label.text = (
				"Online lobby %s. Share this code."
				% (online_relay_lobby_code if not online_relay_lobby_code.is_empty() else "....")
			)
		elif network_enabled and network_is_host:
			home_lobby_status_label.text = (
				"Hosting on port %d. Give players your IP address."
				% NETWORK_PORT
			)
		elif network_enabled and network_mode == NETWORK_MODE_ONLINE:
			home_lobby_status_label.text = (
				"Connected to %s as Player %d.%s"
				% [
					online_relay_lobby_code,
					local_player_index + 1,
					"" if network_table_open else " Waiting for the host to start...",
				]
			)
		elif network_enabled:
			home_lobby_status_label.text = "Connected as Player %d." % (local_player_index + 1)
		elif game_state.multiplayer_enabled:
			home_lobby_status_label.text = (
				"Active lobby: %d players share this market."
				% game_state.get_player_count()
			)
		elif lobby_pending_mode == "host_online":
			home_lobby_status_label.text = "Press CREATE LOBBY to generate a 4-letter code."
		elif lobby_pending_mode == "join_online":
			home_lobby_status_label.text = "Enter a 4-letter code from the host."
		else:
			home_lobby_status_label.text = "Host locally or use a 4-letter online code."
		if lobby_panel_status_label != null:
			lobby_panel_status_label.text = home_lobby_status_label.text
	if home_audio_toggle != null:
		home_audio_toggle.set_pressed_no_signal(audio_enabled)
	if home_music_toggle != null:
		home_music_toggle.set_pressed_no_signal(music_enabled)
	if sfx_volume_slider != null:
		sfx_volume_slider.set_value_no_signal(sfx_volume)
	if home_motion_toggle != null:
		home_motion_toggle.set_pressed_no_signal(motion_enabled)
	if home_noise_slider != null:
		home_noise_slider.set_value_no_signal(home_noise_amount)
	if table_noise_slider != null:
		table_noise_slider.set_value_no_signal(table_noise_amount)
	if action_animation_speed_slider != null:
		action_animation_speed_slider.set_value_no_signal(action_animation_speed)
	if background_music_slider != null:
		background_music_slider.set_value_no_signal(background_music_volume)
	if end_turn_cooldown_slider != null:
		end_turn_cooldown_slider.set_value_no_signal(game_state.end_turn_cooldown_seconds)
		end_turn_cooldown_slider.editable = _can_edit_table_settings()
		end_turn_cooldown_slider.modulate = Color(
			1,
			1,
			1,
			1.0 if _can_edit_table_settings() else 0.4
		)
	if fullscreen_toggle != null:
		fullscreen_toggle.set_pressed_no_signal(
			DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	_refresh_lobby_panel()


func _show_home_tab(tab_name: String) -> void:
	if home_settings_panel != null:
		home_settings_panel.visible = tab_name == "settings"
	if home_kingdoms_panel != null:
		home_kingdoms_panel.visible = tab_name == "kingdoms"
	if home_multiplayer_panel != null:
		home_multiplayer_panel.visible = tab_name == "multiplayer"
	if home_lobby_panel != null:
		home_lobby_panel.visible = tab_name == "lobby"
	_set_menu_overlay_active(true)
	if tab_name == "kingdoms":
		_refresh_kingdom_tab()
	elif tab_name == "lobby":
		_refresh_lobby_panel()
		if (
			lobby_pending_mode == "join_online"
			and not network_enabled
			and home_lobby_address_input != null
		):
			# Joining is all about the code: put the caret right in the box.
			home_lobby_address_input.grab_focus()


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
	tab_button.clip_text = true
	tab_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tab_button.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	tab_button.add_theme_color_override("font_pressed_color", Color("#3a2410"))
	tab_button.add_theme_font_size_override("font_size", 12)
	if title_font != null:
		tab_button.add_theme_font_override("font", title_font)
	tab_button.add_theme_stylebox_override(
		"normal",
		_make_parchment_button_style(kingdom == selected_home_kingdom)
	)
	tab_button.add_theme_stylebox_override(
		"hover",
		_make_parchment_button_style(kingdom == selected_home_kingdom, true)
	)
	tab_button.add_theme_stylebox_override(
		"pressed",
		_make_parchment_button_style(true)
	)
	tab_button.pressed.connect(_on_kingdom_tab_pressed.bind(kingdom))
	section.add_child(tab_button)

	var kingdom_toggle := CheckButton.new()
	kingdom_toggle.name = "KingdomToggle"
	kingdom_toggle.text = "BASE" if kingdom == GameState.BASE_KINGDOM else "IN POOL"
	kingdom_toggle.button_pressed = game_state.is_kingdom_enabled(kingdom)
	kingdom_toggle.disabled = kingdom == GameState.BASE_KINGDOM or not _can_edit_lobby_setup()
	kingdom_toggle.toggled.connect(_on_kingdom_toggled.bind(kingdom))
	_style_home_toggle(kingdom_toggle)
	kingdom_toggle.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
	section.add_child(kingdom_toggle)
	return section


func _refresh_kingdom_cards() -> void:
	_clear_container(home_kingdom_card_grid)
	var cards := game_state.get_cards_for_kingdom(selected_home_kingdom)
	home_kingdom_title_label.text = selected_home_kingdom
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
	return "%d cards - %d / %d enabled for random markets" % [cards.size(), active_count, market_count]


func _create_kingdom_card_button(card: CardDefinition) -> Button:
	var type_palette := _get_card_type_palette(card.card_type)
	var button := Button.new()
	button.name = "Card_%s" % card.id
	button.custom_minimum_size = Vector2(104, 136)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("card_id", card.id)
	button.set_meta("card_type", card.card_type)
	button.set_meta("card_base_color", _get_card_surface_color(card.card_type))
	button.set_meta("card_accent_color", type_palette.accent)
	button.tooltip_text = "%s - %s" % [card.card_name, card.description]
	var kingdom_enabled := game_state.is_kingdom_enabled(game_state.get_card_kingdom(card))
	var card_enabled := game_state.is_card_enabled_for_market(card.id)
	var can_toggle := (
		_can_edit_lobby_setup()
		and
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
	var border_color: Color = type_palette.accent
	if selected_home_kingdom_card_id == card.id:
		border_color = COLOR_BRASS.lightened(0.18)
	button.add_theme_stylebox_override(
		"normal",
		_make_flat_card_style(Color("#241813"), border_color, 1)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_flat_card_style(_get_card_surface_color(card.card_type), type_palette.hover_border, 2)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_flat_card_style(_get_card_surface_color(card.card_type).darkened(0.08), type_palette.accent, 2)
	)

	var content := Control.new()
	content.name = "TileContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.clip_contents = true
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var art := TextureRect.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _load_card_texture(card.art_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	content.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scrim := ColorRect.new()
	scrim.name = "TileScrim"
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.color = Color(0, 0, 0, 0.36)
	content.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var accent := ColorRect.new()
	accent.name = "AccentLine"
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.color = type_palette.accent
	accent.anchor_left = 0.0
	accent.anchor_top = 1.0
	accent.anchor_right = 1.0
	accent.anchor_bottom = 1.0
	accent.offset_top = -3
	content.add_child(accent)

	var cost := _create_price_badge(game_state.get_effective_cost(card))
	cost.scale = Vector2(0.78, 0.78)
	content.add_child(cost)

	var status := Label.new()
	status.name = "Status"
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if game_state.is_required_card(card.id):
		status.text = "LOCK"
	elif card_enabled:
		status.text = "OK"
	else:
		status.text = "OFF"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var status_color := Color("#d8f0c8") if card_enabled else Color(0.85, 0.78, 0.64, 0.7)
	status.add_theme_color_override("font_color", status_color)
	status.add_theme_font_size_override("font_size", 8)
	if title_font != null:
		status.add_theme_font_override("font", title_font)
	status.anchor_left = 0.0
	status.anchor_top = 0.0
	status.anchor_right = 1.0
	status.anchor_bottom = 0.0
	status.offset_left = 4
	status.offset_top = 7
	status.offset_right = -6
	status.offset_bottom = 19
	content.add_child(status)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", type_palette.name_text)
	name_label.add_theme_font_size_override("font_size", 9)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	name_label.anchor_left = 0.0
	name_label.anchor_top = 1.0
	name_label.anchor_right = 1.0
	name_label.anchor_bottom = 1.0
	name_label.offset_left = 5
	name_label.offset_top = -34
	name_label.offset_right = -5
	name_label.offset_bottom = -7
	content.add_child(name_label)
	button.mouse_entered.connect(_on_kingdom_card_hovered.bind(card.id))
	if can_toggle:
		button.toggled.connect(_on_kingdom_card_toggled.bind(card.id))
	else:
		button.pressed.connect(_on_kingdom_card_selected.bind(card.id))
	return button


func _refresh_kingdom_detail() -> void:
	_clear_container(home_kingdom_detail_host)
	if selected_home_kingdom_card_id.is_empty():
		return
	if not game_state.card_catalog.has(selected_home_kingdom_card_id):
		return
	var card: CardDefinition = game_state.card_catalog[selected_home_kingdom_card_id]

	# Show the very same large card preview the player sees when hovering a card
	# on the game board.
	var preview_view := _build_card_preview_view(card)
	preview_view.name = "DetailCard_%s" % card.id
	preview_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_kingdom_detail_host.add_child(preview_view)

	var card_toggle := CheckButton.new()
	card_toggle.name = "DetailCardToggle"
	card_toggle.text = "IN MARKET"
	var kingdom_enabled := game_state.is_kingdom_enabled(game_state.get_card_kingdom(card))
	card_toggle.button_pressed = kingdom_enabled and game_state.is_card_enabled_for_market(card.id)
	card_toggle.disabled = (
		not kingdom_enabled
		or not _can_edit_lobby_setup()
		or game_state.is_required_card(card.id)
		or not card.market_enabled
		or GameState.STARTING_CARD_COUNTS.has(card.id)
	)
	_style_home_toggle(card_toggle)
	card_toggle.add_theme_color_override("font_color", COLOR_PARCHMENT_BODY)
	card_toggle.toggled.connect(_on_kingdom_card_toggled.bind(card.id))
	home_kingdom_detail_host.add_child(card_toggle)


func _build_legacy_card_preview_view(card: CardDefinition) -> PanelContainer:
	# Recreates the in-game hover preview (CardPreview in Main.tscn) as a
	# self-contained panel so menus can show the identical large card view.
	var type_palette := _get_card_type_palette(card.card_type)
	var surface := _get_card_surface_color(card.card_type)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_preview_style(surface, type_palette.accent))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 13)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	var name_label := Label.new()
	name_label.name = "PreviewName"
	name_label.text = card.card_name
	name_label.custom_minimum_size = Vector2(0, 36)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", type_palette.name_text)
	name_label.add_theme_font_size_override("font_size", 21)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	layout.add_child(name_label)

	var meta_label := Label.new()
	meta_label.name = "PreviewMeta"
	meta_label.text = (
		"%s · COST %d COINS · %s"
		% [
			card.card_type.to_upper(),
			game_state.get_effective_cost(card),
			_get_card_meta_chip_text(card).to_upper()
		]
	)
	if not card.card_group.is_empty():
		meta_label.text += " · %s" % card.card_group.to_upper()
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_color_override("font_color", type_palette.chip_text)
	meta_label.add_theme_font_size_override("font_size", 11)
	if body_bold_font != null:
		meta_label.add_theme_font_override("font", body_bold_font)
	layout.add_child(meta_label)

	var art_frame := PanelContainer.new()
	art_frame.name = "PreviewArtFrame"
	art_frame.clip_contents = true
	art_frame.custom_minimum_size = Vector2(0, PREVIEW_ART_HEIGHT)
	art_frame.add_theme_stylebox_override(
		"panel",
		_make_card_art_style(surface.darkened(0.14))
	)
	layout.add_child(art_frame)

	var art := TextureRect.new()
	art.name = "PreviewArt"
	art.texture = _load_card_texture(card.art_id)
	art.modulate = Color(1, 1, 1, CARD_ART_OPACITY)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_frame.add_child(art)
	art_frame.visible = art.texture != null

	var effect_label := RichTextLabel.new()
	effect_label.name = "PreviewEffect"
	effect_label.bbcode_enabled = true
	effect_label.fit_content = false
	effect_label.scroll_active = false
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_label.custom_minimum_size = Vector2(0, 120)
	effect_label.text = _get_card_rules_text(card.description)
	effect_label.add_theme_color_override("default_color", type_palette.description_text)
	effect_label.add_theme_font_size_override("normal_font_size", 13)
	effect_label.add_theme_font_size_override("bold_font_size", 13)
	if body_font != null:
		effect_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		effect_label.add_theme_font_override("bold_font", body_bold_font)
	layout.add_child(effect_label)

	return panel


func _build_card_preview_view(card: CardDefinition) -> PanelContainer:
	var type_palette := _get_card_type_palette(card.card_type)
	var surface := _get_card_surface_color(card.card_type)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PREVIEW_SIZE
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _make_preview_style(surface, type_palette.accent))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	var art_frame := PanelContainer.new()
	art_frame.name = "PreviewArtFrame"
	art_frame.clip_contents = true
	art_frame.custom_minimum_size = Vector2(0, PREVIEW_ART_HEIGHT)
	art_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_frame.add_theme_stylebox_override(
		"panel",
		_make_card_art_style(surface.darkened(0.14))
	)
	layout.add_child(art_frame)

	var art := TextureRect.new()
	art.name = "PreviewArt"
	art.texture = _load_card_texture(card.art_id)
	art.modulate = Color(1, 1, 1, CARD_ART_OPACITY)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_frame.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_frame.visible = art.texture != null

	var name_label := Label.new()
	name_label.name = "PreviewName"
	name_label.text = card.card_name
	name_label.custom_minimum_size = Vector2(0, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", type_palette.name_text)
	name_label.add_theme_font_size_override("font_size", 17)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	layout.add_child(name_label)

	var effect_label := RichTextLabel.new()
	effect_label.name = "PreviewEffect"
	effect_label.bbcode_enabled = true
	effect_label.fit_content = false
	effect_label.scroll_active = false
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_label.custom_minimum_size = Vector2(0, 0)
	effect_label.text = _get_card_rules_text(card.description)
	effect_label.add_theme_color_override("default_color", type_palette.description_text)
	var effect_font_size := _get_preview_effect_font_size(card.description)
	effect_label.add_theme_font_size_override("normal_font_size", effect_font_size)
	effect_label.add_theme_font_size_override("bold_font_size", effect_font_size)
	if body_font != null:
		effect_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		effect_label.add_theme_font_override("bold_font", body_bold_font)
	layout.add_child(effect_label)

	var meta_label := Label.new()
	meta_label.name = "PreviewMeta"
	meta_label.custom_minimum_size = Vector2(0, 18)
	meta_label.text = (
		"%s / COST %d / %s"
		% [
			card.card_type.to_upper(),
			game_state.get_effective_cost(card),
			_get_card_meta_chip_text(card).to_upper()
		]
	)
	if not card.card_group.is_empty():
		meta_label.text += " / %s" % card.card_group.to_upper()
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.clip_text = true
	meta_label.add_theme_color_override("font_color", type_palette.chip_text)
	meta_label.add_theme_font_size_override("font_size", 9)
	if body_bold_font != null:
		meta_label.add_theme_font_override("font", body_bold_font)
	layout.add_child(meta_label)

	return panel


func _node_key(value: String) -> String:
	var key := value.replace(" ", "")
	key = key.replace("'", "")
	key = key.replace("-", "")
	key = key.replace("/", "")
	return key


func _build_market_board() -> void:
	market_panel.custom_minimum_size = Vector2(0, 364)
	market_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var market_margin := market_panel.get_node("MarketMargin") as MarginContainer
	market_margin.add_theme_constant_override("margin_left", 10)
	market_margin.add_theme_constant_override("margin_top", 2)
	market_margin.add_theme_constant_override("margin_right", 10)
	market_margin.add_theme_constant_override("margin_bottom", 4)
	var market_scroll := market_container.get_parent() as ScrollContainer
	var market_layout := VBoxContainer.new()
	market_layout.name = "MarketLayout"
	market_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_layout.add_theme_constant_override("separation", 0)
	market_margin.add_child(market_layout)
	market_scroll.reparent(market_layout)
	market_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	market_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	market_container.add_theme_constant_override("separation", 16)
	market_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var treasury := _create_market_carpet(
		"TreasuryCarpet",
		1,
		CARD_FACE_SIZE.x + 4,
		COLOR_TREASURY_CARPET,
		COLOR_BRASS
	)
	treasury_carpet = treasury.panel
	market_resource_container = treasury.cards

	var barracks := _create_market_carpet(
		"BarracksCarpet",
		5,
		CARD_FACE_SIZE.x * 5.0 + 12.0 * 4.0 + 4.0,
		COLOR_BARRACKS_CARPET,
		COLOR_ACTION_ACCENT
	)
	barracks_carpet = barracks.panel
	barracks_carpet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_action_container = barracks.cards

	var estates := _create_market_carpet(
		"EstatesCarpet",
		1,
		CARD_FACE_SIZE.x + 4,
		COLOR_ESTATES_CARPET,
		COLOR_VICTORY_ACCENT
	)
	estates_carpet = estates.panel
	market_victory_container = estates.cards
	briar_hex_tab = _create_briar_hex_tab()
	# This must not be a child of the Estates PanelContainer: containers own their
	# children's layout, which would stretch the tab into a normal market pile.
	# A root-level overlay lets it remain a compact horizontal tab below Estates.
	add_child(briar_hex_tab)
	estates_carpet.resized.connect(_position_briar_hex_tab)
	resized.connect(_position_briar_hex_tab)
	call_deferred("_position_briar_hex_tab")

	market_container.add_child(treasury_carpet)
	market_container.add_child(_create_market_separator())
	market_container.add_child(barracks_carpet)
	market_container.add_child(_create_market_separator())
	market_container.add_child(estates_carpet)

func _create_market_separator() -> ColorRect:
	var separator := ColorRect.new()
	separator.name = "MarketSeparator"
	separator.custom_minimum_size = Vector2(1, 0)
	separator.size_flags_vertical = Control.SIZE_EXPAND_FILL
	separator.color = Color(0.835, 0.667, 0.314, 0.22)
	return separator


func _create_market_carpet(
	carpet_name: String,
	columns: int,
	minimum_width: float,
	surface_color: Color,
	accent_color: Color
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = carpet_name
	panel.custom_minimum_size = Vector2(minimum_width, 352)
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

	var layout := VBoxContainer.new()
	layout.name = "ZoneLayout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var label := Label.new()
	label.name = "ZoneLabel"
	label.text = (
		"TREASURY"
		if carpet_name == "TreasuryCarpet"
		else "ESTATES" if carpet_name == "EstatesCarpet" else "BARRACKS"
	)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", accent_color)
	label.add_theme_font_size_override("font_size", 9)
	if title_font != null:
		label.add_theme_font_override("font", title_font)
	layout.add_child(label)

	var cards := GridContainer.new()
	cards.name = "Cards"
	cards.columns = columns
	# Fixed-size cards: the grid hugs its content and centres in the zone so
	# faces keep their exact size and ratio rather than stretching to fill.
	cards.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 8)
	layout.add_child(cards)

	return {"panel": panel, "cards": cards}


func _create_briar_hex_tab() -> Button:
	# Curses live beside the victory supply rather than occupying a normal market
	# pile.  Keeping this as a compact tab makes it available as a gain source
	# without implying that it may be bought.
	var tab := Button.new()
	tab.name = "BriarHexSupplyTab"
	tab.custom_minimum_size = Vector2(CARD_FACE_SIZE.x, 34)
	tab.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tab.mouse_default_cursor_shape = Control.CURSOR_ARROW
	tab.tooltip_text = "Briar Hex supply — right-click to preview"
	tab.add_theme_color_override("font_color", COLOR_CURSE_ACCENT.lightened(0.26))
	tab.add_theme_font_size_override("font_size", 9)
	if title_font != null:
		tab.add_theme_font_override("font", title_font)
	tab.add_theme_stylebox_override("normal", _make_panel_style(COLOR_CURSE_CARD.darkened(0.08), COLOR_CURSE_ACCENT.darkened(0.1), 1))
	tab.add_theme_stylebox_override("hover", _make_panel_style(COLOR_CURSE_CARD.lightened(0.08), COLOR_CURSE_ACCENT.lightened(0.12), 1))
	if game_state.card_catalog.has(GameState.CURSE_CARD_ID):
		var hex := game_state.card_catalog[GameState.CURSE_CARD_ID] as CardDefinition
		tab.set_meta("card_id", hex.id)
		tab.gui_input.connect(_on_card_gui_input.bind(hex, tab, MARKET_NEUTRAL))
	tab.pressed.connect(_on_briar_hex_tab_pressed)
	return tab


func _refresh_briar_hex_tab() -> void:
	if briar_hex_tab == null:
		return
	var count := game_state.get_supply_count(GameState.CURSE_CARD_ID)
	briar_hex_tab.text = "BRIAR HEXES   %d" % count
	var selecting_gain := not _direct_supply_gain_token_for(GameState.CURSE_CARD_ID).is_empty()
	# Keep GUI input enabled even at zero so the right-click card preview remains
	# available. Left-click safety lives in the pressed handler below.
	briar_hex_tab.disabled = false
	briar_hex_tab.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if selecting_gain and count > 0 else Control.CURSOR_ARROW
	)
	briar_hex_tab.modulate = Color.WHITE if (not direct_supply_gain_choice or selecting_gain) else Color(0.55, 0.55, 0.55, 0.7)
	_position_briar_hex_tab()


func _on_briar_hex_tab_pressed() -> void:
	if game_state.get_supply_count(GameState.CURSE_CARD_ID) <= 0:
		return
	_on_direct_supply_gain_pressed(_direct_supply_gain_token_for(GameState.CURSE_CARD_ID))


func _position_briar_hex_tab() -> void:
	if briar_hex_tab == null or estates_carpet == null:
		return
	var tab_size := Vector2(CARD_FACE_SIZE.x, 28)
	briar_hex_tab.size = tab_size
	var estates_rect := estates_carpet.get_global_rect()
	briar_hex_tab.global_position = Vector2(
		estates_rect.get_center().x - tab_size.x * 0.5,
		estates_rect.end.y - tab_size.y - 3.0
	)


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
			"Margin/Layout/TopBar/Margin/Row/BrandRow/Star",
			"Margin/Layout/TopBar/Margin/Row/BrandRow/Title",
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

	_apply_original_ui_assets()
	_apply_scene_colors()
	_configure_preview_layout()

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
		_make_panel_style(Color("#1d140c"), Color(0.835, 0.667, 0.314, 0.32), 1)
	)
	right_ledger.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color("#1d140c"), Color(0.835, 0.667, 0.314, 0.32), 1)
	)
	for market_zone in [treasury_carpet, barracks_carpet, estates_carpet]:
		market_zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	hand_panel.add_theme_stylebox_override(
		"panel",
		StyleBoxEmpty.new()
	)
	play_area_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.09, 0.058, 0.035, 0.52), Color(0.835, 0.667, 0.314, 0.16), 1)
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
	if ui_textures.has("button_primary"):
		_apply_button_asset_styles(play_again_button, ui_textures["button_primary"])
		_apply_button_asset_styles(end_game_home_button, ui_textures["button_primary"])
	end_turn_button.add_theme_stylebox_override("normal", _make_end_turn_style())
	end_turn_button.add_theme_stylebox_override("hover", _make_end_turn_style(true))
	end_turn_button.add_theme_stylebox_override("pressed", _make_end_turn_style())
	end_turn_button.add_theme_stylebox_override("disabled", _make_end_turn_style(false, true))
	end_turn_button.add_theme_color_override("font_color", Color("#3a2410"))
	end_turn_button.add_theme_color_override("font_hover_color", Color("#241405"))
	end_turn_button.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.64, 0.78))
	end_turn_button.add_theme_font_size_override("font_size", 14)
	if title_font != null:
		end_turn_button.add_theme_font_override("font", title_font)
	if home_button != null:
		home_button.add_theme_stylebox_override("normal", _make_top_button_style(true))
		home_button.add_theme_stylebox_override("hover", _make_top_button_style(true, true))
		home_button.add_theme_stylebox_override("pressed", _make_top_button_style(true))


func _apply_scene_colors() -> void:
	var table_background := get_node_or_null("Background") as TextureRect
	if table_background != null:
		table_background.modulate = Color("#241813")
	var table_vignette := get_node_or_null("TableVignette") as ColorRect
	if table_vignette != null:
		table_vignette.color = Color(0.047, 0.031, 0.024, 0.56)

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


func _configure_preview_layout() -> void:
	card_preview.custom_minimum_size = PREVIEW_SIZE
	card_preview.size = PREVIEW_SIZE
	card_preview.clip_contents = true
	var preview_margin := card_preview.get_node("Margin") as MarginContainer
	preview_margin.add_theme_constant_override("margin_left", 7)
	preview_margin.add_theme_constant_override("margin_top", 7)
	preview_margin.add_theme_constant_override("margin_right", 7)
	preview_margin.add_theme_constant_override("margin_bottom", 7)
	var layout := preview_margin.get_node("Layout") as VBoxContainer
	layout.add_theme_constant_override("separation", 4)
	layout.move_child(preview_art_frame, 0)
	layout.move_child(preview_name_label, 1)
	layout.move_child(preview_effect_label, 2)
	layout.move_child(preview_meta_label, 3)
	preview_name_label.custom_minimum_size = Vector2(0, 30)
	preview_name_label.add_theme_font_size_override("font_size", 17)
	preview_meta_label.custom_minimum_size = Vector2(0, 18)
	preview_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_meta_label.clip_text = true
	preview_meta_label.add_theme_font_size_override("font_size", 9)
	preview_art_frame.custom_minimum_size = Vector2(0, PREVIEW_ART_HEIGHT)
	preview_art_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	preview_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_effect_label.custom_minimum_size = Vector2(0, 0)
	preview_effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_effect_label.add_theme_font_size_override("normal_font_size", 13)
	preview_effect_label.add_theme_font_size_override("bold_font_size", 13)
	preview_effect_label.scroll_active = false


func _get_preview_effect_font_size(description: String) -> int:
	if description.length() > 150:
		return 12
	if description.length() > 110:
		return 13
	return 14


func _apply_body_font_recursive(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if not label.has_theme_font_override("font"):
			label.add_theme_font_override("font", body_font)
	elif node is Button:
		var button := node as Button
		if not button.has_theme_font_override("font"):
			button.add_theme_font_override("font", body_font)
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
	_hide_all_previews()
	var player := game_state.player
	turn_label.text = (
		"%s  T%d" % [game_state.get_active_player_name(), player.turn_number]
		if game_state.multiplayer_enabled
		else "Turn %d" % player.turn_number
	)
	deck_label.text = str(player.draw_pile.size())
	discard_label.text = str(player.discard_pile.size())
	if trash_pile_button != null:
		trash_pile_button.text = "TRASH\n%d" % player.trash_pile.size()
	coin_label.text = str(player.coins)
	action_label.text = str(player.actions)
	buy_label.text = str(player.buys)
	hand_count_label.text = "%d card%s" % [
		player.hand.size(),
		"" if player.hand.size() == 1 else "s",
	]
	_refresh_discard_pile_art()
	_refresh_end_turn_button()
	_refresh_player_status()
	home_button.disabled = false

	_refresh_hand()
	_refresh_market()
	_refresh_play_area()
	_refresh_relics_rail()
	_refresh_relic_overlay()


func _refresh_player_status() -> void:
	if player_status_list == null:
		return
	var you_index := (
		clampi(local_player_index, 0, game_state.players.size() - 1)
		if network_enabled and not game_state.players.is_empty()
		else game_state.active_player_index
	)
	# Rows update in place every frame (for cooldown bars); they are only
	# rebuilt when the player count changes, not 60 times a second.
	if player_status_list.get_child_count() != game_state.players.size():
		_clear_container(player_status_list)
		player_status_rows.clear()
		for index in range(game_state.players.size()):
			player_status_list.add_child(_create_player_status_row(index))
		var panel := player_status_list.get_parent().get_parent().get_parent() as PanelContainer
		var header := panel.find_child("Header", true, false) as Label if panel != null else null
		if header != null:
			header.text = "TABLE - %d PLAYERS" % maxi(1, game_state.players.size())
	for index in range(game_state.players.size()):
		_update_player_status_row(index, game_state.players[index], you_index)


func _refresh_discard_pile_art() -> void:
	if discard_pile_art == null:
		return
	var discard := game_state.player.discard_pile
	if discard.is_empty():
		discard_pile_art.texture = null
		if discard_pile_scrim != null:
			discard_pile_scrim.color = Color(0, 0, 0, 0.72)
		return
	var top_card: CardDefinition = discard[discard.size() - 1]
	discard_pile_art.texture = _load_card_texture(top_card.art_id)
	if discard_pile_scrim != null:
		discard_pile_scrim.color = Color(0, 0, 0, 0.48)


func _create_player_status_row(index: int) -> PanelContainer:
	var row_panel := PanelContainer.new()
	row_panel.name = "PlayerRow%d" % (index + 1)
	row_panel.custom_minimum_size = Vector2(0, PLAYER_STATUS_ROW_HEIGHT)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.add_theme_stylebox_override("panel", _make_player_row_style(false))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 5)
	row_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	margin.add_child(stack)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	stack.add_child(top)

	var dot := PanelContainer.new()
	dot.name = "StatusDot"
	dot.custom_minimum_size = Vector2(9, 9)
	dot.add_theme_stylebox_override("panel", _make_dot_style(COLOR_BRASS))
	top.add_child(dot)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	name_label.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	top.add_child(name_label)

	var turn_badge := PanelContainer.new()
	turn_badge.name = "TurnBadge"
	turn_badge.custom_minimum_size = Vector2(54, 18)
	turn_badge.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color(0, 0, 0, 0.08), Color(0.835, 0.667, 0.314, 0.44), 5)
	)
	top.add_child(turn_badge)
	var turn_text := Label.new()
	turn_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_text.add_theme_color_override("font_color", COLOR_BRASS)
	turn_text.add_theme_font_size_override("font_size", 8)
	if title_font != null:
		turn_text.add_theme_font_override("font", title_font)
	turn_badge.add_child(turn_text)

	var status_label := Label.new()
	status_label.name = "Status"
	status_label.add_theme_color_override("font_color", COLOR_BRASS)
	status_label.add_theme_font_size_override("font_size", 9)
	if body_font != null:
		status_label.add_theme_font_override("font", body_font)
	stack.add_child(status_label)

	var track := PanelContainer.new()
	track.name = "CooldownBar"
	track.custom_minimum_size = Vector2(0, PLAYER_STATUS_COOLDOWN_BAR_HEIGHT)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color(0, 0, 0, 0.28), Color.TRANSPARENT, 3)
	)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = COLOR_VICTORY_ACCENT
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_right = 0.0
	fill.anchor_bottom = 1.0
	track.add_child(fill)
	track.modulate.a = 0.0
	stack.add_child(track)

	player_status_rows[index] = {
		"row": row_panel,
		"dot": dot,
		"name": name_label,
		"turn": turn_text,
		"status": status_label,
		"bar": track,
		"fill": fill,
	}
	return row_panel


func _is_seat_connected(index: int) -> bool:
	if not network_enabled:
		return true
	if network_is_host:
		return _connected_seat_indexes().has(index)
	if network_connected_seats.is_empty():
		return true
	return network_connected_seats.has(index)


func _update_player_status_row(index: int, game_player: PlayerState, you_index: int) -> void:
	var refs: Dictionary = player_status_rows.get(index, {})
	if refs.is_empty():
		return
	var is_active := index == game_state.active_player_index
	var is_local := index == you_index
	var connected := is_local or _is_seat_connected(index)
	var status_color := COLOR_BRASS
	var status_text := "Waiting"
	if not connected:
		status_color = COLOR_UNAVAILABLE
		status_text = "Disconnected"
	elif not game_player.pending_relic_offer.is_empty():
		status_color = COLOR_CURSE_ACCENT
		status_text = "Choosing relic"
	elif game_player.pending_choice != null:
		status_color = COLOR_ACTION_ACCENT
		status_text = "Choosing"
	elif game_player.cooldown_remaining > 0.0:
		status_color = COLOR_VICTORY_ACCENT
		status_text = "Cooldown %.1fs" % game_player.cooldown_remaining
	elif is_active:
		status_color = COLOR_RESOURCE_ACCENT
		status_text = "Your turn" if is_local else "Buying"
	elif game_player.ending_turn:
		status_color = COLOR_PARCHMENT.darkened(0.25)
		status_text = "Ended"

	if _respite_active() and connected:
		if _is_respite_ready(index):
			status_color = COLOR_VICTORY_ACCENT
			status_text = "Ready"
		else:
			status_color = COLOR_BRASS
			status_text = "Not ready"

	var row: PanelContainer = refs["row"]
	if bool(row.get_meta("row_active", false)) != is_active:
		row.set_meta("row_active", is_active)
		row.add_theme_stylebox_override("panel", _make_player_row_style(is_active))

	var dot: PanelContainer = refs["dot"]
	if dot.get_meta("dot_color", Color.TRANSPARENT) != status_color:
		dot.set_meta("dot_color", status_color)
		dot.add_theme_stylebox_override("panel", _make_dot_style(status_color))

	var name_text := _display_name_for(index)
	if network_enabled and index == 0:
		name_text += " (host)"
	if network_enabled and is_local:
		name_text += " (you)"
	var name_label: Label = refs["name"]
	if name_label.text != name_text:
		name_label.text = name_text

	var turn_text_value := "TURN %d" % game_player.turn_number
	var turn_label: Label = refs["turn"]
	if turn_label.text != turn_text_value:
		turn_label.text = turn_text_value

	var status_label: Label = refs["status"]
	if status_label.text != status_text:
		status_label.text = status_text
	if status_label.get_meta("status_color", Color.TRANSPARENT) != status_color:
		status_label.set_meta("status_color", status_color)
		status_label.add_theme_color_override("font_color", status_color)

	var bar: Control = refs["bar"]
	var fill: ColorRect = refs["fill"]
	var duration := maxf(0.001, game_player.cooldown_duration)
	fill.anchor_right = clampf(game_player.cooldown_remaining / duration, 0.0, 1.0)
	fill.color = status_color
	bar.modulate.a = 1.0 if game_player.cooldown_remaining > 0.0 else 0.0


func _refresh_end_turn_button() -> void:
	if end_turn_button == null:
		return
	if turn_manager.game_over:
		end_turn_button.text = "GAME OVER"
		end_turn_button.disabled = true
		end_turn_button.modulate = Color.WHITE
		return
	if _respite_active():
		var local_ready := _is_respite_ready(_local_respite_seat())
		if local_ready:
			end_turn_button.text = "WAITING %s" % _format_respite_clock()
			end_turn_button.disabled = true
			end_turn_button.modulate = Color(0.72, 0.74, 0.78, 1.0)
		else:
			end_turn_button.text = "READY %s" % _format_respite_clock()
			end_turn_button.disabled = false
			end_turn_button.modulate = Color.WHITE
		return
	if turn_manager.is_cooling_down():
		end_turn_button.text = "COOLDOWN %.1fs" % turn_manager.cooldown_remaining
		end_turn_button.disabled = true
		end_turn_button.modulate = Color(0.72, 0.74, 0.78, 1.0)
		return
	if direct_hand_choice and _choice_is_hand_trash(current_choice) and current_choice != null:
		end_turn_button.text = "CONFIRM"
		end_turn_button.disabled = (
			not _can_control_active_player()
			or not current_choice.is_valid_selection(selected_choice_tokens)
		)
		end_turn_button.modulate = Color.WHITE
		return
	end_turn_button.text = "END TURN"
	end_turn_button.disabled = game_state.has_pending_choice() or not _can_control_active_player()
	end_turn_button.modulate = Color.WHITE


func _refresh_hand() -> void:
	var previous_layout := _capture_hand_layout()
	_clear_container(hand_container)
	var hand_size := game_state.player.hand.size()
	var choice_occurrences: Dictionary = {}
	for index in range(hand_size):
		var card: CardDefinition = game_state.player.hand[index]
		var occurrence := int(choice_occurrences.get(card.id, 0))
		choice_occurrences[card.id] = occurrence + 1
		var direct_token := _direct_hand_token_for(card.id, occurrence)
		var selecting_for_choice := not direct_token.is_empty()
		var playable := _can_play_card(card) or selecting_for_choice
		var visual_state := HAND_PLAYABLE if playable else HAND_UNPLAYABLE
		var button := _create_card_button(card, visual_state)
		button.disabled = not playable
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if playable else Control.CURSOR_ARROW
		)
		button.pressed.connect(_on_direct_hand_choice_pressed.bind(direct_token) if selecting_for_choice else _on_hand_card_pressed.bind(card))
		if selecting_for_choice:
			button.set_meta("direct_hand_trash", _choice_is_hand_trash(current_choice))
			button.set_meta("choice_selected", selected_choice_tokens.has(direct_token))
			button.modulate = Color(1.12, 1.06, 0.82, 1.0) if selected_choice_tokens.has(direct_token) else Color.WHITE
			_set_hand_trash_hover(button, _choice_is_hand_trash(current_choice), selected_choice_tokens.has(direct_token))
		hand_container.add_child(button)
	_assign_hand_flip_origins(previous_layout)
	_apply_hand_fan_offsets()


func _direct_hand_token_for(card_id: String, occurrence: int) -> String:
	if not direct_hand_choice:
		return ""
	var tokens: Array = direct_hand_tokens.get(card_id, [])
	return str(tokens[occurrence]) if occurrence < tokens.size() else ""


func _on_direct_hand_choice_pressed(token: String) -> void:
	if current_choice == null or token.is_empty():
		return
	_on_choice_card_pressed(token)
	_refresh_hand()


func _direct_supply_gain_token_for(card_id: String) -> String:
	if not direct_supply_gain_choice:
		return ""
	var tokens: Array = direct_supply_gain_tokens.get(card_id, [])
	for token in tokens:
		if not selected_choice_tokens.has(str(token)):
			return str(token)
	return ""


func _on_direct_supply_gain_pressed(token: String) -> void:
	if current_choice == null or token.is_empty():
		return
	_submit_choice([token])


func _capture_hand_layout() -> Array[Dictionary]:
	# Remember where each hand card sat (container-local) before a rebuild so
	# the surviving cards can glide to their new fan slots instead of snapping.
	var entries: Array[Dictionary] = []
	for child in hand_container.get_children():
		var control := child as Control
		if control == null or not control.has_meta("card_id"):
			continue
		entries.append({
			"card_id": str(control.get_meta("card_id")),
			"position": control.position,
			"rotation": control.rotation_degrees,
			"consumed": false,
		})
	return entries


func _assign_hand_flip_origins(previous_layout: Array[Dictionary]) -> void:
	if previous_layout.is_empty() or not motion_enabled:
		return
	for child in hand_container.get_children():
		var control := child as Control
		if control == null or not control.has_meta("card_id"):
			continue
		var card_id := str(control.get_meta("card_id"))
		for entry in previous_layout:
			if bool(entry["consumed"]) or str(entry["card_id"]) != card_id:
				continue
			entry["consumed"] = true
			control.set_meta("flip_position", entry["position"])
			control.set_meta("flip_rotation", entry["rotation"])
			break


func _hand_fan_angle_step(total: int) -> float:
	# Degrees between neighbouring cards. Fewer cards splay wider; a big hand
	# tightens the step so the fan never wraps too far.
	if total <= 1:
		return 0.0
	return clampf(70.0 / float(total), 6.0, 12.0)


func _apply_hand_fan_offsets() -> void:
	# Lay the hand out as a true fan: every card shares one pivot point well
	# below the row and is rotated around it, so the cards radiate from a common
	# base (like a hand of cards held at the bottom) instead of stepping up like
	# a podium. Runs on every hand-row layout so it survives re-sorts.
	var cards := hand_container.get_children()
	var total := cards.size()
	if total == 0:
		return
	var row_size := hand_container.size
	if row_size.x <= 0.0:
		row_size = Vector2(CARD_FACE_SIZE.x * float(total), CARD_FACE_SIZE.y)
	var center := float(total - 1) * 0.5
	var angle_step := _hand_fan_angle_step(total)
	var pivot := Vector2(row_size.x * 0.5, row_size.y + HAND_FAN_PIVOT_DROP)
	for index in range(total):
		var card := cards[index] as Control
		if card == null:
			continue
		var card_size := card.size
		if card_size == Vector2.ZERO:
			card_size = CARD_FACE_SIZE
		var radius := HAND_FAN_PIVOT_DROP + card_size.y * 0.5
		var arc_angle := deg_to_rad((float(index) - center) * angle_step)
		# The card centre rides an arc around the shared pivot (this is the fan
		# spread) while the card itself only tilts a fraction of that angle, so
		# the faces stay flatter / more upright than the spread would imply.
		var card_center := pivot + Vector2(sin(arc_angle), -cos(arc_angle)) * radius
		card.pivot_offset = card_size * 0.5
		_place_hand_card(
			card,
			card_center - card_size * 0.5,
			(float(index) - center) * angle_step * HAND_FAN_TILT
		)


func _place_hand_card(card: Control, target_position: Vector2, target_rotation: float) -> void:
	# Cards that survived a hand rebuild carry their previous slot as metadata;
	# glide them into the new fan position. Anything else snaps instantly so a
	# fresh layout never tweens in from (0, 0).
	var previous_tween: Tween = null
	if card.has_meta("hand_tween"):
		var stored_tween = card.get_meta("hand_tween")
		if stored_tween is Tween and (stored_tween as Tween).is_valid():
			previous_tween = stored_tween as Tween
	var from_flip := card.has_meta("flip_position")
	var start_position := card.position
	var start_rotation := card.rotation_degrees
	if from_flip:
		start_position = card.get_meta("flip_position")
		start_rotation = float(card.get_meta("flip_rotation", target_rotation))
		card.remove_meta("flip_position")
		card.remove_meta("flip_rotation")
	if previous_tween != null:
		previous_tween.kill()
	if not motion_enabled or (not from_flip and previous_tween == null):
		card.position = target_position
		card.rotation_degrees = target_rotation
		return
	if (
		start_position.distance_to(target_position) < 1.0
		and absf(start_rotation - target_rotation) < 0.25
	):
		card.position = target_position
		card.rotation_degrees = target_rotation
		return
	card.position = start_position
	card.rotation_degrees = start_rotation
	var duration := _action_animation_duration(CARD_MOVE_SECONDS)
	var tween := create_tween()
	tween.bind_node(card)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_position, duration)
	tween.tween_property(card, "rotation_degrees", target_rotation, duration)
	card.set_meta("hand_tween", tween)


func _refresh_market() -> void:
	_clear_container(market_resource_container)
	_clear_container(market_action_container)
	_clear_container(market_victory_container)

	var resource_cards: Array[CardDefinition] = []
	var action_cards: Array[CardDefinition] = []
	var victory_cards: Array[CardDefinition] = []
	for card in game_state.market:
		if GameState.MARKET_FIXED_RESOURCE_IDS.has(card.id):
			resource_cards.append(card)
		elif GameState.MARKET_FIXED_VICTORY_IDS.has(card.id):
			victory_cards.append(card)
		else:
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
	_refresh_briar_hex_tab()


func _render_market_cards(
	cards: Array[CardDefinition],
	container: GridContainer
) -> void:
	# Before any card is played this turn the player has no coins to judge
	# affordability by, so show the whole market fully saturated (neutral).
	# Once they start playing cards, switch to the affordable / unaffordable look.
	var no_cards_played := game_state.player.play_area.is_empty()
	for card in cards:
		var gain_token := _direct_supply_gain_token_for(card.id)
		var selecting_gain := not gain_token.is_empty()
		var affordable := _can_buy_card(card)
		var visual_state := MARKET_NEUTRAL
		if direct_supply_gain_choice:
			visual_state = MARKET_AFFORDABLE if selecting_gain else MARKET_UNAFFORDABLE
		elif not no_cards_played:
			visual_state = MARKET_AFFORDABLE if affordable else MARKET_UNAFFORDABLE
		var button := _create_card_button(card, visual_state)
		button.disabled = game_state.get_supply_count(card.id) <= 0 or (direct_supply_gain_choice and not selecting_gain)
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND
			if (selecting_gain or (not direct_supply_gain_choice and affordable))
			else Control.CURSOR_ARROW
		)
		button.pressed.connect(_on_direct_supply_gain_pressed.bind(gain_token) if selecting_gain else _on_market_card_pressed.bind(card))
		container.add_child(button)


func _should_showcase_market_before_play(card: CardDefinition) -> bool:
	return (
		_can_interact_with_local_player()
		and not turn_manager.game_over
		and not game_state.has_pending_choice()
		and game_state.player.play_area.is_empty()
		and game_state.player.buys > 0
		and game_state.get_supply_count(card.id) > 0
	)


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
		"(Gain|gain|Draw|draw) ([0-9]+) (extra |more )?(cards|card|actions|action|buys|buy|coins|coin)",
		false
	)
	return _replace_numeric_rule_phrase(
		formatted_text,
		"(, and |, | and )([0-9]+) (cards|card|actions|action|buys|buy|coins|coin)",
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
	var display_records := game_state.player.get_play_display_records()
	# Older saves / snapshots can lack transient records; preserve a useful
	# fallback rather than rendering an empty in-play strip.
	if display_records.is_empty() and not game_state.player.play_area.is_empty():
		for card in game_state.player.play_area:
			display_records.append({"card": card, "occurrence": 1, "total": 1})
	play_area_label.text = "IN PLAY\n%d" % display_records.size()

	var new_ids: Array[String] = []
	for record in display_records:
		var display_card := record.get("card") as CardDefinition
		if display_card != null:
			new_ids.append(display_card.id)
	var owner_id := game_state.player.get_instance_id()
	var pop_from := new_ids.size()
	if owner_id == last_play_area_owner and new_ids.size() > last_play_area_ids.size():
		# Only the chips that just arrived pop in; a view switch or rebuild of
		# the same cards stays still.
		pop_from = last_play_area_ids.size()
	last_play_area_ids = new_ids
	last_play_area_owner = owner_id

	if display_records.is_empty():
		var empty_label := Label.new()
		empty_label.custom_minimum_size = Vector2(0, PLAY_AREA_CONTENT_HEIGHT)
		empty_label.text = ""
		empty_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.28))
		empty_label.add_theme_font_size_override("font_size", 9)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		play_area_container.add_child(empty_label)
		return

	for index in range(display_records.size()):
		var record: Dictionary = display_records[index]
		var card := record.get("card") as CardDefinition
		if card == null:
			continue
		var chip := _create_played_card_chip(card, int(record.get("occurrence", 1)), int(record.get("total", 1)))
		play_area_container.add_child(chip)
		if index >= pop_from:
			_pop_in_control(chip)


func _pop_in_control(control: Control) -> void:
	if not motion_enabled:
		return
	control.scale = Vector2(0.55, 0.55)
	control.modulate.a = 0.2
	var duration := _action_animation_duration(0.16)
	var tween := create_tween()
	tween.bind_node(control)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration)


func _can_play_card(card: CardDefinition) -> bool:
	if (
		_respite_active()
		or not _can_interact_with_local_player()
		or turn_manager.game_over
		or game_state.has_pending_choice()
		or not card.is_playable()
	):
		return false
	if card.card_type == "action" and game_state.player.actions <= 0:
		return false
	return true


func _can_buy_card(card: CardDefinition) -> bool:
	return (
		not _respite_active()
		and _can_interact_with_local_player()
		and not turn_manager.game_over
		and not game_state.has_pending_choice()
		and game_state.player.buys > 0
		and game_state.player.coins >= game_state.get_effective_cost(card)
		and game_state.get_supply_count(card.id) > 0
	)


func _create_card_button(
	card: CardDefinition,
	visual_state: String
) -> Button:
	var type_palette := _get_card_type_palette(card.card_type)
	var card_surface := _get_card_surface_color(card.card_type)
	var is_market_card := visual_state.begins_with("market_")
	var is_hand_card := visual_state.begins_with("hand_")
	var is_unavailable := visual_state == MARKET_UNAFFORDABLE
	var is_disabled_face := visual_state == MARKET_UNAFFORDABLE or visual_state == HAND_UNPLAYABLE
	var is_affordable_face := (
		visual_state == MARKET_AFFORDABLE
		or visual_state == HAND_PLAYABLE
		or visual_state.begins_with("kingdom_")
	)
	var outline_width := 2
	var border_color: Color = type_palette.accent
	if is_disabled_face:
		border_color = Color(0, 0, 0, 0.45)
	var button := Button.new()
	# Every card on the table uses one fixed size and ratio so market, hand and
	# in-play faces match exactly. Market cards centre inside their grid column
	# instead of stretching to fill it.
	button.custom_minimum_size = CARD_FACE_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("card_id", card.id)
	button.set_meta("visual_state", visual_state)
	button.set_meta("card_base_color", card_surface)
	button.set_meta("card_type", card.card_type)
	button.set_meta("card_group", card.card_group)
	button.set_meta("card_accent_color", border_color)
	button.set_meta("supply_count", game_state.get_supply_count(card.id))
	if is_hand_card:
		button.set_meta("hand_fan", true)
	button.tooltip_text = "%s — %s" % [card.card_name, card.description]
	if visual_state.begins_with("market_"):
		button.tooltip_text += "\n%d cards remain in this pile." % game_state.get_supply_count(card.id)
	button.resized.connect(_update_card_pivot.bind(button))
	if not visual_state.begins_with("kingdom_"):
		button.mouse_entered.connect(
			_on_card_mouse_entered.bind(card, button, visual_state)
		)
		button.mouse_exited.connect(_on_card_mouse_exited.bind(button))
		button.gui_input.connect(_on_card_gui_input.bind(card, button, visual_state))
	button.add_theme_stylebox_override(
		"normal",
		_make_card_style(card_surface, border_color, outline_width, is_affordable_face)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_card_style(
			card_surface.lightened(0.08),
			type_palette.hover_border,
			outline_width,
			is_affordable_face
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_card_style(card_surface.darkened(0.06), type_palette.accent, outline_width, is_affordable_face)
	)
	button.add_theme_stylebox_override(
		"focus",
		_make_card_style(Color.TRANSPARENT, COLOR_BRASS.lightened(0.12), outline_width, true)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_card_style(card_surface.darkened(0.12), Color(0, 0, 0, 0.45), outline_width, false)
	)

	var content := MarginContainer.new()
	content.name = "CardContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", 0)
	content.add_theme_constant_override("margin_top", 0)
	content.add_theme_constant_override("margin_right", 0)
	content.add_theme_constant_override("margin_bottom", 0)
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := Control.new()
	layout.name = "CardLayout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.clip_contents = true
	layout.custom_minimum_size = CARD_FACE_SIZE
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var art_height := HAND_CARD_ART_HEIGHT if is_hand_card else CARD_ART_HEIGHT
	var text_scrim_y := art_height
	var name_y := text_scrim_y + 3.0
	var effect_y := name_y + CARD_NAME_HEIGHT + 2.0
	var meta_y := CARD_META_Y
	var effect_height := maxf(24.0, meta_y - effect_y - 1.0)
	var art_texture := _load_card_texture(card.art_id)
	var art_frame := Panel.new()
	art_frame.name = "ArtFrame"
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.clip_contents = true
	art_frame.custom_minimum_size = Vector2(CARD_FACE_SIZE.x, art_height)
	art_frame.size = Vector2(CARD_FACE_SIZE.x, art_height)
	# Art sits flush at the top of the card, so it only rounds its top corners;
	# the bottom edge is straight and meets the text panel below it.
	var art_style := _make_card_art_style(card_surface.darkened(0.16))
	art_style.corner_radius_bottom_left = 0
	art_style.corner_radius_bottom_right = 0
	art_frame.add_theme_stylebox_override("panel", art_style)
	layout.add_child(art_frame)
	art_frame.anchor_left = 0.0
	art_frame.anchor_top = 0.0
	art_frame.anchor_right = 1.0
	art_frame.anchor_bottom = 0.0
	art_frame.offset_left = 0.0
	art_frame.offset_top = 0.0
	art_frame.offset_right = 0.0
	art_frame.offset_bottom = art_height

	var art_rect := TextureRect.new()
	art_rect.name = "Art"
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_rect.texture = art_texture
	art_rect.modulate = Color(1, 1, 1, CARD_ART_OPACITY)
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if is_unavailable:
		art_rect.material = _get_desaturate_material()
	art_frame.add_child(art_rect)
	art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var art_scrim := ColorRect.new()
	art_scrim.name = "ArtScrim"
	art_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_scrim.color = type_palette.scrim
	art_frame.add_child(art_scrim)
	art_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The lower text band rounds its bottom corners to match the card's rounded
	# outline, so the face no longer reads as a square block poking past the frame.
	var text_scrim := Panel.new()
	text_scrim.name = "TextScrim"
	text_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scrim_style := _make_flat_card_style(
		Color(card_surface.r, card_surface.g, card_surface.b, 0.94),
		Color.TRANSPARENT,
		0
	)
	scrim_style.corner_radius_top_left = 0
	scrim_style.corner_radius_top_right = 0
	scrim_style.corner_radius_bottom_left = 13
	scrim_style.corner_radius_bottom_right = 13
	scrim_style.shadow_color = Color.TRANSPARENT
	scrim_style.shadow_size = 0
	text_scrim.add_theme_stylebox_override("panel", scrim_style)
	text_scrim.position = Vector2(0, text_scrim_y)
	text_scrim.size = Vector2(CARD_FACE_SIZE.x, CARD_FACE_SIZE.y - text_scrim_y)
	layout.add_child(text_scrim)

	var accent_line := ColorRect.new()
	accent_line.name = "AccentLine"
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_line.color = type_palette.accent
	accent_line.custom_minimum_size = Vector2(0, 2)
	art_frame.add_child(accent_line)
	accent_line.anchor_left = 0.0
	accent_line.anchor_top = 1.0
	accent_line.anchor_right = 1.0
	accent_line.anchor_bottom = 1.0
	accent_line.offset_left = 0
	accent_line.offset_top = -2
	accent_line.offset_right = 0
	accent_line.offset_bottom = 0

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(0, name_y)
	name_label.custom_minimum_size = Vector2(CARD_FACE_SIZE.x, CARD_NAME_HEIGHT)
	name_label.size = Vector2(CARD_FACE_SIZE.x, CARD_NAME_HEIGHT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", type_palette.name_text)
	name_label.add_theme_font_size_override("font_size", 11)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	layout.add_child(name_label)

	var effect_slot := MarginContainer.new()
	effect_slot.name = "EffectSlot"
	effect_slot.position = Vector2(0, effect_y)
	effect_slot.custom_minimum_size = Vector2(CARD_FACE_SIZE.x, effect_height)
	effect_slot.size = Vector2(CARD_FACE_SIZE.x, effect_height)
	effect_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_slot.add_theme_constant_override("margin_left", 7)
	effect_slot.add_theme_constant_override("margin_top", 0)
	effect_slot.add_theme_constant_override("margin_right", 7)
	effect_slot.add_theme_constant_override("margin_bottom", 1)
	layout.add_child(effect_slot)

	var effect_center := VBoxContainer.new()
	effect_center.name = "EffectCenter"
	effect_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_center.alignment = BoxContainer.ALIGNMENT_BEGIN
	effect_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_center.add_theme_constant_override("separation", 2)
	effect_slot.add_child(effect_center)

	var effect_label := RichTextLabel.new()
	effect_label.name = "EffectLabel"
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_label.bbcode_enabled = true
	var rules_text := _get_card_rules_text(card.description)
	effect_label.fit_content = false
	effect_label.scroll_active = false
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.text = rules_text
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_label.add_theme_color_override("default_color", type_palette.description_text)
	effect_label.add_theme_font_size_override("normal_font_size", 8)
	effect_label.add_theme_font_size_override("bold_font_size", 8)
	if body_font != null:
		effect_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		effect_label.add_theme_font_override("bold_font", body_bold_font)
	effect_center.add_child(effect_label)

	var meta_row := HBoxContainer.new()
	meta_row.name = "MetaRow"
	meta_row.position = Vector2(0, meta_y)
	meta_row.custom_minimum_size = Vector2(CARD_FACE_SIZE.x, CARD_META_HEIGHT)
	meta_row.size = Vector2(CARD_FACE_SIZE.x, CARD_META_HEIGHT)
	meta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	meta_row.add_theme_constant_override("separation", 4)
	layout.add_child(meta_row)

	var type_label := Label.new()
	type_label.name = "TypeLabel"
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.custom_minimum_size = Vector2(0, 10)
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.text = card.card_type.to_upper()
	type_label.add_theme_color_override("font_color", type_palette.footer_text)
	type_label.add_theme_font_size_override("font_size", 6)
	if title_font != null:
		type_label.add_theme_font_override("font", title_font)
	meta_row.add_child(type_label)

	if visual_state.begins_with("market_"):
		button.add_child(_create_pile_badge(game_state.get_supply_count(card.id), type_palette.accent))

	button.add_child(_create_price_badge(game_state.get_effective_cost(card)))

	if visual_state == MARKET_UNAFFORDABLE:
		button.modulate = Color(0.74, 0.72, 0.66, 0.62)
	elif visual_state == HAND_UNPLAYABLE:
		button.modulate = Color(0.78, 0.78, 0.74, 1.0)

	return button


func _create_price_badge(cost: int) -> Control:
	var badge := Control.new()
	badge.name = "PriceBadge"
	badge.custom_minimum_size = Vector2(30, 30)
	badge.size = Vector2(30, 30)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.position = Vector2(5, 5)
	badge.z_index = 4

	var coin_face := PanelContainer.new()
	coin_face.name = "CoinFace"
	coin_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_face.add_theme_stylebox_override(
		"panel",
		_make_coin_style(Color("#7a5418"), Color("#caa044"), 2, 15)
	)
	badge.add_child(coin_face)
	coin_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var inner_ring := PanelContainer.new()
	inner_ring.name = "InnerRing"
	inner_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_ring.position = Vector2(3, 3)
	inner_ring.size = Vector2(24, 24)
	inner_ring.add_theme_stylebox_override(
		"panel",
		_make_coin_style(Color("#bf8f37"), Color("#56380f"), 2, 12)
	)
	badge.add_child(inner_ring)

	var glint := ColorRect.new()
	glint.name = "CoinGlint"
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glint.color = Color(1.0, 0.94, 0.68, 0.52)
	glint.position = Vector2(8, 6)
	glint.size = Vector2(11, 2)
	badge.add_child(glint)

	for dot_position in _get_coin_rivet_positions():
		badge.add_child(_create_coin_rivet(dot_position))

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.text = str(cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_color_override("font_color", Color("#241405"))
	cost_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.933, 0.769, 0.4))
	cost_label.add_theme_constant_override("shadow_offset_x", 1)
	cost_label.add_theme_constant_override("shadow_offset_y", -1)
	cost_label.add_theme_font_size_override("font_size", 14)
	if title_font != null:
		cost_label.add_theme_font_override("font", title_font)
	elif body_bold_font != null:
		cost_label.add_theme_font_override("font", body_bold_font)
	badge.add_child(cost_label)
	cost_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cost_label.offset_left = 0
	cost_label.offset_top = 1
	cost_label.offset_right = 0
	cost_label.offset_bottom = 1
	return badge


func _create_pile_badge(count: int, accent: Color) -> Control:
	var badge := PanelContainer.new()
	badge.name = "PileBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(38, 18)
	badge.size = Vector2(38, 18)
	badge.position = Vector2(CARD_FACE_SIZE.x - 43, 6)
	badge.z_index = 4
	badge.add_theme_stylebox_override(
		"panel",
		_make_pile_badge_style(accent)
	)

	var row := HBoxContainer.new()
	row.name = "PileRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	badge.add_child(row)

	if icon_textures.has("deck"):
		var deck_icon := _create_icon(icon_textures["deck"], Vector2(10, 10), accent.lightened(0.28))
		deck_icon.name = "PileIcon"
		row.add_child(deck_icon)

	var pile_label := Label.new()
	pile_label.name = "PileLabel"
	pile_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pile_label.text = str(count)
	pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pile_label.add_theme_color_override("font_color", accent.lightened(0.28))
	pile_label.add_theme_font_size_override("font_size", 9)
	if title_font != null:
		pile_label.add_theme_font_override("font", title_font)
	row.add_child(pile_label)
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


func _get_coin_rivet_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		positions.append(Vector2(13.5 + cos(angle) * 11.5, 13.5 + sin(angle) * 11.5))
	return positions


func _create_coin_rivet(position: Vector2) -> PanelContainer:
	var rivet := PanelContainer.new()
	rivet.name = "CoinRivet"
	rivet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rivet.position = position - Vector2(1, 1)
	rivet.size = Vector2(2, 2)
	rivet.add_theme_stylebox_override(
		"panel",
		_make_coin_style(COLOR_BRASS.lightened(0.34), COLOR_BRASS.darkened(0.42), 1, 1)
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


func _load_relic_icon_texture(relic_id: String) -> Texture2D:
	var icon_id := RelicCatalog.get_relic_icon_id(relic_id)
	if relic_icon_cache.has(icon_id):
		return relic_icon_cache[icon_id]
	var path := RELIC_ICON_PATH_TEMPLATE % icon_id
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			texture = ImageTexture.create_from_image(image)
	relic_icon_cache[icon_id] = texture
	return texture


func _update_card_pivot(button: Button) -> void:
	if button.get_meta("hand_fan", false):
		# Hand cards share a fan pivot below the row; recompute the whole fan so
		# this card's pivot/position stays consistent when it resizes.
		if button.get_parent() == hand_container:
			_apply_hand_fan_offsets()
		return
	button.pivot_offset = button.size * 0.5


func _on_card_mouse_entered(
	card: CardDefinition,
	button: Button,
	visual_state: String
) -> void:
	if visual_state != MARKET_UNAFFORDABLE:
		var is_hand: bool = button.get_meta("hand_fan", false)
		# Hand cards lift further out of the fan and grow a touch more so the
		# hovered card clearly pops above its neighbours.
		_animate_card_scale(button, HAND_HOVER_SCALE if is_hand else CARD_HOVER_SCALE)
		button.z_index = 30 if is_hand else 10
		if is_hand:
			_reveal_hand_card(button)
			_set_hand_trash_hover(button, bool(button.get_meta("direct_hand_trash", false)), true)


func _reveal_hand_card(card: Control) -> void:
	if hand_scroll == null or hand_container.get_child_count() < 7:
		return
	var visible_width := hand_scroll.size.x
	if visible_width <= 0.0:
		return
	var desired := hand_scroll.scroll_horizontal
	var left := card.position.x
	var right := left + card.size.x
	if left < desired + 18.0:
		desired = left - 18.0
	elif right > desired + visible_width - 18.0:
		desired = right - visible_width + 18.0
	desired = clampf(desired, 0.0, hand_scroll.get_h_scroll_bar().max_value)
	if absf(desired - hand_scroll.scroll_horizontal) < 2.0:
		return
	var tween := create_tween()
	tween.bind_node(hand_scroll)
	tween.tween_property(hand_scroll, "scroll_horizontal", desired, 0.22)


func _on_card_mouse_exited(button: Button) -> void:
	_animate_card_scale(button, CARD_NORMAL_SCALE)
	button.z_index = 0
	# A chosen hand-trash card keeps its X once the pointer leaves, so the
	# player can review every pending deletion before pressing Confirm.
	_set_hand_trash_hover(
		button,
		bool(button.get_meta("direct_hand_trash", false)),
		bool(button.get_meta("choice_selected", false))
	)


func _set_hand_trash_hover(button: Button, is_trash_choice: bool, hovered: bool) -> void:
	var overlay := button.get_node_or_null("TrashHoverOverlay") as Control
	if is_trash_choice and hovered:
		if overlay == null:
			overlay = Control.new()
			overlay.name = "TrashHoverOverlay"
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.z_index = 12
			button.add_child(overlay)
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var shade := ColorRect.new()
			shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shade.color = Color(0.34, 0.015, 0.02, 0.34)
			overlay.add_child(shade)
			shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var x_label := Label.new()
			x_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			x_label.text = "×"
			x_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			x_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			x_label.add_theme_color_override("font_color", Color("#ff5757"))
			x_label.add_theme_color_override("font_shadow_color", Color(0.12, 0, 0, 0.9))
			x_label.add_theme_constant_override("shadow_offset_x", 2)
			x_label.add_theme_constant_override("shadow_offset_y", 2)
			x_label.add_theme_font_size_override("font_size", 92)
			if title_font != null:
				x_label.add_theme_font_override("font", title_font)
			overlay.add_child(x_label)
			x_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		else:
			overlay.show()
	elif overlay != null:
		overlay.hide()


func _on_card_gui_input(
	event: InputEvent,
	card: CardDefinition,
	button: Control,
	visual_state: String
) -> void:
	if not _is_right_click_pressed(event):
		return
	_toggle_card_preview(card, button, visual_state)
	button.accept_event()


func _on_relic_slot_gui_input(event: InputEvent, relic_id: String, source: Control) -> void:
	if not _is_right_click_pressed(event):
		return
	_toggle_relic_preview(relic_id, source)
	source.accept_event()


func _is_right_click_pressed(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT
	return false


func _on_hud_button_hovered(button: Button) -> void:
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
	source_button: Control,
	visual_state: String
) -> void:
	if relic_preview != null:
		relic_preview.hide()
	active_preview_kind = "card"
	active_preview_id = card.id
	var type_palette := _get_card_type_palette(card.card_type)
	preview_name_label.text = card.card_name
	# The preview meta line stays lean: card type, cost, and kingdom only.
	preview_meta_label.text = (
		"%s / COST %d / %s"
		% [
			card.card_type.to_upper(),
			game_state.get_effective_cost(card),
			game_state.get_card_kingdom(card).to_upper()
		]
	)
	card_preview.set_meta("card_type", card.card_type)
	card_preview.set_meta("card_base_color", _get_card_surface_color(card.card_type))
	preview_name_label.add_theme_color_override("font_color", type_palette.name_text)
	preview_meta_label.add_theme_color_override("font_color", type_palette.chip_text)
	preview_art.texture = _load_card_texture(card.art_id)
	preview_art.modulate = Color(1, 1, 1, CARD_ART_OPACITY)
	preview_art_frame.visible = preview_art.texture != null
	preview_art_frame.add_theme_stylebox_override(
		"panel",
		_make_card_art_style(_get_card_surface_color(card.card_type).darkened(0.14))
	)
	var effect_font_size := _get_preview_effect_font_size(card.description)
	preview_effect_label.add_theme_font_size_override("normal_font_size", effect_font_size)
	preview_effect_label.add_theme_font_size_override("bold_font_size", effect_font_size)
	preview_effect_label.text = _get_card_rules_text(card.description)
	preview_effect_label.add_theme_color_override("default_color", type_palette.description_text)
	card_preview.add_theme_stylebox_override(
		"panel",
		_make_preview_style(_get_card_surface_color(card.card_type), type_palette.accent)
	)
	card_preview.position = _get_preview_position(source_button)
	card_preview.show()


func _toggle_card_preview(
	card: CardDefinition,
	source_button: Control,
	visual_state: String
) -> void:
	if card_preview.visible and active_preview_kind == "card" and active_preview_id == card.id:
		_hide_card_preview()
		return
	_show_card_preview(card, source_button, visual_state)


func _show_relic_preview(relic_id: String, source: Control) -> void:
	if card_preview != null:
		card_preview.hide()
	active_preview_kind = "relic"
	active_preview_id = relic_id
	relic_preview_name_label.text = RelicCatalog.get_relic_name(relic_id)
	relic_preview_meta_label.text = "RELIC / CONQUEST BOON"
	relic_preview_description_label.text = RelicCatalog.get_relic_description(relic_id)
	_clear_container(relic_preview_icon_host)
	relic_preview_icon_host.add_child(
		_create_relic_icon_or_glyph(relic_id, RELIC_PREVIEW_ICON_SIZE, true, 48)
	)
	relic_preview.position = _get_preview_position(source, relic_preview)
	relic_preview.show()


func _toggle_relic_preview(relic_id: String, source: Control) -> void:
	if relic_preview.visible and active_preview_kind == "relic" and active_preview_id == relic_id:
		_hide_relic_preview()
		return
	_show_relic_preview(relic_id, source)


func _get_preview_position(source_button: Control, preview_control: Control = null) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var target_preview := preview_control if preview_control != null else card_preview
	var preview_size := Vector2(
		maxf(PREVIEW_SIZE.x, target_preview.size.x),
		maxf(PREVIEW_SIZE.y, target_preview.size.y)
	)
	var source_rect := source_button.get_global_rect()
	var source_center := source_rect.get_center()
	var preview_x := PREVIEW_EDGE_MARGIN
	if source_center.x < viewport_size.x * 0.5:
		preview_x = viewport_size.x - preview_size.x - PREVIEW_EDGE_MARGIN

	var preview_y := PREVIEW_EDGE_MARGIN + TOP_BAR_HEIGHT
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
	if active_preview_kind == "card":
		active_preview_kind = ""
		active_preview_id = ""


func _hide_relic_preview() -> void:
	if relic_preview != null:
		relic_preview.hide()
	if active_preview_kind == "relic":
		active_preview_kind = ""
		active_preview_id = ""


func _hide_all_previews() -> void:
	if card_preview != null:
		card_preview.hide()
	if relic_preview != null:
		relic_preview.hide()
	active_preview_kind = ""
	active_preview_id = ""


func _create_played_card_chip(card: CardDefinition, occurrence: int = 1, total: int = 1) -> Button:
	var type_palette := _get_card_type_palette(card.card_type)
	var surface := _get_card_surface_color(card.card_type)
	var chip := Button.new()
	chip.name = "PlayedCard_%s" % card.id
	chip.custom_minimum_size = PLAYED_CARD_SIZE
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.focus_mode = Control.FOCUS_NONE
	chip.clip_contents = true
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.set_meta("card_id", card.id)
	chip.set_meta("visual_state", "played_card")
	chip.tooltip_text = "%s - %s" % [card.card_name, card.description]
	chip.resized.connect(_update_card_pivot.bind(chip))
	chip.mouse_entered.connect(_on_card_mouse_entered.bind(card, chip, "played_card"))
	chip.mouse_exited.connect(_on_card_mouse_exited.bind(chip))
	chip.gui_input.connect(_on_card_gui_input.bind(card, chip, "played_card"))
	chip.add_theme_stylebox_override(
		"normal",
		_make_card_style(surface, type_palette.accent.darkened(0.06), 2)
	)
	chip.add_theme_stylebox_override(
		"hover",
		_make_card_style(surface.lightened(0.08), type_palette.hover_border, 2)
	)
	chip.add_theme_stylebox_override(
		"pressed",
		_make_card_style(surface.darkened(0.06), type_palette.accent, 2)
	)

	var content := Control.new()
	content.name = "PlayedCardContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.clip_contents = true
	chip.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var art_frame := Panel.new()
	art_frame.name = "ArtFrame"
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.clip_contents = true
	art_frame.add_theme_stylebox_override("panel", _make_card_art_style(surface.darkened(0.18)))
	content.add_child(art_frame)
	art_frame.anchor_left = 0.0
	art_frame.anchor_top = 0.0
	art_frame.anchor_right = 1.0
	art_frame.anchor_bottom = 0.0
	art_frame.offset_bottom = PLAYED_CARD_ART_HEIGHT

	var art := TextureRect.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _load_card_texture(card.art_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_frame.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var art_scrim := ColorRect.new()
	art_scrim.name = "ArtScrim"
	art_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_scrim.color = Color(type_palette.scrim.r, type_palette.scrim.g, type_palette.scrim.b, 0.24)
	art_frame.add_child(art_scrim)
	art_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var name_band := Panel.new()
	name_band.name = "NameBand"
	name_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_band.add_theme_stylebox_override(
		"panel",
		_make_flat_card_style(Color(surface.r, surface.g, surface.b, 0.96), Color.TRANSPARENT, 0)
	)
	content.add_child(name_band)
	name_band.anchor_left = 0.0
	name_band.anchor_top = 0.0
	name_band.anchor_right = 1.0
	name_band.anchor_bottom = 1.0
	name_band.offset_top = PLAYED_CARD_ART_HEIGHT

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", type_palette.name_text)
	name_label.add_theme_font_size_override("font_size", 7)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	name_band.add_child(name_label)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_label.offset_left = 3
	name_label.offset_right = -3
	if total > 1:
		chip.add_child(_create_play_occurrence_badge(occurrence, total, type_palette.accent))
	return chip


func _create_play_occurrence_badge(occurrence: int, total: int, accent: Color) -> Label:
	var badge := Label.new()
	badge.name = "OccurrenceBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.text = "%d/%d" % [occurrence, total]
	badge.position = Vector2(PLAYED_CARD_SIZE.x - 28, 3)
	badge.size = Vector2(24, 15)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 7)
	badge.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	badge.add_theme_stylebox_override("normal", _make_pill_style(Color(0.08, 0.05, 0.03, 0.9), accent, 2))
	if title_font != null:
		badge.add_theme_font_override("font", title_font)
	return badge


func _get_desaturate_material() -> ShaderMaterial:
	if card_desaturate_material != null:
		return card_desaturate_material
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float amount : hint_range(0.0, 1.0) = 0.42;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tfloat grey = dot(tex.rgb, vec3(0.299, 0.587, 0.114));\n\ttex.rgb = mix(tex.rgb, vec3(grey), amount);\n\tCOLOR = tex * COLOR;\n}"
	card_desaturate_material = ShaderMaterial.new()
	card_desaturate_material.shader = shader
	return card_desaturate_material


func _get_card_meta_chip_text(card: CardDefinition) -> String:
	var parts := PackedStringArray()
	if card.card_type == "victory":
		if card.victory_points != 0:
			parts.append("%d VP" % card.victory_points)
		elif card.score_per_cards > 0:
			parts.append("VP / %d" % card.score_per_cards)
	elif card.card_type == "resource" and card.coin_value > 0:
		parts.append(_format_card_stat(card.coin_value, "coin", "coins"))

	if card.draw_cards > 0:
		parts.append(_format_card_stat(card.draw_cards, "card", "cards"))
	if card.gain_actions > 0:
		parts.append(_format_card_stat(card.gain_actions, "action", "actions"))
	if card.gain_buys > 0:
		parts.append(_format_card_stat(card.gain_buys, "buy", "buys"))
	if card.gain_coins > 0:
		parts.append(_format_card_stat(card.gain_coins, "coin", "coins"))

	if parts.is_empty():
		for effect in card.special_effects:
			var label := str(effect.get("label", "")).strip_edges()
			if not label.is_empty():
				parts.append(label)
				break

	if parts.is_empty():
		parts.append(card.card_group if not card.card_group.is_empty() else card.card_type.capitalize())
	return " · ".join(parts)


func _format_card_stat(amount: int, singular: String, plural: String) -> String:
	return "+%d %s" % [amount, singular if amount == 1 else plural]


func _get_card_palette(visual_state: String) -> Dictionary:
	match visual_state:
		HAND_PLAYABLE:
			return {
				"border": COLOR_ACTION_ACCENT,
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.lightened(0.02),
			}
		MARKET_AFFORDABLE:
			return {
				"border": COLOR_BRASS,
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.lightened(0.02),
			}
		MARKET_UNAFFORDABLE:
			return {
				"border": COLOR_UNAVAILABLE,
				"text": COLOR_PARCHMENT.darkened(0.06),
				"muted": COLOR_PARCHMENT.darkened(0.18),
			}
		MARKET_NEUTRAL:
			return {
				"border": COLOR_BRASS.darkened(0.04),
				"text": COLOR_PARCHMENT_LIGHT,
				"muted": COLOR_PARCHMENT.lightened(0.02),
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


func _get_card_type_palette(card_type: String) -> Dictionary:
	match card_type:
		"resource":
			return {
				"accent": COLOR_RESOURCE_ACCENT,
				"hover_border": Color("#ffe0a0"),
				"name_text": Color("#f4e6c4"),
				"chip_bg": Color(0.941, 0.741, 0.345, 0.18),
				"chip_text": Color("#f4cd72"),
				"description_text": Color(0.957, 0.902, 0.769, 0.80),
				"footer_text": Color(0.941, 0.741, 0.345, 0.72),
				"scrim": Color(0.137, 0.082, 0.027, 0.18),
			}
		"victory":
			return {
				"accent": COLOR_VICTORY_ACCENT,
				"hover_border": Color("#f3c4d2"),
				"name_text": Color("#fdebf1"),
				"chip_bg": Color(0.878, 0.541, 0.635, 0.20),
				"chip_text": Color("#f3c4d2"),
				"description_text": Color(0.992, 0.922, 0.945, 0.82),
				"footer_text": Color(0.878, 0.541, 0.635, 0.74),
				"scrim": Color(0.122, 0.051, 0.098, 0.20),
			}
		"curse":
			return {
				"accent": COLOR_CURSE_ACCENT,
				"hover_border": COLOR_CURSE_ACCENT.lightened(0.25),
				"name_text": Color("#eee4ff"),
				"chip_bg": Color(0.706, 0.604, 0.851, 0.22),
				"chip_text": Color("#dbcdf2"),
				"description_text": Color(0.91, 0.86, 0.98, 0.82),
				"footer_text": Color(0.706, 0.604, 0.851, 0.72),
				"scrim": Color(0.118, 0.086, 0.16, 0.20),
			}
		_:
			return {
				"accent": COLOR_ACTION_ACCENT,
				"hover_border": Color("#bfddf8"),
				"name_text": Color("#eef5fc"),
				"chip_bg": Color(0.49, 0.714, 0.91, 0.18),
				"chip_text": Color("#bfddf8"),
				"description_text": Color(0.863, 0.91, 0.969, 0.82),
				"footer_text": Color(0.49, 0.714, 0.91, 0.74),
				"scrim": Color(0.051, 0.086, 0.149, 0.20),
			}


func _get_card_surface_color(card_type: String) -> Color:
	match card_type:
		"resource":
			return COLOR_RESOURCE_CARD
		"victory":
			return COLOR_VICTORY_CARD
		"curse":
			return COLOR_CURSE_CARD
		_:
			return COLOR_ACTION_CARD


func _get_card_type_accent(card_type: String) -> Color:
	match card_type:
		"resource":
			return COLOR_RESOURCE_ACCENT
		"victory":
			return COLOR_VICTORY_ACCENT
		"curse":
			return COLOR_CURSE_ACCENT
		_:
			return COLOR_ACTION_ACCENT


func _make_card_style(
	color: Color,
	border_color: Color,
	border_width: int,
	highlighted: bool = true
) -> StyleBox:
	# Playable / affordable cards are signalled by their bright type-accent border
	# alone, not by a coloured halo. Both states use the same restrained dark drop
	# shadow so the table reads as a clean row of cards rather than a glowing one.
	var style := _make_flat_card_style(color, border_color, border_width)
	style.set_corner_radius_all(13)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 7 if highlighted else 5
	style.shadow_offset = Vector2(0, 4)
	return style


func _make_card_art_style(color: Color) -> StyleBoxFlat:
	var style := _make_flat_card_style(color, Color(0, 0, 0, 0.0), 0)
	style.set_corner_radius_all(13)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	return style


func _make_meta_chip_style(color: Color) -> StyleBoxFlat:
	var style := _make_flat_card_style(color, Color.TRANSPARENT, 0)
	style.set_corner_radius_all(5)
	style.content_margin_left = 5
	style.content_margin_top = 1
	style.content_margin_right = 5
	style.content_margin_bottom = 1
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	return style


func _make_pile_badge_style(accent: Color) -> StyleBoxFlat:
	var style := _make_flat_card_style(
		Color(0.031, 0.02, 0.012, 0.75),
		Color(accent.r, accent.g, accent.b, 0.45),
		1
	)
	style.set_corner_radius_all(11)
	style.content_margin_left = 5
	style.content_margin_top = 2
	style.content_margin_right = 5
	style.content_margin_bottom = 2
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
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
	style.set_corner_radius_all(15)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	return style


func _configure_choice_overlay() -> void:
	# Choice pickers should read as a compact extension of the walnut HUD, not a
	# second full-screen scene. The restore tab intentionally lives outside the
	# overlay so minimizing removes both its dimmer and input blocker.
	choice_panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#1d140c"), COLOR_BRASS.darkened(0.1), 1)
	)
	choice_minimize_button = Button.new()
	choice_minimize_button.name = "MinimizeButton"
	choice_minimize_button.text = "HIDE"
	choice_minimize_button.tooltip_text = "Hide this choice temporarily and view the board"
	choice_minimize_button.custom_minimum_size = Vector2(82, 34)
	choice_minimize_button.add_theme_stylebox_override("normal", _make_top_button_style(false))
	choice_minimize_button.add_theme_stylebox_override("hover", _make_top_button_style(false, true))
	choice_minimize_button.pressed.connect(_minimize_choice_overlay)
	var buttons := choice_confirm_button.get_parent() as HBoxContainer
	buttons.add_child(choice_minimize_button)
	buttons.move_child(choice_minimize_button, 0)

	choice_restore_button = Button.new()
	choice_restore_button.name = "ChoiceRestoreTab"
	choice_restore_button.text = "CHOICE  ▴"
	choice_restore_button.tooltip_text = "Restore pending choice"
	choice_restore_button.custom_minimum_size = Vector2(126, 38)
	choice_restore_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	choice_restore_button.position = Vector2(-146, -58)
	choice_restore_button.add_theme_stylebox_override(
		"normal", _make_panel_style(Color("#1d140c"), COLOR_BRASS.darkened(0.1), 1)
	)
	choice_restore_button.add_theme_stylebox_override("hover", _make_top_button_style(false, true))
	choice_restore_button.pressed.connect(_restore_choice_overlay)
	choice_restore_button.hide()
	choice_restore_button.z_index = 161
	add_child(choice_restore_button)


func _minimize_choice_overlay() -> void:
	if current_choice == null:
		return
	choice_minimized = true
	choice_overlay.hide()
	choice_restore_button.show()


func _restore_choice_overlay() -> void:
	if current_choice == null:
		choice_restore_button.hide()
		return
	choice_minimized = false
	choice_restore_button.hide()
	choice_overlay.show()
	_refresh_choice_controls()


func _make_top_bar_style() -> StyleBoxFlat:
	var style := _make_flat_card_style(Color(0.11, 0.075, 0.055, 0.86), Color(0.835, 0.667, 0.314, 0.2), 1)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 8
	return style


func _make_pill_style(color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := _make_flat_card_style(color, border_color, 1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	return style


func _make_top_button_style(square: bool, hover: bool = false) -> StyleBoxFlat:
	var style := _make_flat_card_style(
		Color(0.18, 0.125, 0.08, 0.78) if not hover else Color(0.24, 0.17, 0.105, 0.86),
		Color(0.835, 0.667, 0.314, 0.5 if hover else 0.34),
		1
	)
	style.set_corner_radius_all(8 if square else 9)
	style.content_margin_left = 8
	style.content_margin_top = 3
	style.content_margin_right = 8
	style.content_margin_bottom = 3
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 5
	return style


func _make_end_turn_style(hover: bool = false, disabled: bool = false) -> StyleBoxFlat:
	# Antique gold rather than bright neon yellow: deeper, warmer, more regal.
	var base := Color("#c39a44") if not disabled else Color(0.35, 0.32, 0.28, 0.75)
	if hover and not disabled:
		base = Color("#d8b25e")
	var style := _make_flat_card_style(
		base,
		Color("#6e4a16") if not disabled else Color(0, 0, 0, 0.35),
		1
	)
	style.set_corner_radius_all(9)
	style.content_margin_left = 10
	style.content_margin_top = 7
	style.content_margin_right = 10
	style.content_margin_bottom = 7
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style


func _make_relic_slot_style(filled: bool) -> StyleBoxFlat:
	var style := _make_flat_card_style(
		Color("#b9882f") if filled else Color(0, 0, 0, 0),
		Color(0.835, 0.667, 0.314, 0.42),
		1
	)
	style.set_corner_radius_all(15)
	style.shadow_color = Color(0.835, 0.667, 0.314, 0.28) if filled else Color.TRANSPARENT
	style.shadow_size = 8 if filled else 0
	return style


func _make_card_back_style(color: Color) -> StyleBoxFlat:
	var style := _make_flat_card_style(color, Color(0.835, 0.667, 0.314, 0.48), 2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.46)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	return style


func _make_discard_pile_style() -> StyleBoxFlat:
	var style := _make_flat_card_style(Color("#1b110a"), Color(0.835, 0.667, 0.314, 0.28), 2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	return style


func _make_count_badge_style() -> StyleBoxFlat:
	var style := _make_flat_card_style(Color("#d5aa50"), Color("#7c5419"), 1)
	style.set_corner_radius_all(11)
	style.content_margin_left = 7
	style.content_margin_top = 2
	style.content_margin_right = 7
	style.content_margin_bottom = 2
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _make_player_row_style(active: bool) -> StyleBoxFlat:
	var style := _make_flat_card_style(
		Color(0.09, 0.058, 0.035, 0.72) if active else Color(0.055, 0.038, 0.026, 0.42),
		Color(0.835, 0.667, 0.314, 0.28 if active else 0.14),
		1
	)
	style.set_corner_radius_all(7)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	return style


func _make_dot_style(color: Color) -> StyleBoxFlat:
	var style := _make_flat_card_style(color, Color.TRANSPARENT, 0)
	style.set_corner_radius_all(5)
	style.shadow_color = color
	style.shadow_color.a = 0.35
	style.shadow_size = 4
	return style


func _make_preview_style(surface_color: Color, border_color: Color) -> StyleBox:
	var style := _make_flat_card_style(surface_color.darkened(0.08), border_color, 2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 8)
	return style


func _make_parchment_panel_style() -> StyleBoxFlat:
	var style := _make_flat_card_style(COLOR_PARCHMENT_PANEL, COLOR_MENU_BORDER, 1)
	style.bg_color = COLOR_PARCHMENT_PANEL
	style.set_corner_radius_all(18)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.62)
	style.shadow_size = 26
	style.shadow_offset = Vector2(0, 14)
	return style


func _make_parchment_button_style(
	primary: bool,
	hover: bool = false,
	disabled: bool = false
) -> StyleBoxFlat:
	# Primary = a warm brass fill (the main call to action); secondary = the same
	# dark, thin-brass-bordered ghost treatment as the home menu buttons.
	var bg := Color("#d8b463") if primary else Color(0.157, 0.114, 0.078, 0.62)
	var border := Color("#a87f2e") if primary else Color(0.835, 0.667, 0.314, 0.42)
	if hover and not disabled:
		bg = Color("#e6c578") if primary else Color(0.22, 0.16, 0.1, 0.74)
		border = Color("#c0922f") if primary else Color(0.835, 0.667, 0.314, 0.72)
	if disabled:
		bg = Color(0.4, 0.34, 0.22, 0.28) if primary else Color(0.12, 0.09, 0.06, 0.4)
		border = Color(0.5, 0.4, 0.22, 0.26)
	var style := _make_flat_card_style(bg, border, 1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12
	style.content_margin_top = 7
	style.content_margin_right = 12
	style.content_margin_bottom = 7
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _make_parchment_input_style() -> StyleBoxFlat:
	var style := _make_flat_card_style(Color(0.05, 0.035, 0.022, 0.55), COLOR_MENU_BORDER, 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
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
	color: Color,
	as_card_back := false
) -> PanelContainer:
	var ghost := PanelContainer.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 1
	ghost.position = source_rect.position
	ghost.size = source_rect.size
	ghost.pivot_offset = source_rect.size * 0.5

	if as_card_back:
		# A face-down draw: the crest card back instead of a bright fill.
		ghost.add_theme_stylebox_override(
			"panel",
			_make_card_style(COLOR_WALNUT_DARK, COLOR_BRASS, 2)
		)
		var crest := _create_logo_emblem(28)
		crest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crest.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ghost.add_child(crest)
		animation_layer.add_child(ghost)
		return ghost

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
	tween.set_parallel(true)
	tween.tween_property(ghost, "scale", Vector2(0.05, 0.05), duration)
	tween.tween_property(ghost, "rotation", 0.4, duration)
	tween.tween_property(ghost, "modulate:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)


func _queue_gain_flights(gained_ids: Array[String], destination := "discard") -> void:
	# Deliberately serialize gains: a pair of curses or Silvers stays legible
	# instead of collapsing into one flash of overlapping cards.
	if gained_ids.is_empty():
		return
	var sequence := create_tween()
	for card_id in gained_ids:
		sequence.tween_callback(_animate_queued_gain_flight.bind(card_id, destination))
		# Each flight has a move/fade phase followed by its shrink-away phase.
		# Leave a small buffer so multiple gains never overlap mid-animation.
		sequence.tween_interval(_action_animation_duration(CARD_MOVE_SECONDS * 2.15))


func _animate_queued_gain_flight(card_id: String, destination: String) -> void:
	if not game_state.card_catalog.has(card_id):
		return
	var source_button := _find_card_button(market_container, card_id)
	if source_button == null and card_id == GameState.CURSE_CARD_ID:
		source_button = briar_hex_tab
	if source_button == null:
		return
	var target := _get_hud_target_center("DiscardStat")
	if destination == "hand":
		target = hand_panel.get_global_rect().get_center()
	elif destination == "deck":
		target = _get_hud_target_center("DeckStat")
	_animate_moving_card(
		_create_moving_card(game_state.card_catalog[card_id], source_button.get_global_rect(), COLOR_FOREST),
		target,
		CARD_MOVE_SECONDS,
		Vector2(0.22, 0.22)
	)
	_play_ui_sound("buy_card", -5.0)


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
			COLOR_SLATE,
			true
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


func _animate_choice_flights(tokens: Array[String]) -> void:
	# When a choice is confirmed, fly the picked cards from the overlay to
	# wherever they are headed (deck, discard, play) or shrink them away for a
	# trash, so choice resolutions read as physical card movement.
	if current_choice == null or tokens.is_empty() or not motion_enabled:
		return
	var resolver := current_choice.resolver
	var trash_resolvers := [
		"trash_hand", "remodel", "develop_trash", "upgrade_resource",
		"upgrade_exact_nonself", "trash_for_copies", "trash_named_coins",
		"trash_resource_mode", "inspect_trash", "attack_trash_resource",
		"salvage_resource",
	]
	var play_resolvers := ["replay_action", "vassal_play", "play_self"]
	for token in tokens:
		var button: Button = choice_buttons.get(token)
		if button == null or not button.is_inside_tree():
			continue
		var card: CardDefinition = null
		for candidate in current_choice.candidates:
			if str(candidate.get("token", "")) == token:
				card = candidate.get("card")
				break
		if card == null:
			continue
		var ghost := _create_moving_card(
			card,
			button.get_global_rect(),
			_get_card_surface_color(card.card_type)
		)
		if trash_resolvers.has(resolver):
			_animate_vanishing_card(ghost)
		elif resolver == "relic_predraw":
			_animate_moving_card(
				ghost,
				hand_panel.get_global_rect().get_center(),
				CARD_MOVE_SECONDS,
				Vector2(0.5, 0.5)
			)
		elif play_resolvers.has(resolver):
			_animate_moving_card(
				ghost,
				play_area_panel.get_global_rect().get_center(),
				CARD_MOVE_SECONDS,
				Vector2(0.48, 0.48)
			)
		elif resolver.contains("topdeck") or resolver == "inspect_order" or resolver == "shuffle_actions" or resolver == "order_cards":
			_animate_moving_card(
				ghost,
				_get_hud_target_center("DeckStat"),
				CARD_MOVE_SECONDS,
				Vector2(0.22, 0.22)
			)
		else:
			_animate_moving_card(
				ghost,
				_get_hud_target_center("DiscardStat"),
				CARD_MOVE_SECONDS,
				Vector2(0.22, 0.22)
			)


func _animate_vanishing_card(ghost: Control) -> void:
	if not motion_enabled:
		ghost.queue_free()
		return
	var duration := _action_animation_duration(CARD_MOVE_SECONDS)
	var tween := create_tween()
	tween.bind_node(ghost)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(ghost, "scale", Vector2(0.05, 0.05), duration)
	tween.tween_property(ghost, "rotation", 0.4, duration)
	tween.tween_property(ghost, "modulate:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)


func _capture_local_zone_summary() -> Dictionary:
	# Clients animate their confirmed actions by diffing the snapshot before
	# and after it is applied. Hosts animate directly, so they skip this.
	if not network_enabled or network_is_host or game_state.players.is_empty():
		return {}
	if not has_active_game or not network_table_open:
		return {}
	var local_player := _local_view_player()
	var hand_rects: Dictionary = {}
	for child in hand_container.get_children():
		var control := child as Control
		if control == null or not control.has_meta("card_id"):
			continue
		var card_id := str(control.get_meta("card_id"))
		if not hand_rects.has(card_id):
			hand_rects[card_id] = []
		(hand_rects[card_id] as Array).append(control.get_global_rect())
	var discard_top := ""
	if not local_player.discard_pile.is_empty():
		discard_top = local_player.discard_pile[local_player.discard_pile.size() - 1].id
	return {
		"hand_ids": _card_ids_from_zone(local_player.hand),
		"play_count": local_player.play_area.size(),
		"discard_count": local_player.discard_pile.size(),
		"discard_ids": _card_ids_from_zone(local_player.discard_pile),
		"discard_top": discard_top,
		"turn_number": local_player.turn_number,
		"hand_rects": hand_rects,
	}


func _take_recorded_rect(hand_rects: Dictionary, card_id: String) -> Rect2:
	var rects: Array = hand_rects.get(card_id, [])
	if rects.is_empty():
		return Rect2()
	return rects.pop_front()


func _multiset_count(values: Array, value: String) -> int:
	var count := 0
	for entry in values:
		if str(entry) == value:
			count += 1
	return count


func _multiset_difference(from_values: Array, subtract_values: Array) -> Array[String]:
	var difference: Array[String] = []
	var seen: Dictionary = {}
	for entry in from_values:
		var value := str(entry)
		seen[value] = int(seen.get(value, 0)) + 1
		if seen[value] > _multiset_count(subtract_values, value):
			difference.append(value)
	return difference


func _animate_snapshot_changes(previous_summary: Dictionary) -> void:
	if previous_summary.is_empty() or not motion_enabled:
		return
	if game_state.players.is_empty() or turn_manager.game_over:
		return
	var local_player := _local_view_player()
	var old_hand: Array = previous_summary.get("hand_ids", [])
	var new_hand := _card_ids_from_zone(local_player.hand)
	var hand_rects: Dictionary = previous_summary.get("hand_rects", {})

	if local_player.turn_number > int(previous_summary.get("turn_number", 1)):
		# Cleanup went through: the old hand sweeps to the discard pile and the
		# fresh hand is dealt from the deck.
		for card_id in old_hand:
			var rect := _take_recorded_rect(hand_rects, str(card_id))
			if rect == Rect2() or not game_state.card_catalog.has(str(card_id)):
				continue
			_animate_moving_card(
				_create_moving_card(
					game_state.card_catalog[str(card_id)],
					rect,
					COLOR_SLATE.darkened(0.18)
				),
				_get_hud_target_center("DiscardStat"),
				CLEANUP_SECONDS,
				Vector2(0.22, 0.22)
			)
		if not old_hand.is_empty():
			_play_ui_sound("discard")
		call_deferred("_animate_draw_cards", new_hand.size())
		return

	var removed := _multiset_difference(old_hand, new_hand)
	var added := _multiset_difference(new_hand, old_hand)
	var play_gain := local_player.play_area.size() - int(previous_summary.get("play_count", 0))
	var discard_gain := (
		local_player.discard_pile.size()
		- int(previous_summary.get("discard_count", 0))
	)

	if play_gain > 0 and not removed.is_empty():
		for card_id in removed:
			var rect := _take_recorded_rect(hand_rects, card_id)
			if rect == Rect2() or not game_state.card_catalog.has(card_id):
				continue
			_animate_moving_card(
				_create_moving_card(game_state.card_catalog[card_id], rect, COLOR_SLATE),
				play_area_panel.get_global_rect().get_center(),
				CARD_MOVE_SECONDS,
				Vector2(0.48, 0.48)
			)
		_play_ui_sound("play_card")
	if not added.is_empty():
		call_deferred("_animate_draw_cards", added.size())
	if discard_gain > 0 and play_gain <= 0 and removed.is_empty():
		# A card was gained straight to our discard pile (a buy, or a curse
		# gifted by an attack): fly it in from its market pile when visible.
		var gained_ids := _multiset_difference(
			_card_ids_from_zone(local_player.discard_pile),
			previous_summary.get("discard_ids", [])
		)
		_queue_gain_flights(gained_ids)


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


func _play_ui_sound(sound_name: String, volume_offset_db := 0.0) -> void:
	if not audio_enabled or sfx_volume <= 0.0 or not ui_sound_players.has(sound_name):
		return
	var player: AudioStreamPlayer = ui_sound_players[sound_name]
	last_ui_sound_name = sound_name
	player.volume_db = _get_sfx_volume_db() + volume_offset_db
	player.stop()
	player.play()


func _get_sfx_volume_db() -> float:
	var level := clampf(sfx_volume, 0.0, 1.0)
	if level <= 0.0:
		return -80.0
	return linear_to_db(pow(level, VOLUME_RESPONSE_EXPONENT)) + SFX_VOLUME_DB


func _create_logo_emblem(logo_size: float) -> Control:
	# The ConquestCartes crest brand mark, replacing the old brass asterisk.
	# Falls back to that asterisk if the texture ever fails to load.
	var logo_texture: Texture2D = ui_textures.get("logo")
	if logo_texture != null:
		var rect := TextureRect.new()
		rect.name = "LogoCrest"
		rect.texture = logo_texture
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(logo_size, logo_size)
		return rect
	var fallback := Label.new()
	fallback.name = "LogoFallback"
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.text = "*"
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback.add_theme_color_override("font_color", COLOR_BRASS)
	fallback.add_theme_font_size_override("font_size", maxi(12, int(logo_size)))
	if title_font != null:
		fallback.add_theme_font_override("font", title_font)
	return fallback


func _poll_background_music_load() -> void:
	# Called each frame while the ambience track is still streaming in on the
	# loader thread. Attach the stream the moment it is ready.
	if not background_music_loading:
		return
	var status := ResourceLoader.load_threaded_get_status(BACKGROUND_MUSIC_PATH)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_attach_background_music_stream(
			ResourceLoader.load_threaded_get(BACKGROUND_MUSIC_PATH) as AudioStream
		)
	elif (
		status == ResourceLoader.THREAD_LOAD_FAILED
		or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	):
		background_music_loading = false
		push_warning("Background music failed to load from %s." % BACKGROUND_MUSIC_PATH)


func ensure_background_music_loaded() -> void:
	# Block until the threaded music load finishes, then attach it. Used by tests
	# and any path that needs the stream present immediately rather than next frame.
	if not background_music_loading:
		return
	var status := ResourceLoader.load_threaded_get_status(BACKGROUND_MUSIC_PATH)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		OS.delay_msec(10)
		status = ResourceLoader.load_threaded_get_status(BACKGROUND_MUSIC_PATH)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_attach_background_music_stream(
			ResourceLoader.load_threaded_get(BACKGROUND_MUSIC_PATH) as AudioStream
		)
	else:
		background_music_loading = false


func _attach_background_music_stream(music_stream: AudioStream) -> void:
	background_music_loading = false
	if music_stream == null or background_music_player == null:
		return
	if music_stream is AudioStreamWAV:
		(music_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif music_stream is AudioStreamMP3:
		(music_stream as AudioStreamMP3).loop = true
	background_music_player.stream = music_stream
	background_music_player.volume_db = _get_background_music_volume_db()
	_refresh_background_music()


func _refresh_background_music() -> void:
	if background_music_player == null:
		return
	if music_enabled:
		background_music_player.volume_db = _get_background_music_volume_db()
		if background_music_volume <= 0.0:
			background_music_player.stop()
			return
		if (
			background_music_start_requested
			and background_music_player.stream != null
			and not background_music_player.playing
		):
			background_music_player.play()
	else:
		background_music_player.stop()
		background_music_start_requested = false


func _get_background_music_volume_db() -> float:
	var linear_volume := _get_background_music_linear_volume()
	if linear_volume <= 0.0:
		return -80.0
	return linear_to_db(linear_volume) + BACKGROUND_MUSIC_VOLUME_DB


func _get_background_music_linear_volume() -> float:
	var slider_volume := clampf(background_music_volume, 0.0, 1.0)
	if slider_volume <= 0.0:
		return 0.0
	return pow(slider_volume, VOLUME_RESPONSE_EXPONENT)


func _keep_background_music_alive() -> void:
	# If the music player ever ends up stopped while audio is on (audio device
	# hiccup, slow audio-server startup on some platforms), quietly restart it.
	if background_music_player == null or not music_enabled:
		return
	if background_music_volume <= 0.0:
		return
	if not background_music_start_requested:
		return
	if background_music_player.stream != null and not background_music_player.playing:
		background_music_player.play()


func _request_background_music_playback() -> void:
	if background_music_player == null or not music_enabled:
		return
	if background_music_volume <= 0.0:
		return
	# Record the request even if the stream is still loading; once it attaches,
	# _refresh_background_music picks up this flag and starts playback.
	background_music_start_requested = true
	if background_music_player.stream == null:
		return
	background_music_player.volume_db = _get_background_music_volume_db()
	if background_music_player.playing:
		return
	background_music_player.stop()
	background_music_player.play()


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_choice_requested(choice: CardChoice) -> void:
	if network_enabled and not _can_control_active_player():
		# A choice for another seat (the host is processing a client request).
		# Leave the local overlay alone; clobbering it here soft-locked the host
		# whenever a guest's card triggered a choice mid-request.
		return
	current_choice = choice
	selected_choice_tokens.clear()
	choice_buttons.clear()
	direct_hand_choice = _choice_can_be_made_from_hand(choice)
	direct_hand_tokens.clear()
	direct_supply_gain_choice = _choice_can_be_made_from_supply(choice)
	direct_supply_gain_tokens.clear()
	if direct_supply_gain_choice:
		for candidate in choice.candidates:
			var supply_card := candidate.get("card") as CardDefinition
			if supply_card != null:
				var tokens: Array = direct_supply_gain_tokens.get(supply_card.id, [])
				tokens.append(str(candidate.get("token", "")))
				direct_supply_gain_tokens[supply_card.id] = tokens
		_set_choice_overlay_hidden(false)
		_refresh_ui()
		return
	if direct_hand_choice:
		for candidate in choice.candidates:
			var hand_card := candidate.get("card") as CardDefinition
			if hand_card != null:
				var tokens: Array = direct_hand_tokens.get(hand_card.id, [])
				tokens.append(str(candidate.get("token", "")))
				direct_hand_tokens[hand_card.id] = tokens
		_set_choice_overlay_hidden(false)
		_refresh_hand()
		_refresh_end_turn_button()
		return
	_clear_container(choice_options)
	_hide_all_previews()
	card_preview.z_index = 180
	choice_prompt_label.text = choice.prompt
	choice_confirm_button.text = choice.confirm_text
	choice_skip_button.text = choice.skip_text

	var shuffled_candidates := choice.candidates.duplicate()
	shuffled_candidates.shuffle()
	for candidate in shuffled_candidates:
		var card: CardDefinition = candidate["card"]
		var token := str(candidate.get("token", ""))
		# Choice previews deliberately use the normal face without a pile-count
		# badge. The choice token remains attached to the original candidate.
		var visual_state := "choice_preview"
		var button := _create_card_button(card, visual_state)
		button.custom_minimum_size = CARD_FACE_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.set_meta("choice_token", token)
		button.set_meta("choice_selected", false)
		button.disabled = false
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_choice_card_pressed.bind(token))
		choice_options.add_child(button)
		choice_buttons[token] = button

	choice_overlay.show()
	choice_minimized = false
	if choice_restore_button != null:
		choice_restore_button.hide()
	_refresh_choice_controls()
	_refresh_ui()
	if network_enabled and network_is_host:
		_broadcast_network_snapshot()


func _on_choice_resolved(choice_id: int) -> void:
	if current_choice != null and current_choice.id != choice_id:
		return
	_hide_choice_overlay()


func _hide_choice_overlay() -> void:
	_set_choice_overlay_hidden(true)


func _set_choice_overlay_hidden(clear_choice: bool) -> void:
	choice_overlay.hide()
	choice_minimized = false
	if choice_restore_button != null:
		choice_restore_button.hide()
	card_preview.z_index = 100
	if clear_choice:
		current_choice = null
		selected_choice_tokens.clear()
		direct_hand_choice = false
		direct_hand_tokens.clear()
		direct_supply_gain_choice = false
		direct_supply_gain_tokens.clear()
	choice_buttons.clear()
	_clear_container(choice_options)


func _choice_can_be_made_from_hand(choice: CardChoice) -> bool:
	# Trash-from-hand always stays in the hand so players can inspect their
	# actual cards while choosing, including optional and multi-card effects.
	if choice.candidates.is_empty() or not _choice_is_hand_trash(choice):
		return false
	if str(choice.context.get("ui_source_zone", "")) == "supply":
		return false
	var available: Dictionary = {}
	for card in game_state.player.hand:
		available[card.id] = int(available.get(card.id, 0)) + 1
	for candidate in choice.candidates:
		var card := candidate.get("card") as CardDefinition
		if card == null or int(available.get(card.id, 0)) <= 0:
			return false
		available[card.id] = int(available[card.id]) - 1
	return true


func _choice_can_be_made_from_supply(choice: CardChoice) -> bool:
	# Gain-a-card effects use the market itself as their picker.  They never
	# spend buys or coins; resolving the choice is the only action a click takes.
	return (
		choice.minimum == 1
		and choice.maximum == 1
		and not choice.candidates.is_empty()
		and str(choice.context.get("ui_choice_kind", "")) == "gain_from_supply"
		and str(choice.context.get("ui_source_zone", "")) == "supply"
	)


func _choice_is_hand_trash(choice: CardChoice) -> bool:
	if choice == null:
		return false
	return (
		str(choice.context.get("ui_choice_kind", "")) == "trash_from_hand"
		or choice.resolver.begins_with("trash")
	)


func _show_trash_pile() -> void:
	# The trash viewer reuses the choice overlay. Do not overwrite an unresolved
	# choice, which would discard its resolver and leave the game waiting for it.
	if current_choice != null:
		return
	if game_state.player == null or game_state.player.trash_pile.is_empty():
		return
	_hide_all_previews()
	direct_hand_choice = false
	direct_hand_tokens.clear()
	selected_choice_tokens.clear()
	choice_buttons.clear()
	_clear_container(choice_options)
	choice_prompt_label.text = "Cards removed from your deck this game"
	choice_selection_label.text = "%d trashed card%s" % [game_state.player.trash_pile.size(), "" if game_state.player.trash_pile.size() == 1 else "s"]
	choice_skip_button.hide()
	choice_confirm_button.text = "CLOSE"
	choice_confirm_button.disabled = false
	var trashed_cards := game_state.player.trash_pile.duplicate()
	trashed_cards.shuffle()
	for card in trashed_cards:
		var preview := _create_card_button(card, "choice_preview")
		preview.disabled = true
		choice_options.add_child(preview)
	choice_overlay.show()


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
	choice_confirm_button.disabled = not current_choice.is_valid_selection(selected_choice_tokens)
	choice_skip_button.visible = minimum == 0
	_refresh_end_turn_button()


func _on_choice_confirmed() -> void:
	if current_choice == null:
		_hide_choice_overlay()
		return
	_submit_choice(selected_choice_tokens.duplicate())


func _on_choice_skipped() -> void:
	_submit_choice([])


func _submit_choice(tokens: Array[String]) -> void:
	if current_choice == null:
		return
	var chosen_gain_ids: Array[String] = []
	var gain_destination := str(current_choice.context.get("destination", "discard"))
	if _choice_can_be_made_from_supply(current_choice):
		for entry in current_choice.get_selected_entries(tokens):
			var gained_card := entry.get("card") as CardDefinition
			if gained_card != null:
				chosen_gain_ids.append(gained_card.id)
	_animate_choice_flights(tokens)
	if _is_network_client():
		_send_network_client_request("request_choice", {"tokens": tokens})
		return
	var hand_before := game_state.player.hand.size()
	var discard_before := _card_ids_from_zone(game_state.player.discard_pile)
	var previous_turn_manager_ending := turn_manager.ending_turn
	if network_enabled and game_state.player.ending_turn:
		turn_manager.ending_turn = false
	if not game_state.resolve_choice(tokens):
		turn_manager.ending_turn = previous_turn_manager_ending
		return
	turn_manager.ending_turn = previous_turn_manager_ending
	if (
		network_enabled
		and network_is_host
		and game_state.player.ending_turn
		and game_state.player.pending_choice == null
		and not game_state.player.cleanup_in_progress
	):
		_complete_network_player_cleanup(local_player_index)
	_refresh_ui()
	var discard_gains := _multiset_difference(_card_ids_from_zone(game_state.player.discard_pile), discard_before)
	if not chosen_gain_ids.is_empty():
		_queue_gain_flights(chosen_gain_ids, gain_destination)
		# A gain-to-discard choice is already represented by its explicit flight.
		for card_id in chosen_gain_ids:
			discard_gains.erase(card_id)
	_queue_gain_flights(discard_gains)
	if network_enabled and network_is_host:
		_broadcast_network_snapshot()
	var drawn_count := maxi(0, game_state.player.hand.size() - hand_before)
	if drawn_count > 0:
		call_deferred("_animate_draw_cards", drawn_count)


func _on_hand_card_pressed(card: CardDefinition) -> void:
	_restore_local_network_view()
	if _respite_active():
		return
	if network_enabled and not _can_interact_with_local_player():
		return
	if _is_network_client():
		_send_network_client_request("request_play_card", {"card_id": card.id})
		return
	var source_button := _find_card_button(hand_container, card.id)
	var discard_before := _card_ids_from_zone(game_state.player.discard_pile)
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
	if played:
		_queue_gain_flights(_multiset_difference(_card_ids_from_zone(game_state.player.discard_pile), discard_before))
	if played and ghost != null:
		_animate_moving_card(
			ghost,
			play_area_panel.get_global_rect().get_center(),
			CARD_MOVE_SECONDS,
			Vector2(0.48, 0.48)
		)
	if played and card.draw_cards > 0:
		call_deferred("_animate_draw_cards", card.draw_cards)
	if played and network_enabled and network_is_host:
		_broadcast_network_snapshot()
	if played and game_state.consume_end_turn_request():
		_end_turn_from_card(local_player_index)


func _end_turn_from_card(player_index: int) -> void:
	# A card asked to end the player's turn. Route through the same paths as the
	# End Turn button so cooldowns and turn-passing behave identically.
	if network_enabled and network_is_host:
		_start_network_player_cooldown(player_index)
		_refresh_ui()
		_queue_network_ui_refresh()
		_broadcast_network_snapshot()
	elif not network_enabled:
		turn_manager.end_turn()
		_refresh_ui()


func _on_market_card_pressed(card: CardDefinition) -> void:
	_restore_local_network_view()
	if _respite_active():
		return
	if network_enabled and not _can_interact_with_local_player():
		return
	if _is_network_client():
		_send_network_client_request("request_buy_card", {"card_id": card.id})
		return
	if not _can_buy_card(card):
		push_warning("Card cannot be bought right now: %s" % card.card_name)
		return
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
	if bought and network_enabled and network_is_host:
		_broadcast_network_snapshot()


func _on_end_turn_pressed() -> void:
	_restore_local_network_view()
	if _respite_active():
		# During the opening timer the button reads READY and skips the wait.
		_on_respite_ready_pressed()
		return
	if direct_hand_choice and _choice_is_hand_trash(current_choice) and current_choice != null:
		if current_choice.is_valid_selection(selected_choice_tokens):
			_submit_choice(selected_choice_tokens.duplicate())
		return
	if game_state.has_pending_choice() or not _can_control_active_player():
		return
	_play_ui_sound("end_turn")
	if _is_network_client():
		_send_network_client_request("request_end_turn")
		return
	if network_enabled and network_is_host:
		_start_network_player_cooldown(local_player_index)
		_refresh_ui()
		_queue_network_ui_refresh()
		_broadcast_network_snapshot()
		return
	turn_manager.end_turn()
	_refresh_ui()


func _on_turn_completed(game_is_over: bool) -> void:
	_refresh_ui()
	_animate_cleanup_cards(pending_cleanup_ghosts)
	pending_cleanup_ghosts.clear()
	if game_is_over:
		_show_final_score(turn_manager.final_score)
	elif not game_state.multiplayer_enabled:
		call_deferred("_animate_draw_cards", game_state.player.hand.size())
	if network_enabled and network_is_host:
		_broadcast_network_snapshot()


func _on_turn_cleanup_started() -> void:
	pending_cleanup_ghosts = _capture_cleanup_cards()


func _on_active_player_changed(_player_index: int) -> void:
	_refresh_ui()


func _on_home_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_screen(true)


func _on_home_new_game_pressed() -> void:
	_play_ui_sound("button_click", NEW_GAME_SOUND_OFFSET_DB)
	_start_new_game(true)


func _on_home_continue_pressed() -> void:
	if not has_active_game:
		return
	_play_ui_sound("button_click")
	_hide_home_screen()


func _on_home_resign_pressed() -> void:
	if not has_active_game:
		return
	_play_ui_sound("button_click")
	_resign_game()


func _resign_game() -> void:
	# Abandon the current game. In a network lobby this also leaves/closes the
	# room (the relay notifies any seated guests), so it never leaves a zombie
	# table behind. Drops the player back to the main menu.
	_disconnect_network()
	has_active_game = false
	turn_manager.game_over = false
	respite_remaining = 0.0
	_hide_end_game_overlay()
	_hide_choice_overlay()
	_clear_animation_layer()
	end_turn_button.disabled = true
	lobby_pending_mode = "host"
	_hide_home_modals()
	_refresh_home_controls()
	_show_home_screen(false)


func _on_home_multiplayer_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_tab("multiplayer")


func _on_home_create_lobby_pressed() -> void:
	_play_ui_sound("button_click")
	lobby_pending_mode = "host"
	_show_home_tab("lobby")


func _on_home_join_lobby_pressed() -> void:
	_play_ui_sound("button_click")
	lobby_pending_mode = "join"
	_show_home_tab("lobby")


func _on_home_create_online_pressed() -> void:
	_play_ui_sound("button_click")
	lobby_pending_mode = "host_online"
	game_state.turn_based_enabled = false
	online_relay_lobby_code = ""
	if home_lobby_address_input != null:
		home_lobby_address_input.text = ""
	_show_home_tab("lobby")


func _on_home_join_online_pressed() -> void:
	_play_ui_sound("button_click")
	lobby_pending_mode = "join_online"
	game_state.turn_based_enabled = false
	online_relay_lobby_code = ""
	if home_lobby_address_input != null:
		home_lobby_address_input.text = ""
	_show_home_tab("lobby")


func _on_home_settings_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_tab("settings")


func _on_home_kingdoms_pressed() -> void:
	_play_ui_sound("button_click")
	# Remember whether the kingdom browser was opened from the lobby so
	# closing it returns there instead of dumping the player to the main menu.
	kingdom_return_tab = (
		"lobby"
		if home_lobby_panel != null and home_lobby_panel.visible
		else ""
	)
	_show_home_tab("kingdoms")


func _on_home_back_pressed() -> void:
	_play_ui_sound("button_click")
	_hide_home_modals()


func _on_kingdoms_close_pressed() -> void:
	_play_ui_sound("button_click")
	_close_kingdom_browser()


func _close_kingdom_browser() -> void:
	if home_kingdoms_panel != null:
		home_kingdoms_panel.hide()
	if not kingdom_return_tab.is_empty():
		var return_tab := kingdom_return_tab
		kingdom_return_tab = ""
		_show_home_tab(return_tab)
		return
	if not _home_modal_is_visible():
		_set_menu_overlay_active(false)


func _set_menu_overlay_active(active: bool) -> void:
	if menu_backdrop != null:
		menu_backdrop.visible = active
	if home_menu_root != null:
		home_menu_root.visible = not active


func _input(event: InputEvent) -> void:
	if _is_audio_unlock_event(event):
		_request_background_music_playback()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _home_modal_is_visible():
		_hide_home_modals()
		get_viewport().set_input_as_handled()


func _home_modal_is_visible() -> bool:
	return (
		(home_settings_panel != null and home_settings_panel.visible)
		or (home_kingdoms_panel != null and home_kingdoms_panel.visible)
		or (home_multiplayer_panel != null and home_multiplayer_panel.visible)
		or (home_lobby_panel != null and home_lobby_panel.visible)
	)


func _hide_home_modals() -> void:
	# Escaping the kingdom browser that was opened from the lobby goes back to
	# the lobby; a second escape then closes the modals for real.
	if (
		home_kingdoms_panel != null
		and home_kingdoms_panel.visible
		and not kingdom_return_tab.is_empty()
	):
		var return_tab := kingdom_return_tab
		kingdom_return_tab = ""
		_show_home_tab(return_tab)
		return
	kingdom_return_tab = ""
	if home_settings_panel != null:
		home_settings_panel.hide()
	if home_kingdoms_panel != null:
		home_kingdoms_panel.hide()
	if home_multiplayer_panel != null:
		home_multiplayer_panel.hide()
	if home_lobby_panel != null:
		home_lobby_panel.hide()
	_set_menu_overlay_active(false)


func _is_audio_unlock_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false


func _on_home_audio_toggled(enabled: bool) -> void:
	audio_enabled = enabled
	if enabled:
		_play_ui_sound("button_click")


func _on_home_music_toggled(enabled: bool) -> void:
	music_enabled = enabled
	if enabled:
		_request_background_music_playback()
	else:
		_refresh_background_music()
	_play_ui_sound("button_click")


func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	# Play a click at the new level so the setting is audible while dragging.
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


func _on_background_music_changed(value: float) -> void:
	background_music_volume = clampf(value, 0.0, 1.0)
	_refresh_background_music()


func _on_end_turn_cooldown_changed(value: float) -> void:
	if not _can_edit_table_settings():
		if end_turn_cooldown_slider != null:
			end_turn_cooldown_slider.set_value_no_signal(game_state.end_turn_cooldown_seconds)
		if lobby_cooldown_slider != null:
			lobby_cooldown_slider.set_value_no_signal(game_state.end_turn_cooldown_seconds)
		return
	game_state.end_turn_cooldown_seconds = clampf(value, 0.5, 10.0)
	if end_turn_cooldown_slider != null:
		end_turn_cooldown_slider.set_value_no_signal(game_state.end_turn_cooldown_seconds)
	if lobby_cooldown_slider != null:
		lobby_cooldown_slider.set_value_no_signal(game_state.end_turn_cooldown_seconds)
	if network_enabled and network_is_host:
		_broadcast_network_snapshot()
	_refresh_lobby_panel()


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _on_settings_slider_value_changed(
	value: float,
	value_label: Label,
	display_mode: String
) -> void:
	_update_settings_slider_value(value, value_label, display_mode)


func _update_settings_slider_value(
	value: float,
	value_label: Label,
	display_mode: String
) -> void:
	if value_label == null:
		return
	match display_mode:
		"pct":
			value_label.text = "%d%%" % roundi(value * 100.0)
		"x":
			value_label.text = "%.1fx" % value
		"s":
			value_label.text = "%.1fs" % value
		_:
			value_label.text = "%.1f" % value


func _on_lobby_address_text_changed(new_text: String) -> void:
	# While typing a join code, keep it uppercase letters only, max 4. Setting
	# the text programmatically does not re-emit text_changed.
	if lobby_pending_mode != "join_online" or network_enabled:
		return
	var normalized := _normalize_online_lobby_code(new_text)
	if normalized != new_text and home_lobby_address_input != null:
		home_lobby_address_input.text = normalized
		home_lobby_address_input.caret_column = normalized.length()


func _is_seat_ready(index: int) -> bool:
	if not network_enabled:
		return true
	if index == 0 or network_table_open:
		return true
	if index == local_player_index and lobby_ready_sent:
		return true
	return network_ready_seats.has(index)


func _on_lobby_name_changed(new_text: String) -> void:
	player_display_name = new_text


func _on_name_submitted(_text: String) -> void:
	_commit_display_name()


func _on_name_focus_exited() -> void:
	_commit_display_name()


func _commit_display_name() -> void:
	if lobby_name_input != null:
		player_display_name = lobby_name_input.text
	_apply_local_player_name()
	_refresh_lobby_panel()
	_refresh_ui()


func _on_show_opponent_names_toggled(enabled: bool) -> void:
	show_opponent_names = enabled
	_play_ui_sound("button_click")
	_refresh_lobby_panel()
	_refresh_ui()


func _on_lobby_copy_pressed() -> void:
	if home_lobby_address_input != null:
		DisplayServer.clipboard_set(
			online_relay_lobby_code
			if network_mode == NETWORK_MODE_ONLINE and not online_relay_lobby_code.is_empty()
			else home_lobby_address_input.text
		)
	_play_ui_sound("button_click")


func _on_lobby_leave_pressed() -> void:
	_play_ui_sound("button_click")
	if network_enabled and (not has_active_game or not network_table_open):
		# Leaving an open-but-unstarted lobby really closes it (the relay tells
		# any seated guests), instead of leaving a zombie room behind.
		_disconnect_network()
		has_active_game = false
	lobby_pending_mode = "host"
	_show_home_tab("multiplayer")
	_refresh_home_controls()


func _on_lobby_start_pressed() -> void:
	_play_ui_sound("button_click")
	if network_enabled and not network_is_host:
		if (
			network_mode == NETWORK_MODE_ONLINE
			and not network_table_open
			and not lobby_ready_sent
		):
			# Guests can't start the table; the button tells the host they are
			# ready to play instead.
			lobby_ready_sent = true
			_send_online_signal("host", {"method": "lobby_ready"})
			_set_lobby_status("You're ready. Waiting for the host to start...")
		_refresh_lobby_panel()
		return
	if lobby_pending_mode == "join":
		_join_network_lobby()
	elif lobby_pending_mode == "join_online":
		_join_online_lobby()
	elif lobby_pending_mode == "host_online":
		if network_enabled and network_mode == NETWORK_MODE_ONLINE and has_active_game:
			network_table_open = true
			_start_respite()
			_hide_home_screen()
			_broadcast_network_snapshot()
		else:
			_host_online_lobby()
	elif game_state.turn_based_enabled:
		# Turn-based tables are a local pass-and-play variation: players share the
		# screen and take sequential turns, so no network server is started.
		_start_lobby_game(lobby_max_players)
	else:
		_host_network_lobby()


func _on_lobby_max_players_pressed(count: int) -> void:
	if not _can_edit_lobby_setup():
		_refresh_lobby_panel()
		return
	lobby_max_players = clampi(count, 2, NETWORK_MAX_PLAYERS)
	_refresh_lobby_panel()


func _on_lobby_turn_based_toggled(enabled: bool) -> void:
	if not _can_edit_lobby_setup():
		_refresh_lobby_panel()
		return
	if lobby_pending_mode == "host_online" or lobby_pending_mode == "join_online":
		game_state.turn_based_enabled = false
		_refresh_lobby_panel()
		return
	game_state.turn_based_enabled = enabled
	if lobby_cooldown_slider != null:
		# A turn-based table has no timer, so the cooldown control is irrelevant.
		lobby_cooldown_slider.editable = not enabled
		lobby_cooldown_slider.modulate = Color(1, 1, 1, 0.4 if enabled else 1.0)
	_refresh_lobby_panel()
	_refresh_home_controls()


func _on_kingdom_tab_pressed(kingdom: String) -> void:
	selected_home_kingdom = kingdom
	selected_home_kingdom_card_id = ""
	_play_ui_sound("button_click")
	_refresh_kingdom_tab()


func _on_kingdom_toggled(enabled: bool, kingdom: String) -> void:
	if not _can_edit_lobby_setup():
		_refresh_kingdom_tab()
		return
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


func _on_kingdom_card_hovered(card_id: String) -> void:
	selected_home_kingdom_card_id = card_id
	_refresh_kingdom_detail()


func _on_kingdom_card_toggled(enabled: bool, card_id: String) -> void:
	if not _can_edit_lobby_setup():
		_refresh_kingdom_tab()
		return
	selected_home_kingdom_card_id = card_id
	if game_state.card_catalog.has(card_id):
		var card: CardDefinition = game_state.card_catalog[card_id]
		selected_home_kingdom = game_state.get_card_kingdom(card)
	game_state.set_card_enabled_for_market(card_id, enabled)
	_refresh_kingdom_tab()


func _on_play_again_pressed() -> void:
	_play_ui_sound("button_click")
	_hide_end_game_overlay()
	_start_new_game(true)


func _on_end_game_home_pressed() -> void:
	_play_ui_sound("button_click")
	has_active_game = false
	_hide_end_game_overlay()
	_show_home_screen(true)


func _show_final_score(_score: int) -> void:
	# Kept for the existing turn/network call sites; the rich summary (and the
	# solo scoring-relic draft that precedes it) lives in _begin_end_game.
	_begin_end_game()


func _hide_end_game_overlay() -> void:
	end_game_overlay.hide()
	end_game_overlay.modulate.a = 1.0
	end_game_panel.scale = Vector2.ONE
	if summary_overlay != null:
		summary_overlay.visible = false
	if scoring_relic_overlay != null:
		scoring_relic_overlay.visible = false


func _begin_end_game() -> void:
	last_animation_event = "game_end"
	_play_ui_sound("game_end")
	var solo_needs_draft := (
		not game_state.multiplayer_enabled
		and game_state.player.scoring_relic.is_empty()
		and not RelicCatalog.get_scoring_pool().is_empty()
	)
	if solo_needs_draft:
		_show_scoring_relic_draft()
	else:
		_present_game_summary()


func _build_scoring_relic_overlay() -> void:
	scoring_relic_overlay = Control.new()
	scoring_relic_overlay.name = "ScoringRelicOverlay"
	scoring_relic_overlay.visible = false
	scoring_relic_overlay.z_index = 160
	scoring_relic_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scoring_relic_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scoring_relic_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.012, 0.006, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	scoring_relic_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	scoring_relic_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_parchment_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	layout.add_child(_create_parchment_title(
		"Scoring Relic",
		"The conquest is done. Claim a boon that rewards how you played."
	))

	scoring_relic_options_row = HBoxContainer.new()
	scoring_relic_options_row.name = "ScoringOptions"
	scoring_relic_options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	scoring_relic_options_row.add_theme_constant_override("separation", 16)
	layout.add_child(scoring_relic_options_row)


func _show_scoring_relic_draft() -> void:
	scoring_relic_offer = game_state.generate_scoring_relic_offer()
	for child in scoring_relic_options_row.get_children():
		child.queue_free()
	for relic_id in scoring_relic_offer:
		scoring_relic_options_row.add_child(_create_scoring_relic_option(relic_id))
	scoring_relic_overlay.visible = true


func _create_scoring_relic_option(relic_id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(236, 156)
	button.add_theme_stylebox_override("normal", _make_card_style(COLOR_WALNUT, COLOR_BRASS, 2))
	button.add_theme_stylebox_override(
		"hover", _make_card_style(COLOR_WALNUT.lightened(0.08), COLOR_BRASS.lightened(0.2), 2)
	)
	button.add_theme_stylebox_override(
		"pressed", _make_card_style(COLOR_WALNUT.lightened(0.12), COLOR_BRASS, 2)
	)
	button.pressed.connect(_on_scoring_relic_chosen.bind(relic_id))

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	button.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	pad.add_child(vbox)

	var name_label := Label.new()
	name_label.text = RelicCatalog.get_scoring_relic_name(relic_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", COLOR_BRASS)
	name_label.add_theme_font_size_override("font_size", 18)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = RelicCatalog.get_scoring_relic_description(relic_id)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	desc_label.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		desc_label.add_theme_font_override("font", body_font)
	vbox.add_child(desc_label)

	return button


func _on_scoring_relic_chosen(relic_id: String) -> void:
	_play_ui_sound("button_click")
	game_state.choose_scoring_relic(game_state.player, relic_id)
	turn_manager.final_score = game_state.calculate_score()
	turn_manager.final_scores = game_state.calculate_all_scores()
	scoring_relic_overlay.visible = false
	_present_game_summary()


func _build_summary_overlay() -> void:
	summary_overlay = Control.new()
	summary_overlay.name = "SummaryOverlay"
	summary_overlay.visible = false
	summary_overlay.z_index = 155
	summary_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	summary_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(summary_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.012, 0.006, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	summary_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	summary_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_card_style(COLOR_WALNUT_DARK, COLOR_BRASS, 2))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	margin.add_child(outer)

	summary_title_label = Label.new()
	summary_title_label.name = "SummaryTitle"
	summary_title_label.text = "CONQUEST COMPLETE"
	summary_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_title_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.15))
	summary_title_label.add_theme_font_size_override("font_size", 28)
	if title_font != null:
		summary_title_label.add_theme_font_override("font", title_font)
	outer.add_child(summary_title_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	summary_content = VBoxContainer.new()
	summary_content.name = "SummaryContent"
	summary_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_content.add_theme_constant_override("separation", 12)
	scroll.add_child(summary_content)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	outer.add_child(footer)
	var again := _create_parchment_button("SummaryPlayAgain", "PLAY AGAIN", true)
	again.pressed.connect(_on_play_again_pressed)
	footer.add_child(again)
	var home := _create_parchment_button("SummaryHome", "HOME", false)
	home.pressed.connect(_on_end_game_home_pressed)
	footer.add_child(home)


func _present_game_summary() -> void:
	for child in summary_content.get_children():
		child.queue_free()
	var is_solo := not game_state.multiplayer_enabled
	summary_title_label.text = "CONQUEST COMPLETE" if is_solo else "THE TABLE RESTS"

	var scores: Array = turn_manager.final_scores.duplicate()
	if scores.size() < game_state.players.size():
		scores = game_state.calculate_all_scores()

	var ranking: Array[int] = []
	for i in range(game_state.players.size()):
		ranking.append(i)
	ranking.sort_custom(func(a, b): return int(scores[a]) > int(scores[b]))

	if not is_solo and game_state.players.size() >= 2:
		summary_content.add_child(_build_podium(ranking, scores))

	for idx in ranking:
		summary_content.add_child(_build_summary_player_section(idx, int(scores[idx])))

	if not is_solo and game_state.players.size() >= 2:
		var prizes := _build_prizes_panel()
		if prizes != null:
			summary_content.add_child(prizes)

	summary_overlay.visible = true


func _summary_you_index() -> int:
	return local_player_index if network_enabled else game_state.active_player_index


func _deck_counts(target: PlayerState) -> Dictionary:
	var counts := {}
	var owned: Array[CardDefinition] = []
	owned.append_array(target.get_all_cards())
	owned.append_array(target.duration_hold)
	for card in owned:
		counts[card.id] = int(counts.get(card.id, 0)) + 1
	return counts


func _build_summary_player_section(index: int, score: int) -> PanelContainer:
	var target := game_state.players[index]
	var section := PanelContainer.new()
	section.add_theme_stylebox_override(
		"panel", _make_flat_card_style(COLOR_WALNUT, COLOR_BRASS.darkened(0.25), 1)
	)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_bottom", 12)
	section.add_child(pad)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	pad.add_child(body)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	body.add_child(header)
	var name_label := Label.new()
	var name_text := _display_name_for(index)
	if index == _summary_you_index():
		name_text += "  (you)"
	name_label.text = name_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	name_label.add_theme_font_size_override("font_size", 18)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	header.add_child(name_label)
	var score_label := Label.new()
	score_label.text = "%d VP" % score
	score_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.15))
	score_label.add_theme_font_size_override("font_size", 20)
	if title_font != null:
		score_label.add_theme_font_override("font", title_font)
	header.add_child(score_label)

	var breakdown := game_state.calculate_score_breakdown(target)
	if breakdown.is_empty():
		var none_label := Label.new()
		none_label.text = "No victory points scored."
		none_label.add_theme_color_override("font_color", COLOR_PARCHMENT_MUTED)
		none_label.add_theme_font_size_override("font_size", 12)
		if body_font != null:
			none_label.add_theme_font_override("font", body_font)
		body.add_child(none_label)
	else:
		for row in breakdown:
			body.add_child(_build_breakdown_row(str(row.get("label", "")), int(row.get("points", 0))))

	var deck_header := Label.new()
	deck_header.text = "DECK"
	deck_header.add_theme_color_override("font_color", COLOR_BRASS.darkened(0.1))
	deck_header.add_theme_font_size_override("font_size", 11)
	if title_font != null:
		deck_header.add_theme_font_override("font", title_font)
	body.add_child(deck_header)
	body.add_child(_build_deck_chip_flow(target))
	return section


func _build_breakdown_row(label_text: String, points: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	name_label.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		name_label.add_theme_font_override("font", body_font)
	row.add_child(name_label)
	var pts := Label.new()
	pts.text = "%+d" % points
	pts.add_theme_color_override("font_color", COLOR_BRASS)
	pts.add_theme_font_size_override("font_size", 13)
	if body_bold_font != null:
		pts.add_theme_font_override("font", body_bold_font)
	row.add_child(pts)
	return row


func _build_deck_chip_flow(target: PlayerState) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	var counts := _deck_counts(target)
	var ids := counts.keys()
	ids.sort_custom(func(a, b):
		if int(counts[a]) != int(counts[b]):
			return int(counts[a]) > int(counts[b])
		return str(a) < str(b)
	)
	for card_id in ids:
		if not game_state.card_catalog.has(card_id):
			continue
		var card: CardDefinition = game_state.card_catalog[card_id]
		flow.add_child(_build_deck_chip(card.card_name, int(counts[card_id])))
	return flow


func _build_deck_chip(card_name: String, count: int) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override(
		"panel", _make_flat_card_style(COLOR_WALNUT_DARK, COLOR_BRASS.darkened(0.4), 1)
	)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_top", 3)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_bottom", 3)
	chip.add_child(pad)
	var label := Label.new()
	label.text = "%s  x%d" % [card_name, count]
	label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	label.add_theme_font_size_override("font_size", 11)
	if body_font != null:
		label.add_theme_font_override("font", body_font)
	pad.add_child(label)
	return chip


func _build_podium(ranking: Array[int], scores: Array) -> Control:
	var wrap := CenterContainer.new()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	wrap.add_child(row)
	# Classic podium order: 2nd, 1st, 3rd. Heights and tints rank the columns.
	var slots := [1, 0, 2]
	var heights := [66, 96, 46]
	for slot_index in range(slots.size()):
		var place: int = slots[slot_index]
		if place >= ranking.size():
			continue
		var player_index: int = ranking[place]
		row.add_child(_build_podium_column(
			place + 1,
			_display_name_for(player_index),
			int(scores[player_index]),
			heights[slot_index]
		))
	return wrap


func _build_podium_column(place: int, name_text: String, score: int, height: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.custom_minimum_size = Vector2(120, 150)
	column.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	name_label.add_theme_font_size_override("font_size", 13)
	if body_font != null:
		name_label.add_theme_font_override("font", body_font)
	column.add_child(name_label)

	var score_label := Label.new()
	score_label.text = "%d VP" % score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_color_override("font_color", COLOR_BRASS.lightened(0.15))
	score_label.add_theme_font_size_override("font_size", 16)
	if title_font != null:
		score_label.add_theme_font_override("font", title_font)
	column.add_child(score_label)

	var pedestal := PanelContainer.new()
	pedestal.custom_minimum_size = Vector2(108, height)
	var tint := COLOR_BRASS if place == 1 else COLOR_WALNUT.lightened(0.12)
	pedestal.add_theme_stylebox_override("panel", _make_flat_card_style(tint, COLOR_BRASS, 2))
	var place_label := Label.new()
	place_label.text = str(place)
	place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	place_label.add_theme_color_override(
		"font_color", COLOR_WALNUT_DARK if place == 1 else COLOR_BRASS
	)
	place_label.add_theme_font_size_override("font_size", 24)
	if title_font != null:
		place_label.add_theme_font_override("font", title_font)
	pedestal.add_child(place_label)
	column.add_child(pedestal)
	return column


func _build_prizes_panel() -> Control:
	var awards := _compute_fun_awards()
	if awards.is_empty():
		return null
	var section := PanelContainer.new()
	section.add_theme_stylebox_override(
		"panel", _make_flat_card_style(COLOR_WALNUT, COLOR_BRASS.darkened(0.25), 1)
	)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_bottom", 12)
	section.add_child(pad)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	pad.add_child(body)

	var header := Label.new()
	header.text = "TABLE HONOURS  (just for fun)"
	header.add_theme_color_override("font_color", COLOR_BRASS.darkened(0.1))
	header.add_theme_font_size_override("font_size", 12)
	if title_font != null:
		header.add_theme_font_override("font", title_font)
	body.add_child(header)

	for award in awards:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var title_label := Label.new()
		title_label.text = str(award.get("title", ""))
		title_label.add_theme_color_override("font_color", COLOR_BRASS)
		title_label.add_theme_font_size_override("font_size", 13)
		if body_bold_font != null:
			title_label.add_theme_font_override("font", body_bold_font)
		row.add_child(title_label)
		var who := Label.new()
		who.text = str(award.get("detail", ""))
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		who.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
		who.add_theme_font_size_override("font_size", 13)
		if body_font != null:
			who.add_theme_font_override("font", body_font)
		row.add_child(who)
		body.add_child(row)
	return section


func _compute_fun_awards() -> Array:
	var pool: Array = []
	var candidates := [
		{"title": "Most Attacked", "unit": "hits", "metric": "attacked"},
		{"title": "Biggest Hoard", "unit": "cards", "metric": "deck"},
		{"title": "Ruthless Cull", "unit": "trashed", "metric": "trash"},
		{"title": "Green Crown", "unit": "victory cards", "metric": "victory"},
		{"title": "Relic Keeper", "unit": "relics", "metric": "relics"},
	]
	for candidate in candidates:
		var best_index := -1
		var best_value := 0
		for index in range(game_state.players.size()):
			var value := _award_metric(str(candidate["metric"]), game_state.players[index])
			if value > best_value:
				best_value = value
				best_index = index
		if best_index >= 0:
			pool.append({
				"title": str(candidate["title"]),
				"detail": "%s  (%d %s)" % [
					_display_name_for(best_index), best_value, str(candidate["unit"])
				],
			})
	pool.shuffle()
	return pool.slice(0, mini(3, pool.size()))


func _award_metric(metric: String, target: PlayerState) -> int:
	match metric:
		"attacked":
			return target.times_attacked
		"deck":
			return target.get_all_cards().size() + target.duration_hold.size()
		"trash":
			return target.trash_pile.size()
		"victory":
			var total := 0
			for card in target.get_all_cards():
				if card.card_type == "victory":
					total += 1
			return total
		"relics":
			return target.relics.size()
	return 0


func _display_name_for(index: int) -> String:
	if index < 0 or index >= game_state.players.size():
		return "Player %d" % (index + 1)
	if network_enabled and not show_opponent_names and index != local_player_index:
		return "Player %d" % (index + 1)
	var chosen := game_state.players[index].player_name.strip_edges()
	if chosen.is_empty():
		return "Player %d" % (index + 1)
	return chosen


func _local_control_seat() -> int:
	return local_player_index if network_enabled else 0


func _apply_local_player_name(broadcast := true) -> void:
	var seat := _local_control_seat()
	var trimmed := player_display_name.strip_edges()
	var resolved := trimmed if not trimmed.is_empty() else "Player %d" % (seat + 1)
	if seat >= 0 and seat < game_state.players.size():
		game_state.players[seat].player_name = resolved
	if not broadcast:
		return
	if network_enabled and not network_is_host:
		_send_network_client_request("set_name", {"name": resolved})
	elif network_enabled and network_is_host:
		_broadcast_network_snapshot()


func _find_card_button(container: Container, card_id: String) -> Button:
	for child in container.get_children():
		if child.get_meta("card_id", "") == card_id:
			return child as Button
		if child is Container:
			var nested := _find_card_button(child as Container, card_id)
			if nested != null:
				return nested
	return null
