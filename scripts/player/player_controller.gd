extends CharacterBody3D

signal mining_feedback(message: String, success: bool)
signal interaction_feedback(message: String, success: bool)
signal inventory_changed(current_count: int, capacity: int, money: int)
signal control_state_changed(message: String, active: bool)
signal upgrade_menu_changed(is_open: bool)
signal upgrade_state_changed()
signal placement_confirm_requested()
signal placement_cancel_requested()

@export_category("Movement")
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0

@export_category("Look")
@export_range(0.0005, 0.02, 0.0005) var mouse_sensitivity: float = 0.0025
@export_range(20.0, 89.0, 1.0) var max_pitch_degrees: float = 85.0

@export_category("Mining")
@export var mining_damage: float = 1.0
@export_range(0.05, 2.0, 0.05) var mining_cooldown: float = 0.45

@export_category("Inventory")
@export_range(1, 999, 1) var inventory_capacity: int = 10

@onready var camera_pivot: Node3D = $CameraPivot
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mining_cooldown_remaining: float = 0.0
var ore_counts: Dictionary = {}
var ore_values: Dictionary = {}
var ore_names: Dictionary = {}
var upgrade_levels: Dictionary = {}
var money: int = 0
var _wants_mouse_capture: bool = true
var _suppress_mining_until_msec: int = 0
var _upgrade_menu_open: bool = false
var _placement_mode: bool = false


func _ready() -> void:
	set_process_input(true)
	_emit_inventory_changed()
	if DisplayServer.get_name() != "headless":
		call_deferred("_request_gameplay_focus")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if not _upgrade_menu_open:
			control_state_changed.emit("ゲーム画面をクリックして操作開始", false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if _upgrade_menu_open:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif _wants_mouse_capture:
			_suppress_mining_until_msec = Time.get_ticks_msec() + 200
			call_deferred("_capture_mouse")
		else:
			control_state_changed.emit("カーソル表示中。ゲーム画面をクリックで操作へ戻る", false)


func _input(event: InputEvent) -> void:
	if _placement_mode:
		if event.is_action_pressed("toggle_cursor"):
			placement_cancel_requested.emit()
			get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("mine"):
			placement_confirm_requested.emit()
			get_viewport().set_input_as_handled()
			return

		if event is InputEventMouseMotion and _gameplay_input_active():
			_apply_mouse_look(event)
			get_viewport().set_input_as_handled()
			return

		return

	if _upgrade_menu_open:
		if event.is_action_pressed("toggle_cursor"):
			close_upgrade_menu()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_cursor"):
		_toggle_cursor()
		get_viewport().set_input_as_handled()
		return

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and not _gameplay_input_active()
	):
		_wants_mouse_capture = true
		_suppress_mining_until_msec = Time.get_ticks_msec() + 200
		if DisplayServer.get_name() != "headless":
			var window := get_window()
			if window:
				window.grab_focus()
			call_deferred("_capture_mouse")
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact") and _gameplay_input_active():
		_try_interact()
		get_viewport().set_input_as_handled()
		return

	if (
		event.is_action_pressed("mine")
		and _gameplay_input_active()
		and Time.get_ticks_msec() >= _suppress_mining_until_msec
	):
		_try_mine()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and _gameplay_input_active():
		_apply_mouse_look(event)


func _apply_mouse_look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * mouse_sensitivity)
	camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
	camera_pivot.rotation.x = clamp(
		camera_pivot.rotation.x,
		deg_to_rad(-max_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)


func _physics_process(delta: float) -> void:
	mining_cooldown_remaining = maxf(0.0, mining_cooldown_remaining - delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	var input_vector: Vector2 = Vector2.ZERO
	if not _upgrade_menu_open:
		input_vector = Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward"
		)

	var direction: Vector3 = (
		transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	).normalized()
	var target_velocity: Vector3 = direction * move_speed
	var change_rate: float = acceleration if direction != Vector3.ZERO else deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, change_rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, change_rate * delta)

	move_and_slide()


