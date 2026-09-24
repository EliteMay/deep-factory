extends StaticBody3D


func interact(player: Node) -> void:
	if player == null or not player.has_method("open_upgrade_menu"):
		return

	player.call("open_upgrade_menu")
