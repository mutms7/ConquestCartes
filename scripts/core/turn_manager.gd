class_name TurnManager
extends RefCounted

signal game_ended(final_score: int)

var game_state: GameState
var turn_number: int = 1
var maximum_turns: int = 15
var game_over: bool = false
var final_score: int = 0


func configure(state: GameState) -> void:
	game_state = state


func start_first_turn() -> void:
	turn_number = 1
	game_over = false
	final_score = 0
	game_state.reset_turn_resources()
	game_state.draw_cards(5)
	print("[Game] Start turn %d" % turn_number)


func end_turn() -> void:
	if game_over or game_state.has_pending_choice():
		return

	print("[Game] End turn %d" % turn_number)
	game_state.discard_hand_and_play_area()
	game_state.reset_turn_resources()

	if turn_number >= maximum_turns:
		game_over = true
		final_score = game_state.calculate_score()
		game_ended.emit(final_score)
		return

	turn_number += 1
	game_state.draw_cards(5)
	print("[Game] Start turn %d" % turn_number)
