extends Node3D

const UpgradeCatalogScript = preload("res://scripts/systems/upgrade_catalog.gd")
const MachineCatalogScript = preload("res://scripts/systems/machine_catalog.gd")
const SaveModelScript = preload("res://scripts/systems/save_model.gd")
const FoundationSaveSystem = preload("res://addons/game_foundation/save/save_system.gd")
const AutoSaveServiceScript = preload("res://addons/game_foundation/save/auto_save_service.gd")
const SettingsSystemScript = preload("res://addons/game_foundation/settings/settings_system.gd")
const SettingsRuntimeScript = preload("res://addons/game_foundation/settings/settings_runtime.gd")
const GameFlowServiceScript = preload("res://addons/game_foundation/flow/game_flow_service.gd")
const SmallMinerScene = preload("res://scenes/world/small_miner.tscn")
const PlacementPreviewScene = preload("res://scenes/world/placement_preview.tscn")

const GAMEPLAY_SETTINGS_DEFAULTS: Dictionary = {
	"mouse_sensitivity": 0.0025,
}

@export var save_path: String = FoundationSaveSystem.DEFAULT_SAVE_PATH
@export var allow_headless_persistence: bool = false
@export_range(5.0, 300.0, 1.0) var periodic_autosave_seconds: float = 15.0

@onready var player: CharacterBody3D = $Player
@onready var feedback: Label = $HUD/Feedback
@onready var inventory_label: Label = $HUD/Inventory
@onready var money_label: Label = $HUD/Money
@onready var control_state_label: Label = $HUD/ControlState
@onready var build_state_label: Label = $HUD/BuildState

@onready var upgrade_panel: PanelContainer = $HUD/UpgradePanel
@onready var upgrade_balance: Label = $HUD/UpgradePanel/Margin/VBox/Balance
@onready var upgrade_status: Label = $HUD/UpgradePanel/Margin/VBox/Status
@onready var mining_info: Label = $HUD/UpgradePanel/Margin/VBox/MiningRow/Info
@onready var mining_button: Button = $HUD/UpgradePanel/Margin/VBox/MiningRow/Top/Purchase
@onready var capacity_info: Label = $HUD/UpgradePanel/Margin/VBox/CapacityRow/Info
@onready var capacity_button: Button = $HUD/UpgradePanel/Margin/VBox/CapacityRow/Top/Purchase
@onready var move_info: Label = $HUD/UpgradePanel/Margin/VBox/MoveRow/Info
@onready var move_button: Button = $HUD/UpgradePanel/Margin/VBox/MoveRow/Top/Purchase
@onready var small_miner_info: Label = $HUD/UpgradePanel/Margin/VBox/MinerRow/Info
@onready var small_miner_button: Button = $HUD/UpgradePanel/Margin/VBox/MinerRow/Top/Purchase

var _feedback_token: int = 0
var _upgrade_definitions: Dictionary = {}
var _machine_definitions: Dictionary = {}

var _placement_preview: Node3D = null
var _placement_valid: bool = false
var _pending_machine_cost: int = 0
var _pending_machine_definition: Dictionary = {}
var _placed_small_miners: int = 0

var _auto_save_service: Node = null
var _game_flow_service: Node = null
var _autosave_timer: Timer = null
var _persistence_active: bool = false
var _restoring_state: bool = false
var _save_writes_blocked: bool = false
var _quit_requested: bool = false
var _base_mining_cooldown: float = 0.45
var _base_inventory_capacity: int = 10
var _base_move_speed: float = 5.0


