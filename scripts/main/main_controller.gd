extends Node3D

const UpgradeCatalogScript = preload("res://scripts/systems/upgrade_catalog.gd")
const MachineCatalogScript = preload("res://scripts/systems/machine_catalog.gd")
const SaveModelScript = preload("res://scripts/systems/save_model.gd")
const FoundationSaveSystem = preload("res://addons/game_foundation/save/save_system.gd")
const AutoSaveServiceScript = preload("res://addons/game_foundation/save/auto_save_service.gd")
const SmallMinerScene = preload("res://scenes/world/small_miner.tscn")
const PlacementPreviewScene = preload("res://scenes/world/placement_preview.tscn")

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
var _autosave_service: Node = null
var _restoring_save: bool = false
var _save_path: String = "user://save.json"


func _ready() -> void:
	_upgrade_definitions = UpgradeCatalogScript.load_all()
	_machine_definitions = MachineCatalogScript.load_all()

	_autosave_service = AutoSaveServiceScript.new()
	_autosave_service.set("save_path", _save_path)
	_autosave_service.set("debounce_seconds", 0.35)
	add_child(_autosave_service)

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
		player.connect("upgrade_state_changed", Callable(self, "_refresh_upgrade_panel"))
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

	_load_game_from_path(_save_path)

	if player.has_method("inventory_count"):
		_on_inventory_changed(
			int(player.call("inventory_count")),
			int(player.get("inventory_capacity")),
			int(player.get("money"))
		)

	_refresh_upgrade_panel()

	if player.has_method("refresh_control_state"):
		player.call_deferred("refresh_control_state")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game_to_path(_save_path)


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

	_request_autosave()


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

	var miner := SmallMinerScene.instantiate() as StaticBody3D
	if miner == null:
		_on_feedback("小型採掘機を生成できません", false)
		return

	var definition: Dictionary = _pending_machine_definition
	miner.set(
		"generation_interval",
		float(definition.get("generation_interval", 2.0))
	)
	miner.set(
		"storage_capacity",
		maxi(1, int(definition.get("storage_capacity", 5)))
	)

	var ore_variant: Variant = definition.get("ore", {})
	if ore_variant is Dictionary:
		var ore: Dictionary = ore_variant as Dictionary
		miner.set("ore_id", StringName(String(ore.get("id", "iron_ore"))))
		miner.set("ore_name", String(ore.get("name", "鉄鉱石")))
		miner.set(
			"ore_sell_value",
			maxi(0, int(ore.get("sell_value", 5)))
		)

	miner.position = _placement_preview.position
	add_child(miner)
	_register_small_miner(miner)
	_placed_small_miners += 1

	_finish_machine_placement(false)
	_on_feedback(
		"小型採掘機を設置した。鉱石がたまったらEで回収できます",
		true
	)
	_refresh_upgrade_panel()
	_request_autosave()


func _on_placement_cancel_requested() -> void:
	if _placement_preview == null:
		return

	_finish_machine_placement(true)
	_on_feedback("設置をキャンセルしました。購入代金を返金しました", false)


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


func build_save_snapshot() -> Dictionary:
	var machine_nodes: Array[Node] = []
	for node in get_tree().get_nodes_in_group("small_miners"):
		if node is Node and is_ancestor_of(node):
			machine_nodes.append(node as Node)

	return SaveModelScript.build_snapshot(player, machine_nodes)


func save_game_to_path(path: String = "user://save.json") -> Dictionary:
	var snapshot: Dictionary = build_save_snapshot()
	return FoundationSaveSystem.save_game(
		snapshot,
		SaveModelScript.CURRENT_SAVE_VERSION,
		path
	)


func load_game_from_path(path: String = "user://save.json") -> Dictionary:
	return _load_game_from_path(path)


func _load_game_from_path(path: String) -> Dictionary:
	var result: Dictionary = FoundationSaveSystem.load_game(
		path,
		SaveModelScript.CURRENT_SAVE_VERSION,
		Callable(self, "_migrate_save_payload")
	)
	if bool(result.get("ok", false)):
		var payload_variant: Variant = result.get("payload", {})
		if payload_variant is Dictionary:
			_restore_save_payload(payload_variant as Dictionary)
		return result

	var code: String = String(result.get("code", "load_failed"))
	if code != "not_found":
		call_deferred(
			"_on_feedback",
			"セーブを読み込めなかったため新規状態で開始しました",
			false
		)
	return result


