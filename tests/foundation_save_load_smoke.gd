extends Node

const SmallMinerScene = preload("res://scenes/world/small_miner.tscn")

const TEST_SAVE_PATH := "user://deep_factory_foundation_save_load_smoke.json"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()

	var first := await _create_game()
	if first == null:
		_finish()
		return

	var first_player := first.get_node_or_null("Player") as CharacterBody3D
	if first_player == null:
		_fail("first Player is missing")
		_finish()
		return

	first_player.set("money", 42)
	first_player.set("ore_counts", {&"iron_ore": 3})
	first_player.set("ore_values", {&"iron_ore": 5})
	first_player.set("ore_names", {&"iron_ore": "鉄鉱石"})
	first_player.set("upgrade_levels", {
		"mining_speed": 1,
		"inventory_capacity": 1,
		"move_speed": 1,
	})
	first_player.global_position = Vector3(1.5, 0.05, -2.0)

	var miner := SmallMinerScene.instantiate() as StaticBody3D
	miner.position = Vector3(4.0, 0.0, 2.0)
	miner.set("stored_amount", 4)
	first.add_child(miner)
	await get_tree().process_frame

	var save_result: Dictionary = first.call("save_now")
	if not bool(save_result.get("ok", false)):
		_fail("first save failed: " + String(save_result.get("code", "unknown")))

	first.queue_free()
	await get_tree().process_frame

	var second := await _create_game()
	if second == null:
		_finish()
		return

	_assert_restored_state(second, 42, 3, 4)

	var second_player := second.get_node_or_null("Player") as CharacterBody3D
	second_player.set("money", 50)
	second_player.call("_emit_inventory_changed")
	var second_save: Dictionary = second.call("save_now")
	if not bool(second_save.get("ok", false)):
		_fail("second save failed: " + String(second_save.get("code", "unknown")))

	second.queue_free()
	await get_tree().process_frame

	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_fail("could not corrupt primary save for recovery test")
	else:
		file.store_string("{ broken json")
		file.close()

	var recovered := await _create_game()
	if recovered == null:
		_finish()
		return

	_assert_restored_state(recovered, 42, 3, 4)
	if bool(recovered.get("_save_writes_blocked")):
		_fail("valid backup recovery should not block future writes")

	recovered.queue_free()
	await get_tree().process_frame
	_cleanup()
	_finish()


func _create_game() -> Node:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene could not be loaded")
		return null

	var game := packed.instantiate()
	game.set("allow_headless_persistence", true)
	game.set("save_path", TEST_SAVE_PATH)
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	return game


func _assert_restored_state(
	game: Node,
	expected_money: int,
	expected_ore: int,
	expected_machine_storage: int
) -> void:
	var player := game.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		_fail("restored Player is missing")
		return

	if int(player.get("money")) != expected_money:
		_fail("money was not restored")
	if int(player.call("inventory_count")) != expected_ore:
		_fail("inventory was not restored")
	if int(player.call("get_upgrade_level", &"mining_speed")) != 1:
		_fail("mining upgrade was not restored")
	if int(player.call("get_upgrade_level", &"inventory_capacity")) != 1:
		_fail("capacity upgrade was not restored")
	if int(player.call("get_upgrade_level", &"move_speed")) != 1:
		_fail("move upgrade was not restored")
	if not is_equal_approx(float(player.get("mining_cooldown")), 0.25):
		_fail("mining cooldown effect was not restored")
	if int(player.get("inventory_capacity")) != 15:
		_fail("inventory capacity effect was not restored")
	if not is_equal_approx(float(player.get("move_speed")), 6.5):
		_fail("move speed effect was not restored")
	if player.global_position.distance_to(Vector3(1.5, 1.0, -2.0)) > 0.01:
		_fail("Player position was not restored")

	var miners: Array[Node] = []
	for node in get_tree().get_nodes_in_group("small_miners"):
		if node is Node and game.is_ancestor_of(node):
			miners.append(node as Node)

	if miners.size() != 1:
		_fail("expected exactly one restored small miner")
		return

	if int(miners[0].get("stored_amount")) != expected_machine_storage:
		_fail("small miner storage was not restored")
	if (miners[0] as Node3D).global_position.distance_to(Vector3(4.0, 0.0, 2.0)) > 0.01:
		_fail("small miner position was not restored")
	if int(game.call("get_placed_small_miner_count")) != 1:
		_fail("placed small miner count was not restored")


func _cleanup() -> void:
	for path in [
		TEST_SAVE_PATH,
		TEST_SAVE_PATH + ".bak",
		TEST_SAVE_PATH + ".tmp",
		TEST_SAVE_PATH + ".bak.tmp",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _fail(message: String) -> void:
	_failed = true
	push_error("FOUNDATION_SAVE_LOAD_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("FOUNDATION_SAVE_LOAD_SMOKE: PASS")
		get_tree().quit(0)