func _ready() -> void:
	_upgrade_definitions = UpgradeCatalogScript.load_all()
	_machine_definitions = MachineCatalogScript.load_all()
	_capture_player_base_values()
	_setup_foundation_services()
	_load_foundation_settings()

	if player.has_signal("mining_feedback"):
		player.connect("mining_feedback", Callable(self, "_on_feedback"))
	if player.has_signal("interaction_feedback"):
		player.connect("interaction_feedback", Callable(self, "_on_feedback"))
	if player.has_signal("inventory_changed"):
		player.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
	if player.has_signal("control_state_changed"):
		player.connect("control_state_changed", Callable(self, "_on_control_state_changed"))
	if player.has_signal("upgrade_menu_changed"):
		player.connect("upgrade_menu_changed", Callable(self, "_on_upgrade_menu_changed"))
	if player.has_signal("upgrade_state_changed"):
		player.connect("upgrade_state_changed", Callable(self, "_on_upgrade_state_changed"))
	if player.has_signal("placement_confirm_requested"):
		player.connect(
			"placement_confirm_requested",
			Callable(self, "_on_placement_confirm_requested")
		)
	if player.has_signal("placement_cancel_requested"):
		player.connect(
			"placement_cancel_requested",
			Callable(self, "_on_placement_cancel_requested")
		)

	mining_button.pressed.connect(
		Callable(self, "_purchase_upgrade").bind(&"mining_speed")
	)
	capacity_button.pressed.connect(
		Callable(self, "_purchase_upgrade").bind(&"inventory_capacity")
	)
	move_button.pressed.connect(
		Callable(self, "_purchase_upgrade").bind(&"move_speed")
	)
	small_miner_button.pressed.connect(
		Callable(self, "_purchase_small_miner")
	)

	feedback.visible = false
	upgrade_panel.visible = false
	build_state_label.visible = false

	if player.has_method("inventory_count"):
		_on_inventory_changed(
			int(player.call("inventory_count")),
			int(player.get("inventory_capacity")),
			int(player.get("money"))
		)

	_load_saved_game()
	_refresh_upgrade_panel()

	if player.has_method("refresh_control_state"):
		player.call_deferred("refresh_control_state")


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_WM_CLOSE_REQUEST
		and _persistence_active
		and not _quit_requested
	):
		_quit_requested = true
		call_deferred("_request_safe_quit")


func _process(_delta: float) -> void:
	if _placement_preview != null:
		_update_placement_preview()


func _on_feedback(message: String, success: bool) -> void:
	_feedback_token += 1
	var token: int = _feedback_token

	feedback.text = message
	feedback.modulate = (
		Color(0.55, 1.0, 0.72, 1.0)
		if success
		else Color(1.0, 0.72, 0.45, 1.0)
	)
	feedback.visible = true

	if upgrade_panel.visible:
		upgrade_status.text = message
		upgrade_status.modulate = (
			Color(0.55, 1.0, 0.72, 1.0)
			if success
			else Color(1.0, 0.72, 0.45, 1.0)
		)

	await get_tree().create_timer(1.2).timeout
	if token == _feedback_token:
		feedback.visible = false


func _on_inventory_changed(current_count: int, capacity: int, money: int) -> void:
	inventory_label.text = "鉱石: %d / %d" % [current_count, capacity]
	money_label.text = "所持金: ¥%d" % money

	if is_instance_valid(upgrade_balance):
		upgrade_balance.text = "所持金: ¥%d" % money
	if is_instance_valid(upgrade_panel) and upgrade_panel.visible:
		_refresh_upgrade_panel()

	if not _restoring_state:
		call_deferred("_queue_auto_save")


func _on_upgrade_state_changed() -> void:
	_refresh_upgrade_panel()
	if not _restoring_state:
		call_deferred("_queue_auto_save")


func _on_control_state_changed(message: String, active: bool) -> void:
	control_state_label.text = message
	control_state_label.visible = not active


func _on_upgrade_menu_changed(is_open: bool) -> void:
	upgrade_panel.visible = is_open
	if is_open:
		upgrade_status.text = "購入するアップグレードや設備を選んでください"
		upgrade_status.modulate = Color(0.74, 0.82, 0.9, 1.0)
		_refresh_upgrade_panel()


func _purchase_upgrade(upgrade_id: StringName) -> void:
	var key: String = String(upgrade_id)
	var definition_variant: Variant = _upgrade_definitions.get(key, {})
	if not (definition_variant is Dictionary):
		upgrade_status.text = "アップグレードデータを読み込めません"
		upgrade_status.modulate = Color(1.0, 0.72, 0.45, 1.0)
		return

	player.call(
		"purchase_upgrade",
		upgrade_id,
		definition_variant as Dictionary
	)
	_refresh_upgrade_panel()


