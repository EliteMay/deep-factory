extends CharacterBody3D

signal mining_feedback(message: String, success: bool)

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

@onready var camera_pivot: Node3D = $CameraPivot
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mining_cooldown_remaining: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_cursor"):
		_toggle_cursor()
		get_viewport().set_input_as_handled()
		return

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("mine") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_try_mine()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
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

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var target_velocity := direction * move_speed
	var change_rate := acceleration if direction != Vector3.ZERO else deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, change_rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, change_rate * delta)

	move_and_slide()


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


func _toggle_cursor() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
