extends Control

const CARD_DATA_PATH := "res://data/cards/starter_cards.json"

const HAND_PLAYABLE := "hand_playable"
const HAND_UNPLAYABLE := "hand_unplayable"
const MARKET_AFFORDABLE := "market_affordable"
const MARKET_UNAFFORDABLE := "market_unaffordable"
const MARKET_NEUTRAL := "market_neutral"
const CARD_HOVER_SCALE := Vector2(1.03, 1.03)
const CARD_NORMAL_SCALE := Vector2.ONE
const HOVER_ANIMATION_SECONDS := 0.08
const CARD_MOVE_SECONDS := 0.18
const CARD_DRAW_SECONDS := 0.16
const CLEANUP_SECONDS := 0.2
const TABLE_SCALE := 0.667
const TOP_BAR_HEIGHT := 52.0
const BOTTOM_BAND_HEIGHT := 248.0
const CARD_FACE_SIZE := Vector2(123, 165)
const PLAY_AREA_PANEL_HEIGHT := 36.0
const PLAY_AREA_CONTENT_HEIGHT := 28.0
const CARD_ART_HEIGHT := 85.0
const HAND_CARD_ART_HEIGHT := 91.0
const HUD_LEDGER_WIDTH := 158.0
const RIGHT_DOCK_WIDTH := 202.0
const END_TURN_BUTTON_WIDTH := 188.0
const PILE_FACE_SIZE := Vector2(105, 145)
const PREVIEW_SIZE := Vector2(320, 540)
const PREVIEW_ART_HEIGHT := 216.0
const PREVIEW_EDGE_MARGIN := 16.0
const SHORT_RULE_BREAK_LIMIT := 72
const HOME_ART_PATH := "res://assets/cards/sunspire_monument.png"
const CARD_RULE_SIDE_MARGIN := 9
const CARD_RULE_TOP_MARGIN := 1
const CARD_RULE_BOTTOM_MARGIN := 7
const NETWORK_PORT := 27041
const NETWORK_DEFAULT_ADDRESS := "127.0.0.1"
const NETWORK_MAX_PLAYERS := 4

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
const COLOR_SLATE := Color("#5c8fc2")
const COLOR_INK := Color("#30251d")
const COLOR_UNAVAILABLE := Color("#77756f")
const COLOR_TREASURY_CARPET := Color("#682b37")
const COLOR_BARRACKS_CARPET := Color("#263f5b")
const COLOR_ESTATES_CARPET := Color("#28503b")
const COLOR_RESOURCE_ACCENT := Color("#f0bd58")
const COLOR_ACTION_ACCENT := Color("#7db6e8")
const COLOR_VICTORY_ACCENT := Color("#e08aa2")
const COLOR_CURSE_ACCENT := Color("#b49ad9")

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
}
const ICON_PATHS := {
	"coin": "res://assets/icons/ui/coin.png",
	"action": "res://assets/icons/ui/action.png",
	"buy": "res://assets/icons/ui/buy.png",
	"deck": "res://assets/icons/ui/deck.png",
	"discard": "res://assets/icons/ui/discard.png",
	"victory": "res://assets/icons/ui/victory.png",
}
const SOUND_PATHS := {
	"button_click": "res://assets/audio/ui/button_click.ogg",
	"play_card": "res://assets/audio/ui/play_card.ogg",
	"buy_card": "res://assets/audio/ui/buy_card.ogg",
	"end_turn": "res://assets/audio/ui/end_turn.ogg",
	"draw": "res://assets/audio/ui/draw.ogg",
	"discard": "res://assets/audio/ui/discard.ogg",
	"game_end": "res://assets/audio/ui/game_end.ogg",
}
const BACKGROUND_MUSIC_PATH := "res://assets/audio/sunspire_court_loop.wav"
const BACKGROUND_MUSIC_VOLUME_DB := 0.0

var game_state := GameState.new()
var turn_manager := TurnManager.new()
var title_font: Font
var body_font: Font
var body_bold_font: Font
var ui_textures: Dictionary = {}
var icon_textures: Dictionary = {}
var ui_sound_players: Dictionary = {}
var background_music_player: AudioStreamPlayer
var background_music_started_from_user_gesture := false
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
var top_bar: PanelContainer
var market_helper_label: Label
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
var pending_cleanup_ghosts: Array[Control] = []
var home_overlay: Control
var home_new_game_button: Button
var home_continue_button: Button
var home_create_lobby_button: Button
var home_join_lobby_button: Button
var home_lobby_address_input: LineEdit
var home_lobby_status_label: Label
var player_status_label: Label
var home_settings_panel: VBoxContainer
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
var local_player_index := 0
var network_peer_to_player: Dictionary = {}
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
	_apply_imported_theme()
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
	_refresh_ui()
	call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _host_network_lobby() -> void:
	if game_state.card_catalog.is_empty() or not game_state.has_enough_market_candidates():
		_refresh_home_controls()
		return
	_disconnect_network()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(NETWORK_PORT, NETWORK_MAX_PLAYERS - 1)
	if error != OK:
		_set_lobby_status("Could not host lobby on port %d." % NETWORK_PORT)
		return
	multiplayer.multiplayer_peer = peer
	network_enabled = true
	network_is_host = true
	local_player_index = 0
	network_peer_to_player = {1: 0}
	_start_lobby_game(NETWORK_MAX_PLAYERS)
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
	local_player_index = 1
	has_active_game = false
	_set_lobby_status("Connecting to %s:%d..." % [address, NETWORK_PORT])
	_refresh_home_controls()
	_queue_network_ui_refresh()


func _disconnect_network() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	network_enabled = false
	network_is_host = false
	local_player_index = 0
	network_peer_to_player.clear()