func _purchase_small_miner() -> void:
	var definition_variant: Variant = _machine_definitions.get("small_miner", {})
	if not (definition_variant is Dictionary):
		_on_feedback("採掘機データを読み込めません", false)
		return

	var definition: Dictionary = definition_variant as Dictionary
	var max_placed: int = maxi(1, int(definition.get("max_placed", 1)))
	if _placed_small_miners >= max_placed:
		_on_feedback("小型採掘機はすでに設置済みです", false)
		return

	var cost: int = maxi(0, int(definition.get("cost", 0)))
	var display_name: String = String(definition.get("name", "小型採掘機"))
	var paid: bool = bool(
		player.call("try_spend_money", cost, display_name)
	)
	if not paid:
		_refresh_upgrade_panel()
		return

	_pending_machine_cost = cost
	_pending_machine_definition = definition.duplicate(true)
	player.call("close_upgrade_menu")
	call_deferred("_start_small_miner_placement")


func _start_small_miner_placement() -> void:
	if _pending_machine_definition.is_empty():
		return

	if _placement_preview != null:
		_placement_preview.queue_free()

	_placement_preview = PlacementPreviewScene.instantiate() as Node3D
	add_child(_placement_preview)
	player.call("set_placement_mode", true)
	build_state_label.visible = true
	_update_placement_preview()


func _update_placement_preview() -> void:
	if _placement_preview == null:
		return

	var forward: Vector3 = -player.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()

	var target_position: Vector3 = player.global_position + forward * 3.0
	target_position.x = snappedf(target_position.x, 0.5)
	target_position.y = 0.0
	target_position.z = snappedf(target_position.z, 0.5)

	_placement_preview.global_position = target_position
	_placement_valid = _can_place_small_miner(target_position)
	_placement_preview.call("set_valid", _placement_valid)

	build_state_label.text = (
		"小型採掘機を配置中　左クリック: 設置　Esc: キャンセル\n"
		+ ("設置できます" if _placement_valid else "ここには設置できません")
	)


func _can_place_small_miner(target_position: Vector3) -> bool:
	if absf(target_position.x) > 10.5 or absf(target_position.z) > 10.5:
		return false

	var flat_player_position := Vector3(
		player.global_position.x,
		0.0,
		player.global_position.z
	)
	var flat_target := Vector3(target_position.x, 0.0, target_position.z)
	if flat_player_position.distance_to(flat_target) < 2.0:
		return false

	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 1.5, 1.7)

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(
		Basis.IDENTITY,
		target_position + Vector3(0.0, 0.75, 0.0)
	)
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var hits: Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(
		query,
		16
	)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or collider == player:
			continue
		if collider is Node and (collider as Node).name == "Ground":
			continue
		return false

	return true


func _on_placement_confirm_requested() -> void:
	if _placement_preview == null:
		return

	if not _placement_valid:
		_on_feedback("ここには小型採掘機を設置できません", false)
		return

	var definition: Dictionary = _pending_machine_definition
	var miner := _create_small_miner(
		definition,
		_placement_preview.position,
		0
	)
	if miner == null:
		_on_feedback("小型採掘機を生成できません", false)
		return

	_placed_small_miners += 1

	_finish_machine_placement(false)
	_on_feedback(
		"小型採掘機を設置した。鉱石がたまったらEで回収できます",
		true
	)
	_refresh_upgrade_panel()
	call_deferred("_queue_auto_save")


func _on_placement_cancel_requested() -> void:
	if _placement_preview == null:
		return

	_finish_machine_placement(true)
	_on_feedback("設置をキャンセルしました。購入代金を返金しました", false)
	call_deferred("_queue_auto_save")


func _finish_machine_placement(refund: bool) -> void:
	if refund and _pending_machine_cost > 0:
		player.call("add_money", _pending_machine_cost)

	if _placement_preview != null:
		_placement_preview.queue_free()
		_placement_preview = null

	_pending_machine_cost = 0
	_pending_machine_definition.clear()
	_placement_valid = false
	build_state_label.visible = false
	player.call("set_placement_mode", false)


