extends SceneTree

# End-to-end online multiplayer test: a host UI and a guest UI in the same
# process talk through the real relay server over local HTTP.
#
# Run the relay first, then the test:
#   $env:PORT = '3123'; node api/relay.js
#   godot --headless --path . --script res://tests/relay_e2e_test.gd
#
# Covers the reported multiplayer bugs end to end:
#   1. A guest holding a stale solo game used to get its assigned seat clamped
#      to seat 0 and would view the host's hand.
#   2. The host's lobby seat list did not show a joiner until they readied up.
#   3. While the host processed a guest's play request, the refresh triggered
#      by active_player_changed snapped the view back to the host's seat, so
#      guest plays resolved out of the host's hand.

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const DEFAULT_RELAY_URL := "http://127.0.0.1:3123/api/relay"

var failure_count := 0
var host_ui: Control
var guest_ui: Control


func _initialize() -> void:
	var relay_url := OS.get_environment("CONQUEST_CARTES_TEST_RELAY_URL")
	if relay_url.is_empty():
		relay_url = DEFAULT_RELAY_URL
	root.size = Vector2i(1280, 720)
	host_ui = MAIN_SCENE.instantiate()
	root.add_child(host_ui)
	guest_ui = MAIN_SCENE.instantiate()
	root.add_child(guest_ui)
	await process_frame
	host_ui.online_relay_url_override = relay_url
	guest_ui.online_relay_url_override = relay_url

	# The reported repro: the guest played a solo game before joining, so a
	# stale one-player game sits in its state.
	guest_ui._start_new_game(false)
	await process_frame
	_check(
		guest_ui.game_state.players.size() == 1,
		"Guest should hold a stale one-player solo game before joining."
	)
	guest_ui._show_home_screen(false)
	await process_frame

	# Host creates an online lobby through the real relay.
	host_ui.lobby_max_players = 2
	host_ui.lobby_pending_mode = "host_online"
	host_ui._host_online_lobby()
	await _wait_until(func(): return not host_ui.online_relay_lobby_code.is_empty(), 10.0)
	if host_ui.online_relay_lobby_code.is_empty():
		push_error(
			"[E2E] No lobby code. Is the relay running? Start it with: "
			+ "$env:PORT = '3123'; node api/relay.js"
		)
		quit(1)
		return
	print("[E2E] Lobby code: %s" % host_ui.online_relay_lobby_code)

	# Guest joins with the code.
	guest_ui.lobby_pending_mode = "join_online"
	guest_ui.home_lobby_address_input.text = host_ui.online_relay_lobby_code
	guest_ui._join_online_lobby()
	await _wait_until(func(): return guest_ui.online_relay_connected, 10.0)
	_check(guest_ui.online_relay_connected, "Guest should connect to the lobby.")

	# Bug 1 regression: the guest keeps its assigned seat despite the stale game.
	await _wait_until(func(): return guest_ui.game_state.players.size() >= 2, 10.0)
	_check(
		guest_ui.local_player_index == 1,
		"Guest with a stale solo game should still be seated at seat 1, got %d."
		% guest_ui.local_player_index
	)

	# Bug 2 regression: the host's seat list shows the joiner before ready-up.
	await _wait_until(func(): return _host_seat_title(1).begins_with("Player 2"), 10.0)
	_check(
		_host_seat_title(1).begins_with("Player 2"),
		"Host seat list should show the joiner before they ready up, got '%s'."
		% _host_seat_title(1)
	)

	# Guest readies up, host opens the table.
	guest_ui._on_lobby_start_pressed()
	await _wait_until(func(): return host_ui.network_ready_seats.has(1), 10.0)
	_check(host_ui.network_ready_seats.has(1), "Host should record the guest as ready.")
	host_ui._on_lobby_start_pressed()
	await _wait_until(func(): return guest_ui.network_table_open, 10.0)
	_check(guest_ui.network_table_open, "Guest should enter the table when the host starts.")

	# Both seats open in the reading respite; skip it so the play regressions run.
	host_ui._end_respite()
	guest_ui._end_respite()
	# Keep this regression focused and quick while still using the real
	# authoritative cooldown/snapshot path.
	host_ui.game_state.end_turn_cooldown_seconds = 0.5
	host_ui._broadcast_network_snapshot()
	await process_frame

	# The guest must be viewing its own seat, not the host's hand.
	_check(
		guest_ui.game_state.active_player_index == 1,
		"Guest view should sit on seat 1, got %d." % guest_ui.game_state.active_player_index
	)

	# The action-phase button intentionally only opens BUY. The first completed
	# guest turn must then clean up and redraw from the host-authoritative state.
	if guest_ui.game_state.is_action_phase():
		guest_ui._on_end_turn_pressed()
		await _wait_until(func(): return guest_ui.game_state.is_buy_phase(), 10.0)
	_check(guest_ui.game_state.is_buy_phase(), "Guest should enter BUY before ending the turn.")
	var guest_turn_before: int = guest_ui.game_state.players[1].turn_number
	guest_ui._on_end_turn_pressed()
	await _wait_until(
		func(): return host_ui.game_state.players[1].cooldown_remaining > 0.0,
		10.0
	)
	_check(
		host_ui.game_state.players[1].cooldown_remaining > 0.0,
		"Host should start the guest's end-turn cooldown."
	)
	await _wait_until(
		func(): return host_ui.game_state.players[1].turn_number > guest_turn_before,
		10.0
	)
	_check(
		host_ui.game_state.players[1].turn_number == guest_turn_before + 1,
		"Host should increment the guest turn after authoritative cleanup."
	)
	await _wait_until(
		func(): return guest_ui.game_state.players[1].turn_number > guest_turn_before,
		10.0
	)
	var guest_hand_after := _card_ids(guest_ui.game_state.players[1].hand)
	_check(
		guest_ui.game_state.players[1].turn_number == guest_turn_before + 1
		and guest_hand_after == _card_ids(host_ui.game_state.players[1].hand)
		and guest_hand_after.size()
			== host_ui.game_state.get_turn_draw_count(host_ui.game_state.players[1]),
		"Guest should receive the fresh hand and incremented turn after cleanup."
	)

	# Bug 3 regression: a guest play must leave seat 1's hand on the host and
	# never touch the host's own hand (seat 0).
	var host_seat0_before: int = host_ui.game_state.players[0].hand.size()
	var host_seat1_before: int = host_ui.game_state.players[1].hand.size()
	var pebble: CardDefinition = null
	for card in guest_ui.game_state.player.hand:
		if card.id == "pebble_coin":
			pebble = card
			break
	_check(pebble != null, "Guest starting hand should include a Pebble Coin.")
	if pebble != null:
		guest_ui._on_hand_card_pressed(pebble)
		await _wait_until(
			func(): return host_ui.game_state.players[1].hand.size() == host_seat1_before - 1,
			10.0
		)
		_check(
			host_ui.game_state.players[1].hand.size() == host_seat1_before - 1,
			"Guest card play should come out of the guest's own hand."
		)
		_check(
			host_ui.game_state.players[0].hand.size() == host_seat0_before,
			"Guest card play must not touch the host's hand."
		)
		await _wait_until(
			func(): return guest_ui.game_state.players[1].play_area.size() >= 1,
			10.0
		)
		_check(
			guest_ui.game_state.players[1].play_area.size() >= 1,
			"Guest should see its played card in its own play area after the snapshot."
		)

	# Host plays a card too; only seat 0's public play area changes.  The
	# snapshot intentionally redacts opponents' hand identities, so the guest
	# cannot observe a hand-size decrement there; play-area cards are public.
	var guest_view_seat0_play_before: int = guest_ui.game_state.players[0].play_area.size()
	var host_pebble: CardDefinition = null
	for card in host_ui.game_state.player.hand:
		if card.id == "pebble_coin":
			host_pebble = card
			break
	_check(host_pebble != null, "Host starting hand should include a Pebble Coin.")
	if host_pebble != null:
		var host_seat1_hand: int = host_ui.game_state.players[1].hand.size()
		host_ui._on_hand_card_pressed(host_pebble)
		await _wait_until(
			func(): return guest_ui.game_state.players[0].play_area.size() == guest_view_seat0_play_before + 1,
			10.0
		)
		_check(
			guest_ui.game_state.players[0].play_area.size() == guest_view_seat0_play_before + 1,
			"Guest should see the host's play reflected on seat 0."
		)
		_check(
			host_ui.game_state.players[1].hand.size() == host_seat1_hand,
			"Host card play must not touch the guest's hand."
		)

	_finish()