func _set_lobby_status(message: String) -> void:
	if home_lobby_status_label != null:
		home_lobby_status_label.text = message


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
	if not network_enabled:
		return true
	if game_state.players.is_empty():
		return false
	_restore_local_network_view()
	return _can_control_active_player()


func _player_index_for_peer(peer_id: int) -> int:
	if peer_id == 1:
		return 0
	return int(network_peer_to_player.get(peer_id, -1))


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


func _on_network_peer_disconnected(peer_id: int) -> void:
	if network_is_host:
		network_peer_to_player.erase(peer_id)
		_set_lobby_status("Player disconnected. Hosting remains open.")


func _on_network_connected_to_server() -> void:
	network_enabled = true
	network_is_host = false
	_set_lobby_status("Connected. Waiting for lobby state...")


func _next_open_network_player_index() -> int:
	for player_index in range(1, NETWORK_MAX_PLAYERS):
		if not network_peer_to_player.values().has(player_index):
			return player_index
	return -1


@rpc("authority", "call_remote", "reliable")
func _rpc_set_local_player_index(player_index: int) -> void:
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
	game_state.draw_cards(5)
	_restore_local_network_view()
	if player_index == local_player_index:
		_animate_cleanup_cards(pending_cleanup_ghosts)
		pending_cleanup_ghosts.clear()
		call_deferred("_animate_draw_cards", game_state.player.hand.size())


func _broadcast_network_snapshot() -> void:
	if not network_enabled or not network_is_host:
		return
	rpc("_rpc_apply_network_snapshot", _create_network_snapshot())
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
			"discard": _card_ids_from_zone(game_player.discard_pile),
			"trash": _card_ids_from_zone(game_player.trash_pile),
			"coins": game_player.coins,
			"actions": game_player.actions,
			"buys": game_player.buys,
			"cooldown_reduction": game_player.end_turn_cooldown_reduction,
			"turn_flags": _serialize_turn_flags(game_player.turn_flags),
			"pending_choice": _serialize_choice(game_player.pending_choice),
			"cleanup_in_progress": game_player.cleanup_in_progress,
			"ending_turn": game_player.ending_turn,
			"cooldown_remaining": game_player.cooldown_remaining,
			"cooldown_duration": game_player.cooldown_duration,
		})
	return {
		"players": player_snapshots,
		"active_player_index": local_player_index,
		"multiplayer_enabled": game_state.multiplayer_enabled,
		"market": _card_ids_from_zone(game_state.market),
		"supply": game_state.supply_piles.duplicate(true),
		"turn": {
			"turn_number": turn_manager.turn_number,
			"game_over": turn_manager.game_over,
			"final_score": turn_manager.final_score,
			"final_scores": turn_manager.final_scores.duplicate(),
		},
	}


func _card_ids_from_zone(zone: Array[CardDefinition]) -> Array[String]:
	var card_ids: Array[String] = []
	for card in zone:
		if card != null:
			card_ids.append(card.id)
	return card_ids


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
		"candidates": candidates,
	}


@rpc("authority", "call_remote", "reliable")
func _rpc_apply_network_snapshot(snapshot: Dictionary) -> void:
	if network_is_host:
		return
	_apply_network_snapshot(snapshot)


func _apply_network_snapshot(snapshot: Dictionary) -> void:
	game_state.players.clear()
	for player_data in snapshot.get("players", []):
		var synced_player := PlayerState.new()
		synced_player.player_name = str(player_data.get("name", "Player"))
		synced_player.turn_number = int(player_data.get("turn_number", 1))
		synced_player.draw_pile = _cards_from_ids(player_data.get("draw", []))
		synced_player.hand = _cards_from_ids(player_data.get("hand", []))
		synced_player.play_area = _cards_from_ids(player_data.get("play", []))
		synced_player.discard_pile = _cards_from_ids(player_data.get("discard", []))
		synced_player.trash_pile = _cards_from_ids(player_data.get("trash", []))
		synced_player.coins = int(player_data.get("coins", 0))
		synced_player.actions = int(player_data.get("actions", 1))
		synced_player.buys = int(player_data.get("buys", 1))
		synced_player.end_turn_cooldown_reduction = float(
			player_data.get("cooldown_reduction", 0.0)
		)
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

	has_active_game = true
	_hide_home_screen()
	_sync_choice_overlay_from_network()
	_refresh_ui()
	_queue_network_ui_refresh()
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
	var player_index := _player_index_for_peer(multiplayer.get_remote_sender_id())
	if not network_is_host or player_index < 0:
		return
	_set_authoritative_player(player_index)
	var card := _find_card_in_active_hand(card_id)
	if card != null and game_state.play_card(card):
		_restore_local_network_view()
		_broadcast_network_snapshot()
	else:
		_restore_local_network_view()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_buy_card(card_id: String) -> void:
	var player_index := _player_index_for_peer(multiplayer.get_remote_sender_id())
	if not network_is_host or player_index < 0:
		return
	_set_authoritative_player(player_index)
	var card: CardDefinition = game_state.card_catalog.get(card_id) as CardDefinition
	if card != null and game_state.buy_card(card):
		_restore_local_network_view()
		_broadcast_network_snapshot()
	else:
		_restore_local_network_view()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_end_turn() -> void:
	var player_index := _player_index_for_peer(multiplayer.get_remote_sender_id())
	if not network_is_host or player_index < 0:
		return
	_start_network_player_cooldown(player_index)
	_broadcast_network_snapshot()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_choice(raw_tokens: Array) -> void:
	var player_index := _player_index_for_peer(multiplayer.get_remote_sender_id())
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
		var music_stream := load(BACKGROUND_MUSIC_PATH) as AudioStream
		if music_stream != null:
			if music_stream is AudioStreamWAV:
				var wav_stream := music_stream as AudioStreamWAV
				wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			background_music_player = AudioStreamPlayer.new()
			background_music_player.name = "BackgroundMusic"
			background_music_player.stream = music_stream
			background_music_player.volume_db = BACKGROUND_MUSIC_VOLUME_DB
			add_child(background_music_player)
			_refresh_background_music()


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

	root_margin.add_theme_constant_override("margin_left", 4)
	root_margin.add_theme_constant_override("margin_top", 4)
	root_margin.add_theme_constant_override("margin_right", 4)
	root_margin.add_theme_constant_override("margin_bottom", 4)
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

	# Left dock: compact Coins / Actions / Buys ledger.
	coin_stat.reparent(left_stats)
	action_stat.reparent(left_stats)
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
	pile_hand_row.add_theme_constant_override("separation", 8)
	hand_column.add_child(pile_hand_row)

	deck_stat.reparent(pile_hand_row)
	hand_panel.reparent(pile_hand_row)
	discard_stat.reparent(pile_hand_row)
	_configure_physical_pile(deck_stat, deck_label, false)
	_configure_physical_pile(discard_stat, discard_label, true)

	hand_panel.custom_minimum_size = Vector2(0, 184)
	hand_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_container.add_theme_constant_override("separation", -9)
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER

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