func _capture_player_base_values() -> void:
	_base_mining_cooldown = float(player.get("mining_cooldown"))
	_base_inventory_capacity = int(player.get("inventory_capacity"))
	_base_move_speed = float(player.get("move_speed"))


func _setup_foundation_services() -> void:
	_persistence_active = (
		DisplayServer.get_name() != "headless"
		or allow_headless_persistence
	)

	_auto_save_service = AutoSaveServiceScript.new()
	_auto_save_service.set("save_path", save_path)
	_auto_save_service.set("debounce_seconds", 0.75)
	add_child(_auto_save_service)

	_game_flow_service = GameFlowServiceScript.new()
	add_child(_game_flow_service)
	_game_flow_service.call(
		"register_quit_hook",
		Callable(self, "_save_before_quit")
	)

	if not _persistence_active:
		return

	get_tree().auto_accept_quit = false

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = maxf(5.0, periodic_autosave_seconds)
	_autosave_timer.one_shot = false
	_autosave_timer.timeout.connect(Callable(self, "_on_periodic_autosave"))
	add_child(_autosave_timer)
	_autosave_timer.start()


func _load_foundation_settings() -> void:
	var result: Dictionary = SettingsSystemScript.load_settings(
		GAMEPLAY_SETTINGS_DEFAULTS
	)
	if not bool(result.get("ok", false)):
		push_warning(
			"Deep Factory: Settingsを読み込めませんでした: "
			+ String(result.get("code", "unknown"))
		)
		return

	var settings_variant: Variant = result.get("settings", {})
	if not (settings_variant is Dictionary):
		return

	var settings: Dictionary = settings_variant as Dictionary
	var apply_result: Dictionary = SettingsRuntimeScript.apply_settings(settings)
	if not bool(apply_result.get("ok", false)):
		push_warning("Deep Factory: SettingsのRuntime適用に失敗しました")

	var gameplay_variant: Variant = settings.get("gameplay", {})
	if gameplay_variant is Dictionary:
		var gameplay: Dictionary = gameplay_variant as Dictionary
		var sensitivity_variant: Variant = gameplay.get("mouse_sensitivity")
		if _is_number(sensitivity_variant):
			player.set(
				"mouse_sensitivity",
				clampf(float(sensitivity_variant), 0.0005, 0.02)
			)

	if (
		_persistence_active
		and String(result.get("source", "")) == "defaults"
	):
		SettingsSystemScript.save_settings(
			settings,
			GAMEPLAY_SETTINGS_DEFAULTS
		)


func _on_periodic_autosave() -> void:
	_queue_auto_save()


func _queue_auto_save() -> void:
	if (
		not _persistence_active
		or _restoring_state
		or _save_writes_blocked
		or _auto_save_service == null
		or _pending_machine_cost > 0
	):
		return

	var snapshot: Dictionary = build_save_snapshot()
	if snapshot.is_empty():
		return

	var result: Dictionary = _auto_save_service.call(
		"request_save",
		snapshot,
		SaveModelScript.CURRENT_SAVE_VERSION
	)
	if not bool(result.get("ok", false)):
		push_warning(
			"Deep Factory: Auto Save要求に失敗しました: "
			+ String(result.get("code", "unknown"))
		)


func save_now() -> Dictionary:
	if not _persistence_active:
		return {
			"ok": true,
			"code": "persistence_disabled",
		}

	if _save_writes_blocked:
		return {
			"ok": true,
			"code": "save_preserved_after_load_failure",
		}

	if _pending_machine_cost > 0:
		return {
			"ok": false,
			"code": "placement_in_progress",
			"message": "placement must finish before saving",
		}

	var snapshot: Dictionary = build_save_snapshot()
	if snapshot.is_empty():
		return {
			"ok": false,
			"code": "snapshot_failed",
		}

	return FoundationSaveSystem.save_game(
		snapshot,
		SaveModelScript.CURRENT_SAVE_VERSION,
		save_path
	)


