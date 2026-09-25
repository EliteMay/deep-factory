extends Node

const SmallMinerScene = preload("res://scenes/world/small_miner.tscn")
const SaveSystem = preload("res://addons/game_foundation/save/save_system.gd")

const SAVE_PATH := "user://deep_factory_foundation_pilot_smoke.json"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_save_files()

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
	player.set("ore_values", {&"iron_ore": 5})
	player.set("ore_names", {&"iron_ore": "鉄鉱石"})
	player.set("upgrade_levels", {"inventory_capacity": 1})
	player.set("inventory_capacity", 15)
	player.global_position = Vector3(1.5, 1.0, -2.0)

	var miner := SmallMinerScene.instantiate() as StaticBody3D
	miner.set("generation_interval", 1000.0)
	miner.set("stored_amount", 4)
	miner.position = Vector3(4.0, 0.0, 2.0)
	game.add_child(miner)
	await get_tree().process_frame

	var save_result: Dictionary = game.call("save_game_to_path", SAVE_PATH)
	if not bool(save_result.get("ok", false)):
		_fail("Foundation save failed: " + String(save_result.get("code", "")))
		_finish()
		return

	player.set("money", 0)
	player.set("ore_counts", {})
	player.set("ore_values", {})
	player.set("ore_names", {})
	player.set("upgrade_levels", {})
	player.set("inventory_capacity", 10)
	player.global_position = Vector3.ZERO
	miner.queue_free()
	await get_tree().process_frame

	var load_result: Dictionary = game.call("load_game_from_path", SAVE_PATH)
	if not bool(load_result.get("ok", false)):
		_fail("Foundation load failed: " + String(load_result.get("code", "")))
		_finish()
		return

	await get_tree().process_frame

	if int(player.get("money")) != 42:
		_fail("money was not restored")
	if int(player.call("inventory_count")) != 3:
		_fail("inventory was not restored")
	if int(player.get("inventory_capacity")) != 15:
		_fail("upgrade effect was not restored")
	if int(player.call("get_upgrade_level", &"inventory_capacity")) != 1:
		_fail("upgrade level was not restored")
	if player.global_position.distance_to(Vector3(1.5, 1.0, -2.0)) > 0.01:
		_fail("player position was not restored")

	var miners: Array[Node] = []
	for node in get_tree().get_nodes_in_group("small_miners"):
		if node is Node and game.is_ancestor_of(node):
			miners.append(node as Node)

	if miners.size() != 1:
		_fail("expected one restored small miner")
	else:
		var restored := miners[0]
		if int(restored.get("stored_amount")) != 4:
			_fail("small miner storage was not restored")
		var restored_position := (restored as Node3D).global_position
		if restored_position.distance_to(Vector3(4.0, 0.0, 2.0)) > 0.01:
			_fail("small miner position was not restored")

	var sold: Dictionary = player.call("sell_all_ore")
	if int(sold.get("sold", 0)) != 3 or int(sold.get("value", 0)) != 15:
		_fail("restored inventory lost static sell metadata")

	_cleanup_save_files()
	_finish()


func _cleanup_save_files() -> void:
	for path in [
		SAVE_PATH,
		SaveSystem.backup_path(SAVE_PATH),
		SaveSystem.temp_path(SAVE_PATH),
		SaveSystem.backup_path(SAVE_PATH) + SaveSystem.TEMP_SUFFIX,
	]:
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute)


func _fail(message: String) -> void:
	_failed = true
	push_error("FOUNDATION_PILOT_SAVE_SMOKE: " + message)


func _finish() -> void:
	_cleanup_save_files()
	if _failed:
		get_tree().quit(1)
	else:
		print("FOUNDATION_PILOT_SAVE_SMOKE: PASS")
		get_tree().quit(0)