func _configure_stat_row(stat: VBoxContainer, accent: Color) -> void:
	stat.custom_minimum_size = Vector2(0, 66)
	stat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stat.add_theme_constant_override("separation", 0)
	var title := stat.find_child("Title", true, false) as Label
	var value := stat.find_child("Value", true, false) as Label
	var value_row := value.get_parent() as HBoxContainer if value != null else null
	var icon := stat.find_child("Icon", true, false) as TextureRect
	if title != null:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.add_theme_color_override("font_color", COLOR_BRASS)
		title.add_theme_font_size_override("font_size", 10)
		if title_font != null:
			title.add_theme_font_override("font", title_font)
	if value_row != null:
		value_row.alignment = BoxContainer.ALIGNMENT_END
		value_row.add_theme_constant_override("separation", 6)
	if icon != null:
		icon.custom_minimum_size = Vector2(18, 18)
		icon.modulate = accent
	if value != null:
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	stat.add_theme_constant_override("separation", 3)

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
	value_label.add_theme_font_size_override("font_size", 15)
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
		var emblem := Label.new()
		emblem.name = "Sunburst"
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emblem.text = "*"
		emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emblem.add_theme_color_override("font_color", COLOR_BRASS)
		emblem.add_theme_font_size_override("font_size", 40)
		if title_font != null:
			emblem.add_theme_font_override("font", title_font)
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
	brand_row.custom_minimum_size = Vector2(370, 0)
	brand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_row.add_theme_constant_override("separation", 10)
	row.add_child(brand_row)

	var star := Label.new()
	star.name = "Star"
	star.text = "*"
	star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star.add_theme_color_override("font_color", COLOR_BRASS)
	star.add_theme_font_size_override("font_size", 24)
	if title_font != null:
		star.add_theme_font_override("font", title_font)
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

	var base_pill := PanelContainer.new()
	base_pill.name = "BaseKingdomPill"
	base_pill.custom_minimum_size = Vector2(112, 26)
	base_pill.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color(0, 0, 0, 0), Color(0.835, 0.667, 0.314, 0.45), 7)
	)
	brand_row.add_child(base_pill)
	var pill_label := Label.new()
	pill_label.text = "BASE KINGDOM"
	pill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill_label.add_theme_color_override("font_color", COLOR_BRASS)
	pill_label.add_theme_font_size_override("font_size", 9)
	if title_font != null:
		pill_label.add_theme_font_override("font", title_font)
	base_pill.add_child(pill_label)

	row.add_child(_create_relics_rail())

	var right_row := HBoxContainer.new()
	right_row.name = "RightActions"
	right_row.custom_minimum_size = Vector2(250, 0)
	right_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_row.alignment = BoxContainer.ALIGNMENT_END
	right_row.add_theme_constant_override("separation", 8)
	row.add_child(right_row)

	bazaar_button = Button.new()
	bazaar_button.name = "BazaarButton"
	bazaar_button.custom_minimum_size = Vector2(156, 38)
	bazaar_button.text = "THE BAZAAR\nopens between rounds"
	bazaar_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bazaar_button.disabled = true
	bazaar_button.add_theme_font_size_override("font_size", 11)
	bazaar_button.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	bazaar_button.add_theme_color_override("font_disabled_color", COLOR_PARCHMENT_LIGHT)
	bazaar_button.add_theme_stylebox_override("normal", _make_top_button_style(false))
	bazaar_button.add_theme_stylebox_override("disabled", _make_top_button_style(false))
	right_row.add_child(bazaar_button)

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
	rail.custom_minimum_size = Vector2(278, 42)
	rail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rail.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color(0.047, 0.031, 0.02, 0.55), Color(0.835, 0.667, 0.314, 0.24), 13)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 5)
	rail.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var label := Label.new()
	label.text = "RELICS"
	label.add_theme_color_override("font_color", COLOR_BRASS)
	label.add_theme_font_size_override("font_size", 9)
	if title_font != null:
		label.add_theme_font_override("font", title_font)
	row.add_child(label)

	for index in range(4):
		row.add_child(_create_relic_slot(index < 2, index))
	return rail