func _save_before_quit() -> Dictionary:
	if _pending_machine_cost > 0:
		_finish_machine_placement(true)

	return save_now()


func _request_safe_quit() -> void:
	if _game_flow_service == null:
		get_tree().quit()
		return

	var result: Dictionary = _game_flow_service.call("request_quit", 0)
	if not bool(result.get("ok", false)):
		_quit_requested = false
		_on_feedback(
			"セーブに失敗したため終了を止めました。もう一度終了してください",
			false
		)


func _load_saved_game() -> Dictionary:
	if not _persistence_active:
		return {
			"ok": true,
			"code": "persistence_disabled",
		}

	var result: Dictionary = FoundationSaveSystem.load_game(
		save_path,
		SaveModelScript.CURRENT_SAVE_VERSION
	)

	if bool(result.get("ok", false)):
		var payload_variant: Variant = result.get("payload", {})
		if not (payload_variant is Dictionary):
			_save_writes_blocked = true
			return {
				"ok": false,
				"code": "invalid_payload",
			}

		var restore_result: Dictionary = _restore_save_payload(
			payload_variant as Dictionary
		)
		if not bool(restore_result.get("ok", false)):
			_save_writes_blocked = true
			_on_feedback(
				"セーブ内容が不正なため新規状態で開始しました。元のセーブは上書きしません",
				false
			)
			return restore_result

		if String(result.get("source", "")) == "backup":
			_on_feedback("バックアップからセーブを復旧しました", true)
		return result

	var code: String = String(result.get("code", "load_failed"))
	var backup_error: String = String(result.get("backup_error", "not_found"))
	if code == "not_found" and backup_error == "not_found":
		return {
			"ok": true,
			"code": "new_game",
		}

	_save_writes_blocked = true
	_on_feedback(
		"セーブを読み込めないため新規状態で開始しました。元のセーブは上書きしません",
		false
	)
	return result


func _restore_save_payload(payload: Dictionary) -> Dictionary:
	var normalized_result: Dictionary = _normalize_save_payload(payload)
	if not bool(normalized_result.get("ok", false)):
		return normalized_result

	var normalized: Dictionary = normalized_result.get("payload", {})
	var inventory: Dictionary = normalized.get("inventory", {})
	var upgrades: Dictionary = normalized.get("upgrades", {})
	var machine_states: Array = normalized.get("machines", [])

	_restoring_state = true

	player.set("mining_cooldown", _base_mining_cooldown)
	player.set("inventory_capacity", _base_inventory_capacity)
	player.set("move_speed", _base_move_speed)
	player.set("money", int(normalized.get("money", 0)))

	var runtime_inventory: Dictionary = {}
	var runtime_values: Dictionary = {}
	var runtime_names: Dictionary = {}
	for ore_key in inventory.keys():
		var ore_id: String = String(ore_key)
		var ore_definition: Dictionary = _ore_definition_for_id(ore_id)
		runtime_inventory[StringName(ore_id)] = int(inventory.get(ore_key, 0))
		runtime_values[StringName(ore_id)] = int(ore_definition.get("sell_value", 0))
		runtime_names[StringName(ore_id)] = String(ore_definition.get("name", ore_id))

	player.set("ore_counts", runtime_inventory)
	player.set("ore_values", runtime_values)
	player.set("ore_names", runtime_names)
	player.set("upgrade_levels", upgrades.duplicate(true))

	for upgrade_key in upgrades.keys():
		var level: int = int(upgrades.get(upgrade_key, 0))
		var definition_variant: Variant = _upgrade_definitions.get(
			String(upgrade_key),
			{}
		)
		if not (definition_variant is Dictionary):
			continue
		var definition: Dictionary = definition_variant as Dictionary
		var effect_variant: Variant = definition.get("effect", {})
		if not (effect_variant is Dictionary):
			continue
		for _index in range(level):
			_apply_restored_upgrade_effect(effect_variant as Dictionary)

	var player_state: Dictionary = normalized.get("player", {})
	player.global_position = _array_to_vector3(
		player_state.get("position", [0.0, 0.05, 5.0])
	)

	for node in get_tree().get_nodes_in_group("small_miners"):
		if node is Node and is_ancestor_of(node):
			(node as Node).free()

	_placed_small_miners = 0
	var small_miner_definition: Dictionary = _small_miner_definition()
	for state_variant in machine_states:
		var state: Dictionary = state_variant as Dictionary
		var miner := _create_small_miner(
			small_miner_definition,
			_array_to_vector3(state.get("position", [0.0, 0.0, 0.0])),
			int(state.get("stored_amount", 0))
		)
		if miner != null:
			_placed_small_miners += 1

	player.call("_emit_inventory_changed")
	player.emit_signal("upgrade_state_changed")
	_restoring_state = false
	return {
		"ok": true,
		"code": "restored",
	}


