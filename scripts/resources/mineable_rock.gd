extends StaticBody3D

@export var max_durability: float = 3.0
@export var ore_drop_scene: PackedScene = preload("res://scenes/resources/ore_drop.tscn")

var current_durability: float
var _destroyed: bool = false


func _ready() -> void:
	current_durability = maxf(1.0, max_durability)


func mine(damage: float) -> Dictionary:
	if _destroyed:
		return {
			"remaining": 0.0,
			"max": max_durability,
			"destroyed": true,
		}

	current_durability = maxf(0.0, current_durability - maxf(0.0, damage))
	_play_hit_feedback()

	var destroyed_now := current_durability <= 0.0
	if destroyed_now:
		_break_rock()

	return {
		"remaining": current_durability,
		"max": max_durability,
		"destroyed": destroyed_now,
	}


func _play_hit_feedback() -> void:
	var original_scale := scale
	scale = original_scale * 0.94

	var tween := create_tween()
	tween.tween_property(self, "scale", original_scale, 0.08)


func _break_rock() -> void:
	if _destroyed:
		return

	_destroyed = true

	if ore_drop_scene:
		var ore := ore_drop_scene.instantiate()
		var world_parent := get_parent()
		if world_parent:
			world_parent.add_child(ore)
			if ore is Node3D:
				ore.global_position = global_position + Vector3(0.0, 0.75, 0.0)

	queue_free()