func _request_gameplay_focus() -> void:
	var window := get_window()
	if window:
		window.grab_focus()
	_capture_mouse()


func _capture_mouse() -> void:
	if _upgrade_menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	var window := get_window()
	if window == null or not window.has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		control_state_changed.emit("ゲーム画面をクリックして操作開始", false)
		return

	_wants_mouse_capture = true
	_suppress_mining_until_msec = Time.get_ticks_msec() + 200
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	control_state_changed.emit("", true)


func refresh_control_state() -> void:
	if _upgrade_menu_open:
		control_state_changed.emit("", true)
	elif _gameplay_input_active():
		control_state_changed.emit("", true)
	elif _wants_mouse_capture:
		control_state_changed.emit("ゲーム画面をクリックして操作開始", false)
	else:
		control_state_changed.emit("カーソル表示中。ゲーム画面をクリックで操作へ戻る", false)


func _gameplay_input_active() -> bool:
	var window := get_window()
	return (
		not _upgrade_menu_open
		and window != null
		and window.has_focus()
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	)


func open_upgrade_menu() -> void:
	if _upgrade_menu_open or _placement_mode:
		return

	_upgrade_menu_open = true
	_wants_mouse_capture = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	control_state_changed.emit("", true)
	upgrade_menu_changed.emit(true)


func close_upgrade_menu() -> void:
	if not _upgrade_menu_open:
		return

	_upgrade_menu_open = false
	_wants_mouse_capture = true
	upgrade_menu_changed.emit(false)

	if DisplayServer.get_name() != "headless":
		var window := get_window()
		if window:
			window.grab_focus()
		call_deferred("_capture_mouse")


func set_placement_mode(active: bool) -> void:
	_placement_mode = active
	if active:
		_wants_mouse_capture = true
		if DisplayServer.get_name() != "headless":
			call_deferred("_request_gameplay_focus")


func is_placement_mode() -> bool:
	return _placement_mode


func try_spend_money(cost: int, item_name: String = "購入") -> bool:
	var safe_cost: int = maxi(0, cost)
	if money < safe_cost:
		interaction_feedback.emit(
			"%sには所持金が足りません　必要 ¥%d" % [item_name, safe_cost],
			false
		)
		return false

	money -= safe_cost
	_emit_inventory_changed()
	return true


func add_money(amount: int) -> void:
	money += maxi(0, amount)
	_emit_inventory_changed()


func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(upgrade_levels.get(String(upgrade_id), 0))


func purchase_upgrade(upgrade_id: StringName, definition: Dictionary) -> Dictionary:
	var upgrade_key: String = String(upgrade_id)
	var display_name: String = String(definition.get("name", upgrade_key))
	var max_level: int = int(definition.get("max_level", 1))
	var current_level: int = get_upgrade_level(upgrade_id)
	var cost: int = maxi(0, int(definition.get("cost", 0)))

	if current_level >= max_level:
		interaction_feedback.emit(display_name + "は購入済み", false)
		return {
			"purchased": false,
			"reason": "max_level",
		}

	if money < cost:
		interaction_feedback.emit(
			"所持金が足りません　必要 ¥%d" % cost,
			false
		)
		return {
			"purchased": false,
			"reason": "insufficient_money",
		}

	var effect_variant: Variant = definition.get("effect", {})
	if not (effect_variant is Dictionary):
		interaction_feedback.emit("アップグレードデータが不正です", false)
		return {
			"purchased": false,
			"reason": "invalid_effect",
		}

	var effect: Dictionary = effect_variant as Dictionary
	if not _apply_upgrade_effect(effect):
		interaction_feedback.emit("アップグレード効果を適用できません", false)
		return {
			"purchased": false,
			"reason": "unsupported_effect",
		}

	money -= cost
	upgrade_levels[upgrade_key] = current_level + 1
	_emit_inventory_changed()
	upgrade_state_changed.emit()
	interaction_feedback.emit(display_name + "を購入した", true)

	return {
		"purchased": true,
		"reason": "ok",
		"level": current_level + 1,
	}