func _create_relic_slot(filled: bool, index: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.name = "RelicSlot%d" % (index + 1)
	slot.custom_minimum_size = Vector2(30, 30)
	slot.add_theme_stylebox_override(
		"panel",
		_make_relic_slot_style(filled)
	)
	var glyph := Label.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.text = "*" if filled else "+"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_color_override(
		"font_color",
		Color("#3a2410") if filled else Color(0.835, 0.667, 0.314, 0.5)
	)
	glyph.add_theme_font_size_override("font_size", 15 if filled else 13)
	if title_font != null:
		glyph.add_theme_font_override("font", title_font)
	slot.add_child(glyph)
	return slot


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

	home_create_lobby_button = _create_home_menu_button("CREATE LOBBY")
	home_create_lobby_button.name = "CreateLobbyButton"
	home_create_lobby_button.pressed.connect(_on_home_create_lobby_pressed)
	button_stack.add_child(home_create_lobby_button)

	home_lobby_address_input = LineEdit.new()
	home_lobby_address_input.name = "LobbyAddress"
	home_lobby_address_input.text = NETWORK_DEFAULT_ADDRESS
	home_lobby_address_input.placeholder_text = "Host IP address"
	home_lobby_address_input.custom_minimum_size = Vector2(310, 38)
	home_lobby_address_input.add_theme_font_size_override("font_size", 14)
	if body_font != null:
		home_lobby_address_input.add_theme_font_override("font", body_font)
	button_stack.add_child(home_lobby_address_input)

	home_join_lobby_button = _create_home_menu_button("JOIN LOBBY")
	home_join_lobby_button.name = "JoinLobbyButton"
	home_join_lobby_button.pressed.connect(_on_home_join_lobby_pressed)
	button_stack.add_child(home_join_lobby_button)

	var settings_button := _create_home_menu_button("SETTINGS")
	settings_button.name = "SettingsButton"
	settings_button.pressed.connect(_on_home_settings_pressed)
	button_stack.add_child(settings_button)

	var kingdoms_button := _create_home_menu_button("KINGDOMS")
	kingdoms_button.name = "KingdomsButton"
	kingdoms_button.pressed.connect(_on_home_kingdoms_pressed)
	button_stack.add_child(kingdoms_button)

	home_lobby_status_label = Label.new()
	home_lobby_status_label.name = "LobbyStatus"
	home_lobby_status_label.text = "Host or join a direct-IP 2-player table."
	home_lobby_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home_lobby_status_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.08))
	home_lobby_status_label.add_theme_font_size_override("font_size", 12)
	if body_font != null:
		home_lobby_status_label.add_theme_font_override("font", body_font)
	button_stack.add_child(home_lobby_status_label)

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
	home_kingdoms_panel.anchor_left = 0.5
	home_kingdoms_panel.anchor_top = 0.5
	home_kingdoms_panel.anchor_right = 0.5
	home_kingdoms_panel.anchor_bottom = 0.5
	home_kingdoms_panel.offset_left = -450
	home_kingdoms_panel.offset_top = -304
	home_kingdoms_panel.offset_right = 450
	home_kingdoms_panel.offset_bottom = 304

	var browser_margin := MarginContainer.new()
	browser_margin.name = "Margin"
	browser_margin.add_theme_constant_override("margin_left", 12)
	browser_margin.add_theme_constant_override("margin_top", 10)
	browser_margin.add_theme_constant_override("margin_right", 12)
	browser_margin.add_theme_constant_override("margin_bottom", 12)
	home_kingdoms_panel.add_child(browser_margin)

	var outer_layout := VBoxContainer.new()
	outer_layout.name = "Layout"
	outer_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_layout.add_theme_constant_override("separation", 8)
	browser_margin.add_child(outer_layout)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.custom_minimum_size = Vector2(0, 32)
	header.add_theme_constant_override("separation", 8)
	outer_layout.add_child(header)

	var heading := Label.new()
	heading.name = "Title"
	heading.text = "KINGDOMS"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	heading.add_theme_font_size_override("font_size", 18)
	if title_font != null:
		heading.add_theme_font_override("font", title_font)
	header.add_child(heading)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(34, 30)
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_color_override("font_color", COLOR_PARCHMENT_LIGHT)
	close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	close_button.add_theme_font_size_override("font_size", 14)
	if body_bold_font != null:
		close_button.add_theme_font_override("font", body_bold_font)
	if ui_textures.has("button"):
		_apply_button_asset_styles(close_button, ui_textures["button"])
	close_button.pressed.connect(_on_kingdoms_close_pressed)
	header.add_child(close_button)

	var browser := HBoxContainer.new()
	browser.name = "Browser"
	browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser.add_theme_constant_override("separation", 12)
	outer_layout.add_child(browser)

	home_kingdom_tab_list = VBoxContainer.new()
	home_kingdom_tab_list.name = "KingdomTabs"
	home_kingdom_tab_list.custom_minimum_size = Vector2(154, 0)
	home_kingdom_tab_list.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
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
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
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
	var can_start := (
		not game_state.card_catalog.is_empty()
		and game_state.has_enough_market_candidates()
	)
	if home_new_game_button != null:
		home_new_game_button.disabled = not can_start
	if home_continue_button != null:
		home_continue_button.disabled = not has_active_game
	if home_create_lobby_button != null:
		home_create_lobby_button.disabled = not can_start
	if home_join_lobby_button != null:
		home_join_lobby_button.disabled = not can_start or network_enabled
	if home_lobby_address_input != null:
		home_lobby_address_input.editable = not network_enabled
	if home_lobby_status_label != null:
		if network_enabled and network_is_host:
			home_lobby_status_label.text = (
				"Hosting on port %d. Give players your IP address."
				% NETWORK_PORT
			)
		elif network_enabled:
			home_lobby_status_label.text = "Connected as Player %d." % (local_player_index + 1)
		elif game_state.multiplayer_enabled:
			home_lobby_status_label.text = (
				"Active lobby: %d players share this market."
				% game_state.get_player_count()
			)
		else:
			home_lobby_status_label.text = "Host or join a direct-IP table for up to 4 players."
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
	tab_button.clip_text = true
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
	market_panel.custom_minimum_size = Vector2(0, 382)
	market_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var market_margin := market_panel.get_node("MarketMargin") as MarginContainer
	market_margin.add_theme_constant_override("margin_left", 10)
	market_margin.add_theme_constant_override("margin_top", 8)
	market_margin.add_theme_constant_override("margin_right", 10)
	market_margin.add_theme_constant_override("margin_bottom", 6)
	var market_scroll := market_container.get_parent() as ScrollContainer
	var market_layout := VBoxContainer.new()
	market_layout.name = "MarketLayout"
	market_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_layout.add_theme_constant_override("separation", 8)
	market_margin.add_child(market_layout)
	market_scroll.reparent(market_layout)
	market_layout.move_child(market_scroll, 1)
	market_layout.add_child(_create_market_header())
	market_layout.move_child(market_layout.get_node("MarketHeader"), 0)
	market_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	market_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	market_container.add_theme_constant_override("separation", 10)
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
		CARD_FACE_SIZE.x * 5.0 + 8.0 * 4.0 + 4.0,
		COLOR_BARRACKS_CARPET,
		COLOR_SLATE.lightened(0.32)
	)
	barracks_carpet = barracks.panel
	barracks_carpet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_action_container = barracks.cards

	var estates := _create_market_carpet(
		"EstatesCarpet",
		1,
		CARD_FACE_SIZE.x + 4,
		COLOR_ESTATES_CARPET,
		COLOR_FOREST.lightened(0.32)
	)
	estates_carpet = estates.panel
	market_victory_container = estates.cards

	market_container.add_child(treasury_carpet)
	market_container.add_child(_create_market_separator())
	market_container.add_child(barracks_carpet)
	market_container.add_child(_create_market_separator())
	market_container.add_child(estates_carpet)


