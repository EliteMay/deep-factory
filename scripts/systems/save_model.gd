extends RefCounted

const CURRENT_SAVE_VERSION: int = 1


static func build_snapshot(player: Node, machine_nodes: Array[Node]) -> Dictionary:
	if player == null or not (player is Node3D):
		push_error("SaveModel: Playerが見つかりません")
		return {}

	var inventory: Dictionary = _normalize_non_negative_int_dictionary(
		_dictionary_property(player, &"ore_counts")
	)
	var upgrades: Dictionary = _normalize_non_negative_int_dictionary(
		_dictionary_property(player, &"upgrade_levels")
	)

	var machines: Array = []
	for machine in machine_nodes:
		if machine == null or not is_instance_valid(machine):
			continue
		if not (machine is Node3D):
			continue
		if not machine.is_in_group("small_miners"):
			continue

		machines.append({
			"type": "small_miner",
			"position": _vector3_to_array((machine as Node3D).global_position),
			"stored_amount": maxi(0, int(machine.get("stored_amount"))),
		})

	return {
		"save_version": CURRENT_SAVE_VERSION,
		"money": maxi(0, int(player.get("money"))),
		"inventory": inventory,
		"upgrades": upgrades,
		"player": {
			"position": _vector3_to_array((player as Node3D).global_position),
		},
		"machines": machines,
	}


static func _dictionary_property(source: Object, property_name: StringName) -> Dictionary:
	var value: Variant = source.get(property_name)
	if value is Dictionary:
		return value as Dictionary
	return {}


static func _normalize_non_negative_int_dictionary(source: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for raw_key in source.keys():
		var key: String = String(raw_key)
		if key.is_empty():
			continue
		normalized[key] = maxi(0, int(source.get(raw_key, 0)))
	return normalized


static func _vector3_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
