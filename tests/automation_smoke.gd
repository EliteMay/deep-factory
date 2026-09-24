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
	var miner_button := game.get_node_or_null(
		"HUD/UpgradePanel/Margin/VBox/MinerRow/Top/Purchase"
	) as Button
	var build_state := game.get_node_or_null("HUD/BuildState") as Label

	if player == null:
		_fail("Player node is missing")
	if miner_button == null:
		_fail("small miner purchase button is missing")
	if build_state == null:
		_fail("BuildState label is missing")
	if _failed:
		_finish()
		return

	player.set("money", 15)
	player.call("_emit_inventory_changed")
	game.call("_purchase_small_miner")
	await get_tree().process_frame
	await get_tree().physics_frame

	if int(player.get("money")) != 0:
		_fail("small miner purchase did not deduct 15")
	if not bool(game.call("is_machine_placement_active")):
		_fail("purchase did not enter placement mode")
	if not bool(player.call("is_placement_mode")):
		_fail("Player did not enter placement input mode")
	if not build_state.visible:
		_fail("placement guidance is not visible")
	if bool(game.call("_can_place_small_miner", Vector3(0, 0, 0))):
		_fail("placement validation allowed overlap with the center mining rock")

	game.call("_on_placement_cancel_requested")
	await get_tree().process_frame

	if int(player.get("money")) != 15:
		_fail("placement cancel did not refund purchase cost")
	if bool(game.call("is_machine_placement_active")):
		_fail("placement mode remained active after cancel")

	game.call("_purchase_small_miner")
	await get_tree().process_frame
	await get_tree().physics_frame

	var placement_valid: bool = bool(game.get("_placement_valid"))
	if not placement_valid:
		_fail("default preview position should be placeable in the test map")
		_finish()
		return

	game.call("_on_placement_confirm_requested")
	await get_tree().process_frame
	await get_tree().physics_frame

	if int(game.call("get_placed_small_miner_count")) != 1:
		_fail("small miner was not placed")
	if bool(game.call("is_machine_placement_active")):
		_fail("placement mode remained active after successful placement")
	if bool(player.call("is_placement_mode")):
		_fail("Player placement input mode remained active after placement")

	var miners: Array[Node] = get_tree().get_nodes_in_group("small_miners")
	if miners.size() != 1:
		_fail("expected exactly one placed small miner")
		_finish()
		return

	var miner: Node = miners[0]
	for _i in range(6):
		miner.call("generate_once")

	if int(miner.get("stored_amount")) != 5:
		_fail("small miner storage did not cap at 5")

	miner.call("interact", player)
	await get_tree().process_frame

	if int(player.call("inventory_count")) != 5:
		_fail("collecting the miner did not add 5 ore to Player inventory")
	if int(miner.get("stored_amount")) != 0:
		_fail("miner storage did not clear after collection")

	var sell_result: Dictionary = player.call("sell_all_ore")
	if int(sell_result.get("sold", 0)) != 5:
		_fail("collected miner ore could not be sold")
	if int(sell_result.get("value", 0)) != 25:
		_fail("miner ore sell value should be 25")
	if int(player.get("money")) != 25:
		_fail("money after miner ore sale should be 25")

	game.call("_refresh_upgrade_panel")
	if not miner_button.disabled or miner_button.text != "設置済み":
		_fail("machine purchase UI did not switch to installed state")

	_finish()


func _fail(message: String) -> void:
	_failed = true
	push_error("AUTOMATION_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("AUTOMATION_SMOKE: PASS")
		get_tree().quit(0)
