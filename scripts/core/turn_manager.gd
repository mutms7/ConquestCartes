class_name TurnManager
extends RefCounted

signal game_ended(final_score: int)
signal turn_completed(game_is_over: bool)
signal turn_cooldown_started(duration: float)
signal turn_cleanup_started

var game_state: GameState
var turn_number: int = 1
var game_over: bool = false
var final_score: int = 0
var final_scores: Array[int] = []
var ending_turn: bool = false
var cooldown_remaining: float = 0.0
var cooldown_duration: float = 0.0


func configure(state: GameState) -> void:
	if game_state != null:
		if game_state.cleanup_completed.is_connected(_on_cleanup_completed):
			game_state.cleanup_completed.disconnect(_on_cleanup_completed)
		if game_state.end_turn_cooldown_reduced.is_connected(_on_end_turn_cooldown_reduced):
			game_state.end_turn_cooldown_reduced.disconnect(_on_end_turn_cooldown_reduced)
	game_state = state
	game_state.cleanup_completed.connect(_on_cleanup_completed)
	game_state.end_turn_cooldown_reduced.connect(_on_end_turn_cooldown_reduced)


func start_first_turn() -> void:
	turn_number = 1
	game_over = false
	final_score = 0
	final_scores.clear()
	ending_turn = false
	cooldown_remaining = 0.0
	cooldown_duration = 0.0
	game_state.start_all_players()
	turn_number = game_state.player.turn_number
	print("[Game] Start turn %d for %s" % [turn_number, game_state.get_active_player_name()])


func end_turn() -> void:
	if game_over or game_state.has_pending_choice() or ending_turn:
		return

	cooldown_duration = game_state.get_end_turn_cooldown_seconds()
	cooldown_remaining = cooldown_duration
	ending_turn = true
	print(
		"[Game] End turn %d for %s in %.1f seconds"
		% [turn_number, game_state.get_active_player_name(), cooldown_duration]
	)
	turn_cooldown_started.emit(cooldown_duration)
	turn_cleanup_started.emit()
	game_state.begin_cleanup()


func tick(delta: float) -> void:
	if game_over or not ending_turn:
		return
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if cooldown_remaining > 0.0:
		return
	ending_turn = false
	cooldown_duration = 0.0


func is_cooling_down() -> bool:
	return ending_turn and cooldown_remaining > 0.0


func _on_end_turn_cooldown_reduced(amount: float) -> void:
	if not ending_turn or cooldown_remaining <= 0.0:
		return
	cooldown_remaining = maxf(0.0, cooldown_remaining - maxf(0.0, amount))


func _on_cleanup_completed() -> void:
	if not ending_turn:
		return
	game_state.reset_turn_resources()

	if game_state.is_game_end_condition_met():
		ending_turn = false
		cooldown_remaining = 0.0
		cooldown_duration = 0.0
		game_over = true
		final_scores = game_state.calculate_all_scores()
		final_score = final_scores[game_state.active_player_index] if not final_scores.is_empty() else 0
		game_ended.emit(final_score)
		turn_completed.emit(true)
		return

	game_state.player.turn_number += 1
	game_state.draw_cards(5)
	turn_number = game_state.player.turn_number
	print("[Game] Start turn %d for %s" % [turn_number, game_state.get_active_player_name()])
	turn_completed.emit(false)
