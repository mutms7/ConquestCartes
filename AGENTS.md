# Project Rules

- This is a Godot 4 project written in GDScript.
- The Trailblazers expansion is an authorized, faithful implementation of
  Dominion: Adventures. Use the official card names, rules text, terminology,
  and mechanics for that expansion.
- Keep card definitions data-driven and separate from game logic.
- When creating or revising cards, follow `docs/card_wording_conventions.md`
  and the card creation process in `docs/card_design_rules.md`.
- Keep UI code separate from rules logic.
- Do not hardcode card behavior into card UI nodes.
- The end-turn cooldown is a multiplayer-only pacing mechanic. Singleplayer
  ("New Game") must have no end-turn timeout; the cooldown only applies in online
  "Create Lobby"/"Join Lobby" games (gated by `GameState.multiplayer_enabled` in
  `get_end_turn_cooldown_seconds`). Never block hand or market card clicks while a
  cooldown counts down. Card play is gated by `_can_play_card`, which must not
  check the cooldown; only the End Turn button itself is disabled during cooldown.
  Do not broadcast a network snapshot every frame while a cooldown ticks: clients
  run their own local countdown, and a per-frame snapshot rebuilds their board and
  swallows clicks. Broadcast only when a cooldown expires (see `_tick_network_cooldowns`).
- Keep changes small, readable, and reviewable.
- Do not delete asset license files.
- Every feature must run in Godot without parse errors.
- Before every push to any branch, run both headless smoke suites from the
  repository root and require them to pass:
  `godot --headless --path . --script res://tests/smoke_test.gd` and
  `godot --headless --path . --script res://tests/ui_smoke_test.gd`.
  Do not push if either suite fails.
- After completing and testing requested changes, commit and push all intended
  repository changes to the active branch unless the user explicitly asks not to.