func _normalize_save_payload(payload: Dictionary) -> Dictionary:
	if int(payload.get("save_version", 0)) != SaveModelScript.CURRENT_SAVE_VERSION:
		return _save_validation_error("save_version")

	if not _is_non_negative_number(payload.get("money")):
		return _save_validation_error("money")

	var inventory_variant: Variant = payload.get("inventory")
	if not (inventory_variant is Dictionary):
		return _save_validation_error("inventory")

	var inventory: Dictionary = {}
	for raw_key in (inventory_variant as Dictionary).keys():
		var ore_id: String = String(raw_key)
		var amount_variant: Variant = (inventory_variant as Dictionary).get(raw_key)
		if (
			ore_id.is_empty()
			or not _is_non_negative_number(amount_variant)
			or _ore_definition_for_id(ore_id).is_empty()
		):
			return _save_validation_error("inventory." + ore_id)
		inventory[ore_id] = int(amount_variant)

	var upgrades_variant: Variant = payload.get("upgrades")
	if not (upgrades_variant is Dictionary):
		return _save_validation_error("upgrades")

	var upgrades: Dictionary = {}
	for raw_key in (upgrades_variant as Dictionary).keys():
		var upgrade_id: String = String(raw_key)
		var definition_variant: Variant = _upgrade_definitions.get(upgrade_id)
		var level_variant: Variant = (upgrades_variant as Dictionary).get(raw_key)
		if (
			not (definition_variant is Dictionary)
			or not _is_non_negative_number(level_variant)
		):
			return _save_validation_error("upgrades." + upgrade_id)

		var definition: Dictionary = definition_variant as Dictionary
		var level: int = int(level_variant)
		if level > maxi(0, int(definition.get("max_level", 1))):
			return _save_validation_error("upgrades." + upgrade_id)
		upgrades[upgrade_id] = level

	var effective_capacity: int = _effective_inventory_capacity(upgrades)
	var inventory_total: int = 0
	for amount in inventory.values():
		inventory_total += int(amount)
	if inventory_total > effective_capacity:
		return _save_validation_error("inventory_capacity")

	var player_variant: Variant = payload.get("player")
	if not (player_variant is Dictionary):
		return _save_validation_error("player")

	var player_position_variant: Variant = (player_variant as Dictionary).get("position")
	if not _is_vector3_array(player_position_variant):
		return _save_validation_error("player.position")

	var machines_variant: Variant = payload.get("machines")
	if not (machines_variant is Array):
		return _save_validation_error("machines")

	var small_miner_definition: Dictionary = _small_miner_definition()
	if small_miner_definition.is_empty():
		return _save_validation_error("machine_definition")

	var max_placed: int = maxi(1, int(small_miner_definition.get("max_placed", 1)))
	var storage_capacity: int = maxi(
		1,
		int(small_miner_definition.get("storage_capacity", 5))
	)
	var machines: Array = []
	for machine_variant in machines_variant as Array:
		if not (machine_variant is Dictionary):
			return _save_validation_error("machines.entry")

		var machine: Dictionary = machine_variant as Dictionary
		if String(machine.get("type", "")) != "small_miner":
			return _save_validation_error("machines.type")
		if not _is_vector3_array(machine.get("position")):
			return _save_validation_error("machines.position")
		if not _is_non_negative_number(machine.get("stored_amount")):
			return _save_validation_error("machines.stored_amount")

		var stored_amount: int = int(machine.get("stored_amount", 0))
		if stored_amount > storage_capacity:
			return _save_validation_error("machines.stored_amount")

		machines.append({
			"type": "small_miner",
			"position": (machine.get("position") as Array).duplicate(),
			"stored_amount": stored_amount,
		})

	if machines.size() > max_placed:
		return _save_validation_error("machines.count")

	return {
		"ok": true,
		"code": "valid",
		"payload": {
			"save_version": SaveModelScript.CURRENT_SAVE_VERSION,
			"money": int(payload.get("money", 0)),
			"inventory": inventory,
			"upgrades": upgrades,
			"player": {
				"position": (player_position_variant as Array).duplicate(),
			},
			"machines": machines,
		},
	}


