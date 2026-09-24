extends StaticBody3D


func interact(player: Node) -> void:
	if player == null or not player.has_method("sell_all_ore"):
		return

	player.call("sell_all_ore")
