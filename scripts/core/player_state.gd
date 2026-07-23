class_name PlayerState
extends RefCounted

var draw_pile: Array[CardDefinition] = []
var hand: Array[CardDefinition] = []
var play_area: Array[CardDefinition] = []
# Transient UI records for each individual resolution of a played card.  A
# replayed card remains one physical card in play_area for cleanup, but gets a
# record per resolution here so the in-play UI can render 1/2, 2/2, etc.
var play_display_records: Array[Dictionary] = []
var discard_pile: Array[CardDefinition] = []
var trash_pile: Array[CardDefinition] = []
# Cards set aside until the start of the owner's next turn (e.g. Sowing Moon).
var set_aside_pile: Array[CardDefinition] = []
# Reserve cards live on a persistent mat instead of in play/discard.  The mat
# is intentionally a normal card array so it can be copied to a network view
# using the same card-id zone serializer as the other zones.
var reserve_mat: Array[CardDefinition] = []
# Expansion state is data-shaped and therefore safe to include in snapshots.
# player_tokens is for tokens owned by this player; supply_tokens belongs to the
# shared GameState and is not duplicated here.
var player_tokens: Dictionary = {}
var journey_state: Dictionary = {}
var traveller_progress: Dictionary = {}
var coin_mat: int = 0
# Compatibility aliases used by older snapshot/UI adapters.  They are true
# accessors (not duplicated dictionaries), so setting an alias from a network
# payload updates the canonical expansion state.
var tokens: Dictionary:
	get:
		return player_tokens
	set(value):
		player_tokens = value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}
var journey_tokens: Dictionary:
	get:
		return journey_state
	set(value):
		journey_state = value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}
var trail_tokens: Dictionary:
	get:
		return traveller_progress
	set(value):
		traveller_progress = value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}
# Duration bookkeeping: cards that stay in play through the next cleanup, and
# the "next turn" effect payloads waiting to resolve at the next turn start.
var duration_hold: Array[CardDefinition] = []
var pending_duration_effects: Array[Dictionary] = []

var player_name: String = "Player"
var turn_number: int = 1
# Conquest-long relic boons and the current unclaimed draft offer (relic ids).
var relics: Array[String] = []
var pending_relic_offer: Array[String] = []
# Optional two-stage context for effects that replace an existing relic.  The
# dictionary is deliberately data-shaped (stage/replaced_relic_id) so it can be
# copied into network snapshots without depending on a UI node or card id.
var pending_relic_replacement: Dictionary = {}
# End-of-game scoring relic drafted in solo play (empty until chosen). Grants
# bonus victory points at the final tally based on the player's playstyle.
var scoring_relic: String = ""
# Victory-point tokens are kept outside the deck and are added directly to the
# final tally (Bishop, Monument, and Investment-style effects use these).
var vp_tokens: int = 0
var end_turn_cooldown_reduction: float = 0.0
# Persists for the whole conquest (game); not reset each turn.
var game_cooldown_reduction: float = 0.0
var turn_flags: Dictionary = {}
# Each turn runs in two phases: "action" (only action cards may be played) and
# "buy" (only treasures may be played and purchases are allowed). Play advances
# to the buy phase automatically once no action can be played, or manually when
# the player ends the action phase.
var turn_phase: String = "action"
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
	clear_play_display_records()
	discard_pile.clear()
	trash_pile.clear()
	set_aside_pile.clear()
	reserve_mat.clear()
	player_tokens.clear()
	journey_state.clear()
	traveller_progress.clear()
	coin_mat = 0
	duration_hold.clear()
	pending_duration_effects.clear()
	turn_number = 1
	relics.clear()
	pending_relic_offer.clear()
	pending_relic_replacement.clear()
	scoring_relic = ""
	vp_tokens = 0
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
	turn_phase = "action"
	end_turn_cooldown_reduction = 0.0
	turn_flags.clear()
	clear_play_display_records()


func register_play_display(card: CardDefinition, repetitions: int = 1) -> void:
	if card == null:
		return
	var total := maxi(1, repetitions)
	for occurrence in range(1, total + 1):
		play_display_records.append({
			"card": card,
			"occurrence": occurrence,
			"total": total,
		})


func get_play_display_records() -> Array[Dictionary]:
	return play_display_records.duplicate()


func clear_play_display_records() -> void:
	play_display_records.clear()


func get_all_cards() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	cards.append_array(draw_pile)
	cards.append_array(hand)
	cards.append_array(play_area)
	cards.append_array(discard_pile)
	cards.append_array(set_aside_pile)
	cards.append_array(reserve_mat)
	return cards


func get_player_token(token_id: String) -> int:
	return int(player_tokens.get(token_id, 0))


func add_player_token(token_id: String, amount: int = 1) -> int:
	if token_id.is_empty() or amount == 0:
		return get_player_token(token_id)
	var next_value := maxi(0, get_player_token(token_id) + amount)
	if next_value == 0:
		player_tokens.erase(token_id)
	else:
		player_tokens[token_id] = next_value
	return next_value


func remove_player_token(token_id: String, amount: int = 1) -> int:
	return add_player_token(token_id, -maxi(0, amount))


func set_journey(journey_id: String, active: bool = true) -> void:
	if journey_id.is_empty():
		return
	journey_state[journey_id] = active


func is_journey_active(journey_id: String) -> bool:
	return bool(journey_state.get(journey_id, false))


func store_reserve(card: CardDefinition) -> bool:
	if card == null or reserve_mat.has(card):
		return false
	reserve_mat.append(card)
	return true


func call_reserve(card: CardDefinition) -> bool:
	if card == null:
		return false
	var index := reserve_mat.find(card)
	if index < 0:
		return false
	reserve_mat.remove_at(index)
	return true


func get_reserve_cards() -> Array[CardDefinition]:
	return reserve_mat.duplicate()


func get_reserve_mat() -> Array[CardDefinition]:
	return get_reserve_cards()


func get_journey_state() -> Dictionary:
	return journey_state.duplicate(true)