func _save_validation_error(field: String) -> Dictionary:
	return {
		"ok": false,
		"code": "invalid_game_payload",
		"field": field,
	}


func _is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]


func _is_non_negative_number(value: Variant) -> bool:
	if not _is_number(value):
		return false
	var number: float = float(value)
	return number == number and number >= 0.0 and number < INF


func _is_vector3_array(value: Variant) -> bool:
	if not (value is Array):
		return false
	var values: Array = value as Array
	if values.size() != 3:
		return false
	for component in values:
		if not _is_number(component):
			return false
		var number: float = float(component)
		if number != number or absf(number) > 100000.0:
			return false
	return true


func _array_to_vector3(value: Variant) -> Vector3:
	var values: Array = value as Array
	return Vector3(
		float(values[0]),
		float(values[1]),
		float(values[2])
	)


func _effective_inventory_capacity(upgrades: Dictionary) -> int:
	var capacity: int = _base_inventory_capacity
	for upgrade_key in upgrades.keys():
		var definition_variant: Variant = _upgrade_definitions.get(
			String(upgrade_key),
			{}
		)
		if not (definition_variant is Dictionary):
			continue
		var definition: Dictionary = definition_variant as Dictionary
		var effect_variant: Variant = definition.get("effect", {})
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant as Dictionary
		if String(effect.get("type", "")) == "add_inventory_capacity":
			capacity += int(effect.get("value", 0)) * int(
				upgrades.get(upgrade_key, 0)
			)
	return maxi(1, capacity)


func _apply_restored_upgrade_effect(effect: Dictionary) -> void:
	var effect_type: String = String(effect.get("type", ""))
	var value: float = float(effect.get("value", 0.0))
	match effect_type:
		"set_mining_cooldown":
			player.set("mining_cooldown", maxf(0.05, value))
		"add_inventory_capacity":
			player.set(
				"inventory_capacity",
				maxi(1, int(player.get("inventory_capacity")) + int(value))
			)
		"add_move_speed":
			player.set(
				"move_speed",
				maxf(0.1, float(player.get("move_speed")) + value)
			)


func _small_miner_definition() -> Dictionary:
	var definition_variant: Variant = _machine_definitions.get("small_miner", {})
	if definition_variant is Dictionary:
		return (definition_variant as Dictionary).duplicate(true)
	return {}


func _ore_definition_for_id(ore_id: String) -> Dictionary:
	for machine_variant in _machine_definitions.values():
		if not (machine_variant is Dictionary):
			continue
		var machine: Dictionary = machine_variant as Dictionary
		var ore_variant: Variant = machine.get("ore", {})
		if not (ore_variant is Dictionary):
			continue
		var ore: Dictionary = ore_variant as Dictionary
		if String(ore.get("id", "")) == ore_id:
			return ore.duplicate(true)
	return {}


