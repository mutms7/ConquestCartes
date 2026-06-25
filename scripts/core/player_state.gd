class_name PlayerState
extends RefCounted

var draw_pile: Array[CardDefinition] = []
var hand: Array[CardDefinition] = []
var play_area: Array[CardDefinition] = []
var discard_pile: Array[CardDefinition] = []
var trash_pile: Array[CardDefinition] = []

var coins: int = 0
var actions: int = 1
var buys: int = 1


func clear_all() -> void:
	draw_pile.clear()
	hand.clear()
	play_area.clear()
	discard_pile.clear()
	trash_pile.clear()
	reset_turn_resources()


func reset_turn_resources() -> void:
	coins = 0
	actions = 1
	buys = 1


func get_all_cards() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	cards.append_array(draw_pile)
	cards.append_array(hand)
	cards.append_array(play_area)
	cards.append_array(discard_pile)
	return cards
