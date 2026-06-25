class_name TurnManager
extends RefCounted

signal game_ended(final_score: int)
signal turn_completed(game_is_over: bool)

var game_state: GameState
var turn_number: int = 1
var maximum_turns: int = 15
var game_over: bool = false
var final_score: int = 0
var ending_turn: bool = false


func configure(state: GameState) -> void:
	if game_state != null and game_state.cleanup_completed.is_connected(_on_cleanup_completed):
		game_state.cleanup_completed.disconnect(_on_cleanup_completed)
	game_state = state
	game_state.cleanup_completed.connect(_on_cleanup_completed)


func start_first_turn() -> void:
	turn_number = 1
	game_over = false
	final_score = 0
	ending_turn = false
	game_state.reset_turn_resources()
	game_state.draw_cards(5)
	print("[Game] Start turn %d" % turn_number)


func end_turn() -> void:
	if game_over or game_state.has_pending_choice() or ending_turn:
		return

	print("[Game] End turn %d" % turn_number)
	ending_turn = true
	game_state.begin_cleanup()


func _on_cleanup_completed() -> void:
	if not ending_turn:
		return
	ending_turn = false
	game_state.reset_turn_resources()

	if turn_number >= maximum_turns:
		game_over = true
		final_score = game_state.calculate_score()
		game_ended.emit(final_score)
		turn_completed.emit(true)
		return

	turn_number += 1
	game_state.draw_cards(5)
	print("[Game] Start turn %d" % turn_number)
	turn_completed.emit(false)