func _create_small_miner(
	definition: Dictionary,
	position: Vector3,
	stored_amount: int
) -> StaticBody3D:
	var miner := SmallMinerScene.instantiate() as StaticBody3D
	if miner == null:
		return null

	miner.set(
		"generation_interval",
		float(definition.get("generation_interval", 2.0))
	)
	var storage_capacity: int = maxi(
		1,
		int(definition.get("storage_capacity", 5))
	)
	miner.set("storage_capacity", storage_capacity)

	var ore_variant: Variant = definition.get("ore", {})
	if ore_variant is Dictionary:
		var ore: Dictionary = ore_variant as Dictionary
		miner.set("ore_id", StringName(String(ore.get("id", "iron_ore"))))
		miner.set("ore_name", String(ore.get("name", "鉄鉱石")))
		miner.set(
			"ore_sell_value",
			maxi(0, int(ore.get("sell_value", 5)))
		)

	miner.position = position
	miner.set("stored_amount", clampi(stored_amount, 0, storage_capacity))
	add_child(miner)
	return miner


func build_save_snapshot() -> Dictionary:
	var machine_nodes: Array[Node] = []
	for node in get_tree().get_nodes_in_group("small_miners"):
		if node is Node and is_ancestor_of(node):
			machine_nodes.append(node as Node)

	return SaveModelScript.build_snapshot(player, machine_nodes)


func get_placed_small_miner_count() -> int:
	return _placed_small_miners


func is_machine_placement_active() -> bool:
	return _placement_preview != null


func _refresh_upgrade_panel() -> void:
	if _upgrade_definitions.is_empty():
		upgrade_status.text = "アップグレードデータを読み込めません"
		upgrade_status.modulate = Color(1.0, 0.72, 0.45, 1.0)
		return

	upgrade_balance.text = "所持金: ¥%d" % int(player.get("money"))
	_refresh_upgrade_row(
		&"mining_speed",
		mining_info,
		mining_button
	)
	_refresh_upgrade_row(
		&"inventory_capacity",
		capacity_info,
		capacity_button
	)
	_refresh_upgrade_row(
		&"move_speed",
		move_info,
		move_button
	)
	_refresh_small_miner_row()


func _refresh_upgrade_row(
	upgrade_id: StringName,
	info_label: Label,
	purchase_button: Button
) -> void:
	var key: String = String(upgrade_id)
	var definition_variant: Variant = _upgrade_definitions.get(key, {})
	if not (definition_variant is Dictionary):
		info_label.text = "データなし"
		purchase_button.disabled = true
		purchase_button.text = "利用不可"
		return

	var definition: Dictionary = definition_variant as Dictionary
	var level: int = int(player.call("get_upgrade_level", upgrade_id))
	var max_level: int = int(definition.get("max_level", 1))
	var cost: int = int(definition.get("cost", 0))
	var description: String = String(definition.get("description", ""))

	var current_value: String = _current_upgrade_value(upgrade_id)
	info_label.text = description + "　現在: " + current_value
	if level >= max_level:
		purchase_button.disabled = true
		purchase_button.text = "購入済み"
	else:
		purchase_button.disabled = false
		purchase_button.text = "購入 ¥%d" % cost


func _refresh_small_miner_row() -> void:
	var definition_variant: Variant = _machine_definitions.get("small_miner", {})
	if not (definition_variant is Dictionary):
		small_miner_info.text = "採掘機データを読み込めません"
		small_miner_button.disabled = true
		small_miner_button.text = "利用不可"
		return

	var definition: Dictionary = definition_variant as Dictionary
	var description: String = String(definition.get("description", ""))
	var cost: int = maxi(0, int(definition.get("cost", 0)))
	var max_placed: int = maxi(1, int(definition.get("max_placed", 1)))

	small_miner_info.text = description
	if _placed_small_miners >= max_placed:
		small_miner_button.disabled = true
		small_miner_button.text = "設置済み"
	else:
		small_miner_button.disabled = false
		small_miner_button.text = "購入して配置 ¥%d" % cost


func _current_upgrade_value(upgrade_id: StringName) -> String:
	match String(upgrade_id):
		"mining_speed":
			return "%.2f秒" % float(player.get("mining_cooldown"))
		"inventory_capacity":
			return "%d" % int(player.get("inventory_capacity"))
		"move_speed":
			return "%.1f" % float(player.get("move_speed"))
		_:
			return "-"
