extends Node

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

	var player := game.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		_fail("Player node is missing")
		_finish()
		return

	for action_name in [
		"move_forward",
		"move_backward",
		"move_left",
		"move_right",
		"interact",
		"toggle_cursor",
		"mine",
	]:
		if not InputMap.has_action(action_name):
			_fail("missing input action: " + action_name)
		elif InputMap.action_get_events(action_name).is_empty():
			_fail("input action has no event: " + action_name)

	var start_position := player.global_position
	Input.action_press("move_forward")
	for _frame in range(12):
		await get_tree().physics_frame
	Input.action_release("move_forward")

	if player.global_position.distance_to(start_position) < 0.05:
		_fail("move_forward did not move the Player")

	var escape_event := InputEventAction.new()
	escape_event.action = &"toggle_cursor"
	escape_event.pressed = true
	player._input(escape_event)

	if bool(player.get("_wants_mouse_capture")):
		_fail("Esc did not release the intended mouse capture state")

	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	player._input(click_event)

	await get_tree().process_frame

	if not bool(player.get("_wants_mouse_capture")):
		_fail("left click did not request gameplay mouse capture")

	_finish()


func _fail(message: String) -> void:
	_failed = true
	push_error("INPUT_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("INPUT_SMOKE: PASS")
		get_tree().quit(0)
