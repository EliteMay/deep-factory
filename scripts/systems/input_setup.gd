extends Node

const InputSystemScript = preload("res://addons/game_foundation/input/input_system.gd")

const INPUT_CONTRACT: Dictionary = {
	"move_forward": {
		"deadzone": 0.5,
		"events": [{
			"type": "key",
			"keycode": 0,
			"physical_keycode": KEY_W,
			"unicode": 0,
			"shift": false,
			"ctrl": false,
			"alt": false,
			"meta": false,
		}],
	},
	"move_backward": {
		"deadzone": 0.5,
		"events": [{
			"type": "key",
			"keycode": 0,
			"physical_keycode": KEY_S,
			"unicode": 0,
			"shift": false,
			"ctrl": false,
			"alt": false,
			"meta": false,
		}],
	},
	"move_left": {
		"deadzone": 0.5,
		"events": [{
			"type": "key",
			"keycode": 0,
			"physical_keycode": KEY_A,
			"unicode": 0,
			"shift": false,
			"ctrl": false,
			"alt": false,
			"meta": false,
		}],
	},
	"move_right": {
		"deadzone": 0.5,
		"events": [{
			"type": "key",
			"keycode": 0,
			"physical_keycode": KEY_D,
			"unicode": 0,
			"shift": false,
			"ctrl": false,
			"alt": false,
			"meta": false,
		}],
	},
	"interact": {
		"deadzone": 0.5,
		"events": [{
			"type": "key",
			"keycode": 0,
			"physical_keycode": KEY_E,
			"unicode": 0,
			"shift": false,
			"ctrl": false,
			"alt": false,
			"meta": false,
		}],
	},
	"toggle_cursor": {
		"deadzone": 0.5,
		"events": [{
			"type": "key",
			"keycode": 0,
			"physical_keycode": KEY_ESCAPE,
			"unicode": 0,
			"shift": false,
			"ctrl": false,
			"alt": false,
			"meta": false,
		}],
	},
	"mine": {
		"deadzone": 0.5,
		"events": [{
			"type": "mouse_button",
			"button_index": MOUSE_BUTTON_LEFT,
			"shift": false,
			"ctrl": false,
			"alt": false,
			"meta": false,
		}],
	},
}


func _ready() -> void:
	var result: Dictionary = InputSystemScript.restore_bindings(INPUT_CONTRACT)
	if not bool(result.get("ok", false)):
		push_error(
			"InputSetup: Foundation Input Systemの初期化に失敗しました: "
			+ String(result.get("code", "unknown"))
		)
