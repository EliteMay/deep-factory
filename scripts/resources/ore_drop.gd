extends RigidBody3D

@export var ore_id: StringName = &"iron_ore"
@export var display_name: String = "鉄鉱石"
@export_range(1, 999, 1) var amount: int = 1
@export_range(0, 999999, 1) var sell_value: int = 5


func interact(player: Node) -> void:
	if amount <= 0 or player == null or not player.has_method("add_ore"):
		return

	var accepted := int(
		player.call(
			"add_ore",
			ore_id,
			display_name,
			sell_value,
			amount
		)
	)

	if accepted <= 0:
		return

	amount -= accepted
	if amount <= 0:
		queue_free()
