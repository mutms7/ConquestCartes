class_name PlayerState
extends RefCounted

var draw_pile: Array[CardDefinition] = []
var hand: Array[CardDefinition] = []
var play_area: Array[CardDefinition] = []
var discard_pile: Array[CardDefinition] = []
var trash_pile: Array[CardDefinition] = []
# Cards set aside until the start of the owner's next turn (e.g. Sowing Moon).
var set_aside_pile: Array[CardDefinition] = []
# Duration bookkeeping: cards that stay in play through the next cleanup, and
# the "next turn" effect payloads waiting to resolve at the next turn start.
var duration_hold: Array[CardDefinition] = []
var pending_duration_effects: Array[Dictionary] = []

var player_name: String = "Player"
var turn_number: int = 1
# Conquest-long relic boons and the current unclaimed draft offer (relic ids).
var relics: Array[String] = []
var pending_relic_offer: Array[String] = []
# End-of-game scoring relic drafted in solo play (empty until chosen). Grants
# bonus victory points at the final tally based on the player's playstyle.
var scoring_relic: String = ""
var end_turn_cooldown_reduction: float = 0.0
# Persists for the whole conquest (game); not reset each turn.
var game_cooldown_reduction: float = 0.0
var turn_flags: Dictionary = {}
var pending_choice: CardChoice
var resolution_queue: Array[Dictionary] = []
var cleanup_in_progress: bool = false
var ending_turn: bool = false
var cooldown_remaining: float = 0.0
var cooldown_duration: float = 0.0

var coins: int = 0
var actions: int = 1
var buys: int = 1

# Tallies kept for the end-game fun awards (not scored).
var times_attacked: int = 0


func clear_all() -> void:
	draw_pile.clear()
	hand.clear()
	play_area.clear()
	discard_pile.clear()
	trash_pile.clear()
	set_aside_pile.clear()
	duration_hold.clear()
	pending_duration_effects.clear()
	turn_number = 1
	relics.clear()
	pending_relic_offer.clear()
	scoring_relic = ""
	times_attacked = 0
	turn_flags.clear()
	pending_choice = null
	resolution_queue.clear()
	cleanup_in_progress = false
	ending_turn = false
	cooldown_remaining = 0.0
	cooldown_duration = 0.0
	game_cooldown_reduction = 0.0
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
	cards.append_array(set_aside_pile)
	return cards
