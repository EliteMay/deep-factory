extends Node

const DEFAULT_BINDINGS := {
	"move_forward": KEY_W,
	"move_backward": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"interact": KEY_E,
	"toggle_cursor": KEY_ESCAPE,
}


func _ready() -> void:
	for action_name in DEFAULT_BINDINGS:
		_ensure_key_action(
			StringName(action_name),
			int(DEFAULT_BINDINGS[action_name])
		)

	_ensure_mouse_action(&"mine", MOUSE_BUTTON_LEFT)


func _ensure_key_action(action_name: StringName, physical_keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	if not InputMap.action_get_events(action_name).is_empty():
		return

	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, event)


func _ensure_mouse_action(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	if not InputMap.action_get_events(action_name).is_empty():
		return

	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)
