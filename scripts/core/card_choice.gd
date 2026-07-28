class_name CardChoice
extends RefCounted

var id: int = 0
var prompt: String = ""
var minimum: int = 1
var maximum: int = 1
var confirm_text: String = "CONFIRM"
var skip_text: String = "SKIP"
var resolver: String = ""
var candidates: Array[Dictionary] = []
var context: Dictionary = {}


func add_candidate(token: String, card: CardDefinition, subtitle: String = "") -> void:
	candidates.append({
		"token": token,
		"card": card,
		"subtitle": subtitle,
	})


func is_valid_selection(tokens: Array[String]) -> bool:
	if tokens.size() < minimum or tokens.size() > maximum:
		return false
	var known_tokens: Dictionary = {}
	for candidate in candidates:
		known_tokens[str(candidate.get("token", ""))] = true
	var seen: Dictionary = {}
	for token in tokens:
		if not known_tokens.has(token) or seen.has(token):
			return false
		seen[token] = true
	return true


func get_selected_entries(tokens: Array[String]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for token in tokens:
		for candidate in candidates:
			if str(candidate.get("token", "")) == token:
				entries.append(candidate)
				break
	return entries
