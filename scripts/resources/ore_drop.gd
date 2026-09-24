extends RigidBody3D

@export var ore_id: StringName = &"iron_ore"
@export var display_name: String = "鉄鉱石"
@export_range(1, 999, 1) var amount: int = 1