func _create_market_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.name = "MarketHeader"
	header.custom_minimum_size = Vector2(0, 24)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.name = "Title"
	title.text = "THE MARKET"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_BRASS)
	title.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	header.add_child(title)

	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.color = Color(0.835, 0.667, 0.314, 0.32)
	header.add_child(rule)

	market_helper_label = Label.new()
	market_helper_label.name = "Helper"
	market_helper_label.text = "Outlined cards are affordable. Greyed cards cost more."
	market_helper_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	market_helper_label.add_theme_color_override("font_color", Color(0.925, 0.863, 0.714, 0.78))
	market_helper_label.add_theme_font_size_override("font_size", 11)
	if body_font != null:
		market_helper_label.add_theme_font_override("font", body_font)
	header.add_child(market_helper_label)
	return header


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
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 8)
	cards.add_theme_constant_override("v_separation", 8)
	layout.add_child(cards)

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
			"Margin/Layout/TopBar/Margin/Row/BrandRow/Star",
			"Margin/Layout/TopBar/Margin/Row/BrandRow/Title",
			"Margin/Layout/TopBar/Margin/Row/BrandRow/BaseKingdomPill/Label",
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
	var preview_margin := card_preview.get_node("Margin") as MarginContainer
	preview_margin.add_theme_constant_override("margin_left", 14)
	preview_margin.add_theme_constant_override("margin_top", 13)
	preview_margin.add_theme_constant_override("margin_right", 14)
	preview_margin.add_theme_constant_override("margin_bottom", 13)
	var layout := preview_margin.get_node("Layout") as VBoxContainer
	layout.add_theme_constant_override("separation", 6)
	preview_name_label.custom_minimum_size = Vector2(0, 44)
	preview_name_label.add_theme_font_size_override("font_size", 21)
	preview_meta_label.add_theme_font_size_override("font_size", 11)
	preview_art_frame.custom_minimum_size = Vector2(0, PREVIEW_ART_HEIGHT)
	preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_effect_label.custom_minimum_size = Vector2(0, 176)
	preview_effect_label.add_theme_font_size_override("normal_font_size", 13)
	preview_effect_label.add_theme_font_size_override("bold_font_size", 13)
	preview_effect_label.scroll_active = false


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
	turn_label.text = (
		"%s  T%d" % [game_state.get_active_player_name(), player.turn_number]
		if game_state.multiplayer_enabled
		else "Turn %d" % player.turn_number
	)
	deck_label.text = str(player.draw_pile.size())
	discard_label.text = str(player.discard_pile.size())
	coin_label.text = str(player.coins)
	action_label.text = str(player.actions)
	buy_label.text = str(player.buys)
	if market_helper_label != null:
		market_helper_label.text = (
			"Outlined cards are affordable with your %d coins. Greyed cards cost more."
			% player.coins
		)
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


func _refresh_player_status() -> void:
	if player_status_list == null:
		return
	_clear_container(player_status_list)
	var you_index := (
		clampi(local_player_index, 0, game_state.players.size() - 1)
		if network_enabled and not game_state.players.is_empty()
		else game_state.active_player_index
	)
	for index in range(game_state.players.size()):
		player_status_list.add_child(
			_create_player_status_row(index, game_state.players[index], you_index)
		)


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


