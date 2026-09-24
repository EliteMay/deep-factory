extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var feedback: Label = $HUD/Feedback
@onready var inventory_label: Label = $HUD/Inventory
@onready var money_label: Label = $HUD/Money

var _feedback_token: int = 0


func _ready() -> void:
	if player.has_signal("mining_feedback"):
		player.connect("mining_feedback", Callable(self, "_on_feedback"))
	if player.has_signal("interaction_feedback"):
		player.connect("interaction_feedback", Callable(self, "_on_feedback"))
	if player.has_signal("inventory_changed"):
		player.connect("inventory_changed", Callable(self, "_on_inventory_changed"))

	feedback.visible = false

	if player.has_method("inventory_count"):
		_on_inventory_changed(
			int(player.call("inventory_count")),
			int(player.get("inventory_capacity")),
			int(player.get("money"))
		)


func _on_feedback(message: String, success: bool) -> void:
	_feedback_token += 1
	var token := _feedback_token

	feedback.text = message
	feedback.modulate = (
		Color(0.55, 1.0, 0.72, 1.0)
		if success
		else Color(1.0, 0.72, 0.45, 1.0)
	)
	feedback.visible = true

	await get_tree().create_timer(1.2).timeout
	if token == _feedback_token:
		feedback.visible = false


func _on_inventory_changed(current_count: int, capacity: int, money: int) -> void:
	inventory_label.text = "鉱石: %d / %d" % [current_count, capacity]
	money_label.text = "所持金: ¥%d" % money
