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

	var player := game.get_node_or_null("Player") as CharacterBody3D
	var panel := game.get_node_or_null("HUD/UpgradePanel") as PanelContainer
	var station := game.get_node_or_null("UpgradeStation") as StaticBody3D

	if player == null:
		_fail("Player node is missing")
	if panel == null:
		_fail("UpgradePanel is missing")
	if station == null:
		_fail("UpgradeStation is missing")
	if _failed:
		_finish()
		return

	var definitions: Dictionary = UpgradeCatalog.load_all()
	for key in ["mining_speed", "inventory_capacity", "move_speed"]:
		if not definitions.has(key):
			_fail("missing upgrade definition: " + key)

	player.set("money", 25)

	var mining_result: Dictionary = player.call(
		"purchase_upgrade",
		&"mining_speed",
		definitions["mining_speed"]
	)
	if not bool(mining_result.get("purchased", false)):
		_fail("mining_speed purchase failed")
	if not is_equal_approx(float(player.get("mining_cooldown")), 0.25):
		_fail("mining cooldown effect was not applied")
	if int(player.get("money")) != 20:
		_fail("mining_speed cost was not deducted")

	var capacity_result: Dictionary = player.call(
		"purchase_upgrade",
		&"inventory_capacity",
		definitions["inventory_capacity"]
	)
	if not bool(capacity_result.get("purchased", false)):
		_fail("inventory_capacity purchase failed")
	if int(player.get("inventory_capacity")) != 15:
		_fail("inventory capacity effect was not applied")
	if int(player.get("money")) != 10:
		_fail("inventory_capacity cost was not deducted")

	var move_result: Dictionary = player.call(
		"purchase_upgrade",
		&"move_speed",
		definitions["move_speed"]
	)
	if not bool(move_result.get("purchased", false)):
		_fail("move_speed purchase failed")
	if not is_equal_approx(float(player.get("move_speed")), 6.5):
		_fail("move speed effect was not applied")
	if int(player.get("money")) != 0:
		_fail("move_speed cost was not deducted")

	var duplicate_result: Dictionary = player.call(
		"purchase_upgrade",
		&"mining_speed",
		definitions["mining_speed"]
	)
	if bool(duplicate_result.get("purchased", false)):
		_fail("maxed upgrade could be purchased twice")

	player.call("open_upgrade_menu")
	if not bool(player.get("_upgrade_menu_open")):
		_fail("upgrade menu did not enter menu mode")
	player.call("close_upgrade_menu")
	if bool(player.get("_upgrade_menu_open")):
		_fail("upgrade menu did not close")

	_finish()


func _fail(message: String) -> void:
	_failed = true
	push_error("UPGRADE_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("UPGRADE_SMOKE: PASS")
		get_tree().quit(0)
