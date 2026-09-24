extends Node3D

const UpgradeCatalogScript = preload("res://scripts/systems/upgrade_catalog.gd")

@onready var player: CharacterBody3D = $Player
@onready var feedback: Label = $HUD/Feedback
@onready var inventory_label: Label = $HUD/Inventory
@onready var money_label: Label = $HUD/Money
@onready var control_state_label: Label = $HUD/ControlState

@onready var upgrade_panel: PanelContainer = $HUD/UpgradePanel
@onready var upgrade_balance: Label = $HUD/UpgradePanel/Margin/VBox/Balance
@onready var upgrade_status: Label = $HUD/UpgradePanel/Margin/VBox/Status
@onready var mining_info: Label = $HUD/UpgradePanel/Margin/VBox/MiningRow/Info
@onready var mining_button: Button = $HUD/UpgradePanel/Margin/VBox/MiningRow/Top/Purchase
@onready var capacity_info: Label = $HUD/UpgradePanel/Margin/VBox/CapacityRow/Info
@onready var capacity_button: Button = $HUD/UpgradePanel/Margin/VBox/CapacityRow/Top/Purchase
@onready var move_info: Label = $HUD/UpgradePanel/Margin/VBox/MoveRow/Info
@onready var move_button: Button = $HUD/UpgradePanel/Margin/VBox/MoveRow/Top/Purchase

var _feedback_token: int = 0
var _upgrade_definitions: Dictionary = {}


func _ready() -> void:
	_upgrade_definitions = UpgradeCatalogScript.load_all()

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

	mining_button.pressed.connect(
		Callable(self, "_purchase_upgrade").bind(&"mining_speed")
	)
	capacity_button.pressed.connect(
		Callable(self, "_purchase_upgrade").bind(&"inventory_capacity")
	)
	move_button.pressed.connect(
		Callable(self, "_purchase_upgrade").bind(&"move_speed")
	)

	feedback.visible = false
	upgrade_panel.visible = false

	if player.has_method("inventory_count"):
		_on_inventory_changed(
			int(player.call("inventory_count")),
			int(player.get("inventory_capacity")),
			int(player.get("money"))
		)

	_refresh_upgrade_panel()

	if player.has_method("refresh_control_state"):
		player.call_deferred("refresh_control_state")


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


func _on_control_state_changed(message: String, active: bool) -> void:
	control_state_label.text = message
	control_state_label.visible = not active


func _on_upgrade_menu_changed(is_open: bool) -> void:
	upgrade_panel.visible = is_open
	if is_open:
		upgrade_status.text = "購入するアップグレードを選んでください"
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