func _create_player_status_row(index: int, game_player: PlayerState, you_index: int) -> PanelContainer:
	var is_active := index == game_state.active_player_index
	var is_local := index == you_index
	var status_color := COLOR_BRASS
	var status_text := "Waiting"
	if game_player.pending_choice != null:
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

	var row_panel := PanelContainer.new()
	row_panel.name = "PlayerRow%d" % (index + 1)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.add_theme_stylebox_override(
		"panel",
		_make_player_row_style(is_active)
	)

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
	dot.add_theme_stylebox_override("panel", _make_dot_style(status_color))
	top.add_child(dot)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = game_player.player_name
	if is_local and network_is_host:
		name_label.text += " (host)"
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
	turn_text.text = "TURN %d" % game_player.turn_number
	turn_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_text.add_theme_color_override("font_color", COLOR_BRASS)
	turn_text.add_theme_font_size_override("font_size", 8)
	if title_font != null:
		turn_text.add_theme_font_override("font", title_font)
	turn_badge.add_child(turn_text)

	var status_label := Label.new()
	status_label.name = "Status"
	status_label.text = status_text
	status_label.add_theme_color_override("font_color", status_color)
	status_label.add_theme_font_size_override("font_size", 9)
	if body_font != null:
		status_label.add_theme_font_override("font", body_font)
	stack.add_child(status_label)

	if game_player.cooldown_remaining > 0.0:
		stack.add_child(_create_cooldown_bar(game_player, status_color))
	return row_panel


func _create_cooldown_bar(game_player: PlayerState, color: Color) -> Control:
	var track := PanelContainer.new()
	track.name = "CooldownBar"
	track.custom_minimum_size = Vector2(0, 5)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.add_theme_stylebox_override(
		"panel",
		_make_pill_style(Color(0, 0, 0, 0.28), Color.TRANSPARENT, 3)
	)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = color
	var duration := maxf(0.001, game_player.cooldown_duration)
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_right = clampf(game_player.cooldown_remaining / duration, 0.0, 1.0)
	fill.anchor_bottom = 1.0
	track.add_child(fill)
	return track


func _refresh_end_turn_button() -> void:
	if end_turn_button == null:
		return
	if turn_manager.game_over:
		end_turn_button.text = "GAME OVER"
		end_turn_button.disabled = true
		end_turn_button.modulate = Color.WHITE
		return
	if turn_manager.is_cooling_down():
		end_turn_button.text = "COOLDOWN %.1fs" % turn_manager.cooldown_remaining
		end_turn_button.disabled = true
		end_turn_button.modulate = Color(0.72, 0.74, 0.78, 1.0)
		return
	end_turn_button.text = "END TURN"
	end_turn_button.disabled = game_state.has_pending_choice() or not _can_control_active_player()
	end_turn_button.modulate = Color.WHITE


func _refresh_hand() -> void:
	_clear_container(hand_container)
	var hand_size := game_state.player.hand.size()
	for index in range(hand_size):
		var card: CardDefinition = game_state.player.hand[index]
		var playable := _can_play_card(card)
		var visual_state := HAND_PLAYABLE if playable else HAND_UNPLAYABLE
		var button := _create_card_button(card, visual_state)
		button.disabled = not playable
		button.rotation_degrees = _get_hand_card_rotation(index, hand_size)
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if playable else Control.CURSOR_ARROW
		)
		button.pressed.connect(_on_hand_card_pressed.bind(card))
		hand_container.add_child(button)


func _get_hand_card_rotation(index: int, total: int) -> float:
	if total <= 1:
		return 0.0
	var center := (float(total) - 1.0) * 0.5
	return clampf((float(index) - center) * 3.2, -8.0, 8.0)


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
	var played_cards := game_state.player.play_area
	play_area_label.text = "IN PLAY  %d" % played_cards.size()

	if played_cards.is_empty():
		var empty_label := Label.new()
		empty_label.custom_minimum_size = Vector2(0, PLAY_AREA_CONTENT_HEIGHT)
		empty_label.text = ""
		empty_label.add_theme_color_override("font_color", COLOR_PARCHMENT.darkened(0.28))
		empty_label.add_theme_font_size_override("font_size", 9)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		play_area_container.add_child(empty_label)
		return

	for card in played_cards:
		play_area_container.add_child(_create_played_card_chip(card))


