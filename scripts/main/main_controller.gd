extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var mining_feedback: Label = $HUD/MiningFeedback

var _feedback_token: int = 0


func _ready() -> void:
	if player.has_signal("mining_feedback"):
		player.mining_feedback.connect(_on_mining_feedback)

	mining_feedback.visible = false


func _on_mining_feedback(message: String, success: bool) -> void:
	_feedback_token += 1
	var token := _feedback_token

	mining_feedback.text = message
	mining_feedback.modulate = (
		Color(0.55, 1.0, 0.72, 1.0)
		if success
		else Color(1.0, 0.72, 0.45, 1.0)
	)
	mining_feedback.visible = true

	await get_tree().create_timer(1.2).timeout
	if token == _feedback_token:
		mining_feedback.visible = false
