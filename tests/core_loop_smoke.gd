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
	var feedback := game.get_node_or_null("HUD/Feedback") as Label
	var inventory_label := game.get_node_or_null("HUD/Inventory") as Label

	if player == null:
		_fail("Player node is missing")
	if feedback == null:
		_fail("HUD/Feedback is missing")
	if inventory_label == null:
		_fail("HUD/Inventory is missing")
	if _failed:
		_finish()
		return

	var ray := player.get_node_or_null("CameraPivot/Camera3D/InteractionRay") as RayCast3D
	if ray == null:
		_fail("InteractionRay is missing")
		_finish()
		return

	ray.enabled = false
	player.set("mining_cooldown_remaining", 0.0)
	player.call("_try_mine")
	await get_tree().process_frame

	if not feedback.visible:
		_fail("empty mining feedback is not visible")
	if feedback.text != "採掘対象なし":
		_fail("empty mining feedback text mismatch: " + feedback.text)

	var ore_scene := load("res://scenes/resources/ore_drop.tscn") as PackedScene
	if ore_scene == null:
		_fail("ore drop scene could not be loaded")
		_finish()
		return

	var ore := ore_scene.instantiate()
	game.add_child(ore)
	await get_tree().process_frame

	ore.call("interact", player)
	await get_tree().process_frame

	if int(player.call("inventory_count")) != 1:
		_fail("ore pickup did not increment Player inventory")
	if inventory_label.text != "鉱石: 1 / 10":
		_fail("HUD inventory did not update after pickup: " + inventory_label.text)

	var sell_result: Dictionary = player.call("sell_all_ore")
	await get_tree().process_frame

	if int(sell_result.get("sold", 0)) != 1:
		_fail("sell_all_ore did not sell picked ore")
	if int(player.call("inventory_count")) != 0:
		_fail("inventory did not clear after selling")
	if inventory_label.text != "鉱石: 0 / 10":
		_fail("HUD inventory did not refresh after selling: " + inventory_label.text)

	_finish()


func _fail(message: String) -> void:
	_failed = true
	push_error("CORE_LOOP_SMOKE: " + message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
	else:
		print("CORE_LOOP_SMOKE: PASS")
		get_tree().quit(0)
