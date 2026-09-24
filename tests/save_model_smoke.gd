extends Node

const SmallMinerScene = preload("res://scenes/world/small_miner.tscn")

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

	player.set("money", 42)
	player.set("ore_counts", {&"iron_ore": 3})
	player.set("upgrade_levels", {
		"mining_speed": 1,
		"inventory_capacity": 1,
	})
	player.global_position = Vector3(1.5, 1.0, -2.0)

	var miner := SmallMinerScene.instantiate() as StaticBody3D
	miner.position = Vector3(4.0, 0.0, 2.0)
	miner.set("stored_amount", 4)
	game.add_child(miner)
	await get_tree().process_frame

	var snapshot: Dictionary = game.call("build_save_snapshot")
	if int(snapshot.get("save_version", 0)) != 1:
		_fail("save_version should be 1")
	if int(snapshot.get("money", -1)) != 42:
		_fail("money was not captured")

	var inventory_variant: Variant = snapshot.get("inventory", {})
	if not (inventory_variant is Dictionary):
		_fail("inventory is not a Dictionary")
	else:
		var inventory := inventory_variant as Dictionary
		if int(inventory.get("iron_ore", 0)) != 3:
			_fail("inventory amount was not captured")

	var upgrades_variant: Variant = snapshot.get("upgrades", {})
	if not (upgrades_variant is Dictionary):
		_fail("upgrades is not a Dictionary")
	else:
		var upgrades := upgrades_variant as Dictionary
		if int(upgrades.get("mining_speed", 0)) != 1:
			_fail("upgrade level was not captured")

	var player_variant: Variant = snapshot.get("player", {})
	if not (player_variant is Dictionary):
		_fail("player state is not a Dictionary")
	else:
		var player_state := player_variant as Dictionary
		var position_variant: Variant = player_state.get("position", [])
		if not (position_variant is Array):
			_fail("player position is not an Array")
		else:
			var position_array := position_variant as Array
			if position_array.size() != 3:
				_fail("player position must have 3 elements")
			elif not is_equal_approx(float(position_array[0]), 1.5):
				_fail("player x position was not captured")

	var machines_variant: Variant = snapshot.get("machines", [])
	if not (machines_variant is Array):
		_fail("machines is not an Array")
	else:
		var machines := machines_variant as Array
		if machines.size() != 1:
			_fail("expected one small miner in save snapshot")
		else:
			var machine_variant: Variant = machines[0]
			if not (machine_variant is Dictionary):
				_fail("machine state is not a Dictionary")
			else:
				var machine := machine_variant as Dictionary
				if String(machine.get("type", "")) != "small_miner":
					_fail("machine type was not captured")
				if int(machine.get("stored_amount", -1)) != 4:
					_fail("machine storage was not captured")

	var json_text := JSON.stringify(snapshot)
	if json_text.is_empty():
		_fail("snapshot could not be serialized to JSON")

	_finish()


func _fail(message: String) -> void:
	_failed = true
	push_error("SAVE_MODEL_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("SAVE_MODEL_SMOKE: PASS")
		get_tree().quit(0)
