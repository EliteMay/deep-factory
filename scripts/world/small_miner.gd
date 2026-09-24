extends StaticBody3D

signal storage_changed(current_count: int, capacity: int)

@export var generation_interval: float = 2.0
@export_range(1, 999, 1) var storage_capacity: int = 5
@export var ore_id: StringName = &"iron_ore"
@export var ore_name: String = "鉄鉱石"
@export_range(0, 999999, 1) var ore_sell_value: int = 5

@onready var generation_timer: Timer = $GenerationTimer
@onready var storage_label: Label3D = $StorageLabel

var stored_amount: int = 0


func _ready() -> void:
	generation_timer.wait_time = maxf(0.1, generation_interval)
	_refresh_storage_label()


func _on_generation_timer_timeout() -> void:
	generate_once()


func generate_once() -> bool:
	if stored_amount >= storage_capacity:
		return false

	stored_amount += 1
	_refresh_storage_label()
	storage_changed.emit(stored_amount, storage_capacity)
	return true


func interact(player: Node) -> void:
	if player == null or not player.has_method("add_ore"):
		return

	if stored_amount <= 0:
		if player.has_signal("interaction_feedback"):
			player.emit_signal(
				"interaction_feedback",
				"採掘機の内部ストレージは空です",
				false
			)
		return

	var accepted := int(
		player.call(
			"add_ore",
			ore_id,
			ore_name,
			ore_sell_value,
			stored_amount
		)
	)

	if accepted <= 0:
		return

	stored_amount -= accepted
	_refresh_storage_label()
	storage_changed.emit(stored_amount, storage_capacity)


func _refresh_storage_label() -> void:
	if not is_instance_valid(storage_label):
		return

	storage_label.text = "小型採掘機\n%d / %d" % [
		stored_amount,
		storage_capacity,
	]