func _can_play_card(card: CardDefinition) -> bool:
	if (
		not _can_interact_with_local_player()
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
		_can_interact_with_local_player()
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
	button.custom_minimum_size = CARD_FACE_SIZE
	if is_market_card:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("card_id", card.id)
	button.set_meta("visual_state", visual_state)
	button.set_meta("card_base_color", card_surface)
	button.set_meta("card_type", card.card_type)
	button.set_meta("card_group", card.card_group)
	button.set_meta("card_accent_color", border_color)
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

	var layout := VBoxContainer.new()
	layout.name = "CardLayout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 0)
	content.add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var art_height := HAND_CARD_ART_HEIGHT if is_hand_card else CARD_ART_HEIGHT
	var art_texture := _load_card_texture(card.art_id)
	var art_frame := PanelContainer.new()
	art_frame.name = "ArtFrame"
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.clip_contents = true
	art_frame.custom_minimum_size = Vector2(0, art_height)
	art_frame.add_theme_stylebox_override(
		"panel",
		_make_card_art_style(card_surface.darkened(0.16))
	)
	layout.add_child(art_frame)

	var art_rect := TextureRect.new()
	art_rect.name = "Art"
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_rect.texture = art_texture
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
	name_label.custom_minimum_size = Vector2(0, 19)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", type_palette.name_text)
	name_label.add_theme_font_size_override("font_size", 10)
	if title_font != null:
		name_label.add_theme_font_override("font", title_font)
	layout.add_child(name_label)

	var effect_slot := MarginContainer.new()
	effect_slot.name = "EffectSlot"
	effect_slot.custom_minimum_size = Vector2(0, 42 if is_market_card else 36)
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

	var meta_chip := PanelContainer.new()
	meta_chip.name = "MetaChip"
	meta_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	meta_chip.custom_minimum_size = Vector2(0, 13)
	meta_chip.add_theme_stylebox_override(
		"panel",
		_make_meta_chip_style(type_palette.chip_bg)
	)
	effect_center.add_child(meta_chip)

	var meta_chip_label := Label.new()
	meta_chip_label.name = "MetaChipLabel"
	meta_chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_chip_label.text = _get_card_meta_chip_text(card)
	meta_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta_chip_label.clip_text = true
	meta_chip_label.add_theme_color_override("font_color", type_palette.chip_text)
	meta_chip_label.add_theme_font_size_override("font_size", 7)
	if title_font != null:
		meta_chip_label.add_theme_font_override("font", title_font)
	meta_chip.add_child(meta_chip_label)

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
	effect_label.add_theme_font_size_override("normal_font_size", 7)
	effect_label.add_theme_font_size_override("bold_font_size", 7)
	if body_font != null:
		effect_label.add_theme_font_override("normal_font", body_font)
	if body_bold_font != null:
		effect_label.add_theme_font_override("bold_font", body_bold_font)
	effect_center.add_child(effect_label)

	var meta_row := HBoxContainer.new()
	meta_row.name = "MetaRow"
	meta_row.custom_minimum_size = Vector2(0, 10)
	meta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	meta_row.add_theme_constant_override("separation", 4)
	layout.add_child(meta_row)

	var type_label := Label.new()
	type_label.name = "TypeLabel"
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.custom_minimum_size = Vector2(0, 10)
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
		button.modulate = Color(0.7, 0.7, 0.66, 0.55)
	elif visual_state == HAND_UNPLAYABLE:
		button.modulate = Color(0.78, 0.78, 0.74, 0.78)

	return button


func _create_price_badge(cost: int) -> Control:
	var badge := Control.new()
	badge.name = "PriceBadge"
	badge.custom_minimum_size = Vector2(30, 30)
	badge.size = Vector2(30, 30)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.position = Vector2(7, 7)
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

	if icon_textures.has("coin"):
		var stamp := TextureRect.new()
		stamp.name = "CoinStamp"
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp.texture = icon_textures["coin"]
		stamp.modulate = Color(0.22, 0.12, 0.03, 0.18)
		stamp.position = Vector2(8, 8)
		stamp.size = Vector2(14, 14)
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.add_child(stamp)

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
	badge.position = Vector2(CARD_FACE_SIZE.x - 45, 8)
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


func _update_card_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_card_mouse_entered(
	card: CardDefinition,
	button: Button,
	visual_state: String
) -> void:
	_animate_card_scale(button, CARD_HOVER_SCALE)
	button.z_index = 10
	_show_card_preview(card, button, visual_state)


func _on_card_mouse_exited(button: Button) -> void:
	_animate_card_scale(button, CARD_NORMAL_SCALE)
	button.z_index = 0
	_hide_card_preview()


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
	source_button: Button,
	visual_state: String
) -> void:
	var type_palette := _get_card_type_palette(card.card_type)
	preview_name_label.text = card.card_name
	preview_meta_label.text = (
		"%s · COST %d COINS · %s"
		% [card.card_type.to_upper(), game_state.get_effective_cost(card), _get_card_meta_chip_text(card).to_upper()]
	)
	if not card.card_group.is_empty():
		preview_meta_label.text += " · %s" % card.card_group.to_upper()
	if visual_state.begins_with("market_"):
		preview_meta_label.text += " · %d LEFT" % game_state.get_supply_count(card.id)
	card_preview.set_meta("card_type", card.card_type)
	card_preview.set_meta("card_base_color", _get_card_surface_color(card.card_type))
	preview_name_label.add_theme_color_override("font_color", type_palette.name_text)
	preview_meta_label.add_theme_color_override("font_color", type_palette.chip_text)
	preview_art.texture = _load_card_texture(card.art_id)
	preview_art_frame.visible = preview_art.texture != null
	preview_art_frame.add_theme_stylebox_override(
		"panel",
		_make_card_art_style(_get_card_surface_color(card.card_type).darkened(0.14))
	)
	preview_effect_label.text = _get_card_rules_text(card.description)
	preview_effect_label.add_theme_color_override("default_color", type_palette.description_text)
	card_preview.add_theme_stylebox_override(
		"panel",
		_make_preview_style(_get_card_surface_color(card.card_type), type_palette.accent)
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


func _create_played_card_chip(card: CardDefinition) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(150, PLAY_AREA_CONTENT_HEIGHT)
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


func _get_desaturate_material() -> ShaderMaterial:
	if card_desaturate_material != null:
		return card_desaturate_material
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float amount : hint_range(0.0, 1.0) = 0.82;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tfloat grey = dot(tex.rgb, vec3(0.299, 0.587, 0.114));\n\ttex.rgb = mix(tex.rgb, vec3(grey), amount);\n\tCOLOR = tex * COLOR;\n}"
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
				"hover_border": Color("#fff0c0"),
				"name_text": Color("#f4e6c4"),
				"chip_bg": Color(0.941, 0.741, 0.345, 0.20),
				"chip_text": Color("#f4cd72"),
				"description_text": Color(0.957, 0.902, 0.769, 0.84),
				"footer_text": Color(0.941, 0.741, 0.345, 0.72),
				"scrim": Color(0.137, 0.082, 0.027, 0.82),
			}
		"victory":
			return {
				"accent": COLOR_VICTORY_ACCENT,
				"hover_border": Color("#f6cdd9"),
				"name_text": Color("#fdebf1"),
				"chip_bg": Color(0.878, 0.541, 0.635, 0.24),
				"chip_text": Color("#f3c4d2"),
				"description_text": Color(0.988, 0.914, 0.941, 0.86),
				"footer_text": Color(0.878, 0.541, 0.635, 0.74),
				"scrim": Color(0.122, 0.051, 0.098, 0.84),
			}
		"curse":
			return {
				"accent": COLOR_CURSE_ACCENT,
				"hover_border": COLOR_CURSE_ACCENT.lightened(0.25),
				"name_text": Color("#eee4ff"),
				"chip_bg": Color(0.706, 0.604, 0.851, 0.22),
				"chip_text": Color("#dbcdf2"),
				"description_text": Color(0.91, 0.86, 0.98, 0.84),
				"footer_text": Color(0.706, 0.604, 0.851, 0.72),
				"scrim": Color(0.086, 0.061, 0.118, 0.84),
			}
		_:
			return {
				"accent": COLOR_ACTION_ACCENT,
				"hover_border": Color("#cfe6fb"),
				"name_text": Color("#eef5fc"),
				"chip_bg": Color(0.49, 0.714, 0.91, 0.22),
				"chip_text": Color("#bfddf8"),
				"description_text": Color(0.878, 0.925, 0.98, 0.86),
				"footer_text": Color(0.49, 0.714, 0.91, 0.74),
				"scrim": Color(0.051, 0.086, 0.149, 0.84),
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
	var style := _make_flat_card_style(color, border_color, border_width)
	style.set_corner_radius_all(13)
	var shadow_color := border_color.lightened(0.1) if highlighted else Color(0, 0, 0, 0.5)
	shadow_color.a = 0.4 if highlighted else 0.5
	style.shadow_color = shadow_color
	style.shadow_size = 16 if highlighted else 10
	style.shadow_offset = Vector2(0, 8 if highlighted else 5)
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
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 7
	return style


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
	var base := Color("#f0cf80") if not disabled else Color(0.35, 0.32, 0.28, 0.75)
	if hover and not disabled:
		base = Color("#f6dc9b")
	var style := _make_flat_card_style(
		base,
		Color("#9c6f28") if not disabled else Color(0, 0, 0, 0.35),
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
	_start_background_music_from_user_gesture()
	var player: AudioStreamPlayer = ui_sound_players[sound_name]
	last_ui_sound_name = sound_name
	player.stop()
	player.play()


func _refresh_background_music() -> void:
	if background_music_player == null:
		return
	if audio_enabled:
		if not background_music_player.playing:
			background_music_player.play()
	else:
		background_music_player.stop()
		background_music_started_from_user_gesture = false


func _start_background_music_from_user_gesture() -> void:
	if background_music_player == null or not audio_enabled:
		return
	if background_music_started_from_user_gesture and background_music_player.playing:
		return
	background_music_player.stop()
	background_music_player.play()
	background_music_started_from_user_gesture = true


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_choice_requested(choice: CardChoice) -> void:
	if network_enabled and not _can_control_active_player():
		_hide_choice_overlay()
		return
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
	_refresh_choice_controls()
	_refresh_ui()
	if network_enabled and network_is_host:
		_broadcast_network_snapshot()


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
	if _is_network_client():
		rpc_id(1, "_rpc_request_choice", tokens)
		return
	var hand_before := game_state.player.hand.size()
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
	if network_enabled and network_is_host:
		_broadcast_network_snapshot()
	var drawn_count := maxi(0, game_state.player.hand.size() - hand_before)
	if drawn_count > 0:
		call_deferred("_animate_draw_cards", drawn_count)


func _on_hand_card_pressed(card: CardDefinition) -> void:
	if network_enabled and not _can_interact_with_local_player():
		return
	if _is_network_client():
		rpc_id(1, "_rpc_request_play_card", card.id)
		return
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
	if played and network_enabled and network_is_host:
		_broadcast_network_snapshot()


func _on_market_card_pressed(card: CardDefinition) -> void:
	if network_enabled and not _can_interact_with_local_player():
		return
	if _is_network_client():
		rpc_id(1, "_rpc_request_buy_card", card.id)
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
	if game_state.has_pending_choice() or not _can_control_active_player():
		return
	_play_ui_sound("end_turn")
	if _is_network_client():
		rpc_id(1, "_rpc_request_end_turn")
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
	_play_ui_sound("button_click")
	_start_new_game(true)


func _on_home_continue_pressed() -> void:
	if not has_active_game:
		return
	_play_ui_sound("button_click")
	_hide_home_screen()


func _on_home_create_lobby_pressed() -> void:
	_play_ui_sound("button_click")
	_host_network_lobby()


func _on_home_join_lobby_pressed() -> void:
	_play_ui_sound("button_click")
	_join_network_lobby()


func _on_home_settings_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_tab("settings")


func _on_home_kingdoms_pressed() -> void:
	_play_ui_sound("button_click")
	_show_home_tab("kingdoms")


func _on_kingdoms_close_pressed() -> void:
	_play_ui_sound("button_click")
	_close_kingdom_browser()


func _close_kingdom_browser() -> void:
	if home_kingdoms_panel != null:
		home_kingdoms_panel.hide()


func _input(event: InputEvent) -> void:
	if _is_audio_unlock_event(event):
		_start_background_music_from_user_gesture()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and home_kingdoms_panel != null and home_kingdoms_panel.visible:
		_close_kingdom_browser()
		get_viewport().set_input_as_handled()


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
	_refresh_background_music()
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


func _on_end_game_home_pressed() -> void:
	_play_ui_sound("button_click")
	has_active_game = false
	_hide_end_game_overlay()
	_show_home_screen(true)


func _show_final_score(score: int) -> void:
	last_animation_event = "game_end"
	_play_ui_sound("game_end")
	final_score_label.text = str(score)
	if game_state.multiplayer_enabled and not turn_manager.final_scores.is_empty():
		var parts: Array[String] = []
		for index in range(turn_manager.final_scores.size()):
			parts.append("P%d %d VP" % [index + 1, turn_manager.final_scores[index]])
		final_summary_label.text = "Scores: %s." % ", ".join(parts)
	else:
		final_summary_label.text = "Supply end reached. Every card in your collection was counted."
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
