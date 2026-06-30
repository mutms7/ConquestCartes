extends SceneTree

# Loads the main UI, drives it to each screen, and saves PNG screenshots
# to user:// (and a copy under res://_shots). Run with:
#   godot --path . --script res://tests/screenshot_harness.gd

const SHOT_DIR := "res://_shots"


func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := DirAccess.open("res://")
	if dir != null and not dir.dir_exists("_shots"):
		dir.make_dir("_shots")

	var packed: PackedScene = load("res://scenes/Main.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	await _wait(8)

	# Home screen
	await _shot(main, "01_home")

	# Settings
	main._on_home_settings_pressed()
	await _wait(6)
	await _shot(main, "02_settings")
	main._hide_home_modals()
	await _wait(3)

	# Kingdom selection
	main._on_home_kingdoms_pressed()
	await _wait(6)
	await _shot(main, "03_kingdoms")
	main._hide_home_modals()
	await _wait(3)

	# Multiplayer
	main._on_home_multiplayer_pressed()
	await _wait(6)
	await _shot(main, "04_multiplayer")
	main._hide_home_modals()
	await _wait(3)

	# Lobby
	main.active_lobby_player_count = 2
	main._on_home_create_lobby_pressed()
	await _wait(6)
	await _shot(main, "05_lobby")
	main._hide_home_modals()
	await _wait(3)

	# Game table
	main._start_new_game(false)
	await _wait(20)
	await _shot(main, "06_table")

	print("SCREENSHOTS DONE")
	quit()


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _shot(main: Node, name: String) -> void:
	await _wait(2)
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [SHOT_DIR, name]
	var err := img.save_png(path)
	print("SHOT %s -> %s (err=%d)" % [name, ProjectSettings.globalize_path(path), err])