func _apply_upgrade_effect(effect: Dictionary) -> bool:
	var effect_type: String = String(effect.get("type", ""))
	var value: float = float(effect.get("value", 0.0))

	match effect_type:
		"set_mining_cooldown":
			mining_cooldown = maxf(0.05, value)
			return true
		"add_inventory_capacity":
			inventory_capacity = maxi(1, inventory_capacity + int(value))
			return true
		"add_move_speed":
			move_speed = maxf(0.1, move_speed + value)
			return true
		_:
			return false


func _try_mine() -> void:
	if mining_cooldown_remaining > 0.0:
		return

	mining_cooldown_remaining = mining_cooldown
	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		mining_feedback.emit("採掘対象なし", false)
		return

	var collider := interaction_ray.get_collider()
	if collider == null or not collider.has_method("mine"):
		mining_feedback.emit("採掘対象なし", false)
		return

	var result: Variant = collider.call("mine", mining_damage)
	if not (result is Dictionary):
		mining_feedback.emit("採掘成功", true)
		return

	var data := result as Dictionary
	if bool(data.get("destroyed", false)):
		mining_feedback.emit("岩を破壊した。鉱石がドロップした", true)
		return

	var remaining := float(data.get("remaining", 0.0))
	var maximum := float(data.get("max", 0.0))
	mining_feedback.emit(
		"採掘成功　耐久 %.0f / %.0f" % [remaining, maximum],
		true
	)


func _try_interact() -> void:
	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		interaction_feedback.emit("操作対象なし", false)
		return

	var collider := interaction_ray.get_collider()
	if collider == null or not collider.has_method("interact"):
		interaction_feedback.emit("操作対象なし", false)
		return

	collider.call("interact", self)


func add_ore(
	ore_id: StringName,
	display_name: String,
	sell_value: int,
	requested_amount: int
) -> int:
	var available: int = maxi(0, inventory_capacity - inventory_count())
	var accepted: int = mini(maxi(requested_amount, 0), available)

	if accepted <= 0:
		interaction_feedback.emit("バッグがいっぱい", false)
		return 0

	var current: int = int(ore_counts.get(ore_id, 0))
	ore_counts[ore_id] = current + accepted
	ore_values[ore_id] = maxi(0, sell_value)
	ore_names[ore_id] = display_name

	if accepted < requested_amount:
		interaction_feedback.emit(
			"%sを%d個拾った。バッグがいっぱい" % [display_name, accepted],
			true
		)
	else:
		interaction_feedback.emit(
			"%sを%d個拾った" % [display_name, accepted],
			true
		)

	_emit_inventory_changed()
	return accepted


func sell_all_ore() -> Dictionary:
	var sold_count: int = inventory_count()
	if sold_count <= 0:
		interaction_feedback.emit("売る鉱石がありません", false)
		return {
			"sold": 0,
			"value": 0,
		}

	var total_value: int = 0
	for ore_id in ore_counts:
		total_value += int(ore_counts[ore_id]) * int(ore_values.get(ore_id, 0))

	ore_counts.clear()
	ore_values.clear()
	ore_names.clear()
	money += total_value

	interaction_feedback.emit(
		"%d個売却　+¥%d" % [sold_count, total_value],
		true
	)
	_emit_inventory_changed()

	return {
		"sold": sold_count,
		"value": total_value,
	}


func inventory_count() -> int:
	var total: int = 0
	for value in ore_counts.values():
		total += int(value)
	return total


func _emit_inventory_changed() -> void:
	inventory_changed.emit(inventory_count(), inventory_capacity, money)


func _toggle_cursor() -> void:
	if _wants_mouse_capture:
		_wants_mouse_capture = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		control_state_changed.emit(
			"カーソル表示中。ゲーム画面をクリックで操作へ戻る",
			false
		)
	else:
		_wants_mouse_capture = true
		_suppress_mining_until_msec = Time.get_ticks_msec() + 200
		if DisplayServer.get_name() != "headless":
			var window := get_window()
			if window:
				window.grab_focus()
			call_deferred("_capture_mouse")