func _host_seat_title(index: int) -> String:
	var seat_list: VBoxContainer = host_ui.home_lobby_seat_list
	if seat_list == null or index >= seat_list.get_child_count():
		return ""
	var labels := seat_list.get_child(index).find_children("*", "Label", true, false)
	if labels.size() < 2:
		return ""
	return (labels[1] as Label).text


func _card_ids(cards: Array) -> Array[String]:
	var ids: Array[String] = []
	for card in cards:
		if card is CardDefinition:
			ids.append((card as CardDefinition).id)
	return ids


func _wait_until(condition: Callable, timeout_seconds: float) -> void:
	var waited := 0.0
	while waited < timeout_seconds:
		if condition.call():
			return
		await create_timer(0.1).timeout
		waited += 0.1


func _check(passed: bool, message: String) -> void:
	if passed:
		print("[E2E] PASS: %s" % message)
	else:
		failure_count += 1
		push_error("[E2E] FAIL: %s" % message)


func _finish() -> void:
	host_ui._disconnect_network()
	guest_ui._disconnect_network()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	if failure_count > 0:
		push_error("[E2E] Relay end-to-end test failed with %d issue(s)." % failure_count)
		quit(1)
	else:
		print("[E2E] Relay end-to-end test passed.")
		quit(0)