func _restore_save_payload(payload: Dictionary) -> void:
	_restoring_save = true

	var inventory: Dictionary = {}
	var inventory_variant: Variant = payload.get("inventory", {})
	if inventory_variant is Dictionary:
		inventory = (inventory_variant as Dictionary).duplicate(true)

	var upgrades: Dictionary = {}
	var upgrades_variant: Variant = payload.get("upgrades", {})
	if upgrades_variant is Dictionary:
		upgrades = (upgrades_variant as Dictionary).duplicate(true)

	var ore_definitions := _ore_definitions_for_restore()
	if player.has_method("restore_progress"):
		player.call(
			"restore_progress",
			maxi(0, int(payload.get("money", 0))),
			inventory,
			upgrades,
			ore_definitions,
			_upgrade_definitions
		)

	var player_variant: Variant = payload.get("player", {})
	if player_variant is Dictionary:
		var position := _array_to_vector3(
			(player_variant as Dictionary).get("position", [])
		)
		if position != null:
			player.global_position = position as Vector3

	for node in get_tree().get_nodes_in_group("small_miners"):
		if node is Node and is_ancestor_of(node):
			(node as Node).queue_free()
	_placed_small_miners = 0

	var machines_variant: Variant = payload.get("machines", [])
	if machines_variant is Array:
		for machine_variant in machines_variant as Array:
			if not (machine_variant is Dictionary):
				continue
			var machine: Dictionary = machine_variant as Dictionary
			if String(machine.get("type", "")) != "small_miner":
				continue
			_restore_small_miner(machine)

	_restoring_save = false
	_refresh_upgrade_panel()


func _restore_small_miner(machine: Dictionary) -> void:
	var definition_variant: Variant = _machine_definitions.get("small_miner", {})
	if not (definition_variant is Dictionary):
		return

	var position := _array_to_vector3(machine.get("position", []))
	if position == null:
		return

	var definition: Dictionary = definition_variant as Dictionary
	var miner := SmallMinerScene.instantiate() as StaticBody3D
	if miner == null:
		return

	miner.set("generation_interval", float(definition.get("generation_interval", 2.0)))
	miner.set("storage_capacity", maxi(1, int(definition.get("storage_capacity", 5))))

	var ore_variant: Variant = definition.get("ore", {})
	if ore_variant is Dictionary:
		var ore: Dictionary = ore_variant as Dictionary
		miner.set("ore_id", StringName(String(ore.get("id", "iron_ore"))))
		miner.set("ore_name", String(ore.get("name", "鉄鉱石")))
		miner.set("ore_sell_value", maxi(0, int(ore.get("sell_value", 5))))

	miner.set(
		"stored_amount",
		clampi(
			int(machine.get("stored_amount", 0)),
			0,
			int(miner.get("storage_capacity"))
		)
	)
	miner.global_position = position as Vector3
	add_child(miner)
	_register_small_miner(miner)
	_placed_small_miners += 1


func _register_small_miner(miner: Node) -> void:
	if miner.has_signal("storage_changed"):
		var callback := Callable(self, "_on_small_miner_storage_changed")
		if not miner.is_connected("storage_changed", callback):
			miner.connect("storage_changed", callback)


func _on_small_miner_storage_changed(_current: int, _capacity: int) -> void:
	_request_autosave()


func _request_autosave() -> void:
	if _restoring_save or not is_instance_valid(_autosave_service):
		return
	_autosave_service.call(
		"request_save",
		build_save_snapshot(),
		SaveModelScript.CURRENT_SAVE_VERSION
	)


func _ore_definitions_for_restore() -> Dictionary:
	var definitions: Dictionary = {}
	for machine_variant in _machine_definitions.values():
		if not (machine_variant is Dictionary):
			continue
		var ore_variant: Variant = (machine_variant as Dictionary).get("ore", {})
		if not (ore_variant is Dictionary):
			continue
		var ore: Dictionary = ore_variant as Dictionary
		var ore_id: String = String(ore.get("id", ""))
		if ore_id.is_empty():
			continue
		definitions[ore_id] = {
			"name": String(ore.get("name", ore_id)),
			"sell_value": maxi(0, int(ore.get("sell_value", 0))),
		}
	return definitions


func _array_to_vector3(value: Variant) -> Variant:
	if not (value is Array):
		return null
	var values: Array = value as Array
	if values.size() != 3:
		return null
	return Vector3(
		float(values[0]),
		float(values[1]),
		float(values[2])
	)


func _migrate_save_payload(
	payload: Dictionary,
	_from_version: int,
	_to_version: int
) -> Dictionary:
	return payload.duplicate(true)


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
