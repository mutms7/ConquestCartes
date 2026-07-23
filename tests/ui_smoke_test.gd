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
		_home_art().anchor_left == 0.0
		and _home_art().anchor_top == 0.0
		and _home_art().anchor_right == 1.0
		and _home_art().anchor_bottom == 1.0,
		"Home art should remain a full-screen gallery backdrop."
	)
	_check(
		_home_overlay().find_child("Eyebrow", true, false) != null
		and _home_overlay().find_child("CataloguePlate", true, false) != null
		and _home_overlay().find_child("PlateCaption", true, false) != null,
		"The home screen should expose its catalogue eyebrow and art caption."
	)
	_check(
		_home_catalogue_plate().visible,
		"The catalogue plate should be visible on the landing composition."
	)
	_check(
		_home_new_game_button().focus_mode == Control.FOCUS_ALL
		and _home_new_game_button().get_theme_stylebox("focus") != null,
		"Primary home actions should be reachable with a visible keyboard focus state."
	)
	_check(
		not main_ui.has_node("HomeOverlay/MenuMargin/Menu/SetLabel"),
		"Home screen should not show the old base kingdom card-count eyebrow."
	)
	_check(_home_continue_button().disabled, "Continue should be disabled before a game starts.")
	_check(not _home_multiplayer_button().disabled, "Multiplayer should be available at startup.")
	_home_multiplayer_button().pressed.emit()
	await process_frame
	_check(
		not _home_catalogue_plate().visible,
		"The catalogue plate should hide behind the Multiplayer modal."
	)
	_check(
		root.get_viewport().gui_get_focus_owner() == _home_create_lobby_button(),
		"Opening Multiplayer should move keyboard focus into its first available action."
	)
	_home_create_lobby_button().pressed.emit()
	await process_frame
	main_ui._on_home_kingdoms_pressed()
	await process_frame
	main_ui._hide_home_modals()
	await process_frame
	_check(
		_home_lobby_panel().visible
		and root.get_viewport().gui_get_focus_owner() == main_ui.home_lobby_edit_kingdom_button,
		"Returning from nested Kingdoms should restore focus to Lobby's Edit Kingdom action."
	)
	main_ui._hide_home_modals()
	await process_frame
	_check(
		not _home_lobby_panel().visible
		and root.get_viewport().gui_get_focus_owner() == _home_multiplayer_button(),
		"Closing Lobby after nested Kingdoms should restore the original Multiplayer opener."
	)
	_home_multiplayer_button().pressed.emit()
	await process_frame
	_check(
		_home_multiplayer_panel().visible
		and not _home_create_lobby_button().disabled
		and not _home_join_lobby_button().disabled
		and not _home_create_online_button().disabled
		and not _home_join_online_button().disabled,
		"Multiplayer should open the local and online create/join choices."
	)
	var multiplayer_back_button := _home_multiplayer_panel().find_child("BackButton", true, false) as Button
	multiplayer_back_button.pressed.emit()
	await process_frame
	_check(
		root.get_viewport().gui_get_focus_owner() == _home_multiplayer_button(),
		"Closing Multiplayer should restore focus to its landing-menu opener."
	)
	_home_multiplayer_button().pressed.emit()
	await process_frame
	_check(
		main_ui._normalize_online_lobby_code("a-b 1 cde") == "ABCD",
		"Online lobby codes should normalize to four letters."
	)
	_check(
		main_ui._get_online_relay_url() == main_ui.ONLINE_RELAY_DEFAULT_URL,
		"Every build should target the one dedicated relay host by default."
	)
	_home_join_online_button().pressed.emit()
	await process_frame
	_check(
		_home_lobby_panel().visible
		and _home_lobby_address_input().text.is_empty()
		and _home_lobby_address_input().placeholder_text == "4-letter code"
		and _lobby_start_button().text == "JOIN ONLINE",
		"Join online should show an empty 4-letter code field, not the local IP field."
	)
	_home_multiplayer_button().pressed.emit()
	await process_frame
	_home_create_online_button().pressed.emit()
	await process_frame
	_check(
		_home_lobby_panel().visible
		and _home_lobby_address_input().text.is_empty()
		and _home_lobby_address_input().placeholder_text == "Code appears here"
		and _lobby_start_button().text == "CREATE LOBBY",
		"Create online should wait in the lobby until a code is assigned."
	)
	_check(
		main_ui.lobby_panel_status_label.text.contains("CREATE LOBBY"),
		"Create online should explain that the CREATE LOBBY button generates the code."
	)
	main_ui.network_enabled = true
	main_ui.network_is_host = true
	main_ui.network_mode = main_ui.NETWORK_MODE_ONLINE
	main_ui._on_online_lobby_created({
		"code": "WXYZ",
		"clientId": "host",
		"maxPlayers": 4,
	})
	await process_frame
	_check(
		_home_overlay().visible
		and _home_lobby_panel().visible
		and _home_lobby_address_input().text == "WXYZ"
		and _lobby_start_button().text == "ENTER TABLE",
		"Create online should keep the generated code visible before entering the table."
	)
	# Regression: the host's seat list must show a joiner immediately, not only
	# once the joiner presses I'M READY.
	main_ui._on_online_relay_peer_joined("guest-relay-id")
	await process_frame
	_check(
		int(main_ui.network_peer_to_player.get("guest-relay-id", -1)) == 1
		and _lobby_seat_title(1).begins_with("Player 2"),
		"A joining guest should appear in the host's seat list before readying up."
	)
	main_ui._disconnect_network()
	main_ui.has_active_game = false
	main_ui.game_state.multiplayer_enabled = false
	main_ui.network_enabled = true
	main_ui.network_is_host = false
	main_ui.network_mode = main_ui.NETWORK_MODE_ONLINE
	main_ui.lobby_pending_mode = "join_online"
	main_ui._show_home_tab("lobby")
	await process_frame
	var cooldown_before_client_edit: float = main_ui.game_state.end_turn_cooldown_seconds
	main_ui._on_end_turn_cooldown_changed(cooldown_before_client_edit + 2.0)
	_check(
		not main_ui.lobby_cooldown_slider.editable
		and _home_lobby_turn_based_toggle().disabled
		and main_ui.home_lobby_edit_kingdom_button.disabled
		and is_equal_approx(
			main_ui.game_state.end_turn_cooldown_seconds,
			cooldown_before_client_edit
		),
		"Joined clients should not be able to edit shared lobby rules."
	)
	_check(
		main_ui.home_lobby_start_button.text == "I'M READY"
		and not main_ui.home_lobby_start_button.disabled,
		"A joined guest should get a ready button instead of a start button."
	)
	main_ui._on_lobby_start_pressed()
	await process_frame
	_check(
		main_ui.lobby_ready_sent
		and main_ui.home_lobby_start_button.disabled
		and main_ui.home_lobby_start_button.text.begins_with("READY"),
		"Pressing ready should lock the button while waiting for the host."
	)
	main_ui._disconnect_network()
	main_ui._show_home_tab("multiplayer")
	await process_frame
	_home_create_lobby_button().pressed.emit()
	await process_frame
	_check(
		_home_lobby_panel().visible
		and _home_lobby_address_input().text == "127.0.0.1:27041",
		"Create local should route into the lobby with a host address."
	)
	_home_lobby_turn_based_toggle().toggled.emit(true)
	await process_frame
	_check(
		main_ui.game_state.turn_based_enabled
		and _home_lobby_rules_summary().text.contains("Turn based")
		and is_zero_approx(main_ui.game_state.get_end_turn_cooldown_seconds()),
		"Lobby turn-based toggle should enable the no-timer sequential variation."
	)
	_home_lobby_turn_based_toggle().toggled.emit(false)
	await process_frame
	# Editing the kingdom from the lobby must return to the lobby on close,
	# not dump the player back to the main menu.
	main_ui._on_home_kingdoms_pressed()
	await process_frame
	_check(
		_home_kingdoms_panel().visible and not _home_lobby_panel().visible,
		"Editing kingdoms from the lobby should open the kingdom browser."
	)
	main_ui._close_kingdom_browser()
	await process_frame
	_check(
		_home_lobby_panel().visible and not _home_kingdoms_panel().visible,
		"Closing the kingdom browser should return to the lobby."
	)
	main_ui._on_home_kingdoms_pressed()
	await process_frame
	main_ui._hide_home_modals()
	await process_frame
	_check(
		_home_lobby_panel().visible,
		"Escaping the kingdom browser should also return to the lobby."
	)
	_home_settings_button().pressed.emit()
	await process_frame
	_check(
		_home_settings_panel().visible and not _home_catalogue_plate().visible,
		"Settings should open with the catalogue plate hidden behind the modal."
	)
	_check(
		root.get_viewport().gui_get_focus_owner() == _home_audio_toggle(),
		"Opening Settings should move keyboard focus into its first interactive control."
	)
	var settings_opener := _home_settings_button()
	var settings_back_button := _home_settings_panel().find_child("BackButton", true, false) as Button
	settings_back_button.pressed.emit()
	await process_frame
	_check(
		root.get_viewport().gui_get_focus_owner() == settings_opener,
		"Closing Settings should restore focus to its landing-menu opener."
	)
	settings_opener.pressed.emit()
	await process_frame
	_check(_home_audio_toggle().button_pressed, "Audio should default to enabled.")
	# The ambience track loads on a background thread; force it to finish before
	# asserting on the stream so the test does not race the loader.
	main_ui.ensure_background_music_loaded()
	await process_frame
	_check(
		main_ui.background_music_player != null
		and main_ui.background_music_player.stream != null,
		"Background medieval music should load its stream."
	)
	_check(
		_music_uses_afterlight_ambience_mp3(),
		"Background music should use the renamed Afterlight ambience MP3."
	)
	_check(
		main_ui.background_music_start_requested,
		"Background music playback should be requested as soon as the scene loads."
	)
	_check(
		is_equal_approx(main_ui.background_music_volume, main_ui.DEFAULT_AUDIO_VOLUME)
		and is_equal_approx(_background_music_slider().value, main_ui.DEFAULT_AUDIO_VOLUME),
		"Background music volume should default to its configured level."
	)
	_check(
		is_equal_approx(_background_music_slider().step, main_ui.VOLUME_SLIDER_STEP)
		and is_equal_approx(
			main_ui._get_background_music_linear_volume(),
			pow(main_ui.DEFAULT_AUDIO_VOLUME, main_ui.VOLUME_RESPONSE_EXPONENT)
		),
		"Background music slider should offer finer low-end volume control."
	)
	await process_frame
	await process_frame
	_check(
		main_ui.background_music_player != null and main_ui.background_music_player.playing,
		"Background music should be playing when audio is enabled."
	)
	_check(
		main_ui.background_music_player != null
		and is_equal_approx(
			main_ui.background_music_player.volume_db,
			main_ui._get_background_music_volume_db()
		),
		"Background music should play at the configured volume."
	)
	main_ui.background_music_player.seek(2.0)
	await process_frame
	var position_before_settings: float = main_ui.background_music_player.get_playback_position()
	var start_requested_before_settings: bool = main_ui.background_music_start_requested
	_home_settings_button().pressed.emit()
	await process_frame
	var position_after_settings: float = main_ui.background_music_player.get_playback_position()
	var settings_preserved_position := true
	if position_before_settings > 1.0:
		settings_preserved_position = position_after_settings > 1.0
	_check(
		main_ui.background_music_start_requested == start_requested_before_settings
		and main_ui.background_music_player != null
		and main_ui.background_music_player.playing
		and settings_preserved_position,
		"Opening Settings should not restart or re-trigger background music."
	)
	_background_music_slider().set_value_no_signal(0.0)
	_background_music_slider().value_changed.emit(0.0)
	_check(
		is_zero_approx(main_ui.background_music_volume)
		and main_ui.background_music_player != null
		and not main_ui.background_music_player.playing,
		"Background music slider at zero should fully stop playback instead of leaving faint noise."
	)
	_background_music_slider().set_value_no_signal(1.0)
	_background_music_slider().value_changed.emit(1.0)
	await process_frame
	_check(
		main_ui.background_music_player != null
		and main_ui.background_music_player.playing
		and is_equal_approx(
			main_ui.background_music_player.volume_db,
			main_ui.BACKGROUND_MUSIC_VOLUME_DB
		),
		"Raising the background music slider should restart the boosted music mix."
	)
	main_ui.background_music_player.stop()
	main_ui.background_music_start_requested = false
	main_ui._play_ui_sound("button_click")
	await process_frame
	_check(
		not main_ui.background_music_start_requested
		and main_ui.background_music_player != null
		and not main_ui.background_music_player.playing
		and main_ui.last_ui_sound_name == "button_click",
		"UI sound effects should not start or restart background music."
	)
	var unlock_click := InputEventMouseButton.new()
	unlock_click.pressed = true
	main_ui._input(unlock_click)
	_check(
		main_ui.background_music_start_requested
		and main_ui.background_music_player.playing,
		"Background music should restart from a real input gesture for Web audio unlock."
	)
	# Sound effects and music now have independent toggles. Turning sound effects
	# off must leave the music that is already playing untouched.
	_home_audio_toggle().set_pressed_no_signal(false)
	_home_audio_toggle().toggled.emit(false)
	_check(
		not main_ui.audio_enabled
		and main_ui.background_music_player != null
		and main_ui.background_music_player.playing,
		"The sound effects toggle should not stop background music."
	)
	_home_audio_toggle().set_pressed_no_signal(true)
	_home_audio_toggle().toggled.emit(true)
	_check(main_ui.audio_enabled, "The sound effects toggle should re-enable effects.")
	# The music toggle is what stops and restarts the ambience track.
	_home_music_toggle().set_pressed_no_signal(false)
	_home_music_toggle().toggled.emit(false)
	_check(
		not main_ui.music_enabled
		and main_ui.background_music_player != null
		and not main_ui.background_music_player.playing,
		"The music toggle should stop the background music."
	)
	_home_music_toggle().set_pressed_no_signal(true)
	_home_music_toggle().toggled.emit(true)
	_check(
		main_ui.music_enabled
		and main_ui.background_music_player != null
		and main_ui.background_music_player.playing
		and main_ui.background_music_start_requested,
		"The music toggle should restart the background music."
	)
	_home_motion_toggle().set_pressed_no_signal(false)
	_home_motion_toggle().toggled.emit(false)
	_check(not main_ui.motion_enabled, "Motion toggle should update the UI setting.")
	_home_motion_toggle().set_pressed_no_signal(true)
	_home_motion_toggle().toggled.emit(true)
	_home_noise_toggle().set_pressed_no_signal(false)
	_home_noise_toggle().toggled.emit(false)
	_check(
		is_equal_approx(main_ui.home_noise_amount, 0.0)
		and is_equal_approx(_home_noise_overlay().modulate.a, 0.0),
		"Menu grain toggle should disable the fixed 4% overlay."
	)
	_check(
		_home_noise_overlay().stretch_mode == TextureRect.STRETCH_TILE,
		"Home noise should tile instead of stretching."
	)
	_home_noise_toggle().set_pressed_no_signal(true)
	_home_noise_toggle().toggled.emit(true)
	_table_noise_toggle().set_pressed_no_signal(false)
	_table_noise_toggle().toggled.emit(false)
	_check(
		is_equal_approx(main_ui.table_noise_amount, 0.0)
		and is_equal_approx(_table_noise_overlay().modulate.a, 0.0),
		"Table grain toggle should disable the fixed 4% overlay."
	)
	_table_noise_toggle().set_pressed_no_signal(true)
	_table_noise_toggle().toggled.emit(true)
	_check(
		is_equal_approx(main_ui.table_noise_amount, 0.04)
		and is_equal_approx(_table_noise_overlay().modulate.a, 0.04),
		"Enabled table grain should always use the fixed 4% amount."
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
		root.get_viewport().gui_get_focus_owner()
			== _kingdom_tabs().get_child(0).find_child("KingdomTab", true, false),
		"Opening Kingdoms should move keyboard focus into its first kingdom tab."
	)
	_check(
		not _home_catalogue_plate().visible,
		"Kingdoms should keep the catalogue plate hidden behind the modal."
	)
	_check(
		main_ui.menu_backdrop != null
		and main_ui.menu_backdrop.visible
		and not main_ui.home_menu_root.visible,
		"Opening a menu tab should raise the dark backdrop and hide the main menu."
	)
	_check(
		_kingdom_tabs().get_child_count() == GameState.KINGDOM_ORDER.size()
		and _kingdom_card_grid().get_child_count() > 0
		and _kingdom_detail_host().get_child_count() > 0,
		"Kingdoms should open a tabbed card browser with a detail pane."
	)
	for kingdom in GameState.KINGDOM_ORDER:
		if str(kingdom).to_lower().contains("trail"):
			_check(
				_kingdom_tab(str(kingdom)) != null
				and _kingdom_toggle(str(kingdom)) != null,
				"Trailblazers should expose the same kingdom filter controls as other packs."
			)
			break
	var kingdom_rect := _home_kingdoms_panel().get_global_rect()
	var root_rect := root.get_visible_rect()
	_check(
		kingdom_rect.position.x >= root_rect.position.x
		and kingdom_rect.end.x <= root_rect.end.x
		and is_equal_approx(_home_kingdoms_panel().anchor_left, 0.04)
		and is_equal_approx(_home_kingdoms_panel().anchor_right, 0.96),
		"Kingdoms browser should fit inside the viewport without right overflow."
	)
	_kingdoms_close_button().pressed.emit()
	await process_frame
	_check(not _home_kingdoms_panel().visible, "Kingdoms close button should hide the browser.")
	_check(
		not main_ui.menu_backdrop.visible and main_ui.home_menu_root.visible,
		"Closing the last menu tab should drop the backdrop and restore the main menu."
	)
	_check(
		_home_catalogue_plate().visible,
		"Closing a home modal should restore the catalogue plate."
	)
	_check(
		root.get_viewport().gui_get_focus_owner() == _home_kingdoms_button(),
		"Closing Kingdoms should restore focus to its landing-menu opener."
	)
	_home_kingdoms_button().pressed.emit()
	await process_frame
	var kingdom_browser_size := _home_kingdoms_panel().size
	var escape_event := InputEventAction.new()
	escape_event.action = "ui_cancel"
	escape_event.pressed = true
	main_ui._unhandled_input(escape_event)
	await process_frame
	_check(not _home_kingdoms_panel().visible, "Escape should hide the Kingdoms browser.")
	_home_kingdoms_button().pressed.emit()
	await process_frame
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
		_home_kingdoms_panel().size == kingdom_browser_size,
		"Switching kingdom tabs should not resize the browser."
	)
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
	_kingdom_toggle(GameState.WITCHING_HOUR_GROUP).set_pressed_no_signal(false)
	_kingdom_toggle(GameState.WITCHING_HOUR_GROUP).toggled.emit(false)
	_kingdom_toggle(GameState.CROWNWEALTH_GROUP).set_pressed_no_signal(false)
	_kingdom_toggle(GameState.CROWNWEALTH_GROUP).toggled.emit(false)
	if GameState.KINGDOM_ORDER.has(GameState.TRAILBLAZERS_GROUP):
		_kingdom_toggle(GameState.TRAILBLAZERS_GROUP).set_pressed_no_signal(false)
		_kingdom_toggle(GameState.TRAILBLAZERS_GROUP).toggled.emit(false)
	_check(_home_new_game_button().disabled, "New Game should lock when filters cannot fill a market.")
	_kingdom_toggle(GameState.BEGINNER_KINGDOM).set_pressed_no_signal(true)
	_kingdom_toggle(GameState.BEGINNER_KINGDOM).toggled.emit(true)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).set_pressed_no_signal(true)
	_kingdom_toggle(GameState.HINTERLANDS_GROUP).toggled.emit(true)
	_kingdom_toggle(GameState.WITCHING_HOUR_GROUP).set_pressed_no_signal(true)
	_kingdom_toggle(GameState.WITCHING_HOUR_GROUP).toggled.emit(true)
	_kingdom_toggle(GameState.CROWNWEALTH_GROUP).set_pressed_no_signal(true)
	_kingdom_toggle(GameState.CROWNWEALTH_GROUP).toggled.emit(true)
	if GameState.KINGDOM_ORDER.has(GameState.TRAILBLAZERS_GROUP):
		_kingdom_toggle(GameState.TRAILBLAZERS_GROUP).set_pressed_no_signal(true)
		_kingdom_toggle(GameState.TRAILBLAZERS_GROUP).toggled.emit(true)
	_home_new_game_button().pressed.emit()
	await process_frame
	await process_frame
	_check(not _home_overlay().visible, "New Game should leave the home screen.")
	_check(main_ui.has_active_game, "Starting from the home menu should create an active game.")
	_check(
		not main_ui._respite_active(),
		"A solo game should skip the opening timer and start playable at once."
	)
	var respite_hand_button := _find_card_button(_hand_container(), "pebble_coin")
	_check(
		respite_hand_button != null and not respite_hand_button.disabled,
		"Hand cards should be playable immediately in a solo game (no opening timer)."
	)
	_check(
		_hud_value("DeckStat") == str(main_ui.game_state.player.draw_pile.size())
		and _hud_value("DiscardStat") == str(main_ui.game_state.player.discard_pile.size()),
		"Physical draw and discard pile badges should mirror game-state counts."
	)
	_check(
		_players_turn_panel().find_child("PlayerRow1", true, false) != null,
		"The players + turns panel should render the local player row in solo."
	)
	await _run_expansion_ui_regression()

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
		_barracks_cards().get_child_count() == GameState.MARKET_CENTRAL_COUNT,
		"The center market grid should render ten random central piles."
	)
	_check(
		_estates_cards().get_child_count() == GameState.MARKET_VICTORY_TOTAL,
		"The right market column should render two victory piles."
	)
	_check(
		main_ui.pebble_coin_side_supply != null
		and main_ui.briar_hex_side_supply != null
		and main_ui.crownwealth_resource_side_supply != null
		and main_ui.crownwealth_victory_side_supply != null
		and main_ui.pebble_coin_side_supply.get_meta("card_id", "") == "pebble_coin"
		and main_ui.briar_hex_side_supply.get_meta("card_id", "") == GameState.CURSE_CARD_ID
		and main_ui.crownwealth_resource_side_supply.get_meta("card_id", "") == GameState.CROWNWEALTH_RESOURCE_ID
		and main_ui.crownwealth_victory_side_supply.get_meta("card_id", "") == GameState.CROWNWEALTH_VICTORY_ID
		and main_ui.pebble_coin_side_supply.custom_minimum_size == main_ui.CARD_FACE_SIZE
		and main_ui.briar_hex_side_supply.custom_minimum_size == main_ui.CARD_FACE_SIZE,
		"All enabled side supplies should render as full finite card faces."
	)
	var market_top_card := _treasury_cards().get_child(0) as Control
	_check(
		market_top_card != null
		and is_equal_approx(
			main_ui.pebble_coin_side_supply.get_global_rect().position.y,
			market_top_card.get_global_rect().position.y
		)
		and is_equal_approx(
			main_ui.briar_hex_side_supply.get_global_rect().position.y,
			market_top_card.get_global_rect().position.y
		),
		"Both fixed side-supply faces should align with the top row of market faces."
	)
	_check(
		_top_market_faces_have_grouped_gaps(),
		"Top-row market faces should use tight internal gaps and larger group gutters."
	)
	_check(
		_central_market_rows_have_equal_gaps(),
		"Every adjacent central-market face should use the same horizontal gap."
	)
	var original_root_size := root.size
	root.size = Vector2i(1366, 768)
	await process_frame
	await process_frame
	market_top_card = _treasury_cards().get_child(0) as Control
	_check(
		market_top_card != null
		and is_equal_approx(
			main_ui.pebble_coin_side_supply.get_global_rect().position.y,
			market_top_card.get_global_rect().position.y
		)
		and is_equal_approx(
			main_ui.briar_hex_side_supply.get_global_rect().position.y,
			market_top_card.get_global_rect().position.y
		),
		"Side-supply faces should stay aligned after the viewport is resized."
	)
	_check(
		_top_market_faces_have_grouped_gaps(),
		"Market group gutters should remain stable after the viewport is resized."
	)
	_check(
		_central_market_rows_have_equal_gaps(),
		"Central-market face gaps should remain equal after the viewport is resized."
	)
	root.size = original_root_size
	await process_frame
	await process_frame
	_check(
		main_ui.game_state.get_supply_count("pebble_coin")
			== main_ui.game_state.scale_supply_count(GameState.PEBBLE_SIDE_SUPPLY_COUNT)
		and main_ui.game_state.get_supply_count(GameState.CURSE_CARD_ID)
			== main_ui.game_state.scale_supply_count(GameState.CURSE_SUPPLY_COUNT),
		"Side-supply cards should expose finite authoritative counts."
	)
	var side_player: PlayerState = main_ui.game_state.player
	var side_buys: int = side_player.buys
	var side_coins: int = side_player.coins
	var pebble_supply_before: int = main_ui.game_state.get_supply_count("pebble_coin")
	var pebble_discard_before: int = side_player.discard_pile.size()
	main_ui.pebble_coin_side_supply.pressed.emit()
	_check(
		main_ui.game_state.get_supply_count("pebble_coin") == pebble_supply_before - 1
		and side_player.discard_pile.size() == pebble_discard_before + 1,
		"Clicking the Pebble Coin side face should use the normal purchase path."
	)
	while side_player.discard_pile.size() > pebble_discard_before:
		side_player.discard_pile.pop_back()
	main_ui.game_state.set_supply_count("pebble_coin", pebble_supply_before)
	side_player.buys = side_buys
	side_player.coins = side_coins
	var briar_supply_before: int = main_ui.game_state.get_supply_count(GameState.CURSE_CARD_ID)
	var briar_discard_before: int = side_player.discard_pile.size()
	main_ui.briar_hex_side_supply.pressed.emit()
	_check(
		main_ui.game_state.get_supply_count(GameState.CURSE_CARD_ID) == briar_supply_before - 1
		and side_player.discard_pile.size() == briar_discard_before + 1,
		"Clicking the Briar Hex side face should use the normal purchase path."
	)
	while side_player.discard_pile.size() > briar_discard_before:
		side_player.discard_pile.pop_back()
	main_ui.game_state.set_supply_count(GameState.CURSE_CARD_ID, briar_supply_before)
	side_player.buys = side_buys
	side_player.coins = side_coins
	var reserve_supply_before: int = main_ui.game_state.get_supply_count(GameState.CROWNWEALTH_RESOURCE_ID)
	var reserve_discard_before: int = side_player.discard_pile.size()
	side_player.buys = 1
	side_player.coins = main_ui.game_state.card_catalog[GameState.CROWNWEALTH_RESOURCE_ID].cost
	main_ui.crownwealth_resource_side_supply.pressed.emit()
	_check(
		main_ui.game_state.get_supply_count(GameState.CROWNWEALTH_RESOURCE_ID) == reserve_supply_before - 1
		and side_player.discard_pile.size() == reserve_discard_before + 1,
		"Clicking the upgraded resource side face should use the normal purchase path."
	)
	while side_player.discard_pile.size() > reserve_discard_before:
		side_player.discard_pile.pop_back()
	main_ui.game_state.set_supply_count(GameState.CROWNWEALTH_RESOURCE_ID, reserve_supply_before)
	side_player.buys = side_buys
	side_player.coins = side_coins
	main_ui._refresh_ui()
	_check(
		_container_holds_only_ids(_treasury_cards(), GameState.MARKET_FIXED_RESOURCE_IDS)
		and _container_holds_only_ids(_estates_cards(), GameState.MARKET_FIXED_VICTORY_IDS)
		and _container_holds_no_ids(
			_barracks_cards(),
			GameState.MARKET_FIXED_RESOURCE_IDS + GameState.MARKET_FIXED_VICTORY_IDS
		),
		"Fixed resources and victories anchor the side carpets; all other cards fill the action grid."
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
		"Central piles should descend from top-right to top-left, then bottom-right to bottom-left."
	)
	_check(
		_market_scroll().horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		and _market_scroll().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"The complete market should fit without scrolling."
	)
	_check(
		_market_container().find_child("Title", true, false) == null
		and _market_container().find_child("Subtitle", true, false) == null,
		"The handoff market should not reserve obsolete scene section titles."
	)
	_check(
		_market_panel().find_child("MarketHeader", true, false) == null,
		"The market should not reserve the old title/helper instruction row."
	)
	_check(
		is_equal_approx(_play_area_panel().custom_minimum_size.y, main_ui.PLAY_AREA_PANEL_HEIGHT)
		and is_equal_approx(
			_play_area_container().custom_minimum_size.y,
			main_ui.PLAY_AREA_CONTENT_HEIGHT
		),
		"Play area should reserve a fixed band height."
	)
	_check(_play_area_container().get_child_count() == 1, "Empty play area should show its hint.")
	_check(main_ui.title_font != null, "Imported title font should load.")
	_check(main_ui.body_font != null, "Imported body font should load.")
	_check(main_ui.body_bold_font != null, "Imported bold effect font should load.")
	_check(main_ui.ui_textures.size() == 9, "All original medieval UI textures should load.")
	_check(_hud_icon("CoinStat").texture != null, "Coin HUD icon should load.")
	_check(_hud_icon("ActionStat").texture != null, "Action HUD icon should load.")
	_check(_hud_icon("BuyStat").texture != null, "Buy HUD icon should load.")
	_check(main_ui.ui_sound_players.size() == 7, "All configured UI sounds should load.")
	_check(_top_bar() != null, "The 2a table should render a top bar.")
	_check(_relics_rail().get_child_count() > 0, "The top bar should include the relics rail.")
	main_ui.game_state.player.relics.append("dawn_banner")
	main_ui._refresh_relics_rail()
	await process_frame
	var relic_slot := main_ui.relics_rail_row.get_child(0) as Control
	_check(
		relic_slot != null and relic_slot.custom_minimum_size.x > 30.0,
		"Claimed relic slots should render as larger board icons."
	)
	if relic_slot != null:
		_right_click_control(relic_slot)
		await process_frame
		_check(
			_relic_preview().visible
			and main_ui.relic_preview_name_label.text == "Dawn Banner",
			"Right-clicking a board relic should show its relic preview."
		)
		_right_click_control(relic_slot)
		await process_frame
		_check(not _relic_preview().visible, "Right-clicking the same relic again should hide its preview.")
	main_ui.game_state.player.relics.clear()
	main_ui._refresh_relics_rail()
	_check(
		_bazaar_button() == null
		and _top_bar().find_child("BaseKingdomPill", true, false) == null,
		"The top bar should not show the old base kingdom or bazaar text."
	)
	_check(
		_settings_gear_button() == main_ui.home_button
		and _settings_gear_button().text.is_empty()
		and _settings_gear_button().find_child("SettingsIcon", true, false) != null,
		"The top-right settings button should use a code-drawn icon, not a Unicode glyph."
	)
	_check(
		main_ui.left_ledger.find_child("TrashPileButton", true, false) != null,
		"Trash should live in the bottom-left ledger below Coins, Actions, and Buys."
	)
	_check(_draw_pile_stack() != null, "The bottom band should include a physical draw pile.")
	_check(_discard_pile_stack() != null, "The bottom band should include a physical discard pile.")
	_check(_players_turn_panel() != null, "The right dock should include the players + turns panel.")
	_check(
		main_ui.CARD_FACE_SIZE.x <= 124.0
		and main_ui.CARD_FACE_SIZE.y <= 166.0
		and main_ui.CARD_FACE_SIZE.x > 0.0,
		"Card tokens should be scaled to the shipped 1280x720 table."
	)
	_check(
		_top_bar().get_global_rect().end.y <= _market_panel().get_global_rect().position.y
		and _market_panel().get_global_rect().end.y <= main_ui.left_ledger.get_global_rect().position.y,
		"Top bar, market, and bottom band should stack in frame order."
	)
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
		_color_distance(main_ui.COLOR_RESOURCE_CARD, main_ui.COLOR_ACTION_CARD) > 0.06
		and _color_distance(main_ui.COLOR_ACTION_CARD, main_ui.COLOR_VICTORY_CARD) > 0.06
		and _color_distance(main_ui.COLOR_RESOURCE_CARD, main_ui.COLOR_VICTORY_CARD) > 0.08,
		"Card type surfaces should stay distinct within the handoff palette."
	)
	_check(
		main_ui._get_card_type_accent("resource") != main_ui._get_card_type_accent("action")
		and main_ui._get_card_type_accent("action")
		!= main_ui._get_card_type_accent("victory"),
		"Each card type should also have a distinct type accent."
	)
	_check(
		main_ui.COLOR_ACTION_CARD.b > main_ui.COLOR_ACTION_CARD.r
		and main_ui.COLOR_ACTION_ACCENT.b > main_ui.COLOR_ACTION_ACCENT.r,
		"Action cards should use the handoff midnight-blue palette."
	)
	_check(
		_table_background().modulate.r > _table_background().modulate.b
		and _table_vignette().color.r > _table_vignette().color.b,
		"The table background should be warmed away from the blue source art."
	)
	_check(
		_hand_panel().get_global_rect().end.y <= root.get_visible_rect().end.y,
		"The full hand panel should remain inside the 1280x720 viewport."
	)
	_check(
		_market_panel().get_global_rect().end.y <= root.get_visible_rect().end.y,
		"The complete handoff market should remain inside the viewport."
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
		>= _market_panel().get_global_rect().end.y
		and main_ui.right_ledger.get_global_rect().position.y
		>= _market_panel().get_global_rect().end.y,
		"The side docks should sit in the bottom band below the market."
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
			== main_ui._get_card_type_accent(resource_button.get_meta("card_type")),
			"Playable hand cards should use their type accent."
		)
		var normal_style := resource_button.get_theme_stylebox("normal") as StyleBoxFlat
		_check(
			normal_style != null and normal_style.border_width_left >= 2,
			"Card outlines should remain clear in their normal state."
		)
		var frame_overlay := resource_button.get_node_or_null("CardFrameOverlay") as Panel
		var frame_style := frame_overlay.get_theme_stylebox("panel") as StyleBoxFlat if frame_overlay != null else null
		var resource_rect := resource_button.get_global_rect()
		var frame_rect := frame_overlay.get_global_rect() if frame_overlay != null else Rect2()
		_check(
			frame_overlay != null
			and frame_overlay.get_index() > resource_button.get_node("CardContent").get_index()
			and frame_overlay.z_index == resource_button.get_node("CardContent").z_index
			and frame_overlay.z_as_relative
			and is_equal_approx(frame_rect.position.x, resource_rect.position.x)
			and is_equal_approx(frame_rect.position.y, resource_rect.position.y)
			and is_equal_approx(frame_rect.size.x, resource_rect.size.x)
			and is_equal_approx(frame_rect.size.y, resource_rect.size.y),
			"The outer card frame should overlay the complete content bounds."
		)
		_check(
			frame_style != null
			and frame_style.border_width_left == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.border_width_top == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.border_width_right == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.border_width_bottom == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.corner_radius_top_left == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.corner_radius_top_right == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.corner_radius_bottom_right == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.corner_radius_bottom_left == main_ui.CARD_FRAME_BORDER_WIDTH
			and frame_style.border_color
				== main_ui._card_edge_color(main_ui._get_card_type_accent("resource")),
			"The outer frame should use a 2px quieted type-colored border with matching subtle corners."
		)
		_check(
			normal_style != null
			and normal_style.corner_radius_top_left == normal_style.border_width_left
			and normal_style.corner_radius_bottom_right == normal_style.border_width_right,
			"Button card styles should keep their corner radius equal to their border width."
		)
		var overlap_pair := _find_overlapping_hand_pair()
		_check(
			overlap_pair.size() == 2,
			"The hand should expose an overlapping card pair for stacking regression coverage."
		)
		if overlap_pair.size() == 2:
			var rear_hand_card := overlap_pair[0] as Control
			var front_hand_card := overlap_pair[1] as Control
			var rear_frame := rear_hand_card.get_node_or_null("CardFrameOverlay") as Control
			var front_frame := front_hand_card.get_node_or_null("CardFrameOverlay") as Control
			_check(
				front_hand_card.get_index() > rear_hand_card.get_index()
				and front_hand_card.z_index == rear_hand_card.z_index
				and rear_frame != null
				and front_frame != null
				and rear_frame.z_index == 0
				and front_frame.z_index == 0
				and rear_frame.z_as_relative
				and front_frame.z_as_relative,
				"A front hand card should stack above the rear card as a whole, including its frame."
			)
		_check(
			resource_button.has_node("CardContent/CardLayout/ArtFrame/ArtScrim")
			and resource_button.has_node("CardContent/CardLayout/ArtFrame/AccentLine")
			and resource_button.has_node("CardContent/CardLayout/TextScrim")
			and not resource_button.has_node("CardContent/CardLayout/EffectSlot/EffectCenter/MetaChip"),
			"Card faces should include the art/text scrims and accent line without a rules meta chip."
		)
		_check(
			_card_art(resource_button).modulate.a >= 0.9
			and _card_art_scrim(resource_button).color.a <= 0.24,
			"Card art scrims should tint the top art band without covering it."
		)
		_check(
			is_equal_approx(_card_art_coverage(resource_button), main_ui.HAND_CARD_ART_HEIGHT / main_ui.CARD_FACE_SIZE.y)
			and _card_text_scrim_alpha(resource_button) <= 0.96,
			"Card art should occupy the top band with a distinct rules body below."
		)
		var art_frame := _card_art(resource_button).get_parent() as Control
		_check(
			art_frame != null
			and art_frame.position.x >= main_ui.CARD_ART_SIDE_INSET - 0.5
			and art_frame.size.x <= main_ui.CARD_FACE_SIZE.x - main_ui.CARD_ART_SIDE_INSET * 2.0 + 0.5,
			"Card art should leave a symmetric inset so the face border stays visible."
		)
		_check(_card_art(resource_button).texture != null, "Card faces should display card artwork.")
		_check(
			not resource_button.has_node("PriceBadge/CoinStamp")
			and not _card_price(resource_button).text.contains("$"),
			"Card cost badges should show numerals without a dollar-stamped icon."
		)
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
			_card_name(resource_button).get_theme_font_size("font_size") >= 10
			and _card_effect(resource_button).get_theme_font_size("normal_font_size") >= 7,
			"Hand card titles and rules text should use the scaled 2a type."
		)
		var hand_effect_slot := resource_button.get_node("CardContent/CardLayout/EffectSlot") as Control
		_check(
			hand_effect_slot != null
			and hand_effect_slot.custom_minimum_size.y >= main_ui.CARD_EFFECT_MIN_HEIGHT
			and is_equal_approx(
				(_card_name(resource_button).position.y - main_ui.CARD_ART_TOP_INSET - main_ui.HAND_CARD_ART_HEIGHT),
				1.0
			)
			and is_equal_approx(
				(hand_effect_slot.position.y - main_ui.CARD_ART_TOP_INSET - main_ui.HAND_CARD_ART_HEIGHT),
				main_ui.CARD_NAME_HEIGHT + 1.0
			),
			"Card rules should have a three-line slot with the title and rules lifted together."
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
		# The hand fans the cards with rotation, so evaluate the internal layout
		# with rotation temporarily removed (the layout itself is rotation-free).
		var saved_rotation := resource_button.rotation_degrees
		resource_button.rotation_degrees = 0.0
		var hand_layout_clear := _card_text_layout_is_clear(resource_button)
		resource_button.rotation_degrees = saved_rotation
		_check(
			hand_layout_clear,
			"Hand card text should stay inside the frame without intersecting neighboring regions."
		)
		_check(
			_hand_is_fanned(),
			"Hand cards should fan out with rotation that grows from the centre outward."
		)
		_check(
			is_equal_approx(
				_card_art(resource_button).get_parent().size.y,
				main_ui.HAND_CARD_ART_HEIGHT
			),
			"Hand artwork should use the 2a hand art height."
		)
		var pre_play_market_button := _all_market_buttons()[0]
		var pre_play_market_card_id: String = pre_play_market_button.get_meta("card_id")
		var pre_play_market_supply: int = main_ui.game_state.get_supply_count(pre_play_market_card_id)
		var pre_play_discard_count: int = main_ui.game_state.player.discard_pile.size()
		_check(
			pre_play_market_button.get_meta("visual_state") == "market_neutral"
			and not pre_play_market_button.disabled,
			"Pre-play market cards should be neutral and inspectable before any card is played."
		)
		_check(
			_card_art(pre_play_market_button).material == null
			and _card_art(pre_play_market_button).modulate.a >= 0.9
			and is_equal_approx(pre_play_market_button.modulate.a, 1.0)
			and _card_art_scrim(pre_play_market_button).color.a <= 0.24,
			"Pre-play market cards should stay fully saturated, not dimmed."
		)
		_check(
			is_equal_approx(_card_art_coverage(pre_play_market_button), main_ui.CARD_ART_HEIGHT / main_ui.CARD_FACE_SIZE.y),
			"Market art should use the handoff top art band."
		)
		pre_play_market_button.pressed.emit()
		await process_frame
		_check(
			main_ui.game_state.get_supply_count(pre_play_market_card_id) == pre_play_market_supply
			and main_ui.game_state.player.discard_pile.size() == pre_play_discard_count,
			"Inspectable pre-play market cards should not bypass buy affordability rules."
		)
		var sound_before_hover: String = main_ui.last_ui_sound_name
		resource_button.mouse_entered.emit()
		await create_timer(0.2).timeout
		_check(not _card_preview().visible, "Hovering a hand card should not show its preview.")
		_right_click_control(resource_button)
		await process_frame
		_check(_card_preview().visible, "Right-clicking a hand card should show its preview.")
		var preview_dismiss_click := InputEventMouseButton.new()
		preview_dismiss_click.pressed = true
		preview_dismiss_click.button_index = MOUSE_BUTTON_LEFT
		main_ui._input(preview_dismiss_click)
		_check(
			not _card_preview().visible and main_ui.active_preview_kind.is_empty(),
			"A left click should dismiss a card preview before the clicked action is dispatched."
		)
		_right_click_control(resource_button)
		await process_frame
		_check(_card_preview().visible, "Card preview should be reopenable after a left-click dismissal.")
		_check(
			_card_preview().custom_minimum_size.x > main_ui.CARD_FACE_SIZE.x
			and _card_preview().custom_minimum_size.x <= 280.0
			and absf(
				(
					_card_preview().custom_minimum_size.x
					/ _card_preview().custom_minimum_size.y
				)
				- (main_ui.CARD_FACE_SIZE.x / main_ui.CARD_FACE_SIZE.y)
			) < 0.02
			and _preview_effect().get_theme_font_size("normal_font_size")
			> _card_effect(resource_button).get_theme_font_size("normal_font_size"),
			"Card previews should read as modestly enlarged card faces with scaled rules text."
		)
		_check(
			main_ui.last_ui_sound_name == sound_before_hover,
			"Card hover should not play a UI sound."
		)
		_check(
			_preview_name_label().text == "Copper",
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
		_check(_card_preview().visible, "Leaving a hand card should leave its right-click preview open.")
		_right_click_control(resource_button)
		await process_frame
		_check(not _card_preview().visible, "Right-clicking the same hand card again should hide its preview.")
		var play_area_size_before_play := _play_area_panel().size
		resource_button.pressed.emit()
		await process_frame
		_check(main_ui.last_ui_sound_name == "play_card", "Playing a card should trigger its sound.")
		_check(main_ui.last_animation_event == "play", "Playing should trigger card movement.")
		_check(_hud_value("CoinStat") == "1", "Coin HUD should update after playing a resource.")
		_check(_hand_container().get_child_count() == 4, "Played card should leave the hand UI.")
		_check(_play_area_container().get_child_count() == 1, "Played card should render in play area.")
		var played_card_button := _play_area_container().get_child(0) as Button
		_check(
			played_card_button != null
			and played_card_button.custom_minimum_size == main_ui.PLAYED_CARD_SIZE
			and played_card_button.has_node("PlayedCardContent/ArtFrame/Art")
			and played_card_button.has_node("PlayedCardContent/NameBand/NameLabel"),
			"Played cards should render as mini art/name cards."
		)
		if played_card_button != null:
			_right_click_control(played_card_button)
			await process_frame
			_check(_card_preview().visible, "Right-clicking a played mini card should show its preview.")
			_right_click_control(played_card_button)
			await process_frame
			_check(not _card_preview().visible, "Right-clicking the same played mini card again should hide its preview.")
		_check(
			_play_area_panel().size == play_area_size_before_play,
			"Playing a card should not resize the play area or move the UI."
		)
		var post_play_market_button := _all_market_buttons()[0]
		_check(
			post_play_market_button.get_meta("visual_state") != "market_neutral",
			"After a card is played the market should switch to affordability treatment."
		)

	var short_rules_card: CardDefinition = main_ui.game_state.card_catalog["candlecap_laboratory"]
	var short_rules_button: Button = main_ui._create_card_button(short_rules_card, "hand_playable")
	root.add_child(short_rules_button)
	await process_frame
	_check(
		_card_effect(short_rules_button).get_parsed_text()
		== "+2 cards.\n+1 action.",
		"Short multi-sentence rules text should split into one sentence per line."
	)
	short_rules_button.queue_free()

	var long_rules: String = main_ui.game_state.card_catalog["grand_archive"].description
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
			score_button.get_meta("card_accent_color") == Color(0, 0, 0, 0.45),
			"Unavailable hand cards should use the no-glow disabled border."
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
			== main_ui._get_card_type_accent(market_card.card_type),
			"Affordable market cards should use their type accent."
		)
		_check(
			_market_pile_label(market_button).text == str(market_supply_before),
			"Market cards should show their remaining pile count in the top badge."
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
			_card_name(market_button).get_theme_font_size("font_size") >= 10
			and _card_effect(market_button).get_theme_font_size("normal_font_size") >= 7,
			"Market card titles and rules text should use the scaled 2a type."
		)
		_check(
			_card_text_layout_is_clear(market_button),
			"Market card text should stay inside the frame without intersecting neighboring regions."
		)
		market_button.mouse_entered.emit()
		await process_frame
		_check(not _card_preview().visible, "Hovering a market card should not show its preview.")
		_right_click_control(market_button)
		await process_frame
		_check(_card_preview().visible, "Right-clicking a market card should show its preview.")
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
			var button_card: CardDefinition = main_ui.game_state.card_catalog[str(button.get_meta("card_id"))]
			_check(
				not button.disabled
				and button.get_meta("visual_state") == "market_unaffordable"
				and not main_ui._can_buy_card(button_card),
				"Market cards should remain inspectable but visually unavailable with no buys remaining."
			)
		main_ui.game_state.player.buys = 1
		main_ui.game_state.player.coins = 99
		main_ui.game_state.set_supply_count(market_card_id, 0)
		main_ui._refresh_ui()
		var sold_out_button := _find_card_button(_market_container(), market_card_id)
		_check(sold_out_button != null, "Sold-out market pile should remain rendered.")
		if sold_out_button != null:
			_check(sold_out_button.disabled, "Sold-out market piles should remain disabled.")
			_check(
				_market_pile_label(sold_out_button).text == "0",
				"Sold-out market piles should visibly show zero remaining."
			)

	_click_control(_end_turn_button())
	await process_frame
	_check(
		not main_ui.turn_manager.is_cooling_down()
		and _end_turn_button().text == "END BUYS",
		"Singleplayer End Turn should not start a cooldown timer."
	)
	_check(
		not _end_turn_button().disabled,
		"Singleplayer End Turn should stay enabled with no timeout."
	)
	_check(
		_end_turn_button().custom_minimum_size.x >= 168.0,
		"End Turn should reserve a stable button width."
	)
	_check(_hand_container().get_child_count() == 5, "End turn should render a new five-card hand.")
	_check(_hud_value("CoinStat") == "0", "Coin HUD should reset at end of turn.")
	_check(_hud_value("ActionStat") == "1", "Action HUD should reset at end of turn.")
	_check(_hud_value("BuyStat") == "1", "Buy HUD should reset at end of turn.")
	_check(
		main_ui.game_state.player.play_area.is_empty(),
		"Play area state should be empty after cleanup."
	)
	_check(main_ui.last_ui_sound_name == "draw", "End turn should finish with draw feedback.")
	_check(main_ui.last_animation_event == "draw", "End turn should animate the new hand.")
	var solo_resource_button := _find_card_button(_hand_container(), "pebble_coin")
	_check(
		solo_resource_button != null,
		"Fresh singleplayer hand should include a playable Pebble Coin."
	)
	if solo_resource_button != null:
		_check(
			not solo_resource_button.disabled,
			"Fresh singleplayer hand cards should be playable."
		)
		var solo_play_area_before: int = main_ui.game_state.player.play_area.size()
		_click_control(solo_resource_button)
		await process_frame
		_check(
			main_ui.game_state.player.play_area.size() == solo_play_area_before + 1,
			"A real click should play a hand card on a fresh singleplayer turn."
		)
		main_ui.game_state.player.coins = 99
		main_ui.game_state.player.buys = 1
		main_ui._refresh_ui()
		var solo_market_button: Button = null
		for button in _all_market_buttons():
			if not button.disabled:
				solo_market_button = button
				break
		_check(
			solo_market_button != null,
			"Singleplayer market cards should be buyable."
		)
		if solo_market_button != null:
			var solo_discard_before_buy: int = main_ui.game_state.player.discard_pile.size()
			_click_control(solo_market_button)
			await process_frame
			_check(
				main_ui.game_state.player.discard_pile.size() == solo_discard_before_buy + 1,
				"A real click should buy from the market on a fresh singleplayer turn."
			)

	main_ui._start_new_game(true)
	await process_frame
	await process_frame
	main_ui._end_respite()
	_click_control(_end_turn_button())
	await process_frame
	_check(
		not main_ui.turn_manager.is_cooling_down(),
		"A fresh singleplayer End Turn click should not start any cooldown."
	)
	solo_resource_button = _find_card_button(_hand_container(), "pebble_coin")
	_check(
		solo_resource_button != null,
		"Fresh singleplayer hand should include a playable Pebble Coin."
	)
	if solo_resource_button != null:
		_check(
			not solo_resource_button.disabled,
			"Fresh singleplayer hand cards should be playable."
		)
		var fresh_play_area_before: int = main_ui.game_state.player.play_area.size()
		_click_control(solo_resource_button)
		await process_frame
		_check(
			main_ui.game_state.player.play_area.size() == fresh_play_area_before + 1,
			"Fresh singleplayer clicks should play cards immediately."
		)

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
	main_ui._end_respite()
	_check(main_ui.last_ui_sound_name == "draw", "Home New Game should finish with draw feedback.")
	var market_after_restart: Array[String] = main_ui.game_state.get_market_card_ids()
	_check(
		market_after_restart.size() == GameState.MARKET_SIZE
		and _unique_string_count(market_after_restart) == GameState.MARKET_SIZE,
		"Home New Game should rebuild a complete unique market; repeating a sample is allowed."
	)
	_check(_hud_value("TurnStat") == "Turn 1", "Home New Game should reset the turn counter.")
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
		_check(not _choice_overlay().visible, "Hand trash choices should keep the board unobstructed.")
		_check(_end_turn_button().text == "CONFIRM", "Hand trash should replace End Turn with Confirm.")
		_check(not _end_turn_button().disabled, "Optional hand trash should allow confirming no selection.")
		var coin_button := _find_card_button(_hand_container(), "pebble_coin")
		var estate_button := _find_card_button(_hand_container(), "homestead")
		_check(coin_button != null and estate_button != null, "Trash candidates should remain in the hand.")
		if coin_button != null and estate_button != null:
			coin_button.pressed.emit()
			estate_button.pressed.emit()
			await process_frame
			_check(not _end_turn_button().disabled, "A valid hand-trash selection should enable Confirm.")
			# Selecting refreshes the hand, so resolve the rebuilt card before
			# checking its persistent selected-trash overlay.
			coin_button = _find_card_button(_hand_container(), "pebble_coin")
			_check(
				coin_button != null and coin_button.get_node_or_null("TrashHoverOverlay") != null,
				"Selected trash cards should retain the red X overlay."
			)
		_end_turn_button().pressed.emit()
		await process_frame
		_check(not _choice_overlay().visible, "Resolving a choice should close the overlay.")
		_check(
			main_ui.game_state.player.trash_pile.size() == 2,
			"Choice confirmation should apply the selected card movement."
		)

	var compact_choice := CardChoice.new()
	compact_choice.id = -9001
	compact_choice.prompt = "Pick a compact preview."
	compact_choice.add_candidate("compact-preview", main_ui.game_state.card_catalog["pebble_coin"])
	main_ui._on_choice_requested(compact_choice)
	await process_frame
	_check(
		_choice_overlay().visible
		and _choice_overlay().get_node("Center/Panel").custom_minimum_size == Vector2(720, 390),
		"Non-direct choices should use the compact walnut picker."
	)
	var hide_choice := _choice_overlay().find_child("MinimizeButton", true, false) as Button
	_check(hide_choice != null, "Choice picker should provide a temporary hide control.")
	if hide_choice != null:
		hide_choice.pressed.emit()
		await process_frame
		var restore_choice := main_ui.get_node_or_null("ChoiceRestoreTab") as Button
		_check(
			not _choice_overlay().visible
			and restore_choice != null
			and restore_choice.visible
			and main_ui.current_choice == compact_choice,
			"Minimizing should preserve the pending choice and expose a restore tab."
		)
		if restore_choice != null:
			restore_choice.pressed.emit()
			await process_frame
			_check(_choice_overlay().visible and main_ui.current_choice == compact_choice, "Restore should reopen the same choice.")
	main_ui._hide_choice_overlay()

	var reward_choice := CardChoice.new()
	reward_choice.id = -9002
	reward_choice.prompt = "Choose a reward."
	reward_choice.context["ui_choice_kind"] = "mode"
	for reward in ["+2 CARDS, +1 ACTION", "+1 BUY, +2 COINS", "+3 COINS"]:
		reward_choice.add_candidate(
			"mode:-9002:%s" % reward,
			main_ui.game_state.card_catalog["acorn_spicebroker"],
			reward
		)
	main_ui._on_choice_requested(reward_choice)
	await process_frame
	var choice_scroll := _choice_overlay().get_node(
		"Center/Panel/Margin/Layout/OptionsScroll"
	) as ScrollContainer
	_check(
		_choice_options().get_child_count() == 3
		and _choice_options().get_child(0).name == "RewardOption"
		and not _choice_options().get_child(0).has_node("CardContent"),
		"Reward modes should show three labelled reward options instead of repeated card faces."
	)
	_check(
		choice_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"A small reward set should remain centered without a horizontal scrollbar."
	)
	main_ui._hide_choice_overlay()

	var many_cards_choice := CardChoice.new()
	many_cards_choice.id = -9003
	many_cards_choice.prompt = "Choose from many cards."
	for index in range(6):
		many_cards_choice.add_candidate(
			"many:%d" % index,
			main_ui.game_state.card_catalog["pebble_coin"]
		)
	main_ui._on_choice_requested(many_cards_choice)
	await process_frame
	_check(
		choice_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS,
		"Card choices beyond the visible capacity should use horizontal scrolling."
	)
	main_ui._hide_choice_overlay()

	main_ui._start_new_game(true)
	await process_frame
	await process_frame
	main_ui._end_respite()
	for index in range(3):
		main_ui.game_state.set_supply_count(main_ui.game_state.market[index].id, 0)
	_end_turn_button().pressed.emit()
	main_ui.turn_manager.tick(GameState.DEFAULT_END_TURN_COOLDOWN_SECONDS)
	await process_frame
	_check(
		main_ui.scoring_relic_overlay.visible,
		"A solo game should open the scoring-relic draft when it ends."
	)
	_check(
		main_ui.scoring_relic_options_row.get_child_count() == 2,
		"The scoring-relic draft should offer two choices."
	)
	_check(main_ui.last_animation_event == "game_end", "Final scoring should animate its reveal.")
	_check(main_ui.last_ui_sound_name == "game_end", "Final scoring should trigger its sound.")

	var chosen_scoring_relic: String = main_ui.scoring_relic_offer[0]
	main_ui._on_scoring_relic_chosen(chosen_scoring_relic)
	await process_frame
	_check(
		not main_ui.scoring_relic_overlay.visible and main_ui.summary_overlay.visible,
		"Choosing a scoring relic should close the draft and open the summary."
	)
	_check(
		main_ui.game_state.player.scoring_relic == chosen_scoring_relic,
		"The chosen scoring relic should be recorded on the player."
	)
	_check(
		main_ui.summary_content.get_child_count() >= 1,
		"The summary should list the player's deck and score."
	)

	main_ui._on_play_again_pressed()
	await process_frame
	await process_frame
	_check(not main_ui.summary_overlay.visible, "Play Again should close the summary overlay.")
	_check(_hud_value("TurnStat") == "Turn 1", "Play Again should start a fresh game.")

	main_ui._show_final_score(11)
	await process_frame
	main_ui._on_scoring_relic_chosen(main_ui.scoring_relic_offer[0])
	await process_frame
	main_ui._on_end_game_home_pressed()
	await process_frame
	_check(_home_overlay().visible, "End-game Home should return to the home screen.")
	_check(
		not main_ui.has_active_game and _home_continue_button().disabled,
		"End-game Home should leave no completed game available to continue."
	)
	_home_multiplayer_button().pressed.emit()
	await process_frame
	_home_create_lobby_button().pressed.emit()
	await process_frame
	_lobby_start_button().pressed.emit()
	await process_frame
	_check(
		main_ui.game_state.multiplayer_enabled
		and main_ui.game_state.get_player_count() == 4,
		"Lobby Start Game should start a four-player table."
	)
	main_ui._end_respite()
	var player_row_height_before_cooldown := _player_row(1).custom_minimum_size.y
	var player_panel_height_before_cooldown := _players_turn_panel().get_global_rect().size.y
	_click_control(_end_turn_button())
	await process_frame
	_check(
		main_ui.game_state.active_player_index == 0
		and main_ui.game_state.player.player_name == "Player 1",
		"Network End Turn should keep the local host view on Player 1."
	)
	_check(
		main_ui.game_state.players[0].cooldown_remaining > 0.0
		and not main_ui.game_state.players[0].ending_turn
		and main_ui.game_state.players[1].cooldown_remaining <= 0.0,
		"Network End Turn should start only Player 1's button cooldown."
	)
	_check(
		is_equal_approx(_player_row(1).custom_minimum_size.y, player_row_height_before_cooldown)
		and is_equal_approx(
			_players_turn_panel().get_global_rect().size.y,
			player_panel_height_before_cooldown
		),
		"Player status panel should not resize when a cooldown bar appears."
	)
	var cooldown_resource_button := _find_card_button(_hand_container(), "pebble_coin")
	_check(cooldown_resource_button != null, "Cooldown hand should include a playable Pebble Coin.")
	if cooldown_resource_button != null:
		_check(
			not cooldown_resource_button.disabled,
			"Hand cards should remain playable during End Turn cooldown."
		)
		var play_area_before: int = main_ui.game_state.player.play_area.size()
		cooldown_resource_button.pressed.emit()
		await process_frame
		_check(
			main_ui.game_state.player.play_area.size() == play_area_before + 1,
			"Playing a hand card should work during End Turn cooldown."
		)
	main_ui.game_state.player.coins = 99
	main_ui.game_state.player.buys = 1
	main_ui._refresh_ui()
	var cooldown_market_button: Button = null
	for button in _all_market_buttons():
		if not button.disabled:
			cooldown_market_button = button
			break
	_check(cooldown_market_button != null, "Market cards should remain buyable during End Turn cooldown.")
	if cooldown_market_button != null:
		var discard_before_cooldown_buy: int = main_ui.game_state.player.discard_pile.size()
		cooldown_market_button.pressed.emit()
		await process_frame
		_check(
			main_ui.game_state.player.discard_pile.size() == discard_before_cooldown_buy + 1,
			"Buying from the market should work during End Turn cooldown."
		)
	# A mid-cooldown tick must keep locking only the End Turn button: the rest of
	# the board stays interactive and is not torn down underneath the player.
	main_ui._tick_network_cooldowns(1.0)
	await process_frame
	_check(
		main_ui.turn_manager.is_cooling_down() and _end_turn_button().disabled,
		"A mid-cooldown tick should keep the End Turn button locked."
	)
	var mid_cooldown_card := _find_card_button(_hand_container(), "pebble_coin")
	_check(
		mid_cooldown_card != null and not mid_cooldown_card.disabled,
		"Hand cards should stay playable midway through the End Turn cooldown."
	)
	main_ui._tick_network_cooldowns(GameState.DEFAULT_END_TURN_COOLDOWN_SECONDS)
	await process_frame
	_check(
		not main_ui.turn_manager.is_cooling_down(),
		"A cooldown expiring should re-enable only the End Turn button."
	)
	_check(
		_player_row_count() == 4
		and _player_row(1) != null
		and _player_row(4) != null,
		"Player status should render one row for each lobby seat."
	)
	# Regression: while the host processes a guest's play request, the
	# active_player_changed refresh must not snap the view back to seat 0,
	# which made guest plays resolve out of the host's own hand.
	var host_seat0_hand: int = main_ui.game_state.players[0].hand.size()
	var host_seat1_hand: int = main_ui.game_state.players[1].hand.size()
	main_ui._handle_network_play_card_request(1, "pebble_coin")
	await process_frame
	_check(
		main_ui.game_state.players[1].hand.size() == host_seat1_hand - 1
		and main_ui.game_state.players[1].play_area.has(
			main_ui.game_state.card_catalog["pebble_coin"]
		),
		"A guest's play request should resolve from the guest's own hand."
	)
	_check(
		main_ui.game_state.players[0].hand.size() == host_seat0_hand,
		"A guest's play request must not touch the host's hand."
	)
	_check(
		main_ui.game_state.active_player_index == 0,
		"The host view should return to its own seat after handling a request."
	)
	var client_race_snapshot: Dictionary = main_ui._create_network_snapshot()
	main_ui.network_is_host = false
	main_ui.local_player_index = 0
	main_ui._apply_network_snapshot(client_race_snapshot)
	main_ui._rpc_set_local_player_index(2)
	await process_frame
	_check(
		main_ui.game_state.active_player_index == 2
		and main_ui.game_state.player.player_name == "Player 3",
		"Assigned clients should immediately view and control their player slot."
	)
	_check(
		_player_row(3) != null
		and (_player_row(3).find_child("Name", true, false) as Label).text.begins_with("Player 3"),
		"Player status should update when a client receives its assigned slot."
	)
	# Regression: a joiner that still holds a stale one-player solo game must
	# keep the seat the host assigned instead of clamping down to the host's
	# seat 0 (which made guests view and play the host's hand).
	var stale_solo_players: Array[PlayerState] = [main_ui.game_state.players[0]]
	main_ui.game_state.players = stale_solo_players
	main_ui.game_state.active_player_index = 0
	main_ui.game_state.player = main_ui.game_state.players[0]
	main_ui._rpc_set_local_player_index(1)
	await process_frame
	_check(
		main_ui.local_player_index == 1,
		"A stale solo game must not clamp a client's assigned network seat."
	)
	main_ui._apply_network_snapshot(client_race_snapshot)
	await process_frame
	_check(
		main_ui.game_state.active_player_index == 1
		and main_ui.game_state.player.player_name == "Player 2",
		"Once the snapshot lands, the reassigned client should view its own hand."
	)
	var status_row := _player_row(2)
	var status_name := status_row.find_child("Name", true, false) as Label if status_row != null else null
	_check(
		status_row != null
		and status_row.find_child("TurnBadge", true, false) != null
		and status_row.find_child("VPBadge", true, false) != null
		and status_name != null
		and status_name.clip_text
		and main_ui.right_ledger.custom_minimum_size.x >= main_ui.RIGHT_DOCK_WIDTH,
		"Player rows should keep compact turn/VP badges inside the fixed right dock."
	)
	_check(
		main_ui.player_vp_cache.size() == main_ui.game_state.players.size(),
		"Player VP values should be cached for cooldown-only status refreshes."
	)
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


func _run_expansion_ui_regression() -> void:
	# Expansion controls can resolve choices, move cards between zones, and spend
	# turn resources.  Exercise them in a disposable scene so the long-running
	# baseline smoke fixture remains untouched for its later interaction checks.
	var expansion_ui := MAIN_SCENE.instantiate()
	root.add_child(expansion_ui)
	await process_frame
	expansion_ui._start_new_game(false)
	await process_frame
	await process_frame

	_check(
		expansion_ui.expansion_panel != null
		and expansion_ui.expansion_panel.name == "ExpansionPanel"
		and expansion_ui.expansion_reserve_container.name == "ReserveMat"
		and expansion_ui.expansion_event_container.name == "EventRow",
		"The expansion surface should expose reserve/mat and event rows."
	)

	var reserve_card: CardDefinition = null
	for candidate in expansion_ui.game_state.card_catalog.values():
		var candidate_card := candidate as CardDefinition
		if candidate_card != null and candidate_card.is_reserve_card():
			reserve_card = candidate_card
			break
	if reserve_card != null:
		expansion_ui.game_state.player.store_reserve(reserve_card)
	expansion_ui.game_state.player.set_journey("smoke_journey", true)
	expansion_ui.game_state.player.add_player_token("smoke_token", 2)
	expansion_ui.game_state.player.traveller_progress["smoke_traveller"] = 2
	expansion_ui.game_state.player.coin_mat = 3
	var token_card := expansion_ui.game_state.market[0] as CardDefinition
	expansion_ui.game_state.place_supply_token(token_card.id, "smoke_marker", 2)
	expansion_ui._refresh_ui()
	_check(
		expansion_ui.expansion_journey_label.text.contains("JOURNEY")
		and expansion_ui.expansion_journey_label.text.contains("PATH 2")
		and expansion_ui.expansion_player_tokens_label.text.contains("2")
		and expansion_ui.expansion_supply_tokens_label.text.contains("2")
		and expansion_ui.expansion_coin_mat_label.text.contains("MAT 3"),
		"Journey, traveller, coin-mat, and player/supply token indicators should mirror generic state."
	)
	if reserve_card != null:
		var reserve_button: Button = null
		for child in expansion_ui.expansion_reserve_container.get_children():
			if child is Button:
				reserve_button = child as Button
				break
		_check(
			reserve_button != null
			and reserve_button.get_meta("expansion_action", "") == "reserve",
			"Reserved cards should render with a call button."
		)
		if reserve_button != null:
			reserve_button.pressed.emit()
		_check(
			expansion_ui.game_state.player.get_reserve_cards().is_empty()
			and expansion_ui.game_state.player.play_area.has(reserve_card)
			and expansion_ui.last_animation_event == "reserve_call",
			"Calling a reserve card should use the authoritative GameState path and enter play."
		)

	var saved_disabled_kingdoms: Dictionary = expansion_ui.game_state.disabled_kingdoms.duplicate(true)
	var saved_disabled_cards: Dictionary = expansion_ui.game_state.disabled_market_card_ids.duplicate(true)
	expansion_ui.game_state.disabled_kingdoms["Trailblazers"] = true
	expansion_ui.game_state.disabled_market_card_ids[token_card.id] = true
	var expansion_snapshot: Dictionary = expansion_ui._create_network_snapshot()
	_check(
		expansion_snapshot.get("disabled_kingdoms", {}).get("Trailblazers", false)
		and expansion_snapshot.get("disabled_market_card_ids", {}).get(token_card.id, false)
		and expansion_snapshot.has("events"),
		"Network snapshots should carry kingdom/card filters used to derive the event row."
	)
	expansion_ui.game_state.disabled_kingdoms = saved_disabled_kingdoms
	expansion_ui.game_state.disabled_market_card_ids = saved_disabled_cards

	var event_candidates: Array[CardDefinition] = expansion_ui.game_state.get_event_candidates()
	if not event_candidates.is_empty():
		var event_card: CardDefinition = event_candidates[0]
		expansion_ui.game_state.player.coins = expansion_ui.game_state.get_event_cost(event_card)
		expansion_ui.game_state.player.buys = 1
		expansion_ui._refresh_ui()
		var event_button := expansion_ui.expansion_event_container.get_child(0) as Button
		_check(
			event_button != null
			and event_button.get_meta("expansion_action", "") == "event",
			"Available events should render as buy buttons."
		)
		if event_button != null:
			event_button.pressed.emit()
		_check(
			expansion_ui.last_animation_event == "event_buy",
			"Buying an event should use the generic event API."
		)

	for player in expansion_ui.ui_sound_players.values():
		(player as AudioStreamPlayer).stop()
	if expansion_ui.background_music_player != null:
		expansion_ui.background_music_player.stop()
	expansion_ui.queue_free()
	await process_frame


func _hand_container() -> HBoxContainer:
	return main_ui.hand_container


func _hand_panel() -> PanelContainer:
	return main_ui.hand_panel


func _market_container() -> HBoxContainer:
	return main_ui.market_container


func _market_panel() -> PanelContainer:
	return main_ui.market_panel


func _play_area_panel() -> PanelContainer:
	return main_ui.play_area_panel


func _top_bar() -> PanelContainer:
	return main_ui.top_bar


func _relics_rail() -> PanelContainer:
	return main_ui.top_bar.find_child("RelicsRail", true, false) as PanelContainer


func _bazaar_button() -> Button:
	return main_ui.bazaar_button


func _settings_gear_button() -> Button:
	return main_ui.home_button


func _draw_pile_stack() -> Control:
	return main_ui.hud_row.find_child("DrawPileStack", true, false) as Control


func _discard_pile_stack() -> Control:
	return main_ui.hud_row.find_child("DiscardPileStack", true, false) as Control


func _players_turn_panel() -> PanelContainer:
	return main_ui.right_ledger.find_child("PlayersTurnPanel", true, false) as PanelContainer


func _player_row(index: int) -> PanelContainer:
	return _players_turn_panel().find_child("PlayerRow%d" % index, true, false) as PanelContainer


func _player_row_count() -> int:
	var count := 0
	for child in main_ui.player_status_list.get_children():
		if child.name.begins_with("PlayerRow"):
			count += 1
	return count


func _home_overlay() -> Control:
	return main_ui.get_node("HomeOverlay")


func _home_art() -> TextureRect:
	return _home_overlay().find_child("HomeArt", true, false) as TextureRect


func _home_catalogue_plate() -> PanelContainer:
	return _home_overlay().find_child("CataloguePlate", true, false) as PanelContainer


func _home_new_game_button() -> Button:
	return _home_overlay().find_child("NewGameButton", true, false) as Button


func _home_continue_button() -> Button:
	return _home_overlay().find_child("ContinueButton", true, false) as Button


func _home_multiplayer_button() -> Button:
	return _home_overlay().find_child("MultiplayerButton", true, false) as Button


func _home_multiplayer_panel() -> PanelContainer:
	return main_ui.get_node("HomeOverlay/MultiplayerPanel")


func _home_lobby_panel() -> PanelContainer:
	return main_ui.get_node("HomeOverlay/LobbyPanel")


func _home_lobby_turn_based_toggle() -> CheckButton:
	return main_ui.home_lobby_turn_based_toggle


func _home_lobby_rules_summary() -> Label:
	return main_ui.home_lobby_rules_summary


func _home_create_lobby_button() -> Button:
	return main_ui.get_node("HomeOverlay/MultiplayerPanel/Margin/Layout/Options/CreateLocalButton")


func _home_lobby_address_input() -> LineEdit:
	return main_ui.home_lobby_address_input


func _home_join_lobby_button() -> Button:
	return main_ui.get_node("HomeOverlay/MultiplayerPanel/Margin/Layout/Options/JoinLocalButton")


func _home_create_online_button() -> Button:
	return main_ui.get_node("HomeOverlay/MultiplayerPanel/Margin/Layout/Options/CreateOnlineButton")


func _home_join_online_button() -> Button:
	return main_ui.get_node("HomeOverlay/MultiplayerPanel/Margin/Layout/Options/JoinOnlineButton")


func _home_settings_button() -> Button:
	return _home_overlay().find_child("SettingsButton", true, false) as Button


func _home_kingdoms_button() -> Button:
	return _home_overlay().find_child("KingdomsButton", true, false) as Button


func _home_settings_panel() -> PanelContainer:
	return main_ui.get_node("HomeOverlay/SettingsPanel")


func _home_kingdoms_panel() -> PanelContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel")


func _home_audio_toggle() -> CheckButton:
	return main_ui.home_audio_toggle


func _home_music_toggle() -> CheckButton:
	return main_ui.home_music_toggle


func _home_motion_toggle() -> CheckButton:
	return main_ui.home_motion_toggle


func _home_noise_toggle() -> CheckButton:
	return main_ui.home_noise_toggle


func _table_noise_toggle() -> CheckButton:
	return main_ui.table_noise_toggle


func _action_speed_slider() -> HSlider:
	return main_ui.action_animation_speed_slider


func _lobby_start_button() -> Button:
	return main_ui.home_lobby_start_button


func _lobby_seat_title(index: int) -> String:
	var seat_list: VBoxContainer = main_ui.home_lobby_seat_list
	if seat_list == null or index >= seat_list.get_child_count():
		return ""
	var labels := seat_list.get_child(index).find_children("*", "Label", true, false)
	if labels.size() < 2:
		return ""
	# Row layout: avatar letter label, then the seat title label.
	return (labels[1] as Label).text


func _home_noise_overlay() -> TextureRect:
	return main_ui.home_noise_overlay


func _table_noise_overlay() -> TextureRect:
	return main_ui.table_noise_overlay


func _table_background() -> TextureRect:
	return main_ui.get_node("Background")


func _table_vignette() -> ColorRect:
	return main_ui.get_node("TableVignette")


func _kingdoms_close_button() -> Button:
	return main_ui.get_node("HomeOverlay/KingdomsPanel/Margin/Layout/Header/CloseButton")


func _kingdom_tabs() -> VBoxContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel/Margin/Layout/Browser/KingdomTabs")


func _kingdom_card_grid() -> GridContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel/Margin/Layout/Browser/CardsPane/CardScroll/CardGrid")


func _kingdom_detail_host() -> VBoxContainer:
	return main_ui.get_node("HomeOverlay/KingdomsPanel/Margin/Layout/Browser/DetailPane/Margin/DetailHost")


func _kingdom_tab(kingdom: String) -> Button:
	return main_ui.get_node(
		"HomeOverlay/KingdomsPanel/Margin/Layout/Browser/KingdomTabs/Kingdom_%s/KingdomTab"
		% main_ui._node_key(kingdom)
	)


func _kingdom_toggle(kingdom: String) -> CheckButton:
	return main_ui.get_node(
		"HomeOverlay/KingdomsPanel/Margin/Layout/Browser/KingdomTabs/Kingdom_%s/KingdomToggle"
		% main_ui._node_key(kingdom)
	)


func _kingdom_card_button(card_id: String) -> Button:
	return _home_kingdoms_panel().find_child("Card_%s" % card_id, true, false) as Button


func _kingdom_detail_card(card_id: String) -> Control:
	return _home_kingdoms_panel().find_child("DetailCard_%s" % card_id, true, false) as Control


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
	return main_ui.market_container.get_parent() as ScrollContainer


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


func _find_overlapping_hand_pair() -> Array[Control]:
	var cards: Array[Control] = []
	for child in _hand_container().get_children():
		var card := child as Control
		if card != null:
			cards.append(card)
	for first_index in range(cards.size()):
		for second_index in range(first_index + 1, cards.size()):
			if cards[first_index].get_global_rect().intersects(cards[second_index].get_global_rect()):
				return [cards[first_index], cards[second_index]]
	return []


func _top_market_faces_have_grouped_gaps() -> bool:
	var faces := _top_market_faces()
	if faces.size() < 2:
		return false
	var expected_gaps := [
		main_ui.MARKET_CARD_GAP,
		main_ui.MARKET_GROUP_GAP,
		main_ui.MARKET_CARD_GAP,
		main_ui.MARKET_CARD_GAP,
		main_ui.MARKET_CARD_GAP,
		main_ui.MARKET_CARD_GAP,
		main_ui.MARKET_GROUP_GAP,
		main_ui.MARKET_CARD_GAP,
	]
	if faces.size() - 1 != expected_gaps.size():
		return false
	for index in range(faces.size() - 1):
		var current_rect := faces[index].get_global_rect()
		var next_rect := faces[index + 1].get_global_rect()
		if not is_equal_approx(
			next_rect.position.x - current_rect.end.x,
			expected_gaps[index]
		):
			return false
	return true


func _top_market_faces() -> Array[Control]:
	var target_y := INF
	for container in [_treasury_cards(), _barracks_cards(), _estates_cards()]:
		for child in container.get_children():
			target_y = minf(target_y, (child as Control).get_global_rect().position.y)
	var faces: Array[Control] = []
	for container in [_treasury_cards(), _barracks_cards(), _estates_cards()]:
		for child in container.get_children():
			var face := child as Control
			if is_equal_approx(face.get_global_rect().position.y, target_y):
				faces.append(face)
	for side_face in [main_ui.pebble_coin_side_supply, main_ui.briar_hex_side_supply]:
		var side_control := side_face as Control
		if side_control != null and is_equal_approx(side_control.get_global_rect().position.y, target_y):
			faces.append(side_control)
	faces.sort_custom(_market_face_before)
	return faces


func _central_market_rows_have_equal_gaps() -> bool:
	var buttons := _barracks_cards().get_children()
	if buttons.size() != GameState.MARKET_CENTRAL_COUNT:
		return false
	for row_start in [0, 5]:
		for index in range(row_start, row_start + 4):
			var current_rect := (buttons[index] as Control).get_global_rect()
			var next_rect := (buttons[index + 1] as Control).get_global_rect()
			if not is_equal_approx(
				next_rect.position.x - current_rect.end.x,
				main_ui.MARKET_CARD_GAP
			):
				return false
	return true


func _market_face_before(first: Control, second: Control) -> bool:
	return first.get_global_rect().position.x < second.get_global_rect().position.x


func _container_has_type(container: GridContainer, card_type: String) -> bool:
	for child in container.get_children():
		if child.get_meta("card_type", "") != card_type:
			return false
	return true


func _container_holds_only_ids(container: GridContainer, ids: Array) -> bool:
	for child in container.get_children():
		if not ids.has(str(child.get_meta("card_id", ""))):
			return false
	return true


func _container_holds_no_ids(container: GridContainer, ids: Array) -> bool:
	for child in container.get_children():
		if ids.has(str(child.get_meta("card_id", ""))):
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
	return main_ui.play_area_container


func _end_turn_button() -> Button:
	return main_ui.end_turn_button


func _home_button() -> Button:
	return main_ui.home_button


func _card_preview() -> PanelContainer:
	return main_ui.get_node("CardPreview")


func _relic_preview() -> PanelContainer:
	return main_ui.get_node("RelicPreview")


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


func _end_game_home_button() -> Button:
	return main_ui.get_node(
		"EndGameOverlay/Center/Panel/Margin/Layout/HomeButton"
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


func _card_art_scrim(button: Button) -> ColorRect:
	return button.get_node("CardContent/CardLayout/ArtFrame/ArtScrim")


func _card_text_scrim(button: Button) -> Panel:
	return button.get_node("CardContent/CardLayout/TextScrim")


func _card_text_scrim_alpha(button: Button) -> float:
	var style := _card_text_scrim(button).get_theme_stylebox("panel") as StyleBoxFlat
	return style.bg_color.a if style != null else 1.0


func _card_art_coverage(button: Button) -> float:
	var art_frame := _card_art(button).get_parent() as Control
	var art_rect := _card_art(button)
	return minf(art_frame.size.y, art_rect.size.y) / button.custom_minimum_size.y


func _card_name(button: Button) -> Label:
	return button.get_node("CardContent/CardLayout/NameLabel")


func _card_effect(button: Button) -> RichTextLabel:
	return button.get_node("CardContent/CardLayout/EffectSlot/EffectCenter/EffectLabel")


func _card_price(button: Button) -> Label:
	return button.get_node("PriceBadge/CostLabel")


func _hand_is_fanned() -> bool:
	# A real fan: rotation rises monotonically from a negative left edge through
	# ~0 in the middle to a positive right edge (not a flat / podium row).
	var cards := _hand_container().get_children()
	if cards.size() < 3:
		return true
	var first := (cards[0] as Control).rotation_degrees
	var last := (cards[cards.size() - 1] as Control).rotation_degrees
	var mid := (cards[cards.size() / 2] as Control).rotation_degrees
	return first < mid and mid < last and absf(last - first) >= 8.0


func _card_text_layout_is_clear(button: Button) -> bool:
	var content := button.get_node("CardContent") as MarginContainer
	var name_label := _card_name(button)
	var art_frame := _card_art(button).get_parent() as Control
	var effect_slot := button.get_node("CardContent/CardLayout/EffectSlot") as MarginContainer
	var effect_center := button.get_node("CardContent/CardLayout/EffectSlot/EffectCenter") as VBoxContainer
	var effect_label := _card_effect(button)
	var meta_row := button.get_node("CardContent/CardLayout/MetaRow") as Control
	var price_badge := button.get_node("PriceBadge") as Control
	var text_scrim := _card_text_scrim(button)
	var price_label := _card_price(button)
	var button_rect := button.get_global_rect()
	var safe_rect := button_rect.grow(4.0)
	var regions: Array[Control] = [
		art_frame,
		text_scrim,
		name_label,
		effect_slot,
		effect_label,
		meta_row,
	]
	var footer_gap := button_rect.end.y - meta_row.get_global_rect().end.y

	if (
		content.get_theme_constant("margin_top") != 0
		or content.get_theme_constant("margin_bottom") != 0
		or name_label.custom_minimum_size.y < main_ui.CARD_NAME_HEIGHT
		or name_label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER
		or effect_slot.get_theme_constant("margin_left") != 7
		or effect_slot.get_theme_constant("margin_right") != 7
		or effect_center.alignment != BoxContainer.ALIGNMENT_BEGIN
		or _card_art_coverage(button) < 0.54
		or _card_art_coverage(button) > 0.62
		or _card_text_scrim_alpha(button) > 0.96
		or not price_badge.has_node("CoinFace")
		or not price_badge.has_node("InnerRing")
		or not price_badge.has_node("CoinRivet")
		or price_label.offset_left != 0
		or price_label.offset_top != 1
	):
		return false

	for region in regions:
		var region_rect := region.get_global_rect()
		if not safe_rect.encloses(region_rect):
			return false

	return (
		art_frame.get_global_rect().position.y <= button_rect.position.y + 8.0
		and art_frame.get_global_rect().end.y <= text_scrim.get_global_rect().position.y + 1.0
		and text_scrim.get_global_rect().position.y <= name_label.get_global_rect().position.y
		# The title and rules boxes intentionally overlap by a few pixels after
		# lifting the three-line rules area; their actual glyph baselines remain
		# separated, while the larger boxes stay inside the face.
		and name_label.get_global_rect().end.y
			<= effect_slot.get_global_rect().position.y + main_ui.CARD_EFFECT_LIFT
		and effect_label.get_global_rect().position.y >= effect_slot.get_global_rect().position.y
		and effect_label.get_global_rect().end.y <= meta_row.get_global_rect().position.y + 4.0
		and footer_gap >= 0.0
		and footer_gap <= 12.0
		and button_rect.grow(2.0).encloses(price_badge.get_global_rect())
		and art_frame.get_global_rect().encloses(price_badge.get_global_rect())
	)


func _market_pile_label(button: Button) -> Label:
	return button.get_node("PileBadge/PileRow/PileLabel")


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


func _click_control(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = center
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.position = center
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release, true)


func _right_click_control(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = center
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	root.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.position = center
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	root.push_input(release, true)


func _unique_string_count(values: Array[String]) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[value] = true
	return unique.size()


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


func _music_uses_afterlight_ambience_mp3() -> bool:
	return (
		main_ui.BACKGROUND_MUSIC_PATH == "res://assets/audio/afterlight_catalogue_ambience.mp3"
		and main_ui.background_music_player.stream is AudioStreamMP3
	)


func _background_music_slider() -> HSlider:
	return main_ui.background_music_slider


func _cleanup_main_ui() -> void:
	for player in main_ui.ui_sound_players.values():
		(player as AudioStreamPlayer).stop()
	if main_ui.background_music_player != null:
		main_ui.background_music_player.stop()
	main_ui.free()
	main_ui = null


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error("[Test] %s" % message)
