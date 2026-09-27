extends Node

const RuntimeTestBridge = preload("res://addons/game_foundation/testing/runtime_test_bridge.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene could not be loaded")
		_finish()
		return

	var game := packed.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame

	if not game.has_method("build_runtime_test_state"):
		_fail("Deep Factory runtime test provider is missing")
		game.queue_free()
		_finish()
		return

	var direct_state: Dictionary = game.call("build_runtime_test_state")
	_validate_game_state(direct_state)

	game.set("_runtime_test_mode", true)
	var isolated_save: Dictionary = game.call("save_now")
	if String(isolated_save.get("code", "")) != "runtime_test_mode":
		_fail("Runtime test mode must prevent save writes")
	game.set("_runtime_test_mode", false)

	var output_path: String = ProjectSettings.globalize_path(
		"user://deep-factory-runtime-test-bridge/state.json"
	)
	var bridge := RuntimeTestBridge.new()
	var configured: Dictionary = bridge.configure(
		output_path,
		"deep-factory-smoke",
		Callable(game, "build_runtime_test_state")
	)
	if not bool(configured.get("ok", false)):
		_fail("Runtime Test Bridge configuration failed")
		game.queue_free()
		_finish()
		return

	add_child(bridge)
	var capture: Dictionary = bridge.capture_now()
	if not bool(capture.get("ok", false)):
		_fail("Runtime Test Bridge capture failed: " + String(capture.get("code", "")))

	var file := FileAccess.open(output_path, FileAccess.READ)
	if file == null:
		_fail("Runtime Test Bridge state file was not created")
	else:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if not (parsed is Dictionary):
			_fail("Runtime Test Bridge state file is invalid JSON")
		else:
			var envelope: Dictionary = parsed as Dictionary
			if String(envelope.get("sessionId", "")) != "deep-factory-smoke":
				_fail("Runtime Test Bridge session mismatch")
			var state_variant: Variant = envelope.get("state", {})
			if not (state_variant is Dictionary):
				_fail("Runtime Test Bridge state payload is missing")
			else:
				_validate_game_state(state_variant as Dictionary)

	bridge.queue_free()
	game.queue_free()
	await get_tree().process_frame
	_finish()


func _validate_game_state(state: Dictionary) -> void:
	if not bool(state.get("ready", false)):
		_fail("ready must be true")
	if String(state.get("game", "")) != "deep-factory":
		_fail("game id mismatch")

	var player_variant: Variant = state.get("player", {})
	if not (player_variant is Dictionary):
		_fail("player telemetry is missing")
	else:
		var player_state: Dictionary = player_variant as Dictionary
		var position_variant: Variant = player_state.get("position", [])
		if not (position_variant is Array) or (position_variant as Array).size() != 3:
			_fail("player position must be a 3-value array")
		if not player_state.has("yaw") or not player_state.has("pitch"):
			_fail("camera telemetry is missing")

	var inventory_variant: Variant = state.get("inventory", {})
	if not (inventory_variant is Dictionary):
		_fail("inventory telemetry is missing")
	else:
		var inventory_state: Dictionary = inventory_variant as Dictionary
		for key in ["count", "capacity", "money", "ores"]:
			if not inventory_state.has(key):
				_fail("inventory telemetry missing key: " + key)

	if not (state.get("machines", []) is Array):
		_fail("machine telemetry must be an Array")


func _fail(message: String) -> void:
	_failed = true
	push_error("RUNTIME_TEST_BRIDGE_INTEGRATION_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("RUNTIME_TEST_BRIDGE_INTEGRATION_SMOKE: PASS")
		get_tree().quit(0)
