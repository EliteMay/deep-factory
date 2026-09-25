extends Node

const Foundation = preload("res://addons/game_foundation/foundation.gd")
const FoundationSaveSystem = preload("res://addons/game_foundation/save/save_system.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_installation_metadata()

	if Foundation.FOUNDATION_VERSION != "0.8.0-dev":
		_fail("Foundation version should be 0.8.0-dev")
	if not Foundation.capabilities().has("generic_save_system"):
		_fail("generic_save_system capability is missing")
	if not Foundation.capabilities().has("settings_system"):
		_fail("settings_system capability is missing")
	if not Foundation.capabilities().has("input_system"):
		_fail("input_system capability is missing")
	if not Foundation.capabilities().has("game_flow"):
		_fail("game_flow capability is missing")

	for action_name in [
		"move_forward",
		"move_backward",
		"move_left",
		"move_right",
		"interact",
		"toggle_cursor",
		"mine",
	]:
		if not InputMap.has_action(StringName(action_name)):
			_fail("Foundation Input integration is missing action: " + action_name)

	var packed := load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene could not be loaded")
		_finish()
		return

	var game := packed.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame

	var snapshot: Dictionary = game.call("build_save_snapshot")
	var validation: Dictionary = FoundationSaveSystem.validate_payload(snapshot)
	if not bool(validation.get("ok", false)):
		_fail("Deep Factory save payload is not Foundation JSON-compatible")

	var flow_service: Variant = game.get("_game_flow_service")
	if not (flow_service is Node):
		_fail("GameFlowService was not created")
	elif int((flow_service as Node).call("quit_hook_count")) != 1:
		_fail("Safe quit save hook was not registered")

	if bool(game.get("_persistence_active")):
		_fail("headless smoke should not use the real save path")

	var player := game.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		_fail("Player node is missing")
	elif not is_equal_approx(float(player.get("mouse_sensitivity")), 0.0025):
		_fail("Foundation gameplay settings default was not applied")

	game.queue_free()
	await get_tree().process_frame
	_finish()


func _validate_installation_metadata() -> void:
	var file := FileAccess.open("res://.game-foundation.json", FileAccess.READ)
	if file == null:
		_fail(".game-foundation.json is missing")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		_fail(".game-foundation.json is invalid JSON")
		return

	var metadata: Dictionary = parsed as Dictionary
	if int(metadata.get("schemaVersion", 0)) != 1:
		_fail("Foundation installation schemaVersion must be 1")
	if String(metadata.get("sourceRepository", "")) != "EliteMay/godot-game-foundation":
		_fail("Foundation source repository mismatch")
	if String(metadata.get("foundationVersion", "")) != Foundation.FOUNDATION_VERSION:
		_fail("Foundation metadata version mismatch")
	if String(metadata.get("foundationCommit", "")) != "12a018a2f6ef5e0a191602746068ce040caec5f9":
		_fail("Foundation commit mismatch")

	var managed_variant: Variant = metadata.get("managedPaths", [])
	if not (managed_variant is Array):
		_fail("managedPaths must be an Array")
	elif managed_variant != ["addons/game_foundation"]:
		_fail("managedPaths must only contain addons/game_foundation")


func _fail(message: String) -> void:
	_failed = true
	push_error("FOUNDATION_PILOT_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("FOUNDATION_PILOT_SMOKE: PASS")
		get_tree().quit(0)
