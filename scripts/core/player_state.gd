class_name PlayerState
extends RefCounted

var draw_pile: Array[CardDefinition] = []
var hand: Array[CardDefinition] = []
var play_area: Array[CardDefinition] = []
var discard_pile: Array[CardDefinition] = []
var trash_pile: Array[CardDefinition] = []

var player_name: String = "Player"
var turn_number: int = 1
var end_turn_cooldown_reduction: float = 0.0
var turn_flags: Dictionary = {}
var pending_choice: CardChoice
var resolution_queue: Array[Dictionary] = []
var cleanup_in_progress: bool = false

var coins: int = 0
var actions: int = 1
var buys: int = 1


func clear_all() -> void:
	draw_pile.clear()
	hand.clear()
	play_area.clear()
	discard_pile.clear()
	trash_pile.clear()
	turn_number = 1
	turn_flags.clear()
	pending_choice = null
	resolution_queue.clear()
	cleanup_in_progress = false
	reset_turn_resources()


func reset_turn_resources() -> void:
	coins = 0
	actions = 1
	buys = 1
	end_turn_cooldown_reduction = 0.0
	turn_flags.clear()


func get_all_cards() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	cards.append_array(draw_pile)
	cards.append_array(hand)
	cards.append_array(play_area)
	cards.append_array(discard_pile)
	return cards
